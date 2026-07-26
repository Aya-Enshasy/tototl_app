import 'package:flutter/foundation.dart';

import '../pilot/shared/pilot_data.dart';

enum MissionStage {
  offerSent,
  awaitingFunding,
  scheduled,
  inProgress,
  submitted,
  completed,
  rejected,
}

extension MissionStageLabel on MissionStage {
  String get label => switch (this) {
    MissionStage.offerSent => 'Offer sent',
    MissionStage.awaitingFunding => 'Ready for funding',
    MissionStage.scheduled => 'Scheduled',
    MissionStage.inProgress => 'In progress',
    MissionStage.submitted => 'Awaiting confirmation',
    MissionStage.completed => 'Completed',
    MissionStage.rejected => 'Declined',
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
    this.pilotRating,
    this.companyRating,
  });
  final String id;
  final PilotApplication application;
  final String date;
  final int hours;
  final double amount;
  MissionStage stage;
  int? pilotRating;
  int? companyRating;
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
        time: 'Just now',
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
        time: 'Just now',
      ),
    );
    notifyListeners();
  }

  void acceptOffer(Mission mission) {
    mission.stage = MissionStage.awaitingFunding;
    notifyListeners();
  }

  void rejectOffer(Mission mission) {
    mission.stage = MissionStage.rejected;
    notifyListeners();
  }

  void fundEscrow(Mission mission) {
    mission.stage = MissionStage.scheduled;
    notifyListeners();
  }

  void startMission(Mission mission) {
    mission.stage = MissionStage.inProgress;
    notifyListeners();
  }

  void submitWork(Mission mission) {
    mission.stage = MissionStage.submitted;
    notifyListeners();
  }

  void confirmAndRelease(Mission mission) {
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
