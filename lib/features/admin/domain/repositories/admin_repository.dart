import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../auth/domain/entities/user_entity.dart';

abstract class AdminRepository {
  /// Register a new seller account (Admin only)
  Future<Either<Failure, UserEntity>> registerSeller({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
  });

  /// Get all sellers
  Future<Either<Failure, List<UserEntity>>> getAllSellers();

  /// Update seller status (active/inactive)
  Future<Either<Failure, void>> updateSellerStatus({
    required String sellerId,
    required bool isActive,
  });

  /// Delete seller account
  Future<Either<Failure, void>> deleteSeller(String sellerId);

  /// Get platform statistics
  Future<Either<Failure, Map<String, dynamic>>> getPlatformStats();
}
