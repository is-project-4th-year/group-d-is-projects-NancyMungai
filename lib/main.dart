import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:naihydro/firebase_options.dart';
import 'src/app.dart';
import 'package:firebase_database/firebase_database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
  );


  runApp(const NaiHydroApp());
}
