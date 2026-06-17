import 'package:flutter/material.dart';

class DispatchDialog extends StatelessWidget {
  const DispatchDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'New Vehicle Dispatch',
        style: TextStyle(
          color: Color(0xFF003B46),
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFBE9DB),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Cannot create dispatch. Make sure there is at least one idle Trackman and one idle Vehicle available.',
          style: TextStyle(
            color: Color(0xFFE47911),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: null, // Disabled as per screenshot
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey.shade300,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade600,
          ),
          child: const Text('Dispatch'),
        ),
      ],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}
