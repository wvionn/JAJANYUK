import 'package:equatable/equatable.dart';

class TransactionReportEntity extends Equatable {
  final String id;
  final String buyerName;
  final String buyerEmail;
  final String sellerName;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final DateTime createdAt;
  final List<Map<String, dynamic>> items;

  const TransactionReportEntity({
    required this.id,
    required this.buyerName,
    required this.buyerEmail,
    required this.sellerName,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.createdAt,
    required this.items,
  });

  @override
  List<Object?> get props => [
        id,
        buyerName,
        buyerEmail,
        sellerName,
        totalAmount,
        status,
        paymentMethod,
        createdAt,
        items,
      ];
}

class PlatformStatsEntity extends Equatable {
  final int totalSellers;
  final int totalBuyers;
  final int totalOrders;
  final int totalCampuses;
  final double totalRevenue;
  final int pendingOrders;
  final int completedOrders;

  const PlatformStatsEntity({
    required this.totalSellers,
    required this.totalBuyers,
    required this.totalOrders,
    required this.totalCampuses,
    required this.totalRevenue,
    required this.pendingOrders,
    required this.completedOrders,
  });

  @override
  List<Object?> get props => [
        totalSellers,
        totalBuyers,
        totalOrders,
        totalCampuses,
        totalRevenue,
        pendingOrders,
        completedOrders,
      ];
}
