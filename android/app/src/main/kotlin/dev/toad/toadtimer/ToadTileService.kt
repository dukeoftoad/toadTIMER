package dev.toad.toadtimer

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Build
import android.service.quicksettings.Tile
import android.service.quicksettings.TileService

/**
 * Android Quick Settings Tile ("Toad Focus").
 *
 * Tap once: if the timer is not running, marks a pending "start_focus"
 * action and opens the app (the Dart side consumes it and launches a focus
 * session). If it is running, marks "stop". Tile state is stored in
 * SharedPreferences so it survives process death and stays in sync with
 * the app via the "dev.toad.toadtimer/tile" MethodChannel.
 */
class ToadTileService : TileService() {

    companion object {
        const val PREFS_NAME = "toad_tile_prefs"
        const val KEY_TILE_ACTIVE = "tile_active"
        const val KEY_PENDING_ACTION = "pending_action"
        const val ACTION_START_FOCUS = "start_focus"
        const val ACTION_STOP = "stop"
    }

    private val prefs: SharedPreferences by lazy {
        getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
    }

    override fun onStartListening() {
        super.onStartListening()
        syncTile()
    }

    override fun onClick() {
        super.onClick()
        val isActive = prefs.getBoolean(KEY_TILE_ACTIVE, false)
        val next = !isActive

        prefs.edit()
            .putBoolean(KEY_TILE_ACTIVE, next)
            .putString(KEY_PENDING_ACTION, if (next) ACTION_START_FOCUS else ACTION_STOP)
            .apply()

        qsTile?.let { tile ->
            tile.state = if (next) Tile.STATE_ACTIVE else Tile.STATE_INACTIVE
            tile.updateTile()
        }

        launchApp()
    }

    private fun syncTile() {
        qsTile?.let { tile ->
            tile.state =
                if (prefs.getBoolean(KEY_TILE_ACTIVE, false)) Tile.STATE_ACTIVE
                else Tile.STATE_INACTIVE
            tile.updateTile()
        }
    }

    private fun launchApp() {
        val launch = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        } ?: return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            val pending = PendingIntent.getActivity(
                this,
                0,
                launch,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
            )
            startActivityAndCollapse(pending)
        } else {
            @Suppress("DEPRECATION")
            startActivityAndCollapse(launch)
        }
    }
}
