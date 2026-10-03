import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/property_model.dart';
import '../../providers/owner_provider.dart';
import '../../utils/constants.dart';

// ══════════════════════════════════════════════════════════════
// DESIGN TOKENS — Blue premium
// ══════════════════════════════════════════════════════════════
class _C {
  static const accent = Color(0xFF2563EB);
  static const accentDark = Color(0xFF1D4ED8);
  static const accentLight = Color(0xFF3B82F6);
  static const accentSoft = Color(0xFFEBF1FF);

  static const success = Color(0xFF10B981);
  static const successLight = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  static const purple = Color(0xFF8B5CF6);
  static const teal = Color(0xFF14B8A6);

  static const darkBg = Color(0xFF0B1020);
  static const darkSurface = Color(0xFF131A2E);
  static const darkSurfaceAlt = Color(0xFF1C2540);

  static const lightBg = Color(0xFFF6F8FC);
  static const lightBorder = Color(0xFFE5EAF3);
  static const lightText = Color(0xFF0F172A);
  static const lightTextSec = Color(0xFF64748B);
  static const lightTextTer = Color(0xFF94A3B8);

  static Color bg(bool d) => d ? darkBg : lightBg;
  static Color surface(bool d) => d ? darkSurface : Colors.white;
  static Color surfaceAlt(bool d) => d ? darkSurfaceAlt : const Color(0xFFF1F4FA);
  static Color border(bool d) => d ? Colors.white.withOpacity(0.07) : lightBorder;
  static Color text(bool d) => d ? Colors.white : lightText;
  static Color textSec(bool d) => d ? Colors.white60 : lightTextSec;
  static Color textTer(bool d) => d ? Colors.white38 : lightTextTer;
  static Color accentSoftBg(bool d) => d ? accent.withOpacity(0.15) : accentSoft;
}

class AddEditPropertyPage extends StatefulWidget {
  final Property? property;
  const AddEditPropertyPage({super.key, this.property});

  @override
  State<AddEditPropertyPage> createState() => _AddEditPropertyPageState();
}

