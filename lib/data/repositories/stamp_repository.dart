import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/stamp_card.dart';
import 'scoped_key.dart';

/// 스탬프 카드를 shared_preferences에 JSON으로 저장한다.
///
/// [scope]는 계정 id. 계정마다 다른 키(`<계정 id>.stamp_card`)에 저장해 서로 섞이지 않게 한다.
class StampRepository {
  StampRepository(this._prefs, {this.scope = ''});

  static const storageKey = 'stamp_card';

  final SharedPreferences _prefs;
  final String scope;

  String get _key => scopedKey(scope, storageKey);

  StampCard load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const StampCard(count: 0);
    return StampCard.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(StampCard card) =>
      _prefs.setString(_key, jsonEncode(card.toJson()));
}
