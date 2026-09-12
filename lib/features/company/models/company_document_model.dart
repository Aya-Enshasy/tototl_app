class CompanyDocumentModel {
  const CompanyDocumentModel({
    required this.id,
    this.collectionName = 'company_documents',
    this.fileName = '',
    this.mimeType = '',
    this.size = 0,
    this.url = '',
    this.downloadUrl = '',
    this.createdAt,
  });

  final int id;
  final String collectionName;
  final String fileName;
  final String mimeType;
  final int size;
  final String url;
  final String downloadUrl;
  final DateTime? createdAt;

  factory CompanyDocumentModel.fromJson(Map<String, dynamic> json) {
    return CompanyDocumentModel(
      id: _asInt(json['id']) ?? 0,
      collectionName: _asString(json['collection_name']).isEmpty
          ? 'company_documents'
          : _asString(json['collection_name']),
      fileName: _asString(json['file_name']),
      mimeType: _asString(json['mime_type']),
      size: _asInt(json['size']) ?? 0,
      url: _asString(json['url']),
      downloadUrl: _asString(json['download_url']),
      createdAt: _asDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'collection_name': collectionName,
    'file_name': fileName,
    'mime_type': mimeType,
    'size': size,
    'url': url,
    'download_url': downloadUrl,
    'created_at': createdAt?.toIso8601String(),
  };

  String get displayName {
    final clean = fileName.trim();
    return clean.isEmpty ? 'Company document #$id' : clean;
  }

  String get extension {
    final clean = fileName.trim().toLowerCase();
    final dot = clean.lastIndexOf('.');
    if (dot < 0 || dot == clean.length - 1) return '';
    return clean.substring(dot + 1);
  }

  bool get isPdf =>
      mimeType.trim().toLowerCase() == 'application/pdf' || extension == 'pdf';

  bool get isImage {
    final mime = mimeType.trim().toLowerCase();
    return mime.startsWith('image/') ||
        const {'png', 'jpg', 'jpeg', 'webp'}.contains(extension);
  }
}

String _asString(dynamic value) =>
    value == null ? '' : value.toString().trim();

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}
