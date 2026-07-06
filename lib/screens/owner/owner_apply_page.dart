import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/owner_provider.dart';

class OwnerApplyPage extends StatefulWidget {
  const OwnerApplyPage({super.key});

  @override
  State<OwnerApplyPage> createState() => _OwnerApplyPageState();
}

class _OwnerApplyPageState extends State<OwnerApplyPage> {
  final _formKey = GlobalKey<FormState>();
  final _businessCtrl = TextEditingController();
  final _aadharCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  File? _aadharDoc, _panDoc, _addressProof;

  Future<void> _pickFile(void Function(File) onPicked) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) onPicked(File(picked.path));
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final ownerProvider = Provider.of<OwnerProvider>(context, listen: false);
    final result = await ownerProvider.applyAsOwner(
      businessName: _businessCtrl.text.trim(),
      aadharNumber: _aadharCtrl.text.trim(),
      panNumber: _panCtrl.text.trim(),
      aadharDoc: _aadharDoc,
      panDoc: _panDoc,
      addressProof: _addressProof,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
      if (result.success) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownerProvider = Provider.of<OwnerProvider>(context);
    return Scaffold(
      appBar: AppBar(title: Text('Apply as Owner', style: GoogleFonts.poppins(fontWeight: FontWeight.w600))),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _businessCtrl,
              decoration: const InputDecoration(labelText: 'Business Name *'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _aadharCtrl,
              decoration: const InputDecoration(labelText: 'Aadhar Number (1234 5678 9012) *'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _panCtrl,
              decoration: const InputDecoration(labelText: 'PAN Number (ABCDE1234F) *'),
              validator: (v) => v!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            _buildFilePicker('Aadhar Document', _aadharDoc, (f) => setState(() => _aadharDoc = f)),
            _buildFilePicker('PAN Document', _panDoc, (f) => setState(() => _panDoc = f)),
            _buildFilePicker('Address Proof', _addressProof, (f) => setState(() => _addressProof = f)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: ownerProvider.isSubmitting ? null : _submit,
              child: ownerProvider.isSubmitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Submit Application'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilePicker(String label, File? file, void Function(File) onPicked) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton.icon(
        onPressed: () => _pickFile(onPicked),
        icon: const Icon(Icons.upload_file),
        label: Text(file != null ? '$label ✅' : label),
      ),
    );
  }
}