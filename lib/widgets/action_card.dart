import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/admin_analytics_models.dart';

class AdminActionCard extends StatelessWidget {
  final AdminActionItem item;
  final VoidCallback onTap;
  final bool isDark;

  const AdminActionCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.isDark,
  });

  Color get _color {
    try {
      return Color(int.parse(item.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      return const Color(0xFF7C3AED);
    }
  }

  IconData get _icon {
    switch (item.icon) {
      case 'verified_user':
        return Icons.verified_user_rounded;
      case 'payments':
        return Icons.payments_rounded;
      case 'flag':
        return Icons.flag_rounded;
      case 'support_agent':
        return Icons.support_agent_rounded;
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'schedule':
        return Icons.schedule_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF141A2C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _color.withOpacity(0.25), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: _color.withOpacity(0.06),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, color: _color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1A1A2E),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.count != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${item.count}',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: _color,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward_rounded,
                  size: 14, color: _color),
            ),
          ],
        ),
      ),
    );
  }
}