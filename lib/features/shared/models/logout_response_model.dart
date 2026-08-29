// ============================================================================
// LOGOUT RESPONSE MODEL
// ============================================================================

class LogoutResponseModel {
  final bool success;
  final String message;
  final dynamic data;
  final dynamic errors;

  const LogoutResponseModel({
    required this.success,
    this.message = '',
    this.data,
    this.errors,
  });

  factory LogoutResponseModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return LogoutResponseModel(
      success: json['success'] == true,
      message: json['message']?.toString().trim() ?? '',
      data: json['data'],
      errors: json['errors'],
    );
  }
}
