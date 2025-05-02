import 'package:flutter/material.dart';
import 'package:helps/create/posts_list_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../login/login_screen.dart';

class CheckAuthScreen extends StatefulWidget {
  const CheckAuthScreen({super.key});

  @override
  State<CheckAuthScreen> createState() => _CheckAuthScreenState();
}

class _CheckAuthScreenState extends State<CheckAuthScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  void _navigate() async {
    await Future.delayed(const Duration(seconds: 1));

    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PostsListScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: CircularProgressIndicator(
        color: Colors.black,
      )),
    );
  }
}
