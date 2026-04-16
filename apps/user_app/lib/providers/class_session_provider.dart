import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/class_session.dart';
import '../services/class_session_service.dart';
import '../features/auth/providers/auth_provider.dart';

final classSessionServiceProvider = Provider((ref) => ClassSessionService());

final classSessionsProvider = FutureProvider<List<ClassSession>>((ref) async {
  final user = ref.watch(userProvider);
  if (user == null) return [];
  return ref.watch(classSessionServiceProvider).getSessions();
});
