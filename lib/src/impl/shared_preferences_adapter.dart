import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:rx_storage/rx_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../interface/shared_preferences_like.dart';

/// [SharedPreferencesLike]'s implementation by delegating a [SharedPreferences].
class SharedPreferencesAdapter implements SharedPreferencesLike {
  final SharedPreferences _prefs;

  SharedPreferencesAdapter._(this._prefs);

  static Future<T> _wrap<T>(T value) => SynchronousFuture<T>(value);

  @override
  Future<void> clear([void _]) =>
      _prefs.clear().throwsIfNotSuccess('Cannot clear');

  @override
  Future<bool> containsKey(String key, [void _]) =>
      _wrap(_prefs.containsKey(key));

  @override
  Future<Map<String, Object?>> reload() {
    return _prefs.reload().then((_) {
      return {
        for (final k in _prefs.getKeys()) k: _prefs.get(k),
      };
    });
  }

  @override
  Future<void> remove(String key, [void _]) =>
      _prefs.remove(key).throwsIfNotSuccess('Cannot remove key=$key');

  /// Create [SharedPreferencesAdapter] from [SharedPreferences].
  static FutureOr<SharedPreferencesAdapter> from(
    FutureOr<SharedPreferences> prefsOrFuture,
  ) =>
      prefsOrFuture is Future<SharedPreferences>
          ? prefsOrFuture.then((p) => SharedPreferencesAdapter._(p))
          : SharedPreferencesAdapter._(prefsOrFuture)
              as FutureOr<SharedPreferencesAdapter>;

  @override
  Future<T?> read<T extends Object>(String key, Decoder<T?> decoder, [void _]) {
    var val = _prefs.get(key);
    if (val is List) {
      val = _prefs.getStringList(key);
    }
    return _wrap(decoder(val));
  }

  @override
  Future<Map<String, Object?>> readAll([void _]) {
    return _wrap({
      for (final k in _prefs.getKeys()) k: _prefs.get(k),
    });
  }

  @override
  Future<void> write<T extends Object>(
      String key, T? value, Encoder<T?> encoder,
      [void _]) {
    final val = encoder(value);

    if (val == null) {
      return remove(key);
    }
    if (val is double) {
      return _prefs.setDouble(key, val).throwsIfNotSuccess(
          'Cannot set double value: key=$key, value=$value');
    }
    if (val is int) {
      return _prefs
          .setInt(key, val)
          .throwsIfNotSuccess('Cannot set int value: key=$key, value=$value');
    }
    if (val is bool) {
      return _prefs
          .setBool(key, val)
          .throwsIfNotSuccess('Cannot set bool value: key=$key, value=$value');
    }
    if (val is String) {
      return _prefs.setString(key, val).throwsIfNotSuccess(
          'Cannot set String value: key=$key, value=$value');
    }
    if (val is List<String>) {
      return _prefs.setStringList(key, val).throwsIfNotSuccess(
          'Cannot set List<String> value: key=$key, value=$value');
    }

    throw StateError('Value $val of type ${val.runtimeType} is not supported. '
        'Encoder must return the value of a supported type, eg. double, int, bool, String or List<String>');
  }
}

extension _ThrowsIfNotSuccess on Future<bool> {
  Future<void> throwsIfNotSuccess(String message) {
    return then((success) {
      if (!success) {
        throw PlatformException(
          code: SharedPreferencesLike.errorCode,
          message: message,
        );
      }
    });
  }
}
