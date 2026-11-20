import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:medcin_app/config/env_config.dart';
import 'package:medcin_app/core/network/api_service.dart';
import 'package:medcin_app/core/theme/app_theme.dart';
import 'package:medcin_app/data/services/chat_service.dart';
import 'package:medcin_app/presentation/providers/app_providers.dart';
import 'package:medcin_app/presentation/providers/auth_provider.dart';
import 'package:medcin_app/presentation/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EnvConfig.load();
  if (!kIsWeb) {
    await OneSignal.initialize(EnvConfig.oneSignalAppId);
    await OneSignal.Notifications.requestPermission(true);
  }
  ApiService.setSessionExpiredHandler(() async {
    ChatService.instance.dispose();
    await AuthProvider.instance.forceLogout();
  });
  runApp(const MedcinApp());
}

class MedcinApp extends StatelessWidget {
  const MedcinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return AppProviders(
          child: MaterialApp.router(
            title: 'Medcin',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(),
            routerConfig: appRouter,
            locale: const Locale('fr'),
            supportedLocales: const [
              Locale('fr'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          ),
        );
      },
    );
  }
}