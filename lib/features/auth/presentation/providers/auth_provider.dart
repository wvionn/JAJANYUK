import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    supabaseClient: Supabase.instance.client,
  );
});

class AuthNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCurrentUser();
  }

  Future<void> loadCurrentUser() async {
    state = const AsyncValue.loading();
    final result = await _repository.getCurrentUser();
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (user) => state = AsyncValue.data(user),
    );
  }

  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.login(email: email, password: password);
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return Left(failure);
      },
      (user) {
        state = AsyncValue.data(user);
        return Right(user);
      },
    );
  }

  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? campusId,
  }) async {
    state = const AsyncValue.loading();
    final result = await _repository.register(
      email: email,
      password: password,
      fullName: fullName,
      phoneNumber: phoneNumber,
      campusId: campusId,
    );
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return Left(failure);
      },
      (user) {
        // Jangan simpan ke state auth secara langsung jika butuh verifikasi email dahulu,
        // tapi jika bypass verifikasi atau langsung login, simpan ke state.
        // Di sini kita update state untuk kenyamanan testing.
        state = AsyncValue.data(user);
        return Right(user);
      },
    );
  }

  Future<Either<Failure, void>> logout() async {
    state = const AsyncValue.loading();
    final result = await _repository.logout();
    return result.fold(
      (failure) {
        state = AsyncValue.error(failure.message, StackTrace.current);
        return Left(failure);
      },
      (_) {
        state = const AsyncValue.data(null);
        return const Right(null);
      },
    );
  }

  Future<Either<Failure, void>> resetPassword(String email) async {
    return await _repository.resetPassword(email);
  }
}

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserEntity?>>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
