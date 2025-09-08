import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedThreshold = 30;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final threshold = await SettingsService.getExpiringThreshold();
    setState(() {
      _selectedThreshold = threshold;
      _isLoading = false;
    });
  }

  Future<void> _saveThreshold(int threshold) async {
    await SettingsService.setExpiringThreshold(threshold);
    setState(() {
      _selectedThreshold = threshold;
    });
    
    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Expiring threshold set to ${SettingsService.getThresholdDisplayText(threshold)}'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warranty Settings Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Warranty Settings',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose when items should be considered "expiring soon"',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Threshold Options
                  ...SettingsService.getThresholdOptions().map((threshold) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () => _saveThreshold(threshold),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _selectedThreshold == threshold
                                ? const Color(0xFFF0FDF4)
                                : const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedThreshold == threshold
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFE5E7EB),
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _selectedThreshold == threshold
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: _selectedThreshold == threshold
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF9CA3AF),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                SettingsService.getThresholdDisplayText(threshold),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: _selectedThreshold == threshold
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  color: _selectedThreshold == threshold
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF111827),
                                ),
                              ),
                              const Spacer(),
                              if (_selectedThreshold == threshold)
                                const Icon(
                                  Icons.check,
                                  color: Color(0xFF10B981),
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Info Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF10B981),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Items with warranties expiring within your selected timeframe will appear in the "Expiring Soon" section.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
