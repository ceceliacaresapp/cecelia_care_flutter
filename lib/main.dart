import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// --- FIX 1: Add Timezone Imports ---
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/providers/badge_provider.dart';
import 'package:cecelia_care_flutter/providers/locale_provider.dart';
import 'package:cecelia_care_flutter/providers/notification_prefs_provider.dart';
import 'package:cecelia_care_flutter/services/notification_service.dart';
import 'package:cecelia_care_flutter/services/firestore_service.dart';

import 'locator.dart';
import 'providers/active_elder_provider.dart';
import 'providers/day_entries_provider.dart';
import 'providers/journal_service_provider.dart';
import 'providers/medication_definitions_provider.dart';
import 'providers/self_care_provider.dart';
import 'providers/user_profile_provider.dart';
import 'routing/app_router.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart'; 

final AppRouter _appRouter = AppRouter();

void main() {
  // 1. Only do the absolute minimum here
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();

  // 2. Run the app immediately. We will handle async loading inside.
  runApp(const AppRoot());
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late Future<SharedPreferences> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initAppResources();
  }

  Future<SharedPreferences> _initAppResources() async {
    // A. Initialize Firebase
    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    // --- FIX 2: Initialize Timezones ---
    tz.initializeTimeZones(); 

    // B. Initialize App Check (Modified for Debug/Local testing)
    if (kIsWeb) {
      await FirebaseAppCheck.instance.activate(
        // For Web testing, we use the debug provider or your site key
        webProvider: ReCaptchaV3Provider('your-recaptcha-site-key-goes-here'),
      );
    } else {
      await FirebaseAppCheck.instance.activate(
        // CHANGED: Using .debug instead of .playIntegrity/deviceCheck
        // This stops the "Member not found" errors during local development
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );
    }

    // C. Return SharedPreferences
    return await SharedPreferences.getInstance();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SharedPreferences>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(home: SplashScreen());
        }

        final prefs = snapshot.data!;

        return MultiProvider(
          providers: [
            Provider<FirestoreService>(create: (_) => FirestoreService()),
            ChangeNotifierProvider<ActiveElderProvider>(
              create: (ctx) => ActiveElderProvider(
                ctx.read<FirestoreService>(),
                prefs,
              ),
            ),
            ChangeNotifierProxyProvider<ActiveElderProvider,
                MedicationDefinitionsProvider>(
              create: (context) {
                final activeElder =
                    Provider.of<ActiveElderProvider>(context, listen: false)
                        .activeElder;
                final medDefsProvider = MedicationDefinitionsProvider();
                medDefsProvider.updateForElder(activeElder);
                return medDefsProvider;
              },
              update: (context, activeElderProvider, previousMedDefsProvider) {
                previousMedDefsProvider!
                    .updateForElder(activeElderProvider.activeElder);
                return previousMedDefsProvider;
              },
            ),
            ChangeNotifierProvider(create: (_) => UserProfileProvider()),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
            ChangeNotifierProvider(create: (_) => BadgeProvider()),
            ChangeNotifierProvider(create: (_) => SelfCareProvider()),
            ChangeNotifierProvider(create: (_) => NotificationPrefsProvider()),
            ChangeNotifierProxyProvider<ActiveElderProvider,
                JournalServiceProvider>(
              create: (context) {
                final activeElder =
                    Provider.of<ActiveElderProvider>(context, listen: false)
                        .activeElder;
                return JournalServiceProvider(
                  activeElder: activeElder,
                  firestoreService: context.read<FirestoreService>(),
                  badgeProvider: context.read<BadgeProvider>(),
                );
              },
              update: (context, activeElderProv, previousJournalSvc) {
                return JournalServiceProvider(
                  activeElder: activeElderProv.activeElder,
                  firestoreService:
                      Provider.of<FirestoreService>(context, listen: false),
                  badgeProvider:
                      Provider.of<BadgeProvider>(context, listen: false),
                );
              },
            ),
            ChangeNotifierProxyProvider<JournalServiceProvider,
                DayEntriesProvider>(
              create: (context) {
                final journalSvc =
                    Provider.of<JournalServiceProvider>(context, listen: false);
                return DayEntriesProvider(journalSvc: journalSvc);
              },
              update: (_, journalSvc, previousDayEntriesProv) {
                if (previousDayEntriesProv != null) {
                  previousDayEntriesProv.updateJournalService(journalSvc);
                  return previousDayEntriesProv;
                } else {
                  return DayEntriesProvider(journalSvc: journalSvc);
                }
              },
            ),
          ],
          child: const CeceliaCareApp(),
        );
      },
    );
  }
}

class CeceliaCareApp extends StatefulWidget {
  const CeceliaCareApp({super.key});

  @override
  State<CeceliaCareApp> createState() => _CeceliaCareAppState();
}

class _CeceliaCareAppState extends State<CeceliaCareApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServicesWithContext();
    });
  }

  Future<void> _initializeServicesWithContext() async {
    if (!mounted) return;
    if (!kIsWeb) {
      try {
        await NotificationService.instance.init(context);
        if (mounted) {
          NotificationService.instance.setNotificationPrefsProvider(
            context.read<NotificationPrefsProvider>(),
          );
        }
      } catch (e) {
        debugPrint('Error initializing NotificationService: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return MaterialApp.router(
          routerConfig: _appRouter.router,
          locale: localeProvider.selectedLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          onGenerateTitle: (ctx) =>
              AppLocalizations.of(ctx)?.appTitle ?? 'Cecelia Care',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
        );
      },
    );
  }
}