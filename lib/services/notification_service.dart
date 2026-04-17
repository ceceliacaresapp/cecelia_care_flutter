import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// FIX: Removed unused BuildContext from the show clause — was flagged by
// the analyzer as unused_shown_name. TimeOfDay is still needed for
// scheduleDailyRepeatingNotification and scheduleMedReminder.
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:cecelia_care_flutter/l10n/app_localizations.dart';
import 'package:cecelia_care_flutter/providers/notification_prefs_provider.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling a background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  if (message.notification != null) {
    debugPrint(
      'Message also contained a notification: ${message.notification?.title}',
    );
  }
}

/// Payload data parsed from a PRN follow-up notification tap.
class PrnFollowUpPayload {
  final String entryId;
  final String medName;
  final String elderId;
  const PrnFollowUpPayload({
    required this.entryId,
    required this.medName,
    required this.elderId,
  });
}

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  /// Stream that emits when a PRN follow-up notification is tapped.
  /// HomeScreen listens to this and pushes PrnFollowupScreen.
  static final _prnFollowUpCtrl =
      StreamController<PrnFollowUpPayload>.broadcast();
  static Stream<PrnFollowUpPayload> get prnFollowUpStream =>
      _prnFollowUpCtrl.stream;

  final FlutterLocalNotificationsPlugin _fln =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  NotificationPrefsProvider? _notificationPrefsProvider;

  static const String _androidDefaultChannelId = 'default_channel_id';
  static const String _androidMedRemindersChannelId = 'med_reminders';
  static const String _androidCalendarEventsChannelId = 'calendar_events';
  static const String _androidSelfCareChannelId = 'self_care';
  static const String _androidChatMessagesChannelId = 'chat_messages';
  static const String _androidHealthRemindersChannelId = 'health_reminders';

  bool _isInitialized = false;

  void setNotificationPrefsProvider(NotificationPrefsProvider provider) {
    _notificationPrefsProvider = provider;
    debugPrint('NotificationService: NotificationPrefsProvider has been set.');
  }

  Future<void> init() async {
    if (_isInitialized) {
      debugPrint('NotificationService: already initialized.');
      return;
    }

    // tz.initializeTimeZones() is already called in main.dart's
    // _initAppResources — no need to repeat the ~300ms parse here.
    await _initLocalNotifications();
    await _initFirebaseMessaging();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    _isInitialized = true;
    debugPrint('NotificationService: initialized successfully.');
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings =
        InitializationSettings(android: androidInit);

    await _fln.initialize(
      initSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
        final String? payload = notificationResponse.payload;
        if (payload != null) {
          debugPrint('FLN: Notification tapped with payload: $payload');
          // PRN follow-up deep link
          if (payload.startsWith('prn_followup|')) {
            final parts = payload.split('|');
            if (parts.length >= 4) {
              _prnFollowUpCtrl.add(PrnFollowUpPayload(
                entryId: parts[1],
                medName: parts[2],
                elderId: parts[3],
              ));
            }
          }
        }
      },
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation = _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    await _createAndroidNotificationChannels();
  }

  Future<void> _createAndroidNotificationChannels() async {
    final List<AndroidNotificationChannel> channelsToCreate = [
      const AndroidNotificationChannel(
        _androidDefaultChannelId,
        'General Notifications',
        description: 'General app notifications.',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        _androidCalendarEventsChannelId,
        'Calendar Events',
        description: 'Reminders for upcoming calendar events.',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        _androidMedRemindersChannelId,
        'Medication Reminders',
        description: 'Reminders to administer medications.',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        _androidSelfCareChannelId,
        'Self-Care Reminders',
        description: 'Reminders for self-care breaks.',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        _androidChatMessagesChannelId,
        'Chat Messages',
        description: 'Notifications for new chat messages.',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        _androidHealthRemindersChannelId,
        'Health Reminders',
        description: 'General health and wellness reminders.',
        importance: Importance.high,
      ),
    ];

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    for (final channel in channelsToCreate) {
      await androidPlugin?.createNotificationChannel(channel);
      debugPrint(
          "NotificationService: channel '${channel.id}' created/updated.");
    }
  }

  static const String _permRequestedKey = 'notification_permission_requested';

  Future<void> _initFirebaseMessaging() async {
    // Permission request is deferred to requestPermissionIfNeeded() —
    // called after the user's first real action (first journal entry or
    // onboarding completion). This increases opt-in rates vs asking at
    // cold launch.
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_permRequestedKey) == true) {
      // Already asked — just refresh the token.
      await _fcm.requestPermission(
        alert: true, badge: true, sound: true,
      );
    }
    await _saveFcmToken();
    _fcm.onTokenRefresh.listen((_) => _saveFcmToken());

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('FCM: Got a message whilst in the foreground!');
      final RemoteNotification? notification = message.notification;
      if (notification != null) {
        final String channelId =
            message.data['channel_id'] as String? ?? _androidDefaultChannelId;
        await showInstant(
          channelId,
          notification.title ?? 'New Message',
          notification.body ?? '',
          message.data['payload']?.toString() ?? message.messageId,
        );
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        debugPrint(
            'FCM: App opened from terminated by notification: ${message.messageId}');
        // TODO: Handle navigation
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint(
          'FCM: App opened from background by notification: ${message.messageId}');
      // TODO: Handle navigation
    });
  }

  /// Request notification permission if we haven't already. Call this after
  /// the user's first meaningful action (first journal entry, onboarding
  /// completion) — not at app startup. Asking when the user has just
  /// experienced value increases opt-in rates by up to 157%.
  Future<void> requestPermissionIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_permRequestedKey) == true) return; // already asked

    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    await prefs.setBool(_permRequestedKey, true);
    await _saveFcmToken(); // refresh token after permission grant
    debugPrint('NotificationService: permission requested (first time).');
  }

  Future<void> _saveFcmToken() async {
    final token = await _fcm.getToken();
    if (token == null) return;
    debugPrint('FCM Token to save: $token');
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userTokensRef = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('fcmTokens')
            .doc(token);
        await userTokensRef.set({
          'token': token,
          'createdAt': FieldValue.serverTimestamp(),
          'platform': defaultTargetPlatform.name,
        });
        debugPrint('FCM token saved to Firestore for user ${user.uid}');
      }
    } catch (e) {
      debugPrint('Error saving FCM token to Firestore: $e');
    }
  }

  Future<void> scheduleOneTimeNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    required DateTime scheduledTime,
    required String channelKey,
  }) async {
    final String androidChannelId = _getAndroidChannelId(channelKey);

    if (_notificationPrefsProvider != null &&
        !await _notificationPrefsProvider!
            .areNotificationsEnabledForChannel(androidChannelId)) {
      debugPrint(
          "FLN: One-time notification for channel '$androidChannelId' suppressed.");
      return;
    }

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    if (scheduledTime.isBefore(now)) {
      debugPrint(
          'FLN: Attempted to schedule a notification in the past. Ignoring. Time: $scheduledTime');
      return;
    }

    final tz.TZDateTime scheduledTzTime =
        tz.TZDateTime.from(scheduledTime, tz.local);

    await _fln.zonedSchedule(
      id,
      title,
      body,
      scheduledTzTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannelId,
          androidChannelId,
        ),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
    debugPrint(
        'FLN: Scheduled one-time notification. ID: $id, Channel: $androidChannelId at $scheduledTzTime');
  }

  // -------------------------------------------------------------------------
  // Core scheduling method used by the med reminder UI.
  //
  // Parameters for the UI to supply:
  //   notificationId  — derive with:
  //                     (elderId.hashCode + medName.hashCode + timeStr.hashCode)
  //                     .toUnsigned(31)
  //   time            — TimeOfDay from the time picker
  //   channelId       — 'med_reminders'
  //   title / body    — pass through from scheduleMedReminder()
  //   payload         — 'med_reminder|{elderId}|{medName}|{timeStr}'
  // -------------------------------------------------------------------------
  Future<void> scheduleDailyRepeatingNotification({
    required int notificationId,
    required TimeOfDay time,
    required String channelId,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (_notificationPrefsProvider != null &&
        !await _notificationPrefsProvider!
            .areNotificationsEnabledForChannel(channelId)) {
      debugPrint(
          "FLN: Daily repeating notification for channel '$channelId' suppressed.");
      return;
    }

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _fln.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      NotificationDetails(
          android: AndroidNotificationDetails(channelId, channelId)),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint(
        'FLN: Scheduled daily repeating notification. ID: $notificationId, Channel: $channelId');
  }

  Future<void> showInstant(
      String channelId, String title, String body, String? payload) async {
    if (_notificationPrefsProvider != null &&
        !await _notificationPrefsProvider!
            .areNotificationsEnabledForChannel(channelId)) {
      debugPrint(
          "FLN: Instant notification for channel '$channelId' suppressed.");
      return;
    }
    await _fln.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
          android: AndroidNotificationDetails(channelId, channelId)),
      payload: payload,
    );
    debugPrint('FLN: Showing instant notification on channel $channelId.');
  }

  // -------------------------------------------------------------------------
  // High-level wrapper called by the scheduling UI.
  //
  // Accepts a reminderArgs map with keys:
  //   elderId, elderName, medName, dosage, time (HH:mm string)
  //
  // Derives a stable notification ID from those values so cancel() is
  // always reliable for the same medication.
  // -------------------------------------------------------------------------
  Future<void> scheduleMedReminder(
      AppLocalizations l10n, Map<String, dynamic> reminderArgs) async {
    final String? elderId = reminderArgs['elderId'] as String?;
    final String? elderName = reminderArgs['elderName'] as String?;
    final String? medName = reminderArgs['medName'] as String?;
    final String? dosage = reminderArgs['dosage'] as String?;
    final String? timeStr = reminderArgs['time'] as String?;

    if (medName == null ||
        dosage == null ||
        timeStr == null ||
        elderId == null ||
        elderName == null) {
      debugPrint('Medication reminder scheduling failed: Missing arguments.');
      return;
    }

    try {
      final parts = timeStr.split(':');
      if (parts.length != 2) return;
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);
      if (hour == null || minute == null) return;

      final time = TimeOfDay(hour: hour, minute: minute);
      final int notificationId =
          (elderId.hashCode + medName.hashCode + timeStr.hashCode)
              .toUnsigned(31);

      final String notificationTitle = l10n.medicationReminderTitle(medName);
      final String notificationBody =
          l10n.medicationReminderBody(dosage, elderName);

      await scheduleDailyRepeatingNotification(
        notificationId: notificationId,
        time: time,
        channelId: _androidMedRemindersChannelId,
        title: notificationTitle,
        body: notificationBody,
        payload: 'med_reminder|$elderId|$medName|$timeStr',
      );
      debugPrint(
          'Medication reminder scheduled for $medName at $timeStr for elder $elderId.');
    } catch (e) {
      debugPrint('Error scheduling medication reminder: $e');
    }
  }

  /// Cancels a notification by its raw ID.
  Future<void> cancel(int id) async {
    await _fln.cancel(id);
    debugPrint('FLN: Cancelled notification with ID: $id');
  }

  // NEW: Convenience cancel by med identity — the UI calls this when the
  // reminder toggle is turned off. Uses the same hash as scheduleMedReminder
  // so the IDs always match.
  Future<void> cancelMedReminder({
    required String elderId,
    required String medName,
    required String timeStr,
  }) async {
    final int id =
        (elderId.hashCode + medName.hashCode + timeStr.hashCode)
            .toUnsigned(31);
    await cancel(id);
    debugPrint(
        'FLN: Cancelled med reminder for $medName at $timeStr (ID: $id)');
  }

  // ---------------------------------------------------------------------------
  // Sundowning Alert — daily 3 PM notification with rotating Alzheimer's tips
  // ---------------------------------------------------------------------------

  static const int _sundowningAlertId = 99001;

  static const List<String> _sundowningTips = [
    'Close curtains and turn on warm, soft lights to reduce shadows.',
    'Start a calm, familiar activity like folding towels or looking at photos.',
    'Play soft music from their younger years — familiarity soothes agitation.',
    'Offer a light snack — hunger can worsen sundowning symptoms.',
    'Reduce background noise: turn off the TV and close windows.',
    'Speak in a calm, reassuring voice. Don\'t argue or correct.',
    'Go for a short, gentle walk if they\'re restless — movement helps.',
    'Avoid caffeine after noon — it can amplify late-day confusion.',
    'Keep the home well-lit as daylight fades to prevent shadow anxiety.',
    'Maintain a consistent daily routine — predictability reduces agitation.',
    'Limit daytime napping to keep the sleep-wake cycle on track.',
    'Try aromatherapy: lavender or vanilla can have a calming effect.',
    'Remove mirrors if they cause confusion or distress in the evening.',
    'Redirect attention with a simple task: sorting buttons, winding yarn.',
    'Make sure they\'ve used the bathroom — discomfort increases agitation.',
    'Hold their hand or offer a gentle back rub for physical comfort.',
    'Avoid asking complex questions in the evening — keep communication simple.',
    'Ensure the room temperature is comfortable — not too warm, not too cool.',
    'A weighted blanket may provide comforting sensory input.',
    'If they pace, walk with them rather than trying to stop them.',
    'Limit visitors and stimulation in the late afternoon and evening.',
    'Try a warm drink: decaf tea or warm milk can be soothing.',
    'Use nightlights in hallways and bathrooms for safe navigation.',
    'Engage them with a pet — animal interaction can reduce anxiety.',
    'Reminisce about happy memories — long-term recall is often preserved.',
    'Check for pain or illness — sundowning can worsen when unwell.',
    'Keep a consistent bedtime routine: same steps, same order, every night.',
    'Distract with a favorite dessert or treat — positive associations help.',
    'If they\'re verbal, let them talk through worries without correcting.',
    'Remember: this is the disease, not the person. Be gentle with yourself too.',
  ];

  static String get _todaySundowningTip {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    return _sundowningTips[seed % _sundowningTips.length];
  }

  Future<void> scheduleSundowningAlert() async {
    await scheduleDailyRepeatingNotification(
      notificationId: _sundowningAlertId,
      time: const TimeOfDay(hour: 15, minute: 0),
      channelId: _androidHealthRemindersChannelId,
      title: 'Sundowning prep time',
      body: _todaySundowningTip,
      payload: 'sundowning_alert',
    );
    debugPrint('NotificationService: Sundowning alert scheduled for 3:00 PM.');
  }

  Future<void> cancelSundowningAlert() async {
    await cancel(_sundowningAlertId);
    debugPrint('NotificationService: Sundowning alert cancelled.');
  }

  // ---------------------------------------------------------------------------
  // Repositioning Reminder — every 2 hours during daytime (8 fixed times)
  // ---------------------------------------------------------------------------

  static const int _repositioningBaseId = 99002;

  static const List<String> _repositioningTips = [
    'Time to reposition. Check heels and sacrum for redness.',
    'Turn to left side. Place pillow between knees for pressure relief.',
    'Check under medical devices \u2014 tubing and sensors cause pressure injuries too.',
    'Reposition and inspect skin. Look for non-blanchable redness.',
    'Elevate heels off the mattress with a pillow under the calves.',
    'Turn to right side. Ensure ears and shoulders are not compressed.',
    'Time for a position change. Offer a drink while repositioning.',
    'Check the sacrum and coccyx area during this turn.',
    'Reposition to back. Use a 30\u00B0 tilt to reduce pressure.',
    'Apply barrier cream to moisture-prone areas during this turn.',
    'Turn and check. Early redness is reversible with timely repositioning.',
    'Position change time. Keep linens smooth \u2014 wrinkles cause friction.',
    'Reposition gently. Lift, don\u2019t drag \u2014 friction damages fragile skin.',
    'Time to turn. Check bony prominences: hips, ankles, elbows.',
    'Every reposition matters. You\u2019re preventing a pressure injury right now.',
  ];

  // 8 fixed daytime times: 6AM, 8AM, 10AM, 12PM, 2PM, 4PM, 6PM, 8PM
  static const List<int> _repositioningHours = [6, 8, 10, 12, 14, 16, 18, 20];

  Future<void> scheduleRepositioningReminders() async {
    for (int i = 0; i < _repositioningHours.length; i++) {
      final hour = _repositioningHours[i];
      final tipIndex = (DateTime.now().day + i) % _repositioningTips.length;
      await scheduleDailyRepeatingNotification(
        notificationId: _repositioningBaseId + i,
        time: TimeOfDay(hour: hour, minute: 0),
        channelId: _androidHealthRemindersChannelId,
        title: 'Repositioning reminder',
        body: _repositioningTips[tipIndex],
        payload: 'repositioning_reminder',
      );
    }
    debugPrint(
        'NotificationService: Repositioning reminders scheduled '
        '(${_repositioningHours.length} daily times).');
  }

  Future<void> cancelRepositioningReminders() async {
    for (int i = 0; i < _repositioningHours.length; i++) {
      await cancel(_repositioningBaseId + i);
    }
    debugPrint('NotificationService: Repositioning reminders cancelled.');
  }

  // ---------------------------------------------------------------------------
  // Burnout Nudge — gentle check-in when wellbeing is sustained low
  // ---------------------------------------------------------------------------

  Future<void> fireBurnoutNudge() async {
    if (_notificationPrefsProvider != null &&
        !_notificationPrefsProvider!.prefs.burnoutNudges) {
      return;
    }

    await showInstant(
      _androidHealthRemindersChannelId,
      'Hey, just checking in',
      'Your wellbeing has been low lately. You\'re doing amazing work \u2014 '
          'take a moment for yourself today.',
      'burnout_nudge',
    );
    debugPrint('NotificationService: Burnout nudge fired.');
  }

  // ---------------------------------------------------------------------------
  // Self-Care Nudge — schedules a gentle 7 PM push if wellbeing has been
  // in the "red" zone (≤30) for 3+ consecutive check-in days.
  //
  // Debounced to max once every 3 days via SharedPreferences.
  // Cancelled automatically if the user opens the app before 7 PM.
  // ---------------------------------------------------------------------------

  static const int _selfCareNudgeId = 999777;

  /// Check wellbeing history and maybe schedule a 7 PM nudge for today.
  Future<void> maybeScheduleSelfCareNudge({
    required List<dynamic> recentCheckins,
  }) async {
    // Respect the self_care channel toggle.
    if (_notificationPrefsProvider != null &&
        !_notificationPrefsProvider!.prefs.selfCare) {
      return;
    }

    // Need 3+ check-ins to evaluate.
    if (recentCheckins.length < 3) return;

    // Check if the last 3 check-ins all have wellbeingScore <= 30.
    bool allLow = true;
    for (int i = 0; i < 3 && i < recentCheckins.length; i++) {
      final checkin = recentCheckins[i];
      final score = (checkin.wellbeingScore as num?)?.toDouble() ?? 100;
      if (score > 30) {
        allLow = false;
        break;
      }
    }
    if (!allLow) return;

    // Debounce: max once every 3 days.
    final sp = await SharedPreferences.getInstance();
    final lastNudge = sp.getString('self_care_nudge_last');
    if (lastNudge != null) {
      final lastDate = DateTime.tryParse(lastNudge);
      if (lastDate != null &&
          DateTime.now().difference(lastDate).inDays < 3) {
        return;
      }
    }

    // Schedule for 7 PM today (or skip if it's already past 7 PM).
    final now = DateTime.now();
    final sevenPm = DateTime(now.year, now.month, now.day, 19);
    if (now.isAfter(sevenPm)) return;

    await scheduleOneTimeNotification(
      id: _selfCareNudgeId,
      title: "You've been giving a lot this week",
      body: 'How are you doing today? Take a moment to check in with yourself.',
      payload: 'self_care_nudge',
      scheduledTime: sevenPm,
      channelKey: 'self_care',
    );

    await sp.setString(
        'self_care_nudge_last', now.toIso8601String());
    debugPrint('NotificationService: Self-care nudge scheduled for 7 PM.');
  }

  /// Cancel the pending self-care nudge (called on app open / resume).
  Future<void> cancelSelfCareNudge() async {
    await cancel(_selfCareNudgeId);
  }

  // ---------------------------------------------------------------------------
  // Weight Loss Alert — fires once when >5% loss detected in 30 days
  // ---------------------------------------------------------------------------

  Future<void> checkAndFireWeightAlert({
    required double percentLoss,
    required String elderName,
    required String elderId,
  }) async {
    // Only fire once per month per elder to avoid spam.
    final key = 'weight_alert_${elderId}_${DateTime.now().month}';
    final sp = await SharedPreferences.getInstance();
    if (sp.getBool(key) == true) return;

    // Check if weight alerts are enabled.
    if (_notificationPrefsProvider != null &&
        !_notificationPrefsProvider!.prefs.weightAlerts) {
      return;
    }

    await showInstant(
      _androidHealthRemindersChannelId,
      'Weight loss alert',
      '$elderName has lost ${percentLoss.toStringAsFixed(1)}% body weight '
          'in the past 30 days. Consider discussing with their doctor.',
      'weight_alert|$elderId',
    );

    await sp.setBool(key, true);
    debugPrint('NotificationService: Weight loss alert fired for $elderName.');
  }

  // ---------------------------------------------------------------------------
  // Missed Dose Alert
  //
  // Runs once per app open. For each non-PRN medication with reminders
  // enabled, checks if 3+ consecutive days have zero "taken" journal
  // entries. Fires one notification per medication, debounced to once
  // per day per med via SharedPreferences.
  // ---------------------------------------------------------------------------

  Future<void> checkMissedDoses({
    required List<dynamic> medDefinitions,
    required List<dynamic> recentMedEntries,
    required String elderName,
    required String elderId,
  }) async {
    if (elderId.isEmpty || medDefinitions.isEmpty) return;

    // Respect the med_reminders channel toggle.
    if (_notificationPrefsProvider != null &&
        !_notificationPrefsProvider!.prefs.meds) {
      return;
    }

    final sp = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';

    // Build a set of (medName, dateString) pairs where a dose was taken.
    final takenSet = <String>{};
    for (final entry in recentMedEntries) {
      final data = entry.data as Map<String, dynamic>?;
      if (data == null) continue;
      final name = (data['name'] as String?)?.toLowerCase() ?? '';
      final taken = data['taken'] == true;
      final dateStr = data['date'] as String? ?? '';
      if (taken && name.isNotEmpty && dateStr.isNotEmpty) {
        takenSet.add('$name|$dateStr');
      }
    }

    // Check each non-PRN med with reminders enabled.
    for (final med in medDefinitions) {
      if (med.isPRN) continue;
      if (!med.reminderEnabled) continue;

      final medName = med.name as String;
      final medNameLower = medName.toLowerCase();

      // Debounce: once per day per med.
      final debounceKey = 'missed_dose_alert_${elderId}_${medNameLower}_$todayKey';
      if (sp.getBool(debounceKey) == true) continue;

      // Check last 3 days (not including today — today's dose may not be due yet).
      int consecutiveMissed = 0;
      for (int daysAgo = 1; daysAgo <= 3; daysAgo++) {
        final date = today.subtract(Duration(days: daysAgo));
        final dateStr =
            '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final key = '$medNameLower|$dateStr';
        if (!takenSet.contains(key)) {
          consecutiveMissed++;
        } else {
          break; // Streak broken.
        }
      }

      if (consecutiveMissed >= 3) {
        await showInstant(
          _androidMedRemindersChannelId,
          '$medName missed 3 days in a row',
          '$medName has not been logged for $elderName in 3 consecutive days. '
              'Is the prescription still active?',
          'missed_dose|$elderId|$medNameLower',
        );
        await sp.setBool(debounceKey, true);
        debugPrint(
            'NotificationService: Missed dose alert fired for $medName ($elderName).');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Zarit Burden Interview — monthly reminder
  //
  // Fires once a month at the user's local 10 AM. The assessment takes
  // about 3 minutes and the cadence matches the validated ZBI-12
  // follow-up interval. Uses a one-time notification that gets
  // re-scheduled each time the user completes (or dismisses past) the
  // assessment — the Self Care screen calls this after a successful
  // save so the next fire date is always ~30 days out.
  // ---------------------------------------------------------------------------

  static const int _zaritMonthlyId = 99500;

  Future<void> scheduleZaritMonthlyReminder({
    DateTime? scheduledFor,
  }) async {
    // Respect the self-care channel toggle so users who disabled
    // self-care nudges don't get badgered.
    if (_notificationPrefsProvider != null &&
        !_notificationPrefsProvider!.prefs.selfCare) {
      return;
    }

    final when = scheduledFor ??
        DateTime.now().add(const Duration(days: 30)).copyWith(
              hour: 10,
              minute: 0,
              second: 0,
              millisecond: 0,
              microsecond: 0,
            );

    await scheduleOneTimeNotification(
      id: _zaritMonthlyId,
      title: 'Monthly burden check-in',
      body:
          'A short 12-question survey — 3 minutes — so you can track how '
          'you\'re really doing over time.',
      payload: 'zarit_monthly',
      scheduledTime: when,
      channelKey: 'self_care',
    );
    debugPrint(
        'NotificationService: Zarit monthly reminder scheduled for $when.');
  }

  Future<void> cancelZaritMonthlyReminder() async {
    await cancel(_zaritMonthlyId);
  }

  // ---------------------------------------------------------------------------
  // Taper schedule reminders
  //
  // A taper consists of N days, each with a fixed dose. The scheduling
  // primitives we already have cover two shapes: daily-repeating (same
  // body every day) and one-shot (single fire on a future date).
  //
  // Tapers need "one notification per day at time T, with a body that
  // changes day-to-day." The clean mapping is one-shot notifications
  // per future day. We cap at 60 days to avoid flooding the OS alarm
  // manager; longer tapers get re-scheduled on each app open.
  //
  // Notification IDs are derived from (elderId, taperId, day-ordinal) so
  // cancel is always reliable. The reserved range starts at 900000 to
  // avoid collision with the med-reminder hash space.
  // ---------------------------------------------------------------------------

  static const int _taperIdBase = 900000;
  static const int _taperMaxDaysAhead = 60;

  /// Compose a deterministic notification id for (taper, day-offset).
  /// Day offset is days from the taper's startDate (0-based).
  int _taperNotificationId({
    required String elderId,
    required String taperId,
    required int dayOffset,
  }) {
    // Keep the final value inside 31-bit positive int range for
    // AndroidNotificationManager.
    final composite =
        '$elderId|$taperId|$dayOffset'.hashCode.toUnsigned(20);
    return (_taperIdBase + composite) & 0x7FFFFFFF;
  }

  /// Schedules per-day reminders for an entire taper window. Safe to
  /// call repeatedly — it cancels any previously-scheduled ids for this
  /// taper before re-scheduling. Pass a list of `(dayOffset, body)`
  /// pairs; callers compute the body text from the step for that day.
  ///
  /// Returns the number of notifications actually scheduled.
  Future<int> scheduleTaperReminders({
    required String elderId,
    required String taperId,
    required String medName,
    required String elderName,
    required DateTime startDate,
    required DateTime endDate,
    required TimeOfDay reminderTime,
    required String Function(DateTime day) bodyForDay,
  }) async {
    // Respect the med-reminders channel toggle.
    if (_notificationPrefsProvider != null &&
        !await _notificationPrefsProvider!
            .areNotificationsEnabledForChannel(_androidMedRemindersChannelId)) {
      debugPrint('Taper reminders suppressed — med channel disabled.');
      return 0;
    }

    // Cancel the previous horizon before rescheduling to avoid orphans.
    await cancelTaperReminders(elderId: elderId, taperId: taperId);

    final today = DateTime.now();
    final firstDay = DateTime(startDate.year, startDate.month, startDate.day);
    final lastDay = DateTime(endDate.year, endDate.month, endDate.day);

    // Start from today or the taper start, whichever is later.
    final effectiveStart = today.isAfter(firstDay)
        ? DateTime(today.year, today.month, today.day)
        : firstDay;

    // Cap the scheduling horizon so we don't flood the alarm queue.
    final horizonEnd =
        DateTime(today.year, today.month, today.day + _taperMaxDaysAhead);
    final effectiveEnd = lastDay.isBefore(horizonEnd) ? lastDay : horizonEnd;

    if (effectiveEnd.isBefore(effectiveStart)) {
      debugPrint(
          'Taper reminders: start $effectiveStart is after end $effectiveEnd — nothing to schedule.');
      return 0;
    }

    int scheduled = 0;
    for (DateTime day = effectiveStart;
        !day.isAfter(effectiveEnd);
        day = day.add(const Duration(days: 1))) {
      final fireAt = DateTime(
        day.year,
        day.month,
        day.day,
        reminderTime.hour,
        reminderTime.minute,
      );
      // Skip if today's fire time is already in the past.
      if (fireAt.isBefore(DateTime.now())) continue;

      final body = bodyForDay(day);
      if (body.isEmpty) continue;

      final dayOffset = day.difference(firstDay).inDays;
      final id = _taperNotificationId(
        elderId: elderId,
        taperId: taperId,
        dayOffset: dayOffset,
      );

      await scheduleOneTimeNotification(
        id: id,
        title: 'Today\'s taper dose — $medName',
        body: '$body (for $elderName)',
        payload: 'taper|$elderId|$taperId|${fireAt.toIso8601String()}',
        scheduledTime: fireAt,
        channelKey: 'med_reminders',
      );
      scheduled++;
    }

    debugPrint(
        'NotificationService: scheduled $scheduled taper reminders '
        'for taper $taperId of $medName.');
    return scheduled;
  }

  /// Cancels every taper notification in the horizon for a given taper.
  /// Iterates across the full scheduling horizon because the underlying
  /// plugin doesn't expose "cancel by prefix" — deterministic ids make
  /// this cheap and reliable.
  Future<void> cancelTaperReminders({
    required String elderId,
    required String taperId,
  }) async {
    for (int offset = 0; offset < _taperMaxDaysAhead + 365; offset++) {
      final id = _taperNotificationId(
        elderId: elderId,
        taperId: taperId,
        dayOffset: offset,
      );
      await _fln.cancel(id);
    }
    debugPrint(
        'NotificationService: cancelled taper reminders for $taperId.');
  }

  String _getAndroidChannelId(String key) {
    switch (key) {
      case 'calendar_events':
        return _androidCalendarEventsChannelId;
      case 'health_reminders':
        return _androidHealthRemindersChannelId;
      case 'med_reminders':
        return _androidMedRemindersChannelId;
      case 'self_care':
        return _androidSelfCareChannelId;
      case 'chat_messages':
        return _androidChatMessagesChannelId;
      default:
        return _androidDefaultChannelId;
    }
  }
}
