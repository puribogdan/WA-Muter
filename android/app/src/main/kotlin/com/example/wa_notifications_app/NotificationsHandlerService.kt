package com.example.wa_notifications_app

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.RemoteInput
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.provider.Settings
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.text.TextUtils
import android.util.Log
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation
import org.json.JSONObject
import java.util.*
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.collections.HashMap

class NotificationsHandlerService: MethodChannel.MethodCallHandler, NotificationListenerService() {
    private val queue = ArrayDeque<NotificationEvent>()
    private lateinit var mBackgroundChannel: MethodChannel
    private lateinit var mContext: Context

    // notification event cache: packageName_id -> event
    private val eventsCache = HashMap<String, NotificationEvent>()
    
    // Track if service is already in foreground mode to prevent duplicate notifications
    private var isInForegroundMode = false
    private var hasInitializedFlutterLoader = false
    private val recentMuteLogFingerprints = HashMap<String, Long>()
    private val recentMuteLogContentFingerprints = HashMap<String, Long>()

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
      when (call.method) {
          "service.initialized" -> {
              initFinish()
              return result.success(true)
          }
          // this should move to plugin
          "service.promoteToForeground" -> {
              // add data
              val cfg = Utils.PromoteServiceConfig.fromMap(call.arguments as Map<*, *>).apply {
                  foreground = true
              }
              return result.success(promoteToForeground(cfg))
          }
          "service.demoteToBackground" -> {
              return result.success(demoteToBackground())
          }
          "service.tap" -> {
              // tap the notification
              Log.d(TAG, "tap the notification")
              val args = call.arguments<ArrayList<*>?>()
              val uid = args!![0]!! as String
              return result.success(tapNotification(uid))
          }
          "service.tap_action" -> {
              // tap the action
              Log.d(TAG, "tap action of notification")
              val args = call.arguments<ArrayList<*>?>()
              val uid = args!![0]!! as String
              val idx = args[1]!! as Int
              return result.success(tapNotificationAction(uid, idx))
          }
          "service.send_input" -> {
              // send the input data
              Log.d(TAG, "set the content for input and the send action")
              val args = call.arguments<ArrayList<*>?>()
              val uid = args!![0]!! as String
              val idx = args[1]!! as Int
              val data = args[2]!! as Map<*, *>
              return result.success(sendNotificationInput(uid, idx, data))
          }
          "service.get_full_notification" -> {
              val args = call.arguments<ArrayList<*>?>()
              val uid = args!![0]!! as String
              if (!eventsCache.contains(uid)) {
                  return result.error("notFound", "can't found this notification $uid", "")
              }
              return result.success(Utils.Marshaller.marshal(eventsCache[uid]?.mSbn))
          }
          else -> {
              Log.d(TAG, "unknown method ${call.method}")
              result.notImplemented()
          }
      }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // if get shutdown release the wake lock
        when (intent?.action) {
            ACTION_SHUTDOWN -> {
                // Reset foreground mode flag when shutting down
                isInForegroundMode = false
                Log.i(TAG, "ðŸ›‘ [SERVICE] Shutdown action received - stopping service")
                disableServiceSettings(mContext)
                stopForeground(true)
                stopSelf()
            }
            else -> {

            }
        }
        Log.i(TAG, "âœ… [SERVICE] Returning START_STICKY - service will restart if killed")
        return START_STICKY
    }

    override fun onCreate() {
        super.onCreate()

        mContext = this

        // store the service instance
        instance = this

        Log.i(TAG, "ðŸ”„ [SERVICE] onCreate called - Service lifecycle event")
        Log.i(TAG, "ðŸ“± [SERVICE] App package: ${packageName}")
        Log.i(TAG, "âš¡ [SERVICE] Starting notification listener service...")
        
        // CRITICAL: Force immediate service component enable
        Log.i(TAG, "ðŸ”§ [SERVICE] Forcing service component enable...")
        enableServiceSettings(mContext)

        // Lightweight delayed re-enable for OEMs that register lazily.
        Handler(mContext.mainLooper).postDelayed({
            try {
                if (!permissionGiven(mContext)) {
                    enableServiceSettings(mContext)
                }
            } catch (e: Exception) {
                Log.e(TAG, "[OEM] Delayed component enable failed: $e")
            }
        }, 300L)

        // Start the main service registration
        startListenerService(this)
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.i(TAG, "ðŸ”„ [SERVICE] onDestroy called - Service being destroyed")
        Log.i(TAG, "ðŸ“± [SERVICE] App package: ${packageName}")
        Log.i(TAG, "âš ï¸ [SERVICE] Service destroyed - this should only happen during shutdown")
        val bdi = Intent(mContext, RebootBroadcastReceiver::class.java)
        // remove notification
        sendBroadcast(bdi)
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        super.onTaskRemoved(rootIntent)
        Log.i(TAG, "ðŸ”„ [SERVICE] onTaskRemoved called - App task removed from recent apps")
        Log.i(TAG, "ðŸ“± [SERVICE] This is normal when user closes app from recent apps")
        Log.i(TAG, "âš ï¸ [SERVICE] Service should continue running in background")
    }

    // **ENHANCED onNotificationPosted with COMPREHENSIVE DEBUG LOGGING**
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        super.onNotificationPosted(sbn)

        val evt = NotificationEvent(mContext, sbn)
        val debugLogging = isDebugLoggingEnabled()

        // store the evt to cache
        eventsCache[evt.uid] = evt

        if (debugLogging) {
            // **COMPREHENSIVE DEBUG LOGGING - Step by step analysis**
            Log.d(TAG, "ðŸ”” [DEBUG] === NOTIFICATION RECEIVED ===")
            Log.d(TAG, "ðŸ”” [DEBUG] Package: ${evt.data["package_name"]}")
            Log.d(TAG, "ðŸ”” [DEBUG] Title: ${evt.data["title"]}")
            Log.d(TAG, "ðŸ”” [DEBUG] Text: ${evt.data["text"]}")
            Log.d(TAG, "ðŸ”” [DEBUG] UID: ${evt.uid}")
            Log.d(TAG, "ðŸ”” [DEBUG] Full data: ${evt.data}")

            // **DEBUG: Log notification actions**
            val actions = evt.data["actions"] as? List<*>
            if (actions != null) {
                Log.d(TAG, "ðŸ”” [DEBUG] Actions count: ${actions.size}")
                actions.forEachIndexed { index, action ->
                    if (action is Map<*, *>) {
                        val title = action["title"] as? String ?: "Unknown"
                        val semantic = action["semantic"] as? Int ?: -1
                        Log.d(TAG, "ðŸ”” [DEBUG] Action $index: '$title' (semantic: $semantic)")
                    }
                }
            } else {
                Log.d(TAG, "ðŸ”” [DEBUG] No actions found")
            }

            // **DEBUG: Test NotificationBlocker class existence and state**
            try {
                Log.d(TAG, "ðŸ” [DEBUG] Testing NotificationBlocker class...")
                
                // Test class existence
                val blockerClass = Class.forName("com.example.wa_notifications_app.NotificationBlocker")
                Log.d(TAG, "âœ… [DEBUG] NotificationBlocker class found: $blockerClass")
                
                // Log current blocker state
                NotificationBlocker.logDebugState(mContext)
                
            } catch (e: ClassNotFoundException) {
                Log.e(TAG, "âŒ [DEBUG] CRITICAL: NotificationBlocker class not found!")
                Log.e(TAG, "âŒ [DEBUG] This means the class was not compiled or is missing")
                return
            } catch (e: Exception) {
                Log.e(TAG, "âŒ [DEBUG] Error accessing NotificationBlocker: $e")
            }
        }

        // **NATIVE BLOCKING LOGIC** - Process notification immediately in native code
        Handler(mContext.mainLooper).post {
            try {
                if (debugLogging) Log.d(TAG, "ðŸ”„ [DEBUG] Starting native blocking analysis...")
                
                // Extract notification data
                val packageName = evt.data["package_name"] as? String
                val title = evt.data["title"] as? String
                val text = evt.data["text"] as? String
                
                if (debugLogging) {
                    Log.d(TAG, "ðŸ” [DEBUG] Package name: '$packageName'")
                    Log.d(TAG, "ðŸ” [DEBUG] Title: '$title'")
                }
                
                // Step 1: Check if NotificationBlocker exists and can be called
                try {
                    if (debugLogging) Log.d(TAG, "ðŸ” [DEBUG] Step 1: Testing NotificationBlocker.shouldBlockNotification...")
                    val shouldBlock = NotificationBlocker.shouldBlockNotification(mContext, packageName, title)
                    if (debugLogging) Log.d(TAG, "ðŸ” [DEBUG] Should block result: $shouldBlock")
                    
                    if (shouldBlock) {
                        if (debugLogging) Log.d(TAG, "ðŸ›‘ [SERVICE] Step 2: Notification should be blocked - attempting to dismiss...")
                        
                        // Step 3: Try to block the notification
                        val blocked = NotificationBlocker.blockNotification(evt)
                        if (debugLogging) Log.d(TAG, "ðŸ” [DEBUG] Block notification result: $blocked")
                        
                        if (blocked) {
                            if (debugLogging) Log.d(TAG, "âœ… [SERVICE] SUCCESS: Notification blocked successfully via native logic")
                            maybeAppendMuteLog(evt, title, text, "Dismissed")
                        } else {
                            Log.w(TAG, "âš ï¸ [SERVICE] FAILED: Could not block notification - no dismiss action found")
                            maybeAppendMuteLog(evt, title, text, "Muted")
                            
                            // **EXTRA DEBUG: Analyze why blocking failed**
                            if (debugLogging) Log.d(TAG, "ðŸ” [DEBUG] Analyzing blocking failure...")
                            val actions = evt.data["actions"] as? List<*>
                            if (actions != null && actions.isNotEmpty()) {
                                if (debugLogging) Log.d(TAG, "ðŸ” [DEBUG] Actions available but none had semantic=2 (dismiss)")
                                actions.forEachIndexed { index, action ->
                                    if (action is Map<*, *>) {
                                        val title = action["title"] as? String ?: "Unknown"
                                        val semantic = action["semantic"] as? Int ?: -1
                                        if (debugLogging) {
                                            Log.d(TAG, "ðŸ” [DEBUG] Action $index: '$title' (semantic: $semantic) - NOT dismissable")
                                        }
                                    }
                                }
                            } else {
                                if (debugLogging) Log.d(TAG, "ðŸ” [DEBUG] No actions available on notification")
                            }
                        }
                    } else {
                        if (debugLogging) {
                            Log.d(TAG, "âœ… [SERVICE] Notification allowed - not meeting blocking criteria")
                            Log.d(TAG, "ðŸ” [DEBUG] Reasons: Not WhatsApp OR not from muted group OR outside schedule")
                        }
                    }
                    
                } catch (e: Exception) {
                    Log.e(TAG, "âŒ [DEBUG] Error in NotificationBlocker.shouldBlockNotification: $e")
                    e.printStackTrace()
                }
                
            } catch (e: Exception) {
                Log.e(TAG, "âŒ [SERVICE] Error in native blocking logic: $e")
                e.printStackTrace()
            }
        }

        // **FALLBACK TO FLUTTER** - Telemetry/streaming only.
        // WhatsApp muting policy is enforced natively to avoid duplicate engines drifting.
        synchronized(sServiceStarted) {
            if (!sServiceStarted.get()) {
                if (debugLogging) Log.d(TAG, "service is not start try to queue the event")
                queue.add(evt)
            } else {
                if (debugLogging) Log.d(TAG, "send event to flutter side as fallback!")
                try {
                    ensureFlutterLoaderInitialized()
                    Handler(mContext.mainLooper).post { sendEvent(evt) }
                } catch (e: Exception) {
                    Log.w(TAG, "âš ï¸ [SERVICE] Flutter communication failed, continuing with native blocking only: $e")
                }
            }
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        super.onNotificationRemoved(sbn)
        if (sbn == null) return
        val evt = NotificationEvent(mContext, sbn)
        // remove the event from cache
        eventsCache.remove(evt.uid)
        if (isDebugLoggingEnabled()) Log.d(TAG, "notification removed: ${evt.uid}")
    }

    private fun initFinish() {
        if (isDebugLoggingEnabled()) Log.d(TAG, "service's flutter engine initialize finished")
        synchronized(sServiceStarted) {
            while (!queue.isEmpty()) sendEvent(queue.remove())
            sServiceStarted.set(true)
        }
    }

    private fun promoteToForeground(cfg: Utils.PromoteServiceConfig? = null): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            Log.e(TAG, "promoteToForeground need sdk >= 26")
            return false
        }

        if (cfg?.foreground != true) {
            Log.i(TAG, "no need to start foreground: ${cfg?.foreground}")
            return false
        }

        // first is not running already, start at first
        // Check if service is already in foreground mode to avoid duplicate notifications
        if (isInForegroundMode) {
            Log.d(TAG, "Service already in foreground mode - skipping duplicate notification")
            return true
        }

        if (!FlutterNotificationListenerPlugin.isServiceRunning(mContext, this.javaClass)) {
            Log.e(TAG, "service is not running")
            return false
        }

        // get args from store or args
        val cfg = cfg ?: Utils.PromoteServiceConfig.load(this)
        // make the service to foreground

        // create a channel for notification
        val channel = NotificationChannel(CHANNEL_ID, "Flutter Notifications Listener Plugin", NotificationManager.IMPORTANCE_LOW)
        val imageId = resources.getIdentifier("ic_launcher", "mipmap", packageName)
        (getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager).createNotificationChannel(channel)

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(cfg.title)
            .setContentText(cfg.description)
            .setShowWhen(cfg.showWhen ?: false)
            .setSubText(cfg.subTitle)
            .setSmallIcon(imageId)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .build()

        Log.d(TAG, "promote the service to foreground")
        startForeground(ONGOING_NOTIFICATION_ID, notification)
        
        // Mark service as in foreground mode to prevent duplicate notifications
        isInForegroundMode = true

        return true
    }

    private fun demoteToBackground(): Boolean {
        Log.d(TAG, "demote the service to background")
        stopForeground(true)
        return true
    }

    private fun tapNotification(uid: String): Boolean {
        Log.d(TAG, "tap the notification: $uid")
        if (!eventsCache.containsKey(uid)) {
            Log.d(TAG, "notification is not exits: $uid")
            return false
        }
        val n = eventsCache[uid] ?: return false
        n.mSbn.notification.contentIntent.send()
        return true
    }

    private fun tapNotificationAction(uid: String, idx: Int): Boolean {
        Log.d(TAG, "tap the notification action: $uid @$idx")
        if (!eventsCache.containsKey(uid)) {
            Log.d(TAG, "notification is not exits: $uid")
            return false
        }
        val n = eventsCache[uid]
        if (n == null) {
            Log.e(TAG, "notification is null: $uid")
            return false
        }
        if (n.mSbn.notification.actions.size <= idx) {
            Log.e(TAG, "tap action out of range: size ${n.mSbn.notification.actions.size} index $idx")
            return false
        }

        val act = n.mSbn.notification.actions[idx]
        if (act == null) {
            Log.e(TAG, "notification $uid action $idx not exits")
            return false
        }
        act.actionIntent.send()
        return true
    }

    private fun sendNotificationInput(uid: String, idx: Int, data: Map<*, *>): Boolean {
        Log.d(TAG, "tap the notification action: $uid @$idx")
        if (!eventsCache.containsKey(uid)) {
            Log.d(TAG, "notification is not exits: $uid")
            return false
        }
        val n = eventsCache[uid]
        if (n == null) {
            Log.e(TAG, "notification is null: $uid")
            return false
        }
        if (n.mSbn.notification.actions.size <= idx) {
            Log.e(TAG, "send inputs out of range: size ${n.mSbn.notification.actions.size} index $idx")
            return false
        }

        val act = n.mSbn.notification.actions[idx]
        if (act == null) {
            Log.e(TAG, "notification $uid action $idx not exits")
            return false
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.KITKAT_WATCH) {
            if (act.remoteInputs == null) {
                Log.e(TAG, "notification $uid action $idx remote inputs not exits")
                return false
            }

            val intent = Intent()
            val bundle = Bundle()
            act.remoteInputs.forEach {
                if (data.containsKey(it.resultKey as String)) {
                    Log.d(TAG, "add input content: ${it.resultKey} => ${data[it.resultKey]}")
                    bundle.putCharSequence(it.resultKey, data[it.resultKey] as String)
                }
            }
            RemoteInput.addResultsToIntent(act.remoteInputs, intent, bundle)
            act.actionIntent.send(mContext, 0, intent)
            Log.d(TAG, "send the input action success")
            return true
        } else {
            Log.e(TAG, "not implement :sdk < KITKAT_WATCH")
            return false
        }
    }

    companion object {

        var callbackHandle = 0L

        @SuppressLint("StaticFieldLeak")
        @JvmStatic
        var instance: NotificationsHandlerService? = null

        @JvmStatic
        private val TAG = "NotificationsListenerService"

        private const val ONGOING_NOTIFICATION_ID = 100
        @JvmStatic
        val ACTION_SHUTDOWN = "SHUTDOWN"

        private const val CHANNEL_ID = "flutter_notifications_listener_channel"

        @JvmStatic
        private var sBackgroundFlutterEngine: FlutterEngine? = null
        @JvmStatic
        private val sServiceStarted = AtomicBoolean(false)

        private const val BG_METHOD_CHANNEL_NAME = "flutter_notification_listener/bg_method"

        private const val ENABLED_NOTIFICATION_LISTENERS = "enabled_notification_listeners"
        private const val ACTION_NOTIFICATION_LISTENER_SETTINGS = "android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS"

        const val NOTIFICATION_INTENT_KEY = "object"
        const val NOTIFICATION_INTENT = "notification_event"

        fun permissionGiven(context: Context): Boolean {
            val packageName = context.packageName
            val flat = Settings.Secure.getString(context.contentResolver, ENABLED_NOTIFICATION_LISTENERS)
            if (!TextUtils.isEmpty(flat)) {
                val names = flat.split(":").toTypedArray()
                for (name in names) {
                    val componentName = ComponentName.unflattenFromString(name)
                    val nameMatch = TextUtils.equals(packageName, componentName?.packageName)
                    if (nameMatch) {
                        return true
                    }
                }
            }

            return false
        }

        fun openPermissionSettings(context: Context): Boolean {
            context.startActivity(Intent(ACTION_NOTIFICATION_LISTENER_SETTINGS).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            return true
        }

        fun enableServiceSettings(context: Context) {
            toggleServiceSettings(context, PackageManager.COMPONENT_ENABLED_STATE_ENABLED)
        }

        fun disableServiceSettings(context: Context) {
            toggleServiceSettings(context, PackageManager.COMPONENT_ENABLED_STATE_DISABLED)
        }

        private fun toggleServiceSettings(context: Context, state: Int) {
            val receiver = ComponentName(context, NotificationsHandlerService::class.java)
            val pm = context.packageManager
            pm.setComponentEnabledSetting(receiver, state, PackageManager.DONT_KILL_APP)
        }

        fun updateFlutterEngine(context: Context) {
            Log.d(TAG, "call instance update flutter engine from plugin init")
            instance?.updateFlutterEngine(context)
            // we need to `finish init` manually
            instance?.initFinish()
        }
    }

    private fun getFlutterEngine(context: Context): FlutterEngine {
        var eng = FlutterEngineCache.getInstance().get(FlutterNotificationListenerPlugin.FLUTTER_ENGINE_CACHE_KEY)
        if (eng != null) return eng

        Log.i(TAG, "flutter engine cache is null, create a new one")
        eng = FlutterEngine(context)

        // ensure initialization
        FlutterInjector.instance().flutterLoader().startInitialization(context)
        FlutterInjector.instance().flutterLoader().ensureInitializationComplete(context, arrayOf())

        // call the flutter side init
        // get the call back handle information
        val cb = context.getSharedPreferences(FlutterNotificationListenerPlugin.SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)
            .getLong(FlutterNotificationListenerPlugin.CALLBACK_DISPATCHER_HANDLE_KEY, 0)

        if (cb != 0L) {
            Log.d(TAG, "try to find callback: $cb")
            val info = FlutterCallbackInformation.lookupCallbackInformation(cb)
            val args = DartExecutor.DartCallback(context.assets,
                FlutterInjector.instance().flutterLoader().findAppBundlePath(), info)
            // call the callback
            eng.dartExecutor.executeDartCallback(args)
        } else {
            Log.e(TAG, "Fatal: no callback register")
        }

        FlutterEngineCache.getInstance().put(FlutterNotificationListenerPlugin.FLUTTER_ENGINE_CACHE_KEY, eng)
        return eng
    }

    private fun updateFlutterEngine(context: Context) {
        Log.d(TAG, "update the flutter engine of service")
        // take the engine
        val eng = getFlutterEngine(context)
        sBackgroundFlutterEngine = eng

        // set the method call
        mBackgroundChannel = MethodChannel(eng.dartExecutor.binaryMessenger, BG_METHOD_CHANNEL_NAME)
        mBackgroundChannel.setMethodCallHandler(this)
    }

    private fun startListenerService(context: Context) {
        Log.d(TAG, "start listener service")

        // First, explicitly enable the service component for Android 14+ compatibility
        Log.d(TAG, "enabling service component for notification access registration")
        enableServiceSettings(context)

        // Bounded registration work to avoid unnecessary wakeups and retries.
        Log.d(TAG, "[FORCED REGISTRATION] Starting bounded registration process...")

        // Immediate permission check
        val immediatePermissionCheck = permissionGiven(context)
        Log.d(TAG, "[FORCED REGISTRATION] Immediate permission check: $immediatePermissionCheck")

        // Perform a single delayed retry only if permission is still missing.
        if (!immediatePermissionCheck) {
            Handler(context.mainLooper).postDelayed({
                Log.d(TAG, "[FORCED REGISTRATION] Retry 1/1 - enabling service component")
                enableServiceSettings(context)

                val hasPermission = permissionGiven(context)
                Log.d(TAG, "[FORCED REGISTRATION] Permission status after retry: $hasPermission")
                if (!hasPermission) {
                    Log.w(TAG, "[FORCED REGISTRATION] Retry failed - ask user to open settings from UI")
                }
            }, 1500L)
        }

        // Wait briefly for Android to register the service.
        Handler(context.mainLooper).postDelayed({
            Log.d(TAG, "[FINAL CHECK] Performing final notification access permission check")
            val hasPermission = permissionGiven(context)
            Log.d(TAG, "[FINAL CHECK] Final permission status: $hasPermission")

            if (!hasPermission) {
                Log.w(TAG, "[FINAL CHECK] No notification listener permission - user needs to enable it")
                Log.d(TAG, "[FINAL CHECK] Waiting for user to open notification access settings from UI")
                return@postDelayed
            }

            synchronized(sServiceStarted) {
                Log.d(TAG, "[FINAL CHECK] Promoting service to foreground")
                promoteToForeground(Utils.PromoteServiceConfig.load(context))

                Log.d(TAG, "[FINAL CHECK] Updating service Flutter engine")
                updateFlutterEngine(context)

                sServiceStarted.set(true)
                Log.d(TAG, "[FINAL CHECK] Service registration and initialization completed")
            }
        }, if (immediatePermissionCheck) 1000L else 2500L)

        Log.d(TAG, "[FORCED REGISTRATION] Service start sequence initiated")
    }

    private fun sendEvent(evt: NotificationEvent) {
        if (isDebugLoggingEnabled()) Log.d(TAG, "send notification event: ${evt.uid}")
        if (callbackHandle == 0L) {
            callbackHandle = mContext.getSharedPreferences(FlutterNotificationListenerPlugin.SHARED_PREFERENCES_KEY, Context.MODE_PRIVATE)
                .getLong(FlutterNotificationListenerPlugin.CALLBACK_HANDLE_KEY, 0)
        }

        // why mBackgroundChannel can be null?

        try {
            // don't care about the method name
            mBackgroundChannel.invokeMethod("sink_event", listOf(callbackHandle, evt.data))
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun ensureFlutterLoaderInitialized() {
        if (hasInitializedFlutterLoader) return
        synchronized(this) {
            if (hasInitializedFlutterLoader) return
            FlutterInjector.instance().flutterLoader().startInitialization(mContext)
            FlutterInjector.instance().flutterLoader().ensureInitializationComplete(mContext, null)
            hasInitializedFlutterLoader = true
        }
    }

    private fun maybeAppendMuteLog(
        evt: NotificationEvent,
        title: String?,
        messageText: String?,
        status: String
    ) {
        if (!NativePreferencesBridge.shouldKeepMuteLog(mContext)) return
        val isGroupSummary = (evt.data["isGroup"] as? Boolean) == true
        if (isGroupSummary) {
            if (isDebugLoggingEnabled()) {
                Log.d(TAG, "[MUTE_LOG] Skipping group summary notification log for ${evt.uid}")
            }
            return
        }
        val logGroupName = if (title.isNullOrBlank()) "Unknown" else title
        val normalizedText = messageText?.trim().orEmpty()
        val fingerprint = buildString {
            append(evt.uid)
            append('|')
            append(logGroupName.trim().lowercase())
            append('|')
            append(normalizedText.lowercase())
        }
        val contentFingerprint = buildString {
            append(logGroupName.trim().lowercase())
            append('|')
            append(normalizedText.lowercase())
        }
        val now = System.currentTimeMillis()
        val lastLoggedAt = recentMuteLogFingerprints[fingerprint]
        if (lastLoggedAt != null && (now - lastLoggedAt) <= 10_000L) {
            if (isDebugLoggingEnabled()) {
                Log.d(TAG, "[MUTE_LOG] Skipping duplicate mute log entry for ${evt.uid}")
            }
            return
        }
        val lastContentLoggedAt = recentMuteLogContentFingerprints[contentFingerprint]
        if (lastContentLoggedAt != null && (now - lastContentLoggedAt) <= 10_000L) {
            if (isDebugLoggingEnabled()) {
                Log.d(TAG, "[MUTE_LOG] Skipping duplicate content log for ${evt.uid}")
            }
            return
        }
        recentMuteLogFingerprints[fingerprint] = now
        recentMuteLogContentFingerprints[contentFingerprint] = now
        if (recentMuteLogFingerprints.size > 200) {
            val cutoff = now - 60_000L
            recentMuteLogFingerprints.entries.removeAll { it.value < cutoff }
        }
        if (recentMuteLogContentFingerprints.size > 200) {
            val cutoff = now - 60_000L
            recentMuteLogContentFingerprints.entries.removeAll { it.value < cutoff }
        }
        NativePreferencesBridge.appendMuteLog(mContext, logGroupName, status, normalizedText)
    }

    private fun isDebugLoggingEnabled(): Boolean {
        return (mContext.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
    }
}

