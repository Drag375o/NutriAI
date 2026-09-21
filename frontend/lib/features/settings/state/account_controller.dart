import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/auth_controller.dart';
import '../data/account_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>(
  (ref) => AccountRepository(ref.watch(apiClientProvider)),
);

class AccountController extends Notifier<void> {
  @override
  void build() {}

  AccountRepository get _repo => ref.read(accountRepositoryProvider);

  /// Each of these returns an error message on failure rather than
  /// throwing, so a dialog can show it inline without a try/catch.

  Future<String?> changePassword({
    required String current,
    required String replacement,
  }) async {
    try {
      await _repo.changePassword(current: current, replacement: replacement);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deactivate() async {
    try {
      await _repo.deactivate();
      // The token is dead the moment the account is paused, so the session
      // is cleared locally rather than by calling logout.
      await ref.read(authControllerProvider.notifier).clearSession();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> deleteAccount(String password) async {
    try {
      await _repo.deleteAccount(password);
      await ref.read(authControllerProvider.notifier).clearSession();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateDetails({String? name, String? email}) async {
    try {
      await _repo.updateDetails(name: name, email: email);
      // The signed-in user is held in auth state, so it has to be
      // refreshed for the new value to appear on screen.
      await ref.read(authControllerProvider.notifier).refreshUser();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

}



final accountControllerProvider =
    NotifierProvider<AccountController, void>(AccountController.new);