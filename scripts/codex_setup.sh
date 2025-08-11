#!/usr/bin/env bash
# stitch.OS — Codex mixed-stack setup script
# Works for Node/Next.js, Flutter, and Python in one go.
# Safe to re-run. Fails the job if analyzers/tests fail (good for PR gates).

set -euo pipefail

echo "─── stitch.OS ▸ Codex setup started"

# -------------------------
# Helpers
# -------------------------
APT_UPDATED=0
apt_ensure() {
  local pkg="$1"
  if ! dpkg -s "$pkg" >/dev/null 2>&1; then
    if [ "$APT_UPDATED" -eq 0 ]; then
      echo "apt update…"
      apt-get update -y
      APT_UPDATED=1
    fi
    echo "apt install $pkg…"
    DEBIAN_FRONTEND=noninteractive apt-get install -y "$pkg"
  fi
}

has_script() { # check if package.json has an npm/yarn/pnpm script
  local name="$1"
  [ -f package.json ] && grep -q "\"$name\"" package.json
}

detect_pm() {
  if [ -f pnpm-lock.yaml ]; then echo "pnpm"
  elif [ -f yarn.lock ]; then echo "yarn"
  elif [ -f package-lock.json ] || [ -f package.json ]; then echo "npm"
  else echo "none"
  fi
}

run_pm() { # run package script if present with the detected PM
  local script="$1" pm="$2"
  if has_script "$script"; then
    case "$pm" in
      pnpm) corepack enable >/dev/null 2>&1 || true; pnpm -s "$script" ;;
      yarn) corepack enable >/dev/null 2>&1 || true; yarn -s "$script" ;;
      npm)  npm run -s "$script" --if-present ;;
    esac
  fi
}

with_dir() { # run a block in a dir safely
  local d="$1"; shift
  ( cd "$d" && eval "$@" )
}

# -------------------------
# NPM auth (if provided)
# -------------------------
if [ "${NPM_TOKEN:-}" != "" ] && [ ! -f .npmrc ]; then
  echo "//registry.npmjs.org/:_authToken=\${NPM_TOKEN}" > .npmrc
  echo "wrote .npmrc for private packages"
fi

# -------------------------
# Node/Next.js handler
# -------------------------
handle_node() {
  local dir="$1"
  echo "→ Node/Next.js: $dir"
  with_dir "$dir" '
    pm=$(detect_pm)
    if [ "$pm" = "none" ]; then
      echo "  (skip: no package.json)"
      exit 0
    fi

    # Corepack gives us pnpm/yarn reliably
    corepack enable >/dev/null 2>&1 || true

    case "$pm" in
      pnpm) echo "  using pnpm"; pnpm i --frozen-lockfile || pnpm i ;;
      yarn) echo "  using yarn"; yarn install --frozen-lockfile || yarn install ;;
      npm)  echo "  using npm";  if [ -f package-lock.json ]; then npm ci; else npm install; fi ;;
    esac

    # Conventional steps (only run if scripts exist)
    run_pm "lint"   "$pm"
    run_pm "test"   "$pm"
    run_pm "build"  "$pm"
  '
}

# -------------------------
# Flutter handler
# -------------------------
install_flutter_if_needed() {
  if command -v flutter >/dev/null 2>&1; then
    flutter --version
    return
  fi
  echo "installing Flutter SDK…"
  apt_ensure curl
  apt_ensure unzip
  apt_ensure xz-utils
  apt_ensure ca-certificates
  FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.22.2-stable.tar.xz"
  curl -L "$FLUTTER_URL" -o /tmp/flutter.tar.xz
  mkdir -p /opt && tar -xJf /tmp/flutter.tar.xz -C /opt
  export PATH="/opt/flutter/bin:$PATH"
  flutter --version
  flutter config --no-analytics
}

handle_flutter() {
  local dir="$1"
  echo "→ Flutter: $dir"
  install_flutter_if_needed
  with_dir "$dir" '
    flutter pub get
    # Safe to run even if no tests
    flutter analyze
    if ls test/*.dart >/dev/null 2>&1; then
      flutter test
    else
      echo "  (no Flutter tests found)"
    fi
  '
}

# -------------------------
# Python handler
# -------------------------
handle_python() {
  local dir="$1"
  echo "→ Python: $dir"
  apt_ensure python3-venv
  with_dir "$dir" '
    python3 -m venv .venv
    . .venv/bin/activate
    pip install -U pip
    if [ -f requirements.txt ]; then
      pip install -r requirements.txt
    elif [ -f pyproject.toml ]; then
      # build-system must be set for this to work
      pip install .
    else
      echo "  (no requirements.txt or pyproject.toml)"
    fi

    # Lint / tests if present
    if [ -f setup.cfg ] || [ -f pyproject.toml ] || [ -f tox.ini ]; then
      pip install pytest flake8 >/dev/null 2>&1 || true
    fi
    if [ -d tests ] || ls test_*.py >/dev/null 2>&1; then
      pytest -q
    else
      echo "  (no pytest tests found)"
    fi
  '
}

# -------------------------
# Scan typical locations
# -------------------------
NODE_DIRS=()
FLUTTER_DIRS=()
PY_DIRS=()

# Root
[ -f package.json ]     && NODE_DIRS+=(".")
[ -f pubspec.yaml ]     && FLUTTER_DIRS+=(".")
[ -f requirements.txt ] && PY_DIRS+=(".")
[ -f pyproject.toml ]   && PY_DIRS+=(".")

# Common monorepo folders
for d in apps/* packages/* services/* backend/* frontend/* mobile/* api/* ; do
  [ -d "$d" ] || continue
  [ -f "$d/package.json" ]     && NODE_DIRS+=("$d")
  [ -f "$d/pubspec.yaml" ]     && FLUTTER_DIRS+=("$d")
  { [ -f "$d/requirements.txt" ] || [ -f "$d/pyproject.toml" ]; } && PY_DIRS+=("$d")
done

# De-duplicate arrays
dedupe() {
  awk '!x[$0]++'
}
NODE_DIRS=($(printf "%s\n" "${NODE_DIRS[@]}" | dedupe))
FLUTTER_DIRS=($(printf "%s\n" "${FLUTTER_DIRS[@]}" | dedupe))
PY_DIRS=($(printf "%s\n" "${PY_DIRS[@]}" | dedupe))

# Execute
for d in "${NODE_DIRS[@]}"; do handle_node "$d"; done
for d in "${FLUTTER_DIRS[@]}"; do handle_flutter "$d"; done
for d in "${PY_DIRS[@]}"; do handle_python "$d"; done

echo "─── stitch.OS ▸ Codex setup finished OK"

