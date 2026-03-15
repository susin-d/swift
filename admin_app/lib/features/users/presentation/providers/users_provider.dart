import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_user.dart';
import '../../data/services/users_service.dart';

class UsersState {
  const UsersState({
    required this.users,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<AdminUser> users;
  final int page;
  final int limit;
  final int total;

  bool get hasMore => page * limit < total;

  UsersState copyWith({
    List<AdminUser>? users,
    int? page,
    int? limit,
    int? total,
  }) {
    return UsersState(
      users: users ?? this.users,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
    );
  }
}

class UsersNotifier extends AsyncNotifier<UsersState> {
  static const int defaultPageSize = 20;

  @override
  Future<UsersState> build() async {
    final response = await UsersService.instance.fetchUsers(page: 1, limit: defaultPageSize);
    return UsersState(
      users: response.users,
      page: response.page,
      limit: response.limit,
      total: response.total,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final response = await UsersService.instance.fetchUsers(page: 1, limit: defaultPageSize);
      return UsersState(
        users: response.users,
        page: response.page,
        limit: response.limit,
        total: response.total,
      );
    });
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore) return;

    final nextPage = current.page + 1;
    final response = await UsersService.instance.fetchUsers(page: nextPage, limit: current.limit);

    state = AsyncData(current.copyWith(
      page: response.page,
      total: response.total,
      users: [...current.users, ...response.users],
    ));
  }

  Future<String?> toggleBlocked(AdminUser user, {String? reason}) async {
    try {
      await UsersService.instance.setBlocked(user.id, !user.blocked, reason: reason);
      await refresh();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> changeRole(AdminUser user, String role) async {
    try {
      await UsersService.instance.updateRole(user.id, role);
      await refresh();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

final usersProvider = AsyncNotifierProvider<UsersNotifier, UsersState>(
  UsersNotifier.new,
);
