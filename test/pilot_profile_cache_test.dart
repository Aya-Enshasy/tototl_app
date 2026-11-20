import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:tototl_app/core/network/api_client.dart';
import 'package:tototl_app/core/storage/user_session_storage.dart';
import 'package:tototl_app/features/pilot/controllers/pilot_profile_controller.dart';
import 'package:tototl_app/features/pilot/services/pilot_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  final controller = PilotProfileController(PilotProfileService(ApiClient()));

  setUp(() async => UserSessionStorage.clearSession());

  test('login without embedded /me profile still displays the pilot account', () async {
    await UserSessionStorage.saveSession({
      'role': 'pilot',
      'user': {'id': 9101, 'name': 'Test Pilot', 'email': 'pilot@example.test'},
    });
    final cached = await controller.loadLocalProfile();
    expect(cached, isNotNull);
    expect(cached!.account.displayName, 'Test Pilot');
    expect(cached.profile.userId, 9101);
    expect(cached.profile.id, isNull);
  });

  test('re-login restores the same account encrypted profile snapshot', () async {
    await UserSessionStorage.saveSession({
      'role': 'pilot',
      'user': {'id': 9102, 'name': 'Old Pilot'},
      'profile': {'id': 111, 'user_id': 9102, 'bio': 'Saved offline bio'},
    });
    await UserSessionStorage.clearSession();
    await UserSessionStorage.saveSession({
      'role': 'pilot',
      'user': {'id': 9102, 'name': 'New Pilot Name'},
    });
    final cached = await controller.loadLocalProfile();
    expect(cached!.account.displayName, 'New Pilot Name');
    expect(cached.profile.bio, 'Saved offline bio');
    expect(cached.profile.id, 111);
  });

  test('switching accounts never displays another pilot profile', () async {
    await UserSessionStorage.saveSession({
      'role': 'pilot',
      'user': {'id': 9103, 'name': 'Pilot A'},
      'profile': {'id': 444, 'user_id': 9103, 'bio': 'Private A'},
    });
    await UserSessionStorage.clearSession();
    await UserSessionStorage.saveSession({
      'role': 'pilot',
      'user': {'id': 9104, 'name': 'Pilot B'},
    });
    final cached = await controller.loadLocalProfile();
    expect(cached!.account.displayName, 'Pilot B');
    expect(cached.profile.id, isNull);
    expect(cached.profile.bio, isEmpty);
  });

  test('company role is not rendered as a pilot', () async {
    await UserSessionStorage.saveSession({
      'role': 'company',
      'user': {'id': 9105, 'name': 'Company A'},
    });
    expect(await controller.loadLocalProfile(), isNull);
  });
}
