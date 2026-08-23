class ProfileDocumentModel {
  final int? id;
  final String collectionName;
  final String fileName;
  final String mimeType;
  final int size;
  final String url;
  final String? downloadUrl;
  final DateTime? createdAt;

  const ProfileDocumentModel({
    this.id,
    this.collectionName = '',
    this.fileName = '',
    this.mimeType = '',
    this.size = 0,
    this.url = '',
    this.downloadUrl,
    this.createdAt,
  });

  factory ProfileDocumentModel.fromJson(Map<String, dynamic> json) {
    return ProfileDocumentModel(
      id: _asInt(json['id']),
      collectionName: _asString(json['collection_name']),
      fileName: _asString(json['file_name']),
      mimeType: _asString(json['mime_type']),
      size: _asInt(json['size']) ?? 0,
      url: _asString(json['url']),
      downloadUrl: json['download_url']?.toString(),
      createdAt: _asDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'collection_name': collectionName,
      'file_name': fileName,
      'mime_type': mimeType,
      'size': size,
      'url': url,
      'download_url': downloadUrl,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

String _asString(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}
