package com.agon.app.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.agon.app.data.ChatMessage
import com.agon.app.viewmodel.ChatViewModel
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen(
    viewModel: ChatViewModel = viewModel()
) {
    val messages by viewModel.messages.collectAsState()
    val isLoading by viewModel.isLoading.collectAsState()
    var textState by remember { mutableStateOf(TextFieldValue("")) }
    val listState = rememberLazyListState()

    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty()) {
            listState.animateScrollToItem(messages.size - 1)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Ghost AI") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                ),
                actions = {
                    TextButton(onClick = { viewModel.clearHistory() }) {
                        Text("Clear")
                    }
                }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            LazyColumn(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp),
                state = listState,
                contentPadding = PaddingValues(vertical = 16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(messages) { message ->
                    MessageBubble(message = message)
                }
                if (isLoading) {
                    item {
                        Box(
                            modifier = Modifier.fillMaxWidth(),
                            contentAlignment = Alignment.Center
                        ) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(24.dp),
                                strokeWidth = 2.dp
                            )
                        }
                    }
                }
            }

            Surface(
                color = MaterialTheme.colorScheme.surfaceVariant,
                tonalElevation = 2.dp
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    OutlinedTextField(
                        value = textState,
                        onValueChange = { textState = it },
                        modifier = Modifier
                            .weight(1f)
                            .padding(end = 8.dp),
                        placeholder = { Text("Ask Ghost AI...") },
                        maxLines = 4,
                        shape = RoundedCornerShape(24.dp),
                        colors = OutlinedTextFieldDefaults.colors(
                            unfocusedBorderColor = Color.Transparent,
                            focusedBorderColor = Color.Transparent
                        )
                    )
                    
                    IconButton(
                        onClick = {
                            if (textState.text.isNotBlank()) {
                                viewModel.sendMessage(textState.text)
                                textState = TextFieldValue("")
                            }
                        },
                        enabled = !isLoading && textState.text.isNotBlank(),
                        modifier = Modifier
                            .size(48.dp)
                            .clip(RoundedCornerShape(24.dp))
                            .background(if (textState.text.isNotBlank() && !isLoading) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.surface)
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.Send,
                            contentDescription = "Send",
                            tint = if (textState.text.isNotBlank() && !isLoading) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun MessageBubble(message: ChatMessage) {
    val isUser = message.role == "user"
    val backgroundColor = if (isUser) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.secondaryContainer
    val textColor = if (isUser) MaterialTheme.colorScheme.onPrimary else MaterialTheme.colorScheme.onSecondaryContainer
    val alignment = if (isUser) Alignment.CenterEnd else Alignment.CenterStart
    val shape = if (isUser) {
        RoundedCornerShape(16.dp, 16.dp, 0.dp, 16.dp)
    } else {
        RoundedCornerShape(16.dp, 16.dp, 16.dp, 0.dp)
    }

    Box(
        modifier = Modifier.fillMaxWidth(),
        contentAlignment = alignment
    ) {
        Column(
            horizontalAlignment = if (isUser) Alignment.End else Alignment.Start,
            modifier = Modifier.fillMaxWidth(0.85f)
        ) {
            Surface(
                color = backgroundColor,
                shape = shape,
                shadowElevation = 1.dp
            ) {
                Text(
                    text = message.content,
                    color = textColor,
                    modifier = Modifier.padding(12.dp),
                    style = MaterialTheme.typography.bodyLarge
                )
            }
            Text(
                text = formatTime(message.timestamp),
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                modifier = Modifier.padding(top = 4.dp, start = 4.dp, end = 4.dp)
            )
        }
    }
}

private fun formatTime(timestamp: Long): String {
    val sdf = SimpleDateFormat("h:mm a", Locale.getDefault())
    return sdf.format(Date(timestamp))
}
