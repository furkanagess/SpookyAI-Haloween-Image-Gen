package com.furkanages.spookyai

import android.content.ComponentName
import android.content.pm.PackageManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "spookyai/app_icon"

        /** Icon id (as used from Dart) -> launcher activity-alias in AndroidManifest.xml. */
        private val ALIASES = mapOf(
            "halloween" to ".IconHalloween",
            "christmas" to ".IconChristmas",
        )
        private const val DEFAULT_ICON = "halloween"
    }

    /**
     * Switching the enabled launcher alias while the app is on screen makes some
     * launchers close the app, so the switch is applied when the app leaves the
     * foreground.
     */
    private var pendingIcon: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        registerDeviceChannel(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isSupported" -> result.success(true)
                    "getIcon" -> result.success(pendingIcon ?: enabledIcon())
                    "setIcon" -> {
                        val icon = call.argument<String>("icon") ?: DEFAULT_ICON
                        if (!ALIASES.containsKey(icon)) {
                            result.error("unknown_icon", "Unknown icon: $icon", null)
                        } else {
                            pendingIcon = if (icon == enabledIcon()) null else icon
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun registerDeviceChannel(flutterEngine: FlutterEngine) {
        // ANDROID_ID is stable for this app across uninstall/reinstall (same
        // signing key, Android 8+); it only changes on factory reset. Used to
        // grant the free starter tokens once per device.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "spookyai/device")
            .setMethodCallHandler { call, result ->
                if (call.method == "deviceId") {
                    result.success(
                        Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
                    )
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onStop() {
        super.onStop()
        pendingIcon?.let { applyIcon(it) }
        pendingIcon = null
    }

    private fun component(alias: String) = ComponentName(packageName, packageName + alias)

    private fun enabledIcon(): String {
        for ((icon, alias) in ALIASES) {
            val state = packageManager.getComponentEnabledSetting(component(alias))
            if (state == PackageManager.COMPONENT_ENABLED_STATE_ENABLED) return icon
        }
        // Nothing switched yet: the manifest default (Halloween) is active.
        return DEFAULT_ICON
    }

    private fun applyIcon(icon: String) {
        // Enable the new alias first so there is never a moment without a launcher entry.
        val target = ALIASES[icon] ?: return
        packageManager.setComponentEnabledSetting(
            component(target),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )
        for ((_, alias) in ALIASES) {
            if (alias == target) continue
            packageManager.setComponentEnabledSetting(
                component(alias),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
    }
}
