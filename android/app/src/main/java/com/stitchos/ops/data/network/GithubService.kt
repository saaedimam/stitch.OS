package com.stitchos.ops.data.network

import retrofit2.Response
import retrofit2.http.*

interface GithubRawService {
    @GET("clickup/WORKFLOW.md")
    suspend fun getWorkflowMd(): Response<String>

    @GET("clickup/data/tasks/{listId}.json")
    suspend fun getTaskList(@Path("listId") listId: String): Response<TaskListResponse>
}

interface GithubApiService {
    @POST("repos/{owner}/{repo}/dispatches")
    suspend fun triggerDispatch(
        @Path("owner") owner: String,
        @Path("repo") repo: String,
        @Body payload: DispatchPayload
    ): Response<Unit>
}

data class DispatchPayload(
    val event_type: String = "clickup-update",
    val client_payload: Map<String, String> = mapOf("source" to "android")
)

@JsonClass(generateAdapter = true)
data class TaskListResponse(
    val list: ListMetadata,
    val tasks: List<Task>
)

@JsonClass(generateAdapter = true)
data class ListMetadata(
    val id: String,
    val name: String
)

