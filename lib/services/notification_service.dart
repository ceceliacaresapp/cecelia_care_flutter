import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' show TimeOfDay, BuildContext;
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

  final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();
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

  Future<void> init(BuildContext context) async {
    if (_isInitialized) {
      debugPrint('NotificationService already initialized.');
      return;
    }

    final l10n = AppLocalizations.of(context)!;

    tz.initializeTimeZones();
    await _initLocalNotifications(l10n);
    await _initFirebaseMessaging();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    _isInitialized = true;
    debugPrint('NotificationService initialized successfully.');
  }

  Future<void> _initLocalNotifications(AppLocalizations l10n) async {
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

    await _createAndroidNotificationChannels(l10n);
  }

  Future<void> _createAndroidNotificationChannels(AppLocalizations l10n) async {
    final List<AndroidNotificationChannel> channelsToCreate = [
      AndroidNotificationChannel(
        _androidDefaultChannelId,
        l10n.notificationChannelDefaultName,
        description: l10n.notificationChannelDefaultDescription,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        _androidCalendarEventsChannelId,
        l10n.notificationChannelCalendarName,
        description: l10n.notificationChannelCalendarDescription,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        _androidMedRemindersChannelId,
        l10n.notificationChannelMedRemindersName,
        description: l10n.notificationChannelMedRemindersDescription,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        _androidSelfCareChannelId,
        l10n.notificationChannelSelfCareName,
        description: l10n.notificationChannelSelfCareDescription,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        _androidChatMessagesChannelId,
        l10n.notificationChannelChatMessagesName,
        description: l10n.notificationChannelChatMessagesDescription,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        _androidHealthRemindersChannelId,
        l10n.notificationChannelHealthRemindersName,
        description: l10n.notificationChannelHealthRemindersDescription,
        importance: Importance.high,
      ),
    ];

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _fln
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    for (final channel in channelsToCreate) {
      await androidPlugin?.createNotificationChannel(channel);
      debugPrint("Android notification channel '${channel.id}' created/updated.");
    }
  }

  Future<void> _initFirebaseMessaging() async {
    await _fcm.requestPermission(
      alert: true, badge: true, sound: true,
    );
    await _saveFcmToken();
    _fcm.onTokenRefresh.listen((_) => _saveFcmToken());

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('FCM: Got a message whilst in the foreground!');
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        String channelId = message.data['channel_id'] as String? ?? _androidDefaultChannelId;
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
        debugPrint('FCM: App opened from terminated by notification: ${message.messageId}');
        // TODO: Handle navigation
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('FCM: App opened from background by notification: ${message.messageId}');
      // TODO: Handle navigation
    });
  }

  Future<void> _saveFcmToken() async {
    final token = await _fcm.getToken();
    if (token == null) return;
    debugPrint('FCM Token to save: $token');
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userTokensRef = FirebaseFirestore.instance
            .collection('users').doc(user.uid)
            .collection('fcmTokens').doc(token);
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
          !await _notificationPrefsProvider!.areNotificationsEnabledForChannel(androidChannelId)) {
        debugPrint("FLN: One-time notification for channel '$androidChannelId' suppressed.");
        return;
      }

      final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
      if (scheduledTime.isBefore(now)) {
        debugPrint('FLN: Attempted to schedule a notification in the past. Ignoring. Time: $scheduledTime');
        return;
      }
      
      final tz.TZDateTime scheduledTzTime = tz.TZDateTime.from(scheduledTime, tz.local);

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
      debugPrint('FLN: Scheduled one-time notification. ID: $id, Channel: $androidChannelId at $scheduledTzTime');
  }


  Future<void> scheduleDailyRepeatingNotification({
    required int notificationId,
    required TimeOfDay time,
    required String channelId,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (_notificationPrefsProvider != null && !await _notificationPrefsProvider!.areNotificationsEnabledForChannel(channelId)) {
      debugPrint("FLN: Daily repeating notification for channel '$channelId' suppressed.");
      return;
    }

    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _fln.zonedSchedule(
      notificationId, title, body, scheduledDate,
      NotificationDetails(android: AndroidNotificationDetails(channelId, channelId)),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
    debugPrint('FLN: Scheduled daily repeating notification. ID: $notificationId, Channel: $channelId');
  }

  Future<void> showInstant(String channelId, String title, String body, String? payload) async {
    if (_notificationPrefsProvider != null && !await _notificationPrefsProvider!.areNotificationsEnabledForChannel(channelId)) {
      debugPrint("FLN: Instant notification for channel '$channelId' suppressed.");
      return;
    }
    await _fln.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title, body,
      NotificationDetails(android: AndroidNotificationDetails(channelId, channelId)),
      payload: payload,
    );
    debugPrint('FLN: Showing instant notification on channel $channelId.');
  }

  Future<void> scheduleMedReminder(AppLocalizations l10n, Map<String, dynamic> reminderArgs) async {
    final String? elderId = reminderArgs['elderId'] as String?;
    final String? elderName = reminderArgs['elderName'] as String?;
    final String? medName = reminderArgs['medName'] as String?;
    final String? dosage = reminderArgs['dosage'] as String?;
    final String? timeStr = reminderArgs['time'] as String?;

    if (medName == null || dosage == null || timeStr == null || elderId == null || elderName == null) {
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
      final int notificationId = (elderId.hashCode + medName.hashCode + timeStr.hashCode).toUnsigned(31);

      final String notificationTitle = l10n.medicationReminderTitle(medName);
      final String notificationBody = l10n.medicationReminderBody(dosage, elderName);

      await scheduleDailyRepeatingNotification(
        notificationId: notificationId,
        time: time,
        channelId: _androidMedRemindersChannelId,
        title: notificationTitle,
        body: notificationBody,
        payload: 'med_reminder|$elderId|$medName|$timeStr',
      );
      debugPrint('Medication reminder scheduled for $medName at $timeStr for elder $elderId.');
    } catch (e) {
      debugPrint('Error scheduling medication reminder: $e');
    }
  }

  Future<void> cancel(int id) async {
    await _fln.cancel(id);
    debugPrint('FLN: Cancelled notification with ID: $id');
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
