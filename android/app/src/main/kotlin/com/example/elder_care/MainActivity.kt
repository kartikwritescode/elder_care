package com.example.elder_care

import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onResume() {
        super.onResume()
        isAppInForeground = true
    }

    override fun onPause() {
        super.onPause()
        isAppInForeground = false
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleAlarm" -> {
                    val alarmId = call.argument<String>("alarmId")
                    val triggerTime = call.argument<Long>("triggerTime")
                    val title = call.argument<String>("title") ?: "Task Reminder"
                    val dosage = call.argument<String>("dosage")
                    val instructions = call.argument<String>("instructions")
                    val repeatType = call.argument<String>("repeatType") ?: "none"
                    val repeatDays = call.argument<List<String>>("repeatDays") ?: emptyList()

                    if (alarmId != null && triggerTime != null) {
                        AlarmScheduler.schedule(
                            this, 
                            alarmId, 
                            triggerTime, 
                            title, 
                            dosage, 
                            instructions, 
                            repeatType, 
                            repeatDays
                        )
                        
                        // Also schedule advance notification 10 mins before
                        val advanceTime = triggerTime - (10 * 60 * 1000)
                        if (advanceTime > System.currentTimeMillis()) {
                            AlarmScheduler.scheduleAdvanceNotification(this, alarmId, advanceTime, title)
                        }
                        
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENTS", "alarmId or triggerTime was null", null)
                    }
                }
                "cancelAlarm" -> {
                    val alarmId = call.argument<String>("alarmId")
                    if (alarmId != null) {
                        AlarmScheduler.cancel(this, alarmId)
                        result.success(null)
                    } else {
                        result.error("INVALID_ARGUMENTS", "alarmId was null", null)
                    }
                }
                "checkBatteryOptimizations" -> {
                    checkBatteryOptimizations()
                    result.success(null)
                }
                "showFullScreenAlarm" -> {
                    val alarmId = call.argument<String>("alarmId") ?: "SOS"
                    val title = call.argument<String>("title") ?: "EMERGENCY"
                    val isSos = call.argument<Boolean>("isSos") ?: false
                    
                    showFullScreenNotification(alarmId, title, isSos)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun checkBatteryOptimizations() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent()
            val packageName = packageName
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                intent.action = Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                intent.data = Uri.parse("package:$packageName")
                startActivity(intent)
            }
        }
    }

    private fun showFullScreenNotification(alarmId: String, title: String, isSos: Boolean) {
        val safeTitle = if (title.isNotBlank()) title.trim() else (if (isSos) "EMERGENCY" else "Task Reminder")

        val intent = Intent(this, AlarmActivity::class.java).apply {
            putExtra("alarm_id", alarmId)
            putExtra("alarm_title", safeTitle)
            putExtra("is_sos", isSos)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            alarmId.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val builder = NotificationCompat.Builder(this, "alarm_channel")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(safeTitle)
            .setContentText(if (isSos) "EMERGENCY - Tap to Respond" else "Time for your task")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(pendingIntent, true)
            .setOngoing(true)
            .setAutoCancel(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(alarmId.hashCode(), builder.build())
    }

    companion object {
        private const val CHANNEL = "eldercare/alarm"
        var isAppInForeground = false
    }
}
