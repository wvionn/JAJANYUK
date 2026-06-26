import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/menu_item_entity.dart';
import '../entities/order_entity.dart';
import '../entities/vendor_entity.dart';
import '../entities/seller_profile_entity.dart';
import '../entities/transaction_entity.dart';

abstract class SellerRepository {
  // ── Menu Management ──
  Future<Either<Failure, List<MenuItemEntity>>> getMenuItems(String vendorId);
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
  });
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
  });
  Future<Either<Failure, void>> deleteMenuItem(String menuItemId);

  // ── Orders ──
  Future<Either<Failure, List<OrderEntity>>> getOrders(String vendorId);
  Future<Either<Failure, void>> updateOrderStatus({
    required String orderId,
    required String status,
  });

  // ── Chat ──
  Future<Either<Failure, List<ChatMessageEntity>>> getChatMessages(String orderId);
  Future<Either<Failure, ChatMessageEntity>> sendMessage({
    required String orderId,
    required String senderId,
    required String message,
  });
  Stream<List<ChatMessageEntity>> watchChatMessages(String orderId);
  Stream<List<OrderEntity>> watchOrders(String vendorId);

  // ── Vendor & Seller Profile ──
  Future<Either<Failure, SellerProfileEntity>> getSellerProfile(String userId);
  Future<Either<Failure, VendorEntity>> getVendorProfile(String vendorId);
  Future<Either<Failure, VendorEntity>> updateVendorProfile(VendorEntity vendor);

  // ── Transaction Reports ──
  Future<Either<Failure, List<TransactionEntity>>> getTransactionReports(
    String vendorId, {
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  });
}

