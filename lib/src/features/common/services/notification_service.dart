import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
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
    // Prevent double initialization
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
      // 1. Request permissions first
      await _requestPermissions();

      // 2. Initialize local notifications
      await _initializeLocalNotifications();

      // 3. Setup message handlers BEFORE getting token
      _setupMessageHandlers();

      // 4. Get FCM Token
      String? fcmToken = await _firebaseMessaging.getToken();
      
      if (fcmToken != null) {
        print('🎫 FCM Token obtained');
        print('   Device ID: $deviceId');
        print('   FCM Token: ${fcmToken.substring(0, 20)}...');
        print('   User ID: $userId');
        
        // Save FCM token to Firebase
        await _saveFcmTokenDirectly(deviceId, userId, fcmToken);
      } else {
        print('❌ Failed to get FCM token');
      }

      // 5. Listen to token refresh
      _listenToTokenRefresh(deviceId, userId);

      _isInitialized = true;
      print('✅ Notification Service initialized successfully');
      print('============================================================');
    } catch (e) {
      print('❌ Error during initialization: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> _requestPermissions() async {
    print('\n📋 Requesting notification permissions...');
    
    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      print('✅ Permission status: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        print('⚠️ User denied notification permissions');
      }
    } catch (e) {
      print('❌ Error requesting permissions: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    print('\n🔧 Initializing local notifications...');
    
    try {
      // Android setup
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

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          print('📲 Notification tapped: ${response.payload}');
        },
      );
      
      // Create notification channel for Android
      await _createNotificationChannel();
      
      print('✅ Local notifications initialized');
    } catch (e) {
      print('❌ Error initializing local notifications: $e');
    }
  }

  Future<void> _createNotificationChannel() async {
    print('   Creating Android notification channel...');
    
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

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      
      print('   ✅ Notification channel created');
    } catch (e) {
      print('   ⚠️ Error creating channel: $e');
    }
  }

  Future<void> _saveFcmTokenDirectly(
    String deviceId,
    String userId,
    String fcmToken,
  ) async {
    try {
      print('\n💾 Saving FCM token to Firebase...');

      // Save to device path
      await _database.ref('devices/$deviceId/fcmToken').set(fcmToken);
      print('   ✅ Saved to /devices/$deviceId/fcmToken');

      // Save to user's device mapping
      await _database.ref('users/$userId/devices/$deviceId/fcmToken').set(fcmToken);
      print('   ✅ Saved to /users/$userId/devices/$deviceId/fcmToken');

      // Update timestamp
      await _database.ref('devices/$deviceId/fcmTokenUpdated').set(
        DateTime.now().toIso8601String()
      );
      
      print('   ✅ FCM token saved successfully');
    } catch (e) {
      print('   ❌ Error saving FCM token: $e');
    }
  }

  void _setupMessageHandlers() {
    print('\n🎧 Setting up message handlers...');
    
    try {
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      print('   ✅ Background handler registered');

      // Handle FOREGROUND messages
      FirebaseMessaging.onMessage.listen(
        (RemoteMessage message) {
          print('\n   🔔 FOREGROUND MESSAGE RECEIVED');
          print('      Title: ${message.notification?.title}');
          print('      Body: ${message.notification?.body}');
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

  void _listenToTokenRefresh(String deviceId, String userId) {
    print('\n🔄 Listening to FCM token refresh...');
    
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

  void _handleMessage(RemoteMessage message) {
    try {
      print('\n🔄 Processing message...');
      
      if (message.notification != null) {
        _showNotification(
          message.notification!.title ?? 'Alert',
          message.notification!.body ?? 'New notification',
          message.data['type'] ?? 'unknown',
        );
      } else if (message.data.isNotEmpty) {
        _showNotification(
          message.data['title'] ?? 'Alert',
          message.data['body'] ?? 'New notification',
          message.data['type'] ?? 'unknown',
        );
      }
    } catch (e) {
      print('❌ Error handling message: $e');
    }
  }

  Future<void> _showNotification(
    String title,
    String body,
    String tag,
  ) async {
    try {
      print('\n📲 Showing notification...');
      print('   Title: $title');
      print('   Body: $body');
      print('   Tag: $tag');
      
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

      // Use unique ID based on timestamp
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
      print('   Exception: ${e.runtimeType}');
    }
  }
}

/// Background message handler (top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('\n🔔 BACKGROUND MESSAGE RECEIVED');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  
  // Initialize Firebase if needed
  await Firebase.initializeApp();
}

// Add this import at the top
