import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A colour-coded chip that displays the status of a maintenance request
/// or shuttle booking.
///
/// Usage:
///   StatusChip(status: 'in_progress')
///   StatusChip(status: 'resolved')
class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, textColor, bgColor) = _resolve(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  /// Returns (label, foreground color, background color) for each status.
  (String, Color, Color) _resolve(String s) {
    switch (s.toLowerCase().replaceAll(' ', '_').replaceAll('-', '_')) {
      case 'submitted':
        return ('Submitted', AppColors.statusSubmitted,
            AppColors.statusSubmitted.withOpacity(0.12));
      case 'pending':
        return ('Pending', AppColors.warning,
            AppColors.warning.withOpacity(0.12));
      case 'acknowledged':
        return ('Acknowledged', AppColors.statusAcknowledged,
            AppColors.statusAcknowledged.withOpacity(0.12));
      case 'assigned':
        return ('Assigned', AppColors.info,
            AppColors.info.withOpacity(0.12));
      case 'in_progress':
        return ('In Progress', AppColors.statusInProgress,
            AppColors.statusInProgress.withOpacity(0.12));
      case 'resolved':
        return ('Resolved', AppColors.success,
            AppColors.success.withOpacity(0.12));
      case 'closed':
        return ('Closed', AppColors.statusCancelled,
            AppColors.statusCancelled.withOpacity(0.1));
      case 'cancelled':
        return ('Cancelled', AppColors.statusCancelled,
            AppColors.statusCancelled.withOpacity(0.1));
      case 'confirmed':
        return ('Confirmed', AppColors.success,
            AppColors.success.withOpacity(0.12));
      default:
        return (s, AppColors.textSecondary, AppColors.divider);
    }
  }
}
