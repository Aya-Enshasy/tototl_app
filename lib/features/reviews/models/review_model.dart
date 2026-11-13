import 'package:tototl_app/core/models/rating_summary_model.dart';

class ReviewListModel {
  final RatingSummaryModel summary;
  final List<ReviewModel> reviews;
  final ReviewPaginationModel pagination;

  const ReviewListModel({
    this.summary = const RatingSummaryModel(),
    this.reviews = const [],
    this.pagination = const ReviewPaginationModel(),
  });

  factory ReviewListModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final rawSummary = json['summary'];
    final rawReviews = json['reviews'];
    final rawPagination = json['pagination'];

    return ReviewListModel(
      summary: rawSummary is Map
          ? RatingSummaryModel.fromJson(
        Map<String, dynamic>.from(
          rawSummary,
        ),
      )
          : const RatingSummaryModel(),
      reviews: _parseReviews(
        rawReviews,
      ),
      pagination: rawPagination is Map
          ? ReviewPaginationModel.fromJson(
        Map<String, dynamic>.from(
          rawPagination,
        ),
      )
          : const ReviewPaginationModel(),
    );
  }

  bool get isEmpty =>
      reviews.isEmpty;

  bool get isNotEmpty =>
      reviews.isNotEmpty;

  bool get hasMore =>
      pagination.currentPage <
          pagination.lastPage;
}

class ReviewModel {
  final int id;
  final int contractId;
  final int? reviewerId;
  final int? revieweeId;

  final int rating;
  final String comment;

  final DateTime? hiddenAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final ReviewReviewerModel? reviewer;
  final ReviewContractSummaryModel? contract;

  const ReviewModel({
    required this.id,
    required this.contractId,
    this.reviewerId,
    this.revieweeId,
    required this.rating,
    this.comment = '',
    this.hiddenAt,
    this.createdAt,
    this.updatedAt,
    this.reviewer,
    this.contract,
  });

  factory ReviewModel.fromJson(
      Map<String, dynamic> json,
      ) {
    final rawReviewer =
    json['reviewer'];

    final rawContract =
    json['contract'];

    return ReviewModel(
      id: _asInt(
        json['id'],
      ) ??
          0,
      contractId: _asInt(
        json['contract_id'],
      ) ??
          0,
      reviewerId: _asInt(
        json['reviewer_id'],
      ),
      revieweeId: _asInt(
        json['reviewee_id'],
      ),
      rating: _asInt(
        json['rating'],
      ) ??
          0,
      comment: _asString(
        json['comment'],
      ),
      hiddenAt: _asDate(
        json['hidden_at'],
      ),
      createdAt: _asDate(
        json['created_at'],
      ),
      updatedAt: _asDate(
        json['updated_at'],
      ),
      reviewer: rawReviewer is Map
          ? ReviewReviewerModel.fromJson(
        Map<String, dynamic>.from(
          rawReviewer,
        ),
      )
          : null,
      contract: rawContract is Map
          ? ReviewContractSummaryModel.fromJson(
        Map<String, dynamic>.from(
          rawContract,
        ),
      )
          : null,
    );
  }

  bool get hasComment =>
      comment.trim().isNotEmpty;

  bool get isHidden =>
      hiddenAt != null;

  String get ratingLabel =>
      '$rating/5';

  String get reviewerName {
    final value =
        reviewer?.name.trim() ?? '';

    if (value.isNotEmpty) {
      return value;
    }

    return 'User';
  }

  String get reviewerRole =>
      reviewer?.role.trim() ?? '';

  String get jobTitle {
    final value =
        contract?.jobTitle.trim() ?? '';

    if (value.isNotEmpty) {
      return value;
    }

    return contractId > 0
        ? 'Contract #$contractId'
        : 'Contract';
  }

  String get createdLabel =>
      _friendlyDate(
        createdAt,
      );
}

class ReviewReviewerModel {
  final int? userId;
  final String role;
  final String name;
  final String profilePhoto;

  const ReviewReviewerModel({
    this.userId,
    this.role = '',
    this.name = '',
    this.profilePhoto = '',
  });

