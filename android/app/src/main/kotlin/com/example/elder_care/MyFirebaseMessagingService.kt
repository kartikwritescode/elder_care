package com.example.elder_care

import android.app.ActivityManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Intent
import android.media.AudioAttributes
import android.os.Build
import android.provider.Settings
import android.util.Log
import androidx.core.app.NotificationCompat
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import org.json.JSONArray
import org.json.JSONException

class MyFirebaseMessagingService : FirebaseMessagingService() {
    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        Log.d("FCM_DEBUG", "🔔 Message received from: ${remoteMessage.from}")
        
        createChannels()

        val data = remoteMessage.data
        if (data.isNotEmpty()) {
            val type = data["type"]
            Log.d("FCM_DEBUG", "Payload type: $type")

            when (type) {
                "schedule_alarm" -> {
                    val alarmId = data["alarm_id"] ?: return
                    val alarmTime = data["alarm_time"]?.toLongOrNull() ?: return
                    val title = data["title"]?.trim()?.takeIf { it.isNotEmpty() } ?: "Task Reminder"
                    val dosage = data["dosage"]
                    val instructions = data["instructions"]
                    val repeatType = data["repeat_type"] ?: "none"
                    val repeatDaysStr = data["repeat_days"] ?: "[]"
                    
                    val repeatDays = try {
                        val arr = JSONArray(repeatDaysStr)
                        val list = mutableListOf<String>()
                        for (i in 0 until arr.length()) {
                            list.add(arr.getString(i))
                        }
                        list
                    } catch (e: JSONException) {
                        emptyList<String>()
                    }
                    
                    Log.d("FCM_DEBUG", "Scheduling local alarm: $alarmId at $alarmTime")
                    AlarmScheduler.schedule(
                        this, 
                        alarmId, 
                        alarmTime, 
                        title, 
                        dosage, 
                        instructions, 
                        repeatType, 
                        repeatDays
                    )
                    
                    val advanceTime = alarmTime - (10 * 60 * 1000)
                    if (advanceTime > System.currentTimeMillis() && repeatType == "none") {
                        AlarmScheduler.scheduleAdvanceNotification(this, alarmId, advanceTime, title)
                    }
                }
                "cancel_alarm" -> {
                    val alarmId = data["alarm_id"] ?: return
                    Log.d("FCM_DEBUG", "Cancelling local alarm: $alarmId")
                    AlarmScheduler.cancel(this, alarmId)
                }
                "sos" -> {
                    showFullScreenAlarm("SOS", "EMERGENCY ALERT", true)
                }
                "chat" -> {
                    // Only show standard notification if not already handled by FCM system tray
                    // (when remoteMessage.notification is present) and not in foreground
                    // (when Flutter's onMessage handles it).
                    if (remoteMessage.notification == null && !isForeground()) {
                        val senderName = data["sender_name"]?.trim()?.takeIf { it.isNotEmpty() }
                            ?: data["title"]?.trim()?.takeIf { it.isNotEmpty() }
                            ?: "New Message"
                        val messageText = data["message"]?.trim()?.takeIf { it.isNotEmpty() }
                            ?: data["body"]?.trim()?.takeIf { it.isNotEmpty() }
                            ?: "You received a chat message"
                        showStandardNotification(
                            "chat_channel",
                            senderName,
                            messageText,
                            data["chat_id"]
                        )
                    } else {
                        Log.d("FCM_DEBUG", "Skipping native chat notification to prevent duplicate (inForeground=${isForeground()}, hasNotification=${remoteMessage.notification != null})")
                    }
                }
                "mood_update", "location_alert", "event_update" -> {
                    if (remoteMessage.notification == null && !isForeground()) {
                        val title = data["title"]?.trim()?.takeIf { it.isNotEmpty() } ?: "Update"
                        val body = data["body"]?.trim()?.takeIf { it.isNotEmpty() } ?: "Update detected"
                        showStandardNotification(
                            "update_channel",
                            title,
                            body,
                            null
                        )
                    } else {
                        Log.d("FCM_DEBUG", "Skipping native update notification to prevent duplicate (inForeground=${isForeground()}, hasNotification=${remoteMessage.notification != null})")
                    }
                }
            }
        }
    }

    private fun isForeground(): Boolean {
        if (MainActivity.isAppInForeground) return true
        return try {
            val am = getSystemService(ACTIVITY_SERVICE) as? ActivityManager ?: return false
            val processes = am.runningAppProcesses ?: return false
            val pkg = packageName
            processes.any {
                it.importance == ActivityManager.RunningAppProcessInfo.IMPORTANCE_FOREGROUND &&
                        it.processName == pkg
            }
        } catch (e: Exception) {
            false
        }
    }

    private fun showFullScreenAlarm(alarmId: String, title: String, isSOS: Boolean) {
        val safeTitle = if (title.isNotBlank()) title.trim() else (if (isSOS) "EMERGENCY ALERT" else "Medicine Reminder")

        val intent = Intent(this, AlarmActivity::class.java).apply {
            putExtra("alarm_id", alarmId)
            putExtra("alarm_title", safeTitle)
            putExtra("is_sos", isSOS)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            alarmId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, ALARM_CHANNEL)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(safeTitle)
            .setContentText(if (isSOS) "EMERGENCY - Tap to Respond" else "Time for your task")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(pendingIntent, true)
            .setOngoing(true)
            .setAutoCancel(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(alarmId.hashCode(), builder.build())
    }

    private fun showStandardNotification(channelId: String, title: String, body: String, extraId: String?) {
        val trimmedTitle = title.trim()
        val trimmedBody = body.trim()

        // NEVER show blank notifications
        if (trimmedTitle.isEmpty() && trimmedBody.isEmpty()) {
            Log.w("FCM_DEBUG", "⚠️ Skipping blank notification: both title and body are empty")
            return
        }

        val safeTitle = if (trimmedTitle.isNotEmpty()) trimmedTitle else "ElderCare"
        val safeBody = if (trimmedBody.isNotEmpty()) trimmedBody else "You have a new notification"

        val intent = Intent(this, MainActivity::class.java).apply {
            putExtra("extra_id", extraId)
            addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            (safeTitle + safeBody).hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, channelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(safeTitle)
            .setContentText(safeBody)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)

        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        manager.notify((safeTitle + safeBody).hashCode(), builder.build())
    }

    private fun createChannels() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager = getSystemService(NotificationManager::class.java)

            val alarmChannel = NotificationChannel(ALARM_CHANNEL, "Alarms", NotificationManager.IMPORTANCE_HIGH).apply {
                enableVibration(true)
                setSound(Settings.System.DEFAULT_ALARM_ALERT_URI, AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_ALARM)
                    .build())
            }

            val chatChannel = NotificationChannel("chat_channel", "Chat Messages", NotificationManager.IMPORTANCE_HIGH)
            val updateChannel = NotificationChannel("update_channel", "Receiver Updates", NotificationManager.IMPORTANCE_HIGH)
            val defaultChannel = NotificationChannel("default_channel", "General Notifications", NotificationManager.IMPORTANCE_HIGH)

            manager.createNotificationChannels(listOf(alarmChannel, chatChannel, updateChannel, defaultChannel))
        }
    }

    override fun onNewToken(token: String) {
        Log.d("FCM_DEBUG", "New token: $token")
    }

    companion object {
        const val ALARM_CHANNEL = "alarm_channel"
    }
}
