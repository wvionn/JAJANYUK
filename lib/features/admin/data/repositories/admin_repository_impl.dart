import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../domain/entities/campus_entity.dart';
import '../../domain/entities/transaction_report_entity.dart';
import '../../domain/repositories/admin_repository.dart';
import '../datasources/admin_remote_datasource.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminRemoteDataSource remoteDataSource;

  AdminRepositoryImpl({required this.remoteDataSource});

  // ── User Management ──

  @override
  Future<Either<Failure, List<UserEntity>>> getAllUsers() async {
    try {
      final result = await remoteDataSource.getAllUsers();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getUsersByRole(String role) async {
    try {
      final result = await remoteDataSource.getUsersByRole(role);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserStatus({
    required String userId,
    required bool isActive,
  }) async {
    try {
      await remoteDataSource.updateUserStatus(
          userId: userId, isActive: isActive);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteUser(String userId) async {
    try {
      await remoteDataSource.deleteUser(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  // ── Seller Management ──

  @override
  Future<Either<Failure, UserEntity>> registerSeller({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? campusId,
  }) async {
    try {
      final result = await remoteDataSource.registerSeller(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        campusId: campusId,
      );
      return Right(result);
    } on AuthException catch (e) {
      return Left(AuthFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<UserEntity>>> getAllSellers() async {
    try {
      final result = await remoteDataSource.getAllSellers();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateSellerStatus({
    required String sellerId,
    required bool isActive,
  }) async {
    try {
      await remoteDataSource.updateSellerStatus(
          sellerId: sellerId, isActive: isActive);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSeller(String sellerId) async {
    try {
      await remoteDataSource.deleteSeller(sellerId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  // ── Campus Management ──

  @override
  Future<Either<Failure, List<CampusEntity>>> getAllCampuses() async {
    try {
      final result = await remoteDataSource.getAllCampuses();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, CampusEntity>> createCampus({
    required String name,
    String? address,
    String? city,
  }) async {
    try {
      final result = await remoteDataSource.createCampus(
        name: name,
        address: address,
        city: city,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateCampus({
    required String campusId,
    String? name,
    String? address,
    String? city,
    bool? isActive,
  }) async {
    try {
      await remoteDataSource.updateCampus(
        campusId: campusId,
        name: name,
        address: address,
        city: city,
        isActive: isActive,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCampus(String campusId) async {
    try {
      await remoteDataSource.deleteCampus(campusId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  // ── Reports ──

  @override
  Future<Either<Failure, PlatformStatsEntity>> getPlatformStats() async {
    try {
      final result = await remoteDataSource.getPlatformStats();
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<TransactionReportEntity>>> getTransactionReports({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      final result = await remoteDataSource.getTransactionReports(
        startDate: startDate,
        endDate: endDate,
        status: status,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}