class _AddEditPropertyPageState extends State<AddEditPropertyPage>
    with TickerProviderStateMixin {
  // ================= STEPS =================
  static const List<String> _steps = [
    'Basic',
    'Location',
    'Pricing',
    'Media',
    'Done',
  ];

  static const List<String> _propertyTypes = [
    'PG',
    'HOSTEL',
    'HOTEL',
    'FLAT',
    'ROOM'
  ];
  static const List<String> _genders = ['BOYS', 'GIRLS', 'BOTH'];
  static const List<String> _allAmenities = [
    'WiFi',
    'AC',
    'Meals',
    'Laundry',
    'CCTV',
    'Parking',
    'Gym',
    'Hot Water',
    'Power Backup',
    'Security',
    'TV',
    'Fridge',
  ];

  // ================= STATE =================
  int _currentStep = 0;
  bool _loading = false;
  bool _uploadingMedia = false;
  bool _submitted = false;
  int? _createdPropertyId;

  // 🆕 Location state
  bool _fetchingLocation = false;
  bool _locationCaptured = false;
  double? _capturedLat;
  double? _capturedLng;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _rentMinCtrl = TextEditingController();
  final _rentMaxCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();

  String _propertyType = '';
  String _genderAllowed = '';
  bool _isNegotiable = false;
  final List<String> _selectedAmenities = [];

  final List<_MediaItem> _mediaFiles = [];
  final ImagePicker _picker = ImagePicker();

  final Map<String, String> _errors = {};

  bool get _isEdit => widget.property != null;

  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    )..forward();

    if (_isEdit) {
      final p = widget.property!;
      _titleCtrl.text = p.title;
      _descCtrl.text = p.description ?? '';
      _addressCtrl.text = p.addressLine;
      _cityCtrl.text = p.city;
      _stateCtrl.text = p.state;
      _pincodeCtrl.text = p.pincode;
      _rentMinCtrl.text = p.monthlyRentMin?.toStringAsFixed(0) ?? '';
      _rentMaxCtrl.text = p.monthlyRentMax?.toStringAsFixed(0) ?? '';
      _depositCtrl.text = p.securityDeposit?.toStringAsFixed(0) ?? '';
      _propertyType = p.propertyType;
      _genderAllowed = p.genderAllowed;
      _isNegotiable = p.isNegotiable;
      _selectedAmenities.addAll(p.amenities);

      // Existing property ki location
      if (p.latitude != null && p.longitude != null) {
        _capturedLat = p.latitude;
        _capturedLng = p.longitude;
        _locationCaptured = true;
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _rentMinCtrl.dispose();
    _rentMaxCtrl.dispose();
    _depositCtrl.dispose();
    super.dispose();
  }

  // ================= LOCATION =================
  Future<void> _fetchCurrentLocation() async {
    setState(() => _fetchingLocation = true);

    try {
      // 1. Location service check
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('GPS is disabled. Please enable location services.');
      }

      // 2. Permission check
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
            'Location permission permanently denied. Please enable from Settings.');
      }

      // 3. Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      // 4. Reverse geocode
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      String addressLine = '';
      String city = '';
      String state = '';
      String pincode = '';

      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        addressLine = [
          p.street,
          p.subLocality,
          p.locality,
        ].where((e) => e != null && e.trim().isNotEmpty).join(', ');
        city = p.locality ?? p.subAdministrativeArea ?? '';
        state = p.administrativeArea ?? '';
        pincode = p.postalCode ?? '';
      }

      setState(() {
        _capturedLat = position.latitude;
        _capturedLng = position.longitude;
        _locationCaptured = true;

        // Auto-fill only if fields are empty
        if (_addressCtrl.text.trim().isEmpty && addressLine.isNotEmpty) {
          _addressCtrl.text = addressLine;
        }
        if (_cityCtrl.text.trim().isEmpty && city.isNotEmpty) {
          _cityCtrl.text = city;
        }
        if (_stateCtrl.text.trim().isEmpty && state.isNotEmpty) {
          _stateCtrl.text = state;
        }
        if (_pincodeCtrl.text.trim().isEmpty && pincode.isNotEmpty) {
          _pincodeCtrl.text = pincode;
        }
      });

      _showSnackBar('✅ Location captured — verify address below');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  void _clearLocation() {
    setState(() {
      _locationCaptured = false;
      _capturedLat = null;
      _capturedLng = null;
    });
  }

  // ================= VALIDATION =================
  bool _validateStep() {
    final errs = <String, String>{};

    if (_currentStep == 0) {
      if (_titleCtrl.text.trim().isEmpty) errs['title'] = 'Title is required';
      if (_propertyType.isEmpty) {
        errs['propertyType'] = 'Property type is required';
      }
      if (_genderAllowed.isEmpty) {
        errs['genderAllowed'] = 'Gender is required';
      }
    }
    if (_currentStep == 1) {
      if (_addressCtrl.text.trim().isEmpty) {
        errs['address'] = 'Address is required';
      }
      if (_cityCtrl.text.trim().isEmpty) errs['city'] = 'City is required';
      if (_stateCtrl.text.trim().isEmpty) errs['state'] = 'State is required';
      if (_pincodeCtrl.text.trim().isEmpty) {
        errs['pincode'] = 'Pincode is required';
      }
    }
    if (_currentStep == 2) {
      if (_rentMinCtrl.text.trim().isEmpty) {
        errs['rentMin'] = 'Min rent required';
      }
      if (_rentMaxCtrl.text.trim().isEmpty) {
        errs['rentMax'] = 'Max rent required';
      }
    }

    setState(() {
      _errors.clear();
      _errors.addAll(errs);
    });
    return errs.isEmpty;
  }

  // ================= NAVIGATION =================
  Future<void> _handleNext() async {
    if (!_validateStep()) return;

    if (_currentStep == 3) {
      await _submitAll();
      return;
    }

    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
      _fadeController.forward(from: 0);
    }
  }

  void _handleBack() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _fadeController.forward(from: 0);
    } else {
      Navigator.pop(context);
    }
  }

  // ================= SUBMIT =================
  Future<void> _submitAll() async {
    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);

    setState(() => _loading = true);

    try {
      final body = <String, dynamic>{
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'propertyType': _propertyType,
        'genderAllowed': _genderAllowed,
        'amenities': _selectedAmenities,
        'addressLine': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'pincode': _pincodeCtrl.text.trim(),
        if (_capturedLat != null) 'latitude': _capturedLat,
        if (_capturedLng != null) 'longitude': _capturedLng,
        if (_rentMinCtrl.text.isNotEmpty)
          'monthlyRentMin': double.tryParse(_rentMinCtrl.text),
        if (_rentMaxCtrl.text.isNotEmpty)
          'monthlyRentMax': double.tryParse(_rentMaxCtrl.text),
        if (_depositCtrl.text.isNotEmpty)
          'securityDeposit': double.tryParse(_depositCtrl.text),
        'isNegotiable': _isNegotiable,
      };

      int? propertyId;

      if (_isEdit) {
        final ok = await ownerProvider.updateProperty(
          widget.property!.propertyId,
          body,
        );
        if (!ok) throw Exception(ownerProvider.error ?? 'Update failed');
        propertyId = widget.property!.propertyId;
      } else {
        final Property? created = await ownerProvider.addProperty(body);
        if (created == null) {
          throw Exception(ownerProvider.error ?? 'Failed to add property');
        }
        propertyId = created.propertyId;
      }

      _createdPropertyId = propertyId;

      if (_mediaFiles.isNotEmpty && propertyId != null) {
        setState(() => _uploadingMedia = true);

        for (int i = 0; i < _mediaFiles.length; i++) {
          final m = _mediaFiles[i];
          try {
            await ownerProvider.uploadPropertyMedia(
              propertyId,
              m.file,
              mediaType: m.isVideo ? 'VIDEO' : 'IMAGE',
              isPrimary: i == 0,
            );
          } catch (_) {}
        }

        setState(() => _uploadingMedia = false);
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
        _submitted = true;
        _currentStep = 4;
      });

      _fadeController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _showSnackBar(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  // ================= MEDIA =================
  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 80);
    if (picked.isEmpty) return;
    setState(() {
      for (final x in picked) {
        _mediaFiles.add(_MediaItem(file: File(x.path), isVideo: false));
      }
    });
  }

  Future<void> _pickVideo() async {
    final picked = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30),
    );
    if (picked == null) return;
    setState(() {
      _mediaFiles.add(_MediaItem(file: File(picked.path), isVideo: true));
    });
  }

  void _removeMedia(int index) {
    setState(() => _mediaFiles.removeAt(index));
  }

  // ================= HELPERS =================
  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontSize: 13)),
        backgroundColor: isError ? _C.danger : _C.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _clearError(String key) {
    if (_errors.containsKey(key)) {
      setState(() => _errors.remove(key));
    }
  }

  double _bottomPad(BuildContext ctx) => MediaQuery.of(ctx).padding.bottom;

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: _currentStep == 0 && !_loading && !_uploadingMedia,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_loading && !_uploadingMedia) _handleBack();
      },
      child: Scaffold(
        backgroundColor: _C.bg(isDark),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(isDark),
              _buildStepIndicator(isDark),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeController,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    child: _buildStepContent(isDark),
                  ),
                ),
              ),
              if (_currentStep < 4) _buildBottomNav(isDark),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- HEADER ----------
  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          _iconButton(
            icon: Icons.arrow_back_rounded,
            onTap: _handleBack,
            isDark: isDark,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEdit ? 'Edit Property' : 'Add New Property',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                    letterSpacing: -0.3,
                    color: _C.text(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Step ${_currentStep + 1} of ${_steps.length} • ${_steps[_currentStep]}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: _C.textSec(isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _C.surface(isDark),
          shape: BoxShape.circle,
          border: Border.all(color: _C.border(isDark)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.20 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: _C.text(isDark)),
      ),
    );
  }

  // ---------- STEP INDICATOR ----------
  Widget _buildStepIndicator(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: _C.surface(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.20 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_steps.length, (i) {
          final isActive = i == _currentStep;
          final isDone = i < _currentStep;

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (i > 0)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 2,
                          color: i <= _currentStep
                              ? _C.accent
                              : _C.border(isDark),
                        ),
                      ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isActive
                            ? const LinearGradient(
                                colors: [_C.accent, _C.accentLight],
                              )
                            : null,
                        color: isDone
                            ? _C.accent
                            : (isActive
                                ? null
                                : (isDark
                                    ? const Color(0xFF1E2540)
                                    : const Color(0xFFF0F1F6))),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: _C.accent.withOpacity(0.40),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(
                                Icons.check_rounded,
                                size: 15,
                                color: Colors.white,
                              )
                            : Text(
                                '${i + 1}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: isActive
                                      ? Colors.white
                                      : _C.textTer(isDark),
                                ),
                              ),
                      ),
                    ),
                    if (i < _steps.length - 1)
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 2,
                          color: i < _currentStep
                              ? _C.accent
                              : _C.border(isDark),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _steps[i],
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? _C.accent
                        : (isDone ? _C.accent : _C.textTer(isDark)),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ---------- STEP CONTENT ----------
  Widget _buildStepContent(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildStepBasic(isDark);
      case 1:
        return _buildStepLocation(isDark);
      case 2:
        return _buildStepPricing(isDark);
      case 3:
        return _buildStepMedia(isDark);
      default:
        return _buildStepSuccess(isDark);
    }
  }

  // ============ STEP 0: BASIC ============
  Widget _buildStepBasic(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          isDark: isDark,
          children: [
            _label('Property Title', required: true, isDark: isDark),
            _textField(
              controller: _titleCtrl,
              hint: 'e.g. Rahman Boys PG — Sector 62 Noida',
              isDark: isDark,
              error: _errors['title'],
              onChanged: (_) => _clearError('title'),
            ),
            const SizedBox(height: 16),
            _label('Description', isDark: isDark),
            _textField(
              controller: _descCtrl,
              hint: 'Describe your property — location, nearby landmarks...',
              isDark: isDark,
              maxLines: 4,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _sectionCard(
          isDark: isDark,
          children: [
            _label('Property Type', required: true, isDark: isDark),
            _chipRow(
              items: _propertyTypes,
              selected: _propertyType,
              onSelect: (v) {
                setState(() => _propertyType = v);
                _clearError('propertyType');
              },
              isDark: isDark,
            ),
            if (_errors['propertyType'] != null)
              _errorText(_errors['propertyType']!),
            const SizedBox(height: 16),
            _label('Gender Allowed', required: true, isDark: isDark),
            _chipRow(
              items: _genders,
              selected: _genderAllowed,
              onSelect: (v) {
                setState(() => _genderAllowed = v);
                _clearError('genderAllowed');
              },
              isDark: isDark,
            ),
            if (_errors['genderAllowed'] != null)
              _errorText(_errors['genderAllowed']!),
            const SizedBox(height: 16),
            _label('Amenities', isDark: isDark),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allAmenities.map((a) {
                final selected = _selectedAmenities.contains(a);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (selected) {
                      _selectedAmenities.remove(a);
                    } else {
                      _selectedAmenities.add(a);
                    }
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: selected
                          ? _C.accentSoftBg(isDark)
                          : _C.surfaceAlt(isDark),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: selected
                            ? _C.accent
                            : _C.border(isDark),
                        width: 1.4,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected) ...[
                          const Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: _C.accent,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          a,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? _C.accent
                                : _C.textSec(isDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ],
    );
  }

  // ============ STEP 1: LOCATION (UPDATED) ============
  Widget _buildStepLocation(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ⭐ Auto-detect location card
        _sectionCard(
          isDark: isDark,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_C.accent, _C.accentLight],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-detect Location',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: _C.text(isDark),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Stand at your property & tap below',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: _C.textSec(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _gradientButton(
              label: _fetchingLocation
                  ? 'Getting location…'
                  : (_locationCaptured
                      ? 'Refresh Location'
                      : 'Use My Current Location'),
              icon: Icons.gps_fixed_rounded,
              loading: _fetchingLocation,
              onTap: _fetchingLocation ? null : _fetchCurrentLocation,
            ),
            if (_locationCaptured) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _C.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _C.success.withOpacity(0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: _C.success,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Location captured',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _C.success,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _clearLocation,
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: _C.success.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),

        // Address fields
        _sectionCard(
          isDark: isDark,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.home_rounded,
                  size: 16,
                  color: _C.accent,
                ),
                const SizedBox(width: 6),
                Text(
                  'Address Details',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: _C.text(isDark),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(auto-filled, editable)',
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                    color: _C.textTer(isDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _label('Address Line', required: true, isDark: isDark),
            _textField(
              controller: _addressCtrl,
              hint: 'House No, Street, Area',
              isDark: isDark,
              error: _errors['address'],
              onChanged: (_) => _clearError('address'),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('City', required: true, isDark: isDark),
                      _textField(
                        controller: _cityCtrl,
                        hint: 'e.g. Noida',
                        isDark: isDark,
                        error: _errors['city'],
                        onChanged: (_) => _clearError('city'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('State', required: true, isDark: isDark),
                      _textField(
                        controller: _stateCtrl,
                        hint: 'e.g. UP',
                        isDark: isDark,
                        error: _errors['state'],
                        onChanged: (_) => _clearError('state'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _label('Pincode', required: true, isDark: isDark),
            _textField(
              controller: _pincodeCtrl,
              hint: 'e.g. 201309',
              isDark: isDark,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              error: _errors['pincode'],
              onChanged: (_) => _clearError('pincode'),
            ),
          ],
        ),

        // Map preview
        if (_locationCaptured && _capturedLat != null && _capturedLng != null) ...[
          const SizedBox(height: 14),
          _sectionCard(
            isDark: isDark,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.map_rounded,
                    size: 16,
                    color: _C.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Verify Location on Map',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: _C.text(isDark),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Lat: ${_capturedLat!.toStringAsFixed(6)}, Lng: ${_capturedLng!.toStringAsFixed(6)}',
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  color: _C.textTer(isDark),
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: _C.surfaceAlt(isDark),
                  child: Image.network(
                    'https://maps.googleapis.com/maps/api/staticmap?'
                    'center=$_capturedLat,$_capturedLng&'
                    'zoom=16&size=600x300&'
                    'markers=color:red%7C$_capturedLat,$_capturedLng&'
                    'key=${AppConstants.googleMapsApiKey}',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 40,
                            color: _C.accent,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Map preview unavailable',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              color: _C.textSec(isDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: _C.accentSoftBg(isDark),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: _C.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Make sure the pin is at your property location',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: _C.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ============ STEP 2: PRICING ============
  Widget _buildStepPricing(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          isDark: isDark,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Min Rent (₹)', required: true, isDark: isDark),
                      _textField(
                        controller: _rentMinCtrl,
                        hint: '5000',
                        isDark: isDark,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        error: _errors['rentMin'],
                        onChanged: (_) => _clearError('rentMin'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Max Rent (₹)', required: true, isDark: isDark),
                      _textField(
                        controller: _rentMaxCtrl,
                        hint: '8000',
                        isDark: isDark,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        error: _errors['rentMax'],
                        onChanged: (_) => _clearError('rentMax'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _label('Security Deposit (₹)', isDark: isDark),
            _textField(
              controller: _depositCtrl,
              hint: '10000',
              isDark: isDark,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => setState(() => _isNegotiable = !_isNegotiable),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _isNegotiable
                  ? _C.accentSoftBg(isDark)
                  : _C.surface(isDark),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isNegotiable
                    ? _C.accent
                    : _C.border(isDark),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.20 : 0.04),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _isNegotiable ? _C.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isNegotiable
                          ? _C.accent
                          : _C.textTer(isDark),
                      width: 2,
                    ),
                  ),
                  child: _isNegotiable
                      ? const Icon(
                          Icons.check_rounded,
                          size: 15,
                          color: Colors.white,
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rent is Negotiable',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _C.text(isDark),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Students will see "Negotiable" badge on your listing',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: _C.textSec(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============ STEP 3: MEDIA ============
  Widget _buildStepMedia(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          isDark: isDark,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: _C.accentSoftBg(isDark),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      size: 14, color: _C.accent),
                ),
                const SizedBox(width: 8),
                Text(
                  'Photos & Videos',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _C.text(isDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Upload property photos and videos (max 30 sec). First photo will be the cover.',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: _C.textSec(isDark),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _uploadTile(
                    icon: Icons.image_rounded,
                    title: 'Add Photos',
                    isDark: isDark,
                    onTap: _pickImages,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _uploadTile(
                    icon: Icons.videocam_rounded,
                    title: 'Add Video',
                    isDark: isDark,
                    onTap: _pickVideo,
                  ),
                ),
              ],
            ),
            if (_mediaFiles.isNotEmpty) ...[
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    '${_mediaFiles.length} file${_mediaFiles.length != 1 ? 's' : ''}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _C.text(isDark),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _C.accentSoftBg(isDark),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'First = Cover',
                      style: GoogleFonts.poppins(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: _C.accent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _mediaFiles.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, i) {
                  final m = _mediaFiles[i];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: m.isVideo
                            ? Container(
                                color: Colors.black,
                                child: const Center(
                                  child: Icon(
                                    Icons.play_circle_fill_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              )
                            : Image.file(
                                m.file,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                      ),
                      if (i == 0)
                        Positioned(
                          left: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_C.accent, _C.accentLight],
                              ),
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: _C.accent.withOpacity(0.40),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              'COVER',
                              style: GoogleFonts.poppins(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: GestureDetector(
                          onTap: () => _removeMedia(i),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.65),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _uploadTile({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 22),
        decoration: BoxDecoration(
          color: _C.accentSoftBg(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _C.accent.withOpacity(0.25),
            width: 1.6,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _C.accent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _C.accent, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: _C.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============ STEP 4: SUCCESS ============
  Widget _buildStepSuccess(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [_C.successLight, _C.success],
              ),
              boxShadow: [
                BoxShadow(
                  color: _C.success.withOpacity(0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 52,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            _isEdit ? 'Property Updated!' : 'Property Submitted!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              letterSpacing: -0.5,
              color: _C.text(isDark),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _isEdit
                  ? 'Your property details have been updated successfully.'
                  : 'Your property has been submitted for review. Admin will verify and publish it within 24 hours.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: _C.textSec(isDark),
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _gradientButton(
            label: 'View My Properties',
            icon: Icons.home_rounded,
            onTap: () => Navigator.pop(context, true),
          ),
          const SizedBox(height: 12),
          if (!_isEdit)
            _outlinedButton(
              label: 'Add Another',
              icon: Icons.add_rounded,
              isDark: isDark,
              onTap: () {
                setState(() {
                  _submitted = false;
                  _currentStep = 0;
                  _createdPropertyId = null;
                  _mediaFiles.clear();
                  _selectedAmenities.clear();
                  _titleCtrl.clear();
                  _descCtrl.clear();
                  _addressCtrl.clear();
                  _cityCtrl.clear();
                  _stateCtrl.clear();
                  _pincodeCtrl.clear();
                  _rentMinCtrl.clear();
                  _rentMaxCtrl.clear();
                  _depositCtrl.clear();
                  _propertyType = '';
                  _genderAllowed = '';
                  _isNegotiable = false;
                  _locationCaptured = false;
                  _capturedLat = null;
                  _capturedLng = null;
                });
                _fadeController.forward(from: 0);
              },
            ),
        ],
      ),
    );
  }

  // ---------- BOTTOM NAV ----------
  Widget _buildBottomNav(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + _bottomPad(context),
      ),
      decoration: BoxDecoration(
        color: _C.surface(isDark),
        border: Border(
          top: BorderSide(color: _C.border(isDark), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.30 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: _outlinedButton(
              label: 'Back',
              icon: Icons.arrow_back_rounded,
              isDark: isDark,
              onTap: _loading || _uploadingMedia ? () {} : _handleBack,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _gradientButton(
              label: _currentStep == 3
                  ? (_loading || _uploadingMedia
                      ? 'Submitting…'
                      : (_isEdit ? 'Update Property' : 'Submit Property'))
                  : 'Next',
              icon: _currentStep == 3
                  ? Icons.check_rounded
                  : Icons.arrow_forward_rounded,
              loading: _loading || _uploadingMedia,
              onTap: _loading || _uploadingMedia ? null : _handleNext,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- REUSABLE ----------
  Widget _sectionCard({
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _C.surface(isDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.border(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.20 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _label(String text, {bool required = false, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: text,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: _C.text(isDark),
          ),
          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: GoogleFonts.poppins(color: _C.danger),
              ),
          ],
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? error,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          cursorColor: _C.accent,
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            color: _C.text(isDark),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 12.5,
              color: _C.textTer(isDark),
            ),
            filled: true,
            fillColor: _C.surfaceAlt(isDark),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: error != null ? _C.danger : _C.border(isDark),
                width: error != null ? 1.8 : 1.4,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: error != null ? _C.danger : _C.border(isDark),
                width: error != null ? 1.8 : 1.4,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: error != null ? _C.danger : _C.accent,
                width: 1.8,
              ),
            ),
          ),
        ),
        if (error != null) _errorText(error),
      ],
    );
  }

  Widget _errorText(String msg) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 4),
      child: Text(
        msg,
        style: GoogleFonts.poppins(fontSize: 11, color: _C.danger),
      ),
    );
  }

  Widget _chipRow({
    required List<String> items,
    required String selected,
    required ValueChanged<String> onSelect,
    required bool isDark,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSel = item == selected;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSel
                  ? const LinearGradient(
                      colors: [_C.accent, _C.accentLight],
                    )
                  : null,
              color: isSel ? null : _C.surfaceAlt(isDark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSel ? Colors.transparent : _C.border(isDark),
                width: 1.4,
              ),
              boxShadow: isSel
                  ? [
                      BoxShadow(
                        color: _C.accent.withOpacity(0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              item,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isSel ? Colors.white : _C.textSec(isDark),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _gradientButton({
    required String label,
    required IconData icon,
    VoidCallback? onTap,
    bool loading = false,
  }) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 52,
        decoration: BoxDecoration(
          gradient: disabled
              ? const LinearGradient(
                  colors: [Color(0xFFBBBBBB), Color(0xFFCCCCCC)])
              : const LinearGradient(
                  colors: [_C.accent, _C.accentLight],
                ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: disabled
              ? null
              : [
                  BoxShadow(
                    color: _C.accent.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.4,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(icon, color: Colors.white, size: 18),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _outlinedButton({
    required String label,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: _C.surface(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.border(isDark), width: 1.4),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: _C.textSec(isDark)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                  color: _C.textSec(isDark),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================= MEDIA ITEM =================
class _MediaItem {
  final File file;
  final bool isVideo;
  _MediaItem({required this.file, required this.isVideo});
}