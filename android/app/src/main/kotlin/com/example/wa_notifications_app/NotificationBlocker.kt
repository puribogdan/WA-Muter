package com.example.wa_notifications_app

import android.content.Context
import android.util.Log
import java.util.Calendar

/**
 * Native notification blocking evaluator.
 * Uses native SharedPreferences ("SharedPreferences") as the source of truth.
 */
object NotificationBlocker {

    private const val TAG = "NotificationBlocker"

    private const val PREFS_NAME = "SharedPreferences"
    private const val SCHEDULES_KEY = "schedules_v1"

    private const val WHATSAPP_PACKAGE = "com.whatsapp"
    private const val WHATSAPP_BUSINESS_PACKAGE = "com.whatsapp.w4b"

    data class ScheduleData(
        val id: String,
        val name: String,
        val startHour: Int,
        val startMinute: Int,
        val endHour: Int,
        val endMinute: Int,
        val days: Set<Int>,
        val groups: List<String>,
        val enabled: Boolean,
    )

    fun shouldBlockNotification(context: Context, packageName: String?, title: String?): Boolean {
        if (!isWhatsAppNotification(packageName)) return false
        val notificationTitle = title?.trim().orEmpty()
        if (notificationTitle.isEmpty()) return false

        return try {
            val schedules = getSchedules(context)
            if (schedules.isEmpty()) return false

            val now = Calendar.getInstance()
            schedules.any { schedule ->
                schedule.enabled &&
                    isScheduleActiveAt(schedule, now) &&
                    titleMatchesAnyGroup(notificationTitle, schedule.groups)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error evaluating notification block rules", e)
            false
        }
    }

    fun blockNotification(notificationEvent: NotificationEvent): Boolean {
        try {
            val actions = notificationEvent.data["actions"] as? List<*> ?: return false
            if (actions.isEmpty()) return false

            val notificationActions = notificationEvent.mSbn.notification.actions ?: return false
            for (action in actions) {
                if (action !is Map<*, *>) continue
                val actionTitle = action["title"] as? String ?: continue
                val semantic = action["semantic"] as? Int ?: -1
                if (semantic != 2) continue

                for (nativeAction in notificationActions) {
                    if (nativeAction.semanticAction == 2 && nativeAction.title.toString() == actionTitle) {
                        nativeAction.actionIntent.send()
                        return true
                    }
                }
            }
            return false
        } catch (e: Exception) {
            Log.e(TAG, "Error blocking notification", e)
            return false
        }
    }

    fun logDebugState(context: Context) {
        try {
            val schedules = getSchedules(context)
            Log.d(TAG, "Native schedules: ${schedules.size}")
            schedules.forEach { schedule ->
                Log.d(
                    TAG,
                    "Schedule ${schedule.name} enabled=${schedule.enabled} days=${schedule.days} " +
                        "time=${"%02d".format(schedule.startHour)}:${"%02d".format(schedule.startMinute)}-" +
                        "${"%02d".format(schedule.endHour)}:${"%02d".format(schedule.endMinute)} groups=${schedule.groups.size}"
                )
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error logging debug state", e)
        }
    }

    private fun isWhatsAppNotification(packageName: String?): Boolean {
        return packageName == WHATSAPP_PACKAGE || packageName == WHATSAPP_BUSINESS_PACKAGE
    }

    private fun titleMatchesAnyGroup(title: String, groups: List<String>): Boolean {
        val normalizedTitle = normalizeText(title)
        return groups.any { group ->
            val normalizedGroup = normalizeText(group)
            normalizedGroup.isNotEmpty() && matchesGroupTitle(normalizedTitle, normalizedGroup)
        }
    }

    private fun matchesGroupTitle(normalizedTitle: String, normalizedGroup: String): Boolean {
        if (normalizedTitle == normalizedGroup) return true
        if (normalizedTitle.startsWith("$normalizedGroup:")) return true
        if (normalizedTitle.startsWith("$normalizedGroup (")) return true
        if (normalizedTitle.contains(" in $normalizedGroup")) return true
        return false
    }

    private fun normalizeText(value: String): String {
        return value.trim()
            .lowercase()
            .replace(Regex("\\s+"), " ")
    }

    private fun isScheduleActiveAt(schedule: ScheduleData, now: Calendar): Boolean {
        val nowMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        val startMinutes = schedule.startHour * 60 + schedule.startMinute
        val endMinutes = schedule.endHour * 60 + schedule.endMinute

        val isOvernight = startMinutes > endMinutes
        val today = normalizeDay(now.get(Calendar.DAY_OF_WEEK))
        val previousDay = if (today == 1) 7 else today - 1

        if (!isOvernight) {
            return schedule.days.contains(today) &&
                nowMinutes >= startMinutes &&
                nowMinutes < endMinutes
        }

        return if (nowMinutes >= startMinutes) {
            schedule.days.contains(today)
        } else {
            schedule.days.contains(previousDay) && nowMinutes < endMinutes
        }
    }

    private fun normalizeDay(calendarDay: Int): Int {
        return when (calendarDay) {
            Calendar.MONDAY -> 1
            Calendar.TUESDAY -> 2
            Calendar.WEDNESDAY -> 3
            Calendar.THURSDAY -> 4
            Calendar.FRIDAY -> 5
            Calendar.SATURDAY -> 6
            Calendar.SUNDAY -> 7
            else -> 1
        }
    }

    private fun getSchedules(context: Context): List<ScheduleData> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val raw = prefs.getString(SCHEDULES_KEY, "[]") ?: "[]"
        val array = org.json.JSONArray(raw)
        val result = mutableListOf<ScheduleData>()

        for (i in 0 until array.length()) {
            val item = array.optJSONObject(i) ?: continue

            val daysArray = item.optJSONArray("days") ?: org.json.JSONArray()
            val days = mutableSetOf<Int>()
            for (d in 0 until daysArray.length()) {
                val day = daysArray.optInt(d, 0)
                if (day in 1..7) days.add(day)
            }
            if (days.isEmpty()) continue

            val groupsArray = item.optJSONArray("groups") ?: org.json.JSONArray()
            val groups = mutableListOf<String>()
            for (g in 0 until groupsArray.length()) {
                val value = groupsArray.optString(g, "").trim()
                if (value.isNotEmpty()) groups.add(value)
            }
            if (groups.isEmpty()) continue

            val startHour = item.optInt("startHour", -1)
            val startMinute = item.optInt("startMinute", -1)
            val endHour = item.optInt("endHour", -1)
            val endMinute = item.optInt("endMinute", -1)

            if (startHour !in 0..23 || endHour !in 0..23 || startMinute !in 0..59 || endMinute !in 0..59) {
                continue
            }

            result.add(
                ScheduleData(
                    id = item.optString("id", ""),
                    name = item.optString("name", "Schedule"),
                    startHour = startHour,
                    startMinute = startMinute,
                    endHour = endHour,
                    endMinute = endMinute,
                    days = days,
                    groups = groups,
                    enabled = item.optBoolean("enabled", true),
                )
            )
        }

        return result
    }
}
