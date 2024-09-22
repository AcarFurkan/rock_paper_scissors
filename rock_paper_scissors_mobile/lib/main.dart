import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:rock_paper_scissors_mobile/appointment_page.dart';
import 'package:rock_paper_scissors_mobile/firebase_options.dart';
import 'package:rock_paper_scissors_mobile/login_page.dart';
import 'package:rock_paper_scissors_mobile/scanner_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ControllerPage(),
    );
  }
}
