import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/class_session.dart';
import '../services/class_session_service.dart';

final classSessionServiceProvider = Provider((ref) => ClassSessionService());

final classSessionsProvider = FutureProvider<List<ClassSession>>((ref) async {
  return ref.watch(classSessionServiceProvider).getSessions();
});
