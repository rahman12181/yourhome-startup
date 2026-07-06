import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _pincodeCtrl;
  late TextEditingController _rentMinCtrl;
  late TextEditingController _rentMaxCtrl;
  late TextEditingController _depositCtrl;

  String _propertyType = 'PG';
  String _genderAllowed = 'BOYS';
  bool _isNegotiable = false;
  final List<String> _selectedAmenities = [];

  final List<String> _propertyTypes = ['PG', 'HOSTEL', 'HOTEL', 'FLAT', 'ROOM'];
  final List<String> _genders = ['BOYS', 'GIRLS', 'BOTH'];
  final List<String> _allAmenities = [
    'WiFi', 'AC', 'Meals', 'Laundry', 'CCTV', 'Parking', 'Gym', 'Hot Water',
    'Power Backup', 'Security', 'TV', 'Fridge'
  ];

  bool get _isEdit => widget.property != null;

  @override
  void initState() {
    super.initState();
    final p = widget.property;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _addressCtrl = TextEditingController(text: p?.addressLine ?? '');
    _cityCtrl = TextEditingController(text: p?.city ?? '');
    _stateCtrl = TextEditingController(text: p?.state ?? '');
    _pincodeCtrl = TextEditingController(text: p?.pincode ?? '');
    _rentMinCtrl = TextEditingController(text: p?.monthlyRentMin?.toStringAsFixed(0) ?? '');
    _rentMaxCtrl = TextEditingController(text: p?.monthlyRentMax?.toStringAsFixed(0) ?? '');
    _depositCtrl = TextEditingController(text: p?.securityDeposit?.toStringAsFixed(0) ?? '');
    if (p != null) {
      _propertyType = p.propertyType;
      _genderAllowed = p.genderAllowed;
      _isNegotiable = p.isNegotiable;
      _selectedAmenities.addAll(p.amenities);
    }
  }

  @override
  void dispose() {
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final body = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'addressLine': _addressCtrl.text.trim(),
      'city': _cityCtrl.text.trim(),
      'state': _stateCtrl.text.trim(),
      'pincode': _pincodeCtrl.text.trim(),
      'genderAllowed': _genderAllowed,
      'isNegotiable': _isNegotiable,
      'amenities': _selectedAmenities,
      if (_rentMinCtrl.text.isNotEmpty) 'monthlyRentMin': double.tryParse(_rentMinCtrl.text),
      if (_rentMaxCtrl.text.isNotEmpty) 'monthlyRentMax': double.tryParse(_rentMaxCtrl.text),
      if (_depositCtrl.text.isNotEmpty) 'securityDeposit': double.tryParse(_depositCtrl.text),
    };
    if (!_isEdit) body['propertyType'] = _propertyType;

    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
    final success = _isEdit
        ? await ownerProvider.updateProperty(widget.property!.propertyId, body)
        : (await ownerProvider.addProperty(body)) != null;

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEdit ? '✅ Property updated successfully!' : '✅ Property added successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 2),
            margin: const EdgeInsets.all(12),
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              ownerProvider.error ?? 'Something went wrong',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(12),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ownerProvider = Provider.of<OwnerProvider>(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit Property' : 'Add Property',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _submit,
            child: Text(
              _isEdit ? 'Update' : 'Add',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: const Color(0xFF7C3AED),
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(bottom: 20 + bottomPadding),
          child: Column(
            children: [
              _buildSectionHeader('Basic Information', isDark),
              _buildTextField(_titleCtrl, 'Title *', isDark,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              _buildTextField(_descCtrl, 'Description', isDark, maxLines: 3),
              if (!_isEdit) ...[
                _buildSectionHeader('Property Type *', isDark),
                _buildChipSelector(
                  _propertyTypes,
                  _propertyType,
                  (value) => setState(() => _propertyType = value),
                  isDark,
                ),
              ],
              _buildSectionHeader('Location', isDark),
              _buildTextField(_addressCtrl, 'Address Line *', isDark,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(_cityCtrl, 'City *', isDark,
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(_stateCtrl, 'State *', isDark,
                        validator: (v) => v!.isEmpty ? 'Required' : null),
                  ),
                ],
              ),
              _buildTextField(_pincodeCtrl, 'Pincode *', isDark,
                  validator: (v) => v!.isEmpty ? 'Required' : null),
              _buildSectionHeader('Pricing', isDark),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(_rentMinCtrl, 'Min Rent', isDark,
                        keyboardType: TextInputType.number),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildTextField(_rentMaxCtrl, 'Max Rent', isDark,
                        keyboardType: TextInputType.number),
                  ),
                ],
              ),
              _buildTextField(_depositCtrl, 'Security Deposit', isDark,
                  keyboardType: TextInputType.number),
              _buildSectionHeader('Gender & Negotiable', isDark),
              _buildChipSelector(
                _genders,
                _genderAllowed,
                (value) => setState(() => _genderAllowed = value),
                isDark,
              ),
              SwitchListTile(
                title: Text(
                  'Negotiable',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                value: _isNegotiable,
                onChanged: (v) => setState(() => _isNegotiable = v),
                activeColor: const Color(0xFF7C3AED),
              ),
              _buildSectionHeader('Amenities', isDark),
              _buildAmenitySelector(isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, bool isDark,
      {int maxLines = 1,
      TextInputType? keyboardType,
      String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.poppins(
          fontSize: 13,
          color: isDark ? Colors.white : const Color(0xFF1A1A2E),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF1A1F33) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildChipSelector(
    List<String> options,
    String selected,
    Function(String) onSelected,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        children: options.map((option) {
          final isSelected = selected == option;
          return ChoiceChip(
            label: Text(
              option,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            selected: isSelected,
            onSelected: (_) => onSelected(option),
            selectedColor: const Color(0xFF7C3AED),
            backgroundColor: isDark ? const Color(0xFF1A1F33) : Colors.grey[200],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAmenitySelector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _allAmenities.map((amenity) {
          final isSelected = _selectedAmenities.contains(amenity);
          return FilterChip(
            label: Text(
              amenity,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _selectedAmenities.add(amenity);
                } else {
                  _selectedAmenities.remove(amenity);
                }
              });
            },
            selectedColor: const Color(0xFF7C3AED),
            backgroundColor: isDark ? const Color(0xFF1A1F33) : Colors.grey[200],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }).toList(),
      ),
    );
  }
}