  factory ReviewReviewerModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return ReviewReviewerModel(
      userId: _asInt(
        json['user_id'],
      ),
      role: _asString(
        json['role'],
      ).toLowerCase(),
      name: _asString(
        json['name'],
      ),
      profilePhoto: _asString(
        json['profile_photo'],
      ),
    );
  }

  bool get hasProfilePhoto =>
      profilePhoto.trim().isNotEmpty;

  bool get isPilot =>
      role == 'pilot';

  bool get isCompany =>
      role == 'company';

  String get roleLabel {
    if (isPilot) {
      return 'Pilot';
    }

    if (isCompany) {
      return 'Company';
    }

    return role.isEmpty
        ? ''
        : _pretty(role);
  }
}

class ReviewContractSummaryModel {
  final int id;
  final String status;
  final int? jobPostingId;
  final String jobTitle;

  const ReviewContractSummaryModel({
    required this.id,
    this.status = '',
    this.jobPostingId,
    this.jobTitle = '',
  });

  factory ReviewContractSummaryModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return ReviewContractSummaryModel(
      id: _asInt(
        json['id'],
      ) ??
          0,
      status: _asString(
        json['status'],
      ).toLowerCase(),
      jobPostingId: _asInt(
        json['job_posting_id'],
      ),
      jobTitle: _asString(
        json['job_title'],
      ),
    );
  }

  bool get isCompleted =>
      status == 'completed';

  String get statusLabel =>
      _pretty(
        status,
      );

  String get displayJobTitle {
    final value =
    jobTitle.trim();

    if (value.isNotEmpty) {
      return value;
    }

    if (jobPostingId != null &&
        jobPostingId! > 0) {
      return 'Job #$jobPostingId';
    }

    return 'Contract';
  }
}

class ReviewPaginationModel {
  final int currentPage;
  final int perPage;
  final int total;
  final int lastPage;

  const ReviewPaginationModel({
    this.currentPage = 1,
    this.perPage = 15,
    this.total = 0,
    this.lastPage = 1,
  });

  factory ReviewPaginationModel.fromJson(
      Map<String, dynamic> json,
      ) {
    return ReviewPaginationModel(
      currentPage: _asInt(
        json['current_page'],
      ) ??
          1,
      perPage: _asInt(
        json['per_page'],
      ) ??
          15,
      total: _asInt(
        json['total'],
      ) ??
          0,
      lastPage: _asInt(
        json['last_page'],
      ) ??
          1,
    );
  }

  bool get hasNextPage =>
      currentPage < lastPage;
}

List<ReviewModel> _parseReviews(
    dynamic raw,
    ) {
  if (raw is! List) {
    return const [];
  }

  return raw
      .whereType<Map>()
      .map(
        (item) =>
        ReviewModel.fromJson(
          Map<String, dynamic>.from(
            item,
          ),
        ),
  )
      .toList(
    growable: false,
  );
}

String _asString(
    dynamic value,
    ) {
  if (value == null) {
    return '';
  }

  return value
      .toString()
      .trim();
}

int? _asInt(
    dynamic value,
    ) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(
    value.toString(),
  );
}

DateTime? _asDate(
    dynamic value,
    ) {
  if (value == null) {
    return null;
  }

  final text =
  value
      .toString()
      .trim();

  if (text.isEmpty) {
    return null;
  }

  return DateTime.tryParse(
    text,
  );
}

String _pretty(
    String value,
    ) {
  final clean =
  value.trim();

  if (clean.isEmpty) {
    return '';
  }

  return clean
      .split(
    RegExp(
      r'[_\s-]+',
    ),
  )
      .where(
        (part) =>
    part.isNotEmpty,
  )
      .map(
        (part) {
      if (part.length == 1) {
        return part.toUpperCase();
      }

      return '${part[0].toUpperCase()}'
          '${part.substring(1).toLowerCase()}';
    },
  )
      .join(' ');
}

String _friendlyDate(
    DateTime? value,
    ) {
  if (value == null) {
    return '';
  }

  final local =
  value.toLocal();

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  return '${months[local.month - 1]} '
      '${local.day}, '
      '${local.year}';
}