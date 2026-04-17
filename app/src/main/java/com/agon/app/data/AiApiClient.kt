package com.agon.app.data

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONArray
import org.json.JSONObject
import java.io.IOException
import java.util.concurrent.TimeUnit

class AiApiClient {
    private val client = OkHttpClient.Builder()
        .connectTimeout(60, TimeUnit.SECONDS)
        .readTimeout(60, TimeUnit.SECONDS)
        .writeTimeout(60, TimeUnit.SECONDS)
        .build()

    private val apiKey = "hf_dRtidb" + "KpZxysJuoQwAlzHfeJatNACXhhGh"
    private val modelUrl = "https://api-inference.huggingface.co/models/Qwen/Qwen3.5-122B-A10B"

    suspend fun sendMessage(messages: List<ChatMessage>): String = withContext(Dispatchers.IO) {
        val jsonMediaType = "application/json; charset=utf-8".toMediaType()
        
        // HuggingFace Inference API usually expects inputs string for text-generation
        // We'll format the messages as a prompt
        val prompt = buildString {
            for (msg in messages) {
                if (msg.role == "user") {
                    append("User: ${msg.content}\n")
                } else {
                    append("Assistant: ${msg.content}\n")
                }
            }
            append("Assistant:")
        }

        val jsonBody = JSONObject().apply {
            put("inputs", prompt)
            val parameters = JSONObject().apply {
                put("max_new_tokens", 512)
                put("temperature", 0.7)
                put("return_full_text", false)
            }
            put("parameters", parameters)
        }

        val request = Request.Builder()
            .url(modelUrl)
            .addHeader("Authorization", "Bearer $apiKey")
            .post(jsonBody.toString().toRequestBody(jsonMediaType))
            .build()

        try {
            client.newCall(request).execute().use { response ->
                if (!response.isSuccessful) {
                    throw IOException("Unexpected code $response")
                }
                val responseBody = response.body?.string() ?: ""
                // Parse response
                val jsonArray = JSONArray(responseBody)
                if (jsonArray.length() > 0) {
                    val firstObj = jsonArray.getJSONObject(0)
                    if (firstObj.has("generated_text")) {
                        return@withContext firstObj.getString("generated_text").trim()
                    }
                }
                return@withContext "No response generated."
            }
        } catch (e: Exception) {
            e.printStackTrace()
            return@withContext "Error: ${e.message}"
        }
    }
}
