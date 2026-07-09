// lib/screens/owner/owner_reels_upload_screen.dart

// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:yourhome/providers/reel_provider.dart';
import 'package:yourhome/providers/property_provider.dart';
import 'package:yourhome/models/property_model.dart';

class OwnerReelsUploadScreen extends StatefulWidget {
  const OwnerReelsUploadScreen({super.key});

  @override
  State<OwnerReelsUploadScreen> createState() =>
      _OwnerReelsUploadScreenState();
}

class _OwnerReelsUploadScreenState extends State<OwnerReelsUploadScreen>
    with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _propertySearchController =
      TextEditingController();

  // State Variables
  File? _videoFile;
  String? _videoThumbnail;
  int? _selectedPropertyId;
  String? _selectedPropertyTitle;
  double _uploadProgress = 0.0;
  bool _isUploading = false;
  bool _isProcessing = false;
  bool _isPropertyDropdownOpen = false;
  List<Property> _filteredProperties = [];

  // Animation Controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _progressController;
  late AnimationController _mainController;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;
  late Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadProperties();
  }

  void _setupAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeInOutCubic),
    );

    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutCubic),
    );

    _scaleIn = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _mainController, curve: Curves.easeOutBack),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _mainController.forward();
  }

  Future<void> _loadProperties() async {
    final propertyProvider =
        Provider.of<PropertyProvider>(context, listen: false);
    if (propertyProvider.properties.isEmpty) {
      await propertyProvider.searchProperties();
    }
    setState(() {
      _filteredProperties = propertyProvider.properties;
    });
  }

  @override
  void dispose() {
    _captionController.dispose();
    _propertySearchController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _mainController.dispose();
    super.dispose();
  }

  // ========== PICK VIDEO ==========
  Future<void> _pickVideo() async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );

      if (video != null) {
        setState(() {
          _isProcessing = true;
        });

        final compressed = await VideoCompress.compressVideo(
          video.path,
          quality: VideoQuality.DefaultQuality,
          deleteOrigin: false,
        );

        if (compressed != null && compressed.file != null) {
          setState(() {
            _videoFile = compressed.file;
            _videoThumbnail = compressed.file!.path;
            _isProcessing = false;
          });

          _showSnackBar('Video selected successfully! 🎬', Colors.green);
        } else {
          setState(() {
            _isProcessing = false;
          });
          _showSnackBar('Failed to compress video', Colors.red);
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showSnackBar('Failed to pick video: $e', Colors.red);
    }
  }

  // ========== RECORD VIDEO ==========
  Future<void> _recordVideo() async {
    try {
      final picker = ImagePicker();
      final video = await picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(seconds: 30),
      );

      if (video != null) {
        setState(() {
          _isProcessing = true;
        });

        final compressed = await VideoCompress.compressVideo(
          video.path,
          quality: VideoQuality.DefaultQuality,
          deleteOrigin: false,
        );

        if (compressed != null && compressed.file != null) {
          setState(() {
            _videoFile = compressed.file;
            _videoThumbnail = compressed.file!.path;
            _isProcessing = false;
          });

          _showSnackBar('Video recorded successfully! 🎬', Colors.green);
        } else {
          setState(() {
            _isProcessing = false;
          });
          _showSnackBar('Failed to compress video', Colors.red);
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      _showSnackBar('Failed to record video: $e', Colors.red);
    }
  }

  // ========== UPLOAD REEL ==========
  Future<void> _uploadReel() async {
    if (_videoFile == null) {
      _showSnackBar('Please select a video', Colors.red);
      return;
    }

    if (_selectedPropertyId == null) {
      _showSnackBar('Please select a property', Colors.red);
      return;
    }

    if (_captionController.text.trim().isEmpty) {
      _showSnackBar('Please add a caption', Colors.red);
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    _progressController.forward();

    final reelProvider = Provider.of<ReelProvider>(context, listen: false);

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() {
        _uploadProgress = i / 10;
      });
    }

    final success = await reelProvider.uploadReel(
      propertyId: _selectedPropertyId!,
      caption: _captionController.text.trim(),
      videoFile: _videoFile!,
    );

    setState(() {
      _isUploading = false;
      _uploadProgress = 1.0;
    });

    if (success && mounted) {
      _showSnackBar('Reel uploaded successfully! 🎉', Colors.green);
      Navigator.pop(context, true);
    } else if (mounted) {
      _showSnackBar(reelProvider.error ?? 'Failed to upload reel', Colors.red);
    }
  }

  // ========== UI HELPERS ==========
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: GoogleFonts.poppins(fontSize: 13))),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
        appBar: _buildPremiumAppBar(isDark),
        body: _isProcessing
            ? _buildProcessingState(isDark)
            : FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideUp,
                  child: ScaleTransition(
                    scale: _scaleIn,
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildVideoUploadSection(isDark),
                          const SizedBox(height: 16),
                          _buildPropertySelection(isDark),
                          const SizedBox(height: 16),
                          _buildCaptionInput(isDark),
                          const SizedBox(height: 20),
                          _buildUploadButton(isDark),
                          const SizedBox(height: 16),
                          _buildGuidelines(isDark),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // ========== PREMIUM APP BAR ==========
  PreferredSizeWidget _buildPremiumAppBar(bool isDark) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: Container(
        margin: const EdgeInsets.only(left: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1F33) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF4B5563),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFD4AF37)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.movie_creation_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Upload Reel',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
        ],
      ),
      actions: [
        if (_isUploading)
          const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFF59E0B),
              ),
            ),
          ),
      ],
    );
  }

  // ========== VIDEO UPLOAD SECTION ==========
  Widget _buildVideoUploadSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _videoFile != null
              ? const Color(0xFF22C55E).withOpacity(0.3)
              : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06)),
          width: _videoFile != null ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.video_library_rounded,
                  color: Color(0xFFF59E0B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Select Video',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              if (_videoFile != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF22C55E),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Selected',
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF22C55E),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          _videoFile != null
              ? _buildVideoPreview(isDark)
              : _buildUploadButtons(isDark),

          if (_videoFile != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Max 30 seconds video allowed',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: isDark ? Colors.grey[500] : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview(bool isDark) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: _videoThumbnail != null
            ? DecorationImage(
                image: FileImage(File(_videoThumbnail!)),
                fit: BoxFit.cover,
              )
            : null,
        color: isDark ? Colors.grey[800] : Colors.grey[200],
      ),
      child: Stack(
        children: [
          // Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Remove Button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _videoFile = null;
                  _videoThumbnail = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
          // Play Icon
          Positioned.fill(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
          // Duration Badge
          Positioned(
            bottom: 8,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
              child: const Text(
                '🎬 30s max',
                style: TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _pickVideo,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2338) : const Color(0xFFF0F2F6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.06),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.photo_library_rounded,
                    size: 28,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Gallery',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _recordVideo,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF59E0B).withOpacity(0.1),
                    const Color(0xFFD4AF37).withOpacity(0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.camera_alt_rounded,
                    size: 28,
                    color: const Color(0xFFF59E0B),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Camera',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ========== PROPERTY SELECTION ==========
  Widget _buildPropertySelection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: Color(0xFFF59E0B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Select Property',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              if (_selectedPropertyId != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '✓ Selected',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Input
          TextField(
            controller: _propertySearchController,
            onTap: () {
              setState(() {
                _isPropertyDropdownOpen = true;
              });
            },
            onChanged: (value) {
              setState(() {
                _filteredProperties = Provider.of<PropertyProvider>(
                  context,
                  listen: false,
                ).properties.where((p) {
                  return p.title
                      .toLowerCase()
                      .contains(value.toLowerCase()) ||
                      p.city.toLowerCase().contains(value.toLowerCase());
                }).toList();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search your properties...',
              hintStyle: GoogleFonts.poppins(
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                size: 20,
              ),
              suffixIcon: _selectedPropertyId != null
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () {
                        setState(() {
                          _selectedPropertyId = null;
                          _selectedPropertyTitle = null;
                          _propertySearchController.clear();
                          _filteredProperties =
                              Provider.of<PropertyProvider>(context,
                                      listen: false)
                                  .properties;
                          _isPropertyDropdownOpen = false;
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark
                  ? const Color(0xFF1A2338)
                  : const Color(0xFFF0F2F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              fontSize: 14,
            ),
          ),

          // Selected Property Display
          if (_selectedPropertyId != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF59E0B).withOpacity(0.08),
                    const Color(0xFFD4AF37).withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF22C55E),
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedPropertyTitle ?? '',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                          ),
                        ),
                        Text(
                          'ID: #${_selectedPropertyId}',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: isDark ? Colors.grey[400] : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Dropdown List
          if (_isPropertyDropdownOpen && _filteredProperties.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A2338) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.black.withOpacity(0.06),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredProperties.length > 5
                    ? 5
                    : _filteredProperties.length,
                itemBuilder: (context, index) {
                  final property = _filteredProperties[index];
                  return ListTile(
                    onTap: () {
                      setState(() {
                        _selectedPropertyId = property.propertyId;
                        _selectedPropertyTitle = property.title;
                        _propertySearchController.text = property.title;
                        _isPropertyDropdownOpen = false;
                      });
                    },
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 40,
                        height: 40,
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        child: property.coverImage.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: property.coverImage,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Icon(
                                  Icons.apartment_rounded,
                                  size: 20,
                                  color: isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400],
                                ),
                              )
                            : Icon(
                                Icons.apartment_rounded,
                                size: 20,
                                color: isDark ? Colors.grey[600] : Colors.grey[400],
                              ),
                      ),
                    ),
                    title: Text(
                      property.title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      property.city,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  // ========== CAPTION INPUT ==========
  Widget _buildCaptionInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F33) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notes_rounded,
                  color: Color(0xFFF59E0B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Caption',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
              const Spacer(),
              Text(
                '${_captionController.text.length}/500',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _captionController,
            maxLength: 500,
            maxLines: 4,
            decoration: InputDecoration(
              hintText:
                  'Describe your property... e.g. "Fully furnished room with AC, WiFi 🏠"',
              hintStyle: GoogleFonts.poppins(
                color: isDark ? Colors.grey[400] : Colors.grey[500],
                fontSize: 13,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1A2338) : const Color(0xFFF0F2F6),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              counterText: '',
            ),
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ========== UPLOAD BUTTON ==========
  Widget _buildUploadButton(bool isDark) {
    final isValid = _videoFile != null &&
        _selectedPropertyId != null &&
        _captionController.text.trim().isNotEmpty;

    return Column(
      children: [
        if (_isUploading) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _uploadProgress,
                      minHeight: 4,
                      backgroundColor: isDark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${(_uploadProgress * 100).toInt()}%',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: const Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        GestureDetector(
          onTap: _isUploading ? null : _uploadReel,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: isValid
                  ? const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD4AF37)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.grey[400]!,
                        Colors.grey[300]!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: isValid
                  ? [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isUploading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                else
                  Icon(
                    Icons.upload_rounded,
                    color: isValid ? Colors.white : Colors.grey[500],
                    size: 20,
                  ),
                if (!_isUploading) const SizedBox(width: 8),
                Text(
                  _isUploading ? 'Uploading...' : 'Upload Reel 🚀',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isValid ? Colors.white : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ========== GUIDELINES ==========
  Widget _buildGuidelines(bool isDark) {
    final guidelines = [
      '🎬 20-30 seconds video recommended',
      '📱 MP4, MOV, AVI formats supported',
      '📝 Add engaging caption to attract users',
      '🏠 Property must be yours (verified owner)',
      '⚠️ No inappropriate content allowed',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1A1F33).withOpacity(0.5)
            : const Color(0xFFF0F2F6).withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: const Color(0xFFF59E0B),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Guidelines',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...guidelines.map((text) => Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Row(
              children: [
                Text(
                  '• ',
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  // ========== PROCESSING STATE ==========
  Widget _buildProcessingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF59E0B).withOpacity(0.2),
                        const Color(0xFFD4AF37).withOpacity(0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Text(
            'Processing Video...',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Compressing and preparing your reel',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}