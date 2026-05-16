import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

class AddCheckInScreen extends StatefulWidget {
  const AddCheckInScreen({super.key});

  @override
  State<AddCheckInScreen> createState() => _AddCheckInScreenState();
}

class _AddCheckInScreenState extends State<AddCheckInScreen> {
  final _clientnameController = TextEditingController();

  String? _selectedRoomType;
  String? _selectedGuestStatus;

  final List<String> _roomTypeOptions = ['Deluxe', 'Suite', 'Standard'];

  final List<String> _guestStatusOptions = [
    'Leisure/Vacationers',
    'Business Travelers/Corporate',
    'Staycationers/Locals',
    'Walk-in Guests',
    'VIP Guests',
  ];

  Uint8List? _selectedImageBytes;
  double? _lat;
  double? _lng;
  bool _isSaving = false;

  final String _groupName = 'HMS';

  String get _proofLabel {
    final now = DateTime.now();
    final monthDay =
        '${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return '$_groupName-Hotel-$monthDay';
  }

  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70, maxWidth: 800);
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() => _selectedImageBytes = bytes);
    }
  }

  Future<void> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { _showSnack('Please enable location services.'); return; }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        _showSnack('Location permission denied. Please allow in browser.'); return;
      }
      _showSnack('Getting location...');
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() { _lat = pos.latitude; _lng = pos.longitude; });
    } catch (e) {
      _showSnack('Location error: $e');
    }
  }

  Future<void> _save() async {
    if (_clientnameController.text.isEmpty || _selectedRoomType == null ||
        _selectedGuestStatus == null || _selectedImageBytes == null || _lat == null) {
      _showSnack('Please fill all fields, add photo, and get location.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      final base64Image = base64Encode(_selectedImageBytes!);
      final docRef = FirebaseFirestore.instance.collection('hotel_checkins').doc();
      await docRef.set({
        'clientName': _clientnameController.text.trim(),
        'roomType': _selectedRoomType,
        'guestStatus': _selectedGuestStatus,
        'photoBase64': base64Image,
        'lat': _lat,
        'lng': _lng,
        'createdBy': _groupName,
        'proofLabel': _proofLabel,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _showSnack('Check-in saved successfully!');
      Navigator.pop(context);
    } catch (e) {
      _showSnack('Error saving: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Check-In',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF8B0000),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // White background
          Container(color: Colors.white),
          // Logo watermark
          Positioned.fill(
            child: Opacity(
              opacity: 0.20,
              child: Image.asset(
                'assets/images/velour_grand.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          // Content
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B0000).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF8B0000).withOpacity(0.3)),
                  ),
                  child: Text('Proof: $_proofLabel',
                      style: const TextStyle(color: Color(0xFF8B0000), fontWeight: FontWeight.bold, fontSize: 13)),
                ),
                const SizedBox(height: 20),

                _sectionLabel('Client Name'),
                _buildInput(_clientnameController, 'e.g. Juan Dela Cruz'),
                const SizedBox(height: 16),

                _sectionLabel('Room Type'),
                const SizedBox(height: 4),
                _buildDropdown(
                  value: _selectedRoomType,
                  hint: 'Select room type',
                  items: _roomTypeOptions,
                  onChanged: (value) => setState(() => _selectedRoomType = value),
                ),
                const SizedBox(height: 16),

                _sectionLabel('Guest Status'),
                const SizedBox(height: 4),
                _buildDropdown(
                  value: _selectedGuestStatus,
                  hint: 'Select guest status',
                  items: _guestStatusOptions,
                  onChanged: (value) => setState(() => _selectedGuestStatus = value),
                ),
                const SizedBox(height: 24),

                _sectionLabel('Photo'),
                const SizedBox(height: 8),
                if (_selectedImageBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_selectedImageBytes!,
                        height: 180, width: double.infinity, fit: BoxFit.cover),
                  )
                else
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Center(child: Icon(Icons.photo_library, size: 48, color: Colors.grey)),
                  ),
                const SizedBox(height: 10),
                _actionButton(icon: Icons.photo_library, label: 'Gallery', onTap: _pickImageFromGallery, fullWidth: true),
                const SizedBox(height: 20),

                _sectionLabel('Location (GPS)'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _lat != null ? Colors.green.withOpacity(0.08) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _lat != null ? Colors.green : Colors.grey[300]!),
                  ),
                  child: Text(
                    _lat != null
                        ? '📍 Lat: ${_lat!.toStringAsFixed(6)}\n    Lng: ${_lng!.toStringAsFixed(6)}'
                        : 'No location captured yet.',
                    style: TextStyle(color: _lat != null ? Colors.green[800] : Colors.grey, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 10),
                _actionButton(icon: Icons.my_location, label: 'Get My Location', onTap: _getLocation, fullWidth: true),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B0000),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('SAVE CHECK-IN',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87));

  Widget _buildInput(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF8B0000))),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey))),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF8B0000)),
        hint: Text(hint, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        items: items.map((item) => DropdownMenuItem<String>(value: item, child: Text(item, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _actionButton({required IconData icon, required String label, required VoidCallback onTap, bool fullWidth = false}) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: const Color(0xFF8B0000), size: 18),
        label: Text(label, style: const TextStyle(color: Color(0xFF8B0000))),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF8B0000)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
