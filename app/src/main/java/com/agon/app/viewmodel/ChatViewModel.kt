package com.agon.app.viewmodel

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.agon.app.data.AiApiClient
import com.agon.app.data.ChatHistory
import com.agon.app.data.ChatMessage
import com.agon.app.data.ChatRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.util.UUID

class ChatViewModel(application: Application) : AndroidViewModel(application) {
    private val repository = ChatRepository(application)
    private val apiClient = AiApiClient()

    private val _messages = MutableStateFlow<List<ChatMessage>>(emptyList())
    val messages: StateFlow<List<ChatMessage>> = _messages.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading: StateFlow<Boolean> = _isLoading.asStateFlow()

    init {
        loadHistory()
    }

    private fun loadHistory() {
        viewModelScope.launch {
            val history = repository.getHistory()
            _messages.value = history.messages
        }
    }

    fun sendMessage(content: String) {
        if (content.isBlank()) return

        val userMessage = ChatMessage(
            id = UUID.randomUUID().toString(),
            role = "user",
            content = content.trim(),
            timestamp = System.currentTimeMillis()
        )

        val updatedMessages = _messages.value + userMessage
        _messages.value = updatedMessages
        saveHistory(updatedMessages)

        viewModelScope.launch {
            _isLoading.value = true
            
            val responseText = apiClient.sendMessage(updatedMessages)
            
            val aiMessage = ChatMessage(
                id = UUID.randomUUID().toString(),
                role = "assistant",
                content = responseText,
                timestamp = System.currentTimeMillis()
            )

            val finalMessages = _messages.value + aiMessage
            _messages.value = finalMessages
            saveHistory(finalMessages)
            
            _isLoading.value = false
        }
    }

    fun clearHistory() {
        viewModelScope.launch {
            repository.clearHistory()
            _messages.value = emptyList()
        }
    }

    private fun saveHistory(messagesList: List<ChatMessage>) {
        viewModelScope.launch {
            repository.saveHistory(ChatHistory(messagesList))
        }
    }
}
