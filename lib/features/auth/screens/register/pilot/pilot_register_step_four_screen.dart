import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../../core/navigation/bottom_navbar.dart';
import '../../../../../core/session/account_role_store.dart';
import '../../../../../core/theme/app_colors.dart';

// ============================================================================
// DOCUMENT TYPES
// ============================================================================

enum _PilotDocumentType {
  license,
  permit,
}

// ============================================================================
// SCREEN 4: Certifications & Documents
// ============================================================================

class PilotRegisterStepFourScreen extends StatefulWidget {
  const PilotRegisterStepFourScreen({
    super.key,
  });

  @override
  State<PilotRegisterStepFourScreen> createState() =>
      _PilotRegisterStepFourScreenState();
}

class _PilotRegisterStepFourScreenState
    extends State<PilotRegisterStepFourScreen>
    with TickerProviderStateMixin {
  // ==========================================================================
  // FORM
  // ==========================================================================

  final GlobalKey<FormState> _formKey =
  GlobalKey<FormState>();

  final TextEditingController _licenseNumberController =
  TextEditingController();

  final TextEditingController _expiryController =
  TextEditingController();

  // ==========================================================================
  // STATE
  // ==========================================================================

  String? _selectedLicenseType;
  String? _selectedIssuingAuthority;

  DateTime? _selectedExpiryDate;

  File? _licenseImage;
  File? _permitImage;

  _PilotDocumentType? _pickingDocument;

  bool _isSubmitting = false;
  bool _buttonPressed = false;

  bool _showLicenseUploadError = false;
  bool _showPermitUploadError = false;

  // ==========================================================================
  // UPLOAD PROGRESS
  // ==========================================================================

  final Map<_PilotDocumentType, double> _uploadProgress = {
    _PilotDocumentType.license: 0,
    _PilotDocumentType.permit: 0,
  };

  final Map<_PilotDocumentType, bool> _isUploading = {
    _PilotDocumentType.license: false,
    _PilotDocumentType.permit: false,
  };

  // ==========================================================================
  // PICKERS
  // ==========================================================================

  final ImagePicker _picker =
  ImagePicker();

  // ==========================================================================
  // OPTIONS
  // ==========================================================================

  final List<String> _licenseTypes = const [
    'Commercial UAS Pilot',
    'Recreational Drone Pilot',
    'Inspection Pilot',
    'Aerial Photography Pilot',
  ];

  final List<String> _issuingAuthorities = const [
    'CAA (Civil Aviation Authority)',
    'FAA',
    'CASA',
    'EASA',
    'GCAA',
    'Ministry of Transport',
    'DJI Academy',
  ];

  // ==========================================================================
  // COLORS
  // ==========================================================================

  static const Color kPrimary =
      AppColors.primary;

  static const Color kPrimarySoft =
      AppColors.blueBg;

  static const Color kTextDark =
      AppColors.text;

  static const Color kTextMuted =
      AppColors.grey;

  static const Color kHint =
      AppColors.lightGrey;

  static const Color kBorder =
      AppColors.border;

  static const Color kSurfaceSoft =
      AppColors.bg;

  static const Color kDanger =
      AppColors.red;

  static const Color kSuccess =
      AppColors.green;

  // ==========================================================================
  // ANIMATION
  // ==========================================================================

  late final AnimationController
  _pageAnimationController;

  // ==========================================================================
  // INIT
  // ==========================================================================

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
        Brightness.dark,
        statusBarBrightness:
        Brightness.light,
      ),
    );

    _pageAnimationController =
        AnimationController(
          vsync: this,
          duration:
          const Duration(
            milliseconds: 1100,
          ),
        );

    _pageAnimationController.forward();
  }

  // ==========================================================================
  // DISPOSE
  // ==========================================================================

  @override
  void dispose() {
    _licenseNumberController.dispose();
    _expiryController.dispose();

    _pageAnimationController.dispose();

    super.dispose();
  }

  // ==========================================================================
  // PAGE ENTRANCE
  // ==========================================================================

  Widget _animatedEntry({
    required int index,
    required Widget child,
  }) {
    final double start =
    (index * 0.065)
        .clamp(
      0.0,
      0.70,
    )
        .toDouble();

    final double end =
    (start + 0.32)
        .clamp(
      0.0,
      1.0,
    )
        .toDouble();

    final animation =
    CurvedAnimation(
      parent:
      _pageAnimationController,

      curve: Interval(
        start,
        end,
        curve:
        Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: animation,

      child: SlideTransition(
        position:
        Tween<Offset>(
          begin:
          const Offset(
            0,
            0.055,
          ),

          end: Offset.zero,
        ).animate(animation),

        child: child,
      ),
    );
  }

  // ==========================================================================
  // DOCUMENT HELPERS
  // ==========================================================================

  File? _documentFile(
      _PilotDocumentType document,
      ) {
    switch (document) {
      case _PilotDocumentType.license:
        return _licenseImage;

      case _PilotDocumentType.permit:
        return _permitImage;
    }
  }

  String _documentTitle(
      _PilotDocumentType document,
      ) {
    switch (document) {
      case _PilotDocumentType.license:
        return 'Pilot License Document';

      case _PilotDocumentType.permit:
        return 'Permit / Insurance Document';
    }
  }

  String _documentDescription(
      _PilotDocumentType document,
      ) {
    switch (document) {
      case _PilotDocumentType.license:
        return 'Upload your official pilot license or certification.';

      case _PilotDocumentType.permit:
        return 'Upload a valid permit or insurance document.';
    }
  }

  IconData _documentIcon(
      _PilotDocumentType document,
      ) {
    switch (document) {
      case _PilotDocumentType.license:
        return Icons.badge_outlined;

      case _PilotDocumentType.permit:
        return Icons.shield_outlined;
    }
  }

  void _setDocumentFile(
      _PilotDocumentType document,
      File? file,
      ) {
    switch (document) {
      case _PilotDocumentType.license:
        _licenseImage = file;

        if (file != null) {
          _showLicenseUploadError = false;
        }

        break;

      case _PilotDocumentType.permit:
        _permitImage = file;

        if (file != null) {
          _showPermitUploadError = false;
        }

        break;
    }
  }

  // ==========================================================================
  // SIMULATED UPLOAD
  // ==========================================================================

  Future<void> _simulateUpload(
      _PilotDocumentType document,
      ) async {
    if (!mounted) return;

    setState(() {
      _isUploading[document] = true;
      _uploadProgress[document] = 0;
    });

    const steps = 12;

    for (int i = 1; i <= steps; i++) {
      await Future.delayed(
        const Duration(
          milliseconds: 55,
        ),
      );

      if (!mounted) return;

      setState(() {
        _uploadProgress[document] =
            i / steps;
      });
    }

    if (!mounted) return;

    setState(() {
      _isUploading[document] = false;
    });

    HapticFeedback.lightImpact();
  }

  // ==========================================================================
  // PICK IMAGE
  // ==========================================================================

  Future<void> _pickDocumentImage(
      _PilotDocumentType document,
      ImageSource source,
      ) async {
    if (_pickingDocument != null ||
        _isSubmitting) {
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _pickingDocument = document;
    });

    try {
      final picked =
      await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (picked == null) {
        return;
      }

      final file =
      File(picked.path);

      if (!await file.exists()) {
        if (mounted) {
          _showSnack(
            'The selected file could not be found.',
            isError: true,
          );
        }

        return;
      }

      final size =
      await file.length();

      if (size >
          10 * 1024 * 1024) {
        if (mounted) {
          _showSnack(
            'Document must be smaller than 10 MB.',
            isError: true,
          );
        }

        return;
      }

      if (!mounted) return;

      setState(() {
        _setDocumentFile(
          document,
          file,
        );
      });

      await _simulateUpload(
        document,
      );
    } on PlatformException {
      if (!mounted) return;

      _showSnack(
        'Unable to open the image picker. Check app permissions.',
        isError: true,
      );
    } catch (_) {
      if (!mounted) return;

      _showSnack(
        'Unable to add this image. Please try another photo.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _pickingDocument = null;
        });
      }
    }
  }

  // ==========================================================================
  // PICK PDF / IMAGE FILE
  // ==========================================================================

  Future<void> _pickDocumentFile(
      _PilotDocumentType document,
      ) async {
    if (_pickingDocument != null ||
        _isSubmitting) {
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _pickingDocument = document;
    });

    try {
      final result =
      await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'pdf',
          'jpg',
          'jpeg',
          'png',
        ],
      );

      if (result == null ||
          result.files.single.path ==
              null) {
        return;
      }

      final file = File(
        result.files.single.path!,
      );

      if (!await file.exists()) {
        if (mounted) {
          _showSnack(
            'The selected file could not be found.',
            isError: true,
          );
        }

        return;
      }

      final size =
      await file.length();

      if (size >
          10 * 1024 * 1024) {
        if (mounted) {
          _showSnack(
            'Document must be smaller than 10 MB.',
            isError: true,
          );
        }

        return;
      }

      if (!mounted) return;

      setState(() {
        _setDocumentFile(
          document,
          file,
        );
      });

      await _simulateUpload(
        document,
      );
    } catch (_) {
      if (!mounted) return;

      _showSnack(
        'Unable to add this file. Please try again.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _pickingDocument = null;
        });
      }
    }
  }

  // ==========================================================================
  // DOCUMENT SOURCE SHEET
  // ==========================================================================

  void _showImageSourceActionSheet(
      _PilotDocumentType document,
      ) {
    if (_isSubmitting) return;

    HapticFeedback.lightImpact();

    showModalBottomSheet(
      context: context,

      backgroundColor:
      Colors.transparent,

      isScrollControlled: true,

      builder: (context) {
        final currentFile =
        _documentFile(document);

        return SafeArea(
          child: Container(
            decoration:
            const BoxDecoration(
              color: Colors.white,

              borderRadius:
              BorderRadius.vertical(
                top:
                Radius.circular(
                  28,
                ),
              ),
            ),

            padding:
            const EdgeInsets
                .fromLTRB(
              18,
              10,
              18,
              24,
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
                    color: kBorder,

                    borderRadius:
                    BorderRadius
                        .circular(
                      20,
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,

                      decoration:
                      BoxDecoration(
                        color: kPrimary
                            .withOpacity(
                          0.09,
                        ),

                        borderRadius:
                        BorderRadius
                            .circular(
                          12,
                        ),
                      ),

                      child: Icon(
                        _documentIcon(
                          document,
                        ),

                        color:
                        kPrimary,

                        size: 19,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                        children: [
                          Text(
                            _documentTitle(
                              document,
                            ),

                            style:
                            const TextStyle(
                              fontSize:
                              16,

                              fontWeight:
                              FontWeight
                                  .w800,

                              color:
                              kTextDark,
                            ),
                          ),

                          const SizedBox(
                            height: 2,
                          ),

                          Text(
                            _documentDescription(
                              document,
                            ),

                            style:
                            const TextStyle(
                              fontSize:
                              10.5,

                              color:
                              kTextMuted,
                            ),
                          ),
                        ],
                      ),
                    ),

                    IconButton(
                      onPressed: () {
                        Navigator.pop(
                          context,
                        );
                      },

                      icon:
                      const Icon(
                        Icons.close_rounded,

                        color: kHint,
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 18,
                ),

                _buildSheetOption(
                  icon: Icons
                      .camera_alt_rounded,

                  title:
                  'Take Photo',

                  subtitle:
                  'Use your device camera',

                  onTap: () {
                    Navigator.pop(
                      context,
                    );

                    _pickDocumentImage(
                      document,
                      ImageSource.camera,
                    );
                  },
                ),

                const SizedBox(
                  height: 10,
                ),

                _buildSheetOption(
                  icon: Icons
                      .photo_library_rounded,

                  title:
                  'Choose from Gallery',

                  subtitle:
                  'Select an image from your device',

                  onTap: () {
                    Navigator.pop(
                      context,
                    );

                    _pickDocumentImage(
                      document,
                      ImageSource.gallery,
                    );
                  },
                ),

                const SizedBox(
                  height: 10,
                ),

                _buildSheetOption(
                  icon: Icons
                      .picture_as_pdf_outlined,

                  title:
                  'Choose File',

                  subtitle:
                  'PDF, JPG or PNG · Max 10 MB',

                  onTap: () {
                    Navigator.pop(
                      context,
                    );

                    _pickDocumentFile(
                      document,
                    );
                  },
                ),

                if (currentFile !=
                    null) ...[
                  const SizedBox(
                    height: 10,
                  ),

                  _buildSheetOption(
                    icon: Icons
                        .delete_outline_rounded,

                    title:
                    'Remove Document',

                    subtitle:
                    'Delete the selected file',

                    destructive: true,

                    onTap: () {
                      Navigator.pop(
                        context,
                      );

                      HapticFeedback
                          .lightImpact();

                      setState(() {
                        _setDocumentFile(
                          document,
                          null,
                        );

                        _uploadProgress[
                        document] =
                        0;
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final color =
    destructive
        ? kDanger
        : kPrimary;

    return Material(
      color: destructive
          ? kDanger.withOpacity(
        0.05,
      )
          : kSurfaceSoft,

      borderRadius:
      BorderRadius.circular(
        16,
      ),

      child: InkWell(
        borderRadius:
        BorderRadius.circular(
          16,
        ),

        onTap: onTap,

        child: Padding(
          padding:
          const EdgeInsets
              .symmetric(
            horizontal: 14,
            vertical: 13,
          ),

          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,

                decoration:
                BoxDecoration(
                  color: color
                      .withOpacity(
                    0.10,
                  ),

                  borderRadius:
                  BorderRadius
                      .circular(
                    12,
                  ),
                ),

                child: Icon(
                  icon,

                  color: color,

                  size: 19,
                ),
              ),

              const SizedBox(
                width: 12,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

                  children: [
                    Text(
                      title,

                      style:
                      TextStyle(
                        color: destructive
                            ? color
                            : kTextDark,

                        fontSize:
                        13.5,

                        fontWeight:
                        FontWeight
                            .w700,
                      ),
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      subtitle,

                      style:
                      const TextStyle(
                        color:
                        kTextMuted,

                        fontSize:
                        10.5,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons
                    .chevron_right_rounded,

                color: color,

                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // EXPIRY DATE
  // ==========================================================================

  Future<void> _selectExpiryDate() async {
    if (_isSubmitting) return;

    HapticFeedback.selectionClick();

    final now =
    DateTime.now();

    final pickedDate =
    await showDatePicker(
      context: context,

      initialDate:
      _selectedExpiryDate ??
          now.add(
            const Duration(
              days: 365,
            ),
          ),

      firstDate: now,

      lastDate:
      DateTime(
        now.year + 15,
        12,
        31,
      ),

      builder: (
          context,
          child,
          ) {
        return Theme(
          data:
          Theme.of(context)
              .copyWith(
            colorScheme:
            const ColorScheme
                .light(
              primary:
              kPrimary,

              onPrimary:
              Colors.white,

              onSurface:
              kTextDark,
            ),
          ),

          child: child!,
        );
      },
    );

    if (pickedDate == null) {
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _selectedExpiryDate =
          pickedDate;

      _expiryController.text =
          DateFormat(
            'yyyy-MM-dd',
          ).format(
            pickedDate,
          );
    });
  }

  // ==========================================================================
  // SELECT SHEET
  // ==========================================================================

  Future<void> _openSelectSheet({
    required String title,
    required List<String> items,
    required String? selected,
    required ValueChanged<String?>
    onSelected,
    IconData icon =
        Icons.list_alt_rounded,
  }) async {
    HapticFeedback.lightImpact();

    await showModalBottomSheet(
      context: context,

      backgroundColor:
      Colors.transparent,

      isScrollControlled: true,

      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor:
            items.length > 5
                ? 0.75
                : 0.62,

            child: Container(
              decoration:
              const BoxDecoration(
                color: Colors.white,

                borderRadius:
                BorderRadius
                    .vertical(
                  top:
                  Radius.circular(
                    28,
                  ),
                ),
              ),

              child: Column(
                children: [
                  const SizedBox(
                    height: 10,
                  ),

                  Container(
                    width: 42,
                    height: 4,

                    decoration:
                    BoxDecoration(
                      color: kBorder,

                      borderRadius:
                      BorderRadius
                          .circular(
                        20,
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 18,
                  ),

                  Padding(
                    padding:
                    const EdgeInsets
                        .symmetric(
                      horizontal:
                      18,
                    ),

                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,

                            style:
                            const TextStyle(
                              fontSize:
                              18,

                              fontWeight:
                              FontWeight
                                  .w800,

                              color:
                              kTextDark,
                            ),
                          ),
                        ),

                        IconButton(
                          onPressed:
                              () {
                            Navigator.pop(
                              context,
                            );
                          },

                          icon:
                          const Icon(
                            Icons
                                .close_rounded,

                            color:
                            kHint,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Expanded(
                    child:
                    ListView.separated(
                      padding:
                      const EdgeInsets
                          .fromLTRB(
                        18,
                        0,
                        18,
                        18,
                      ),

                      itemCount:
                      items.length,

                      separatorBuilder:
                          (
                          context,
                          index,
                          ) {
                        return const SizedBox(
                          height: 8,
                        );
                      },

                      itemBuilder:
                          (
                          context,
                          index,
                          ) {
                        final item =
                        items[index];

                        final isSelected =
                            item ==
                                selected;

                        return Material(
                          color: isSelected
                              ? kPrimary
                              .withOpacity(
                            0.075,
                          )
                              : kSurfaceSoft,

                          borderRadius:
                          BorderRadius
                              .circular(
                            15,
                          ),

                          child: InkWell(
                            borderRadius:
                            BorderRadius
                                .circular(
                              15,
                            ),

                            onTap:
                                () {
                              HapticFeedback
                                  .selectionClick();

                              onSelected(
                                item,
                              );

                              Navigator.pop(
                                context,
                              );
                            },

                            child:
                            Container(
                              padding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal:
                                14,

                                vertical:
                                13,
                              ),

                              decoration:
                              BoxDecoration(
                                borderRadius:
                                BorderRadius
                                    .circular(
                                  15,
                                ),

                                border:
                                Border.all(
                                  color: isSelected
                                      ? kPrimary
                                      : Colors
                                      .transparent,
                                ),
                              ),

                              child:
                              Row(
                                children: [
                                  Container(
                                    width:
                                    34,

                                    height:
                                    34,

                                    decoration:
                                    BoxDecoration(
                                      color: isSelected
                                          ? kPrimary.withOpacity(
                                        0.10,
                                      )
                                          : Colors.white,

                                      borderRadius:
                                      BorderRadius.circular(
                                        10,
                                      ),
                                    ),

                                    child:
                                    Icon(
                                      icon,

                                      size:
                                      17,

                                      color: isSelected
                                          ? kPrimary
                                          : kHint,
                                    ),
                                  ),

                                  const SizedBox(
                                    width:
                                    12,
                                  ),

                                  Expanded(
                                    child:
                                    Text(
                                      item,

                                      maxLines:
                                      2,

                                      overflow:
                                      TextOverflow.ellipsis,

                                      style:
                                      TextStyle(
                                        fontSize:
                                        13,

                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,

                                        color: isSelected
                                            ? kPrimary
                                            : kTextDark,
                                      ),
                                    ),
                                  ),

                                  AnimatedSwitcher(
                                    duration:
                                    const Duration(
                                      milliseconds:
                                      180,
                                    ),

                                    child: isSelected
                                        ? const Icon(
                                      Icons.check_circle_rounded,

                                      key: ValueKey(
                                        'selected',
                                      ),

                                      color:
                                      kPrimary,

                                      size:
                                      20,
                                    )
                                        : const SizedBox(
                                      key: ValueKey(
                                        'not-selected',
                                      ),

                                      width:
                                      20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // SUBMIT
  // ==========================================================================

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    FocusScope.of(context).unfocus();

    bool isValid =
        _formKey.currentState
            ?.validate() ??
            false;

    if (_licenseImage == null) {
      setState(() {
        _showLicenseUploadError =
        true;
      });

      isValid = false;
    }

    // Permit is also required now
    if (_permitImage == null) {
      setState(() {
        _showPermitUploadError =
        true;
      });

      isValid = false;
    }

    if (!isValid) {
      HapticFeedback.heavyImpact();

      if (_licenseImage ==
          null &&
          _permitImage ==
              null) {
        _showSnack(
          'Please upload both required documents.',
          isError: true,
        );
      } else if (_licenseImage ==
          null) {
        _showSnack(
          'Please upload your pilot license document.',
          isError: true,
        );
      } else if (_permitImage ==
          null) {
        _showSnack(
          'Please upload your permit or insurance document.',
          isError: true,
        );
      } else {
        _showSnack(
          'Please complete all required fields.',
          isError: true,
        );
      }

      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // UI loading only - NO API
    await Future.delayed(
      const Duration(
        milliseconds: 850,
      ),
    );

    if (!mounted) return;

    await AccountRoleStore.instance
        .setRole(
      AccountRole.pilot,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    HapticFeedback.mediumImpact();

    _showCompletionSuccessDialog();
  }

  // ==========================================================================
  // SUCCESS DIALOG
  // ==========================================================================

  void _showCompletionSuccessDialog() {
    showGeneralDialog(
      context: context,

      barrierDismissible: false,

      barrierLabel:
      'Registration Complete',

      barrierColor:
      Colors.black.withOpacity(
        0.46,
      ),

      transitionDuration:
      const Duration(
        milliseconds: 420,
      ),

      pageBuilder: (
          context,
          animation,
          secondaryAnimation,
          ) {
        return const SizedBox.shrink();
      },

      transitionBuilder: (
          context,
          animation,
          secondaryAnimation,
          child,
          ) {
        final curved =
        CurvedAnimation(
          parent: animation,

          curve:
          Curves.easeOutBack,
        );

        return FadeTransition(
          opacity: animation,

          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.86,
              end: 1,
            ).animate(
              curved,
            ),

            child: Center(
              child: Material(
                color:
                Colors.transparent,

                child: Container(
                  width:
                  double.infinity,

                  constraints:
                  const BoxConstraints(
                    maxWidth: 390,
                  ),

                  margin:
                  const EdgeInsets
                      .symmetric(
                    horizontal: 24,
                  ),

                  padding:
                  const EdgeInsets
                      .fromLTRB(
                    24,
                    28,
                    24,
                    22,
                  ),

                  decoration:
                  BoxDecoration(
                    color:
                    Colors.white,

                    borderRadius:
                    BorderRadius
                        .circular(
                      28,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color:
                        Colors.black.withOpacity(
                          0.15,
                        ),

                        blurRadius:
                        35,

                        offset:
                        const Offset(
                          0,
                          15,
                        ),
                      ),
                    ],
                  ),

                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,

                    children: [
                      // =========================================
                      // SUCCESS ICON
                      // =========================================

                      Stack(
                        alignment:
                        Alignment.center,

                        children: [
                          Container(
                            width: 94,
                            height: 94,

                            decoration:
                            BoxDecoration(
                              shape:
                              BoxShape.circle,

                              color: kPrimary
                                  .withOpacity(
                                0.06,
                              ),
                            ),
                          ),

                          Container(
                            width: 72,
                            height: 72,

                            decoration:
                            BoxDecoration(
                              shape:
                              BoxShape.circle,

                              gradient:
                              const LinearGradient(
                                begin:
                                Alignment.topLeft,

                                end:
                                Alignment.bottomRight,

                                colors: [
                                  Color(
                                    0xFF18B99F,
                                  ),

                                  kPrimary,
                                ],
                              ),

                              boxShadow: [
                                BoxShadow(
                                  color: kPrimary
                                      .withOpacity(
                                    0.25,
                                  ),

                                  blurRadius:
                                  18,

                                  offset:
                                  const Offset(
                                    0,
                                    7,
                                  ),
                                ),
                              ],
                            ),

                            child:
                            const Icon(
                              Icons
                                  .verified_user_rounded,

                              color:
                              Colors.white,

                              size:
                              34,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      const Text(
                        'Registration Submitted!',

                        textAlign:
                        TextAlign.center,

                        style:
                        TextStyle(
                          fontSize: 20,

                          fontWeight:
                          FontWeight
                              .w800,

                          letterSpacing:
                          -0.3,

                          color:
                          kTextDark,
                        ),
                      ),

                      const SizedBox(
                        height: 9,
                      ),

                      const Text(
                        'Your pilot profile and documents have been submitted for verification.',

                        textAlign:
                        TextAlign.center,

                        style:
                        TextStyle(
                          fontSize: 13,

                          height: 1.5,

                          color:
                          kTextMuted,
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      // =========================================
                      // REVIEW STATUS
                      // =========================================

                      Container(
                        width:
                        double.infinity,

                        padding:
                        const EdgeInsets
                            .symmetric(
                          horizontal: 14,

                          vertical: 12,
                        ),

                        decoration:
                        BoxDecoration(
                          color: kPrimary
                              .withOpacity(
                            0.06,
                          ),

                          borderRadius:
                          BorderRadius
                              .circular(
                            15,
                          ),

                          border:
                          Border.all(
                            color: kPrimary
                                .withOpacity(
                              0.10,
                            ),
                          ),
                        ),

                        child:
                        const Row(
                          children: [
                            Icon(
                              Icons
                                  .schedule_rounded,

                              color:
                              kPrimary,

                              size:
                              18,
                            ),

                            SizedBox(
                              width: 9,
                            ),

                            Expanded(
                              child:
                              Text(
                                'Status: Pending verification',

                                style:
                                TextStyle(
                                  fontSize:
                                  12.5,

                                  fontWeight:
                                  FontWeight
                                      .w600,

                                  color:
                                  kPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 22,
                      ),

                      // =========================================
                      // DONE BUTTON
                      // =========================================

                      Container(
                        width:
                        double.infinity,

                        height: 50,

                        decoration:
                        BoxDecoration(
                          borderRadius:
                          BorderRadius
                              .circular(
                            25,
                          ),

                          gradient:
                          const LinearGradient(
                            begin:
                            Alignment.centerLeft,

                            end:
                            Alignment.centerRight,

                            colors: [
                              Color(
                                0xFF0D8AA5,
                              ),

                              kPrimary,
                            ],
                          ),

                          boxShadow: [
                            BoxShadow(
                              color: kPrimary
                                  .withOpacity(
                                0.22,
                              ),

                              blurRadius:
                              16,

                              offset:
                              const Offset(
                                0,
                                6,
                              ),
                            ),
                          ],
                        ),

                        child:
                        ElevatedButton(
                          onPressed:
                              () {
                            Navigator.of(
                              context,

                              rootNavigator:
                              true,
                            ).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                const MyScreen(),
                              ),

                                  (route) =>
                              false,
                            );
                          },

                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            Colors.transparent,

                            shadowColor:
                            Colors.transparent,

                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                25,
                              ),
                            ),
                          ),

                          child:
                          const Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .center,

                            children: [
                              Text(
                                'Done',

                                style:
                                TextStyle(
                                  color:
                                  Colors.white,

                                  fontSize:
                                  14.5,

                                  fontWeight:
                                  FontWeight
                                      .w700,
                                ),
                              ),

                              SizedBox(
                                width:
                                7,
                              ),

                              Icon(
                                Icons
                                    .arrow_forward_rounded,

                                color:
                                Colors.white,

                                size:
                                17,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ==========================================================================
  // SNACK
  // ==========================================================================

  void _showSnack(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior:
          SnackBarBehavior.floating,

          elevation: 8,

          margin:
          const EdgeInsets.all(
            18,
          ),

          backgroundColor:
          isError
              ? const Color(
            0xFFE95C67,
          )
              : const Color(
            0xFF168F8A,
          ),

          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              16,
            ),
          ),

          content: Row(
            children: [
              Container(
                width: 34,
                height: 34,

                decoration:
                BoxDecoration(
                  color: Colors.white
                      .withOpacity(
                    0.15,
                  ),

                  shape:
                  BoxShape.circle,
                ),

                child: Icon(
                  isError
                      ? Icons
                      .error_outline_rounded
                      : Icons
                      .check_rounded,

                  color:
                  Colors.white,

                  size: 20,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child: Text(
                  message,

                  style:
                  const TextStyle(
                    color:
                    Colors.white,

                    fontSize:
                    12.5,

                    fontWeight:
                    FontWeight.w600,

                    height:
                    1.3,
                  ),
                ),
              ),
            ],
          ),
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
      backgroundColor:
      const Color(
        0xFFF8FAFB,
      ),

      body: Stack(
        children: [
          // ==================================================================
          // BACKGROUND
          // ==================================================================

          Positioned(
            top: -125,
            right: -105,

            child: IgnorePointer(
              child: Container(
                width: 285,
                height: 285,

                decoration:
                BoxDecoration(
                  shape:
                  BoxShape.circle,

                  gradient:
                  RadialGradient(
                    colors: [
                      kPrimary
                          .withOpacity(
                        0.12,
                      ),

                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          Positioned(
            top: 560,
            left: -160,

            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,

                decoration:
                BoxDecoration(
                  shape:
                  BoxShape.circle,

                  gradient:
                  RadialGradient(
                    colors: [
                      const Color(
                        0xFF0D8AA5,
                      ).withOpacity(
                        0.045,
                      ),

                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ==================================================================
          // CONTENT
          // ==================================================================

          SafeArea(
            child: LayoutBuilder(
              builder: (
                  context,
                  constraints,
                  ) {
                return SingleChildScrollView(
                  physics:
                  const BouncingScrollPhysics(),

                  keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior
                      .onDrag,

                  padding:
                  const EdgeInsets.fromLTRB(
                    20,
                    16,
                    20,
                    34,
                  ),

                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                      const BoxConstraints(
                        maxWidth: 560,
                      ),

                      child: Form(
                        key: _formKey,

                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [
                            // ================================================
                            // HEADER
                            // ================================================

                            _animatedEntry(
                              index: 0,

                              child:
                              _buildHeader(),
                            ),

                            const SizedBox(
                              height: 26,
                            ),

                            // ================================================
                            // BADGE
                            // ================================================

                            _animatedEntry(
                              index: 1,

                              child:
                              _buildCertificationBadge(),
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            // ================================================
                            // TITLE
                            // ================================================

                            _animatedEntry(
                              index: 2,

                              child:
                              const Text(
                                'Certifications &\nDocuments',

                                style:
                                TextStyle(
                                  fontSize:
                                  27,

                                  fontWeight:
                                  FontWeight
                                      .w800,

                                  color:
                                  kTextDark,

                                  letterSpacing:
                                  -0.6,

                                  height:
                                  1.15,
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 7,
                            ),

                            _animatedEntry(
                              index: 3,

                              child:
                              const Text(
                                'Add your pilot certification details and upload the required documents for verification.',

                                style:
                                TextStyle(
                                  fontSize:
                                  13.5,

                                  color:
                                  kTextMuted,

                                  fontWeight:
                                  FontWeight
                                      .w400,

                                  height:
                                  1.5,
                                ),
                              ),
                            ),

                            const SizedBox(
                              height: 31,
                            ),

                            // ================================================
                            // LICENSE INFORMATION
                            // ================================================

                            _animatedEntry(
                              index: 4,

                              child:
                              _buildSectionHeader(
                                icon: Icons
                                    .card_membership_rounded,

                                title:
                                'License Information',

                                subtitle:
                                'Official pilot certification details',
                              ),
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            _animatedEntry(
                              index: 5,

                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,

                                children: [
                                  // License Type
                                  _buildSmallLabel(
                                    'License Type',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  _buildSelectField(
                                    hintText:
                                    'Select License Type',

                                    icon: Icons
                                        .card_membership_rounded,

                                    value:
                                    _selectedLicenseType,

                                    items:
                                    _licenseTypes,

                                    onChanged:
                                        (value) {
                                      setState(
                                            () {
                                          _selectedLicenseType =
                                              value;
                                        },
                                      );
                                    },

                                    sheetIcon: Icons
                                        .workspace_premium_outlined,
                                  ),

                                  const SizedBox(
                                    height: 18,
                                  ),

                                  // License Number
                                  _buildSmallLabel(
                                    'License / Certification Number',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  _buildTextField(
                                    controller:
                                    _licenseNumberController,

                                    hintText:
                                    'e.g. C-129384910',

                                    prefixIcon:
                                    Icons
                                        .badge_outlined,

                                    textInputAction:
                                    TextInputAction.next,

                                    validator:
                                        (value) {
                                      if (value ==
                                          null ||
                                          value
                                              .trim()
                                              .isEmpty) {
                                        return 'License number is required';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(
                                    height: 18,
                                  ),

                                  // Authority
                                  _buildSmallLabel(
                                    'Issuing Authority',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  _buildSelectField(
                                    hintText:
                                    'Select Issuing Authority',

                                    icon: Icons
                                        .account_balance_outlined,

                                    value:
                                    _selectedIssuingAuthority,

                                    items:
                                    _issuingAuthorities,

                                    onChanged:
                                        (value) {
                                      setState(
                                            () {
                                          _selectedIssuingAuthority =
                                              value;
                                        },
                                      );
                                    },

                                    sheetIcon: Icons
                                        .account_balance_rounded,
                                  ),

                                  const SizedBox(
                                    height: 18,
                                  ),

                                  // Expiration
                                  _buildSmallLabel(
                                    'License Expiration Date',
                                  ),

                                  const SizedBox(
                                    height: 8,
                                  ),

                                  _buildTextField(
                                    controller:
                                    _expiryController,

                                    hintText:
                                    'Select Expiration Date',

                                    prefixIcon: Icons
                                        .calendar_today_rounded,

                                    readOnly:
                                    true,

                                    onTap:
                                    _selectExpiryDate,

                                    suffixIcon:
                                    const Icon(
                                      Icons
                                          .keyboard_arrow_down_rounded,

                                      size: 20,

                                      color:
                                      kHint,
                                    ),

                                    validator:
                                        (value) {
                                      if (value ==
                                          null ||
                                          value
                                              .trim()
                                              .isEmpty) {
                                        return 'Expiration date is required';
                                      }

                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 32,
                            ),

                            // ================================================
                            // DOCUMENTS
                            // ================================================

                            _animatedEntry(
                              index: 6,

                              child:
                              _buildSectionHeader(
                                icon: Icons
                                    .folder_copy_outlined,

                                title:
                                'Verification Documents',

                                subtitle:
                                'Upload clear and valid documents',
                              ),
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            _animatedEntry(
                              index: 7,

                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,

                                children: [
                                  _buildDocumentHeading(
                                    icon: Icons
                                        .badge_outlined,

                                    title:
                                    'Pilot License',

                                    required:
                                    true,
                                  ),

                                  const SizedBox(
                                    height: 9,
                                  ),

                                  _buildDocumentUploadCard(
                                    documentType:
                                    _PilotDocumentType.license,

                                    showError:
                                    _showLicenseUploadError,
                                  ),

                                  const SizedBox(
                                    height: 22,
                                  ),

                                  _buildDocumentHeading(
                                    icon: Icons
                                        .shield_outlined,

                                    title:
                                    'Permit / Insurance',

                                    required:
                                    true,
                                  ),

                                  const SizedBox(
                                    height: 9,
                                  ),

                                  _buildDocumentUploadCard(
                                    documentType:
                                    _PilotDocumentType.permit,

                                    showError:
                                    _showPermitUploadError,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 30,
                            ),

                            // ================================================
                            // COMPLETE BUTTON
                            // ================================================

                            _animatedEntry(
                              index: 8,

                              child:
                              _buildPrimaryButton(
                                text:
                                'Complete Registration',

                                isLoading:
                                _isSubmitting,

                                onPressed:
                                _isSubmitting
                                    ? null
                                    : _handleSubmit,
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            _animatedEntry(
                              index: 9,

                              child:
                              _buildBottomNote(),
                            ),

                            const SizedBox(
                              height: 8,
                            ),
                          ],
                        ),
                      ),
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

  // ==========================================================================
  // HEADER
  // ==========================================================================

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            _buildBackButton(),

            const Spacer(),

            Container(
              padding:
              const EdgeInsets.symmetric(
                horizontal: 11,
                vertical: 6,
              ),

              decoration:
              BoxDecoration(
                color: Colors.white,

                borderRadius:
                BorderRadius.circular(
                  20,
                ),

                border:
                Border.all(
                  color: kBorder,
                ),
              ),

              child: const Text(
                'STEP 4 OF 4',

                style: TextStyle(
                  fontSize: 10,

                  letterSpacing:
                  0.5,

                  fontWeight:
                  FontWeight.w700,

                  color:
                  kTextMuted,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(
          height: 15,
        ),

        Row(
          children:
          List.generate(
            4,
                (index) {
              // all completed because current is step 4
              const active = true;

              return Expanded(
                child: Padding(
                  padding:
                  EdgeInsets.only(
                    right:
                    index == 3
                        ? 0
                        : 6,
                  ),

                  child:
                  AnimatedContainer(
                    duration:
                    const Duration(
                      milliseconds:
                      450,
                    ),

                    curve:
                    Curves.easeOutCubic,

                    height:
                    4,

                    decoration:
                    BoxDecoration(
                      color: active
                          ? kPrimary
                          : kBorder,

                      borderRadius:
                      BorderRadius.circular(
                        20,
                      ),

                      boxShadow:
                      active
                          ? [
                        BoxShadow(
                          color: kPrimary.withOpacity(
                            0.18,
                          ),

                          blurRadius:
                          7,
                        ),
                      ]
                          : [],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // BADGE
  // ==========================================================================

  Widget _buildCertificationBadge() {
    return Container(
      padding:
      const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 6,
      ),

      decoration:
      BoxDecoration(
        color:
        kPrimary.withOpacity(
          0.085,
        ),

        borderRadius:
        BorderRadius.circular(
          20,
        ),
      ),

      child: const Row(
        mainAxisSize:
        MainAxisSize.min,

        children: [
          Icon(
            Icons
                .verified_user_outlined,

            color:
            kPrimary,

            size:
            14,
          ),

          SizedBox(
            width:
            6,
          ),

          Text(
            'FINAL VERIFICATION',

            style: TextStyle(
              color:
              kPrimary,

              fontSize:
              10,

              fontWeight:
              FontWeight.w700,

              letterSpacing:
              0.65,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // SECTION HEADER
  // ==========================================================================

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,

          decoration:
          BoxDecoration(
            color: kPrimary
                .withOpacity(
              0.09,
            ),

            borderRadius:
            BorderRadius.circular(
              11,
            ),
          ),

          child: Icon(
            icon,

            color:
            kPrimary,

            size:
            18,
          ),
        ),

        const SizedBox(
          width:
          11,
        ),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style:
                const TextStyle(
                  color:
                  kTextDark,

                  fontSize:
                  15,

                  fontWeight:
                  FontWeight.w700,
                ),
              ),

              const SizedBox(
                height:
                2,
              ),

              Text(
                subtitle,

                maxLines:
                2,

                style:
                const TextStyle(
                  color:
                  kTextMuted,

                  fontSize:
                  10.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallLabel(
      String label,
      ) {
    return Text(
      label,

      style:
      const TextStyle(
        color:
        kTextDark,

        fontSize:
        12.5,

        fontWeight:
        FontWeight.w700,
      ),
    );
  }

  Widget _buildDocumentHeading({
    required IconData icon,
    required String title,
    required bool required,
  }) {
    return Row(
      children: [
        Icon(
          icon,

          color:
          kPrimary,

          size:
          16,
        ),

        const SizedBox(
          width:
          7,
        ),

        Expanded(
          child: Text(
            title,

            style:
            const TextStyle(
              color:
              kTextDark,

              fontSize:
              12.5,

              fontWeight:
              FontWeight.w700,
            ),
          ),
        ),

        if (required)
          Container(
            padding:
            const EdgeInsets.symmetric(
              horizontal:
              8,

              vertical:
              4,
            ),

            decoration:
            BoxDecoration(
              color: kDanger
                  .withOpacity(
                0.07,
              ),

              borderRadius:
              BorderRadius.circular(
                20,
              ),
            ),

            child:
            const Text(
              'Required',

              style:
              TextStyle(
                color:
                kDanger,

                fontSize:
                9.5,

                fontWeight:
                FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  // ==========================================================================
  // BACK
  // ==========================================================================

  Widget _buildBackButton() {
    return Material(
      color:
      Colors.transparent,

      child: InkWell(
        borderRadius:
        BorderRadius.circular(
          50,
        ),

        onTap: _isSubmitting
            ? null
            : () {
          HapticFeedback
              .selectionClick();

          Navigator.pop(
            context,
          );
        },

        child: Container(
          width: 38,
          height: 38,

          decoration:
          BoxDecoration(
            color:
            Colors.white,

            shape:
            BoxShape.circle,

            border:
            Border.all(
              color: Colors.black
                  .withOpacity(
                0.045,
              ),
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withOpacity(
                  0.035,
                ),

                blurRadius:
                9,

                offset:
                const Offset(
                  0,
                  3,
                ),
              ),
            ],
          ),

          child:
          const Icon(
            Icons
                .arrow_back_ios_new_rounded,

            size:
            13,

            color:
            kTextDark,
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // DOCUMENT UPLOAD CARD
  // ==========================================================================

  Widget _buildDocumentUploadCard({
    required _PilotDocumentType documentType,
    required bool showError,
  }) {
    final file =
    _documentFile(
      documentType,
    );

    final isPicking =
        _pickingDocument ==
            documentType;

    final isUploading =
        _isUploading[
        documentType] ??
            false;

    final progress =
        _uploadProgress[
        documentType] ??
            0;

    final isImage =
        file != null &&
            [
              '.jpg',
              '.jpeg',
              '.png',
            ].any(
                  (extension) =>
                  file.path
                      .toLowerCase()
                      .endsWith(
                    extension,
                  ),
            );

    final hasFile =
        file != null;

    return GestureDetector(
      onTap: isUploading
          ? null
          : () {
        _showImageSourceActionSheet(
          documentType,
        );
      },

      child: AnimatedContainer(
        duration:
        const Duration(
          milliseconds:
          250,
        ),

        curve:
        Curves.easeOutCubic,

        width:
        double.infinity,

        padding:
        const EdgeInsets.all(
          14,
        ),

        decoration:
        BoxDecoration(
          color: showError
              ? kDanger
              .withOpacity(
            0.025,
          )
              : hasFile
              ? kPrimary
              .withOpacity(
            0.045,
          )
              : Colors.white,

          borderRadius:
          BorderRadius.circular(
            17,
          ),

          border:
          Border.all(
            color: showError
                ? kDanger
                : hasFile
                ? kPrimary
                .withOpacity(
              0.45,
            )
                : kBorder,

            width: showError
                ? 1.2
                : hasFile
                ? 1.1
                : 0.8,
          ),

          boxShadow: hasFile
              ? [
            BoxShadow(
              color: kPrimary
                  .withOpacity(
                0.055,
              ),

              blurRadius:
              14,

              offset:
              const Offset(
                0,
                5,
              ),
            ),
          ]
              : [],
        ),

        child: !hasFile &&
            !isPicking
            ? Column(
          children: [
            Container(
              width: 50,
              height: 50,

              decoration:
              BoxDecoration(
                color: showError
                    ? kDanger
                    .withOpacity(
                  0.08,
                )
                    : kPrimary
                    .withOpacity(
                  0.08,
                ),

                shape:
                BoxShape.circle,
              ),

              child: Icon(
                Icons
                    .cloud_upload_outlined,

                color: showError
                    ? kDanger
                    : kPrimary,

                size:
                23,
              ),
            ),

            const SizedBox(
              height:
              11,
            ),

            Text(
              'Tap to upload document',

              style:
              TextStyle(
                fontSize:
                13,

                fontWeight:
                FontWeight.w700,

                color: showError
                    ? kDanger
                    : kTextDark,
              ),
            ),

            const SizedBox(
              height:
              3,
            ),

            const Text(
              'Camera, Gallery or File',

              style:
              TextStyle(
                color:
                kTextMuted,

                fontSize:
                10.5,
              ),
            ),

            const SizedBox(
              height:
              2,
            ),

            const Text(
              'JPG, PNG or PDF · Max 10 MB',

              style:
              TextStyle(
                color:
                kHint,

                fontSize:
                10,
              ),
            ),

            if (showError) ...[
              const SizedBox(
                height:
                8,
              ),

              const Text(
                'This document is required',

                style:
                TextStyle(
                  color:
                  kDanger,

                  fontSize:
                  10.5,

                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ],
          ],
        )
            : Row(
          children: [
            // Thumbnail
            Container(
              width:
              54,

              height:
              54,

              clipBehavior:
              Clip.antiAlias,

              decoration:
              BoxDecoration(
                color:
                Colors.white,

                borderRadius:
                BorderRadius.circular(
                  13,
                ),

                border:
                Border.all(
                  color:
                  kBorder,
                ),
              ),

              child: isPicking
                  ? const Center(
                child:
                SizedBox(
                  width:
                  19,

                  height:
                  19,

                  child:
                  CircularProgressIndicator(
                    color:
                    kPrimary,

                    strokeWidth:
                    2,
                  ),
                ),
              )
                  : isImage
                  ? Image.file(
                file!,

                fit:
                BoxFit.cover,
              )
                  : const Icon(
                Icons.picture_as_pdf_rounded,

                color:
                kPrimary,

                size:
                25,
              ),
            ),

            const SizedBox(
              width:
              12,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Text(
                    isPicking
                        ? 'Preparing file...'
                        : file!.path
                        .split('/')
                        .last,

                    maxLines:
                    1,

                    overflow:
                    TextOverflow.ellipsis,

                    style:
                    const TextStyle(
                      color:
                      kTextDark,

                      fontSize:
                      12.5,

                      fontWeight:
                      FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height:
                    6,
                  ),

                  if (isUploading)
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,

                      children: [
                        ClipRRect(
                          borderRadius:
                          BorderRadius.circular(
                            20,
                          ),

                          child:
                          LinearProgressIndicator(
                            value:
                            progress,

                            minHeight:
                            5,

                            backgroundColor:
                            kBorder,

                            valueColor:
                            const AlwaysStoppedAnimation<Color>(
                              kPrimary,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height:
                          4,
                        ),

                        Text(
                          'Uploading ${(progress * 100).round()}%',

                          style:
                          const TextStyle(
                            color:
                            kTextMuted,

                            fontSize:
                            10,
                          ),
                        ),
                      ],
                    )
                  else if (!isPicking)
                    const Row(
                      children: [
                        Icon(
                          Icons
                              .check_circle_rounded,

                          size:
                          14,

                          color:
                          kSuccess,
                        ),

                        SizedBox(
                          width:
                          4,
                        ),

                        Text(
                          'Uploaded',

                          style:
                          TextStyle(
                            color:
                            kSuccess,

                            fontSize:
                            11,

                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            if (!isPicking &&
                !isUploading)
              Container(
                width:
                34,

                height:
                34,

                decoration:
                BoxDecoration(
                  color: kPrimary
                      .withOpacity(
                    0.07,
                  ),

                  shape:
                  BoxShape.circle,
                ),

                child:
                const Icon(
                  Icons
                      .more_horiz_rounded,

                  color:
                  kPrimary,

                  size:
                  19,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // TEXT FIELD
  // ==========================================================================

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType keyboardType =
        TextInputType.text,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller:
      controller,

      enabled:
      !_isSubmitting ||
          readOnly,

      readOnly:
      readOnly,

      onTap:
      onTap,

      keyboardType:
      keyboardType,

      textInputAction:
      textInputAction,

      validator:
      validator,

      autovalidateMode:
      AutovalidateMode
          .onUserInteraction,

      style:
      const TextStyle(
        color:
        kTextDark,

        fontSize:
        13.5,

        fontWeight:
        FontWeight.w500,
      ),

      decoration:
      InputDecoration(
        hintText:
        hintText,

        hintStyle:
        const TextStyle(
          color:
          kHint,

          fontSize:
          13,

          fontWeight:
          FontWeight.w400,
        ),

        prefixIcon:
        prefixIcon == null
            ? null
            : Icon(
          prefixIcon,

          color:
          kHint,

          size:
          18,
        ),

        suffixIcon:
        suffixIcon,

        filled:
        true,

        fillColor:
        Colors.white,

        contentPadding:
        const EdgeInsets
            .symmetric(
          horizontal:
          14,

          vertical:
          15,
        ),

        errorStyle:
        const TextStyle(
          color:
          kDanger,

          fontSize:
          10.5,

          height:
          1.2,
        ),

        border:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            15,
          ),

          borderSide:
          const BorderSide(
            color:
            kBorder,

            width:
            0.8,
          ),
        ),

        enabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            15,
          ),

          borderSide:
          const BorderSide(
            color:
            kBorder,

            width:
            0.8,
          ),
        ),

        focusedBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            15,
          ),

          borderSide:
          const BorderSide(
            color:
            kPrimary,

            width:
            1.4,
          ),
        ),

        errorBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            15,
          ),

          borderSide:
          const BorderSide(
            color:
            kDanger,

            width:
            1,
          ),
        ),

        focusedErrorBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            15,
          ),

          borderSide:
          const BorderSide(
            color:
            kDanger,

            width:
            1.3,
          ),
        ),

        disabledBorder:
        OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(
            15,
          ),

          borderSide:
          const BorderSide(
            color:
            kBorder,

            width:
            0.8,
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // SELECT FIELD
  // ==========================================================================

  Widget _buildSelectField({
    required String hintText,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData sheetIcon,
  }) {
    return FormField<String>(
      validator: (_) {
        if (value == null ||
            value.isEmpty) {
          return 'Selection is required';
        }

        return null;
      },

      builder: (state) {
        final hasValue =
            value != null &&
                value.isNotEmpty;

        return InkWell(
          borderRadius:
          BorderRadius.circular(
            15,
          ),

          onTap: _isSubmitting
              ? null
              : () {
            _openSelectSheet(
              title:
              hintText,

              items:
              items,

              selected:
              value,

              icon:
              sheetIcon,

              onSelected:
                  (
                  selectedValue,
                  ) {
                onChanged(
                  selectedValue,
                );

                state.didChange(
                  selectedValue,
                );
              },
            );
          },

          child: Container(
            width:
            double.infinity,

            padding:
            const EdgeInsets
                .symmetric(
              horizontal:
              14,

              vertical:
              14,
            ),

            decoration:
            BoxDecoration(
              color:
              Colors.white,

              borderRadius:
              BorderRadius.circular(
                15,
              ),

              border:
              Border.all(
                color: state.hasError
                    ? kDanger
                    : kBorder,

                width: state.hasError
                    ? 1
                    : 0.8,
              ),
            ),

            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Row(
                  children: [
                    Icon(
                      icon,

                      color: hasValue
                          ? kPrimary
                          : kHint,

                      size:
                      18,
                    ),

                    const SizedBox(
                      width:
                      10,
                    ),

                    Expanded(
                      child: Text(
                        value ??
                            hintText,

                        maxLines:
                        2,

                        overflow:
                        TextOverflow.ellipsis,

                        style:
                        TextStyle(
                          color: hasValue
                              ? kTextDark
                              : kHint,

                          fontSize:
                          13.5,

                          fontWeight: hasValue
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),

                    const Icon(
                      Icons
                          .keyboard_arrow_down_rounded,

                      color:
                      kHint,

                      size:
                      20,
                    ),
                  ],
                ),

                if (state.hasError)
                  Padding(
                    padding:
                    const EdgeInsets.only(
                      top:
                      7,

                      left:
                      28,
                    ),

                    child: Text(
                      state.errorText!,

                      style:
                      const TextStyle(
                        color:
                        kDanger,

                        fontSize:
                        10.5,
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

  // ==========================================================================
  // PRIMARY BUTTON
  // ==========================================================================

  Widget _buildPrimaryButton({
    required String text,
    required VoidCallback? onPressed,
    bool isLoading = false,
  }) {
    return Listener(
      onPointerDown: (_) {
        if (onPressed != null &&
            !isLoading) {
          setState(() {
            _buttonPressed = true;
          });
        }
      },

      onPointerUp: (_) {
        if (mounted) {
          setState(() {
            _buttonPressed = false;
          });
        }
      },

      onPointerCancel: (_) {
        if (mounted) {
          setState(() {
            _buttonPressed = false;
          });
        }
      },

      child:
      AnimatedScale(
        duration:
        const Duration(
          milliseconds:
          120,
        ),

        scale:
        _buttonPressed
            ? 0.975
            : 1,

        child:
        Container(
          width:
          double.infinity,

          height:
          54,

          decoration:
          BoxDecoration(
            borderRadius:
            BorderRadius.circular(
              28,
            ),

            gradient:
            const LinearGradient(
              begin:
              Alignment.centerLeft,

              end:
              Alignment.centerRight,

              colors: [
                Color(
                  0xFF0D8AA5,
                ),

                kPrimary,
              ],
            ),

            boxShadow: [
              BoxShadow(
                color: kPrimary
                    .withOpacity(
                  0.27,
                ),

                blurRadius:
                20,

                offset:
                const Offset(
                  0,
                  7,
                ),
              ),
            ],
          ),

          child:
          ElevatedButton(
            onPressed:
            onPressed,

            style:
            ElevatedButton.styleFrom(
              backgroundColor:
              Colors.transparent,

              disabledBackgroundColor:
              Colors.transparent,

              shadowColor:
              Colors.transparent,

              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  28,
                ),
              ),
            ),

            child:
            AnimatedSwitcher(
              duration:
              const Duration(
                milliseconds:
                220,
              ),

              child: isLoading
                  ? const SizedBox(
                key:
                ValueKey(
                  'loading',
                ),

                width:
                23,

                height:
                23,

                child:
                CircularProgressIndicator(
                  strokeWidth:
                  2.4,

                  color:
                  Colors.white,
                ),
              )
                  : Row(
                key:
                const ValueKey(
                  'normal',
                ),

                mainAxisAlignment:
                MainAxisAlignment.center,

                children: [
                  Flexible(
                    child:
                    Text(
                      text,

                      maxLines:
                      1,

                      overflow:
                      TextOverflow.ellipsis,

                      style:
                      const TextStyle(
                        color:
                        Colors.white,

                        fontSize:
                        14.5,

                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                  ),

                  const SizedBox(
                    width:
                    7,
                  ),

                  const Icon(
                    Icons
                        .check_circle_outline_rounded,

                    color:
                    Colors.white,

                    size:
                    18,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================================
  // BOTTOM NOTE
  // ==========================================================================

  Widget _buildBottomNote() {
    return const Center(
      child: Row(
        mainAxisSize:
        MainAxisSize.min,

        children: [
          Icon(
            Icons
                .lock_outline_rounded,

            color:
            kTextMuted,

            size:
            12,
          ),

          SizedBox(
            width:
            5,
          ),

          Flexible(
            child: Text(
              'Your documents are used for account verification.',

              textAlign:
              TextAlign.center,

              style:
              TextStyle(
                color:
                kTextMuted,

                fontSize:
                10.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}