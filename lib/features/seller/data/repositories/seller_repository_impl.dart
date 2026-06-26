import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/menu_item_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/entities/vendor_entity.dart';
import '../../domain/entities/seller_profile_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/seller_repository.dart';
import '../datasources/seller_remote_datasource.dart';
import '../models/vendor_model.dart';

class SellerRepositoryImpl implements SellerRepository {
  final SellerRemoteDataSource remoteDataSource;

  SellerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<MenuItemEntity>>> getMenuItems(
      String vendorId) async {
    try {
      return Right(await remoteDataSource.getMenuItems(vendorId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, MenuItemEntity>> addMenuItem({
    required String vendorId,
    required String name,
    String? description,
    required double price,
    required String category,
    required int stock,
    required int estimatedTime,
    String? label,
    bool isAvailable = true,
  }) async {
    try {
      return Right(await remoteDataSource.addMenuItem(
        vendorId: vendorId,
        name: name,
        description: description,
        price: price,
        category: category,
        stock: stock,
        estimatedTime: estimatedTime,
        label: label,
        isAvailable: isAvailable,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, MenuItemEntity>> updateMenuItem({
    required String menuItemId,
    String? name,
    String? description,
    double? price,
    String? category,
    int? stock,
    int? estimatedTime,
    String? label,
    bool? isAvailable,
  }) async {
    try {
      return Right(await remoteDataSource.updateMenuItem(
        menuItemId: menuItemId,
        name: name,
        description: description,
        price: price,
        category: category,
        stock: stock,
        estimatedTime: estimatedTime,
        label: label,
        isAvailable: isAvailable,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMenuItem(String menuItemId) async {
    try {
      await remoteDataSource.deleteMenuItem(menuItemId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getOrders(String vendorId) async {
    try {
      return Right(await remoteDataSource.getOrders(vendorId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    try {
      await remoteDataSource.updateOrderStatus(
          orderId: orderId, status: status);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<ChatMessageEntity>>> getChatMessages(
      String orderId) async {
    try {
      return Right(await remoteDataSource.getChatMessages(orderId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required String orderId,
    required String senderId,
    required String message,
  }) async {
    try {
      return Right(await remoteDataSource.sendMessage(
        orderId: orderId,
        senderId: senderId,
        message: message,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Stream<List<ChatMessageEntity>> watchChatMessages(String orderId) =>
      remoteDataSource.watchChatMessages(orderId);

  @override
  Stream<List<OrderEntity>> watchOrders(String vendorId) =>
      remoteDataSource.watchOrders(vendorId);

  @override
  Future<Either<Failure, SellerProfileEntity>> getSellerProfile(String userId) async {
    try {
      return Right(await remoteDataSource.getSellerProfile(userId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, VendorEntity>> getVendorProfile(String vendorId) async {
    try {
      return Right(await remoteDataSource.getVendorProfile(vendorId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, VendorEntity>> updateVendorProfile(VendorEntity vendor) async {
    try {
      final model = VendorModel(
        id: vendor.id,
        campusId: vendor.campusId,
        name: vendor.name,
        description: vendor.description,
        logoUrl: vendor.logoUrl,
        location: vendor.location,
        phone: vendor.phone,
        openTime: vendor.openTime,
        closeTime: vendor.closeTime,
        isOpen: vendor.isOpen,
        estimatedProcessTime: vendor.estimatedProcessTime,
        verificationStatus: vendor.verificationStatus,
        createdAt: vendor.createdAt,
        updatedAt: vendor.updatedAt,
      );
      return Right(await remoteDataSource.updateVendorProfile(model));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<TransactionEntity>>> getTransactionReports(
    String vendorId, {
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      return Right(await remoteDataSource.getTransactionReports(
        vendorId: vendorId,
        startDate: startDate,
        endDate: endDate,
        status: status,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }
}

