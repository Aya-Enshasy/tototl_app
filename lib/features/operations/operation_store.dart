import 'package:flutter/foundation.dart';
import 'package:tototl_app/core/localization/app_language.dart';

import '../pilot/screens/shared/pilot_data.dart';



enum MissionStage {
  offerSent,
  contractPending,
  contractSigned,
  readyToStart,
  inProgress,
  terminationPending,
  terminationSigned,
  paymentPending,
  paymentSent,
  completed,
  rejected,
}

extension MissionStageLabel on MissionStage {
  String get label => switch (this) {
    MissionStage.offerSent => AppLanguage.text('Offer sent'),
    MissionStage.contractPending => AppLanguage.text('Contract pending'),
    MissionStage.contractSigned => AppLanguage.text('Contract signed'),
    MissionStage.readyToStart => AppLanguage.text('Ready to start'),
    MissionStage.inProgress => AppLanguage.text('In progress'),
    MissionStage.terminationPending => AppLanguage.text('Ending contract'),
    MissionStage.terminationSigned => AppLanguage.text('Termination signed'),
    MissionStage.paymentPending => AppLanguage.text('Payment pending'),
    MissionStage.paymentSent => AppLanguage.text('Payment sent'),
    MissionStage.completed => AppLanguage.text('Completed'),
    MissionStage.rejected => AppLanguage.text('Declined'),
  };
}

class Mission {
  Mission({
    required this.id,
    required this.application,
    required this.date,
    required this.hours,
    required this.amount,
    required this.stage,
    this.contractFileName,
    this.terminationFileName,
    this.companyStarted = false,
    this.pilotStarted = false,
    this.companyEnded = false,
    this.pilotEnded = false,
    this.pilotRating,
    this.companyRating,
  });
  final String id;
  final PilotApplication application;
  final String date;
  final int hours;
  final double amount;
  MissionStage stage;
  String? contractFileName;
  String? terminationFileName;
  bool companyStarted;
  bool pilotStarted;
  bool companyEnded;
  bool pilotEnded;
  int? pilotRating;
  int? companyRating;

  bool get bothStarted => companyStarted && pilotStarted;
  bool get bothEnded => companyEnded && pilotEnded;
  bool get bothRated => pilotRating != null && companyRating != null;
}

class ChatMessage {
  ChatMessage({
    required this.id,
    required this.applicationId,
    required this.text,
    required this.isCompany,
    required this.time,
  });
  final String id;
  final String applicationId;
  final String text;
  final bool isCompany;
  final String time;
}

class OperationStore extends ChangeNotifier {
  OperationStore._();
  static final instance = OperationStore._();
  final List<Mission> _missions = [];
  final List<ChatMessage> _messages = [];

  List<Mission> get missions => List.unmodifiable(_missions);
  Mission? missionFor(String applicationId) =>
      _missions.cast<Mission?>().firstWhere(
        (mission) => mission!.application.id == applicationId,
        orElse: () => null,
      );

  Mission ensureApprovedMission(PilotApplication application) {
    final existing = missionFor(application.id);
    if (existing != null) return existing;
    final parsedAmount =
        double.tryParse(application.job.pay.replaceAll(RegExp(r'[^0-9.]'), '')) ??
        850;
    final mission = Mission(
      id: 'mission-${DateTime.now().millisecondsSinceEpoch}',
      application: application,
      date: application.job.date,
      hours: 8,
      amount: parsedAmount,
      stage: MissionStage.contractPending,
    );
    _missions.add(mission);
    _messages.add(
      ChatMessage(
        id: 'message-${DateTime.now().millisecondsSinceEpoch}',
        applicationId: application.id,
        text:
            AppLanguage.text('Application approved. The company can upload the contract, then both sides confirm start.'),
        isCompany: true,
        time: AppLanguage.text('Just now'),
      ),
    );
    notifyListeners();
    return mission;
  }
  List<ChatMessage> messagesFor(String applicationId) => _messages
      .where((message) => message.applicationId == applicationId)
      .toList();
  double get pilotAvailableBalance => _missions
      .where((mission) => mission.stage == MissionStage.completed)
      .fold(0, (sum, mission) => sum + mission.amount);
  double get companyEscrowBalance => _missions
      .where(
        (mission) =>
            mission.stage != MissionStage.completed &&
            mission.stage != MissionStage.rejected &&
            mission.stage != MissionStage.offerSent,
      )
      .fold(0, (sum, mission) => sum + mission.amount);

