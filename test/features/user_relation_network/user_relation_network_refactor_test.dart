import 'package:flutter_test/flutter_test.dart';
import 'package:portugal_guide/app/core/auth/auth_token_manager.dart';
import 'package:portugal_guide/app/core/config/injector.dart';
import 'package:portugal_guide/features/main_contents/topic/ownership_repository_interface.dart';
import 'package:portugal_guide/features/user/user_repository_interface.dart';
import 'package:portugal_guide/features/user_relation_network/connection_profile_model.dart';
import 'package:portugal_guide/features/user_relation_network/user_relation_network_screen.dart';
import 'package:portugal_guide/features/user_relation_network/user_relation_network_view_model.dart';

class _FakeUserRepository extends Fake implements UserRepositoryInterface {}

class _FakeAuthTokenManager extends Fake implements AuthTokenManager {}

class _FakeOwnershipRepository extends Fake
    implements OwnershipRepositoryInterface {}

void main() {
  test('relocated screen retains its public constructor', () {
    injector.registerSingleton<AuthTokenManager>(_FakeAuthTokenManager());
    addTearDown(() => injector.unregister<AuthTokenManager>());
    const screen = UserRelationNetworkScreen();
    expect(screen.createState(), isNotNull);
  });

  test('relocated model preserves copy semantics and connection labels', () {
    const profile = ConnectionProfileModel(
      id: 'profile-1',
      name: 'Profile',
      avatarUrl: 'assets/images/avatar.png',
      isOnline: false,
      status: ConnectionStatus.suggested,
    );

    final updated = profile.copyWith(
      name: 'Updated profile',
      isOnline: true,
      status: ConnectionStatus.connected,
    );

    expect(updated.id, profile.id);
    expect(updated.avatarUrl, profile.avatarUrl);
    expect(updated.name, 'Updated profile');
    expect(updated.isOnline, isTrue);
    expect(updated.status, ConnectionStatus.connected);
    expect(profile.name, 'Profile');
    expect(profile.isOnline, isFalse);
    expect(ConnectionStatus.connected.displayName, 'Conectado');
    expect(ConnectionStatus.following.displayName, 'Seguindo');
    expect(ConnectionStatus.suggested.displayName, 'Conectar');
  });

  test(
    'relocated view model accepts repositories and notifies on query changes',
    () {
      final viewModel = UserRelationNetworkViewModel(
        userRepository: _FakeUserRepository(),
        ownershipRepository: _FakeOwnershipRepository(),
      );
      addTearDown(viewModel.dispose);
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      expect(viewModel.searchQuery, isEmpty);
      expect(viewModel.connections, isEmpty);
      expect(viewModel.ownershipContents, isEmpty);
      expect(viewModel.isLoadingConnections, isFalse);
      expect(viewModel.isLoadingOwnership, isFalse);

      viewModel.setSearchQuery('Portugal');
      expect(viewModel.searchQuery, 'Portugal');
      expect(notifications, 1);

      viewModel.setSearchQuery('Portugal');
      expect(notifications, 1);

      viewModel.setSearchQuery('');
      expect(viewModel.searchQuery, isEmpty);
      expect(notifications, 2);
    },
  );
}
