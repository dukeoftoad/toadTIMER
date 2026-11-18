import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Bridge to the Android Quick Settings Tile (ToadTileService.kt).
///
/// The tile toggles a "start_focus" / "stop" pending action in
/// SharedPreferences and launches the app; the Flutter side consumes the
/// pending action on resume. No engine attachment inside the TileService —
/// lightweight and reliable.
class TileBridge {
  TileBridge._();

  static final instance = TileBridge._();

  static const _channel = MethodChannel('dev.toad.toadtimer/tile');

  Future<void> setActive(bool active) async {
    try {
      await _channel.invokeMethod<void>('setTileActive', {'active': active});
    } on PlatformException catch (e) {
      // e.g. iOS or pre-tile builds — safe to ignore
      debugPrint('TileBridge setActive failed: ${e.code}');
    } on MissingPluginException {
      // platform channel not registered (e.g. iOS) — safe to ignore
    }
  }

  /// Returns the pending tile action ("start_focus" | "stop") and clears it.
  Future<String?> consumePendingAction() async {
    try {
      return await _channel.invokeMethod<String>('consumePendingAction');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
