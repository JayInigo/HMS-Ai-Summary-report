import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AiSummaryScreen extends StatefulWidget {
  const AiSummaryScreen({super.key});

  @override
  State<AiSummaryScreen> createState() => _AiSummaryScreenState();
}

class _AiSummaryScreenState extends State<AiSummaryScreen> {
  // Parsed report sections
  String _totalCheckins = '';
  String _roomBreakdown = '';
  String _guestBreakdown = '';
  String _revenueEstimate = '';
  String _recommendations = '';

  bool _isLoading = false;
  bool _hasFetched = false;
  String? _errorMessage;

  // ── Replace with your actual Groq API key ───────────────────────────────
  // Get a FREE key at: https://console.groq.com → API Keys → Create API Key
  static const String _apiKey = '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';
  // ─────────────────────────────────────────────────────────────────────────

  // Room pricing for revenue estimate (in PHP)
  static const Map<String, int> _roomRates = {
    'Deluxe': 3500,
    'Suite': 6500,
    'Standard': 1800,
  };

  Future<void> _generateSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _totalCheckins = '';
      _roomBreakdown = '';
      _guestBreakdown = '';
      _revenueEstimate = '';
      _recommendations = '';
    });

    try {
      // 1. Fetch all check-ins from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('hotel_checkins')
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No check-in records found to summarize.';
        });
        return;
      }

      // 2. Pre-compute stats locally
      final total = snapshot.docs.length;
      final roomCounts = <String, int>{};
      final guestCounts = <String, int>{};
      int revenueTotal = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final room = data['roomType'] as String? ?? 'Unknown';
        final guest = data['guestStatus'] as String? ?? 'Unknown';
        roomCounts[room] = (roomCounts[room] ?? 0) + 1;
        guestCounts[guest] = (guestCounts[guest] ?? 0) + 1;
        revenueTotal += _roomRates[room] ?? 0;
      }

      // 3. Build structured data string for AI
      final buffer = StringBuffer();
      buffer.writeln('HOTEL CHECK-IN DATA FOR VELOUR GRAND HOTEL');
      buffer.writeln('Total Check-ins: $total');
      buffer.writeln();
      buffer.writeln('Room Type Counts:');
      roomCounts.forEach((k, v) => buffer.writeln('  $k: $v guests'));
      buffer.writeln();
      buffer.writeln('Guest Status Counts:');
      guestCounts.forEach((k, v) => buffer.writeln('  $k: $v guests'));
      buffer.writeln();
      buffer.writeln(
          'Room Rates: Deluxe=₱3,500/night, Suite=₱6,500/night, Standard=₱1,800/night');
      buffer.writeln('Estimated Total Revenue: ₱$revenueTotal');

      final checkInData = buffer.toString();

      // 4. Send to Groq API (free, no credit card needed)
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-8b-instant',
          'max_tokens': 1024,
          'temperature': 0.7,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a hotel management AI assistant for Velour Grand Hotel in the Philippines. '
                  'You generate structured business summary reports. '
                  'Always respond in exactly this format with these exact section headers, nothing else:\n\n'
                  'TOTAL CHECK-INS:\n[your content]\n\n'
                  'ROOM TYPE BREAKDOWN:\n[your content]\n\n'
                  'GUEST STATUS BREAKDOWN:\n[your content]\n\n'
                  'REVENUE ESTIMATE:\n[your content]\n\n'
                  'MANAGEMENT RECOMMENDATIONS:\n[your content]',
            },
            {
              'role': 'user',
              'content':
                  'Generate a professional business summary report using this data:\n\n$checkInData\n\n'
                  'For each section, write 2-3 clear, professional sentences. '
                  'For revenue, explain the estimate and what it means for the business. '
                  'For recommendations, give 2 specific actionable tips for management.',
            }
          ],
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final text =
            responseData['choices'][0]['message']['content'] as String;
        _parseReport(text);
        setState(() => _hasFetched = true);
      } else {
        final errorData = jsonDecode(response.body);
        setState(() {
          _errorMessage =
              'API Error: ${errorData['error']?['message'] ?? response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _parseReport(String text) {
    String extract(String header, String nextHeader) {
      final start = text.indexOf(header);
      if (start == -1) return '';
      final contentStart = start + header.length;
      final end = nextHeader.isNotEmpty
          ? text.indexOf(nextHeader, contentStart)
          : text.length;
      return text
          .substring(contentStart, end == -1 ? text.length : end)
          .trim();
    }

    setState(() {
      _totalCheckins =
          extract('TOTAL CHECK-INS:', 'ROOM TYPE BREAKDOWN:');
      _roomBreakdown =
          extract('ROOM TYPE BREAKDOWN:', 'GUEST STATUS BREAKDOWN:');
      _guestBreakdown =
          extract('GUEST STATUS BREAKDOWN:', 'REVENUE ESTIMATE:');
      _revenueEstimate =
          extract('REVENUE ESTIMATE:', 'MANAGEMENT RECOMMENDATIONS:');
      _recommendations = extract('MANAGEMENT RECOMMENDATIONS:', '');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a0010),
      appBar: AppBar(
        title: const Text(
          'AI Business Summary',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF8B0000),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Dark Hero Header ──────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8B0000), Color(0xFF1a0010)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            color: Colors.amber, size: 13),
                        SizedBox(width: 5),
                        Text(
                          'AI-POWERED',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Daily Business\nSummary Report',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Velour Grand Hotel  •  ${_formatDate(DateTime.now())}',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────────
            Container(
              color: const Color(0xFFF2F2F2),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 4),

                  // Generate button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _generateSummary,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome,
                              color: Colors.white, size: 18),
                      label: Text(
                        _isLoading
                            ? 'Generating Report...'
                            : _hasFetched
                                ? 'Regenerate Report'
                                : 'Generate AI Report',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B0000),
                        disabledBackgroundColor:
                            const Color(0xFF8B0000).withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Error
                  if (_errorMessage != null) _errorCard(_errorMessage!),

                  // Loading
                  if (_isLoading) _loadingCard(),

                  // Report sections
                  if (_hasFetched && !_isLoading) ...[
                    _reportSection(
                      icon: Icons.people_alt,
                      color: const Color(0xFF8B0000),
                      title: 'Total Check-Ins',
                      content: _totalCheckins,
                    ),
                    _reportSection(
                      icon: Icons.hotel,
                      color: const Color(0xFF5D4037),
                      title: 'Room Type Breakdown',
                      content: _roomBreakdown,
                    ),
                    _reportSection(
                      icon: Icons.person_search,
                      color: const Color(0xFF1565C0),
                      title: 'Guest Status Breakdown',
                      content: _guestBreakdown,
                    ),
                    _reportSection(
                      icon: Icons.payments,
                      color: const Color(0xFF2E7D32),
                      title: 'Revenue Estimate',
                      content: _revenueEstimate,
                    ),
                    _reportSection(
                      icon: Icons.lightbulb,
                      color: const Color(0xFFE65100),
                      title: 'Management Recommendations',
                      content: _recommendations,
                      isLast: true,
                    ),
                  ],

                  // Placeholder
                  if (!_isLoading && !_hasFetched && _errorMessage == null)
                    _placeholderCard(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportSection({
    required IconData icon,
    required Color color,
    required String title,
    required String content,
    bool isLast = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header bar
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.1,
                  ),
                ),
              ],
            ),
          ),
          // Section content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content.isNotEmpty ? content : '—',
              style: const TextStyle(
                fontSize: 14,
                height: 1.65,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _loadingCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(color: Color(0xFF8B0000)),
          SizedBox(height: 16),
          Text(
            'Reading check-in records\nand generating your report...',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _placeholderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: const Column(
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No Report Generated Yet',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            'Tap "Generate AI Report" above to create\na full business summary from your check-in data.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}