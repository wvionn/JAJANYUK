import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/menu_item_entity.dart';
import '../entities/order_entity.dart';

abstract class SellerRepository {
  // ── Menu Management ──
  Future<Either<Failure, List<MenuItemEntity>>> getMenuItems(String sellerId);
  Future<Either<Failure, MenuItemEntity>> addMenuItem({
    required String sellerId,
    required String name,
    String? description,
    required double price,
    String? category,
    bool available,
  });
  Future<Either<Failure, MenuItemEntity>> updateMenuItem({
    required String menuItemId,
    String? name,
    String? description,
    double? price,
    String? category,
    bool? available,
  });
  Future<Either<Failure, void>> deleteMenuItem(String menuItemId);

  // ── Orders ──
  Future<Either<Failure, List<OrderEntity>>> getOrders(String sellerId);
  Future<Either<Failure, void>> updateOrderStatus({
    required String orderId,
    required String status,
  });

  // ── Chat ──
  Future<Either<Failure, List<ChatMessageEntity>>> getChatMessages(
      String orderId);
  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required String orderId,
    required String senderId,
    required String message,
  });
  Stream<List<ChatMessageEntity>> watchChatMessages(String orderId);
  Stream<List<OrderEntity>> watchOrders(String sellerId);
}
