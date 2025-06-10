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

  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color accentBlue = Color(0xFF1976D2);

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
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')));
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
        'phone': _phoneController.text.trim().isEmpty
            ? ''
            : '$_countryCode ${_phoneController.text.trim()}',
        'photoUrl': _photoUrl,
        'backgroundUrl': _backgroundUrl,
      }, SetOptions(merge: true));
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _onBackgroundPhotoAction() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: darkBlue),
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
      final url = await _showImageUrlDialog(true);
      if (url != null && url.isNotEmpty) setState(() => _backgroundUrl = url);
    } else if (action == 'delete') {
      setState(() => _backgroundUrl = '');
    }
  }

  Future<void> _onProfilePhotoAction() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit, color: darkBlue),
            title: const Text('Edit Profile Photo'),
            onTap: () => Navigator.pop(context, 'edit'),
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.redAccent),
            title: const Text('Delete Profile Photo'),
            onTap: () => Navigator.pop(context, 'delete'),
          ),
        ],
      ),
    );

    if (action == 'edit') {
      final url = await _showImageUrlDialog(false);
      if (url != null && url.isNotEmpty) setState(() => _photoUrl = url);
    } else if (action == 'delete') {
      setState(() => _photoUrl = '');
    }
  }

  Future<String?> _showImageUrlDialog(bool isBackground) async {
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: darkBlue),
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save')),
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
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: accentBlue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: darkBlue, width: 2),
          ),
          labelStyle: const TextStyle(color: darkBlue),
        ),
      ),
    );
  }

  Widget _infoContainer(String label, String value,
      {bool showDelete = false, VoidCallback? onDelete}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: accentBlue.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, color: darkBlue, fontSize: 14)),
                const SizedBox(height: 6),
                Text(value.isNotEmpty ? value : 'No $label yet',
                    style: const TextStyle(fontSize: 16, color: Colors.black87)),
              ],
            ),
          ),
          if (showDelete && onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: onDelete,
              tooltip: 'Delete $label',
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBlue,
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'User Settings',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: darkBlue,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: darkBlue))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Background and profile photo UI
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _backgroundUrl.isNotEmpty
                      ? Image.network(
                    _backgroundUrl,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) =>
                    progress == null
                        ? child
                        : Container(
                      width: double.infinity,
                      height: 180,
                      color: Colors.grey[200],
                      child: const Center(
                          child: CircularProgressIndicator()),
                    ),
                    errorBuilder: (context, error, stackTrace) =>
                        Container(
                          width: double.infinity,
                          height: 180,
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.broken_image, size: 48),
                          ),
                        ),
                  )
                      : Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text(
                        'No background picture yet',
                        style: TextStyle(
                            fontSize: 16, color: Colors.black54),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: darkBlue.withOpacity(0.8),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: _onBackgroundPhotoAction,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: 16,
                  child: CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.white,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundImage: _photoUrl.isNotEmpty
                              ? NetworkImage(_photoUrl)
                              : null,
                          child: _photoUrl.isEmpty
                              ? const Icon(Icons.person, size: 40)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: darkBlue.withOpacity(0.8),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 18,
                              icon: const Icon(Icons.camera_alt,
                                  color: Colors.white),
                              onPressed: _onProfilePhotoAction,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),
            _isEditing
                ? _buildTextField('Name', _nameController)
                : _infoContainer('Name', _nameController.text),
            _isEditing
                ? _buildTextField('Age', _ageController,
                keyboardType: TextInputType.number)
                : _infoContainer('Age', _ageController.text),
            _isEditing
                ? _buildTextField('Bio', _bioController, maxLines: 4)
                : _infoContainer('Bio', _bioController.text),
            const SizedBox(height: 8),
            _isEditing
                ? Container(
              padding: const EdgeInsets.symmetric(
                  vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border:
                Border.all(color: accentBlue.withOpacity(0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _pronounsController.text.isEmpty
                      ? 'Secret'
                      : _pronounsController.text,
                  items: const [
                    DropdownMenuItem(value: 'He', child: Text('He')),
                    DropdownMenuItem(value: 'She', child: Text('She')),
                    DropdownMenuItem(
                        value: 'Secret', child: Text('Secret')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _pronounsController.text = val;
                      });
                    }
                  },
                ),
              ),
            )
                : _infoContainer('Pronouns', _pronounsController.text),
            const SizedBox(height: 8),
            _isEditing
                ? Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: accentBlue.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _countryCode,
                      items: _countryCodes
                          .map((code) => DropdownMenuItem(
                        value: code,
                        child: Text(code),
                      ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _countryCode = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField('Phone Number',
                      _phoneController,
                      keyboardType: TextInputType.phone),
                )
              ],
            )
                : _infoContainer('Phone Number',
                _phoneController.text.isNotEmpty
                    ? '$_countryCode ${_phoneController.text}'
                    : ''),
          ],
        ),
      ),
    );
  }
}
