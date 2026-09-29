import 'dart:convert';

class ContractSubmissionFileModel {
  final int? id;
  final String name;
  final String url;
  final String mimeType;
  final int? sizeBytes;

  const ContractSubmissionFileModel({
    this.id,
    required this.name,
    required this.url,
    required this.mimeType,
    this.sizeBytes,
  });

  factory ContractSubmissionFileModel.fromDynamic(dynamic raw) {
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final url = _firstString(map, const [
        'download_url',
        'original_url',
        'url',
        'file_url',
        'path',
      ]);
      final name = _firstString(map, const [
        'file_name',
        'original_name',
        'name',
        'filename',
      ]);
      return ContractSubmissionFileModel(
        id: _asInt(map['id'] ?? map['media_id']),
        name: name.isNotEmpty ? name : _basename(url),
        url: url,
        mimeType: _firstString(map, const ['mime_type', 'mime', 'type']),
        sizeBytes: _asInt(map['size'] ?? map['size_bytes']),
      );
    }

    final text = raw?.toString().trim() ?? '';
    return ContractSubmissionFileModel(
      name: _basename(text),
      url: text,
      mimeType: '',
    );
  }

  String get displayName => name.trim().isEmpty ? 'Attachment' : name.trim();

  String get sizeLabel {
    final size = sizeBytes;
    if (size == null || size <= 0) return '';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ContractSubmissionModel {
  final int id;
  final int contractId;
  final String notes;
  final String status;
  final int? reviewedBy;
  final String reviewNotes;
  final DateTime? reviewedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<ContractSubmissionFileModel> files;

  const ContractSubmissionModel({
    required this.id,
    required this.contractId,
    required this.notes,
    required this.status,
    required this.reviewedBy,
    required this.reviewNotes,
    required this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.files,
  });

  factory ContractSubmissionModel.fromJson(Map<String, dynamic> json) {
    return ContractSubmissionModel(
      id: _asInt(json['id']) ?? 0,
      contractId: _asInt(json['contract_id']) ?? 0,
      notes: _asString(json['notes']),
      status: _asString(json['status']).toLowerCase(),
      reviewedBy: _asInt(json['reviewed_by']),
      reviewNotes: _asString(json['review_notes']),
      reviewedAt: _asDate(json['reviewed_at']),
      createdAt: _asDate(json['created_at']),
      updatedAt: _asDate(json['updated_at']),
      files: List.unmodifiable(_parseFiles(json['files'])),
    );
  }

  bool get isSubmitted => status == 'submitted';
  bool get isRevisionRequested => status == 'revision_requested';
  bool get isApproved => status == 'approved';

  String get statusLabel {
    switch (status) {
      case 'submitted':
        return 'Submitted';
      case 'revision_requested':
        return 'Revision Requested';
      case 'approved':
        return 'Approved';
      default:
        return _pretty(status.isEmpty ? 'submitted' : status);
    }
  }

  String get submittedLabel => _formatDateTime(createdAt);
  String get reviewedLabel => _formatDateTime(reviewedAt);

  static List<ContractSubmissionFileModel> _parseFiles(dynamic raw) {
    dynamic value = raw;

    if (value is String) {
      final text = value.trim();
      if (text.isEmpty) return const [];
      if ((text.startsWith('[') && text.endsWith(']')) ||
          (text.startsWith('{') && text.endsWith('}'))) {
        try {
          value = jsonDecode(text);
        } catch (_) {
          return [ContractSubmissionFileModel.fromDynamic(text)];
        }
      } else {
        return [ContractSubmissionFileModel.fromDynamic(text)];
      }
    }

    if (value is List) {
      return value
          .map(ContractSubmissionFileModel.fromDynamic)
          .toList(growable: false);
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final nested = map['data'] ?? map['files'] ?? map['media'];
      if (nested is List) {
        return nested
            .map(ContractSubmissionFileModel.fromDynamic)
            .toList(growable: false);
      }
      return [ContractSubmissionFileModel.fromDynamic(map)];
    }

    return const [];
  }
}

String _asString(dynamic value) => value == null ? '' : value.toString().trim();

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

String _firstString(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = _asString(map[key]);
    if (value.isNotEmpty) return value;
  }
  return '';
}

String _basename(String value) {
  final clean = value.trim();
  if (clean.isEmpty) return 'Attachment';
  final withoutQuery = clean.split('?').first;
  final parts = withoutQuery.split(RegExp(r'[\\/]'));
  final last = parts.isEmpty ? clean : parts.last;
  return last.trim().isEmpty ? 'Attachment' : Uri.decodeComponent(last);
}

String _pretty(String value) {
  return value
      .trim()
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
      .join(' ');
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  String p(int value) => value.toString().padLeft(2, '0');
  return '${local.year}-${p(local.month)}-${p(local.day)} · ${p(local.hour)}:${p(local.minute)}';
}
