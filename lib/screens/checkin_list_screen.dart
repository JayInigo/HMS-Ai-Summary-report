import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_checkin_screen.dart';
import 'welcome_screen.dart';
import 'ai_summary_screen.dart';

class CheckInListScreen extends StatelessWidget {
  const CheckInListScreen({super.key});

  Future<void> _deleteEntry(BuildContext context, String docId, String photoUrl) async {
    try {
      await FirebaseFirestore.instance.collection('hotel_checkins').doc(docId).delete();
      if (photoUrl.isNotEmpty) {
        await FirebaseStorage.instance.refFromURL(photoUrl).delete();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check-in deleted.'), backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showDetail(BuildContext context, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        builder: (_, controller) => SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              if (data['photoUrl'] != null && data['photoUrl'].isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(data['photoUrl'], height: 200, width: double.infinity, fit: BoxFit.cover),
                ),
              const SizedBox(height: 16),
              _detailRow('Client Name', data['clientName'] ?? ''),
              _detailRow('Room Type', data['roomType'] ?? ''),
              _detailRow('Guest Status', data['guestStatus'] ?? ''),
              _detailRow('Location', 'Lat: ${data['lat']?.toStringAsFixed(5)}, Lng: ${data['lng']?.toStringAsFixed(5)}'),
              _detailRow('Created By', data['createdBy'] ?? ''),
              _detailRow('Proof Label', data['proofLabel'] ?? ''),
              _detailRow('Date', data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate().toString() : ''),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B0000))),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Hotel Check-In Log',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF8B0000),
        automaticallyImplyLeading: false,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Colors.white),
          tooltip: 'Logout',
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Logout?'),
                content: const Text('Are you sure you want to log out?'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.auto_awesome, color: Colors.white),
                    tooltip: 'AI Summary',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiSummaryScreen()),
                    ),
                  ),
                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Logout', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
            if (confirm == true) {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                (route) => false,
              );
            }
          },
        ),
        actions: [                          // 👈 ADD THIS
    IconButton(
      icon: const Icon(Icons.auto_awesome, color: Colors.white),
      tooltip: 'AI Summary',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AiSummaryScreen()),
      ),
    ),
  ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AddCheckInScreen())),
        backgroundColor: const Color(0xFF8B0000),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Check-In', style: TextStyle(color: Colors.white)),
      ),
      body: Stack(
        children: [
          // Subtle logo watermark on the list background
          Positioned.fill(
            child: Opacity(
              opacity: 0.04,
              child: Image.asset(
                'assets/images/velour_grand.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('hotel_checkins')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF8B0000)));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.list_alt, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('No check-ins yet.\nTap + to add one.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                );
              }

              final docs = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final date = data['createdAt'] != null
                      ? (data['createdAt'] as Timestamp).toDate()
                      : DateTime.now();

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: data['photoUrl'] != null && data['photoUrl'].isNotEmpty
                            ? Image.network(data['photoUrl'], width: 56, height: 56, fit: BoxFit.cover)
                            : Container(
                                width: 56, height: 56,
                                color: const Color(0xFF8B0000).withOpacity(0.1),
                                child: const Icon(Icons.hotel, color: Color(0xFF8B0000)),
                              ),
                      ),
                      title: Text(data['clientName'] ?? data['clientName'] ?? 'Unknown Client',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Room: ${data['roomType'] ?? '-'}',
                              style: const TextStyle(color: Color(0xFF8B0000))),
                          Text(
                            '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete Check-In?'),
                              content: const Text('This will remove the record and photo permanently.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete', style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            _deleteEntry(context, doc.id, data['photoUrl'] ?? '');
                          }
                        },
                      ),
                      onTap: () => _showDetail(context, data),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}