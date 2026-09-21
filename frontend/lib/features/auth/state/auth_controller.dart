import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/networking/api_client.dart';
import '../../../core/networking/api_exception.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(ref.watch(apiClientProvider)),
);

/// Session status. The router switches on this, so it is deliberately
/// small: three states and nothing else to interpret.
enum AuthStatus { checking, signedOut, signedIn }

class AuthState {
  const AuthState({
    this.status = AuthStatus.checking,
    this.user,
    this.error,
    this.deactivated = false,
  });

  final AuthStatus status;
  final AuthUser? user;

  /// Last failure, for the form to display. Cleared on the next attempt.
  final String? error;

  /// True when the last login attempt found a paused account, so the form
  /// can offer to restore it rather than only reporting a failure.
  final bool deactivated;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    String? error,
    bool? deactivated,
  }) =>
      AuthState(
        status: status ?? this.status,
        user: user ?? this.user,
        error: error,
        deactivated: deactivated ?? false,
      );
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Deliberately not awaited: build must be synchronous, and the UI
    // shows a checking state until this resolves.
    _restore();
    return const AuthState();
  }

  ApiClient get _api => ref.read(apiClientProvider);
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Reuses a stored token if the server still accepts it.
  Future<void> _restore() async {
    await _api.loadToken();

    if (_api.token == null) {
      state = const AuthState(status: AuthStatus.signedOut);
      return;
    }

    try {
      final user = await _repo.me();
      state = AuthState(status: AuthStatus.signedIn, user: user);
    } catch (_) {
      // Expired, revoked, or the account was paused. Either way the token
      // is useless, so discard it rather than retrying.
      await _api.clearToken();
      state = const AuthState(status: AuthStatus.signedOut);
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.checking);

    try {
      final user = await _repo.login(email: email, password: password);
      state = AuthState(status: AuthStatus.signedIn, user: user);
      return true;
    } on ApiException catch (e) {
      // 423 means the credentials were right but the account is paused.
      // The form offers restoration rather than showing an error.
      final paused = e.statusCode == 423;
      state = AuthState(
        status: AuthStatus.signedOut,
        error: paused ? null : e.message,
        deactivated: paused,
      );
      return false;
    } catch (e) {
      state = AuthState(status: AuthStatus.signedOut, error: e.toString());
      return false;
    }
  }

  Future<bool> register(String email, String name, String password) =>
      _attempt(() => _repo.register(email: email, name: name, password: password));

  /// Restores a paused account and signs in.
  Future<bool> reactivate(String email, String password) =>
      _attempt(() => _repo.reactivate(email: email, password: password));

  /// Shared shape: try, land on signed in or an error message. Returns
  /// whether it worked, so the form can react.
  Future<bool> _attempt(Future<AuthUser> Function() action) async {
    state = state.copyWith(status: AuthStatus.checking);

    try {
      final user = await action();
      state = AuthState(status: AuthStatus.signedIn, user: user);
      return true;
    } catch (e) {
      state = AuthState(status: AuthStatus.signedOut, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState(status: AuthStatus.signedOut);
  }

  /// Drops the session without calling the server.
  ///
  /// Used after deactivating or deleting, where the token is already dead
  /// and a logout request would only fail.
  Future<void> clearSession() async {
    await _api.clearToken();
    state = const AuthState(status: AuthStatus.signedOut);
  }

  /// Re-reads the account from the server.
  ///
  /// Used after editing name or email, since the user object in state is
  /// a snapshot taken at sign-in.
  Future<void> refreshUser() async {
    try {
      final user = await _repo.me();
      state = AuthState(status: AuthStatus.signedIn, user: user);
    } catch (_) {
      // A failure here is not worth signing someone out over: the change
      // saved, only the local copy is stale.
    }
  }

}

final authControllerProvider =
    NotifierProvider<AuthController, AuthState>(AuthController.new);