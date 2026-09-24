// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:yourhome/models/booking_model.dart';
import 'package:yourhome/providers/auth_provider.dart';
import 'package:yourhome/screens/booking/booking_payment_screen.dart';
import '../providers/property_provider.dart';
import '../models/property_model.dart';
import '../models/room_model.dart';
import '../models/review_model.dart';
import '../services/booking_service.dart';
import '../services/chat_service.dart';
import 'chat/chat_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final int propertyId;

  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
  });

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isSaved = false;
  String? _error;
  Property? _property;
  List<Room> _rooms = [];
  List<Review> _reviews = [];
  int _selectedTabIndex = 0;

  int? _activeBookingRequestId;
  int? _activeRoomId;
  String? _bookingStatus;
  Set<int> _bookedRoomIds = {};
  int _paidBookingsCount = 0;
  bool _isCheckingBooking = false;

  bool _isUserLoggedIn = false;
  bool _isCheckingLogin = true;

  final ChatService _chatService = ChatService();

  Color get _primary => Theme.of(context).primaryColor;
  Color get _goldAccent => const Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _checkLoginStatus();
    _loadPropertyDetail();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final isLoggedIn = token != null && token.isNotEmpty;

      if (mounted) {
        setState(() {
          _isUserLoggedIn = isLoggedIn;
          _isCheckingLogin = false;
        });
      }

      debugPrint('═══════════════════════════════════════');
      debugPrint('🔐 LOGIN STATUS CHECK');
      debugPrint('   Token exists: ${token != null}');
      debugPrint('   Is logged in: $isLoggedIn');
      debugPrint('═══════════════════════════════════════');
    } catch (e) {
      debugPrint('❌ Login check error: $e');
      if (mounted) {
        setState(() => _isCheckingLogin = false);
      }
    }
  }

  Future<void> _loadPropertyDetail() async {
    setState(() => _isLoading = true);

    final propertyProvider =
        Provider.of<PropertyProvider>(context, listen: false);

    await propertyProvider.loadPropertyDetailWithRooms(widget.propertyId);

    final property = propertyProvider.selectedProperty;

    if (property != null) {
      _property = property;
      _rooms = propertyProvider.rooms;
      _isSaved = propertyProvider.savedProperties
          .any((p) => p.propertyId == property.propertyId);

      debugPrint('═══════════════════════════════════════');
      debugPrint('✅ PROPERTY: ${property.title}');
      debugPrint('✅ ROOMS COUNT: ${_rooms.length}');
      debugPrint('✅ ROOMS: ${_rooms.map((r) => "${r.roomNumber}|${r.status}").toList()}');
      debugPrint('═══════════════════════════════════════');

      if (_isUserLoggedIn) {
        await _checkActiveBooking();
      }
    } else {
      _error = propertyProvider.error ?? 'Failed to load property';
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _checkActiveBooking() async {
    if (!_isUserLoggedIn) return;

    setState(() => _isCheckingBooking = true);

    try {
      final bookingService = BookingService();
      final response = await bookingService.getMyBookings();

      if (response.success && response.data != null) {
        final bookings = response.data!;

        // Sirf is property ki bookings
        final propertyBookings = bookings
            .where((b) => b.propertyId == widget.propertyId)
            .toList();

        BookingRequest? acceptedUnpaidBooking;
        BookingRequest? pendingBooking;
        int paidCount = 0;
        final Set<int> bookedRoomIds = {};

        debugPrint('═══════════════════════════════════════');
        debugPrint('📋 BOOKINGS FOR PROPERTY ${widget.propertyId}');

        for (final booking in propertyBookings) {
          debugPrint(
              '   #${booking.requestId} | roomId: ${booking.roomId} | status: ${booking.status} | isPaid: ${booking.isPaid}');

          // Track booked rooms (PENDING, ACCEPTED, PAID — sab)
          if (booking.roomId != null) {
            if (booking.status == 'PENDING' ||
                booking.status == 'ACCEPTED' ||
                booking.isPaid) {
              bookedRoomIds.add(booking.roomId!);
            }
          }

          if (booking.status == 'ACCEPTED' && booking.isPaid) {
            paidCount++;
          } else if (booking.status == 'ACCEPTED' && !booking.isPaid) {
            acceptedUnpaidBooking = booking;
          } else if (booking.status == 'PENDING') {
            pendingBooking = booking;
          }
        }
        debugPrint('   Booked room IDs: $bookedRoomIds');
        debugPrint('   Paid bookings count: $paidCount');
        debugPrint('═══════════════════════════════════════');

        if (mounted) {
          setState(() {
            _bookedRoomIds = bookedRoomIds;
            _paidBookingsCount = paidCount;

            if (acceptedUnpaidBooking != null) {
              _activeBookingRequestId = acceptedUnpaidBooking!.requestId;
              _activeRoomId = acceptedUnpaidBooking.roomId;
              _bookingStatus = 'ACCEPTED';
            } else if (pendingBooking != null) {
              _activeBookingRequestId = pendingBooking!.requestId;
              _activeRoomId = pendingBooking.roomId;
              _bookingStatus = 'PENDING';
            } else if (paidCount > 0) {
              _activeBookingRequestId = null;
              _activeRoomId = null;
              _bookingStatus = 'PAID';
            } else {
              _activeBookingRequestId = null;
              _activeRoomId = null;
              _bookingStatus = null;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking booking: $e');
    }

    if (mounted) setState(() => _isCheckingBooking = false);
  }

  Future<void> _toggleSave() async {
    if (!_isUserLoggedIn) {
      _showLoginPrompt();
      return;
    }

    final propertyProvider =
        Provider.of<PropertyProvider>(context, listen: false);

    if (_isSaved) {
      await propertyProvider.removeSavedProperty(widget.propertyId);
      setState(() => _isSaved = false);
      _showSnack(
        icon: Icons.favorite,
        iconColor: Colors.white,
        text: 'Removed from favorites',
        bg: Colors.grey[800]!,
      );
    } else {
      await propertyProvider.saveProperty(widget.propertyId);
      setState(() => _isSaved = true);
      _showSnack(
        icon: Icons.favorite,
        iconColor: Colors.redAccent,
        text: 'Added to favorites',
        bg: Colors.grey[900]!,
      );
    }
  }

  void _showSnack({
    required IconData icon,
    required Color iconColor,
    required String text,
    Color? bg,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: bg ?? Colors.black87,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 6,
      ),
    );
  }

  Future<void> _chatWithOwner() async {
    if (!_isUserLoggedIn) {
      _showLoginPrompt();
      return;
    }

    if (_property == null) return;

    try {
      final response = await _chatService.createConversation(
        ownerUserId: _property!.ownerUserId ?? 0,
        propertyId: _property!.propertyId,
      );

      if (response.success && response.data != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: response.data!.conversationId,
              otherUserId: response.data!.otherUserId,
              otherUserName: response.data!.otherUserName,
              propertyTitle: response.data!.propertyTitle,
            ),
          ),
        );
      } else {
        _showSnack(
          icon: Icons.error_outline,
          iconColor: Colors.white,
          text: response.message,
          bg: Colors.red[700]!,
        );
      }
    } catch (e) {
      _showSnack(
        icon: Icons.error_outline,
        iconColor: Colors.white,
        text: 'Failed to start chat: $e',
        bg: Colors.red[700]!,
      );
    }
  }

  Future<void> _bookNow({bool forceNew = false}) async {
    if (!_isUserLoggedIn) {
      _showLoginPrompt();
      return;
    }

    if (_property == null) return;

    // Agar forceNew nahi hai — purane status check karo
    if (!forceNew) {
      // ACCEPTED unpaid → Pay Now
      if (_activeBookingRequestId != null && _bookingStatus == 'ACCEPTED') {
        final activeRoom = _rooms.firstWhere(
          (r) => r.roomId == _activeRoomId,
          orElse: () => _rooms.isNotEmpty
              ? _rooms.first
              : Room(
                  roomId: 0,
                  roomType: 'SINGLE',
                  monthlyRent: 0,
                  capacity: 1,
                ),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingPaymentScreen(
              bookingRequestId: _activeBookingRequestId!,
              propertyTitle: _property!.title,
              roomNumber: activeRoom.roomNumber ?? 'N/A',
              originalAmount: _property!.monthlyRentMin ?? 10000,
            ),
          ),
        );
        return;
      }

      // PENDING → snackbar
      if (_activeBookingRequestId != null && _bookingStatus == 'PENDING') {
        _showSnack(
          icon: Icons.hourglass_top_rounded,
          iconColor: Colors.white,
          text:
              'You have a pending request. Please wait for owner response.',
          bg: Colors.orange[700]!,
        );
        return;
      }
    }

    // ✅ Check karo koi available room hai kya (booked ke alawa)
    final availableRooms = _rooms
        .where((r) =>
            r.status == 'AVAILABLE' && !_bookedRoomIds.contains(r.roomId))
        .toList();

    if (availableRooms.isEmpty) {
      _showSnack(
        icon: Icons.error_outline,
        iconColor: Colors.white,
        text: _bookedRoomIds.isNotEmpty
            ? 'You have already booked all available rooms in this property.'
            : 'No rooms available for this property yet.',
        bg: Colors.orange[800]!,
      );
      return;
    }

    // Bottom sheet kholo — booked rooms exclude karke
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (context) => BookingBottomSheet(
        property: _property!,
        rooms: _rooms,
        bookedRoomIds: _bookedRoomIds,
        onSuccess: () {
          _showSnack(
            icon: Icons.check_circle,
            iconColor: Colors.greenAccent,
            text: 'Booking request sent! Waiting for owner approval.',
            bg: Colors.grey[900]!,
          );
          _checkActiveBooking();
        },
      ),
    );
  }

  void _watchTour() {
    final videoMedia = _property?.media.firstWhere(
      (m) => m.mediaType == 'VIDEO',
      orElse: () => Media(
        mediaId: 0,
        mediaType: 'IMAGE',
        url: '',
      ),
    );

    if (videoMedia != null && videoMedia.url.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => InAppVideoPlayerScreen(
            videoUrl: videoMedia.url,
            title: _property?.title ?? 'Property Tour',
          ),
        ),
      );
    } else {
      _showSnack(
        icon: Icons.videocam_off,
        iconColor: Colors.white,
        text: 'No tour video available',
        bg: Colors.orange[800]!,
      );
    }
  }

  Future<void> _reportProperty() async {
    if (!_isUserLoggedIn) {
      _showLoginPrompt();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => ReportDialog(
        propertyId: _property!.propertyId,
        onSuccess: () {
          _showSnack(
            icon: Icons.check_circle,
            iconColor: Colors.greenAccent,
            text: 'Report submitted successfully!',
            bg: Colors.grey[900]!,
          );
        },
      ),
    );
  }

  void _openLocation() async {
    if (_property?.latitude == null || _property?.longitude == null) return;

    final url = 'https://www.google.com/maps/search/?api=1&query='
        '${_property!.latitude},${_property!.longitude}';

    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      _showSnack(
        icon: Icons.error_outline,
        iconColor: Colors.white,
        text: 'Could not open maps',
        bg: Colors.red[700]!,
      );
    }
  }

  void _copyCoordinates() {
    if (_property?.latitude == null || _property?.longitude == null) return;

    final coords = '${_property!.latitude}, ${_property!.longitude}';
    _showSnack(
      icon: Icons.copy,
      iconColor: Colors.white,
      text: 'Coordinates copied: $coords',
      bg: Colors.grey[850]!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyColor =
        isDark ? const Color(0xFF12121E) : const Color(0xFFF7F8FA);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bodyColor,
        appBar: AppBar(
          backgroundColor: bodyColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _primary),
              const SizedBox(height: 16),
              Text(
                'Loading property details...',
                style: GoogleFonts.poppins(
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null || _property == null) {
      return Scaffold(
        backgroundColor: bodyColor,
        appBar: AppBar(
          backgroundColor: bodyColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _error ?? 'Property not found',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _loadPropertyDetail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bodyColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(isDark, bodyColor),
          SliverToBoxAdapter(
            child: _buildBody(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildBookNowSection(bool isDark) {
    final property = _property!;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B2F) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.07),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => LinearGradient(
                      colors: [_primary, _primary.withOpacity(0.65)],
                    ).createShader(bounds),
                    child: Text(
                      property.monthlyRentMin != null
                          ? '₹${property.monthlyRentMin!.toStringAsFixed(0)}'
                          : 'Contact for price',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  if (property.monthlyRentMax != null &&
                      property.monthlyRentMax != property.monthlyRentMin)
                    Text(
                      '— ₹${property.monthlyRentMax!.toStringAsFixed(0)} /month',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFF11998E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${property.availableRooms} available',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF11998E),
                    fontWeight: FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (property.securityDeposit != null)
            Text(
              'Security: ₹${property.securityDeposit!.toStringAsFixed(0)} • ${property.isNegotiable ? 'Negotiable' : 'Fixed'}',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: Colors.grey[600],
              ),
            ),
          const SizedBox(height: 18),
          _buildBookingActionButton(isDark),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _secondaryActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  onTap: _chatWithOwner,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _secondaryActionButton(
                  icon: Icons.play_circle_outline,
                  label: 'Tour',
                  onTap: _watchTour,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _secondaryActionButton(
                  icon: Icons.flag_outlined,
                  label: 'Report',
                  onTap: _reportProperty,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingActionButton(bool isDark) {
    if (_isCheckingLogin) {
      return _loadingButton(isDark);
    }

    if (_isCheckingBooking) {
      return _loadingButton(isDark);
    }

    // CASE 1: ACCEPTED unpaid → Pay Now
    if (_activeBookingRequestId != null && _bookingStatus == 'ACCEPTED') {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primary, _primary.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _primary.withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _bookNow,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payment_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Pay Now',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // CASE 2: PENDING → waiting card
    if (_activeBookingRequestId != null && _bookingStatus == 'PENDING') {
      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.hourglass_top_rounded,
                    color: Colors.orange, size: 20),
                const SizedBox(width: 8),
                Text(
                  '⏳ Booking Request Pending',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // CASE 3: PAID → Already booked + Book Another Room
    if (_bookingStatus == 'PAID' && _paidBookingsCount > 0) {
      final hasAvailableRooms = _rooms.any((r) =>
          r.status == 'AVAILABLE' && !_bookedRoomIds.contains(r.roomId));

      return Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Text(
                  _paidBookingsCount > 1
                      ? '✅ $_paidBookingsCount Rooms Booked'
                      : '✅ Already Booked',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          if (hasAvailableRooms) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primary, _primary.withOpacity(0.75)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _bookNow(forceNew: true),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_rounded,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Book Another Room',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
    }

    // CASE 4: No booking → Book Now
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primary, _primary.withOpacity(0.75)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _isUserLoggedIn ? _bookNow : _showLoginPrompt,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isUserLoggedIn ? Icons.bolt : Icons.login_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isUserLoggedIn ? 'Book Now' : 'Login to Book',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadingButton(bool isDark) {
    return Container(
      width: double.infinity,
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2.2, color: _primary),
      ),
    );
  }

  void _showLoginPrompt() {
    _showSnack(
      icon: Icons.login_rounded,
      iconColor: Colors.white,
      text: 'Please login to continue',
      bg: Colors.orange[700]!,
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.28),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: IconButton(
              icon: Icon(icon, color: iconColor ?? Colors.white, size: 20),
              onPressed: onTap,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(bool isDark, Color bodyColor) {
    final property = _property!;

    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: bodyColor,
      elevation: 0,
      leadingWidth: 56,
      leading: _glassIconButton(
        icon: Icons.arrow_back_ios_new,
        onTap: () => Navigator.pop(context),
      ),
      actions: [
        _glassIconButton(
          icon: _isSaved ? Icons.favorite : Icons.favorite_border,
          iconColor: _isSaved ? Colors.redAccent : Colors.white,
          onTap: _toggleSave,
        ),
        _glassIconButton(
          icon: Icons.share,
          onTap: () {},
        ),
        const SizedBox(width: 4),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            property.coverImage.isNotEmpty
                ? Image.network(
                    property.coverImage,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 64,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: const Icon(
                      Icons.house,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.55, 1.0],
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 18,
              left: 18,
              right: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (property.isVerifiedOwner)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified,
                                  color: Colors.white, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                'Verified Owner',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF7971E), Color(0xFFFFD200)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.play_circle_fill,
                                color: Colors.white, size: 13),
                            const SizedBox(width: 4),
                            Text(
                              'Tour Available',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    property.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ],
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

  Widget _buildBody(bool isDark) {
    final property = _property!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on_rounded,
                size: 16,
                color: _primary,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${property.addressLine}, ${property.city}, ${property.state} - ${property.pincode}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildTag(property.propertyType, _primary),
              _buildTag(property.genderAllowed, Colors.purple),
              _buildTag('${property.viewCount} views', Colors.blueGrey),
              _buildTag('${property.availableRooms} available',
                  const Color(0xFF11998E)),
            ],
          ),
          const SizedBox(height: 20),
          _buildTabBar(isDark),
          const SizedBox(height: 18),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: ValueKey(_selectedTabIndex),
              child: _buildTabContent(isDark),
            ),
          ),
          const SizedBox(height: 24),
          _buildBookNowSection(isDark),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B2F) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        labelStyle:
            GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12.5),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12.5),
        indicator: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primary, _primary.withOpacity(0.75)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.35),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Rooms'),
          Tab(text: 'Reviews'),
          Tab(text: 'Tour'),
        ],
      ),
    );
  }

  Widget _buildTabContent(bool isDark) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildOverviewTab(isDark);
      case 1:
        return _buildRoomsTab(isDark);
      case 2:
        return _buildReviewsTab(isDark);
      case 3:
        return _buildTourTab(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _premiumCard({required Widget child, bool isDark = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B2F) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildOverviewTab(bool isDark) {
    final property = _property!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (property.description.isNotEmpty) ...[
          _premiumCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About this place',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  property.description,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    height: 1.7,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (property.amenities.isNotEmpty) ...[
          _premiumCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amenities',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: property.amenities.map((amenity) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : _primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _primary.withOpacity(0.15),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getAmenityIcon(amenity),
                            size: 14,
                            color: _primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            amenity,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        Text(
          'Location on Map',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          height: MediaQuery.of(context).size.width * 0.5,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: property.latitude != null && property.longitude != null
                ? Image.network(
                    'https://maps.googleapis.com/maps/api/staticmap?'
                    'center=${property.latitude},${property.longitude}&'
                    'zoom=15&size=600x300&'
                    'markers=color:red%7C${property.latitude},${property.longitude}&'
                    'key=YOUR_GOOGLE_MAPS_API_KEY',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map, size: 48, color: Colors.grey[500]),
                          const SizedBox(height: 8),
                          Text(
                            'Map not available',
                            style:
                                GoogleFonts.poppins(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  )
                : Container(
                    color: Colors.grey[300],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off,
                            size: 48, color: Colors.grey[500]),
                        const SizedBox(height: 8),
                        Text(
                          'Location not available',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _openLocation,
                icon: Icon(Icons.map_outlined, color: _primary, size: 18),
                label: Text('Open in Maps',
                    style: GoogleFonts.poppins(color: _primary, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: _primary.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyCoordinates,
                icon: Icon(Icons.copy, color: _primary, size: 16),
                label: Text('Copy coords',
                    style: GoogleFonts.poppins(color: _primary, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: _primary.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Property Owner',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        _premiumCard(
          isDark: isDark,
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [_primary, _primary.withOpacity(0.7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  backgroundColor: Colors.transparent,
                  child: Text(
                    property.ownerName?.isNotEmpty == true
                        ? property.ownerName![0].toUpperCase()
                        : 'O',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
                      property.ownerName ?? 'Owner',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    if (property.isVerifiedOwner)
                      Row(
                        children: [
                          const Icon(Icons.verified,
                              size: 14, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            'Verified Owner',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _chatWithOwner,
                icon: const Icon(Icons.chat_bubble_outline, size: 15),
                label: const Text('Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(84, 38),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoomsTab(bool isDark) {
    if (_rooms.isEmpty) {
      return _emptyState(
        icon: Icons.bed_outlined,
        text: 'No rooms available',
        isDark: isDark,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Available Rooms',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF11998E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_rooms.where((r) => r.status == 'AVAILABLE').length} available',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF11998E),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._rooms.map((room) => _buildRoomCard(room, isDark)),
      ],
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(icon, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              text,
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomCard(Room room, bool isDark) {
    final isAvailable = room.status == 'AVAILABLE';
    final isBooked = _bookedRoomIds.contains(room.roomId);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B2F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.22 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isBooked
              ? Colors.green.withOpacity(0.4)
              : (isAvailable
                  ? const Color(0xFF11998E).withOpacity(0.25)
                  : Colors.transparent),
          width: isBooked ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isBooked
                    ? [Colors.green, Colors.green.shade400]
                    : (isAvailable
                        ? [const Color(0xFF11998E), const Color(0xFF38EF7D)]
                        : [Colors.grey, Colors.grey.shade400]),
              ),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Room ${room.roomNumber ?? room.roomId}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    if (isBooked) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'YOURS',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: Colors.green,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      room.roomType,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (room.hasAc) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'AC',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                    if (room.hasAttachedBathroom) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.teal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Bath',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.teal,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${room.monthlyRent.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isBooked
                      ? Colors.green
                      : (isAvailable ? _primary : Colors.grey),
                ),
              ),
              Text(
                '/month',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isBooked
                      ? Colors.green.withOpacity(0.15)
                      : (isAvailable
                          ? const Color(0xFF11998E).withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isBooked
                      ? 'Booked'
                      : (isAvailable ? 'Available' : 'Occupied'),
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: isBooked
                        ? Colors.green
                        : (isAvailable
                            ? const Color(0xFF11998E)
                            : Colors.grey),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab(bool isDark) {
    if (_reviews.isEmpty) {
      return _emptyState(
        icon: Icons.star_border,
        text: 'No reviews yet',
        isDark: isDark,
      );
    }

    return Column(
      children: [
        _premiumCard(
          isDark: isDark,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF7971E), Color(0xFFFFD200)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _property!.averageRating?.toStringAsFixed(1) ?? '4.0',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        final rating = _property!.averageRating ?? 4.0;
                        return Icon(
                          index < rating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 18,
                        );
                      }),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_reviews.length} reviews',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.edit, size: 15, color: _primary),
                label: Text('Write',
                    style: GoogleFonts.poppins(color: _primary, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _primary.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._reviews.map((review) => _buildReviewCard(review, isDark)),
      ],
    );
  }

  Widget _buildReviewCard(Review review, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: _premiumCard(
        isDark: isDark,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: _primary,
                  child: Text(
                    review.userName[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index < review.rating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 13,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatDate(review.createdAt),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            if (review.comment != null) ...[
              const SizedBox(height: 8),
              Text(
                review.comment!,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  height: 1.5,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTourTab(bool isDark) {
    final videoMedia = _property?.media.firstWhere(
      (m) => m.mediaType == 'VIDEO',
      orElse: () => Media(
        mediaId: 0,
        mediaType: 'IMAGE',
        url: '',
      ),
    );

    final hasVideo = videoMedia != null && videoMedia.url.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            height: 210,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F0F1E), Color(0xFF1A1A2E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: hasVideo
                ? InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _watchTour,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primary, _primary.withOpacity(0.6)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 44,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.videocam_off, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No tour video available',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            hasVideo
                ? 'Tap to play property tour video'
                : 'No tour video available for this property',
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
          if (hasVideo)
            TextButton.icon(
              onPressed: _watchTour,
              icon: Icon(Icons.play_circle_filled, color: _primary),
              label: Text(
                'Watch Full Tour',
                style: GoogleFonts.poppins(
                  color: _primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _secondaryActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? _primary;
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 17, color: c),
      label: Text(
        label,
        style: GoogleFonts.poppins(
            fontSize: 12, color: c, fontWeight: FontWeight.w500),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        side: BorderSide(color: c.withOpacity(0.35)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'ac':
        return Icons.ac_unit;
      case 'meals':
        return Icons.restaurant;
      case 'laundry':
        return Icons.local_laundry_service;
      case 'cctv':
        return Icons.videocam;
      case 'parking':
        return Icons.local_parking;
      case 'gym':
        return Icons.fitness_center;
      case 'hot water':
        return Icons.water;
      case 'power backup':
        return Icons.battery_alert;
      case 'security':
        return Icons.security;
      case 'tv':
        return Icons.tv;
      case 'fridge':
        return Icons.kitchen;
      default:
        return Icons.circle;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inMinutes}m ago';
    }
  }
}

// ══════════════════════════════════════════════════════════════
// BOOKING BOTTOM SHEET — Updated
// ══════════════════════════════════════════════════════════════
class BookingBottomSheet extends StatefulWidget {
  final Property property;
  final List<Room> rooms;
  final Set<int> bookedRoomIds;
  final VoidCallback onSuccess;

  const BookingBottomSheet({
    super.key,
    required this.property,
    required this.rooms,
    this.bookedRoomIds = const {},
    required this.onSuccess,
  });

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _messageController = TextEditingController();

  DateTime? _selectedDate;
  int? _selectedRoomId;
  int _durationMonths = 1;
  bool _isLoading = false;
  String? _dateError;

  final BookingService _bookingService = BookingService();

  Color get _primary => Theme.of(context).primaryColor;

  List<Room> get _allRooms => widget.rooms;

  Room? get _selectedRoom {
    if (_selectedRoomId == null) return null;
    try {
      return widget.rooms.firstWhere((r) => r.roomId == _selectedRoomId);
    } catch (_) {
      return null;
    }
  }

  double get _estimatedMonthlyRent {
    if (_selectedRoom != null) return _selectedRoom!.monthlyRent;
    return widget.property.monthlyRentMin ?? 0;
  }

  double get _estimatedTotal => _estimatedMonthlyRent * _durationMonths;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: _primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateError = null;
      });
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _apiDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _submitBooking() async {
    if (_selectedDate == null) {
      setState(() => _dateError = 'Please select a move-in date');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final request = CreateBookingRequest(
      propertyId: widget.property.propertyId,
      roomId: _selectedRoomId,
      moveInDate: _apiDate(_selectedDate!),
      durationMonths: _durationMonths,
      message: _messageController.text.trim().isNotEmpty
          ? _messageController.text.trim()
          : null,
    );

    final response = await _bookingService.sendBookingRequest(request);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (response.success) {
      Navigator.pop(context);
      widget.onSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetColor = isDark ? const Color(0xFF15152A) : Colors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.6,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: sheetColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 4),
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 12, 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primary, _primary.withOpacity(0.65)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withOpacity(0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.bolt,
                            color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.bookedRoomIds.isNotEmpty
                                  ? 'Book Another Room'
                                  : 'Book Your Stay',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              widget.property.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 12.5,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            color: isDark ? Colors.white70 : Colors.black54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Select Room', isDark, optional: true),
                        const SizedBox(height: 10),
                        _buildRoomSelector(isDark),
                        const SizedBox(height: 22),
                        _sectionTitle('Move-in Date', isDark),
                        const SizedBox(height: 10),
                        _buildDateField(isDark),
                        if (_dateError != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            _dateError!,
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: Colors.red,
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        _sectionTitle('Duration', isDark),
                        const SizedBox(height: 10),
                        _buildDurationChips(isDark),
                        const SizedBox(height: 22),
                        _sectionTitle('Message to Owner', isDark,
                            optional: true),
                        const SizedBox(height: 10),
                        _buildMessageField(isDark),
                        const SizedBox(height: 22),
                        _buildPriceSummary(isDark),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                  decoration: BoxDecoration(
                    color: sheetColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 14,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_primary, _primary.withOpacity(0.75)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: _primary.withOpacity(0.4),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: _isLoading ? null : _submitBooking,
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.send_rounded,
                                            color: Colors.white, size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Send Booking Request',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title, bool isDark, {bool optional = false}) {
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 6),
          Text(
            '(Optional)',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRoomSelector(bool isDark) {
    // Available rooms — already booked by user excluded
    final availableRooms = _allRooms
        .where((r) =>
            r.status == 'AVAILABLE' &&
            !widget.bookedRoomIds.contains(r.roomId))
        .toList();

    return Column(
      children: [
        // "Any Available Room" option (only if available rooms exist)
        if (availableRooms.isNotEmpty)
          _roomOptionCard(
            isDark: isDark,
            selected: _selectedRoomId == null,
            title: 'Any Available Room',
            subtitle: 'Owner will assign the best available room',
            trailing: null,
            onTap: () => setState(() => _selectedRoomId = null),
            icon: Icons.auto_awesome,
          ),
        const SizedBox(height: 10),

        // Show ALL rooms — booked ones disabled
        ..._allRooms.map((room) {
          final isAvailable = room.status == 'AVAILABLE';
          final isBooked = widget.bookedRoomIds.contains(room.roomId);
          final canBook = isAvailable && !isBooked;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _roomOptionCard(
              isDark: isDark,
              selected: _selectedRoomId == room.roomId,
              enabled: canBook,
              isBooked: isBooked,
              title: 'Room ${room.roomNumber ?? room.roomId}',
              subtitle: isBooked
                  ? 'Already booked by you'
                  : (isAvailable
                      ? '${room.roomType}${room.hasAc ? ' • AC' : ''}${room.hasAttachedBathroom ? ' • Bath' : ''}'
                      : '${room.roomType}${room.hasAc ? ' • AC' : ''} • Occupied'),
              trailing: isBooked
                  ? 'Booked'
                  : (isAvailable
                      ? '₹${room.monthlyRent.toStringAsFixed(0)}/mo'
                      : 'Unavailable'),
              onTap: canBook
                  ? () => setState(() => _selectedRoomId = room.roomId)
                  : null,
              icon: isBooked ? Icons.check_circle : Icons.bed_outlined,
            ),
          );
        }),

        if (availableRooms.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.orange[700]),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'No more rooms available for booking.',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: Colors.orange[700],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _roomOptionCard({
    required bool isDark,
    required bool selected,
    required String title,
    required String subtitle,
    required String? trailing,
    required VoidCallback? onTap,
    required IconData icon,
    bool enabled = true,
    bool isBooked = false,
  }) {
    final color = _primary;
    return Opacity(
      opacity: enabled ? 1 : (isBooked ? 0.75 : 0.5),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? onTap : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: selected
                    ? color.withOpacity(isDark ? 0.16 : 0.08)
                    : (isBooked
                        ? Colors.green.withOpacity(isDark ? 0.08 : 0.05)
                        : (isDark
                            ? const Color(0xFF1E1E38)
                            : Colors.grey[50])),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? color
                      : (isBooked
                          ? Colors.green.withOpacity(0.3)
                          : Colors.transparent),
                  width: 1.6,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: isBooked
                          ? Colors.green.withOpacity(0.15)
                          : (selected
                              ? color.withOpacity(0.15)
                              : Colors.grey.withOpacity(0.12)),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 18,
                      color: isBooked
                          ? Colors.green
                          : (selected ? color : Colors.grey[600]),
                    ),
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
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: isBooked
                                ? Colors.green
                                : (!enabled
                                    ? Colors.red[300]
                                    : Colors.grey[500]),
                            fontWeight:
                                isBooked ? FontWeight.w600 : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        trailing,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isBooked
                              ? Colors.green
                              : (enabled ? color : Colors.grey),
                        ),
                      ),
                    ),
                  if (!isBooked)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: selected
                          ? Icon(Icons.check_circle,
                              color: color,
                              size: 20,
                              key: const ValueKey('sel'))
                          : Icon(Icons.circle_outlined,
                              color: Colors.grey[400],
                              size: 20,
                              key: const ValueKey('unsel')),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateField(bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E38) : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _dateError != null
                ? Colors.red
                : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 18, color: _primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _selectedDate != null
                    ? _formatDate(_selectedDate!)
                    : 'Select move-in date',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChips(bool isDark) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 12,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final months = index + 1;
          final selected = _durationMonths == months;
          return GestureDetector(
            onTap: () => setState(() => _durationMonths = months),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                        colors: [_primary, _primary.withOpacity(0.7)])
                    : null,
                color: selected
                    ? null
                    : (isDark ? const Color(0xFF1E1E38) : Colors.grey[50]),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected
                      ? Colors.transparent
                      : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _primary.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                '$months mo',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? Colors.white
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageField(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E38) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: TextFormField(
        controller: _messageController,
        maxLines: 3,
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          color: isDark ? Colors.white : Colors.black87,
        ),
        decoration: InputDecoration(
          hintText: 'Tell owner about yourself, requirements, etc...',
          hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  Widget _buildPriceSummary(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primary.withOpacity(isDark ? 0.18 : 0.08),
            _primary.withOpacity(isDark ? 0.08 : 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _primary.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.receipt_long_rounded, size: 16, color: _primary),
              const SizedBox(width: 6),
              Text(
                'Booking Summary',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _summaryRow('Monthly Rent',
              '₹${_estimatedMonthlyRent.toStringAsFixed(0)}', isDark),
          const SizedBox(height: 6),
          _summaryRow(
              'Duration',
              '$_durationMonths month${_durationMonths > 1 ? 's' : ''}',
              isDark),
          const SizedBox(height: 6),
          if (widget.property.securityDeposit != null)
            _summaryRow(
                'Security Deposit',
                '₹${widget.property.securityDeposit!.toStringAsFixed(0)}',
                isDark),
          const Divider(height: 20),
          _summaryRow(
            'Estimated Total',
            '₹${_estimatedTotal.toStringAsFixed(0)}',
            isDark,
            bold: true,
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, bool isDark,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: bold ? 13.5 : 12.5,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: bold ? 15 : 12.5,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: bold ? _primary : (isDark ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════
// REPORT DIALOG (unchanged)
// ══════════════════════════════════════════════════════════════
class ReportDialog extends StatefulWidget {
  final int propertyId;
  final VoidCallback onSuccess;

  const ReportDialog({
    super.key,
    required this.propertyId,
    required this.onSuccess,
  });

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _reasonController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? _selectedType;
  bool _isLoading = false;

  final List<String> _reportTypes = ['PROPERTY', 'OWNER', 'USER'];

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.pop(context);
    widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16213E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flag_rounded,
                          color: Colors.red, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Report Property',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  isExpanded: true,
                  items: _reportTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(
                        type,
                        style: GoogleFonts.poppins(
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedType = value),
                  decoration: InputDecoration(
                    labelText: 'Report Type',
                    labelStyle: GoogleFonts.poppins(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    prefixIcon: const Icon(Icons.category_outlined),
                    filled: true,
                    fillColor:
                        isDark ? const Color(0xFF1E1E38) : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  validator: (value) =>
                      value == null ? 'Please select a type' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'Reason',
                    labelStyle: GoogleFonts.poppins(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    prefixIcon: const Icon(Icons.title_rounded),
                    filled: true,
                    fillColor:
                        isDark ? const Color(0xFF1E1E38) : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Please enter a reason'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    labelStyle: GoogleFonts.poppins(
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                    prefixIcon: const Icon(Icons.description_outlined),
                    filled: true,
                    fillColor:
                        isDark ? const Color(0xFF1E1E38) : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.poppins(color: Colors.grey[600]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text(
                                'Submit',
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// IN-APP VIDEO PLAYER (unchanged)
// ══════════════════════════════════════════════════════════════
class InAppVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const InAppVideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<InAppVideoPlayerScreen> createState() => _InAppVideoPlayerScreenState();
}

class _InAppVideoPlayerScreenState extends State<InAppVideoPlayerScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  bool _showControls = true;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final uri = Uri.parse(widget.videoUrl);
      _controller = VideoPlayerController.networkUrl(uri);
      await _controller!.initialize();
      _controller!.addListener(() {
        if (mounted) setState(() {});
      });
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller!.play();
        _autoHideControls();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }

  void _autoHideControls() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _controller != null && _controller!.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _togglePlayPause() {
    if (_controller == null) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _showControls = true;
      } else {
        _controller!.play();
        _autoHideControls();
      }
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls && _controller != null && _controller!.value.isPlaying) {
      _autoHideControls();
    }
  }

  void _toggleFullscreen() {
    setState(() => _isFullscreen = !_isFullscreen);
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = d.inHours;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        top: !_isFullscreen,
        bottom: !_isFullscreen,
        child: Column(
          children: [
            if (!_isFullscreen)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Center(
                child: _buildPlayerBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerBody() {
    if (_hasError) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.white54, size: 48),
          const SizedBox(height: 12),
          Text(
            'Unable to play this video',
            style: GoogleFonts.poppins(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () {
              setState(() {
                _hasError = false;
                _isInitialized = false;
              });
              _initializePlayer();
            },
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    if (!_isInitialized || _controller == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Theme.of(context).primaryColor),
          const SizedBox(height: 12),
          Text(
            'Loading video...',
            style: GoogleFonts.poppins(color: Colors.white60, fontSize: 13),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio == 0
                ? 16 / 9
                : _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
          AnimatedOpacity(
            opacity: _showControls ? 1 : 0,
            duration: const Duration(milliseconds: 200),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.35),
                      Colors.transparent,
                      Colors.black.withOpacity(0.55),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: Icon(
                          _isFullscreen
                              ? Icons.fullscreen_exit
                              : Icons.fullscreen,
                          color: Colors.white,
                        ),
                        onPressed: _toggleFullscreen,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _controller!.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 38,
                        ),
                        onPressed: _togglePlayPause,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VideoProgressIndicator(
                            _controller!,
                            allowScrubbing: true,
                            padding: EdgeInsets.zero,
                            colors: VideoProgressColors(
                              playedColor: Theme.of(context).primaryColor,
                              bufferedColor: Colors.white24,
                              backgroundColor: Colors.white12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_controller!.value.position),
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                _formatDuration(_controller!.value.duration),
                                style: GoogleFonts.poppins(
                                  color: Colors.white70,
                                  fontSize: 11,
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
            ),
          ),
        ],
      ),
    );
  }
}