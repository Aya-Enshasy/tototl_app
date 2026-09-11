

import '../../models/company_job_application_model.dart';
import '../../models/company_job_posting_model.dart';

/// One row returned by GET /company/applicants.
///
/// The endpoint returns the application itself plus a nested job_posting,
/// pilot_profile and drone. [CompanyJobApplicationModel] already parses the
/// application/pilot/drone portion, while this wrapper keeps the nested job
/// posting available for the Applications list UI and preserves the original
/// JSON for local caching.
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
      application: CompanyJobApplicationModel.fromJson(json),
      jobPosting: rawJob is Map
          ? CompanyJobPostingModel.fromJson(
        Map<String, dynamic>.from(rawJob),
      )
          : null,
      sourceJson: _deepCopyMap(json),
    );
  }

  Map<String, dynamic> toJson() => _deepCopyMap(sourceJson);

  CompanyApplicantListItem copyWithApplication(
      CompanyJobApplicationModel value,
      ) {
    final next = _deepCopyMap(sourceJson)
      ..['id'] = value.id
      ..['job_posting_id'] = value.jobPostingId
      ..['pilot_profile_id'] = value.pilotProfileId
      ..['drone_id'] = value.droneId
      ..['cover_message'] = value.coverMessage
      ..['status'] = value.status
      ..['decided_at'] = value.decidedAt?.toIso8601String()
      ..['withdrawn_at'] = value.withdrawnAt?.toIso8601String()
      ..['created_at'] = value.createdAt?.toIso8601String()
      ..['rejection_reason'] = value.rejectionReason;

    return CompanyApplicantListItem(
      application: value,
      jobPosting: jobPosting,
      sourceJson: next,
    );
  }
}

Map<String, dynamic> _deepCopyMap(Map source) {
  final result = <String, dynamic>{};

  source.forEach((key, value) {
    result[key.toString()] = _deepCopyValue(value);
  });

  return result;
}

dynamic _deepCopyValue(dynamic value) {
  if (value is Map) {
    return _deepCopyMap(value);
  }

  if (value is List) {
    return value.map(_deepCopyValue).toList(growable: false);
  }

  return value;
}
