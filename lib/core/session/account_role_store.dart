import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AccountRole { pilot, company }

class AccountRoleStore extends ChangeNotifier {
  AccountRoleStore._();

  static final instance = AccountRoleStore._();
  static const _roleKey = 'account_role';
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  AccountRole _role = AccountRole.pilot;

  AccountRole get role => _role;

  Future<void> load() async {
    final savedRole = await _preferences.getString(_roleKey);
    _role = savedRole == AccountRole.company.name
        ? AccountRole.company
        : AccountRole.pilot;
  }

  Future<void> setRole(AccountRole role) async {
    _role = role;
    await _preferences.setString(_roleKey, role.name);
    notifyListeners();
  }
}
