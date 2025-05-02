import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);

  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  File? _image;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadPost() async {
    if (_image == null || _titleController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('املأ كل الحقول')),
      );
      return;
    }

    final fileName = DateTime.now().millisecondsSinceEpoch.toString();
    final filePath = 'posts/$fileName.jpg';

    final supabase = Supabase.instance.client;
    final storage = supabase.storage.from('my');

    try {
      final fileBytes = await _image!.readAsBytes();

      final response = await storage.uploadBinary(
        filePath,
        fileBytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      if (response.isEmpty) {
        throw Exception('لم يتم رفع الملف');
      }

      final publicUrl = storage.getPublicUrl(filePath);

      await supabase.from('posts').insert({
        'image_url': publicUrl,
        'title': _titleController.text,
        'description': _descController.text,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ تم رفع المنشور بنجاح')),
      );

      Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ فشل في رفع المنشور: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة منشور')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 150,
                width: double.infinity,
                color: Colors.grey[300],
                child: _image != null
                    ? Image.file(_image!, fit: BoxFit.cover)
                    : const Icon(Icons.add_a_photo, size: 50),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'العنوان'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(labelText: 'الوصف'),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _uploadPost,
              child: const Text('نشر'),
            ),
          ],
        ),
      ),
    );
  }
}
