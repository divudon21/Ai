package com.agon.app.data

import android.content.Context
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.io.File

class ChatRepository(private val context: Context) {
    private val historyFile = File(context.filesDir, "chat_history.json")
    private val json = Json { ignoreUnknownKeys = true }

    suspend fun getHistory(): ChatHistory = withContext(Dispatchers.IO) {
        if (!historyFile.exists()) {
            return@withContext ChatHistory()
        }
        try {
            val content = historyFile.readText()
            json.decodeFromString<ChatHistory>(content)
        } catch (e: Exception) {
            ChatHistory()
        }
    }

    suspend fun saveHistory(history: ChatHistory) = withContext(Dispatchers.IO) {
        val content = json.encodeToString(history)
        historyFile.writeText(content)
    }

    suspend fun clearHistory() = withContext(Dispatchers.IO) {
        if (historyFile.exists()) {
            historyFile.delete()
        }
    }
}
