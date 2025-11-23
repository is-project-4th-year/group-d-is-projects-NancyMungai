import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FirebaseMessaging _firebaseMessaging;
  late FirebaseDatabase _database;
  late FlutterLocalNotificationsPlugin _localNotifications;
  bool _isInitialized = false;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  bool get isInitialized => _isInitialized;

  Future<void> initialize(String deviceId, String userId) async {
    if (_isInitialized) {
      print('⚠️ NotificationService already initialized, skipping...');
      return;
    }

    _firebaseMessaging = FirebaseMessaging.instance;
    _database = FirebaseDatabase.instance;
    _localNotifications = FlutterLocalNotificationsPlugin();

    print('============================================================');
    print('🔔 NOTIFICATION SERVICE INITIALIZATION');
    print('Device ID: $deviceId');
    print('User ID: $userId');
    print('============================================================');

    try {
      // Step 1: Initialize local notifications FIRST
      print('\n📋 Step 1: Initializing local notifications...');
      await _initializeLocalNotifications();

      // Step 2: Request permissions
      print('\n📋 Step 2: Requesting notification permissions...');
      await _requestPermissions();

      // Step 3: Setup message handlers
      print('\n🎧 Step 3: Setting up message handlers...');
     void _setupMessageHandlers() {
  try {
    print('   Registering message listeners...');

    // CRITICAL: Foreground message listener
    final subscription = FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        print('\n   ✅ 🔔 FOREGROUND MESSAGE RECEIVED!');
        print('      Title: ${message.notification?.title}');
        print('      Body: ${message.notification?.body}');
        
        // Always display when app is open
        _handleMessage(message);
      },
      onError: (error) {
        print('   ❌ Error in onMessage: $error');
      },
    );

    // Handle notification tap
    FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        print('\n   👆 App opened from notification');
        print('      Title: ${message.notification?.title}');
      },
      onError: (error) {
        print('   ❌ Error in onMessageOpenedApp: $error');
      },
    );
    
    print('   ✅ Message handlers registered');
  } catch (e) {
    print('   ❌ Error setting up handlers: $e');
  }
}

      // Step 4: Get FCM Token
      print('\n🎫 Step 4: Getting FCM token...');
      String? fcmToken = await _firebaseMessaging.getToken();
      
      if (fcmToken != null && fcmToken.isNotEmpty) {
        print('✅ FCM Token obtained: ${fcmToken.substring(0, 20)}...');
        print('   Device ID: $deviceId');
        print('   User ID: $userId');
        await _saveFcmTokenDirectly(deviceId, userId, fcmToken);
      } else {
        print('❌ Failed to get FCM token');
      }

      // Step 5: Listen to token refresh
      print('\n🔄 Step 5: Listening to FCM token refresh...');
      _listenToTokenRefresh(deviceId, userId);

      _isInitialized = true;
      print('\n✅ Notification Service initialized successfully');
      print('============================================================\n');
    } catch (e) {
      print('❌ Error during initialization: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings androidInit =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          print('📲 Notification tapped: ${response.payload}');
        },
      );
      
      await _createNotificationChannel();
      print('   ✅ Local notifications initialized');
    } catch (e) {
      print('   ❌ Error initializing local notifications: $e');
    }
  }

  Future<void> _createNotificationChannel() async {
    try {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'naihydro_alerts',
        'Farm Alerts',
        description: 'Critical notifications for farm sensor alerts',
        importance: Importance.max,
        enableVibration: true,
        playSound: true,
        showBadge: true,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
        print('   ✅ Android channel created: naihydro_alerts');
      }
    } catch (e) {
      print('   ⚠️ Error creating channel: $e');
    }
  }

  Future<void> _requestPermissions() async {
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('   ✅ Permission status: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('   ⚠️ Notifications were denied');
      }
    } catch (e) {
      print('   ❌ Error requesting permissions: $e');
    }
  }

  void _setupMessageHandlers() {
    try {
      print('   Registering foreground message listener...');

      // This is the KEY handler for when app is open
      FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) {
          print('\n   ✅ 🔔 FOREGROUND MESSAGE RECEIVED!');
          print('      Title: ${message.notification?.title}');
          print('      Body: ${message.notification?.body}');
          print('      Has notification: ${message.notification != null}');
          print('      Data keys: ${message.data.keys}');
          
          _handleMessage(message);
        },
        onError: (error) {
          print('   ❌ Error in onMessage listener: $error');
        },
      );

      // Handle when user taps notification
      FirebaseMessaging.onMessageOpenedApp.listen(
        (RemoteMessage message) {
          print('\n   👆 App opened/resumed from notification tap');
          print('      Title: ${message.notification?.title}');
        },
        onError: (error) {
          print('   ❌ Error in onMessageOpenedApp: $error');
        },
      );
      
      print('   ✅ Message handlers registered');
    } catch (e) {
      print('   ❌ Error setting up handlers: $e');
    }
  }

  void _listenToTokenRefresh(String deviceId, String userId) {
    _firebaseMessaging.onTokenRefresh.listen(
      (String newToken) {
        print('\n🔔 FCM Token REFRESHED');
        print('   New token: ${newToken.substring(0, 30)}...');
        _saveFcmTokenDirectly(deviceId, userId, newToken);
      },
      onError: (error) {
        print('❌ Error in token refresh: $error');
      },
    );
  }

  Future<void> _saveFcmTokenDirectly(
    String deviceId,
    String userId,
    String fcmToken,
  ) async {
    try {
      print('   💾 Saving FCM token to Firebase...');

      await _database.ref('devices/$deviceId/fcmToken').set(fcmToken);
      print('      ✅ Saved to /devices/$deviceId/fcmToken');

      await _database.ref('users/$userId/devices/$deviceId/fcmToken').set(fcmToken);
      print('      ✅ Saved to /users/$userId/devices/$deviceId/fcmToken');

      await _database.ref('devices/$deviceId/fcmTokenUpdated').set(
        DateTime.now().toIso8601String(),
      );
      
      print('   ✅ FCM token saved successfully');
    } catch (e) {
      print('   ❌ Error saving FCM token: $e');
    }
  }

  void _handleMessage(RemoteMessage message) {
    try {
      print('\n🔄 Processing message for display...');
      
      final title = message.notification?.title ?? 
                    message.data['title'] ?? 
                    'Alert';
      final body = message.notification?.body ?? 
                   message.data['body'] ?? 
                   'New notification';
      final type = message.data['type'] ?? 'unknown';

      print('   Title: $title');
      print('   Body: $body');
      print('   Type: $type');

      _showNotification(title, body, type);
    } catch (e) {
      print('❌ Error handling message: $e');
      print('Stack: ${StackTrace.current}');
    }
  }

  Future<void> _showNotification(
    String title,
    String body,
    String tag,
  ) async {
    try {
      print('   📲 Displaying local notification...');
      
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'naihydro_alerts',
        'Farm Alerts',
        channelDescription: 'Critical notifications for farm sensor alerts',
        importance: Importance.max,
        priority: Priority.max,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        autoCancel: true,
        ongoing: false,
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

      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      await _localNotifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: tag,
      );

      print('   ✅ Notification displayed');
    } catch (e) {
      print('   ❌ Error showing notification: $e');
    }
  }
}