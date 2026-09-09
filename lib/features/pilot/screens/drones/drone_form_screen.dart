import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';

import '../../controllers/drone_controller.dart';
import '../../models/drone_form_request.dart';
import '../../models/drone_model.dart';
import '../../services/drone_service.dart';

// ============================================================================
// COLORS
// ============================================================================

const Color _bg = Color(0xFFF7F9FB);
const Color _ink = Color(0xFF071A35);
const Color _muted = Color(0xFF63748A);
const Color _hint = Color(0xFF98A6B4);
const Color _teal = Color(0xFF0FA6B4);
const Color _tealDark = Color(0xFF078B98);
const Color _tealSoft = Color(0xFFEAF9FA);
const Color _border = Color(0xFFE5EAF0);
const Color _danger = Color(0xFFE45252);

// ============================================================================
// ADD / EDIT DRONE SCREEN
// ============================================================================

class DroneFormScreen extends StatefulWidget {
  const DroneFormScreen({
    super.key,
    this.initialDrone,
  });

  final DroneModel? initialDrone;

  bool get isEditing =>
      initialDrone != null;

  @override
  State<DroneFormScreen> createState() =>
      _DroneFormScreenState();
}

class _DroneFormScreenState
    extends State<DroneFormScreen> {
  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  late final DroneController _controller;

  final ImagePicker _picker =
  ImagePicker();

  final TextEditingController _makeController =
  TextEditingController();

  final TextEditingController _modelController =
  TextEditingController();

  final TextEditingController _yearController =
  TextEditingController();

  final TextEditingController _serialController =
  TextEditingController();

  final TextEditingController _weightController =
  TextEditingController();

  final TextEditingController _flightTimeController =
  TextEditingController();

  final TextEditingController _batteriesController =
  TextEditingController();

  final TextEditingController _batteryTypeController =
  TextEditingController();

  final TextEditingController _batteryFeeController =
  TextEditingController();

  final TextEditingController _hourlyRateController =
  TextEditingController();

  final TextEditingController _dailyRateController =
  TextEditingController();

  final TextEditingController _emergencyRateController =
  TextEditingController();

  final Set<String> _capabilities =
  <String>{};

  String? _selectedImagePath;

  bool _saving = false;

  static const List<_CapabilityOption>
  _capabilityOptions = [
    _CapabilityOption(
      value: 'thermal',
      label: 'Thermal',
      icon: Icons.thermostat_rounded,
    ),
    _CapabilityOption(
      value: 'night_vision',
      label: 'Night Vision',
      icon: Icons.nights_stay_outlined,
    ),
    _CapabilityOption(
      value: 'zoom',
      label: 'Zoom',
      icon: Icons.zoom_in_rounded,
    ),
    _CapabilityOption(
      value: 'multispectral',
      label: 'Multispectral',
      icon: Icons.filter_center_focus_rounded,
    ),
    _CapabilityOption(
      value: 'speaker',
      label: 'Speaker',
      icon: Icons.volume_up_outlined,
    ),
    _CapabilityOption(
      value: 'spotlight',
      label: 'Spotlight',
      icon: Icons.light_mode_outlined,
    ),
    _CapabilityOption(
      value: 'parachute',
      label: 'Parachute',
      icon: Icons.paragliding_rounded,
    ),
    _CapabilityOption(
      value: 'rtk',
      label: 'RTK',
      icon: Icons.gps_fixed_rounded,
    ),
    _CapabilityOption(
      value: 'winch',
      label: 'Winch',
      icon: Icons.vertical_align_bottom_rounded,
    ),
    _CapabilityOption(
      value: 'laser',
      label: 'Laser',
      icon: Icons.center_focus_strong_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _controller = DroneController(
      DroneService(
        ApiClient(),
      ),
    );

    _fillInitialData();
  }

  void _fillInitialData() {
    final drone =
        widget.initialDrone;

    if (drone == null) {
      _yearController.text =
          DateTime.now().year.toString();
      return;
    }

    _makeController.text =
        drone.make;

    _modelController.text =
        drone.model;

    _yearController.text =
        drone.manufactureYear?.toString() ?? '';

    _serialController.text =
        drone.serialNumber;

    _weightController.text =
        _numberText(drone.weightKg);

    _flightTimeController.text =
        drone.flightTimePerBatteryMinutes
            ?.toString() ??
            '';

    _batteriesController.text =
        drone.totalBatteries?.toString() ?? '';

    _batteryTypeController.text =
        drone.batteryType;

    _batteryFeeController.text =
        _numberText(drone.batteryUsageFee);

    _hourlyRateController.text =
        _numberText(drone.hourlyRate);

    _dailyRateController.text =
        _numberText(drone.dailyRate);

    _emergencyRateController.text =
        _numberText(
          drone.emergencyCalloutFee,
        );

    _capabilities.addAll(
      drone.capabilities,
    );
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _serialController.dispose();
    _weightController.dispose();
    _flightTimeController.dispose();
    _batteriesController.dispose();
    _batteryTypeController.dispose();
    _batteryFeeController.dispose();
    _hourlyRateController.dispose();
    _dailyRateController.dispose();
    _emergencyRateController.dispose();

    super.dispose();
  }

  // ==========================================================================
  // IMAGE
  // ==========================================================================

  Future<void> _pickImage() async {
    final source =
    await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            margin:
            const EdgeInsets.all(12),
            padding:
            const EdgeInsets.fromLTRB(
              20,
              12,
              20,
              20,
            ),
            decoration:
            BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration:
                  BoxDecoration(
                    color: _border,
                    borderRadius:
                    BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Drone Photo',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 17,
                    fontWeight:
                    FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SourceButton(
                        icon:
                        Icons.camera_alt_outlined,
                        title:
                        'Camera',
                        onTap: () {
                          Navigator.pop(
                            sheetContext,
                            ImageSource.camera,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SourceButton(
                        icon:
                        Icons.photo_library_outlined,
                        title:
                        'Gallery',
                        onTap: () {
                          Navigator.pop(
                            sheetContext,
                            ImageSource.gallery,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    final image =
    await _picker.pickImage(
      source: source,
      imageQuality: 88,
      maxWidth: 1800,
      maxHeight: 1800,
    );

    if (image == null || !mounted) {
      return;
    }

    final file =
    File(image.path);

    final size =
    await file.length();

    if (size >
        10 * 1024 * 1024) {
      _showSnack(
        'Drone image must be 10 MB or smaller.',
        isError: true,
      );
      return;
    }

    setState(() {
      _selectedImagePath =
          image.path;
    });
  }

  // ==========================================================================
  // SAVE
  // ==========================================================================

  Future<void> _save() async {
    if (_saving) return;

    FocusScope.of(context).unfocus();

    final valid =
        _formKey.currentState?.validate() ??
            false;

    if (!valid) {
      _showSnack(
        'Please check the highlighted fields.',
        isError: true,
      );
      return;
    }

    if (!widget.isEditing &&
        (_selectedImagePath == null ||
            _selectedImagePath!.isEmpty)) {
      _showSnack(
        'Please add a drone photo.',
        isError: true,
      );
      return;
    }

    final request =
    DroneFormRequest(
      make:
      _makeController.text,
      model:
      _modelController.text,
      manufactureYear:
      int.parse(
        _yearController.text.trim(),
      ),
      serialNumber:
      _serialController.text,
      weightKg:
      double.parse(
        _weightController.text.trim(),
      ),
      capabilities:
      _capabilities.toList(),
      flightTimePerBatteryMinutes:
      int.parse(
        _flightTimeController.text.trim(),
      ),
      totalBatteries:
      int.parse(
        _batteriesController.text.trim(),
      ),
      batteryType:
      _batteryTypeController.text,
      batteryUsageFee:
      _optionalDouble(
        _batteryFeeController.text,
      ),
      hourlyRate:
      double.parse(
        _hourlyRateController.text.trim(),
      ),
      dailyRate:
      double.parse(
        _dailyRateController.text.trim(),
      ),
      emergencyCalloutFee:
      double.parse(
        _emergencyRateController.text.trim(),
      ),
      imagePath:
      _selectedImagePath,
    );

    setState(() {
      _saving = true;
    });

    final result =
    widget.isEditing
        ? await _controller.updateDrone(
      widget.initialDrone!.id,
      request,
    )
        : await _controller.createDrone(
      request,
    );

    if (!mounted) return;

    setState(() {
      _saving = false;
    });

    if (result == null) {
      _showSnack(
        _controller.errorMessage ??
            'Unable to save drone.',
        isError: true,
      );
      return;
    }

    HapticFeedback.mediumImpact();

    Navigator.pop(
      context,
      result,
    );
  }

  void _showSnack(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior:
        SnackBarBehavior.floating,
        backgroundColor:
        isError ? _danger : _ink,
        margin:
        const EdgeInsets.all(16),
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(16),
        ),
        content:
        Text(message),
      ),
    );
  }

  // ==========================================================================
  // BUILD
  // ==========================================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: _bg,
        elevation: 0,
        leading: IconButton(
          onPressed:
          _saving
              ? null
              : () =>
              Navigator.pop(context),
          icon:
          const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _ink,
            size: 18,
          ),
        ),
        title: Text(
          widget.isEditing
              ? 'Edit Drone'
              : 'Add Drone',
          style:
          const TextStyle(
            color: _ink,
            fontSize: 16,
            fontWeight:
            FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: Stack(
            children: [
              ListView(
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior
                    .onDrag,
                padding:
                const EdgeInsets.fromLTRB(
                  18,
                  8,
                  18,
                  110,
                ),
                children: [
                  _DroneImageCard(
                    selectedImagePath:
                    _selectedImagePath,
                    currentImageUrl:
                    widget.initialDrone
                        ?.imageUrl ??
                        '',
                    onTap:
                    _pickImage,
                  ),

                  const SizedBox(height: 14),

                  _SectionCard(
                    number: '01',
                    icon:
                    Icons.flight_takeoff_rounded,
                    title:
                    'Aircraft details',
                    subtitle:
                    'Identity and physical information',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child:
                              _Input(
                                controller:
                                _makeController,
                                label:
                                'Make',
                                hint:
                                'DJI',
                                icon:
                                Icons.apartment_rounded,
                                validator:
                                _required,
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child:
                              _Input(
                                controller:
                                _modelController,
                                label:
                                'Model',
                                hint:
                                'Mavic 3 Pro',
                                icon:
                                Icons.flight_rounded,
                                validator:
                                _required,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child:
                              _Input(
                                controller:
                                _yearController,
                                label:
                                'Year',
                                hint:
                                '2026',
                                icon:
                                Icons.calendar_month_outlined,
                                keyboardType:
                                TextInputType.number,
                                validator:
                                _yearValidator,
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child:
                              _Input(
                                controller:
                                _weightController,
                                label:
                                'Weight (kg)',
                                hint:
                                '0.95',
                                icon:
                                Icons.scale_outlined,
                                keyboardType:
                                const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (value) =>
                                    _positiveNumber(
                                      value,
                                      'Weight',
                                    ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _Input(
                          controller:
                          _serialController,
                          label:
                          'Serial number',
                          hint:
                          'Enter aircraft serial number',
                          icon:
                          Icons.qr_code_rounded,
                          validator:
                          _required,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  _SectionCard(
                    number: '02',
                    icon:
                    Icons.battery_charging_full_rounded,
                    title:
                    'Power & capabilities',
                    subtitle:
                    'Battery setup and aircraft equipment',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child:
                              _Input(
                                controller:
                                _flightTimeController,
                                label:
                                'Flight time',
                                hint:
                                '45',
                                suffix:
                                'min',
                                icon:
                                Icons.timer_outlined,
                                keyboardType:
                                TextInputType.number,
                                validator: (value) =>
                                    _positiveInt(
                                      value,
                                      'Flight time',
                                    ),
                              ),
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child:
                              _Input(
                                controller:
                                _batteriesController,
                                label:
                                'Batteries',
                                hint:
                                '3',
                                icon:
                                Icons.battery_std_rounded,
                                keyboardType:
                                TextInputType.number,
                                validator: (value) =>
                                    _positiveInt(
                                      value,
                                      'Batteries',
                                    ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        _Input(
                          controller:
                          _batteryTypeController,
                          label:
                          'Battery type',
                          hint:
                          'Optional',
                          icon:
                          Icons.battery_6_bar_rounded,
                        ),

                        const SizedBox(height: 12),

                        _Input(
                          controller:
                          _batteryFeeController,
                          label:
                          'Battery usage fee',
                          hint:
                          'Optional',
                          prefixText:
                          '\$ ',
                          icon:
                          Icons.payments_outlined,
                          keyboardType:
                          const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator:
                          _optionalMoney,
                        ),

                        const SizedBox(height: 18),

                        const Align(
                          alignment:
                          Alignment.centerLeft,
                          child:
                          Text(
                            'Capabilities',
                            style:
                            TextStyle(
                              color: _ink,
                              fontSize: 12,
                              fontWeight:
                              FontWeight.w800,
                            ),
                          ),
                        ),

                        const SizedBox(height: 9),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                          _capabilityOptions.map(
                                (option) {
                              final selected =
                              _capabilities.contains(
                                option.value,
                              );

                              return FilterChip(
                                selected:
                                selected,
                                showCheckmark:
                                false,
                                backgroundColor:
                                Colors.white,
                                selectedColor:
                                _tealSoft,
                                side:
                                BorderSide(
                                  color: selected
                                      ? _teal
                                      : _border,
                                ),
                                avatar:
                                Icon(
                                  option.icon,
                                  size: 15,
                                  color: selected
                                      ? _tealDark
                                      : _hint,
                                ),
                                label:
                                Text(
                                  option.label,
                                  style:
                                  TextStyle(
                                    color: selected
                                        ? _tealDark
                                        : _muted,
                                    fontWeight:
                                    FontWeight.w700,
                                    fontSize: 10.5,
                                  ),
                                ),
                                onSelected:
                                    (_) {
                                  setState(() {
                                    if (selected) {
                                      _capabilities.remove(
                                        option.value,
                                      );
                                    } else {
                                      _capabilities.add(
                                        option.value,
                                      );
                                    }
                                  });
                                },
                              );
                            },
                          ).toList(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  _SectionCard(
                    number: '03',
                    icon:
                    Icons.attach_money_rounded,
                    title:
                    'Pricing',
                    subtitle:
                    'Pilot rates for this aircraft',
                    child: Column(
                      children: [
                        _Input(
                          controller:
                          _hourlyRateController,
                          label:
                          'Hourly rate',
                          hint:
                          '150',
                          prefixText:
                          '\$ ',
                          icon:
                          Icons.schedule_rounded,
                          keyboardType:
                          const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) =>
                              _positiveNumber(
                                value,
                                'Hourly rate',
                              ),
                        ),

                        const SizedBox(height: 12),

                        _Input(
                          controller:
                          _dailyRateController,
                          label:
                          'Daily rate',
                          hint:
                          '800',
                          prefixText:
                          '\$ ',
                          icon:
                          Icons.today_outlined,
                          keyboardType:
                          const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) =>
                              _positiveNumber(
                                value,
                                'Daily rate',
                              ),
                        ),

                        const SizedBox(height: 12),

                        _Input(
                          controller:
                          _emergencyRateController,
                          label:
                          'Emergency callout fee',
                          hint:
                          '250',
                          prefixText:
                          '\$ ',
                          icon:
                          Icons.bolt_rounded,
                          keyboardType:
                          const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: (value) =>
                              _nonNegativeNumber(
                                value,
                                'Emergency fee',
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child:
                _SaveBar(
                  editing:
                  widget.isEditing,
                  saving:
                  _saving,
                  onSave:
                  _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // VALIDATION
  // ==========================================================================

  String? _required(
      String? value,
      ) {
    if (value == null ||
        value.trim().isEmpty) {
      return 'Required';
    }

    return null;
  }

  String? _yearValidator(
      String? value,
      ) {
    final clean =
        value?.trim() ?? '';

    final year =
    int.tryParse(clean);

    if (year == null) {
      return 'Enter a valid year';
    }

    final current =
        DateTime.now().year;

    if (year < 1900 ||
        year > current + 1) {
      return 'Invalid year';
    }

    return null;
  }

  String? _positiveInt(
      String? value,
      String label,
      ) {
    final number =
    int.tryParse(
      value?.trim() ?? '',
    );

    if (number == null ||
        number <= 0) {
      return '$label must be greater than 0';
    }

    return null;
  }

  String? _positiveNumber(
      String? value,
      String label,
      ) {
    final number =
    double.tryParse(
      value?.trim() ?? '',
    );

    if (number == null ||
        number <= 0) {
      return '$label must be greater than 0';
    }

    return null;
  }

  String? _nonNegativeNumber(
      String? value,
      String label,
      ) {
    final number =
    double.tryParse(
      value?.trim() ?? '',
    );

    if (number == null ||
        number < 0) {
      return '$label must be 0 or more';
    }

    return null;
  }

  String? _optionalMoney(
      String? value,
      ) {
    final clean =
        value?.trim() ?? '';

    if (clean.isEmpty) {
      return null;
    }

    final number =
    double.tryParse(clean);

    if (number == null ||
        number < 0) {
      return 'Enter a valid amount';
    }

    return null;
  }
}

// ============================================================================
// IMAGE CARD
// ============================================================================

class _DroneImageCard extends StatelessWidget {
  const _DroneImageCard({
    required this.selectedImagePath,
    required this.currentImageUrl,
    required this.onTap,
  });

  final String? selectedImagePath;
  final String currentImageUrl;
  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    final hasLocal =
        selectedImagePath != null &&
            selectedImagePath!.isNotEmpty;

    final hasRemote =
        currentImageUrl.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      borderRadius:
      BorderRadius.circular(26),
      child: InkWell(
        onTap:
        onTap,
        borderRadius:
        BorderRadius.circular(26),
        child:
        Container(
          height: 210,
          clipBehavior:
          Clip.antiAlias,
          decoration:
          BoxDecoration(
            color:
            const Color(0xFFEAF5F7),
            borderRadius:
            BorderRadius.circular(26),
            border:
            Border.all(
              color:
              _border,
            ),
          ),
          child:
          Stack(
            fit:
            StackFit.expand,
            children: [
              if (hasLocal)
                Image.file(
                  File(
                    selectedImagePath!,
                  ),
                  fit:
                  BoxFit.cover,
                )
              else if (hasRemote)
                Image.network(
                  currentImageUrl,
                  fit:
                  BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) =>
                  const _DroneImageFallback(),
                )
              else
                const _DroneImageFallback(),

              Positioned.fill(
                child:
                DecoratedBox(
                  decoration:
                  BoxDecoration(
                    gradient:
                    LinearGradient(
                      begin:
                      Alignment.topCenter,
                      end:
                      Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        _ink.withOpacity(
                          0.02,
                        ),
                        _ink.withOpacity(
                          0.42,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child:
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration:
                      BoxDecoration(
                        color:
                        Colors.white.withOpacity(
                          0.92,
                        ),
                        shape:
                        BoxShape.circle,
                      ),
                      child:
                      const Icon(
                        Icons.add_a_photo_outlined,
                        color:
                        _tealDark,
                        size: 19,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child:
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Drone photo',
                            style:
                            TextStyle(
                              color:
                              Colors.white,
                              fontSize:
                              14,
                              fontWeight:
                              FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tap to choose or replace • max 10 MB',
                            style:
                            TextStyle(
                              color:
                              Colors.white70,
                              fontSize:
                              10,
                            ),
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
      ),
    );
  }
}

class _DroneImageFallback
    extends StatelessWidget {
  const _DroneImageFallback();

  @override
  Widget build(
      BuildContext context,
      ) {
    return const DecoratedBox(
      decoration:
      BoxDecoration(
        gradient:
        LinearGradient(
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
          colors: [
            Color(0xFFEAF7F7),
            Color(0xFFDCEFF2),
          ],
        ),
      ),
      child:
      Center(
        child:
        Icon(
          Icons.flight_takeoff_rounded,
          color:
          Color(0x55078B98),
          size: 84,
        ),
      ),
    );
  }
}

// ============================================================================
// SECTION CARD
// ============================================================================

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.number,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String number;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      const EdgeInsets.all(16),
      decoration:
      BoxDecoration(
        color:
        Colors.white,
        borderRadius:
        BorderRadius.circular(24),
        border:
        Border.all(
          color:
          _border,
        ),
        boxShadow: [
          BoxShadow(
            color:
            _ink.withOpacity(0.035),
            blurRadius:
            18,
            offset:
            const Offset(0, 7),
          ),
        ],
      ),
      child:
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 43,
                height: 43,
                decoration:
                BoxDecoration(
                  color:
                  _tealSoft,
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child:
                Icon(
                  icon,
                  color:
                  _tealDark,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style:
                      const TextStyle(
                        color:
                        _ink,
                        fontSize:
                        14.5,
                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style:
                      const TextStyle(
                        color:
                        _muted,
                        fontSize:
                        9.8,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                number,
                style:
                const TextStyle(
                  color:
                  _teal,
                  fontSize:
                  12,
                  fontWeight:
                  FontWeight.w900,
                  letterSpacing:
                  1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// ============================================================================
// INPUT
// ============================================================================

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.validator,
    this.keyboardType,
    this.suffix,
    this.prefixText,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final String? suffix;
  final String? prefixText;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Padding(
          padding:
          const EdgeInsets.only(
            left: 2,
            bottom: 7,
          ),
          child:
          Text(
            label,
            style:
            const TextStyle(
              color:
              _ink,
              fontSize:
              10.8,
              fontWeight:
              FontWeight.w700,
            ),
          ),
        ),
        TextFormField(
          controller:
          controller,
          validator:
          validator,
          keyboardType:
          keyboardType,
          textInputAction:
          TextInputAction.next,
          style:
          const TextStyle(
            color:
            _ink,
            fontSize:
            12.3,
            fontWeight:
            FontWeight.w600,
          ),
          decoration:
          InputDecoration(
            hintText:
            hint,
            hintStyle:
            const TextStyle(
              color:
              _hint,
              fontSize:
              11,
            ),
            prefixIcon:
            Icon(
              icon,
              color:
              _tealDark,
              size:
              18,
            ),
            prefixText:
            prefixText,
            suffixText:
            suffix,
            filled:
            true,
            fillColor:
            const Color(
              0xFFF8FAFC,
            ),
            enabledBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(15),
              borderSide:
              const BorderSide(
                color:
                _border,
              ),
            ),
            focusedBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(15),
              borderSide:
              const BorderSide(
                color:
                _teal,
                width:
                1.3,
              ),
            ),
            errorBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(15),
              borderSide:
              const BorderSide(
                color:
                _danger,
              ),
            ),
            focusedErrorBorder:
            OutlineInputBorder(
              borderRadius:
              BorderRadius.circular(15),
              borderSide:
              const BorderSide(
                color:
                _danger,
                width:
                1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SAVE BAR
// ============================================================================

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.editing,
    required this.saving,
    required this.onSave,
  });

  final bool editing;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      padding:
      EdgeInsets.fromLTRB(
        18,
        10,
        18,
        MediaQuery.paddingOf(context).bottom +
            10,
      ),
      decoration:
      BoxDecoration(
        color:
        Colors.white.withOpacity(0.97),
        border:
        const Border(
          top:
          BorderSide(
            color:
            _border,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withOpacity(0.04),
            blurRadius:
            18,
            offset:
            const Offset(0, -5),
          ),
        ],
      ),
      child:
      SizedBox(
        width:
        double.infinity,
        child:
        FilledButton.icon(
          onPressed:
          saving
              ? null
              : onSave,
          style:
          FilledButton.styleFrom(
            backgroundColor:
            _tealDark,
            foregroundColor:
            Colors.white,
            disabledBackgroundColor:
            _tealDark.withOpacity(0.55),
            padding:
            const EdgeInsets.symmetric(
              vertical:
              15,
            ),
            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(17),
            ),
          ),
          icon:
          saving
              ? const SizedBox(
            width: 19,
            height: 19,
            child:
            CircularProgressIndicator(
              strokeWidth: 2.2,
              color: Colors.white,
            ),
          )
              : Icon(
            editing
                ? Icons.save_outlined
                : Icons.add_rounded,
            size: 18,
          ),
          label:
          Text(
            saving
                ? 'Saving...'
                : editing
                ? 'Save Changes'
                : 'Add Drone',
            style:
            const TextStyle(
              fontWeight:
              FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _SourceButton
    extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(
      BuildContext context,
      ) {
    return OutlinedButton.icon(
      onPressed:
      onTap,
      style:
      OutlinedButton.styleFrom(
        foregroundColor:
        _tealDark,
        side:
        const BorderSide(
          color:
          _border,
        ),
        padding:
        const EdgeInsets.symmetric(
          vertical:
          14,
        ),
        shape:
        RoundedRectangleBorder(
          borderRadius:
          BorderRadius.circular(16),
        ),
      ),
      icon:
      Icon(
        icon,
        size:
        18,
      ),
      label:
      Text(
        title,
        style:
        const TextStyle(
          fontWeight:
          FontWeight.w700,
        ),
      ),
    );
  }
}

class _CapabilityOption {
  const _CapabilityOption({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;
}

double? _optionalDouble(
    String value,
    ) {
  final clean =
  value.trim();

  if (clean.isEmpty) {
    return null;
  }

  return double.tryParse(clean);
}

String _numberText(
    double? value,
    ) {
  if (value == null) return '';

  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}