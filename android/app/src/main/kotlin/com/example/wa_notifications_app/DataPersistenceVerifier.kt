package com.example.wa_notifications_app

import android.content.Context
import android.content.SharedPreferences
import android.util.Log

/**
 * Comprehensive debugging tool to verify data persistence between Flutter and native code
 */
object DataPersistenceVerifier {
    
    private const val TAG = "DataVerifier"
    
    // Keys that match both Flutter and native code
    private const val SELECTED_GROUPS_KEY = "selected_groups"
    private const val SELECTED_GROUPS_JSON_KEY = "selected_groups_json"
    private const val SCHEDULE_START_HOUR_KEY = "schedule_start_hour"
    private const val SCHEDULE_START_MINUTE_KEY = "schedule_start_minute"
    private const val SCHEDULE_END_HOUR_KEY = "schedule_end_hour"
    private const val SCHEDULE_END_MINUTE_KEY = "schedule_end_minute"
    
    /**
     * Comprehensive debug function to check all data persistence locations
     */
    fun debugAllDataPersistence(context: Context) {
        Log.d(TAG, "🔍 ==================================================")
        Log.d(TAG, "🔍 DATA PERSISTENCE VERIFICATION START")
        Log.d(TAG, "🔍 ==================================================")
        
        val possiblePrefsNames = arrayOf(
            "SharedPreferences",  // Native bridge location
            "${context.packageName}_preferences",  // Package-specific
            "flutter_shared_preferences",  // Original approach
            "com.example.wa_notifications_app_preferences"  // Full package name
        )
        
        for (prefsName in possiblePrefsNames) {
            debugSharedPreferencesFile(context, prefsName)
        }
        
        Log.d(TAG, "🔍 ==================================================")
        Log.d(TAG, "🔍 DATA PERSISTENCE VERIFICATION COMPLETE")
        Log.d(TAG, "🔍 ==================================================")
    }
    
    /**
     * Debug a specific SharedPreferences file
     */
    private fun debugSharedPreferencesFile(context: Context, prefsName: String) {
        Log.d(TAG, "📁 Analyzing SharedPreferences file: $prefsName")
        
        try {
            val prefs = context.getSharedPreferences(prefsName, Context.MODE_PRIVATE)
            
            // Check all possible keys
            val allKeys = prefs.all?.keys ?: emptySet()
            Log.d(TAG, "📝 All keys in $prefsName: ${allKeys.joinToString(", ")}")
            
            // Check selected groups data
            debugSelectedGroups(prefs, prefsName)
            
            // Check schedule data
            debugSchedule(prefs, prefsName)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error accessing $prefsName: $e")
        }
        
        Log.d(TAG, "")
    }
    
    /**
     * Debug selected groups data in a SharedPreferences file
     */
    private fun debugSelectedGroups(prefs: SharedPreferences, prefsName: String) {
        Log.d(TAG, "🔍 Checking selected groups in $prefsName...")
        
        // Method 1: Try StringSet (preferred by native bridge)
        try {
            val groupsSet = prefs.getStringSet(SELECTED_GROUPS_KEY, null)
            if (groupsSet != null && groupsSet.isNotEmpty()) {
                Log.d(TAG, "✅ FOUND via StringSet: ${groupsSet.toList()}")
                Log.d(TAG, "✅ StringSet size: ${groupsSet.size}")
                Log.d(TAG, "✅ StringSet contents: ${groupsSet.joinToString(", ")}")
            } else {
                Log.d(TAG, "⚠️ No StringSet data found")
            }
        } catch (e: ClassCastException) {
            Log.d(TAG, "⚠️ StringSet cast failed (data might be saved as String): $e")
        } catch (e: Exception) {
            Log.d(TAG, "⚠️ Error reading StringSet: $e")
        }
        
        // Method 2: Try String (fallback)
        try {
            val groupsString = prefs.getString(SELECTED_GROUPS_KEY, null)
            if (!groupsString.isNullOrEmpty()) {
                Log.d(TAG, "✅ FOUND via String: $groupsString")
                
                // Try to parse as JSON
                if (groupsString.startsWith("[") && groupsString.endsWith("]")) {
                    try {
                        val jsonArray = org.json.JSONArray(groupsString)
                        val parsedGroups = mutableListOf<String>()
                        for (i in 0 until jsonArray.length()) {
                            parsedGroups.add(jsonArray.getString(i))
                        }
                        Log.d(TAG, "✅ Parsed JSON array: ${parsedGroups.joinToString(", ")}")
                    } catch (e: Exception) {
                        Log.d(TAG, "⚠️ Failed to parse JSON: $e")
                    }
                }
            } else {
                Log.d(TAG, "⚠️ No String data found")
            }
        } catch (e: ClassCastException) {
            Log.d(TAG, "⚠️ String cast failed (data might be saved as StringSet): $e")
        } catch (e: Exception) {
            Log.d(TAG, "⚠️ Error reading String: $e")
        }
        
        // Method 3: Check JSON string backup
        try {
            val groupsJsonString = prefs.getString(SELECTED_GROUPS_JSON_KEY, null)
            if (!groupsJsonString.isNullOrEmpty()) {
                Log.d(TAG, "✅ FOUND JSON backup: $groupsJsonString")
            } else {
                Log.d(TAG, "⚠️ No JSON backup found")
            }
        } catch (e: Exception) {
            Log.d(TAG, "⚠️ Error reading JSON backup: $e")
        }
    }
    
