import 'package:dartz/dartz.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/menu_item_entity.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/seller_repository.dart';
import '../datasources/seller_remote_datasource.dart';

class SellerRepositoryImpl implements SellerRepository {
  final SellerRemoteDataSource remoteDataSource;

  SellerRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<MenuItemEntity>>> getMenuItems(
      String sellerId) async {
    try {
      return Right(await remoteDataSource.getMenuItems(sellerId));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, MenuItemEntity>> addMenuItem({
    required String sellerId,
    required String name,
    String? description,
    required double price,
    String? category,
    bool available = true,
  }) async {
    try {
      return Right(await remoteDataSource.addMenuItem(
        sellerId: sellerId,
        name: name,
        description: description,
        price: price,
        category: category,
        available: available,
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
    bool? available,
  }) async {
    try {
      return Right(await remoteDataSource.updateMenuItem(
        menuItemId: menuItemId,
        name: name,
        description: description,
        price: price,
        category: category,
        available: available,
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
  Future<Either<Failure, List<OrderEntity>>> getOrders(String sellerId) async {
    try {
      return Right(await remoteDataSource.getOrders(sellerId));
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
  Stream<List<OrderEntity>> watchOrders(String sellerId) =>
      remoteDataSource.watchOrders(sellerId);
}
