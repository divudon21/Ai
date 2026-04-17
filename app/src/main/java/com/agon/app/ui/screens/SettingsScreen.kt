package com.agon.app.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen() {
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Settings") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.primaryContainer,
                    titleContentColor = MaterialTheme.colorScheme.onPrimaryContainer
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            ListItem(
                headlineContent = { Text("Model Info") },
                supportingContent = { Text("Qwen/Qwen3.5-122B-A10B") },
                leadingContent = { Icon(Icons.Default.Info, contentDescription = null) }
            )
            HorizontalDivider()
            ListItem(
                headlineContent = { Text("Account") },
                supportingContent = { Text("GitHub API configured") },
                leadingContent = { Icon(Icons.Default.Person, contentDescription = null) }
            )
            HorizontalDivider()
            ListItem(
                headlineContent = { Text("App Version") },
                supportingContent = { Text("1.0.0") },
                leadingContent = { Icon(Icons.Default.Settings, contentDescription = null) }
            )
        }
    }
}
