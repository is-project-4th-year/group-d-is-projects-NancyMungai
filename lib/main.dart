import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:naihydro/firebase_options.dart';
import 'src/app.dart';
import 'package:firebase_database/firebase_database.dart';
import 'src/features/common/services/notification_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   // Initialize Firebase only once
   // Initialize Firebase ONLY if not already initialized
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully');
    } catch (e) {
      print('⚠️ Firebase initialization error: $e');  
      // Continue anyway - Firebase might already be initialized
    }
  } else {
    print('ℹ️ Firebase already initialized');
  }
  runApp(const NaiHydroApp());
}
