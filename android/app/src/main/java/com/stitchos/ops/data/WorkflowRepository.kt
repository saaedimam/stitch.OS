package com.stitchos.ops.data

import com.stitchos.ops.data.models.WorkflowSnapshot
import com.stitchos.ops.data.network.GithubApiService
import com.stitchos.ops.data.network.GithubRawService
import javax.inject.Inject

class WorkflowRepository @Inject constructor(
    private val rawService: GithubRawService,
    private val apiService: GithubApiService,
    private val settings: EncryptedSettings
) {
    suspend fun fetchWorkflowMd(): WorkflowSnapshot {
        val response = rawService.getWorkflowMd()
        if (!response.isSuccessful) throw Exception("Failed to fetch workflow")

        val content = response.body() ?: throw Exception("Empty response")
        return parseWorkflowMd(content)
    }

    suspend fun fetchTasksIndex(): List<Task> {
        // For demo, just fetch first list found
        val response = rawService.getTaskList("demo_list")
        if (!response.isSuccessful) return emptyList()

        return response.body()?.tasks ?: emptyList()
    }

    suspend fun triggerDispatch(): Result<Unit> = try {
        val (owner, repo) = settings.githubRepoFull.split("/")
        val response = apiService.triggerDispatch(owner, repo, DispatchPayload())
        if (response.isSuccessful) Result.success(Unit)
        else Result.failure(Exception("Failed to trigger: ${response.code()}"))
    } catch (e: Exception) {
        Result.failure(e)
    }

    private fun parseWorkflowMd(content: String): WorkflowSnapshot {
        val openRegex = """Open Tasks: (\d+)""".toRegex()
        val closedRegex = """Closed Tasks: (\d+)""".toRegex()
        val overdueRegex = """Overdue: (\d+)""".toRegex()

        return WorkflowSnapshot(
            openTasks = openRegex.find(content)?.groupValues?.get(1)?.toIntOrNull() ?: 0,
            closedTasks = closedRegex.find(content)?.groupValues?.get(1)?.toIntOrNull() ?: 0,
            overdueTasks = overdueRegex.find(content)?.groupValues?.get(1)?.toIntOrNull() ?: 0
        )
    }
}

