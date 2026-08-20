import 'package:dio/dio.dart';
import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/network/api_endpoints.dart';

import '../controllers/user_session_storage.dart';
import '../models/LoginResponseModel.dart';
import '../models/PilotRegisterRequestModel.dart';
import '../models/CompanyRegisterRequestModel.dart';

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

    // ============================================================
    // RAW RESPONSE
    // ============================================================

    final rawResponse =
    Map<String, dynamic>.from(
      response.data as Map,
    );

    // ============================================================
    // MODEL
    // ============================================================

    final model =
    LoginResponseModel.fromJson(
      rawResponse,
    );

    // ============================================================
    // SAVE USER / ROLE / STATUS / PROFILE LOCALLY
    // ============================================================

    if (model.success && model.data != null) {
      final data = rawResponse['data'];

      if (data is Map) {
        await UserSessionStorage.saveSession(
          Map<String, dynamic>.from(data),
        );

        print(
          'LOGIN USER SESSION SAVED SUCCESSFULLY',
        );
      }
    }

    return model;
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

    Future<void> addFile(String key, String? path) async {
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

    addField('name', request.name);
    addField('email', request.email);
    addField('password', request.password);
    addField('password_confirmation', request.passwordConfirmation);
    addField('username', request.username);
    addField('phone', request.phone);
    addField('date_of_birth', request.dateOfBirth);
    addField('nationality', request.nationality);
    addField('linkedin_url', request.linkedinUrl);
    await addFile('profile_photo', request.profilePhotoPath);

    addField('experience_years', request.experienceYears);

    for (var i = 0; i < request.languages.length; i++) {
      addField('languages[$i]', request.languages[i]);
    }

    addField('current_country', request.currentCountry);
    addField('current_state', request.currentState);
    addField('current_city', request.currentCity);
    addField('previous_company', request.previousCompany);
    addField('bio', request.bio);

    for (var i = 0; i < request.workRegions.length; i++) {
      final region = request.workRegions[i];
      addField('work_regions[$i][country]', region.country);
      addField('work_regions[$i][state]', region.state);
      addField('work_regions[$i][city]', region.city);
    }

    final drone = request.drone;
    if (drone != null) {
      addField('drone[make]', drone.make);
      addField('drone[model]', drone.model);
      addField('drone[manufacture_year]', drone.manufactureYear);
      addField('drone[serial_number]', drone.serialNumber);
      addField('drone[weight_kg]', drone.weightKg);

      for (var i = 0; i < drone.capabilities.length; i++) {
        addField('drone[capabilities][$i]', drone.capabilities[i]);
      }

      addField(
        'drone[flight_time_per_battery_minutes]',
        drone.flightTimePerBatteryMinutes,
      );
      addField('drone[total_batteries]', drone.totalBatteries);
      addField('drone[battery_type]', drone.batteryType);
      addField('drone[battery_usage_fee]', drone.batteryUsageFee);
      addField('drone[hourly_rate]', drone.hourlyRate);
      addField('drone[daily_rate]', drone.dailyRate);
      addField('drone[emergency_callout_fee]', drone.emergencyCalloutFee);
      await addFile('drone[image]', drone.imagePath);
    }

    final license = request.pilotLicense;
    if (license != null) {
      addField('pilot_license[license_type]', license.licenseType);
      addField('pilot_license[license_number]', license.licenseNumber);
      addField(
        'pilot_license[issuing_authority]',
        license.issuingAuthority,
      );
      addField('pilot_license[expires_at]', license.expiresAt);
      await addFile(
        'pilot_license[license_document]',
        license.licenseDocumentPath,
      );
      await addFile(
        'pilot_license[permit_or_insurance_document]',
        license.permitOrInsuranceDocumentPath,
      );
    }

    formData.fields.add(MapEntry('fcm_token', request.fcmToken));
    formData.fields.add(MapEntry('apn_token', request.apnToken));
    addField('device_type', request.deviceType);

    _debugFormData('PILOT', formData);

    return apiClient.post(
      ApiEndpoints.pilotRegister,
      data: formData,
    );
  }

  // ============================================================
  // COMPANY REGISTER — ONE REQUEST FOR ALL 3 SCREENS
  // ============================================================

  Future<Response<dynamic>> registerCompany(
      CompanyRegisterRequestModel request,
      ) async {
    final formData = FormData();

    void addField(String key, Object? value) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isEmpty) return;
      formData.fields.add(MapEntry(key, text));
    }

    Future<void> addFile(String key, String? path) async {
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

    // Account + company identity
    addField('name', request.name);
    addField('username', request.username);
    addField('email', request.email);
    addField('password', request.password);
    addField('company_name', request.companyName);
    addField('password_confirmation', request.passwordConfirmation);
    addField('phone', request.phone);
    await addFile('logo', request.logoPath);
    addField('industry_type', request.industryType);

    // Company profile
    addField('description', request.description);
    addField('country', request.country);
    addField('state', request.state);
    addField('city', request.city);
    addField('address', request.address);
    addField('website', request.website);

    // Operating regions — Laravel/PHP multipart array notation
    for (var i = 0; i < request.workRegions.length; i++) {
      final region = request.workRegions[i];
      addField('work_regions[$i][country]', region.country);
      addField('work_regions[$i][state]', region.state);
      addField('work_regions[$i][city]', region.city);
    }

    // Device tokens
    formData.fields.add(MapEntry('fcm_token', request.fcmToken));
    formData.fields.add(MapEntry('apn_token', request.apnToken));
    addField('device_type', request.deviceType);

    _debugFormData('COMPANY', formData);

    return apiClient.post(
      ApiEndpoints.companyRegister,
      data: formData,
    );
  }

  // ============================================================
  // SAFE DEBUG
  // ============================================================

  void _debugFormData(String type, FormData formData) {
    print('================ $type FORM DATA FIELDS ================');

    for (final field in formData.fields) {
      if (field.key == 'password' ||
          field.key == 'password_confirmation') {
        print('${field.key} = ********');
      } else {
        print('${field.key} = ${field.value}');
      }
    }

    print('================ $type FORM DATA FILES =================');

    for (final file in formData.files) {
      print('${file.key} = ${file.value.filename}');
    }

    print('========================================================');
  }
}
