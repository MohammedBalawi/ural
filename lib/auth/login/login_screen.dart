import 'package:flutter/material.dart';
import 'package:helps/create/posts_list_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../signUp/sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final supabase = Supabase.instance.client;
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  Future<void> signIn() async {
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى إدخال رقم الجوال وكلمة المرور'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final user = await supabase
          .from('users')
          .select()
          .eq('phone_number', phone)
          .eq('password', password)
          .maybeSingle();

      if (user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', user['id']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PostsListScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('رقم الجوال أو كلمة المرور غير صحيحة'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('حدث خطأ: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const Text('... اهلا بعودتك',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              const Image(image: AssetImage('assets/image.png'), height: 200),
              const SizedBox(height: 30),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'رقم الجوال',
                  prefixIcon: const Icon(Icons.call),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'كلمة المرور',
                  prefixIcon: const Icon(Icons.lock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: loading ? null : signIn,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('تسجيل الدخول',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  );
                },
                child: const Text('إنشاء حساب جديد',
                    style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
