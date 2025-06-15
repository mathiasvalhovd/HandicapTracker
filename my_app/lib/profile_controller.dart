import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController bioController = TextEditingController();
  final TextEditingController pronounsController =
  TextEditingController(text: 'Secret');
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController photoUrlController = TextEditingController();

  bool isEditing = false;
  bool loading = false;

  String photoUrl = '';
  String backgroundUrl = '';
  String countryCode = '+62';

  final List<String> countryCodes = ['+60', '+44', '+62', '+91', '+81'];

  static const Color _darkBlue = Color(0xFF0D47A1);

  Future<void> loadProfile(BuildContext context, VoidCallback refresh) async {
    loading = true;
    refresh();
    try {
      final uid = _auth.currentUser!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();

      nameController.text = data?['name'] ?? '';
      ageController.text = data?['age']?.toString() ?? '';
      bioController.text = data?['bio'] ?? '';
      pronounsController.text = data?['pronouns'] ?? 'Secret';
      phoneController.text =
          data?['phone']?.replaceFirst(RegExp(r'^\+\d+\s?'), '') ?? '';
      photoUrl = data?['photoUrl'] ?? '';
      backgroundUrl = data?['backgroundUrl'] ?? '';
      photoUrlController.text = photoUrl;

      if (data?['phone'] != null && data!['phone'].toString().contains(' ')) {
        countryCode = data['phone'].toString().split(' ')[0];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    } finally {
      loading = false;
      refresh();
    }
  }

  Future<void> saveProfile(BuildContext context, VoidCallback refresh) async {
    loading = true;
    refresh();
    try {
      final uid = _auth.currentUser!.uid;
      final String photoUrlInput = photoUrlController.text.trim();

      await _firestore.collection('users').doc(uid).set({
        'name': nameController.text.trim(),
        'age': int.tryParse(ageController.text.trim()),
        'bio': bioController.text.trim(),
        'pronouns': pronounsController.text.trim(),
        'phone': phoneController.text.trim().isEmpty
            ? ''
            : '$countryCode ${phoneController.text.trim()}',
        'photoUrl': photoUrlInput,
        'backgroundUrl': backgroundUrl,
      }, SetOptions(merge: true));

      isEditing = false;
      photoUrl = photoUrlInput;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      loading = false;
      refresh();
    }
  }

  Future<void> onBackgroundPhotoAction(
      BuildContext context, VoidCallback refresh) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: _darkBlue),
            title: const Text('Edit Background Photo'),
            onTap: () => Navigator.pop(context, 'edit'),
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.redAccent),
            title: const Text('Delete Background Photo'),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
        ],
      ),
    );

    if (action == 'edit') {
      final url = await _showImageUrlDialog(context, isBackground: true);
      if (url != null && url.isNotEmpty) backgroundUrl = url;
    } else if (action == 'delete') {
      backgroundUrl = '';
    }
    refresh();
  }

  Future<void> onProfilePhotoAction(
      BuildContext context, VoidCallback refresh) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: _darkBlue),
            title: const Text('Edit Profile Picture'),
            onTap: () => Navigator.pop(context, 'edit'),
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.redAccent),
            title: const Text('Delete Profile Picture'),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
        ],
      ),
    );

    if (action == 'edit') {
      final url = await _showImageUrlDialog(context, isBackground: false);
      if (url != null && url.isNotEmpty) {
        photoUrl = url;
        photoUrlController.text = url;
      }
    } else if (action == 'delete') {
      photoUrl = '';
      photoUrlController.text = '';
    }
    refresh();
  }

  void dispose() {
    nameController.dispose();
    ageController.dispose();
    bioController.dispose();
    pronounsController.dispose();
    phoneController.dispose();
    photoUrlController.dispose();
  }

  Future<String?> _showImageUrlDialog(BuildContext context,
      {required bool isBackground}) async {
    final controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter ${isBackground ? 'background' : 'profile'} photo URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Image URL'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _darkBlue),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
