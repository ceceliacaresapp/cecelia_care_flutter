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

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

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
          // TODO: Implement deep-linking
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
