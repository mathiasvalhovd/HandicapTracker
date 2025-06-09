import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  bool _isEditing = false;
  bool _loading = false;

  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _bioController = TextEditingController();
  final _photoController = TextEditingController();
  final _bgPhotoController = TextEditingController();
  final _phoneController = TextEditingController();

  String _selectedPronoun = 'Secret';
  String _selectedCountryCode = '+1';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _loading = true);
    try {
      final uid = _auth.currentUser!.uid;
      final doc = await _firestore.collection('users').doc(uid).get();
      final data = doc.data();

      _nameController.text = data?['name'] ?? '';
      _ageController.text = data?['age']?.toString() ?? '';
      _bioController.text = data?['bio'] ?? '';
      _photoController.text = data?['photoUrl'] ?? '';
      _bgPhotoController.text = data?['backgroundUrl'] ?? '';
      _selectedPronoun = data?['pronouns'] ?? 'Secret';
      _phoneController.text = data?['phone'] ?? '';

      // Extract country code if phone starts with it
      if (_phoneController.text.startsWith('+')) {
        final parts = _phoneController.text.split(' ');
        if (parts.length > 1) {
          _selectedCountryCode = parts[0];
          _phoneController.text = parts.sublist(1).join(' ');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);
    try {
      final uid = _auth.currentUser!.uid;
      String fullPhone =
          '${_selectedCountryCode.trim()} ${_phoneController.text.trim()}';
      await _firestore.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'bio': _bioController.text.trim(),
        'photoUrl': _photoController.text.trim(),
        'backgroundUrl': _bgPhotoController.text.trim(),
        'pronouns': _selectedPronoun,
        'phone': fullPhone,
      }, SetOptions(merge: true));
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteField(String field) async {
    setState(() => _loading = true);
    try {
      final uid = _auth.currentUser!.uid;
      await _firestore.collection('users').doc(uid).update({
        field: FieldValue.delete(),
      });
      await _loadProfile();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to delete $field: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showImageEditDialog(
      String title, TextEditingController controller, String firestoreField) {
    final tempController = TextEditingController(text: controller.text);
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('$title Edit'),
          content: TextField(
            controller: tempController,
            decoration: InputDecoration(
              labelText: '$title URL',
            ),
          ),
          actions: [
            TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  // Delete image URL field
                  await _deleteField(firestoreField);
                  setState(() {
                    controller.text = '';
                  });
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                )),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() {
                  controller.text = tempController.text.trim();
                });
              },
              child: const Text('Edit'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildReadRow(String label, String value, {VoidCallback? onDelete}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value.isEmpty ? 'No $label' : value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
                size: 22,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final profileUrl = _photoController.text.isNotEmpty
        ? _photoController.text
        : user?.photoURL ??
        'https://www.gravatar.com/avatar/placeholder?d=mp';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  // Background and profile pic stack
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      _bgPhotoController.text.isNotEmpty
                          ? Image.network(
                        _bgPhotoController.text,
                        width: double.infinity,
                        height: 180,
                        fit: BoxFit.cover,
                      )
                          : Container(
                        width: double.infinity,
                        height: 180,
                        color: Colors.grey[300],
                        alignment: Alignment.center,
                        child: const Text(
                          'No background picture yet',
                          style: TextStyle(
                              color: Colors.black54, fontSize: 16),
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white),
                          onPressed: () => _showImageEditDialog(
                              'Background Image',
                              _bgPhotoController,
                              'backgroundUrl'),
                        ),
                      ),
                      Positioned(
                        bottom: -40,
                        left: 16,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(profileUrl),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white),
                              onPressed: () => _showImageEditDialog(
                                  'Profile Picture',
                                  _photoController,
                                  'photoUrl'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text
                                    : 'No name',
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  setState(() => _isEditing = !_isEditing),
                              icon: Icon(
                                _isEditing ? Icons.close : Icons.edit,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_isEditing) ...[
                          _buildTextField('Name', _nameController),
                          _buildTextField('Photo URL', _photoController),
                          _buildTextField('Background URL', _bgPhotoController),
                          _buildTextField('Age', _ageController,
                              keyboardType: TextInputType.number),
                          _buildTextField('Bio', _bioController, maxLines: 3),
                          DropdownButtonFormField<String>(
                            value: _selectedPronoun,
                            items: const [
                              DropdownMenuItem(value: 'He', child: Text('He')),
                              DropdownMenuItem(value: 'She', child: Text('She')),
                              DropdownMenuItem(
                                  value: 'Secret', child: Text('Secret')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedPronoun = val);
                              }
                            },
                            decoration:
                            const InputDecoration(labelText: 'Pronouns'),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              SizedBox(
                                width: 80,
                                child: DropdownButtonFormField<String>(
                                  value: _selectedCountryCode,
                                  items: const [
                                    DropdownMenuItem(
                                        value: '+1', child: Text('+1')),
                                    DropdownMenuItem(
                                        value: '+62', child: Text('+62')),
                                    DropdownMenuItem(
                                        value: '+91', child: Text('+91')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() => _selectedCountryCode = val);
                                    }
                                  },
                                  decoration:
                                  const InputDecoration(labelText: 'Code'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildTextField(
                                  'Phone Number',
                                  _phoneController,
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          _buildReadRow('Age', _ageController.text,
                              onDelete: () => _deleteField('age')),
                          _buildReadRow('Bio', _bioController.text,
                              onDelete: () => _deleteField('bio')),
                          _buildReadRow('Pronouns', _selectedPronoun),
                          _buildReadRow('Phone',
                              '${_selectedCountryCode} ${_phoneController.text}'),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isEditing)
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ElevatedButton(
                onPressed: _saveProfile,
                child: const Text('Save Profile'),
              ),
            ),
        ],
      ),
    );
  }
}
