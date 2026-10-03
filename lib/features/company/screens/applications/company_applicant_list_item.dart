import '../../models/company_job_application_model.dart';
import '../../models/company_job_posting_model.dart';

/// One row returned by GET /company/applicants.
///
/// The backend response already contains:
/// - application scalar fields
/// - nested job_posting
/// - nested pilot_profile
/// - nested drone
///
/// Important:
/// The current /company/applicants response DOES NOT contain a drone image URL.
/// Drone images must be enriched separately from the pilot-drones endpoint when
/// a screen actually needs to display the drone photo.
class CompanyApplicantListItem {
  const CompanyApplicantListItem({
    required this.application,
    required this.jobPosting,
    required this.sourceJson,
  });

  final CompanyJobApplicationModel application;
  final CompanyJobPostingModel? jobPosting;
  final Map<String, dynamic> sourceJson;

  factory CompanyApplicantListItem.fromJson(
      Map<String, dynamic> json,
      ) {
    final rawJob = json['job_posting'];

    return CompanyApplicantListItem(
      application:
      CompanyJobApplicationModel.fromJson(
        json,
      ),
      jobPosting: rawJob is Map
          ? CompanyJobPostingModel.fromJson(
        Map<String, dynamic>.from(rawJob),
      )
          : null,
      sourceJson: _deepCopyMap(json),
    );
  }

  Map<String, dynamic> toJson() =>
      _deepCopyMap(sourceJson);

  CompanyApplicantListItem copyWithApplication(
      CompanyJobApplicationModel value,
      ) {
    // Keep job_posting from the original row while updating the complete
    // application, including nested pilot_profile and drone. This avoids
    // stale cache data after accept/reject or detail enrichment.
    final next = _deepCopyMap(sourceJson)
      ..addAll(
        _deepCopyMap(
          value.toJson(),
        ),
      );

    return CompanyApplicantListItem(
      application: value,
      jobPosting: jobPosting,
      sourceJson: next,
    );
  }
}

Map<String, dynamic> _deepCopyMap(
    Map source,
    ) {
  final result = <String, dynamic>{};

  source.forEach((key, value) {
    result[key.toString()] =
        _deepCopyValue(value);
  });

  return result;
}

dynamic _deepCopyValue(dynamic value) {
  if (value is Map) {
    return _deepCopyMap(value);
  }

  if (value is List) {
    return value
        .map(_deepCopyValue)
        .toList(growable: false);
  }

  return value;
}
