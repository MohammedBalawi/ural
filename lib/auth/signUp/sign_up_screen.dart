import 'package:flutter/material.dart';
import 'package:helps/create/posts_list_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final supabase = Supabase.instance.client;

  final fullNameController = TextEditingController();
  final nationalIdController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;

  Future<void> signUp() async {
    final fullName = fullNameController.text.trim();
    final nationalId = nationalIdController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();

    if (fullName.isEmpty || nationalId.isEmpty || phone.isEmpty || password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('يرجى تعبئة جميع الحقول واستخدام كلمة مرور لا تقل عن 6 أحرف.'),
      ));
      return;
    }

    setState(() => loading = true);

    try {
      // تحقق من عدم تكرار رقم الجوال
      final existing = await supabase
          .from('users')
          .select()
          .eq('phone_number', phone)
          .maybeSingle();

      if (existing != null) {
        throw Exception('رقم الجوال مستخدم مسبقًا');
      }

      // إدخال المستخدم مباشرة إلى جدول users بدون auth
      await supabase.from('users').insert({
        'name': fullName,
        'national_id': nationalId,
        'phone_number': phone,
        'password': password, // فقط للتخزين المحلي وليس للـ auth
        'created_at': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الحساب بنجاح')),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: ${e.toString()}')),
      );
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text('إنشاء حساب', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              const Image(image: AssetImage('assets/image.png'), height: 200),
              const SizedBox(height: 30),

              TextField(
                controller: fullNameController,
                decoration: InputDecoration(
                  hintText: 'الاسم الكامل',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: nationalIdController,
                decoration: InputDecoration(
                  hintText: 'رقم الهوية',
                  prefixIcon: const Icon(Icons.credit_card),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),

              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  hintText: 'رقم الجوال',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

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
                  onPressed: loading ? null : signUp,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.black87,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('تسجيل', style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
