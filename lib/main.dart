import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:naihydro/firebase_options.dart';
import 'src/app.dart';

/// Background message handler (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('\n🔔 BACKGROUND MESSAGE RECEIVED');
  print('   Title: ${message.notification?.title}');
  print('   Body: ${message.notification?.body}');
  print('   Data: ${message.data}');
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

  // Set up Firebase Messaging background handler
  // This MUST be done before the app starts
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  print('✅ Background message handler registered\n');

  runApp(const NaiHydroApp());
}