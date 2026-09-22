import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/property_model.dart';
import '../../providers/owner_provider.dart';

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
    'Basic Info',
    'Location',
    'Pricing',
    'Media',
    'Review',
  ];

  static const List<String> _propertyTypes = ['PG', 'HOSTEL', 'HOTEL', 'FLAT', 'ROOM'];
  static const List<String> _genders = ['BOYS', 'GIRLS', 'BOTH'];
  static const List<String> _allAmenities = [
    'WiFi', 'AC', 'Meals', 'Laundry', 'CCTV', 'Parking', 'Gym',
    'Hot Water', 'Power Backup', 'Security', 'TV', 'Fridge',
  ];

  // ================= STATE =================
  int _currentStep = 0;
  bool _loading = false;
  bool _uploadingMedia = false;
  bool _submitted = false;
  int? _createdPropertyId;

  // Controllers
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  final _rentMinCtrl = TextEditingController();
  final _rentMaxCtrl = TextEditingController();
  final _depositCtrl = TextEditingController();

  // Form values
  String _propertyType = '';
  String _genderAllowed = '';
  bool _isNegotiable = false;
  final List<String> _selectedAmenities = [];

  // Media
  final List<_MediaItem> _mediaFiles = [];
  final ImagePicker _picker = ImagePicker();

  // Errors
  final Map<String, String> _errors = {};

  bool get _isEdit => widget.property != null;

  late final AnimationController _fadeController;

  // ================= INIT =================
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
      _latCtrl.text = p.latitude?.toString() ?? '';
      _lngCtrl.text = p.longitude?.toString() ?? '';
      _rentMinCtrl.text = p.monthlyRentMin?.toStringAsFixed(0) ?? '';
      _rentMaxCtrl.text = p.monthlyRentMax?.toStringAsFixed(0) ?? '';
      _depositCtrl.text = p.securityDeposit?.toStringAsFixed(0) ?? '';
      _propertyType = p.propertyType;
      _genderAllowed = p.genderAllowed;
      _isNegotiable = p.isNegotiable;
      _selectedAmenities.addAll(p.amenities);
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
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _rentMinCtrl.dispose();
    _rentMaxCtrl.dispose();
    _depositCtrl.dispose();
    super.dispose();
  }

  // ================= VALIDATION =================
  bool _validateStep() {
    final errs = <String, String>{};

    if (_currentStep == 0) {
      if (_titleCtrl.text.trim().isEmpty) errs['title'] = 'Title is required';
      if (_propertyType.isEmpty) errs['propertyType'] = 'Property type is required';
      if (_genderAllowed.isEmpty) errs['genderAllowed'] = 'Gender is required';
    }
    if (_currentStep == 1) {
      if (_addressCtrl.text.trim().isEmpty) errs['address'] = 'Address is required';
      if (_cityCtrl.text.trim().isEmpty) errs['city'] = 'City is required';
      if (_stateCtrl.text.trim().isEmpty) errs['state'] = 'State is required';
      if (_pincodeCtrl.text.trim().isEmpty) errs['pincode'] = 'Pincode is required';
    }
    if (_currentStep == 2) {
      if (_rentMinCtrl.text.trim().isEmpty) errs['rentMin'] = 'Min rent required';
      if (_rentMaxCtrl.text.trim().isEmpty) errs['rentMax'] = 'Max rent required';
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

    // On Media step (index 3), submit property + upload media
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

  // ================= SUBMIT (uses YOUR OwnerProvider) =================
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
        if (_latCtrl.text.isNotEmpty) 'latitude': double.tryParse(_latCtrl.text),
        if (_lngCtrl.text.isNotEmpty) 'longitude': double.tryParse(_lngCtrl.text),
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
        // ---- EDIT MODE ----
        final ok = await ownerProvider.updateProperty(
          widget.property!.propertyId,
          body,
        );
        if (!ok) throw Exception(ownerProvider.error ?? 'Update failed');
        propertyId = widget.property!.propertyId;
      } else {
        // ---- ADD MODE ----
        final Property? created = await ownerProvider.addProperty(body);
        if (created == null) {
          throw Exception(ownerProvider.error ?? 'Failed to add property');
        }
        propertyId = created.propertyId;
      }

      _createdPropertyId = propertyId;

      // ---- Upload media (works in both modes) ----
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
          } catch (_) {
            // skip failed media, continue with others
          }
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

  // ================= MEDIA PICKERS =================
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
        backgroundColor:
            isError ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _clearError(String key) {
    if (_errors.containsKey(key)) {
      setState(() => _errors.remove(key));
    }
  }

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
        backgroundColor:
            isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF7F8FC),
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(isDark),
              _buildStepIndicator(isDark),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeController,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
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
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                    fontSize: 20,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                Text(
                  'Step ${_currentStep + 1} of ${_steps.length}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : const Color(0xFF8A8FA3),
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
          color: isDark ? const Color(0xFF1A1F33) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : const Color(0xFFE8E8F0),
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
      ),
    );
  }

  // ---------- STEP INDICATOR ----------
  Widget _buildStepIndicator(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121729) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        child: Container(
                          height: 2,
                          color: i <= _currentStep
                              ? const Color(0xFF22C55E)
                              : (isDark
                                  ? Colors.white12
                                  : const Color(0xFFEDEDF5)),
                        ),
                      ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: isActive
                            ? const LinearGradient(
                                colors: [
                                  Color(0xFF7C3AED),
                                  Color(0xFF4ECDC4)
                                ],
                              )
                            : null,
                        color: isDone
                            ? const Color(0xFF22C55E)
                            : (isActive
                                ? null
                                : (isDark
                                    ? const Color(0xFF1E2540)
                                    : const Color(0xFFF0F0F5))),
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF7C3AED)
                                      .withOpacity(0.4),
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
                                size: 16,
                                color: Colors.white,
                              )
                            : Text(
                                '${i + 1}',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: isActive
                                      ? Colors.white
                                      : (isDark
                                          ? Colors.white38
                                          : const Color(0xFF8A8FA3)),
                                ),
                              ),
                      ),
                    ),
                    if (i < _steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: i < _currentStep
                              ? const Color(0xFF22C55E)
                              : (isDark
                                  ? Colors.white12
                                  : const Color(0xFFEDEDF5)),
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
                        ? const Color(0xFF7C3AED)
                        : (isDone
                            ? const Color(0xFF22C55E)
                            : (isDark
                                ? Colors.white38
                                : const Color(0xFF8A8FA3))),
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
            const SizedBox(height: 8),
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
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF7C3AED).withOpacity(0.12)
                          : (isDark
                              ? const Color(0xFF1A1F33)
                              : Colors.white),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF7C3AED)
                            : (isDark
                                ? Colors.white12
                                : const Color(0xFFE8E8F0)),
                        width: 1.6,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected) ...[
                          const Icon(
                            Icons.check_rounded,
                            size: 13,
                            color: Color(0xFF7C3AED),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          a,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: selected
                                ? const Color(0xFF7C3AED)
                                : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF666666)),
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

  // ============ STEP 1: LOCATION ============
  Widget _buildStepLocation(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionCard(
          isDark: isDark,
          children: [
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
        const SizedBox(height: 14),
        _sectionCard(
          isDark: isDark,
          children: [
            _label('Coordinates (Optional)', isDark: isDark),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _textField(
                    controller: _latCtrl,
                    hint: 'Latitude',
                    isDark: isDark,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _textField(
                    controller: _lngCtrl,
                    hint: 'Longitude',
                    isDark: isDark,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: const Color(0xFF7C3AED).withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: Color(0xFF7C3AED),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Add coordinates for location-based search results',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF7C3AED),
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
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF121729) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: _isNegotiable
                    ? const Color(0xFF7C3AED)
                    : (isDark ? Colors.white12 : const Color(0xFFE8E8F0)),
                width: 1.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
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
                    color: _isNegotiable
                        ? const Color(0xFF7C3AED)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isNegotiable
                          ? const Color(0xFF7C3AED)
                          : (isDark
                              ? Colors.white24
                              : const Color(0xFFCCCCDD)),
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
                          color:
                              isDark ? Colors.white : const Color(0xFF1A1A2E),
                        ),
                      ),
                      Text(
                        'Students will see "Negotiable" badge on your listing',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: isDark
                              ? Colors.white54
                              : const Color(0xFF8A8FA3),
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
            Text(
              'Photos & Videos',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Upload property photos and videos (max 30 sec). First photo will be the cover.',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark ? Colors.white54 : const Color(0xFF8A8FA3),
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
              Text(
                '${_mediaFiles.length} file${_mediaFiles.length != 1 ? 's' : ''} selected',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF666680),
                ),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _mediaFiles.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                                colors: [
                                  Color(0xFF7C3AED),
                                  Color(0xFF4ECDC4)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              'Cover',
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
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
          color: isDark ? const Color(0xFF1A1F33) : const Color(0xFFF5F3FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF7C3AED).withOpacity(0.25),
            width: 1.6,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF7C3AED), size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7C3AED),
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
                colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF22C55E).withOpacity(0.35),
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
            _isEdit ? 'Property Updated! ✅' : 'Property Submitted! 🎉',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
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
                fontSize: 13.5,
                color: isDark ? Colors.white60 : const Color(0xFF8A8FA3),
                height: 1.6,
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
                  _latCtrl.clear();
                  _lngCtrl.clear();
                  _rentMinCtrl.clear();
                  _rentMaxCtrl.clear();
                  _depositCtrl.clear();
                  _propertyType = '';
                  _genderAllowed = '';
                  _isNegotiable = false;
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
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F1320) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
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
                      ? 'Submitting...'
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

  // ---------- REUSABLE WIDGETS ----------
  Widget _sectionCard({required bool isDark, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121729) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : const Color(0xFFF0F0F8),
        ),
      ),
      child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _label(String text, {bool required = false, required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          text: text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
          children: [
            if (required)
              TextSpan(
                text: ' *',
                style: GoogleFonts.poppins(color: const Color(0xFFEF4444)),
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
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.white38 : const Color(0xFFB0B3C0),
            ),
            filled: true,
            fillColor: isDark ? const Color(0xFF1A1F33) : const Color(0xFFF8F9FC),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: error != null
                    ? const Color(0xFFEF4444)
                    : (isDark ? Colors.white12 : const Color(0xFFE8E8F0)),
                width: error != null ? 1.8 : 1.4,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: error != null
                    ? const Color(0xFFEF4444)
                    : (isDark ? Colors.white12 : const Color(0xFFE8E8F0)),
                width: error != null ? 1.8 : 1.4,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color:
                    error != null ? const Color(0xFFEF4444) : const Color(0xFF7C3AED),
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
        style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFFEF4444)),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSel
                  ? const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF9F7AEA)],
                    )
                  : null,
              color: isSel
                  ? null
                  : (isDark ? const Color(0xFF1A1F33) : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSel
                    ? Colors.transparent
                    : (isDark ? Colors.white12 : const Color(0xFFE8E8F0)),
                width: 1.4,
              ),
              boxShadow: isSel
                  ? [
                      BoxShadow(
                        color: const Color(0xFF7C3AED).withOpacity(0.3),
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
                color: isSel
                    ? Colors.white
                    : (isDark ? Colors.white70 : const Color(0xFF666680)),
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 52,
        decoration: BoxDecoration(
          gradient: onTap == null
              ? const LinearGradient(
                  colors: [Color(0xFFBBBBBB), Color(0xFFCCCCCC)])
              : const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF4ECDC4)],
                ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: onTap == null
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
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
                        fontSize: 14.5,
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
          color: isDark ? const Color(0xFF1A1F33) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE8E8F0),
            width: 1.4,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isDark ? Colors.white70 : const Color(0xFF666680),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white70 : const Color(0xFF666680),
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