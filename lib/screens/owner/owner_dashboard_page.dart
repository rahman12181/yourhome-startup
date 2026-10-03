// ignore_for_file: deprecated_member_use, unused_import

import 'dart:async';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:yourhome/widgets/no_internet_widget.dart';

import '../../providers/auth_provider.dart';
import '../../providers/owner_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/payment_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/dashboard_model.dart';
import '../chat/chat_list_screen.dart';
import '../notifications/notification_screen.dart';
import 'owner_profile_screen.dart';
import 'owner_my_reels_screen.dart';
import 'owner_reels_upload_screen.dart';
import 'owner_property_management_page.dart';
import 'owner_booking_management_page.dart';
import 'property_access_subscription_page.dart';
import 'listing_subscription_page.dart';
import 'owner_apply_page.dart';

// ══════════════════════════════════════════════════════════════
// ROUTE OBSERVER — register this in main.dart:
//   MaterialApp(navigatorObservers: [routeObserver], ...)
// ══════════════════════════════════════════════════════════════
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

// ============================================================
// DESIGN TOKENS — Blue brand palette
// ============================================================
class _P {
  static const primary = Color(0xFF1E5EFF);
  static const primaryLight = Color(0xFF4B7BFF);
  static const primaryDeep = Color(0xFF1247D6);
  static const primarySoft = Color(0xFFEBF1FF);

  static const sky = Color(0xFF0EA5E9);
  static const indigo = Color(0xFF6366F1);
  static const teal = Color(0xFF06B6D4);

  static const success = Color(0xFF16A34A);
  static const gold = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);

  static const darkBg = Color(0xFF0A0E1A);
  static const darkSurface = Color(0xFF141A2C);
  static const darkCard = Color(0xFF1B2338);
  static const lightBg = Color(0xFFF7F8FC);

  static Color bg(bool d) => d ? darkBg : lightBg;
  static Color card(bool d) => d ? darkSurface : Colors.white;
  static Color ink(bool d) => d ? Colors.white : const Color(0xFF0B1220);
  static Color sub(bool d) =>
      d ? const Color(0xFF9AA3B8) : const Color(0xFF64748B);
  static Color hair(bool d) =>
      d ? Colors.white.withOpacity(0.07) : const Color(0xFFE8ECF4);
  static Color soft(bool d) =>
      d ? Colors.white.withOpacity(0.05) : const Color(0xFFF1F4FB);
}

const double _kPad = 6.0;   

// ============================================================
// SAFE ACCESSORS
// ============================================================
dynamic _d(dynamic Function() f) {
  try {
    return f();
  } catch (_) {
    return null;
  }
}

double _dn(dynamic Function() f, [double def = 0]) {
  try {
    final v = f();
    if (v == null) return def;
    if (v is num) return v.toDouble();
    return double.tryParse('$v') ?? def;
  } catch (_) {
    return def;
  }
}

double? _dnn(dynamic Function() f) {
  try {
    final v = f();
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse('$v');
  } catch (_) {
    return null;
  }
}

int _di(dynamic Function() f, [int def = 0]) {
  try {
    final v = f();
    if (v == null) return def;
    if (v is num) return v.round();
    return int.tryParse('$v') ?? def;
  } catch (_) {
    return def;
  }
}

String _ds(dynamic Function() f, [String def = '']) {
  try {
    final v = f();
    return v == null ? def : v.toString();
  } catch (_) {
    return def;
  }
}

bool _db(dynamic Function() f) => _d(f) == true;

List _dl(dynamic Function() f) {
  final v = _d(f);
  return v is List ? v : const [];
}

// ============================================================
// FORMATTERS
// ============================================================
final NumberFormat _inr0 =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
final NumberFormat _inr2 =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);

String _inr(double v) => (v - v.roundToDouble()).abs() < 0.005
    ? _inr0.format(v.roundToDouble())
    : _inr2.format(v);

String _trim(double x) {
  final r = x.toStringAsFixed(1);
  return r.endsWith('.0') ? r.substring(0, r.length - 2) : r;
}

String _compact(double v) {
  final a = v.abs();
  final s = v < 0 ? '-' : '';
  if (a >= 1e7) return '$s${_trim(a / 1e7)}Cr';
  if (a >= 1e5) return '$s${_trim(a / 1e5)}L';
  if (a >= 1e3) return '$s${_trim(a / 1e3)}K';
  return '$s${a.toStringAsFixed(0)}';
}

String _pct(double v) => '${v >= 0 ? '+' : ''}${_trim(v)}%';

double _niceMax(double v) {
  if (v <= 0) return 1000;
  final exp = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
  final f = v / exp;
  final nice = f <= 1 ? 1 : (f <= 2 ? 2 : (f <= 2.5 ? 2.5 : (f <= 5 ? 5 : 10)));
  return nice * exp;
}

IconData _iconFor(String name) {
  switch (name) {
    case 'schedule':
      return Icons.schedule_rounded;
    case 'warning':
      return Icons.warning_amber_rounded;
    case 'payment':
      return Icons.payments_rounded;
    case 'visibility_off':
      return Icons.visibility_off_rounded;
    case 'verified_user':
      return Icons.verified_user_rounded;
    case 'trending_up':
      return Icons.trending_up_rounded;
    case 'booking':
    case 'request':
      return Icons.book_online_rounded;
    case 'check':
      return Icons.check_circle_rounded;
    case 'close':
    case 'cancel':
      return Icons.cancel_rounded;
    case 'home':
      return Icons.home_rounded;
    case 'star':
      return Icons.star_rounded;
    case 'visibility':
      return Icons.visibility_rounded;
    case 'message':
      return Icons.chat_bubble_rounded;
    case 'property':
      return Icons.apartment_rounded;
    case 'subscription':
      return Icons.workspace_premium_rounded;
    case 'undo':
      return Icons.undo_rounded;
    default:
      return Icons.info_rounded;
  }
}

String _planName(String plan) {
  if (plan.isEmpty) return '';
  final m = RegExp(r'^MONTHLY_(\d+)$').firstMatch(plan);
  if (m != null) {
    final n = int.tryParse(m.group(1)!) ?? 1;
    return '$n-Month Plan';
  }
  final low = plan.toLowerCase();
  return '${low[0].toUpperCase()}${low.substring(1)} Plan';
}

// ============================================================
// SHARED STYLE HELPERS
// ============================================================
BoxDecoration _cardDeco(bool d, {double r = 20}) => BoxDecoration(
      color: _P.card(d),
      borderRadius: BorderRadius.circular(r),
      border: Border.all(color: _P.hair(d)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(d ? 0.28 : 0.04),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );

Widget _cardBox(
  bool d, {
  required Widget child,
  EdgeInsets padding = const EdgeInsets.all(18),
  EdgeInsets margin = const EdgeInsets.fromLTRB(_kPad, 0, _kPad, 14),
}) {
  return Container(
    margin: margin,
    padding: padding,
    decoration: _cardDeco(d),
    child: child,
  );
}

Widget _secHead(
  bool d,
  IconData icon,
  Color color,
  String title, {
  String? sub,
  Widget? trailing,
}) {
  return Row(
    children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(d ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.1,
                color: _P.ink(d),
                height: 1.25,
              ),
            ),
            if (sub != null)
              Text(
                sub,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: _P.sub(d),
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
      if (trailing != null) trailing,
    ],
  );
}

Widget _pill(String text, Color c, {IconData? icon}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: c.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 11, color: c),
          const SizedBox(width: 3),
        ],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: c,
              height: 1.3,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _growthPill(double growth, double prev, double cur) {
  if (prev <= 0 && cur <= 0) {
    return _pill('No data', _P.sub(false));
  }
  if (prev <= 0) return _pill('New', _P.primary, icon: Icons.auto_awesome);
  final up = growth >= 0;
  return _pill(
    _pct(growth),
    up ? _P.success : _P.danger,
    icon: up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
  );
}

Widget _segmented(
  bool d,
  List<String> labels,
  int selected,
  ValueChanged<int> onTap,
) {
  return Container(
    padding: const EdgeInsets.all(3),
    decoration: BoxDecoration(
      color: _P.soft(d),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(labels.length, (i) {
        final sel = i == selected;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!sel) {
              HapticFeedback.selectionClick();
              onTap(i);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: sel
                  ? (d ? const Color(0xFF2A3350) : Colors.white)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(d ? 0.25 : 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              labels[i],
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: sel ? (d ? Colors.white : _P.primary) : _P.sub(d),
              ),
            ),
          ),
        );
      }),
    ),
  );
}

// ============================================================
// SMALL REUSABLE WIDGETS
// ============================================================
class _Tap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  const _Tap({required this.child, this.onTap, this.scale = 0.97});

  @override
  State<_Tap> createState() => _TapState();
}

