package com.stitchos.ops.data.models

import com.squareup.moshi.JsonClass

@JsonClass(generateAdapter = true)
data class WorkflowSnapshot(
    val openTasks: Int,
    val closedTasks: Int,
    val overdueTasks: Int
)

@JsonClass(generateAdapter = true)
data class Task(
    val id: String,
    val name: String,
    val dueDate: String?,
    val status: String,
    val assignees: List<String>,
    val listName: String,
    val daysOverdue: Int
)

data class SettingsState(
    val githubRepoFull: String = "",
    val githubToken: String = "",
    val rawBaseUrl: String = ""
)

