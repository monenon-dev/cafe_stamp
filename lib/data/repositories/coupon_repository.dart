import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/coupon.dart';
import 'scoped_key.dart';

/// 쿠폰 목록을 shared_preferences에 JSON으로 저장한다.
///
/// [scope]는 계정 id. 계정마다 다른 키에 저장한다.
class CouponRepository {
  CouponRepository(this._prefs, {this.scope = ''});

  static const storageKey = 'coupons';

  final SharedPreferences _prefs;
  final String scope;

  String get _key => scopedKey(scope, storageKey);

  List<Coupon> loadAll() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const [];
    return (jsonDecode(raw) as List<dynamic>)
        .map((e) => Coupon.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveAll(List<Coupon> coupons) => _prefs.setString(
    _key,
    jsonEncode(coupons.map((e) => e.toJson()).toList()),
  );
}
