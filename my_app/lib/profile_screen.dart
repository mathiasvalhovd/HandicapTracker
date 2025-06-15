import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_controller.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController _controller;

  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color darkBlue = Color(0xFF0D47A1);
  static const Color accentBlue = Color(0xFF1976D2);

  @override
  void initState() {
    super.initState();
    _controller = ProfileController();
    _controller.loadProfile(context, _refresh);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
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
            borderSide: const BorderSide(color: accentBlue),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: darkBlue, width: 2),
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
                        fontWeight: FontWeight.bold,
                        color: darkBlue,
                        fontSize: 14)),
                const SizedBox(height: 6),
                Text(value.isNotEmpty ? value : 'No $label yet',
                    style:
                    const TextStyle(fontSize: 16, color: Colors.black87)),
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
        title: const Text('User Settings', style: TextStyle(color: Colors.white)),
        backgroundColor: darkBlue,
        elevation: 0,
      ),
      body: _controller.loading
          ? const Center(child: CircularProgressIndicator(color: darkBlue))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Background & profile image
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _controller.backgroundUrl.isNotEmpty
                      ? Image.network(
                    _controller.backgroundUrl,
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
                        child: CircularProgressIndicator(),
                      ),
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
                      onPressed: () => _controller.onBackgroundPhotoAction(
                          context, _refresh),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: 16,
                  child: CircleAvatar(
                    radius: 64,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: _controller.photoUrl.isNotEmpty
                          ? NetworkImage(_controller.photoUrl)
                          : null,
                      child: _controller.photoUrl.isEmpty
                          ? const Icon(Icons.person, size: 60)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // 🔧 Edit icon above Name section
            if (!_controller.isEditing)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: darkBlue),
                    tooltip: 'Edit Profile',
                    onPressed: () =>
                        setState(() => _controller.isEditing = true),
                  ),
                ),
              ),

            // Name & profile pic URL (edit or display)
            _controller.isEditing
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField('Name', _controller.nameController),
                _buildTextField('Profile Pic URL',
                    _controller.photoUrlController),
              ],
            )
                : _infoContainer('Name', _controller.nameController.text),

            // Age
            _controller.isEditing
                ? _buildTextField('Age', _controller.ageController,
                keyboardType: TextInputType.number)
                : _infoContainer('Age', _controller.ageController.text),

            // Bio
            _controller.isEditing
                ? _buildTextField('Bio', _controller.bioController,
                maxLines: 2)
                : _infoContainer('Bio', _controller.bioController.text),

            const SizedBox(height: 8),

            // Pronouns
            _controller.isEditing
                ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8.0, bottom: 4),
                  child: Text(
                    'Pronouns',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: darkBlue,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
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
                      isExpanded: true,
                      value: _controller.pronounsController.text.isEmpty
                          ? 'Secret'
                          : _controller.pronounsController.text,
                      items: const [
                        DropdownMenuItem(
                            value: 'He', child: Text('He')),
                        DropdownMenuItem(
                            value: 'She', child: Text('She')),
                        DropdownMenuItem(
                            value: 'Secret', child: Text('Secret')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _controller
                              .pronounsController.text = val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            )
                : _infoContainer(
                'Pronouns', _controller.pronounsController.text),

            const SizedBox(height: 8),

            // Phone Number
            _controller.isEditing
                ? Row(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: accentBlue.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _controller.countryCode,
                      items: _controller.countryCodes
                          .map((code) => DropdownMenuItem(
                        value: code,
                        child: Text(code),
                      ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() =>
                          _controller.countryCode = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField('Phone Number',
                      _controller.phoneController,
                      keyboardType: TextInputType.phone),
                ),
              ],
            )
                : _infoContainer(
                'Phone Number',
                _controller.phoneController.text.isNotEmpty
                    ? '${_controller.countryCode} ${_controller.phoneController.text}'
                    : ''),

            // Save button
            if (_controller.isEditing)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: darkBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () =>
                        _controller.saveProfile(context, _refresh),
                    child: const Text(
                      'Save',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
