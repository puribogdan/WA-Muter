package com.example.wa_notifications_app

import android.content.Context
import android.content.SharedPreferences
import android.content.pm.ApplicationInfo
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Bridge to save data in SharedPreferences that both Flutter and native code can access
 */
class NativePreferencesBridge {
    
    companion object {
        private const val TAG = "NativePreferencesBridge"
        private const val CHANNEL_NAME = "flutter_notification_listener/native_prefs"
        private const val MUTE_LOG_EVENT_CHANNEL = "flutter_notification_listener/mute_log_events"
        private const val PREFS_NAME = "SharedPreferences"
        private const val MUTE_LOGS_KEY = "mute_logs_json"
        private const val SCHEDULES_KEY = "schedules_v1"
        private const val APP_SETTINGS_KEY = "app_settings_v1"
        private const val MUTE_LOG_MAX = 300

        @Volatile
        private var muteLogEventSink: EventChannel.EventSink? = null
        
        fun setupChannel(flutterEngine: FlutterEngine, context: Context) {
            val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
            val eventChannel = EventChannel(
                flutterEngine.dartExecutor.binaryMessenger,
                MUTE_LOG_EVENT_CHANNEL
            )

            eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    muteLogEventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    muteLogEventSink = null
                }
            })
            
            methodChannel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "saveMutedGroups" -> {
                        try {
                            val groups = call.argument<List<String>>("groups") ?: emptyList()
                            saveMutedGroups(context, groups)
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error saving muted groups: $e")
                            result.error("SAVE_GROUPS_ERROR", e.message, null)
                        }
                    }
                    "saveSchedule" -> {
                        try {
                            val schedule = call.arguments as? Map<String, Any>
                            if (schedule != null) {
                                saveSchedule(context, schedule)
                                result.success(true)
                            } else {
                                result.error("INVALID_SCHEDULE", "Schedule data is null", null)
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "Error saving schedule: $e")
                            result.error("SAVE_SCHEDULE_ERROR", e.message, null)
                        }
                    }
                    "getSchedule" -> {
                        try {
                            val schedule = getSchedule(context)
                            result.success(schedule)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error getting schedule: $e")
                            result.error("GET_SCHEDULE_ERROR", e.message, null)
                        }
                    }
                    "getMutedGroups" -> {
                        try {
                            val groups = getMutedGroups(context)
                            result.success(groups)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error getting muted groups: $e")
                            result.error("GET_GROUPS_ERROR", e.message, null)
                        }
                    }
                    "saveMuteLog" -> {
                        try {
                            val groupName = call.argument<String>("groupName") ?: ""
                            val status = call.argument<String>("status") ?: "Muted"
                            appendMuteLog(context, groupName, status)
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error saving mute log: $e")
                            result.error("SAVE_MUTE_LOG_ERROR", e.message, null)
                        }
                    }
                    "saveSchedules" -> {
                        try {
                            val schedulesJson = call.argument<String>("schedulesJson") ?: "[]"
                            saveSchedulesJson(context, schedulesJson)
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error saving schedules json: $e")
                            result.error("SAVE_SCHEDULES_ERROR", e.message, null)
                        }
                    }
                    "saveAppSettings" -> {
                        try {
                            val settingsJson = call.argument<String>("settingsJson") ?: "{}"
                            saveAppSettingsJson(context, settingsJson)
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error saving app settings json: $e")
                            result.error("SAVE_APP_SETTINGS_ERROR", e.message, null)
                        }
                    }
                    "getMuteLogs" -> {
                        try {
                            result.success(getMuteLogs(context))
                        } catch (e: Exception) {
                            Log.e(TAG, "Error getting mute logs: $e")
                            result.error("GET_MUTE_LOGS_ERROR", e.message, null)
                        }
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }
        
        private fun saveMutedGroups(context: Context, groups: List<String>) {
            try {
                // Save to "SharedPreferences" file that native code can access
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val editor = prefs.edit()
                
                // Save as StringSet
                val groupsSet = groups.toSet()
                editor.putStringSet("selected_groups", groupsSet)
                
                // Save as JSON string for additional compatibility
                val groupsJson = org.json.JSONArray(groups)
                editor.putString("selected_groups_json", groupsJson.toString())
                
                editor.apply()
                
                Log.d(TAG, "âœ… Saved ${groups.size} muted groups to native-accessible location")
                Log.d(TAG, "ðŸ“ Groups: ${groups.joinToString(", ")}")
                
            } catch (e: Exception) {
                Log.e(TAG, "âŒ Error saving muted groups: $e")
            }
        }
        
        private fun saveSchedule(context: Context, schedule: Map<String, Any>) {
            try {
                // Save to "SharedPreferences" file that native code can access
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val editor = prefs.edit()
                
                val startHour = schedule["startHour"] as? Int ?: -1
                val startMinute = schedule["startMinute"] as? Int ?: -1
                val endHour = schedule["endHour"] as? Int ?: -1
                val endMinute = schedule["endMinute"] as? Int ?: -1
                
                editor.putInt("schedule_start_hour", startHour)
                editor.putInt("schedule_start_minute", startMinute)
                editor.putInt("schedule_end_hour", endHour)
                editor.putInt("schedule_end_minute", endMinute)
                editor.putBoolean("has_partial_schedule", true)
                
                editor.apply()
                
                Log.d(TAG, "âœ… Saved schedule: $startHour:$startMinute - $endHour:$endMinute")
                
            } catch (e: Exception) {
                Log.e(TAG, "âŒ Error saving schedule: $e")
            }
        }
        
        /**
         * Get schedule from SharedPreferences
         * Returns null if no schedule is set, otherwise returns Map with schedule data
         */
        private fun getSchedule(context: Context): Map<String, Any>? {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                
                val startHour = prefs.getInt("schedule_start_hour", -1)
                val startMinute = prefs.getInt("schedule_start_minute", -1)
                val endHour = prefs.getInt("schedule_end_hour", -1)
                val endMinute = prefs.getInt("schedule_end_minute", -1)
                val hasPartial = prefs.getBoolean("has_partial_schedule", false)
                
                // Check if all values are present and valid
                if (hasPartial && startHour >= 0 && startMinute >= 0 && endHour >= 0 && endMinute >= 0) {
                    val scheduleMap = mapOf(
                        "startHour" to startHour,
                        "startMinute" to startMinute,
                        "endHour" to endHour,
                        "endMinute" to endMinute
                    )
                    Log.d(TAG, "âœ… Retrieved schedule: $startHour:$startMinute - $endHour:$endMinute")
                    return scheduleMap
                }
                
                Log.d(TAG, "ðŸ“ No complete schedule found in native storage")
                return null
                
            } catch (e: Exception) {
                Log.e(TAG, "âŒ Error getting schedule: $e")
                return null
            }
        }
        
        /**
         * Get muted groups from SharedPreferences
         * Returns empty list if no groups are found
         */
        private fun getMutedGroups(context: Context): List<String> {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                
                // Try to get StringSet first
                val groupsSet = prefs.getStringSet("selected_groups", emptySet())
                if (groupsSet != null && groupsSet.isNotEmpty()) {
                    val groupsList = groupsSet.toList()
                    Log.d(TAG, "âœ… Retrieved ${groupsList.size} muted groups from native storage")
                    Log.d(TAG, "ðŸ“ Groups: ${groupsList.joinToString(", ")}")
                    return groupsList
                }
                
                // Fallback to JSON string if StringSet is not available
                val groupsJson = prefs.getString("selected_groups_json", null)
                if (!groupsJson.isNullOrEmpty()) {
                    try {
                        val jsonArray = org.json.JSONArray(groupsJson)
                        val groupsList = mutableListOf<String>()
                        for (i in 0 until jsonArray.length()) {
                            groupsList.add(jsonArray.getString(i))
                        }
                        if (groupsList.isNotEmpty()) {
                            Log.d(TAG, "âœ… Retrieved ${groupsList.size} muted groups from JSON in native storage")
                            Log.d(TAG, "ðŸ“ Groups: ${groupsList.joinToString(", ")}")
                            return groupsList
                        }
                    } catch (e: Exception) {
                        Log.d(TAG, "âš ï¸ Failed to parse groups JSON: $groupsJson")
                    }
                }
                
                Log.d(TAG, "ðŸ“ No muted groups found in native storage")
                return emptyList()
                
            } catch (e: Exception) {
                Log.e(TAG, "âŒ Error getting muted groups: $e")
                return emptyList()
            }
        }

        private fun saveSchedulesJson(context: Context, schedulesJson: String) {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit().putString(SCHEDULES_KEY, schedulesJson).apply()
            } catch (e: Exception) {
                Log.e(TAG, "Error saving schedules json: $e")
            }
        }

        private fun saveAppSettingsJson(context: Context, settingsJson: String) {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                prefs.edit().putString(APP_SETTINGS_KEY, settingsJson).apply()
            } catch (e: Exception) {
                Log.e(TAG, "Error saving app settings json: $e")
            }
        }

        fun shouldKeepMuteLog(context: Context): Boolean {
            return try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val raw = prefs.getString(APP_SETTINGS_KEY, "{}") ?: "{}"
                val obj = org.json.JSONObject(raw)
                obj.optBoolean("keepMutedLog", true)
            } catch (_: Exception) {
                true
            }
        }

        fun appendMuteLog(context: Context, groupName: String, status: String) {
            try {
                val trimmed = groupName.trim()
                if (trimmed.isEmpty()) return

                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val existingRaw = prefs.getString(MUTE_LOGS_KEY, "[]") ?: "[]"
                val array = org.json.JSONArray(existingRaw)

                val entry = org.json.JSONObject()
                entry.put("timestamp", System.currentTimeMillis())
                entry.put("groupName", trimmed)
                entry.put("status", status)
                val updated = org.json.JSONArray()
                updated.put(entry)
                for (i in 0 until array.length()) {
                    if (updated.length() >= MUTE_LOG_MAX) break
                    updated.put(array.get(i))
                }

                prefs.edit().putString(MUTE_LOGS_KEY, updated.toString()).apply()
                if (isDebugLoggingEnabled(context)) {
                    Log.d(TAG, "Saved mute log: $trimmed ($status)")
                }
                emitMuteLogEvent(
                    mapOf(
                        "timestamp" to System.currentTimeMillis(),
                        "groupName" to trimmed,
                        "status" to status,
                    )
                )
            } catch (e: Exception) {
                Log.e(TAG, "âŒ Error appending mute log: $e")
            }
        }

        private fun emitMuteLogEvent(payload: Map<String, Any>) {
            val sink = muteLogEventSink ?: return
            Handler(Looper.getMainLooper()).post {
                try {
                    sink.success(payload)
                } catch (_: Exception) {
                    // No-op if stream listener has detached.
                }
            }
        }
        private fun isDebugLoggingEnabled(context: Context): Boolean {
            return (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        }

        private fun getMuteLogs(context: Context): List<Map<String, Any>> {
            val result = mutableListOf<Map<String, Any>>()
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val existingRaw = prefs.getString(MUTE_LOGS_KEY, "[]") ?: "[]"
                val array = org.json.JSONArray(existingRaw)
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    result.add(
                        mapOf(
                            "timestamp" to obj.optLong("timestamp", 0L),
                            "groupName" to obj.optString("groupName", "Unknown"),
                            "status" to obj.optString("status", "Muted"),
                        )
                    )
                }
            } catch (e: Exception) {
                Log.e(TAG, "âŒ Error reading mute logs: $e")
            }
            return result
        }
    }
}

