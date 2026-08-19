import 'package:dio/dio.dart';
import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/network/api_endpoints.dart';

import '../models/LoginResponseModel.dart';
import '../models/PilotRegisterRequestModel.dart';

class AuthService {
  final ApiClient apiClient;

  AuthService(this.apiClient);

  // ============================================================
  // LOGIN
  // ============================================================

  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiEndpoints.login,
      data: {
        'login': email,
        'password': password,
        'fcm_token': '',
        'apn_token': '',
        'device_type': 'android',
      },
    );

    return LoginResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  // ============================================================
  // PILOT REGISTER — ONE REQUEST FOR ALL 4 STEPS
  // ============================================================

  Future<Response<dynamic>> registerPilot(
      PilotRegisterRequestModel request,
      ) async {
    final formData = FormData();

    void addField(String key, Object? value) {
      if (value == null) return;

      final text = value.toString().trim();
      if (text.isEmpty) return;

      formData.fields.add(MapEntry(key, text));
    }

    Future<void> addFile(
        String key,
        String? path,
        ) async {
      if (path == null || path.trim().isEmpty) return;

      formData.files.add(
        MapEntry(
          key,
          await MultipartFile.fromFile(
            path,
            filename: path.split(RegExp(r'[\\/]')).last,
          ),
        ),
      );
    }

    // ==========================================================
    // STEP 1 — ACCOUNT
    // ==========================================================

    addField('name', request.name);
    addField('email', request.email);
    addField('password', request.password);
    addField(
      'password_confirmation',
      request.passwordConfirmation,
    );
    addField('username', request.username);
    addField('phone', request.phone);
    addField('date_of_birth', request.dateOfBirth);
    addField('nationality', request.nationality);
    addField('linkedin_url', request.linkedinUrl);

    // IMPORTANT: API key is profile_photo, not image.
    await addFile(
      'profile_photo',
      request.profilePhotoPath,
    );

    // ==========================================================
    // STEP 2 — EXPERIENCE / PROFILE
    // ==========================================================

    addField(
      'experience_years',
      request.experienceYears,
    );

    for (var i = 0; i < request.languages.length; i++) {
      addField(
        'languages[$i]',
        request.languages[i],
      );
    }

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
    addField(
      'previous_company',
      request.previousCompany,
    );
    addField('bio', request.bio);

    for (var i = 0; i < request.workRegions.length; i++) {
      final region = request.workRegions[i];

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

    // ==========================================================
    // STEP 3 — DRONE (AT MOST ONE)
    // ==========================================================

    final drone = request.drone;

    if (drone != null) {
      addField('drone[make]', drone.make);
      addField('drone[model]', drone.model);
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

      // Existing drone API examples use a comma-separated text value.
      addField(
        'drone[capabilities]',
        drone.capabilities.join(','),
      );

      addField(
        'drone[flight_time_per_battery_minutes]',
        drone.flightTimePerBatteryMinutes,
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

      await addFile(
        'drone[image]',
        drone.imagePath,
      );
    }

    // ==========================================================
    // STEP 4 — PILOT LICENSE / CERTIFICATION (AT MOST ONE)
    // ==========================================================

    final license = request.pilotLicense;

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
        license.expiresAt,
      );

      await addFile(
        'pilot_license[license_document]',
        license.licenseDocumentPath,
      );

      await addFile(
        'pilot_license[permit_or_insurance_document]',
        license.permitOrInsuranceDocumentPath,
      );
    }

    // ==========================================================
    // DEVICE TOKENS
    // ==========================================================

    // Keep the keys present even before push-notification wiring is finished.
    formData.fields.add(
      MapEntry('fcm_token', request.fcmToken),
    );
    formData.fields.add(
      MapEntry('apn_token', request.apnToken),
    );
    addField('device_type', request.deviceType);

    return apiClient.post(
      ApiEndpoints.pilotRegister,
      data: formData,
    );
  }
}

