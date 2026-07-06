import 'package:flutter/material.dart';
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

class _AddEditPropertyPageState extends State<AddEditPropertyPage> {
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_isEdit ? 'Property updated' : 'Property added successfully')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(ownerProvider.error ?? 'Something went wrong')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ownerProvider = Provider.of<OwnerProvider>(context);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Property' : 'Add Property',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField(_titleCtrl, 'Title *', validator: (v) => v!.isEmpty ? 'Required' : null),
            _buildTextField(_descCtrl, 'Description', maxLines: 3),
            if (!_isEdit) ...[
              const SizedBox(height: 12),
              Text('Property Type *', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              Wrap(
                spacing: 8,
                children: _propertyTypes
                    .map((t) => ChoiceChip(
                          label: Text(t),
                          selected: _propertyType == t,
                          onSelected: (_) => setState(() => _propertyType = t),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Text('Gender Allowed *', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            Wrap(
              spacing: 8,
              children: _genders
                  .map((g) => ChoiceChip(
                        label: Text(g),
                        selected: _genderAllowed == g,
                        onSelected: (_) => setState(() => _genderAllowed = g),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            _buildTextField(_addressCtrl, 'Address Line *', validator: (v) => v!.isEmpty ? 'Required' : null),
            _buildTextField(_cityCtrl, 'City *', validator: (v) => v!.isEmpty ? 'Required' : null),
            _buildTextField(_stateCtrl, 'State *', validator: (v) => v!.isEmpty ? 'Required' : null),
            _buildTextField(_pincodeCtrl, 'Pincode *', validator: (v) => v!.isEmpty ? 'Required' : null),
            Row(
              children: [
                Expanded(child: _buildTextField(_rentMinCtrl, 'Min Rent', keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(_rentMaxCtrl, 'Max Rent', keyboardType: TextInputType.number)),
              ],
            ),
            _buildTextField(_depositCtrl, 'Security Deposit', keyboardType: TextInputType.number),
            SwitchListTile(
              title: const Text('Negotiable'),
              value: _isNegotiable,
              onChanged: (v) => setState(() => _isNegotiable = v),
            ),
            const SizedBox(height: 12),
            Text('Amenities', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allAmenities
                  .map((a) => FilterChip(
                        label: Text(a),
                        selected: _selectedAmenities.contains(a),
                        onSelected: (sel) {
                          setState(() {
                            if (sel) {
                              _selectedAmenities.add(a);
                            } else {
                              _selectedAmenities.remove(a);
                            }
                          });
                        },
                      ))
                  .toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: ownerProvider.isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: ownerProvider.isSubmitting
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Update Property' : 'Add Property'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label,
      {int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}