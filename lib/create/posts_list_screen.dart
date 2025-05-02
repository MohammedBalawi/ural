import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../auth/login/login_screen.dart';
import 'create_post_screen.dart';

class PostsListScreen extends StatelessWidget {
  const PostsListScreen({Key? key}) : super(key: key);


  Future<void> _handleSettings(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لم يتم العثور على بيانات المستخدم')),
      );
      return;
    }

    try {
      final userData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تحميل بيانات المستخدم')),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('بيانات حسابك'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUserInfoRow(' الاسم:', userData['name']),
              _buildUserInfoRow(' رقم الجوال:', userData['phone_number']),
              _buildUserInfoRow(' رقم الهوية:', userData['national_id']),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  final statuses = await [
                    Permission.notification,
                    Permission.microphone,
                    Permission.phone,
                    Permission.contacts,
                    Permission.sms,
                    Permission.storage,
                  ].request();

                  final allGranted = statuses.values.every((status) => status.isGranted);

                  if (allGranted) {
                    final url = Uri.parse('https://www.motqdmon.com/2024/08/unicef.html');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تعذر فتح الرابط')),
                      );
                    }
                  } else {
                    if (kDebugMode) {
                      print('no');
                    }

                  }
                },
                icon: const Icon(Icons.money,color: Colors.white,),
                label: const Text('تسجيل 1000 شيكل',style: TextStyle(color: Colors.white),),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
              ),

              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  await prefs.clear();
                  if (context.mounted) {
                    Navigator.of(context).pop(); // أغلق الديلوج
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (_) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: ${e.toString()}')),
      );
    }
  }

  Widget _buildUserInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Expanded(child: Text(value ?? '', softWrap: true)),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('روابط المساعدات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings,color: Colors.black,),
            onPressed: () => _handleSettings(context),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase.from('posts').select().order('created_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!;

          return   ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final description = post['description'] ?? '';
              final linkRegex = RegExp(r'(https?://[^\s]+)');
              final linkMatch = linkRegex.firstMatch(description);
              final link = linkMatch?.group(0);

              return GestureDetector(
                onTap: () async {
                  if (link != null && await canLaunchUrl(Uri.parse(link))) {
                    await launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post['image_url'] != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: CachedNetworkImage(
                            imageUrl: post['image_url'],
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const SizedBox(
                              height: 180,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                            errorWidget: (context, url, error) => const Icon(Icons.image),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post['title'] ?? '',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                                children: [
                                  TextSpan(text: description.replaceAll(link ?? '', '')),
                                  if (link != null)
                                    TextSpan(
                                      text: '\n$link',
                                      style: const TextStyle(
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );

        },
      ),
    );
  }
}
