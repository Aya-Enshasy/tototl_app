import 'package:dio/dio.dart';

class CloudinaryChatMediaService {
  CloudinaryChatMediaService._();

  static final CloudinaryChatMediaService instance =
      CloudinaryChatMediaService._();

  static const String cloudName =
      'dku7urxs1';

  static const String imagePreset =
      'tototl_chat_images';

  static const String voicePreset =
      'tototl_chat_voice';

  final Dio _dio =
      Dio(
    BaseOptions(
      connectTimeout:
          const Duration(
        seconds: 30,
      ),
      sendTimeout:
          const Duration(
        seconds: 90,
      ),
      receiveTimeout:
          const Duration(
        seconds: 90,
      ),
    ),
  );

  Future<CloudinaryUploadResult> uploadImage(
    String filePath,
  ) {
    return _upload(
      filePath:
          filePath,
      resourceType:
          'image',
      uploadPreset:
          imagePreset,
    );
  }

  Future<CloudinaryUploadResult> uploadVoice(
    String filePath,
  ) {
    // Cloudinary treats audio files as video resources.
    return _upload(
      filePath:
          filePath,
      resourceType:
          'video',
      uploadPreset:
          voicePreset,
    );
  }

  Future<CloudinaryUploadResult> _upload({
    required String filePath,
    required String resourceType,
    required String uploadPreset,
  }) async {
    final filename =
        filePath
            .replaceAll(
              '\\',
              '/',
            )
            .split('/')
            .last;

    final formData =
        FormData.fromMap(
      {
        'file':
            await MultipartFile.fromFile(
          filePath,
          filename:
              filename,
        ),
        'upload_preset':
            uploadPreset,
      },
    );

    final response =
        await _dio.post<Map<String, dynamic>>(
      'https://api.cloudinary.com/v1_1/'
      '$cloudName/$resourceType/upload',
      data:
          formData,
      options:
          Options(
        contentType:
            'multipart/form-data',
        responseType:
            ResponseType.json,
      ),
    );

    final body =
        response.data;

    if (body == null) {
      throw const CloudinaryUploadException(
        'Cloudinary returned an empty response.',
      );
    }

    final secureUrl =
        body['secure_url']
                ?.toString()
                .trim() ??
            '';

    if (secureUrl.isEmpty) {
      final error =
          body['error'];

      if (error is Map) {
        final message =
            error['message']
                    ?.toString()
                    .trim() ??
                '';

        if (message.isNotEmpty) {
          throw CloudinaryUploadException(
            message,
          );
        }
      }

      throw const CloudinaryUploadException(
        'Media upload failed.',
      );
    }

    return CloudinaryUploadResult(
      secureUrl:
          secureUrl,
      publicId:
          body['public_id']
                  ?.toString()
                  .trim() ??
              '',
      resourceType:
          body['resource_type']
                  ?.toString()
                  .trim() ??
              resourceType,
      format:
          body['format']
                  ?.toString()
                  .trim() ??
              '',
      bytes:
          _asInt(
                body['bytes'],
              ) ??
              0,
      durationSeconds:
          _asDouble(
                body['duration'],
              ) ??
              0,
    );
  }
}

class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.secureUrl,
    required this.publicId,
    required this.resourceType,
    required this.format,
    required this.bytes,
    required this.durationSeconds,
  });

  final String secureUrl;
  final String publicId;
  final String resourceType;
  final String format;
  final int bytes;
  final double durationSeconds;
}

class CloudinaryUploadException
    implements Exception {
  const CloudinaryUploadException(
    this.message,
  );

  final String message;

  @override
  String toString() =>
      message;
}

int? _asInt(
  dynamic value,
) {
  if (value is int) {
    return value;
  }

  return int.tryParse(
    value?.toString() ?? '',
  );
}

double? _asDouble(
  dynamic value,
) {
  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
    value?.toString() ?? '',
  );
}
