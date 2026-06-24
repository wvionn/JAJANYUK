import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../data/datasources/admin_remote_datasource.dart';
import '../../data/repositories/admin_repository_impl.dart';
import '../../domain/entities/campus_entity.dart';
import '../../domain/entities/transaction_report_entity.dart';
import '../../domain/repositories/admin_repository.dart';

// ── Dependency Injection ──

final adminRemoteDataSourceProvider = Provider<AdminRemoteDataSource>((ref) {
  return AdminRemoteDataSourceImpl(
    supabaseClient: Supabase.instance.client,
  );
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(
    remoteDataSource: ref.watch(adminRemoteDataSourceProvider),
  );
});

// ── State Classes ──

class AdminState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const AdminState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  AdminState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

// ── Users Notifier ──

class UsersNotifier extends StateNotifier<AsyncValue<List<UserEntity>>> {
  final AdminRepository _repository;

  UsersNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadAllUsers();
  }

  Future<void> loadAllUsers() async {
    state = const AsyncValue.loading();
    final result = await _repository.getAllUsers();
    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (users) => state = AsyncValue.data(users),
    );
  }

  Future<void> loadByRole(String role) async {
    state = const AsyncValue.loading();
    final result = await _repository.getUsersByRole(role);
    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (users) => state = AsyncValue.data(users),
    );
  }

  Future<bool> toggleUserStatus(String userId, bool isActive) async {
    final result =
        await _repository.updateUserStatus(userId: userId, isActive: isActive);
    return result.fold(
      (_) => false,
      (_) {
        loadAllUsers();
        return true;
      },
    );
  }

  Future<bool> deleteUser(String userId) async {
    final result = await _repository.deleteUser(userId);
    return result.fold(
      (_) => false,
      (_) {
        loadAllUsers();
        return true;
      },
    );
  }
}

final usersNotifierProvider =
    StateNotifierProvider<UsersNotifier, AsyncValue<List<UserEntity>>>((ref) {
  return UsersNotifier(ref.watch(adminRepositoryProvider));
});

// ── Sellers Notifier ──

class SellersNotifier extends StateNotifier<AsyncValue<List<UserEntity>>> {
  final AdminRepository _repository;

  SellersNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSellers();
  }

  Future<void> loadSellers() async {
    state = const AsyncValue.loading();
    final result = await _repository.getAllSellers();
    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (sellers) => state = AsyncValue.data(sellers),
    );
  }

  Future<String?> registerSeller({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? campusId,
  }) async {
    final result = await _repository.registerSeller(
      email: email,
      password: password,
      fullName: fullName,
      phoneNumber: phoneNumber,
      campusId: campusId,
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        loadSellers();
        return null; // null = success
      },
    );
  }

  Future<bool> toggleSellerStatus(String sellerId, bool isActive) async {
    final result = await _repository.updateSellerStatus(
        sellerId: sellerId, isActive: isActive);
    return result.fold(
      (_) => false,
      (_) {
        loadSellers();
        return true;
      },
    );
  }

  Future<bool> deleteSeller(String sellerId) async {
    final result = await _repository.deleteSeller(sellerId);
    return result.fold(
      (_) => false,
      (_) {
        loadSellers();
        return true;
      },
    );
  }
}

final sellersNotifierProvider =
    StateNotifierProvider<SellersNotifier, AsyncValue<List<UserEntity>>>((ref) {
  return SellersNotifier(ref.watch(adminRepositoryProvider));
});

// ── Campus Notifier ──

class CampusNotifier extends StateNotifier<AsyncValue<List<CampusEntity>>> {
  final AdminRepository _repository;

  CampusNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCampuses();
  }

  Future<void> loadCampuses() async {
    state = const AsyncValue.loading();
    final result = await _repository.getAllCampuses();
    result.fold(
      (failure) =>
          state = AsyncValue.error(failure.message, StackTrace.current),
      (campuses) => state = AsyncValue.data(campuses),
    );
  }

  Future<String?> createCampus({
    required String name,
    String? address,
    String? city,
  }) async {
    final result = await _repository.createCampus(
        name: name, address: address, city: city);
    return result.fold(
      (failure) => failure.message,
      (_) {
        loadCampuses();
        return null;
      },
    );
  }

  Future<String?> updateCampus({
    required String campusId,
    String? name,
    String? address,
    String? city,
    bool? isActive,
  }) async {
    final result = await _repository.updateCampus(
      campusId: campusId,
      name: name,
      address: address,
      city: city,
      isActive: isActive,
    );
    return result.fold(
      (failure) => failure.message,
      (_) {
        loadCampuses();
        return null;
      },
    );
  }

  Future<bool> deleteCampus(String campusId) async {
    final result = await _repository.deleteCampus(campusId);
    return result.fold(
      (_) => false,
      (_) {
        loadCampuses();
        return true;
      },
    );
  }
}

final campusNotifierProvider =
    StateNotifierProvider<CampusNotifier, AsyncValue<List<CampusEntity>>>(
        (ref) {
  return CampusNotifier(ref.watch(adminRepositoryProvider));
});

// ── Stats Provider ──

final platformStatsProvider = FutureProvider<PlatformStatsEntity>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  final result = await repository.getPlatformStats();
  return result.fold(
    (failure) => throw failure.message,
    (stats) => stats,
  );
});

// ── Transaction Reports Notifier ──

class TransactionReportState {
  final List<TransactionReportEntity> reports;
  final bool isLoading;
  final String? error;
  final String filterStatus;
  final DateTime? startDate;
  final DateTime? endDate;

  const TransactionReportState({
    this.reports = const [],
    this.isLoading = true,
    this.error,
    this.filterStatus = 'all',
    this.startDate,
    this.endDate,
  });

  TransactionReportState copyWith({
    List<TransactionReportEntity>? reports,
    bool? isLoading,
    String? error,
    String? filterStatus,
    DateTime? startDate,
    DateTime? endDate,
    bool clearError = false,
    bool clearDates = false,
  }) {
    return TransactionReportState(
      reports: reports ?? this.reports,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filterStatus: filterStatus ?? this.filterStatus,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
    );
  }
}

class TransactionReportNotifier extends StateNotifier<TransactionReportState> {
  final AdminRepository _repository;

  TransactionReportNotifier(this._repository)
      : super(const TransactionReportState()) {
    loadReports();
  }

  Future<void> loadReports({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    final filterStatus = status ?? state.filterStatus;
    final from = startDate ?? state.startDate;
    final to = endDate ?? state.endDate;

    final result = await _repository.getTransactionReports(
      status: filterStatus == 'all' ? null : filterStatus,
      startDate: from,
      endDate: to,
    );

    result.fold(
      (failure) =>
          state = state.copyWith(isLoading: false, error: failure.message),
      (reports) => state = state.copyWith(
        reports: reports,
        isLoading: false,
        filterStatus: filterStatus,
        startDate: from,
        endDate: to,
      ),
    );
  }

  void setFilter(String status) {
    loadReports(status: status);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    loadReports(startDate: start, endDate: end);
  }

  void clearFilters() {
    state = state.copyWith(filterStatus: 'all', clearDates: true);
    loadReports(status: 'all');
  }
}

final transactionReportNotifierProvider =
    StateNotifierProvider<TransactionReportNotifier, TransactionReportState>(
        (ref) {
  return TransactionReportNotifier(ref.watch(adminRepositoryProvider));
});
