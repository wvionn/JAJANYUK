import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../entities/campus_entity.dart';
import '../entities/transaction_report_entity.dart';

abstract class AdminRepository {
  // ── User Management ──
  Future<Either<Failure, List<UserEntity>>> getAllUsers();
  Future<Either<Failure, List<UserEntity>>> getUsersByRole(String role);
  Future<Either<Failure, void>> updateUserStatus({
    required String userId,
    required bool isActive,
  });
  Future<Either<Failure, void>> deleteUser(String userId);

  // ── Seller / Kantin Management ──
  Future<Either<Failure, UserEntity>> registerSeller({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? campusId,
  });
  Future<Either<Failure, List<UserEntity>>> getAllSellers();
  Future<Either<Failure, void>> updateSellerStatus({
    required String sellerId,
    required bool isActive,
  });
  Future<Either<Failure, void>> deleteSeller(String sellerId);

  // ── Campus Management ──
  Future<Either<Failure, List<CampusEntity>>> getAllCampuses();
  Future<Either<Failure, CampusEntity>> createCampus({
    required String name,
    String? address,
    String? city,
  });
  Future<Either<Failure, void>> updateCampus({
    required String campusId,
    String? name,
    String? address,
    String? city,
    bool? isActive,
  });
  Future<Either<Failure, void>> deleteCampus(String campusId);

  // ── Reports & Stats ──
  Future<Either<Failure, PlatformStatsEntity>> getPlatformStats();
  Future<Either<Failure, List<TransactionReportEntity>>> getTransactionReports({
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  });
}
