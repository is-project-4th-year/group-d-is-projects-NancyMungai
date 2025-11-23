import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:naihydro/firebase_options.dart';
import 'package:naihydro/src/features/auth/presentation/data/firebase_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:naihydro/src/features/common/services/notification_service.dart';
import 'src/app.dart';

/// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('\n🔔 BACKGROUND MESSAGE RECEIVED');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Data: ${message.data}');
  
  await Firebase.initializeApp();
  
  // Display notification in background
  print('   📲 Attempting to show notification in background...');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('\n🚀 Starting NaiHydro App...\n');

  // Initialize Firebase
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully\n');
    } catch (e) {
      print('❌ Firebase initialization error: $e\n');
    }
  } else {
    print('ℹ️ Firebase already initialized\n');
  }

  // Register background handler BEFORE initializing NotificationService
  print('📋 Registering Firebase background message handler...');
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  print('✅ Background handler registered\n');

  // Initialize Notification Service with current user
  print('📋 Initializing Notification Service...');
  await _initializeNotifications();

  runApp(const NaiHydroApp());
}

/// Initialize notifications with current user's UID and device ID from first farm
Future<void> _initializeNotifications() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      print('⚠️ No authenticated user found, skipping notification initialization');
      return;
    }

    final userId = user.uid;
    print('👤 User authenticated: $userId');

    // Get the first farm and its deviceId from FirebaseService
    final firebaseService = FirebaseService();
    
    // Get farms stream and take first value
    final farmsStream = firebaseService.farmsStream();
    final farmsList = await farmsStream.first;

    if (farmsList.isEmpty) {
      print('⚠️ No farms found for user, skipping notification initialization');
      return;
    }

    final firstFarm = farmsList.first;
    final deviceId = firstFarm['deviceId'] as String?;

    if (deviceId == null) {
      print('⚠️ No deviceId linked to farm, skipping notification initialization');
      return;
    }

    print('🌾 Farm found: ${firstFarm['name']}');
    print('📱 Device ID: $deviceId');

    // Initialize NotificationService with actual values
    NotificationService notificationService = NotificationService();
    await notificationService.initialize(deviceId, userId);

  } catch (e) {
    print('❌ Error initializing notifications: $e');
    print('   Stack: ${StackTrace.current}');
    // Don't rethrow - allow app to continue even if notifications fail
  }
}