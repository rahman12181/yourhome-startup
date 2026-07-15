import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusChip extends StatelessWidget {
  final String status;

  const StatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _getColor(status);
    final icon = _getIcon(status);
    final label = _getLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.amber;
      case 'PROCESSING':
        return Colors.blue;
      case 'APPROVED':
        return Colors.green;
      case 'FAILED':
        return Colors.red;
      case 'REJECTED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getIcon(String status) {
    switch (status) {
      case 'PENDING':
        return '⏳';
      case 'PROCESSING':
        return '🔄';
      case 'APPROVED':
        return '✅';
      case 'FAILED':
        return '❌';
      case 'REJECTED':
        return '🚫';
      default:
        return '❓';
    }
  }

  String _getLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'Pending';
      case 'PROCESSING':
        return 'Processing';
      case 'APPROVED':
        return 'Approved';
      case 'FAILED':
        return 'Failed';
      case 'REJECTED':
        return 'Rejected';
      default:
        return status;
    }
  }
}