  Mission sendOffer(
    PilotApplication application, {
    required String date,
    required int hours,
    required double amount,
  }) {
    final mission = Mission(
      id: 'mission-${DateTime.now().millisecondsSinceEpoch}',
      application: application,
      date: date,
      hours: hours,
      amount: amount,
      stage: MissionStage.offerSent,
    );
    _missions.add(mission);
    _messages.add(
      ChatMessage(
        id: 'message-${DateTime.now().millisecondsSinceEpoch}',
        applicationId: application.id,
        text:
            'We sent an offer for \$${amount.toStringAsFixed(0)} on $date ($hours hours).',
        isCompany: true,
        time: AppLanguage.text('Just now'),
      ),
    );
    notifyListeners();
    return mission;
  }

  void sendMessage(
    String applicationId,
    String text, {
    required bool isCompany,
  }) {
    if (text.trim().isEmpty) return;
    _messages.add(
      ChatMessage(
        id: 'message-${DateTime.now().millisecondsSinceEpoch}',
        applicationId: applicationId,
        text: text.trim(),
        isCompany: isCompany,
        time: AppLanguage.text('Just now'),
      ),
    );
    notifyListeners();
  }

  void acceptOffer(Mission mission) {
    mission.stage = MissionStage.contractPending;
    notifyListeners();
  }

  void rejectOffer(Mission mission) {
    mission.stage = MissionStage.rejected;
    notifyListeners();
  }

  void cancelMission(Mission mission) {
    mission.stage = MissionStage.rejected;
    notifyListeners();
  }

  void fundEscrow(Mission mission) {
    mission.stage = MissionStage.readyToStart;
    notifyListeners();
  }

  void startMission(Mission mission) {
    markStartReady(mission, byCompany: false);
  }

  void submitWork(Mission mission) {
    markWorkEnded(mission, byCompany: false);
  }

  void confirmAndRelease(Mission mission) {
    mission.stage = MissionStage.paymentSent;
    notifyListeners();
  }

  void uploadContract(Mission mission) {
    mission.contractFileName = 'services-contract-${mission.application.id}.pdf';
    mission.stage = MissionStage.contractPending;
    notifyListeners();
  }

  void signContract(Mission mission) {
    mission.stage = MissionStage.contractSigned;
    notifyListeners();
  }

  void markStartReady(Mission mission, {required bool byCompany}) {
    mission.companyStarted = true;
    mission.pilotStarted = true;
    mission.stage = MissionStage.inProgress;
    notifyListeners();
  }

  void uploadTermination(Mission mission) {
    mission.terminationFileName =
        'termination-agreement-${mission.application.id}.pdf';
    mission.stage = MissionStage.terminationPending;
    notifyListeners();
  }

  void markWorkEnded(Mission mission, {required bool byCompany}) {
    mission.companyEnded = true;
    mission.pilotEnded = true;
    mission.stage = MissionStage.terminationPending;
    notifyListeners();
  }

  void signTermination(Mission mission) {
    mission.stage = MissionStage.terminationSigned;
    notifyListeners();
  }

  void openSecurePayment(Mission mission) {
    mission.stage = MissionStage.paymentPending;
    notifyListeners();
  }

  void sendPilotPayment(Mission mission) {
    mission.stage = MissionStage.paymentSent;
    notifyListeners();
  }

  void confirmPaymentReceived(Mission mission) {
    mission.stage = MissionStage.completed;
    notifyListeners();
  }

  void ratePilot(Mission mission, int rating) {
    mission.pilotRating = rating;
    notifyListeners();
  }

  void rateCompany(Mission mission, int rating) {
    mission.companyRating = rating;
    notifyListeners();
  }
}
