import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controllers/company_contract_controller.dart';
import '../../models/company_contract_location_model.dart';
import '../../services/company_contract_service.dart';

class CompanyContractLocationScreen extends StatefulWidget {
  const CompanyContractLocationScreen({
    super.key,
    required this.contractId,
    this.initialLocation,
  });

  final int contractId;
  final CompanyContractLocationModel? initialLocation;

  @override
  State<CompanyContractLocationScreen> createState() =>
      _CompanyContractLocationScreenState();
}

class _CompanyContractLocationScreenState
    extends State<CompanyContractLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final CompanyContractController _controller;
  late final TextEditingController _addressController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _controller = CompanyContractController(
      CompanyContractService(ApiClient()),
    );
    final location = widget.initialLocation;
    _addressController = TextEditingController(text: location?.address ?? '');
    _latitudeController = TextEditingController(
      text: location == null ? '' : location.latitude.toStringAsFixed(6),
    );
    _longitudeController = TextEditingController(
      text: location == null ? '' : location.longitude.toStringAsFixed(6),
    );
    _notesController = TextEditingController(text: location?.notes ?? '');
  }

  @override
  void dispose() {
    _addressController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_controller.isSavingLocation) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final latitude = double.parse(_latitudeController.text.trim());
    final longitude = double.parse(_longitudeController.text.trim());

    HapticFeedback.mediumImpact();
    setState(() {});

    final saved = await _controller.saveLocation(
      widget.contractId,
      CompanyContractLocationRequest(
        address: _addressController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        notes: _notesController.text.trim(),
      ),
    );

    if (!mounted) return;

    if (saved == null) {
      setState(() {});
      _snack(
        _controller.locationErrorMessage ??
            'Unable to save the exact job location.',
        error: true,
      );
      return;
    }

    _snack('Exact job location saved.', success: true);
    Navigator.of(context).pop(saved);
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initialLocation != null;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.navy,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              editing ? 'Edit Exact Location' : 'Add Exact Location',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Text(
              'Private contract location',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
            children: [
              _privacyCard(),
              const SizedBox(height: 14),
              _card(
                title: 'Address',
                icon: Icons.location_on_outlined,
                child: TextFormField(
                  controller: _addressController,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    'Exact street, site, gate or facility address',
                  ),
                  validator: (value) {
                    final clean = value?.trim() ?? '';
                    if (clean.isEmpty) return 'Exact address is required.';
                    if (clean.length > 500) {
                      return 'Address cannot exceed 500 characters.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 14),
              _card(
                title: 'Coordinates',
                icon: Icons.my_location_rounded,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: _inputDecoration('Latitude'),
                            validator: (value) => _coordinateValidator(
                              value,
                              min: -90,
                              max: 90,
                              label: 'Latitude',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _longitudeController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            decoration: _inputDecoration('Longitude'),
                            validator: (value) => _coordinateValidator(
                              value,
                              min: -180,
                              max: 180,
                              label: 'Longitude',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.grey,
                          size: 15,
                        ),
                        SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'The API requires both coordinates. They are revealed only through the protected contract-location flow.',
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 10.3,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _card(
                title: 'Access Notes',
                icon: Icons.route_outlined,
                child: TextFormField(
                  controller: _notesController,
                  maxLength: 2000,
                  minLines: 4,
                  maxLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _inputDecoration(
                    'Optional: gate, contact point, access instructions, safety notes...',
                  ),
                  validator: (value) {
                    if ((value ?? '').trim().length > 2000) {
                      return 'Notes cannot exceed 2000 characters.';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 13),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.cardBorder)),
          ),
          child: FilledButton.icon(
            onPressed: _controller.isSavingLocation ? null : _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              backgroundColor: AppColors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: _controller.isSavingLocation
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.location_on_rounded, size: 19),
            label: Text(
              _controller.isSavingLocation
                  ? 'Saving Location...'
                  : editing
                      ? 'Save Location Changes'
                      : 'Save Exact Location',
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }

  Widget _privacyCard() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEAFBF7), Color(0xFFF2F8FC)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.green.withOpacity(0.12)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline_rounded, color: AppColors.green, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Private operational location',
                  style: TextStyle(
                    color: AppColors.navy,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'This exact location is not part of the public job post. It becomes available to the contracted pilot through the active contract workflow.',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 10.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.07),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: AppColors.blue, size: 18),
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.lightGrey, fontSize: 11),
      filled: true,
      fillColor: AppColors.bg,
      counterStyle: const TextStyle(color: AppColors.grey, fontSize: 9),
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.blue, width: 1.4),
      ),
    );
  }

  String? _coordinateValidator(
    String? value, {
    required double min,
    required double max,
    required String label,
  }) {
    final clean = value?.trim() ?? '';
    if (clean.isEmpty) return '$label is required.';
    final number = double.tryParse(clean);
    if (number == null) return 'Enter a valid $label.';
    if (number < min || number > max) {
      return '$label must be between $min and $max.';
    }
    return null;
  }

  void _snack(String message, {bool success = false, bool error = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          backgroundColor: error
              ? AppColors.red
              : success
                  ? AppColors.green
                  : AppColors.navy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Text(message),
        ),
      );
  }
}
