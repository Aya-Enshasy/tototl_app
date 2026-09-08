import 'package:flutter/foundation.dart';
import 'package:tototl_app/features/pilot/services/pilot_application_service.dart';

import '../models/pilot_home_snapshot.dart';
import '../services/drone_service.dart';
import '../services/pilot_home_cache.dart';

class PilotHomeController extends ChangeNotifier {
  PilotHomeController({
    required this.applicationService,
    required this.droneService,
  });

  final PilotApplicationService applicationService;
  final DroneService droneService;

  PilotHomeSnapshot? snapshot;
  bool isInitialLoading = true;
  bool isRefreshing = false;
  String? errorMessage;
  String? dronesError;
  String? applicationsError;

  bool get hasCachedOrFreshData => snapshot != null;

  Future<void> bootstrap() async {
    final cached = await PilotHomeCache.read();

    if (cached != null) {
      snapshot = cached;
      isInitialLoading = false;
      notifyListeners();
    } else {
      isInitialLoading = true;
      notifyListeners();
    }

    // Stale-while-revalidate:
    // show cached content immediately, then refresh silently in the background.
    Future<void>.microtask(refreshSilently);
  }

  Future<void> refreshSilently() async {
    if (isRefreshing) return;

    isRefreshing = true;
    errorMessage = null;
    dronesError = null;
    applicationsError = null;

    final previous = snapshot ?? const PilotHomeSnapshot();

    List<PilotHomeApplicationItem>? freshApplications;
    List<PilotHomeDroneItem>? freshDrones;
    final failures = <String>[];

    await Future.wait<void>([
      () async {
        try {
          final applications = await applicationService.getMyApplications();
          freshApplications = applications
              .take(3)
              .map(PilotHomeApplicationItem.fromApplication)
              .toList(growable: false);
        } catch (e) {
          applicationsError = e.toString();
          failures.add(e.toString());
        }
      }(),
      () async {
        try {
          final drones = await droneService.getMyDrones();
          freshDrones = drones
              .take(10)
              .map(PilotHomeDroneItem.fromDrone)
              .toList(growable: false);
        } catch (e) {
          dronesError = e.toString();
          failures.add(e.toString());
        }
      }(),
    ]);

    final anySuccess = freshApplications != null || freshDrones != null;

    if (anySuccess) {
      final freshSnapshot = PilotHomeSnapshot(
        applications: freshApplications ?? previous.applications,
        drones: freshDrones ?? previous.drones,
        cachedAt: DateTime.now(),
      );

      snapshot = freshSnapshot;
      await PilotHomeCache.write(freshSnapshot);
      errorMessage = null;
    } else if (snapshot == null) {
      errorMessage = failures.isEmpty
          ? 'Unable to load your home data.'
          : failures.first;
    }

    isInitialLoading = false;
    isRefreshing = false;
    notifyListeners();
  }

  Future<void> forceRefresh() async {
    await refreshSilently();
  }
}
