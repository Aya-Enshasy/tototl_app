import 'package:flutter/foundation.dart';

import '../../../core/models/rating_summary_model.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';

enum ReviewTargetType {
  pilot,
  company,
}

class ReviewController extends ChangeNotifier {
  final ReviewService service;
  // Verified successful reads only: never convert API errors into "0 reviews".
  static final Map<String, ReviewListModel> _lastGoodByProfile = {};

  static String _cacheKey(ReviewTargetType type, int id) =>
      '${type.name}:$id';

  ReviewController(this.service);

  ReviewListModel? _data;

  bool _isLoading = false;
  bool _isLoadingMore = false;

  String? _errorMessage;

  ReviewTargetType? _targetType;
  int? _targetProfileId;

  ReviewListModel? get data => _data;

  List<ReviewModel> get reviews =>
      _data?.reviews ?? const [];

  RatingSummaryModel get summary =>
      _data?.summary ??
          const RatingSummaryModel();

  ReviewPaginationModel get pagination =>
      _data?.pagination ??
          const ReviewPaginationModel();

  bool get isLoading =>
      _isLoading;

  bool get isLoadingMore =>
      _isLoadingMore;

  bool get isBusy =>
      _isLoading ||
          _isLoadingMore;

  String? get errorMessage =>
      _errorMessage;

  ReviewTargetType? get targetType =>
      _targetType;

  int? get targetProfileId =>
      _targetProfileId;

  bool get hasReviews =>
      reviews.isNotEmpty;

  bool get isEmpty =>
      !_isLoading &&
          reviews.isEmpty;

  bool get canLoadMore =>
      !_isLoading &&
          !_isLoadingMore &&
          pagination.hasNextPage;

  // ===========================================================================
  // PILOT REVIEWS
  // ===========================================================================

  Future<bool> loadPilotReviews(
      int pilotProfileId, {
        bool refresh = false,
      }) async {
    if (pilotProfileId <= 0) {
      _setError(
        'Invalid pilot profile.',
      );

      return false;
    }

    return _loadReviews(
      targetType: ReviewTargetType.pilot,
      targetProfileId: pilotProfileId,
      refresh: refresh,
    );
  }

  // ===========================================================================
  // COMPANY REVIEWS
  // ===========================================================================

  Future<bool> loadCompanyReviews(
      int companyProfileId, {
        bool refresh = false,
      }) async {
    if (companyProfileId <= 0) {
      _setError(
        'Invalid company profile.',
      );

      return false;
    }

    return _loadReviews(
      targetType: ReviewTargetType.company,
      targetProfileId: companyProfileId,
      refresh: refresh,
    );
  }

  // ===========================================================================
  // REFRESH
  // ===========================================================================

  Future<bool> refresh() async {
    final type =
        _targetType;

    final id =
        _targetProfileId;

    if (type == null ||
        id == null ||
        id <= 0) {
      return false;
    }

    return _loadReviews(
      targetType: type,
      targetProfileId: id,
      refresh: true,
    );
  }

  // ===========================================================================
  // LOAD MORE
  // ===========================================================================

  Future<bool> loadMore() async {
    if (!canLoadMore) {
      return false;
    }

    final type =
        _targetType;

    final id =
        _targetProfileId;

    if (type == null ||
        id == null ||
        id <= 0) {
      return false;
    }

    _isLoadingMore = true;
    _errorMessage = null;

    notifyListeners();

    try {
      final nextPage =
          pagination.currentPage + 1;

      final result =
      await _fetchReviews(
        targetType: type,
        targetProfileId: id,
        page: nextPage,
        perPage: pagination.perPage,
      );

      final merged =
      <ReviewModel>[
        ...reviews,
        ...result.reviews,
      ];

      final uniqueById =
      <int, ReviewModel>{};

      final withoutId =
      <ReviewModel>[];

      for (final review in merged) {
        if (review.id > 0) {
          uniqueById[review.id] =
              review;
        } else {
          withoutId.add(
            review,
          );
        }
      }

      final mergedReviews =
      <ReviewModel>[
        ...uniqueById.values,
        ...withoutId,
      ];

      _data =
          ReviewListModel(
            summary: result.summary,
            reviews:
            List<ReviewModel>.unmodifiable(
              mergedReviews,
            ),
            pagination:
            result.pagination,
          );

      _isLoadingMore = false;

      notifyListeners();

      return true;
    } on ReviewException catch (e) {
      _isLoadingMore = false;
      _errorMessage =
          e.message;

      notifyListeners();

      return false;
    } catch (_) {
      _isLoadingMore = false;
      _errorMessage =
      'Unable to load more reviews.';

      notifyListeners();

      return false;
    }
  }

  // ===========================================================================
  // PRIVATE LOAD
  // ===========================================================================

  Future<bool> _loadReviews({
    required ReviewTargetType targetType,
    required int targetProfileId,
    required bool refresh,
  }) async {
    if (_isLoading) {
      return false;
    }

    _targetType =
        targetType;

    _targetProfileId =
        targetProfileId;

    _isLoading = true;
    _errorMessage = null;

    final cacheKey = _cacheKey(targetType, targetProfileId);
    if (_data == null || !refresh) {
      _data = _lastGoodByProfile[cacheKey];
    }

    notifyListeners();

    try {
      final result =
      await _fetchReviews(
        targetType: targetType,
        targetProfileId: targetProfileId,
        page: 1,
        perPage: 15,
      );

      _data = result;
      _lastGoodByProfile[cacheKey] = result;

      _isLoading = false;

      notifyListeners();

      return true;
    } on ReviewException catch (e) {
      _isLoading = false;
      _errorMessage =
          e.message;

      notifyListeners();

      return false;
    } catch (_) {
      _isLoading = false;
      _errorMessage =
      'Unable to load reviews.';

      notifyListeners();

      return false;
    }
  }

  Future<ReviewListModel> _fetchReviews({
    required ReviewTargetType targetType,
    required int targetProfileId,
    required int page,
    required int perPage,
  }) {
    switch (targetType) {
      case ReviewTargetType.pilot:
        return service.getPilotReviews(
          targetProfileId,
          page: page,
          perPage: perPage,
        );

      case ReviewTargetType.company:
        return service.getCompanyReviews(
          targetProfileId,
          page: page,
          perPage: perPage,
        );
    }
  }

  // ===========================================================================
  // STATE HELPERS
  // ===========================================================================

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;

    notifyListeners();
  }

  void clear() {
    _data = null;

    _isLoading = false;
    _isLoadingMore = false;

    _errorMessage = null;

    _targetType = null;
    _targetProfileId = null;

    notifyListeners();
  }

  void _setError(
      String message,
      ) {
    _errorMessage =
        message;

    notifyListeners();
  }
}