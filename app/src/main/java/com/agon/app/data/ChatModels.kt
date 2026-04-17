package com.agon.app.data

import kotlinx.serialization.Serializable

@Serializable
data class ChatMessage(
    val id: String,
    val role: String, // "user" or "assistant"
    val content: String,
    val timestamp: Long
)

@Serializable
data class ChatHistory(
    val messages: List<ChatMessage> = emptyList()
)