    /**
     * Debug schedule data in a SharedPreferences file
     */
    private fun debugSchedule(prefs: SharedPreferences, prefsName: String) {
        Log.d(TAG, "🔍 Checking schedule in $prefsName...")
        
        val startHour = prefs.getInt(SCHEDULE_START_HOUR_KEY, -1)
        val startMinute = prefs.getInt(SCHEDULE_START_MINUTE_KEY, -1)
        val endHour = prefs.getInt(SCHEDULE_END_HOUR_KEY, -1)
        val endMinute = prefs.getInt(SCHEDULE_END_MINUTE_KEY, -1)
        
        if (startHour >= 0 && startMinute >= 0 && endHour >= 0 && endMinute >= 0) {
            Log.d(TAG, "✅ FOUND schedule: ${String.format("%02d:%02d - %02d:%02d", startHour, startMinute, endHour, endMinute)}")
        } else {
            Log.d(TAG, "⚠️ No complete schedule found (startHour=$startHour, startMinute=$startMinute, endHour=$endHour, endMinute=$endMinute)")
        }
    }
    
    /**
     * Force save test data to verify the bridge works
     */
    fun saveTestData(context: Context) {
        Log.d(TAG, "🧪 SAVING TEST DATA...")
        
        try {
            val prefs = context.getSharedPreferences("SharedPreferences", Context.MODE_PRIVATE)
            val editor = prefs.edit()
            
            // Save test groups
            val testGroups = setOf("Test Group 1", "Work Group", "Family Group")
            editor.putStringSet(SELECTED_GROUPS_KEY, testGroups)
            
            // Save test schedule (22:00 to 08:00)
            editor.putInt(SCHEDULE_START_HOUR_KEY, 22)
            editor.putInt(SCHEDULE_START_MINUTE_KEY, 0)
            editor.putInt(SCHEDULE_END_HOUR_KEY, 8)
            editor.putInt(SCHEDULE_END_MINUTE_KEY, 0)
            
            editor.apply()
            
            Log.d(TAG, "✅ Test data saved successfully")
            Log.d(TAG, "📝 Test groups: ${testGroups.joinToString(", ")}")
            Log.d(TAG, "⏰ Test schedule: 22:00 - 08:00")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error saving test data: $e")
        }
    }
    
    /**
     * Clear all test data
     */
    fun clearTestData(context: Context) {
        Log.d(TAG, "🧹 CLEARING TEST DATA...")
        
        try {
            val prefs = context.getSharedPreferences("SharedPreferences", Context.MODE_PRIVATE)
            val editor = prefs.edit()
            
            editor.remove(SELECTED_GROUPS_KEY)
            editor.remove(SELECTED_GROUPS_JSON_KEY)
            editor.remove(SCHEDULE_START_HOUR_KEY)
            editor.remove(SCHEDULE_START_MINUTE_KEY)
            editor.remove(SCHEDULE_END_HOUR_KEY)
            editor.remove(SCHEDULE_END_MINUTE_KEY)
            
            editor.apply()
            
            Log.d(TAG, "✅ Test data cleared successfully")
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ Error clearing test data: $e")
        }
    }
}