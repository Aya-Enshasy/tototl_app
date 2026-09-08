import 'package:dio/dio.dart';

import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/network/api_endpoints.dart';

import '../controllers/user_session_storage.dart';

import '../models/LoginResponseModel.dart';
import '../models/PilotRegisterRequestModel.dart';
import '../models/CompanyRegisterRequestModel.dart';

// ============================================================================
// AUTH SERVICE
// ============================================================================

class AuthService {
  final ApiClient apiClient;

  AuthService(
      this.apiClient,
      );

  // ==========================================================================
  // LOGIN
  // ==========================================================================

  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response =
    await apiClient.post(
      ApiEndpoints.login,
      data: {
        'login':
        email.trim(),

        'password':
        password,

        'fcm_token':
        '',

        'apn_token':
        '',

        'device_type':
        'android',
      },
    );

    // ------------------------------------------------------------------------
    // RAW RESPONSE
    // ------------------------------------------------------------------------

    final rawResponse =
    Map<String, dynamic>.from(
      response.data as Map,
    );

    // ------------------------------------------------------------------------
    // MODEL
    // ------------------------------------------------------------------------

    final model =
    LoginResponseModel.fromJson(
      rawResponse,
    );

    // ------------------------------------------------------------------------
    // SAVE SESSION
    // ------------------------------------------------------------------------

    if (model.success &&
        model.data != null) {
      final data =
      rawResponse['data'];

      if (data is Map) {
        await UserSessionStorage
            .saveSession(
          Map<String, dynamic>.from(
            data,
          ),
        );

        print(
          'LOGIN USER SESSION SAVED SUCCESSFULLY',
        );
      }
    }

