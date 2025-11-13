import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FirebaseMessaging _firebaseMessaging;
  late FirebaseDatabase _database;
  late FlutterLocalNotificationsPlugin _localNotifications;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  Future<void> initialize(String deviceId, String userId) async {
    _firebaseMessaging = FirebaseMessaging.instance;
    _database = FirebaseDatabase.instance;
    _localNotifications = FlutterLocalNotificationsPlugin();

    print('============================================================');
    print('🔔 NOTIFICATION SERVICE INITIALIZATION');
    print('Device ID: $deviceId');
    print('User ID: $userId');
    print('============================================================');

    try {
      // Request permissions
      await _requestPermissions();

      // Initialize local notifications with channel
      await _initializeLocalNotifications();

      // Get FCM Token
      String? fcmToken = await _firebaseMessaging.getToken();
      
      if (fcmToken != null) {
        print('🎫 FCM Token obtained');
        print('   Device ID: $deviceId');
        print('   FCM Token: ${fcmToken.substring(0, 20)}...');
        print('   User ID: $userId');
        
        // Save FCM token
        await _saveFcmTokenDirectly(deviceId, userId, fcmToken);
      } else {
        print('❌ Failed to get FCM token');
      }

      // Set up message handlers BEFORE listening
      _setupMessageHandlers();

      // Listen to real-time processed data changes
      _listenToProcessedData(deviceId);

      // Listen to token refresh
      listenToTokenRefresh(deviceId, userId);

      print('✅ Local notifications initialized');
      print('✅ Notification Service initialized successfully');
      print('============================================================');
      print('✅ Notifications initialized for device: $deviceId');
    } catch (e) {
      print('❌ Error during initialization: $e');
    }
  }

  Future<void> _requestPermissions() async {
    print('\n📋 Requesting notification permissions...');
    
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('✅ Permissions granted: ${settings.authorizationStatus}');
  }

  Future<void> _initializeLocalNotifications() async {
    print('\n🔧 Initializing local notifications...');
    
    // Android setup with notification channel
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS setup
    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotifications.initialize(initSettings);
    
    // Create notification channel for Android
    await _createNotificationChannel();
    
    print('   ✅ Local notifications initialized');
  }

  Future<void> _createNotificationChannel() async {
    print('   Creating notification channel...');
    
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'naihydro_alerts', // ID
      'Farm Alerts', // title
      description: 'Notifications for farm sensor alerts and ML predictions',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    print('   ✅ Notification channel created');
  }

  Future<void> _saveFcmTokenDirectly(
    String deviceId,
    String userId,
    String fcmToken,
  ) async {
    try {
      print('\n💾 Saving FCM token to Realtime Database...');

      // Save to device path
      await _database.ref('devices/$deviceId/fcmToken').set(fcmToken);
      print('   ✅ Saved to /devices/$deviceId/fcmToken');

      // Save to user's device mapping
      await _database.ref('users/$userId/devices/$deviceId/fcmToken').set(fcmToken);
      print('   ✅ Saved to /users/$userId/devices/$deviceId/fcmToken');

      // Update timestamp
      await _database.ref('devices/$deviceId/fcmTokenUpdated').set(DateTime.now().toIso8601String());
      
      print('   ✅ FCM token saved successfully');
    } catch (e) {
      print('   ❌ Error saving FCM token: $e');
    }
  }

  void _setupMessageHandlers() {
    print('\n🎧 Setting up message handlers...');
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    print('   ✅ Background handler registered');

    // Handle FOREGROUND messages (when app is open)
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        print('   🔔 FOREGROUND FCM message received!');
        print('      Title: ${message.notification?.title}');
        print('      Body: ${message.notification?.body}');
        print('      Data: ${message.data}');
        
        // IMPORTANT: Show notification even when app is in foreground
        _handleMessage(message);
      },
      onError: (error) {
        print('   ❌ Error in onMessage listener: $error');
      },
    );

    // Handle notification tap
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        print('   👆 App opened from notification');
        print('      Title: ${message.notification?.title}');
      },
      onError: (error) {
        print('   ❌ Error in onMessageOpenedApp: $error');
      },
    );
    
    print('   ✅ Message handlers registered');
  }

  void _listenToProcessedData(String deviceId) {
    print('\n👂 Setting up data listeners...');
    print('   Listening to /processed/$deviceId/');
    
    _database.ref('processed/$deviceId').onValue.listen(
      (DatabaseEvent event) {
        if (event.snapshot.exists) {
          final data = event.snapshot.value;
          if (data != null) {
            print('   ✅ Processed data changed');
            _checkAndNotifyForAnomalies(deviceId, data);
          }
        }
      },
      onError: (error) {
        print('   ❌ Error listening: $error');
      },
    );
  }

  void _checkAndNotifyForAnomalies(String deviceId, dynamic data) {
    try {
      if (data is! Map<dynamic, dynamic>) return;

      final dataMap = data as Map<dynamic, dynamic>;

      // Check prediction
      if (dataMap.containsKey('prediction')) {
        final prediction = dataMap['prediction'];
        if (prediction == 1) {
          print('   🚨 ML Alert detected from DB listener');
          _showNotification(
            '🚨 Critical Alert',
            'ML model detected potential issues',
            'ml_alert',
          );
        }
      }

      // Check pump/relay
      if (dataMap.containsKey('pump_state')) {
        _showNotification(
          '💧 Pump',
          'Pump turned ${dataMap['pump_state'] == 1 ? "ON" : "OFF"}',
          'pump_change',
        );
      }
    } catch (e) {
      print('   ❌ Error checking anomalies: $e');
    }
  }

  Future<void> _showNotification(
    String title,
    String body,
    String tag,
  ) async {
    try {
      print('\n📲 Displaying notification...');
      print('   Title: $title');
      print('   Body: $body');
      print('   Tag: $tag');
      
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'naihydro_alerts',
        'Farm Alerts',
        channelDescription: 'Notifications for farm sensor alerts',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        // Remove sound reference - use channel default
      );

      const DarwinNotificationDetails iosDetails =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use unique ID based on timestamp to avoid duplicates
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _localNotifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: tag,
      );

      print('   ✅ Notification displayed successfully');
    } catch (e) {
      print('   ❌ Error showing notification: $e');
      print('   📋 Exception type: ${e.runtimeType}');
      print('   📋 Exception: ${e.toString()}');
    }
  }

  void _handleMessage(RemoteMessage message) {
    print('\n🔄 Processing FCM message...');
    print('   Message ID: ${message.messageId}');
    
    if (message.notification != null) {
      print('   Has notification: title="${message.notification?.title}", body="${message.notification?.body}"');
      _showNotification(
        message.notification!.title ?? 'Alert',
        message.notification!.body ?? 'New notification',
        message.data['type'] ?? 'unknown',
      );
    } else {
      print('   ⚠️ Message has no notification payload');
      if (message.data.isNotEmpty) {
        print('   Data: ${message.data}');
      }
    }
  }

  void listenToTokenRefresh(String deviceId, String userId) {
    print('\n🔄 Listening to token refresh events...');
    
    _firebaseMessaging.onTokenRefresh.listen(
      (String newToken) {
        print('🔔 FCM Token REFRESHED');
        print('   New token: ${newToken.substring(0, 30)}...');
        _saveFcmTokenDirectly(deviceId, userId, newToken);
      },
      onError: (error) {
        print('❌ Error in token refresh: $error');
      },
    );
  }
}

/// Background message handler (must be a top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔔 BACKGROUND MESSAGE RECEIVED');
  print('   Message ID: ${message.messageId}');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  
  // You can initialize Firebase and database here if needed
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}