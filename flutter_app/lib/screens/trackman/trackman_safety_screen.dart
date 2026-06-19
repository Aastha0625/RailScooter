import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';

class TrackmanSafetyScreen extends StatefulWidget {
  const TrackmanSafetyScreen({super.key});

  @override
  State<TrackmanSafetyScreen> createState() => _TrackmanSafetyScreenState();
}

class _TrackmanSafetyScreenState extends State<TrackmanSafetyScreen> {
  final Map<String, bool> _checks = {
    'Helmet & Safety Vest Secured': false,
    'Brakes Checked and Responsive': false,
    'Headlight & Taillight Functional': false,
    'Two-Way Radio On and Tuned': false,
    'Battery Level Above Minimum Threshold': false,
  };

  bool get _allChecked => _checks.values.every((v) => v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Safety Guidelines'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pre-Ride Checklist',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please complete all safety verifications before initiating your track patrol run.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: _checks.keys.map((key) {
                  return CheckboxListTile(
                    title: Text(
                      key,
                      style: TextStyle(
                        color: _checks[key]! ? AppColors.textPrimary : AppColors.textSecondary,
                        fontWeight: _checks[key]! ? FontWeight.w600 : FontWeight.normal,
                        decoration: _checks[key]! ? TextDecoration.lineThrough : null,
                        decorationColor: Colors.green,
                      ),
                    ),
                    value: _checks[key],
                    activeColor: Colors.green,
                    checkColor: Colors.white,
                    side: const BorderSide(color: AppColors.textLight),
                    onChanged: (bool? value) {
                      setState(() {
                        _checks[key] = value ?? false;
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.severityHigh.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.severityHigh.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.severityHigh, size: 32),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Failure to adhere to safety guidelines may result in disciplinary action. Safety is everyone\'s responsibility.',
                      style: TextStyle(color: AppColors.severityHigh, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _allChecked
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Safety checks confirmed! You are ready to ride.'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        Navigator.pop(context); // Go back to dashboard
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  'Confirm & Start',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _allChecked ? Colors.white : Colors.grey.shade500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
