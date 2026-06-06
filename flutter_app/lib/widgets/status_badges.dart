import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shared status/severity display widgets used across multiple screens.
/// Import this file instead of duplicating these widgets in each screen.

// ─────────────────────────────────────────────────────────────────────────────
// StatusDot — small coloured circle for vehicle status
// ─────────────────────────────────────────────────────────────────────────────
class StatusDot extends StatelessWidget {
  final String status;
  const StatusDot({super.key, required this.status});

  Color get _color {
    switch (status) {
      case 'active':
        return AppColors.statusActive;
      case 'idle':
        return AppColors.statusIdle;
      case 'maintenance':
        return AppColors.statusMaintenance;
      default:
        return AppColors.statusOffline;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// StatusBadge — pill with dot + label text for vehicle status
// ─────────────────────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String status;
  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case 'active':
        return AppColors.statusActive;
      case 'idle':
        return AppColors.statusIdle;
      case 'maintenance':
        return AppColors.statusMaintenance;
      default:
        return AppColors.statusOffline;
    }
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(fontSize: 13, color: _color, fontWeight: FontWeight.w500),
      ),
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SeverityDot — small coloured circle for alert severity
// ─────────────────────────────────────────────────────────────────────────────
class SeverityDot extends StatelessWidget {
  final String severity;
  const SeverityDot({super.key, required this.severity});

  Color get _color {
    switch (severity) {
      case 'critical':
        return AppColors.severityCritical;
      case 'high':
        return AppColors.severityHigh;
      case 'medium':
        return AppColors.severityMedium;
      default:
        return AppColors.severityLow;
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SeverityColor — utility function (not a widget) for getting severity color
// ─────────────────────────────────────────────────────────────────────────────
Color severityColor(String severity) {
  switch (severity) {
    case 'critical':
      return AppColors.severityCritical;
    case 'high':
      return AppColors.severityHigh;
    case 'medium':
      return AppColors.severityMedium;
    default:
      return AppColors.severityLow;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LabelTag — coloured pill tag used across alert and geofence screens
// ─────────────────────────────────────────────────────────────────────────────
class LabelTag extends StatelessWidget {
  final String label;
  final Color color;
  const LabelTag({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// InfoRow — icon + text row used in department and vehicle cards
// ─────────────────────────────────────────────────────────────────────────────
class InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const InfoRow({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textLight),
        const SizedBox(width: 4),
        Expanded(child: Text(text, style: AppTextStyles.bodySmall)),
      ],
    ),
  );
}