class _TapState extends State<_Tap> {
  bool _down = false;
  void _set(bool v) {
    if (widget.onTap == null) return;
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _CountUp extends StatelessWidget {
  final double value;
  final String Function(double) format;
  final TextStyle style;
  final Duration duration;
  const _CountUp({
    required this.value,
    required this.format,
    required this.style,
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text(format(v), style: style),
    );
  }
}

class _AnimBar extends StatelessWidget {
  final double value;
  final Color color;
  final Color track;
  final double height;
  const _AnimBar({
    required this.value,
    required this.color,
    required this.track,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Container(
        height: height,
        color: track,
        alignment: Alignment.centerLeft,
        child: TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: v),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (_, t, __) => FractionallySizedBox(
            widthFactor: t,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.75), color],
                ),
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegBar extends StatelessWidget {
  final List<int> values;
  final List<Color> colors;
  final bool isDark;
  const _SegBar({
    required this.values,
    required this.colors,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final total = values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return Container(
        height: 10,
        decoration: BoxDecoration(
          color: _P.soft(isDark),
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) => ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: t,
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                for (int i = 0; i < values.length; i++)
                  if (values[i] > 0)
                    Expanded(
                      flex: values[i],
                      child: Container(
                        margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          color: colors[i],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedDonut extends StatelessWidget {
  final double size;
  final List<double> values;
  final List<Color> colors;
  final double total;
  final Color track;
  final Widget center;
  const _AnimatedDonut({
    required this.size,
    required this.values,
    required this.colors,
    required this.total,
    required this.track,
    required this.center,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1000),
        curve: Curves.easeOutCubic,
        builder: (_, t, __) {
          double used = 0;
          final sections = <PieChartSectionData>[];
          for (int i = 0; i < values.length; i++) {
            final v = values[i] * t;
            used += v;
            if (v > 0) {
              sections.add(PieChartSectionData(
                value: v,
                color: colors[i],
                radius: 15,
                showTitle: false,
              ));
            }
          }
          final rest = math.max(0.0001, total - used);
          sections.add(PieChartSectionData(
            value: rest,
            color: track,
            radius: 12,
            showTitle: false,
          ));
          return Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: size / 2 - 17,
                  startDegreeOffset: -90,
                  sections: sections,
                ),
                swapAnimationDuration: Duration.zero,
              ),
              center,
            ],
          );
        },
      ),
    );
  }
}

class _Skel extends StatelessWidget {
  final double t;
  final bool isDark;
  final double? width;
  final double height;
  final double radius;
  const _Skel({
    required this.t,
    required this.isDark,
    required this.height,
    this.width,
    this.radius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final base = isDark ? const Color(0xFF1E2640) : const Color(0xFFE8ECF4);
    final hi = isDark ? const Color(0xFF2A3354) : const Color(0xFFF5F7FB);
    final dx = -2.0 + 4.0 * t;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(dx - 1, 0),
          end: Alignment(dx + 1, 0),
          colors: [base, hi, base],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

// ============================================================
// CHART DATA MODELS
// ============================================================
class _Pt {
  final double x;
  final String label;
  final String full;
  final double value;
  final int tx;
  final DateTime? date;
  const _Pt({
    required this.x,
    required this.label,
    required this.full,
    required this.value,
    this.tx = -1,
    this.date,
  });
}

class _RevenueData {
  final double thisMonth,
      lastMonth,
      growth,
      paid,
      pending,
      collection,
      payoutsDone,
      payoutsPending,
      thisYear;
  final int txns;
  final List<_Pt> monthly;
  final List<_Pt> daily;

  const _RevenueData({
    required this.thisMonth,
    required this.lastMonth,
    required this.growth,
    required this.paid,
    required this.pending,
    required this.collection,
    required this.payoutsDone,
    required this.payoutsPending,
    required this.thisYear,
    required this.txns,
    required this.monthly,
    required this.daily,
  });

  factory _RevenueData.from(dynamic r) {
    final monthly = <_Pt>[];
    final ml = _dl(() => r.monthlyTrend);
    for (int i = 0; i < ml.length; i++) {
      final e = ml[i];
      final m = _ds(() => e.month);
      final y = _di(() => e.year, 0);
      monthly.add(_Pt(
        x: i.toDouble(),
        label: m,
        full: y > 0 ? '$m $y' : m,
        value: _dn(() => e.amount),
        tx: _di(() => e.transactions, -1),
      ));
    }

    var daily = <_Pt>[];
    final dl = _dl(() => r.dailyTrend);
    final tmp = <_Pt>[];
    for (final e in dl) {
      final raw = _d(() => e.date);
      final dt = raw is DateTime ? raw : DateTime.tryParse('$raw');
      if (dt == null) continue;
      tmp.add(_Pt(
        x: 0,
        label: '',
        full: '',
        value: _dn(() => e.amount),
        date: DateTime.utc(dt.year, dt.month, dt.day),
      ));
    }
    tmp.sort((a, b) => a.date!.compareTo(b.date!));
    if (tmp.isNotEmpty) {
      final first = tmp.first.date!;
      daily = tmp
          .map((p) => _Pt(
                x: p.date!.difference(first).inDays.toDouble(),
                label: DateFormat('d MMM').format(p.date!),
                full: DateFormat('EEE, d MMM').format(p.date!),
                value: p.value,
                date: p.date,
              ))
          .toList();
    }

    return _RevenueData(
      thisMonth: _dn(() => r.thisMonthTotal),
      lastMonth: _dn(() => r.lastMonthTotal),
      growth: _dn(() => r.growthPercent),
      paid: _dn(() => r.paidAmount),
      pending: _dn(() => r.pendingAmount),
      collection: _dn(() => r.collectionRate),
      payoutsDone: _dn(() => r.payoutsCompleted),
      payoutsPending: _dn(() => r.payoutsPending),
      thisYear: _dn(() => r.thisYearTotal),
      txns: _di(() => r.totalTransactions),
      monthly: monthly,
      daily: daily,
    );
  }
}

class _DayPt {
  final String day;
  final String full;
  final double value;
  final double? accepted;
  final double? rejected;
  const _DayPt({
    required this.day,
    required this.full,
    required this.value,
    this.accepted,
    this.rejected,
  });

  static List<_DayPt> parse(List raw) {
    return raw.map((e) {
      final day = _ds(() => e.day);
      final rawDate = _d(() => e.date);
      final dt = rawDate is DateTime ? rawDate : DateTime.tryParse('$rawDate');
      final full = dt != null ? '$day, ${DateFormat('d MMM').format(dt)}' : day;
      return _DayPt(
        day: day,
        full: full,
        value: _dn(() => e.value),
        accepted: _dnn(() => e.accepted),
        rejected: _dnn(() => e.rejected),
      );
    }).toList();
  }
}

// ============================================================
// REVENUE CARD
// ============================================================
class _RevenueCard extends StatefulWidget {
  final _RevenueData data;
  final bool isDark;
  const _RevenueCard({required this.data, required this.isDark});

  @override
  State<_RevenueCard> createState() => _RevenueCardState();
}

class _RevenueCardState extends State<_RevenueCard> {
  int _range = 0;
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final dark = widget.isDark;
    final hasDaily = d.daily.length >= 2;
    final hasMonthly = d.monthly.isNotEmpty;
    final useDaily = _range == 0 && hasDaily || (!hasMonthly && hasDaily);
    final pts = useDaily ? d.daily : d.monthly;
    final t = (_touched != null && _touched! < pts.length) ? _touched : null;
    const color = _P.primary;

    final total = pts.fold<double>(0, (s, p) => s + p.value);
    final span = pts.isEmpty
        ? 0
        : (useDaily ? (pts.last.x - pts.first.x).round() + 1 : pts.length);
    final avg = span > 0 ? total / span : 0.0;

    final paidBase = d.paid + d.pending;
    final paidRatio = paidBase > 0 ? d.paid / paidBase : 0.0;

    return _cardBox(
      dark,
      padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _secHead(
              dark,
              Icons.show_chart_rounded,
              _P.primary,
              'Revenue',
              sub: 'Rent collected via Nestora',
              trailing: (hasDaily && hasMonthly)
                  ? _segmented(dark, const ['30D', '6M'], useDaily ? 0 : 1,
                      (i) => setState(() {
                            _range = i;
                            _touched = null;
                          }))
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: _CountUp(
                    value: t != null ? pts[t].value : d.thisMonth,
                    format: _inr,
                    duration: const Duration(milliseconds: 350),
                    style: GoogleFonts.poppins(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                      color: _P.ink(dark),
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: t != null
                      ? Row(
                          key: const ValueKey('touch'),
                          children: [
                            Text(
                              pts[t].full,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _P.sub(dark),
                              ),
                            ),
                            if (pts[t].tx >= 0) ...[
                              const SizedBox(width: 8),
                              _pill('${pts[t].tx} payments', _P.primary),
                            ],
                          ],
                        )
                      : Row(
                          key: const ValueKey('idle'),
                          children: [
                            _growthPill(d.growth, d.lastMonth, d.thisMonth),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'this month · last month ${_inr(d.lastMonth)}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  color: _P.sub(dark),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 190,
            child: pts.isEmpty
                ? Center(
                    child: Text(
                      'No revenue data yet',
                      style: GoogleFonts.poppins(
                          fontSize: 12.5, color: _P.sub(dark)),
                    ),
                  )
                : _chart(pts, useDaily, color, dark),
          ),
          if (pts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(
                useDaily
                    ? 'Last $span days · ${_inr(total)} · avg ${_inr(avg)}/day'
                    : 'Last $span months · ${_inr(total)} · avg ${_inr(avg)}/mo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 11, color: _P.sub(dark)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                        child:
                            _miniStat(dark, 'Paid', _inr(d.paid), _P.success)),
                    Expanded(
                        child: _miniStat(
                            dark, 'Pending', _inr(d.pending), _P.gold)),
                    Expanded(
                        child: _miniStat(dark, 'Collected',
                            '${_trim(d.collection)}%', _P.primary)),
                  ],
                ),
                const SizedBox(height: 10),
                _AnimBar(
                  value: paidRatio,
                  color: _P.success,
                  track: _P.gold.withOpacity(dark ? 0.35 : 0.28),
                  height: 8,
                ),
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: _P.soft(dark),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          child: _kv(dark, 'This year', _compactInr(d.thisYear))),
                      _vDivider(dark),
                      Expanded(child: _kv(dark, 'Transactions', '${d.txns}')),
                      _vDivider(dark),
                      Expanded(
                          child: _kv(
                              dark, 'Payouts done', _compactInr(d.payoutsDone))),
                      _vDivider(dark),
                      Expanded(
                          child: _kv(dark, 'In process',
                              _compactInr(d.payoutsPending))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _compactInr(double v) => '₹${_compact(v)}';

  Widget _vDivider(bool dark) => Container(
        width: 1,
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: _P.hair(dark),
      );

  Widget _kv(bool dark, String label, String value) {
    return Column(
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _P.ink(dark),
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(fontSize: 9.5, color: _P.sub(dark)),
        ),
      ],
    );
  }

  Widget _miniStat(bool dark, String label, String value, Color c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 11, color: _P.sub(dark)),
            ),
          ],
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: _P.ink(dark),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chart(List<_Pt> pts, bool daily, Color c, bool dark) {
    final maxV = pts.fold<double>(0, (m, p) => math.max(m, p.value));
    final maxY = _niceMax(maxV * 1.08);
    final minX = pts.first.x;
    var maxX = pts.last.x;
    if (maxX <= minX) maxX = minX + 1;
    final spots = pts.map((p) => FlSpot(p.x, p.value)).toList();
    final surface = _P.card(dark);
    final showAllDots = pts.length <= 8;
    final bottomInterval =
        daily ? math.max(1.0, ((maxX - minX) / 4).roundToDouble()) : 1.0;

    String labelAt(double v) {
      if (v < minX - 0.01 || v > maxX + 0.01) return '';
      if (daily) {
        final first = pts.first.date!;
        return DateFormat('d MMM').format(first.add(Duration(days: v.round())));
      }
      final i = v.round();
      return (i >= 0 && i < pts.length) ? pts[i].label : '';
    }

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (v) => FlLine(
            color: _P.hair(dark),
            strokeWidth: 1,
            dashArray: const [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 44,
              interval: maxY / 4,
              getTitlesWidget: (v, meta) {
                if (v <= 0) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    '₹${_compact(v)}',
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: _P.sub(dark),
                    ),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              interval: bottomInterval,
              getTitlesWidget: (v, meta) {
                final l = labelAt(v);
                if (l.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l,
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w500,
                      color: _P.sub(dark),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchSpotThreshold: 40,
          touchCallback: (event, resp) {
            final ls = resp?.lineBarSpots;
            if (!event.isInterestedForInteractions ||
                ls == null ||
                ls.isEmpty) {
              if (_touched != null) setState(() => _touched = null);
              return;
            }
            final idx = ls.first.spotIndex;
            if (idx != _touched) {
              HapticFeedback.selectionClick();
              setState(() => _touched = idx);
            }
          },
          getTouchedSpotIndicator: (barData, indexes) {
            return indexes
                .map((i) => TouchedSpotIndicatorData(
                      FlLine(
                        color: c.withOpacity(0.55),
                        strokeWidth: 1.2,
                        dashArray: const [4, 4],
                      ),
                      FlDotData(
                        show: true,
                        getDotPainter: (s, p, b, idx) => FlDotCirclePainter(
                          radius: 5.5,
                          color: c,
                          strokeWidth: 2.5,
                          strokeColor: surface,
                        ),
                      ),
                    ))
                .toList();
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) =>
                dark ? const Color(0xFF2A3350) : const Color(0xFF0B1220),
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) => spots.map((s) {
              final i = s.spotIndex;
              return LineTooltipItem(
                i < pts.length ? _inr(pts[i].value) : '',
                GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.2,
            preventCurveOverShooting: true,
            color: c,
            barWidth: 2.6,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, barData) =>
                  showAllDots || spot.x == barData.spots.last.x,
              getDotPainter: (spot, p, bar, i) => FlDotCirclePainter(
                radius: 4,
                color: c,
                strokeWidth: 2,
                strokeColor: surface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [c.withOpacity(0.28), c.withOpacity(0.0)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
  }
}

// ============================================================
// WEEKLY TRENDS CARD
// ============================================================
class _TrendCard extends StatefulWidget {
  final bool isDark;
  final List<_DayPt> bookings;
  final List<_DayPt> views;
  final int totalThisWeek;
  final int totalLastWeek;
  final double growth;
  final int viewsTotal;

  const _TrendCard({
    required this.isDark,
    required this.bookings,
    required this.views,
    required this.totalThisWeek,
    required this.totalLastWeek,
    required this.growth,
    required this.viewsTotal,
  });

  @override
  State<_TrendCard> createState() => _TrendCardState();
}

class _TrendCardState extends State<_TrendCard> {
  int _mode = 0;
  int? _touched;

  @override
  Widget build(BuildContext context) {
    final dark = widget.isDark;
    final hasViews = widget.views.isNotEmpty;
    final mode = (_mode == 1 && hasViews) ? 1 : 0;
    final data = mode == 0 ? widget.bookings : widget.views;
    final t = (_touched != null && _touched! < data.length) ? _touched : null;

    final hasBreakdown = mode == 0 &&
        data.isNotEmpty &&
        data.every((e) => e.accepted != null && e.rejected != null);

    double sumA = 0, sumR = 0, sumAll = 0;
    for (final e in data) {
      sumAll += e.value;
      sumA += e.accepted ?? 0;
      sumR += e.rejected ?? 0;
    }
    final sumP = math.max(0.0, sumAll - sumA - sumR);

    final heroValue = t != null
        ? data[t].value
        : (mode == 0
            ? widget.totalThisWeek.toDouble()
            : widget.viewsTotal.toDouble());
    final heroLabel = t != null
        ? data[t].full
        : (mode == 0 ? 'bookings this week' : 'views this week');

    return _cardBox(
      dark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secHead(
            dark,
            Icons.bar_chart_rounded,
            _P.primary,
            'Weekly Performance',
            sub: 'Last 7 days',
            trailing: hasViews
                ? _segmented(dark, const ['Bookings', 'Views'], mode,
                    (i) => setState(() {
                          _mode = i;
                          _touched = null;
                        }))
                : null,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _CountUp(
                value: heroValue,
                format: (v) => mode == 1 && t == null
                    ? _compact(v.roundToDouble())
                    : v.round().toString(),
                duration: const Duration(milliseconds: 300),
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: _P.ink(dark),
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    heroLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                        fontSize: 11.5, color: _P.sub(dark)),
                  ),
                ),
              ),
              if (mode == 0 && t == null)
                _growthPill(
                  widget.growth,
                  widget.totalLastWeek >= 0
                      ? widget.totalLastWeek.toDouble()
                      : (widget.growth == 0 ? 0 : 1),
                  widget.totalThisWeek.toDouble(),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 170,
            child: data.isEmpty
                ? Center(
                    child: Text(
                      'No activity this week',
                      style: GoogleFonts.poppins(
                          fontSize: 12.5, color: _P.sub(dark)),
                    ),
                  )
                : _bars(data, mode, hasBreakdown, dark),
          ),
          const SizedBox(height: 14),
          if (mode == 0 && hasBreakdown)
            Row(
              children: [
                _legend(dark, 'Accepted', sumA.round(), _P.success),
                const SizedBox(width: 14),
                _legend(dark, 'Rejected', sumR.round(), _P.danger),
                const SizedBox(width: 14),
                _legend(dark, 'Pending', sumP.round(), _P.gold),
              ],
            )
          else
            Row(
              children: [
                _legend(
                  dark,
                  'Daily avg',
                  data.isEmpty ? 0 : (sumAll / data.length).round(),
                  _P.primary,
                ),
                const SizedBox(width: 14),
                _legend(
                  dark,
                  'Best day',
                  data.isEmpty
                      ? 0
                      : data.map((e) => e.value).reduce(math.max).round(),
                  _P.sky,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _legend(bool dark, String label, int value, Color c) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$label ',
          style: GoogleFonts.poppins(fontSize: 11, color: _P.sub(dark)),
        ),
        Text(
          _compact(value.toDouble()),
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _P.ink(dark),
          ),
        ),
      ],
    );
  }

  Widget _bars(List<_DayPt> data, int mode, bool breakdown, bool dark) {
    final maxVal = data.fold<double>(0, (m, e) {
      final total = math.max(e.value, (e.accepted ?? 0) + (e.rejected ?? 0));
      return math.max(m, total);
    });
    final niceTop = mode == 1
        ? _niceMax(maxVal * 1.1)
        : math.max(4.0, (maxVal * 1.25).ceilToDouble());
    final interval =
        mode == 1 ? niceTop / 4 : math.max(1.0, (niceTop / 4).ceilToDouble());
    final maxY = mode == 1 ? niceTop : interval * 4;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (v) => FlLine(
            color: _P.hair(dark),
            strokeWidth: 1,
            dashArray: const [4, 4],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: interval,
              getTitlesWidget: (v, meta) {
                if (v == 0 && maxY > 0) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text('0',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.poppins(
                            fontSize: 9.5, color: _P.sub(dark))),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(
                    _compact(v),
                    textAlign: TextAlign.right,
                    style:
                        GoogleFonts.poppins(fontSize: 9.5, color: _P.sub(dark)),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (v, meta) {
                final i = v.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                final sel = _touched == i;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    data[i].day,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                      color: sel ? _P.ink(dark) : _P.sub(dark),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (event, resp) {
            final idx = resp?.spot?.touchedBarGroupIndex;
            if (!event.isInterestedForInteractions || idx == null) {
              if (_touched != null) setState(() => _touched = null);
              return;
            }
            if (idx != _touched) {
              HapticFeedback.selectionClick();
              setState(() => _touched = idx);
            }
          },
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) =>
                dark ? const Color(0xFF2A3350) : const Color(0xFF0B1220),
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, gi, rod, ri) {
              final e = data[group.x];
              final extra = (mode == 0 && breakdown)
                  ? '\n${(e.accepted ?? 0).round()} accepted · ${(e.rejected ?? 0).round()} rejected'
                  : '';
              return BarTooltipItem(
                '${e.full}\n${e.value.round()} ${mode == 0 ? 'bookings' : 'views'}$extra',
                GoogleFonts.poppins(
                  fontSize: 10.5,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              );
            },
          ),
        ),
        barGroups: List.generate(data.length, (i) {
          final e = data[i];
          final dim = _touched != null && _touched != i;
          final a = e.accepted ?? 0;
          final r = e.rejected ?? 0;
          final total = math.max(e.value, a + r);
          const radius = BorderRadius.vertical(top: Radius.circular(7));
          final back = BackgroundBarChartRodData(
            show: true,
            toY: maxY,
            color: _P.soft(dark),
          );
          if (mode == 0 && breakdown) {
            final op = dim ? 0.4 : 1.0;
            final items = <BarChartRodStackItem>[];
            double cur = 0;
            void push(double amount, Color c) {
              if (amount <= 0) return;
              items.add(
                  BarChartRodStackItem(cur, cur + amount, c.withOpacity(op)));
              cur += amount;
            }

            push(a, _P.success);
            push(r, _P.danger);
            push(math.max(0, total - a - r), _P.gold);
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: total,
                  width: 20,
                  borderRadius: radius,
                  rodStackItems: items,
                  backDrawRodData: back,
                ),
              ],
            );
          }
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: e.value,
                width: 20,
                borderRadius: radius,
                gradient: LinearGradient(
                  colors: [
                    _P.primaryDeep.withOpacity(dim ? 0.35 : 1),
                    _P.primaryLight.withOpacity(dim ? 0.35 : 1),
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                backDrawRodData: back,
              ),
            ],
          );
        }),
      ),
      swapAnimationDuration: const Duration(milliseconds: 350),
      swapAnimationCurve: Curves.easeOutCubic,
    );
  }
}

// ============================================================
// PAGE
// ============================================================
class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage>
    with TickerProviderStateMixin, RouteAware {   // ✅ RouteAware added
  bool _isFirstLoad = true;
  int _unreadNotifications = 0;

  late AnimationController _staggerController;
  late AnimationController _shimmerController;

  int _selectedPropertyId = 0;
  String _selectedPropertyTitle = 'Property Access';

  StreamSubscription? _connectivitySub;
  Timer? _retryTimer;
  Timer? _backOnlineTimer;

  bool _isDisposed = false;
  bool _isLoadingAll = false;
  bool _introPlayed = false;
  bool _wasOffline = false;
  bool _isReconnecting = false;
  bool _showBackOnline = false;
  bool _showAllActions = false;

  // ============================================================
  // LIFECYCLE
  // ============================================================
  @override
  void initState() {
    super.initState();

    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1300),
      vsync: this,
    );
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat();

    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((dynamic result) {
      if (!mounted || _isDisposed) return;
      final p = Provider.of<OwnerProvider>(context, listen: false);
      if (_hasNet(result)) {
        if (_wasOffline || !p.hasInternet) _flashBackOnline();
        _wasOffline = false;
        _loadAll();
      } else {
        _wasOffline = true;
        p.checkConnectivity();
      }
    });

    _retryTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!mounted || _isDisposed) return;
      final p = Provider.of<OwnerProvider>(context, listen: false);
      if (!p.hasInternet) _reconnectAndLoad();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_isFirstLoad) {
        _isFirstLoad = false;
        _loadAll();
      }
    });
  }

  // ✅ Subscribe to route observer
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  // ✅ Called when returning from pushed screens (e.g., ProfileScreen)
  @override
  void didPopNext() {
    super.didPopNext();
    _refreshProfileAndData();
  }

  Future<void> _refreshProfileAndData() async {
    if (!mounted) return;
    try {
      // Refresh profile (profile pic)
      await Provider.of<ProfileProvider>(context, listen: false)
          .getProfile();
      if (!mounted) return;
      // Refresh owner data (stats, subscriptions, etc.)
      await _loadAll();
    } catch (_) {}
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);   // ✅ Unsubscribe
    _isDisposed = true;
    _connectivitySub?.cancel();
    _retryTimer?.cancel();
    _backOnlineTimer?.cancel();
    _staggerController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  bool _hasNet(dynamic r) {
    if (r is List) return r.any((e) => e != ConnectivityResult.none);
    return r != ConnectivityResult.none;
  }

  void _flashBackOnline() {
    if (!mounted) return;
    _backOnlineTimer?.cancel();
    setState(() => _showBackOnline = true);
    _backOnlineTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted) setState(() => _showBackOnline = false);
    });
  }

  Future<void> _reconnectAndLoad() async {
    if (!mounted) return;
    final p = Provider.of<OwnerProvider>(context, listen: false);
    if (!p.hasInternet) {
      if (_isReconnecting) return;
      setState(() => _isReconnecting = true);
      final ok = await p.checkConnectivity();
      if (!mounted) return;
      setState(() => _isReconnecting = false);
      if (!ok) return;
      _wasOffline = false;
      _flashBackOnline();
    }
    await _loadAll();
  }

  // ============================================================
  // DATA
  // ============================================================
  Future<void> _loadAll() async {
    if (_isLoadingAll || !mounted) return;
    _isLoadingAll = true;
    try {
      final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
      await ownerProvider.loadAllOwnerData();
      if (!mounted) return;
      _loadPropertyData(ownerProvider);
      _loadUnreadNotifications();
    } finally {
      _isLoadingAll = false;
      if (mounted) setState(() {});
    }
  }

  void _loadPropertyData(OwnerProvider provider) {
    if (provider.myProperties.isNotEmpty) {
      final firstProperty = provider.myProperties.first;
      if (mounted) {
        setState(() {
          _selectedPropertyId = firstProperty.propertyId ?? 0;
          _selectedPropertyTitle = firstProperty.title ?? 'Property';
        });
      }
    }
  }

  Future<void> _loadUnreadNotifications() async {
    if (!mounted) return;
    final p = Provider.of<OwnerProvider>(context, listen: false);
    setState(() => _unreadNotifications = p.unreadBookingCount);
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    await _reconnectAndLoad();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  // ============================================================
  // NAVIGATION
  // ============================================================
  void _navigateTo(Widget screen) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 280),
      ),
    );
  }

  void _navigateToPropertyAccess() {
    _navigateTo(
      PropertyAccessSubscriptionPage(
        propertyId: _selectedPropertyId,
        propertyTitle: _selectedPropertyTitle,
      ),
    );
  }

  void _navigateToListingSubscription() {
    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
    String title = 'Listing Subscription';
    int id = 0;
    if (ownerProvider.myProperties.isNotEmpty) {
      final p = ownerProvider.myProperties.first;
      id = p.propertyId ?? 0;
      title = p.title ?? 'Listing';
    }
    _navigateTo(ListingSubscriptionPage(
      propertyId: id,
      propertyTitle: title,
    ));
  }

  void _handleAction(String type) {
    switch (type) {
      case 'PENDING_BOOKING':
        _navigateTo(const OwnerBookingManagementPage());
        break;
      case 'EXPIRING_SUBSCRIPTION':
        _navigateToPropertyAccess();
        break;
      case 'UPI_MISSING':
        _showPayoutUpiDialog();
        break;
      case 'UNPUBLISHED_PROPERTY':
      case 'HIGH_VIEWS_LOW_BOOKINGS':
        _navigateTo(const OwnerPropertyManagementPage());
        break;
      default:
        break;
    }
  }

  // ============================================================
  // BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthProvider>(context);
    final profileProvider = Provider.of<ProfileProvider>(context);
    final ownerProvider = Provider.of<OwnerProvider>(context);

    final user = authProvider.user;
    final profileImage = profileProvider.profile?.profilePic;
    final stats = ownerProvider.dashboardStats;
    final verification = ownerProvider.verificationStatus;
    final accessStatus = ownerProvider.propertyAccessStatus;
    final listingSub = ownerProvider.listingSubscription;
    final ownerProfile = ownerProvider.ownerProfile;
    final dynamic sm = ownerProvider.dashboardSummary;

    final hasData = stats != null || sm != null;
    final offline = !ownerProvider.hasInternet;
    if (offline) _wasOffline = true;
    final loading = ownerProvider.isLoading || _isLoadingAll;
    final showSkeleton = !hasData && (loading || offline);

    final sumNotif = _di(() => sm.unreadNotifications, -1);
    final notifCount = sumNotif >= 0 ? sumNotif : _unreadNotifications;
    final unreadMessages = _di(() => sm.unreadMessages, 0);

    if (!showSkeleton && !_introPlayed) {
      _introPlayed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _staggerController.forward(from: 0);
      });
    }

    final counts = _bookingCounts(ownerProvider, stats);

    final sections = <Widget>[];
    int order = 0;
    void add(String key, Widget w) => sections.add(_animated(order++, key, w));

    if (!showSkeleton) {
      final actions = _d(() => sm.actionsRequired);
      final actionCount = _di(() => actions.totalActions);
      if (actions != null && actionCount > 0) {
        add('actions', _actionRequiredSection(isDark, actions, actionCount));
      }

      final rev = _d(() => sm.revenue);
      if (rev != null) {
        add('revenue',
            _RevenueCard(data: _RevenueData.from(rev), isDark: isDark));
      }

      final occ = _d(() => sm.occupancy);
      if (occ != null) add('occupancy', _occupancySection(isDark, occ));

      final trends = _d(() => sm.trends);
      if (trends != null) {
        add(
          'trends',
          _TrendCard(
            isDark: isDark,
            bookings: _DayPt.parse(_dl(() => trends.bookingsTrend)),
            views: _DayPt.parse(_dl(() => trends.viewsTrend)),
            totalThisWeek: _di(() => trends.totalThisWeek),
            totalLastWeek: _di(() => trends.totalLastWeek, -1),
            growth: _dn(() => trends.growthPercent),
            viewsTotal: _di(() => trends.totalViewsThisWeek),
          ),
        );
      }

      final schedule = _d(() => sm.todaySchedule);
      if (schedule != null && _di(() => schedule.totalEvents) > 0) {
        add('schedule', _todayScheduleSection(isDark, schedule));
      }

      final top = _d(() => sm.topProperty);
      if (top != null) add('top', _topPropertySection(isDark, top));

      final activity = _d(() => sm.recentActivity);
      if (activity != null && _dl(() => activity.activities).isNotEmpty) {
        add('activity', _activitySection(isDark, activity));
      }

      add('payout', _payoutCard(isDark, ownerProvider));

      if (stats != null) add('stats', _statsGrid(isDark, stats));

      if (verification != null) {
        add('verify', _verificationCard(isDark, verification));
      }

      add('subs', _subscriptionSection(isDark, accessStatus, listingSub));

      add('reels', _reelsSection(isDark));

      add(
        'quick',
        _quickActions(
          isDark,
          pending: counts['PENDING'] ?? 0,
          notifications: notifCount,
          messages: unreadMessages,
          properties: _di(() => stats?.totalProperties, -1),
        ),
      );

      add('bookings', _bookingOverview(isDark, counts));

      if (!hasData && !loading && !offline) {
        sections.insert(0, _loadErrorCard(isDark));
      }
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: _P.bg(isDark),
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: _P.bg(isDark),
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: _P.primary,
            backgroundColor: isDark ? _P.darkSurface : Colors.white,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _header(
                    isDark,
                    user,
                    profileImage,
                    ownerProfile,
                    _db(() => verification?.isVerified),
                    notifCount,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _connectionBanner(
                    isDark,
                    offline: offline,
                    hasData: hasData,
                    loading: loading,
                  ),
                ),
                if (showSkeleton)
                  SliverToBoxAdapter(child: _skeleton(isDark))
                else
                  SliverList(delegate: SliverChildListDelegate(sections)),
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).padding.bottom + 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _animated(int index, String key, Widget child) {
    final start = math.min(index * 0.05, 0.55);
    return AnimatedBuilder(
      key: ValueKey(key),
      animation: _staggerController,
      child: child,
      builder: (_, c) {
        final t = Curves.easeOutCubic.transform(
            ((_staggerController.value - start) / 0.45).clamp(0.0, 1.0));
        if (t >= 1) return c!;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 26 * (1 - t)),
            child: c,
          ),
        );
      },
    );
  }

  Map<String, int> _bookingCounts(OwnerProvider p, dynamic stats) {
    final counts = <String, int>{
      'PENDING': 0,
      'ACCEPTED': 0,
      'REJECTED': 0,
      'CANCELLED': 0,
      'COMPLETED': 0,
    };
    final list = p.bookingRequests;
    if (list.isNotEmpty) {
      for (final b in list) {
        final s = _ds(() => b.status, 'PENDING').toUpperCase();
        counts[s] = (counts[s] ?? 0) + 1;
      }
      counts['TOTAL'] = list.length;
    } else if (stats != null) {
      final pending = _di(() => stats.pendingRequests);
      final accepted = _di(() => stats.acceptedRequests);
      final rejected = _di(() => stats.rejectedRequests);
      final total = _di(() => stats.totalBookingRequests);
      counts['PENDING'] = pending;
      counts['ACCEPTED'] = accepted;
      counts['REJECTED'] = rejected;
      counts['CANCELLED'] = math.max(0, total - pending - accepted - rejected);
      counts['TOTAL'] = math.max(total, pending + accepted + rejected);
    } else {
      counts['TOTAL'] = 0;
    }
    return counts;
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _header(
    bool isDark,
    dynamic user,
    String? profileImage,
    dynamic ownerProfile,
    bool verified,
    int notifCount,
  ) {
    final hasImage = profileImage != null && profileImage.isNotEmpty;
    final name = _ds(() => user.name, 'Owner');
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'O';
    final business = _ds(() => ownerProfile.businessName);

    return Padding(
      padding: const EdgeInsets.fromLTRB(_kPad, 14, _kPad, 14),
      child: Row(
        children: [
          _Tap(
            onTap: () => _navigateTo(const OwnerProfileScreen()),
            child: Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [_P.primary, _P.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _P.primary.withOpacity(0.28),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _P.bg(isDark),
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: hasImage
                      ? CachedNetworkImage(
                          imageUrl: profileImage,
                          fit: BoxFit.cover,
                          fadeInDuration: const Duration(milliseconds: 250),
                          cacheKey: profileImage,  // ✅ cache key
                          placeholder: (_, __) => _avatarFallback(initial),
                          errorWidget: (_, __, ___) => _avatarFallback(initial),
                        )
                      : _avatarFallback(initial),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _greeting(),
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: _P.sub(isDark),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 1),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          color: _P.ink(isDark),
                          height: 1.25,
                        ),
                      ),
                    ),
                    if (verified) ...[
                      const SizedBox(width: 5),
                      const Icon(Icons.verified_rounded,
                          color: _P.primary, size: 17),
                    ],
                  ],
                ),
                if (business.isNotEmpty)
                  Text(
                    business,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: _P.sub(isDark),
                      height: 1.2,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _circleBtn(
            isDark: isDark,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (c, a) => RotationTransition(
                turns: Tween<double>(begin: 0.75, end: 1).animate(a),
                child: FadeTransition(opacity: a, child: c),
              ),
              child: Icon(
                isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                key: ValueKey(isDark),
                size: 19,
                color: isDark ? _P.gold : const Color(0xFF475569),
              ),
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              final tp = Provider.of<ThemeProvider>(context, listen: false);
              tp.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
            },
          ),
          const SizedBox(width: 8),
          _circleBtn(
            isDark: isDark,
            badge: notifCount,
            child: Icon(
              Icons.notifications_none_rounded,
              size: 21,
              color: _P.ink(isDark),
            ),
            onTap: () => _navigateTo(const NotificationScreen()),
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback(String initial) => Container(
        color: _P.primary,
        alignment: Alignment.center,
        child: Text(
          initial,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 19,
          ),
        ),
      );

  Widget _circleBtn({
    required bool isDark,
    required Widget child,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    return _Tap(
      onTap: onTap,
      scale: 0.9,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _P.card(isDark),
              shape: BoxShape.circle,
              border: Border.all(color: _P.hair(isDark)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(child: child),
          ),
          Positioned(
            right: -2,
            top: -2,
            child: AnimatedScale(
              scale: badge > 0 ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutBack,
              child: Container(
                constraints: const BoxConstraints(minWidth: 19, minHeight: 19),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _P.danger,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _P.bg(isDark), width: 2),
                ),
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CONNECTION BANNER
  // ============================================================
  Widget _connectionBanner(
    bool isDark, {
    required bool offline,
    required bool hasData,
    required bool loading,
  }) {
    Widget child;
    if (offline) {
      child = _bannerCard(
        key: 'offline',
        isDark: isDark,
        color: _P.gold,
        icon: Icons.wifi_off_rounded,
        title: "You're offline",
        subtitle: hasData
            ? 'Showing last synced data · reconnecting automatically'
            : 'Waiting for connection to load your dashboard',
        progress: true,
        trailing: _isReconnecting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: _P.gold,
                ),
              )
            : _Tap(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _reconnectAndLoad();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _P.gold,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
      );
    } else if (_showBackOnline) {
      child = _bannerCard(
        key: 'online',
        isDark: isDark,
        color: _P.success,
        icon: Icons.wifi_rounded,
        title: 'Back online',
        subtitle: loading ? 'Syncing latest data…' : 'Dashboard is up to date',
        progress: loading,
      );
    } else if (loading && hasData) {
      child = Padding(
        key: const ValueKey('slim'),
        padding: const EdgeInsets.fromLTRB(_kPad, 0, _kPad, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            minHeight: 3,
            color: _P.primary,
            backgroundColor: _P.primary.withOpacity(0.12),
          ),
        ),
      );
    } else {
      child = const SizedBox(key: ValueKey('none'), width: double.infinity);
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeOutCubic,
        transitionBuilder: (c, a) => FadeTransition(
          opacity: a,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.2),
              end: Offset.zero,
            ).animate(a),
            child: c,
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _bannerCard({
    required String key,
    required bool isDark,
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool progress,
    Widget? trailing,
  }) {
    return Container(
      key: ValueKey(key),
      margin: const EdgeInsets.fromLTRB(_kPad, 0, _kPad, 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.14 : 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _P.ink(isDark),
                        height: 1.25,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: _P.sub(isDark),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 10),
                trailing,
              ],
            ],
          ),
          if (progress) ...[
            const SizedBox(height: 11),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                minHeight: 4,
                color: color,
                backgroundColor: color.withOpacity(0.15),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // SKELETON
  // ============================================================
  Widget _skeleton(bool isDark) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (_, __) {
        final t = _shimmerController.value;
        Widget sk(double h, {double? w, double r = 12}) =>
            _Skel(t: t, isDark: isDark, height: h, width: w, radius: r);

        return Column(
          children: [
            _cardBox(
              isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    sk(34, w: 34, r: 11),
                    const SizedBox(width: 10),
                    sk(14, w: 120, r: 7),
                    const Spacer(),
                    sk(28, w: 90, r: 10),
                  ]),
                  const SizedBox(height: 18),
                  sk(34, w: 190, r: 10),
                  const SizedBox(height: 10),
                  sk(14, w: 150, r: 7),
                  const SizedBox(height: 18),
                  sk(150, r: 16),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(child: sk(38, r: 10)),
                    const SizedBox(width: 12),
                    Expanded(child: sk(38, r: 10)),
                    const SizedBox(width: 12),
                    Expanded(child: sk(38, r: 10)),
                  ]),
                ],
              ),
            ),
            _cardBox(
              isDark,
              child: Row(
                children: [
                  sk(120, w: 120, r: 60),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      children: [
                        sk(16, r: 8),
                        const SizedBox(height: 14),
                        sk(16, r: 8),
                        const SizedBox(height: 14),
                        sk(16, r: 8),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _cardBox(
              isDark,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    sk(34, w: 34, r: 11),
                    const SizedBox(width: 10),
                    sk(14, w: 140, r: 7),
                  ]),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      7,
                      (i) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: sk(40.0 + (i * 37 % 70), r: 8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _cardBox(
              isDark,
              child: Row(
                children: List.generate(
                  4,
                  (i) => Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i == 3 ? 0 : 10),
                      child: sk(70, r: 14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _loadErrorCard(bool isDark) {
    return _cardBox(
      isDark,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _P.danger.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.cloud_off_rounded, color: _P.danger, size: 26),
          ),
          const SizedBox(height: 14),
          Text(
            "Couldn't load your dashboard",
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _P.ink(isDark),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pull down to refresh or try again.',
            style: GoogleFonts.poppins(fontSize: 12, color: _P.sub(isDark)),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: _reconnectAndLoad,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text('Try again',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _P.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return _P.danger;
      case 'MEDIUM':
        return _P.gold;
      default:
        return _P.primary;
    }
  }

  Widget _actionRequiredSection(bool isDark, dynamic actions, int total) {
    final items = _dl(() => actions.items);
    final shown = _showAllActions ? items : items.take(3).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(_kPad, 0, _kPad, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _P.danger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.bolt_rounded, color: _P.danger, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Action Required',
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                  color: _P.ink(isDark),
                ),
              ),
              const SizedBox(width: 8),
              _pill('$total', _P.danger),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: Column(
              children: shown.map((a) => _actionCard(isDark, a)).toList(),
            ),
          ),
          if (items.length > 3)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showAllActions = !_showAllActions);
                },
                icon: AnimatedRotation(
                  turns: _showAllActions ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20, color: _P.primary),
                ),
                label: Text(
                  _showAllActions
                      ? 'Show less'
                      : 'Show ${items.length - 3} more',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _P.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionCard(bool isDark, dynamic item) {
    final type = _ds(() => item.type);
    final priority = _ds(() => item.priority);
    final c = _priorityColor(priority);
    final title = _ds(() => item.title);
    final desc = _ds(() => item.description);
    final label = _ds(() => item.actionLabel, 'Open');
    final icon = _iconFor(_ds(() => item.icon));

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _Tap(
        onTap: () {
          HapticFeedback.selectionClick();
          _handleAction(type);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _P.card(isDark),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.withOpacity(0.30)),
            boxShadow: [
              BoxShadow(
                color: c.withOpacity(isDark ? 0.10 : 0.07),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: c.withOpacity(0.13),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: c, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (priority.toUpperCase() == 'HIGH')
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: _P.danger,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'URGENT',
                              style: GoogleFonts.poppins(
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _P.ink(isDark),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: _P.sub(isDark),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: c,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // OCCUPANCY
  // ============================================================
  Widget _occupancySection(bool isDark, dynamic occ) {
    final total = _di(() => occ.totalRooms);
    final occupied = _di(() => occ.occupiedRooms);
    final available = _di(() => occ.availableRooms);
    final maintenance = _di(() => occ.maintenanceRooms);
    final rate = _dn(() => occ.occupancyRate);
    final label = _ds(() => occ.occupancyLabel);
    final change = _dnn(() => occ.changeFromLastWeek);
    final byProperty = _dl(() => occ.byProperty);

    final rateColor = rate >= 85
        ? _P.success
        : rate >= 70
            ? _P.primary
            : rate >= 50
                ? _P.gold
                : _P.danger;

    final sum = occupied + available + maintenance;
    final donutTotal = math.max(total, sum).toDouble();

    const propColors = [_P.primary, _P.sky, _P.indigo, _P.teal];

    Widget legend(String name, int v, Color c) {
      final pctv = donutTotal > 0 ? v / donutTotal * 100 : 0.0;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                name,
                style:
                    GoogleFonts.poppins(fontSize: 12, color: _P.sub(isDark)),
              ),
            ),
            Text(
              '$v',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _P.ink(isDark),
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                '${_trim(pctv)}%',
                textAlign: TextAlign.right,
                style:
                    GoogleFonts.poppins(fontSize: 10.5, color: _P.sub(isDark)),
              ),
            ),
          ],
        ),
      );
    }

    return _cardBox(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secHead(
            isDark,
            Icons.home_work_rounded,
            _P.primary,
            'Occupancy',
            sub: '$total rooms across your properties',
            trailing: label.isEmpty ? null : _pill(label, rateColor),
          ),
          const SizedBox(height: 18),
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'Add rooms to see occupancy insights',
                  style:
                      GoogleFonts.poppins(fontSize: 12.5, color: _P.sub(isDark)),
                ),
              ),
            )
          else
            Row(
              children: [
                _AnimatedDonut(
                  size: 132,
                  values: [
                    occupied.toDouble(),
                    available.toDouble(),
                    maintenance.toDouble(),
                  ],
                  colors: const [_P.primary, _P.sky, _P.gold],
                  total: donutTotal,
                  track: _P.soft(isDark),
                  center: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _CountUp(
                        value: rate,
                        format: (v) => '${_trim(v)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: _P.ink(isDark),
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'occupied',
                        style: GoogleFonts.poppins(
                            fontSize: 10, color: _P.sub(isDark)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    children: [
                      legend('Occupied', occupied, _P.primary),
                      legend('Available', available, _P.sky),
                      if (maintenance > 0)
                        legend('Maintenance', maintenance, _P.gold),
                      legend('Total', total, _P.sub(isDark)),
                    ],
                  ),
                ),
              ],
            ),
          if (change != null && total > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: _P.soft(isDark),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    change >= 0
                        ? Icons.trending_up_rounded
                        : Icons.trending_down_rounded,
                    size: 16,
                    color: change >= 0 ? _P.success : _P.danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${change >= 0 ? '+' : ''}${_trim(change)}% vs last week',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _P.ink(isDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (byProperty.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              'BY PROPERTY',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: _P.sub(isDark),
              ),
            ),
            const SizedBox(height: 10),
            ...List.generate(math.min(4, byProperty.length), (i) {
              final p = byProperty[i];
              final title = _ds(() => p.propertyTitle, 'Property');
              final tr = _di(() => p.totalRooms);
              final orr = _di(() => p.occupiedRooms);
              final pr = _dn(() => p.occupancyRate);
              final pc = propColors[i % propColors.length];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _P.ink(isDark),
                            ),
                          ),
                        ),
                        Text(
                          '$orr/$tr · ${_trim(pr)}%',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _P.sub(isDark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _AnimBar(
                      value: pr / 100,
                      color: pc,
                      track: _P.soft(isDark),
                      height: 7,
                    ),
                  ],
                ),
              );
            }),
            if (byProperty.length > 4)
              Text(
                '+${byProperty.length - 4} more properties',
                style:
                    GoogleFonts.poppins(fontSize: 11, color: _P.sub(isDark)),
              ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // TODAY'S SCHEDULE
  // ============================================================
  Widget _todayScheduleSection(bool isDark, dynamic schedule) {
    final events = _dl(() => schedule.events);
    final total = _di(() => schedule.totalEvents);
    final shown = events.take(4).toList();

    return _cardBox(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secHead(
            isDark,
            Icons.event_rounded,
            _P.primary,
            "Today's Schedule",
            sub: DateFormat('EEEE, d MMM').format(DateTime.now()),
            trailing: _pill('$total', _P.primary),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < shown.length; i++)
            _scheduleTile(isDark, shown[i], i == shown.length - 1),
          if (events.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '+${events.length - 4} more today',
                style:
                    GoogleFonts.poppins(fontSize: 11, color: _P.sub(isDark)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _scheduleTile(bool isDark, dynamic item, bool last) {
    const c = _P.primary;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 62,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                _ds(() => item.timeLabel),
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _P.sub(isDark),
                ),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.withOpacity(0.25), width: 3),
                ),
              ),
              if (!last)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: _P.hair(isDark),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: last ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: c.withOpacity(isDark ? 0.10 : 0.06),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    Icon(_iconFor(_ds(() => item.icon)), color: c, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _ds(() => item.title),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _P.ink(isDark),
                            ),
                          ),
                          Text(
                            _ds(() => item.description),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              color: _P.sub(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOP PROPERTY
  // ============================================================
  Widget _topPropertySection(bool isDark, dynamic prop) {
    final title = _ds(() => prop.title, 'Property');
    final city = _ds(() => prop.city);
    final cover = _ds(() => prop.coverImage);
    final revenue = _dn(() => prop.revenueThisMonth);
    final bookings = _di(() => prop.bookingsThisMonth);
    final rating = _dn(() => prop.averageRating);
    final reviews = _di(() => prop.totalReviews);
    final views = _di(() => prop.viewCount);
    final occ = _dn(() => prop.occupancyRate);
    final avail = _di(() => prop.availableRooms);
    final rooms = _di(() => prop.totalRooms);
    final reason = _ds(() => prop.topReason);
    final badge = _ds(() => prop.rankBadge, 'Top Performer');

    Widget metric(IconData icon, Color c, String value, String label) {
      return Expanded(
        child: Column(
          children: [
            Icon(icon, size: 17, color: c),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _P.ink(isDark),
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 10, color: _P.sub(isDark)),
            ),
          ],
        ),
      );
    }

    final placeholder = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_P.primaryDeep, _P.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.apartment_rounded, color: Colors.white54, size: 54),
      ),
    );

    return _Tap(
      scale: 0.985,
      onTap: () => _navigateTo(const OwnerPropertyManagementPage()),
      child: Container(
        margin: const EdgeInsets.fromLTRB(_kPad, 0, _kPad, 14),
        decoration: _cardDeco(isDark),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 176,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    cover.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: cover,
                            fit: BoxFit.cover,
                            fadeInDuration: const Duration(milliseconds: 300),
                            placeholder: (_, __) => placeholder,
                            errorWidget: (_, __, ___) => placeholder,
                          )
                        : placeholder,
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.15),
                            Colors.transparent,
                            Colors.black.withOpacity(0.72),
                          ],
                          stops: const [0, 0.4, 1],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _P.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events_rounded,
                                color: Colors.white, size: 13),
                            const SizedBox(width: 5),
                            Text(
                              badge,
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 14,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.25,
                            ),
                          ),
                          if (city.isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    size: 13, color: Colors.white70),
                                const SizedBox(width: 3),
                                Text(
                                  city,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Earned this month',
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: _P.sub(isDark)),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: _CountUp(
                                  value: revenue,
                                  format: _inr,
                                  style: GoogleFonts.poppins(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                    color: _P.primary,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (reason.isNotEmpty)
                          Flexible(
                            child: _pill(reason, _P.primary,
                                icon: Icons.workspace_premium_rounded),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: _P.soft(isDark),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          metric(Icons.book_online_rounded, _P.primary,
                              '$bookings', 'Bookings'),
                          metric(
                            Icons.star_rounded,
                            _P.gold,
                            rating > 0
                                ? '${rating.toStringAsFixed(1)}${reviews > 0 ? ' ($reviews)' : ''}'
                                : '—',
                            'Rating',
                          ),
                          metric(Icons.visibility_rounded, _P.sky,
                              _compact(views.toDouble()), 'Views'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Occupancy',
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _P.ink(isDark),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_trim(occ)}% · $avail of $rooms rooms free',
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: _P.sub(isDark)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _AnimBar(
                      value: occ / 100,
                      color: _P.primary,
                      track: _P.soft(isDark),
                      height: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RECENT ACTIVITY
  // ============================================================
  Widget _activitySection(bool isDark, dynamic activity) {
    final list = _dl(() => activity.activities).take(5).toList();
    return _cardBox(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secHead(isDark, Icons.history_rounded, _P.primary, 'Recent Activity',
              sub: 'Latest updates across your properties'),
          const SizedBox(height: 14),
          for (int i = 0; i < list.length; i++) ...[
            _activityTile(isDark, list[i]),
            if (i != list.length - 1)
              Divider(height: 18, thickness: 1, color: _P.hair(isDark)),
          ],
        ],
      ),
    );
  }

  Widget _activityTile(bool isDark, dynamic item) {
    const c = _P.primary;
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: c.withOpacity(isDark ? 0.18 : 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_iconFor(_ds(() => item.icon)), color: c, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _ds(() => item.title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: _P.ink(isDark),
                ),
              ),
              Text(
                _ds(() => item.description),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    GoogleFonts.poppins(fontSize: 10.5, color: _P.sub(isDark)),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _ds(() => item.timeAgo),
          style: GoogleFonts.poppins(fontSize: 10.5, color: _P.sub(isDark)),
        ),
      ],
    );
  }

  // ============================================================
  // PAYOUT
  // ============================================================
  Widget _payoutCard(bool isDark, OwnerProvider ownerProvider) {
    final hasUpi = ownerProvider.hasPayoutUpi;
    final upi = _ds(() => (ownerProvider as dynamic).payoutUpiId);
    String masked = '';
    if (upi.contains('@')) {
      final parts = upi.split('@');
      final head = parts.first;
      masked =
          '${head.length <= 2 ? head : head.substring(0, 2)}••••@${parts.sublist(1).join('@')}';
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutCubic,
      transitionBuilder: (c, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(a), child: c),
      ),
      child: hasUpi
          ? Container(
              key: const ValueKey('upi_on'),
              margin: const EdgeInsets.fromLTRB(_kPad, 0, _kPad, 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _P.card(isDark),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _P.success.withOpacity(0.35)),
                boxShadow: [
                  BoxShadow(
                    color: _P.success.withOpacity(isDark ? 0.10 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _P.success.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.verified_rounded,
                        color: _P.success, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payments Activated',
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: _P.ink(isDark),
                          ),
                        ),
                        Text(
                          masked.isNotEmpty
                              ? 'Rent is paid out to $masked'
                              : 'You will receive rent automatically',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: _P.sub(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _pill('Active', _P.success, icon: Icons.check_rounded),
                ],
              ),
            )
          : Container(
              key: const ValueKey('upi_off'),
              margin: const EdgeInsets.fromLTRB(_kPad, 0, _kPad, 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_P.primaryDeep, _P.primary, _P.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _P.primary.withOpacity(0.35),
                    blurRadius: 22,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded,
                        color: Colors.white, size: 23),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set up Payments',
                          style: GoogleFonts.poppins(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Add your UPI ID to receive rent payments',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.85),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Tap(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showPayoutUpiDialog();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Text(
                        'Add UPI',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _P.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showPayoutUpiDialog() {
    final upiController = TextEditingController();
    String? error;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 260),
      transitionBuilder: (ctx, anim, _, child) {
        final c = anim.drive(CurveTween(curve: Curves.easeOutCubic));
        return FadeTransition(
          opacity: c,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(c),
            child: child,
          ),
        );
      },
      pageBuilder: (dialogContext, _, __) {
        final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (ctx, setD) => AlertDialog(
            backgroundColor: isDark ? _P.darkCard : Colors.white,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: _P.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.payments_rounded,
                      color: _P.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Add UPI',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: _P.ink(isDark),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rent payments will be sent to this UPI ID automatically.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: _P.sub(isDark),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: upiController,
                  autofocus: true,
                  cursorColor: _P.primary,
                  onChanged: (_) {
                    if (error != null) setD(() => error = null);
                  },
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: _P.ink(isDark),
                  ),
                  decoration: InputDecoration(
                    labelText: 'UPI ID',
                    hintText: 'e.g. owner@okhdfcbank',
                    errorText: error,
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                    filled: true,
                    fillColor:
                        isDark ? _P.darkSurface : const Color(0xFFF1F4FB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: _P.primary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.poppins(color: _P.sub(isDark)),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final upiId = upiController.text.trim();
                  final valid = RegExp(r'^[\w.\-]{2,256}@[a-zA-Z]{2,64}$')
                      .hasMatch(upiId);
                  if (!valid) {
                    setD(() => error = 'Please enter a valid UPI ID');
                    return;
                  }
                  Navigator.pop(dialogContext);
                  await _savePayoutUpi(upiId);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _P.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _savePayoutUpi(String upiId) async {
    final provider = Provider.of<PaymentProvider>(context, listen: false);
    final result = await provider.setPayoutUpi(upiId);

    if (!mounted) return;

    if (result['success'] == true) {
      final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
      await ownerProvider.setPayoutUpiSaved();

      _snack(result['message'] ?? 'UPI saved!', _P.success,
          Icons.check_circle_rounded);
      await _loadAll();
    } else {
      _snack(result['message'] ?? 'Failed', _P.danger,
          Icons.error_outline_rounded);
    }
  }

  void _snack(String msg, Color color, IconData icon) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
              ),
            ],
          ),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
  }

  // ============================================================
  // QUICK STATS
  // ============================================================
  Widget _statsGrid(bool isDark, dynamic stats) {
    final rating = _dn(() => stats.averageRating);
    final items = <Map<String, dynamic>>[
      {
        'label': 'Properties',
        'value': _dn(() => stats.totalProperties),
        'icon': Icons.apartment_rounded,
        'color': _P.primary,
      },
      {
        'label': 'Published',
        'value': _dn(() => stats.publishedProperties),
        'icon': Icons.check_circle_rounded,
        'color': _P.success,
      },
      {
        'label': 'Rooms',
        'value': _dn(() => stats.totalRooms),
        'icon': Icons.meeting_room_rounded,
        'color': _P.indigo,
      },
      {
        'label': 'Available',
        'value': _dn(() => stats.availableRooms),
        'icon': Icons.bed_rounded,
        'color': _P.sky,
      },
      {
        'label': 'Bookings',
        'value': _dn(() => stats.totalBookingRequests),
        'icon': Icons.book_online_rounded,
        'color': _P.primaryLight,
      },
      {
        'label': 'Pending',
        'value': _dn(() => stats.pendingRequests),
        'icon': Icons.schedule_rounded,
        'color': _P.gold,
      },
      {
        'label': 'Rating',
        'value': rating,
        'icon': Icons.star_rounded,
        'color': _P.gold,
        'rating': true,
      },
      {
        'label': 'Views',
        'value': _dn(() => stats.totalViews),
        'icon': Icons.visibility_rounded,
        'color': _P.teal,
        'compact': true,
      },
    ];

    Widget tile(Map<String, dynamic> m) {
      final c = m['color'] as Color;
      final isRating = m['rating'] == true;
      final compact = m['compact'] == true;
      final v = m['value'] as double;
      final numStyle = GoogleFonts.poppins(
        fontSize: 19,
        fontWeight: FontWeight.w800,
        color: _P.ink(isDark),
        letterSpacing: -0.3,
        height: 1.15,
      );
      return Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: c.withOpacity(isDark ? 0.18 : 0.11),
              shape: BoxShape.circle,
            ),
            child: Icon(m['icon'] as IconData, color: c, size: 20),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: (isRating && v <= 0)
                ? Text('—', style: numStyle)
                : _CountUp(
                    value: v,
                    style: numStyle,
                    format: (x) => isRating
                        ? x.toStringAsFixed(1)
                        : compact
                            ? _compact(x.roundToDouble())
                            : x.round().toString(),
                  ),
          ),
          const SizedBox(height: 2),
          Text(
            m['label'] as String,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: _P.sub(isDark),
            ),
          ),
        ],
      );
    }

    Widget row(int from) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = from; i < from + 4; i++) Expanded(child: tile(items[i])),
          ],
        );

    return _cardBox(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secHead(isDark, Icons.insights_rounded, _P.primary, 'Quick Stats',
              sub: 'Your portfolio at a glance'),
          const SizedBox(height: 18),
          row(0),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Divider(height: 1, color: _P.hair(isDark)),
          ),
          row(4),
        ],
      ),
    );
  }

  // ============================================================
  // VERIFICATION
  // ============================================================
  Widget _verificationCard(bool isDark, dynamic verification) {
    final isVerified = _db(() => verification.isVerified);
    final isRejected = _db(() => verification.isRejected);
    final color = isVerified
        ? _P.success
        : isRejected
            ? _P.danger
            : _P.gold;
    final icon = isVerified
        ? Icons.verified_rounded
        : isRejected
            ? Icons.error_outline_rounded
            : Icons.hourglass_top_rounded;
    final title = isVerified
        ? 'Verified Owner'
        : isRejected
            ? 'Verification Rejected'
            : 'Verification Pending';
    final subtitle = isVerified
        ? 'You can add properties & receive bookings'
        : isRejected
            ? _ds(() => verification.rejectionReason, 'Please re-apply')
            : 'Admin reviews within 24-48 hours';

    return Container(
      margin: const EdgeInsets.fromLTRB(_kPad, 0, _kPad, 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _P.ink(isDark),
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: _P.sub(isDark),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          if (isRejected)
            _Tap(
              onTap: () => _navigateTo(const OwnerApplyPage()),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Re-apply',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // SUBSCRIPTIONS
  // ============================================================
  Widget _subscriptionSection(
      bool isDark, dynamic accessStatus, dynamic listingSub) {
    final accessActive = _db(() => accessStatus.hasActiveSubscription);
    final accessDays = _di(() => accessStatus.daysRemaining);
    final accessMonths = _di(() => accessStatus.durationMonths);
    final accessPlan = _planName(_ds(() => accessStatus.plan));
    final accessEnd = _endDate(_d(() => accessStatus.endDate));
    final accessTotal = accessMonths > 0 ? accessMonths * 30 : 30;

    final listActive = _db(() => listingSub.isActive);
    final listDays = _di(() => listingSub.daysRemaining);
    final listPlan = _ds(() => listingSub.planDisplayName);
    final listEnd = _endDate(_d(() => listingSub.endDate));

    return _cardBox(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secHead(isDark, Icons.workspace_premium_rounded, _P.primary,
              'Subscriptions',
              sub: 'Plans that keep your listings live'),
          const SizedBox(height: 14),
          _subItem(
            isDark: isDark,
            title: 'Property Access',
            plan: accessActive ? accessPlan : '',
            emptyText: 'No active plan — buy to keep properties visible',
            active: accessActive,
            days: accessDays,
            totalDays: accessTotal,
            endLabel: accessEnd,
            color: _P.primary,
            icon: Icons.home_work_rounded,
            onTap: _navigateToPropertyAccess,
          ),
          const SizedBox(height: 10),
          _subItem(
            isDark: isDark,
            title: 'Listing Boost',
            plan: listActive ? listPlan : '',
            emptyText: 'No active plan — boost your search ranking',
            active: listActive,
            days: listDays,
            totalDays: 30,
            endLabel: listEnd,
            color: _P.indigo,
            icon: Icons.rocket_launch_rounded,
            onTap: _navigateToListingSubscription,
          ),
        ],
      ),
    );
  }

  String _endDate(dynamic raw) {
    if (raw == null) return '';
    final dt = raw is DateTime ? raw : DateTime.tryParse('$raw');
    if (dt == null) return '';
    return DateFormat('d MMM yyyy').format(dt);
  }

  Widget _subItem({
    required bool isDark,
    required String title,
    required String plan,
    required String emptyText,
    required bool active,
    required int days,
    required int totalDays,
    required String endLabel,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final expiring = active && days <= 7;
    final statusColor = !active
        ? _P.danger
        : expiring
            ? _P.gold
            : _P.success;
    final statusText = !active
        ? 'Inactive'
        : expiring
            ? 'Expiring soon'
            : 'Active';
    final progress = totalDays > 0 ? days / totalDays : 0.0;

    return _Tap(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _P.soft(isDark),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _P.ink(isDark),
                        ),
                      ),
                      Text(
                        active
                            ? '${plan.isEmpty ? 'Active plan' : plan} · $days ${days == 1 ? 'day' : 'days'} left'
                            : emptyText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                            fontSize: 10.5, color: _P.sub(isDark)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _pill(statusText, statusColor),
              ],
            ),
            if (active) ...[
              const SizedBox(height: 12),
              _AnimBar(
                value: progress,
                color: statusColor,
                track: _P.hair(isDark),
                height: 7,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    endLabel.isNotEmpty ? 'Valid till $endLabel' : 'Active',
                    style: GoogleFonts.poppins(
                        fontSize: 10.5, color: _P.sub(isDark)),
                  ),
                  const Spacer(),
                  Text(
                    expiring ? 'Renew now' : 'Manage',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: expiring ? _P.gold : color,
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      size: 16, color: expiring ? _P.gold : color),
                ],
              ),
            ] else ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Buy plan',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, size: 16, color: color),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // REELS
  // ============================================================
  Widget _reelsSection(bool isDark) {
    return _cardBox(
      isDark,
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_P.primaryDeep, _P.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.movie_creation_rounded,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reels',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Show your property with short video tours',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Tap(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _navigateTo(const OwnerReelsUploadScreen());
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.upload_rounded,
                              size: 16, color: _P.primary),
                          const SizedBox(width: 5),
                          Text(
                            'Upload',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _P.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  _reelTile(
                    isDark,
                    Icons.video_library_rounded,
                    'My Reels',
                    'View & manage',
                    _P.primary,
                    () => _navigateTo(const OwnerMyReelsScreen()),
                  ),
                  const SizedBox(width: 10),
                  _reelTile(
                    isDark,
                    Icons.analytics_rounded,
                    'Insights',
                    'Views & reach',
                    _P.sky,
                    () => _navigateTo(const OwnerMyReelsScreen()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reelTile(bool isDark, IconData icon, String label, String sub,
      Color color, VoidCallback onTap) {
    return Expanded(
      child: _Tap(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _P.soft(isDark),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _P.ink(isDark),
                      ),
                    ),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 10, color: _P.sub(isDark)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================
  Widget _quickActions(
    bool isDark, {
    required int pending,
    required int notifications,
    required int messages,
    required int properties,
  }) {
    final actions = <Map<String, dynamic>>[
      {
        'label': 'Properties',
        'sub': properties >= 0
            ? '$properties ${properties == 1 ? 'listing' : 'listings'}'
            : 'Manage listings',
        'icon': Icons.apartment_rounded,
        'color': _P.primary,
        'badge': 0,
        'onTap': () => _navigateTo(const OwnerPropertyManagementPage()),
      },
      {
        'label': 'Bookings',
        'sub': pending > 0 ? '$pending pending' : 'All caught up',
        'icon': Icons.book_online_rounded,
        'color': _P.sky,
        'badge': pending,
        'onTap': () => _navigateTo(const OwnerBookingManagementPage()),
      },
      {
        'label': 'Chat',
        'sub': messages > 0 ? '$messages unread' : 'Messages',
        'icon': Icons.chat_bubble_rounded,
        'color': _P.indigo,
        'badge': messages,
        'onTap': () => _navigateTo(const ChatListScreen()),
      },
      {
        'label': 'Alerts',
        'sub': notifications > 0 ? '$notifications new' : 'Notifications',
        'icon': Icons.notifications_rounded,
        'color': _P.teal,
        'badge': notifications,
        'onTap': () => _navigateTo(const NotificationScreen()),
      },
    ];

    Widget tile(Map<String, dynamic> a) {
      final c = a['color'] as Color;
      final badge = a['badge'] as int;
      return Expanded(
        child: _Tap(
          onTap: () {
            HapticFeedback.selectionClick();
            (a['onTap'] as VoidCallback)();
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: c.withOpacity(isDark ? 0.10 : 0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.withOpacity(0.18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(a['icon'] as IconData, color: c, size: 20),
                    ),
                    const Spacer(),
                    if (badge > 0)
                      Container(
                        constraints:
                            const BoxConstraints(minWidth: 22, minHeight: 22),
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          badge > 99 ? '99+' : '$badge',
                          style: GoogleFonts.poppins(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      )
                    else
                      Icon(Icons.arrow_outward_rounded,
                          size: 17, color: _P.sub(isDark)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  a['label'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _P.ink(isDark),
                  ),
                ),
                Text(
                  a['sub'] as String,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      GoogleFonts.poppins(fontSize: 10.5, color: _P.sub(isDark)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _cardBox(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secHead(isDark, Icons.flash_on_rounded, _P.primary, 'Quick Actions',
              sub: 'Jump to what matters'),
          const SizedBox(height: 14),
          Row(children: [
            tile(actions[0]),
            const SizedBox(width: 10),
            tile(actions[1]),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            tile(actions[2]),
            const SizedBox(width: 10),
            tile(actions[3]),
          ]),
        ],
      ),
    );
  }

  // ============================================================
  // BOOKING OVERVIEW
  // ============================================================
  Widget _bookingOverview(bool isDark, Map<String, int> counts) {
    final pending = counts['PENDING'] ?? 0;
    final accepted = counts['ACCEPTED'] ?? 0;
    final rejected = counts['REJECTED'] ?? 0;
    final cancelled = counts['CANCELLED'] ?? 0;
    final completed = counts['COMPLETED'] ?? 0;
    final total = counts['TOTAL'] ?? 0;
    final decided = accepted + rejected;
    final acceptance = decided > 0 ? accepted / decided * 100 : 0.0;
    const slate = Color(0xFF94A3B8);

    Widget stat(String label, int v, IconData icon, Color c) {
      return Expanded(
        child: _Tap(
          onTap: () => _navigateTo(const OwnerBookingManagementPage()),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: c.withOpacity(isDark ? 0.10 : 0.07),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(icon, color: c, size: 18),
                const SizedBox(height: 6),
                _CountUp(
                  value: v.toDouble(),
                  format: (x) => x.round().toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: c,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: _P.sub(isDark),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget legend(String label, int v, Color c) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$label $v',
              style: GoogleFonts.poppins(fontSize: 10.5, color: _P.sub(isDark)),
            ),
          ],
        );

    final accColor = acceptance >= 70
        ? _P.success
        : acceptance >= 40
            ? _P.gold
            : _P.danger;

    return _cardBox(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secHead(
            isDark,
            Icons.pending_actions_rounded,
            _P.primary,
            'Booking Overview',
            sub: '$total total requests',
            trailing: _Tap(
              onTap: () => _navigateTo(const OwnerBookingManagementPage()),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View all',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _P.primary,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 17, color: _P.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _SegBar(
            isDark: isDark,
            values: [pending, accepted, rejected, cancelled, completed],
            colors: const [
              _P.gold,
              _P.success,
              _P.danger,
              slate,
              _P.sky,
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              legend('Pending', pending, _P.gold),
              legend('Accepted', accepted, _P.success),
              legend('Rejected', rejected, _P.danger),
              if (cancelled > 0) legend('Cancelled', cancelled, slate),
              if (completed > 0) legend('Completed', completed, _P.sky),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              stat('Pending', pending, Icons.schedule_rounded, _P.gold),
              const SizedBox(width: 10),
              stat('Accepted', accepted, Icons.check_circle_rounded,
                  _P.success),
              const SizedBox(width: 10),
              stat('Rejected', rejected, Icons.cancel_rounded, _P.danger),
            ],
          ),
          if (decided > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _P.soft(isDark),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Acceptance rate',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: _P.ink(isDark),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_trim(acceptance)}%',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: accColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _AnimBar(
                    value: acceptance / 100,
                    color: accColor,
                    track: _P.hair(isDark),
                    height: 7,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}