    return model;
  }

  // ==========================================================================
  // PILOT REGISTER
  // ==========================================================================
  //
  // One multipart/form-data request containing:
  //
  // Step 1 -> Account / personal information
  // Step 2 -> Experience / work regions
  // Step 3 -> Drone object
  // Step 4 -> Pilot license object
  //
  // ==========================================================================

  Future<Response<dynamic>> registerPilot(
      PilotRegisterRequestModel request,
      ) async {
    final formData =
    FormData();

    // ------------------------------------------------------------------------
    // HELPER: TEXT FIELD
    // ------------------------------------------------------------------------

    void addField(
        String key,
        Object? value,
        ) {
      if (value == null) {
        return;
      }

      final text =
      value
          .toString()
          .trim();

      if (text.isEmpty) {
        return;
      }

      formData.fields.add(
        MapEntry(
          key,
          text,
        ),
      );
    }

    // ------------------------------------------------------------------------
    // HELPER: FILE
    // ------------------------------------------------------------------------

    Future<void> addFile(
        String key,
        String? path,
        ) async {
      if (path == null ||
          path.trim().isEmpty) {
        return;
      }

      final cleanPath =
      path.trim();

      final fileName =
          cleanPath
              .split(
            RegExp(
              r'[\\/]',
            ),
          )
              .last;

      formData.files.add(
        MapEntry(
          key,
          await MultipartFile.fromFile(
            cleanPath,
            filename:
            fileName,
          ),
        ),
      );
    }

    // ------------------------------------------------------------------------
    // HELPER: DATE ONLY
    //
    // Flutter may store:
    // 2026-08-23T00:00:00.000
    //
    // API normally expects:
    // 2026-08-23
    // ------------------------------------------------------------------------

    String? dateOnly(
        String? value,
        ) {
      if (value == null) {
        return null;
      }

      final clean =
      value.trim();

      if (clean.isEmpty) {
        return null;
      }

      if (clean.contains(
        'T',
      )) {
        return clean
            .split(
          'T',
        )
            .first;
      }

      if (clean.length >= 10) {
        return clean.substring(
          0,
          10,
        );
      }

      return clean;
    }

    // ========================================================================
    // STEP 1
    // ACCOUNT + PERSONAL INFORMATION
    // ========================================================================

    addField(
      'name',
      request.name,
    );

    addField(
      'email',
      request.email,
    );

    addField(
      'password',
      request.password,
    );

    addField(
      'password_confirmation',
      request.passwordConfirmation,
    );

    addField(
      'username',
      request.username,
    );

    addField(
      'phone',
      request.phone,
    );

    addField(
      'date_of_birth',
      dateOnly(
        request.dateOfBirth,
      ),
    );

    addField(
      'nationality',
      request.nationality,
    );

    addField(
      'linkedin_url',
      request.linkedinUrl,
    );

    // ------------------------------------------------------------------------
    // PROFILE PHOTO
    // ------------------------------------------------------------------------

    await addFile(
      'profile_photo',
      request.profilePhotoPath,
    );

    // ========================================================================
    // STEP 2
    // EXPERIENCE
    // ========================================================================

    addField(
      'experience_years',
      request.experienceYears,
    );

    // ------------------------------------------------------------------------
    // LANGUAGES
    //
    // languages[0] = English
    // languages[1] = Arabic
    // ------------------------------------------------------------------------

    for (
    var i = 0;
    i < request.languages.length;
    i++
    ) {
      addField(
        'languages[$i]',
        request.languages[i],
      );
    }

    // ------------------------------------------------------------------------
    // CURRENT LOCATION
    // ------------------------------------------------------------------------

    addField(
      'current_country',
      request.currentCountry,
    );

    addField(
      'current_state',
      request.currentState,
    );

    addField(
      'current_city',
      request.currentCity,
    );

    // ------------------------------------------------------------------------
    // PROFESSIONAL INFORMATION
    // ------------------------------------------------------------------------

    addField(
      'previous_company',
      request.previousCompany,
    );

    addField(
      'bio',
      request.bio,
    );

    // ------------------------------------------------------------------------
    // WORK REGIONS
    //
    // work_regions[0][country]
    // work_regions[0][state]
    // work_regions[0][city]
    //
    // Laravel converts this to an array of objects.
    // ------------------------------------------------------------------------

    for (
    var i = 0;
    i < request.workRegions.length;
    i++
    ) {
      final region =
      request.workRegions[i];

      addField(
        'work_regions[$i][country]',
        region.country,
      );

      addField(
        'work_regions[$i][state]',
        region.state,
      );

      addField(
        'work_regions[$i][city]',
        region.city,
      );
    }

    // ========================================================================
    // STEP 3
    // DRONE OBJECT
    // ========================================================================

    final drone =
        request.drone;

    if (drone != null) {
      // ----------------------------------------------------------------------
      // BASIC DRONE DATA
      // ----------------------------------------------------------------------

      addField(
        'drone[make]',
        drone.make,
      );

      addField(
        'drone[model]',
        drone.model,
      );

      addField(
        'drone[manufacture_year]',
        drone.manufactureYear,
      );

      addField(
        'drone[serial_number]',
        drone.serialNumber,
      );

      addField(
        'drone[weight_kg]',
        drone.weightKg,
      );

      // ----------------------------------------------------------------------
      // FLIGHT / BATTERY
      // ----------------------------------------------------------------------

      addField(
        'drone[flight_time]',
        drone.flightTime,
      );

      addField(
        'drone[total_batteries]',
        drone.totalBatteries,
      );

      addField(
        'drone[battery_type]',
        drone.batteryType,
      );

      addField(
        'drone[battery_usage_fee]',
        drone.batteryUsageFee,
      );

      // ----------------------------------------------------------------------
      // SERVICE RATES
      // ----------------------------------------------------------------------

      addField(
        'drone[hourly_rate]',
        drone.hourlyRate,
      );

      addField(
        'drone[daily_rate]',
        drone.dailyRate,
      );

      addField(
        'drone[emergency_callout_fee]',
        drone.emergencyCalloutFee,
      );

      // ----------------------------------------------------------------------
      // CAPABILITIES
      //
      // API example:
      // capabilities = laser,thermal
      //
      // App example:
      // thermal,rtk,spotlight
      // ----------------------------------------------------------------------

      if (drone.capabilities.isNotEmpty) {
        final capabilities =
        drone.capabilities
            .map(
              (item) =>
              item.trim(),
        )
            .where(
              (item) =>
          item.isNotEmpty,
        )
            .join(
          ',',
        );

        addField(
          'drone[capabilities]',
          capabilities,
        );
      }

      // ----------------------------------------------------------------------
      // DRONE IMAGE
      // ----------------------------------------------------------------------

      await addFile(
        'drone[image]',
        drone.imagePath,
      );
    }

    // ========================================================================
    // STEP 4
    // PILOT LICENSE OBJECT
    // ========================================================================

    final license =
        request.pilotLicense;

    if (license != null) {
      addField(
        'pilot_license[license_type]',
        license.licenseType,
      );

      addField(
        'pilot_license[license_number]',
        license.licenseNumber,
      );

      addField(
        'pilot_license[issuing_authority]',
        license.issuingAuthority,
      );

      addField(
        'pilot_license[expires_at]',
        dateOnly(
          license.expiresAt,
        ),
      );

      // ----------------------------------------------------------------------
      // LICENSE DOCUMENT
      // ----------------------------------------------------------------------

      await addFile(
        'pilot_license[license_document]',
        license.licenseDocumentPath,
      );

      // ----------------------------------------------------------------------
      // PERMIT / INSURANCE
      // OPTIONAL
      // ----------------------------------------------------------------------

      await addFile(
        'pilot_license[permit_or_insurance_document]',
        license.permitOrInsuranceDocumentPath,
      );
    }

    // ========================================================================
    // DEVICE TOKENS
    // ========================================================================

    // Keep these fields even when empty because they exist in the register API.

    formData.fields.add(
      MapEntry(
        'fcm_token',
        request.fcmToken,
      ),
    );

    formData.fields.add(
      MapEntry(
        'apn_token',
        request.apnToken,
      ),
    );

    addField(
      'device_type',
      request.deviceType,
    );

    // ========================================================================
    // DEBUG
    // ========================================================================

    _debugFormData(
      'PILOT',
      formData,
    );

    // ========================================================================
    // API REQUEST
    // ========================================================================

    return apiClient.post(
      ApiEndpoints.pilotRegister,
      data:
      formData,
    );
  }

  // ==========================================================================
  // COMPANY REGISTER
  // ==========================================================================

  Future<Response<dynamic>> registerCompany(
      CompanyRegisterRequestModel request,
      ) async {
    final formData =
    FormData();

    // ------------------------------------------------------------------------
    // TEXT
    // ------------------------------------------------------------------------

    void addField(
        String key,
        Object? value,
        ) {
      if (value == null) {
        return;
      }

      final text =
      value
          .toString()
          .trim();

      if (text.isEmpty) {
        return;
      }

      formData.fields.add(
        MapEntry(
          key,
          text,
        ),
      );
    }

    // ------------------------------------------------------------------------
    // FILE
    // ------------------------------------------------------------------------

    Future<void> addFile(
        String key,
        String? path,
        ) async {
      if (path == null ||
          path.trim().isEmpty) {
        return;
      }

      final cleanPath =
      path.trim();

      final fileName =
          cleanPath
              .split(
            RegExp(
              r'[\\/]',
            ),
          )
              .last;

      formData.files.add(
        MapEntry(
          key,
          await MultipartFile.fromFile(
            cleanPath,
            filename:
            fileName,
          ),
        ),
      );
    }

    // ========================================================================
    // ACCOUNT
    // ========================================================================

    addField(
      'name',
      request.name,
    );

    addField(
      'username',
      request.username,
    );

    addField(
      'email',
      request.email,
    );

    addField(
      'password',
      request.password,
    );

    addField(
      'password_confirmation',
      request.passwordConfirmation,
    );

    addField(
      'phone',
      request.phone,
    );

    // ========================================================================
    // COMPANY
    // ========================================================================

    addField(
      'company_name',
      request.companyName,
    );

    await addFile(
      'logo',
      request.logoPath,
    );

    addField(
      'industry_type',
      request.industryType,
    );

    addField(
      'description',
      request.description,
    );

    // ========================================================================
    // LOCATION
    // ========================================================================

    addField(
      'country',
      request.country,
    );

    addField(
      'state',
      request.state,
    );

    addField(
      'city',
      request.city,
    );

    addField(
      'address',
      request.address,
    );

    addField(
      'website',
      request.website,
    );

    // ========================================================================
    // OPERATING REGIONS
    // ========================================================================

    for (
    var i = 0;
    i < request.workRegions.length;
    i++
    ) {
      final region =
      request.workRegions[i];

      addField(
        'work_regions[$i][country]',
        region.country,
      );

      addField(
        'work_regions[$i][state]',
        region.state,
      );

      addField(
        'work_regions[$i][city]',
        region.city,
      );
    }

    // ========================================================================
    // DEVICE
    // ========================================================================

    formData.fields.add(
      MapEntry(
        'fcm_token',
        request.fcmToken,
      ),
    );

    formData.fields.add(
      MapEntry(
        'apn_token',
        request.apnToken,
      ),
    );

    addField(
      'device_type',
      request.deviceType,
    );

    // ========================================================================
    // DEBUG
    // ========================================================================

    _debugFormData(
      'COMPANY',
      formData,
    );

    return apiClient.post(
      ApiEndpoints.companyRegister,
      data:
      formData,
    );
  }

  // ==========================================================================
  // FORGOT PASSWORD
  // ==========================================================================

  Future<Response<dynamic>> forgotPassword({
    required String email,
  }) async {
    print(
      'FORGOT PASSWORD ENDPOINT: ${ApiEndpoints.forgotPassword}',
    );

    return apiClient.post(
      ApiEndpoints.forgotPassword,
      data: {
        'email':
        email.trim(),
      },
    );
  }

  // ==========================================================================
  // SAFE DEBUG
  // ==========================================================================

  void _debugFormData(
      String type,
      FormData formData,
      ) {
    print(
      '================ $type FORM DATA FIELDS ================',
    );

    for (final field
    in formData.fields) {
      if (field.key ==
          'password' ||
          field.key ==
              'password_confirmation') {
        print(
          '${field.key} = ********',
        );
      } else {
        print(
          '${field.key} = ${field.value}',
        );
      }
    }

    print(
      '================ $type FORM DATA FILES =================',
    );

    for (final file
    in formData.files) {
      print(
        '${file.key} = ${file.value.filename}',
      );
    }

    print(
      '========================================================',
    );
  }
}