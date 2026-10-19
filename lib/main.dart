import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/repositories/repository_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 번들 폰트(Pretendard, SIL OFL 1.1) 라이선스를 오픈소스 라이선스 화면에 노출한다.
  LicenseRegistry.addLicense(() async* {
    final text = await rootBundle.loadString('assets/fonts/pretendard/OFL.txt');
    yield LicenseEntryWithLineBreaks(const ['Pretendard'], text);
  });

  // 스탬프·쿠폰 기록은 계정별로 저장된다. 예시 기록은 데모 계정에 로그인할 때 넣는다.
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MoaStampApp(),
    ),
  );
}
