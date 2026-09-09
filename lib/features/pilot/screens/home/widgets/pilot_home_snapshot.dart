 import 'package:tototl_app/features/pilot/models/pilot_application_model.dart';

import '../../../models/drone_model.dart';

/// Lightweight view-model used only by the Pilot Home screen.
///
/// The authoritative models are cached by their own services. Keeping the Home
/// snapshot lightweight avoids maintaining a second, duplicated cache format.
class PilotHomeSnapshot {
  const PilotHomeSnapshot({
    this.drones = const <PilotHomeDroneItem>[],
    this.applications = const <PilotHomeApplicationItem>[],
  });

  final List<PilotHomeDroneItem> drones;
  final List<PilotHomeApplicationItem> applications;

  PilotHomeSnapshot copyWith({
    List<PilotHomeDroneItem>? drones,
    List<PilotHomeApplicationItem>? applications,
  }) {
    return PilotHomeSnapshot(
      drones: drones ?? this.drones,
      applications: applications ?? this.applications,
    );
  }
}

class PilotHomeDroneItem {
  const PilotHomeDroneItem({
    required this.id,
    this.title = 'Drone',
    this.year = '',
    this.serialNumber = '',
    this.capabilities = const <String>[],
    this.imageUrl = '',
  });

  final int id;
  final String title;
  final String year;
  final String serialNumber;
  final List<String> capabilities;
  final String imageUrl;

  factory PilotHomeDroneItem.fromDrone(DroneModel drone) {
    return PilotHomeDroneItem(
      id: drone.id,
      title: drone.title,
      year: drone.yearLabel,
      serialNumber: drone.serialNumber.trim(),
      capabilities: List<String>.unmodifiable(drone.capabilities),
      imageUrl: drone.imageUrl.trim(),
    );
  }
}

class PilotHomeApplicationItem {
  const PilotHomeApplicationItem({
    required this.id,
    this.jobTitle = 'Job application',
    this.company = '',
    this.location = '',
    this.status = '',
    this.statusLabel = '',
    this.submittedLabel = '',
  });

  final int id;
  final String jobTitle;
  final String company;
  final String location;
  final String status;
  final String statusLabel;
  final String submittedLabel;

  factory PilotHomeApplicationItem.fromApplication(
      PilotApplicationModel application,
      ) {
    final rawLocation = application.job?.detailedLocationLabel.trim() ?? '';
    final location = rawLocation.toLowerCase() == 'not specified'
        ? ''
        : rawLocation;

    return PilotHomeApplicationItem(
      id: application.id,
      jobTitle: application.jobTitle.trim().isEmpty
          ? 'Job application'
          : application.jobTitle.trim(),
      company: application.companyLabel.trim(),
      location: location,
      status: application.status.trim(),
      statusLabel: application.statusLabel.trim(),
      submittedLabel: application.submittedLabel.trim(),
    );
  }
}
