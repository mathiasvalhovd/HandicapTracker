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
  final _pronounsController = TextEditingController(text: 'Secret');
  final _phoneController = TextEditingController();

  String _photoUrl = '';
  String _backgroundUrl = '';
  String _countryCode = '+62';

  final List<String> _countryCodes = ['+1', '+44', '+62', '+91', '+81'];

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
      _pronounsController.text = data?['pronouns'] ?? 'Secret';
      _phoneController.text = data?['phone']?.replaceFirst(RegExp(r'^\+\d+\s?'), '') ?? '';
      _photoUrl = data?['photoUrl'] ?? '';
      _backgroundUrl = data?['backgroundUrl'] ?? '';

      if (data?['phone'] != null && data!['phone'].toString().contains(' ')) {
        _countryCode = data['phone'].toString().split(' ')[0];
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _loading = true);
    try {
      final uid = _auth.currentUser!.uid;
      await _firestore.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'bio': _bioController.text.trim(),
        'pronouns': _pronounsController.text.trim(),
        'phone': '$_countryCode ${_phoneController.text.trim()}',
        'photoUrl': _photoUrl,
        'backgroundUrl': _backgroundUrl,
      }, SetOptions(merge: true));
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save profile: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onBackgroundPhotoAction() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Background Photo'),
            onTap: () => Navigator.pop(context, 'edit'),
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Delete Background Photo'),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
        ],
      ),
    );

    if (action == 'edit') {
      final url = await _showImageUrlDialog(true);
      if (url != null) setState(() => _backgroundUrl = url);
    } else if (action == 'delete') {
      setState(() => _backgroundUrl = '');
    }
  }

  Future<String?> _showImageUrlDialog(bool isBackground) async {
    final controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter ${isBackground ? 'background' : 'profile'} photo URL'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Image URL')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
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
          alignLabelWithHint: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _infoContainer(String label, String value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value.isNotEmpty ? value : 'No $label yet', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _backgroundUrl.isNotEmpty
                    ? Image.network(
                  _backgroundUrl,
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                )
                    : Container(
                  width: double.infinity,
                  height: 180,
                  color: Colors.grey[300],
                  alignment: Alignment.center,
                  child: const Text('No background picture yet',
                      style: TextStyle(color: Colors.black54)),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.black54,
                    child: IconButton(
                      onPressed: _onBackgroundPhotoAction,
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: 16,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 36,
                      backgroundImage: _photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null,
                      child: _photoUrl.isEmpty ? const Icon(Icons.person, size: 36) : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 56),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _nameController.text.isNotEmpty ? _nameController.text : 'No name yet',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => _isEditing = !_isEditing),
                  icon: Icon(_isEditing ? Icons.close : Icons.edit),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_isEditing) ...[
              _buildTextField('Name', _nameController),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextField(
                  controller: TextEditingController(text: _photoUrl)
                    ..selection = TextSelection.collapsed(offset: _photoUrl.length),
                  onChanged: (value) => setState(() => _photoUrl = value),
                  decoration: InputDecoration(
                    labelText: 'Profile Photo URL',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              _buildTextField('Age', _ageController, keyboardType: TextInputType.number),
              _buildTextField('Bio', _bioController, maxLines: 3),
              DropdownButtonFormField<String>(
                value: _pronounsController.text.isNotEmpty ? _pronounsController.text : 'Secret',
                items: const [
                  DropdownMenuItem(value: 'He', child: Text('He')),
                  DropdownMenuItem(value: 'She', child: Text('She')),
                  DropdownMenuItem(value: 'Secret', child: Text('Secret')),
                ],
                onChanged: (val) => setState(() => _pronounsController.text = val ?? 'Secret'),
                decoration: const InputDecoration(labelText: 'Pronouns'),
              ),
              Row(
                children: [
                  DropdownButton<String>(
                    value: _countryCode,
                    onChanged: (val) => setState(() => _countryCode = val ?? '+62'),
                    items: _countryCodes
                        .map((code) => DropdownMenuItem(value: code, child: Text(code)))
                        .toList(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField('Phone Number', _phoneController,
                        keyboardType: TextInputType.phone),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _saveProfile, child: const Text('Save Profile')),
            ] else ...[
              _infoContainer('Age', _ageController.text),
              _infoContainer('Bio', _bioController.text),
              _infoContainer('Pronouns', _pronounsController.text),
              _infoContainer(
                  'Phone Number',
                  _phoneController.text.isNotEmpty
                      ? '$_countryCode ${_phoneController.text}'
                      : ''),
            ],
          ],
        ),
      ),
    );
  }
}
