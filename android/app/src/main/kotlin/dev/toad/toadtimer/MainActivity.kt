package dev.toad.toadtimer

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Standard Flutter entry activity. Registers the tile MethodChannel so the
 * Dart side can sync tile state and consume pending quick-tile actions.
 */
class MainActivity : FlutterActivity() {

    private val prefs by lazy {
        getSharedPreferences(ToadTileService.PREFS_NAME, Context.MODE_PRIVATE)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // The self-update flow's native half: system download + installer
        // handoff (UpdatePlugin.kt), ported from the family's
        // toadFILES/toadHEALTH flow.
        UpdatePlugin.register(this, flutterEngine.dartExecutor.binaryMessenger)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "dev.toad.toadtimer/tile",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setTileActive" -> {
                    val active = call.argument<Boolean>("active") == true
                    prefs.edit()
                        .putBoolean(ToadTileService.KEY_TILE_ACTIVE, active)
                        .apply()
                    result.success(null)
                }
                "consumePendingAction" -> {
                    val action = prefs.getString(ToadTileService.KEY_PENDING_ACTION, null)
                    if (action != null) {
                        prefs.edit().remove(ToadTileService.KEY_PENDING_ACTION).apply()
                    }
                    result.success(action)
                }
                else -> result.notImplemented()
            }
        }
    }
}
