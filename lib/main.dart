import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/providers/badge_provider.dart';
import 'package:cecelia_care_flutter/providers/locale_provider.dart';
import 'package:cecelia_care_flutter/providers/message_provider.dart'; // NEW
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
import 'providers/wellness_provider.dart';
import 'providers/custom_entry_types_provider.dart';
import 'providers/symptom_analytics_provider.dart';
import 'providers/gamification_provider.dart';
import 'providers/theme_provider.dart';
import 'routing/app_router.dart';
import 'utils/app_theme.dart';
import 'screens/splash_screen.dart';

// ---------------------------------------------------------------------------
// reCAPTCHA site key for Firebase App Check on Web.
//
// Pass your real key at build time using --dart-define so it is never
// hardcoded in source control:
//
//   flutter build web \
//     --dart-define=RECAPTCHA_SITE_KEY=your-real-key-here
//
// During local development the value falls back to an empty string, which
// causes App Check to use the debug provider automatically (see below).
// ---------------------------------------------------------------------------
const String _recaptchaSiteKey = String.fromEnvironment(
  'RECAPTCHA_SITE_KEY',
  defaultValue: '',
);

final AppRouter _appRouter = AppRouter();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupLocator();
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
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // B. Initialize Timezones
    tz.initializeTimeZones();

    // C. Initialize App Check
    //
    // Web: use the debug token provider when in debug mode OR when no
    //      reCAPTCHA key has been supplied (i.e. local dev).
    //
    // Android / iOS: use the real attestation provider in release builds
    //      (Play Integrity / DeviceCheck) and the debug provider only
    //      during development. Never ship with the debug provider in
    //      production — it bypasses all App Check enforcement.
    if (kIsWeb) {
      if (kDebugMode || _recaptchaSiteKey.isEmpty) {
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaEnterpriseProvider('debug'),
        );
        debugPrint('AppCheck: Web debug provider active.');
      } else {
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaV3Provider(_recaptchaSiteKey),
        );
        debugPrint('AppCheck: Web reCAPTCHA provider active.');
      }
    } else {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode
            ? AppleProvider.debug
            : AppleProvider.deviceCheck,
      );
      debugPrint(
        'AppCheck: ${kDebugMode ? "debug" : "production"} provider active.',
      );
    }

    // D. Return SharedPreferences
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
            ChangeNotifierProxyProvider<ActiveElderProvider,
                CustomEntryTypesProvider>(
              create: (context) {
                final activeElder =
                    Provider.of<ActiveElderProvider>(context, listen: false)
                        .activeElder;
                final provider = CustomEntryTypesProvider();
                provider.updateForElder(activeElder);
                return provider;
              },
              update: (context, activeElderProvider, previous) {
                previous!.updateForElder(activeElderProvider.activeElder);
                return previous;
              },
            ),
            ChangeNotifierProxyProvider<ActiveElderProvider,
                SymptomAnalyticsProvider>(
              create: (context) {
                final provider = SymptomAnalyticsProvider(
                  firestoreService: context.read<FirestoreService>(),
                );
                final elder = Provider.of<ActiveElderProvider>(
                        context, listen: false)
                    .activeElder;
                provider.updateForElder(elder);
                return provider;
              },
              update: (context, activeElderProvider, previous) {
                previous!.updateForElder(activeElderProvider.activeElder);
                return previous;
              },
            ),
            ChangeNotifierProvider(create: (_) => UserProfileProvider()),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
            ChangeNotifierProvider(create: (_) => BadgeProvider()),
            ChangeNotifierProvider(create: (_) => SelfCareProvider()),
            ChangeNotifierProvider(create: (_) => WellnessProvider()),
            ChangeNotifierProvider(create: (_) => GamificationProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => NotificationPrefsProvider()),

            // FIX: On elder switch, mutate the existing JournalServiceProvider
            // via setActiveElder() instead of discarding and recreating it.
            // Recreating it every update discards in-flight state and can leak
            // the old provider's listeners.
            ChangeNotifierProxyProvider<ActiveElderProvider,
                JournalServiceProvider>(
              create: (context) => JournalServiceProvider(
                activeElder:
                    Provider.of<ActiveElderProvider>(context, listen: false)
                        .activeElder,
                firestoreService: context.read<FirestoreService>(),
                badgeProvider: context.read<BadgeProvider>(),
              ),
              update: (context, activeElderProv, previousJournalSvc) {
                previousJournalSvc!.setActiveElder(activeElderProv.activeElder);
                return previousJournalSvc;
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

            // NEW: MessageProvider — tracks unread message count for the
            // Timeline nav tab badge. Registered as a ProxyProvider listening
            // to ActiveElderProvider so it re-subscribes automatically when
            // the active elder changes, exactly mirroring the pattern used by
            // MedicationDefinitionsProvider above.
            //
            // create: builds the provider once with no elder yet. Auth state
            //   changes are handled internally via FirebaseAuth.authStateChanges.
            //
            // update: called whenever ActiveElderProvider rebuilds. Calls
            //   updateForElder() which cancels the old Firestore stream and
            //   opens a new one scoped to the new elder's journalEntries.
            ChangeNotifierProxyProvider<ActiveElderProvider, MessageProvider>(
              create: (_) => MessageProvider(),
              update: (context, activeElderProv, previousMsgProvider) {
                previousMsgProvider!
                    .updateForElder(activeElderProv.activeElder);
                return previousMsgProvider;
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
        await NotificationService.instance.init();
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
    return Consumer2<LocaleProvider, ThemeProvider>(
      builder: (context, localeProvider, themeProvider, child) {
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
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
        );
      },
    );
  }
}
