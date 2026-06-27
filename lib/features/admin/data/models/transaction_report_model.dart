import '../../domain/entities/transaction_report_entity.dart';

class TransactionReportModel extends TransactionReportEntity {
  const TransactionReportModel({
    required super.id,
    required super.buyerName,
    required super.buyerEmail,
    required super.sellerName,
    required super.totalAmount,
    required super.status,
    required super.paymentMethod,
    required super.createdAt,
    required super.items,
  });

  factory TransactionReportModel.fromJson(Map<String, dynamic> json) {
    final buyer = json['buyer'] as Map<String, dynamic>?;
    final vendor = json['vendor'] as Map<String, dynamic>?;
    final transactionsList = json['transactions'] as List<dynamic>?;
    final transaction = (transactionsList != null && transactionsList.isNotEmpty)
        ? transactionsList.first as Map<String, dynamic>?
        : null;
    final rawItems = json['order_items'] as List<dynamic>? ?? [];

    return TransactionReportModel(
      id: json['id'] as String? ?? '',
      buyerName: buyer?['full_name'] as String? ?? buyer?['name'] as String? ?? 'Unknown',
      buyerEmail: buyer?['email'] as String? ?? '',
      sellerName: vendor?['name'] as String? ?? 'Unknown Seller',
      totalAmount: (json['total_price'] as num?)?.toDouble() ??
          (json['total_amount'] as num?)?.toDouble() ??
          0.0,
      status: json['order_status'] as String? ?? json['status'] as String? ?? 'pending',
      paymentMethod: transaction?['payment_method'] as String? ?? json['payment_method'] as String? ?? 'cash',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      items: rawItems.map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        final menu = map['menus'] as Map<String, dynamic>?;
        map['product_name'] = menu?['name'] as String? ?? map['product_name'] as String? ?? 'Item';
        return map;
      }).toList(),
    );
  }
}

class PlatformStatsModel extends PlatformStatsEntity {
  const PlatformStatsModel({
    required super.totalSellers,
    required super.totalBuyers,
    required super.totalOrders,
    required super.totalCampuses,
    required super.totalRevenue,
    required super.pendingOrders,
    required super.completedOrders,
  });

  factory PlatformStatsModel.fromJson(Map<String, dynamic> json) {
    return PlatformStatsModel(
      totalSellers: json['sellers_count'] as int? ?? 0,
      totalBuyers: json['buyers_count'] as int? ?? 0,
      totalOrders: json['orders_count'] as int? ?? 0,
      totalCampuses: json['campuses_count'] as int? ?? 0,
      totalRevenue: (json['total_revenue'] as num?)?.toDouble() ?? 0.0,
      pendingOrders: json['pending_orders'] as int? ?? 0,
      completedOrders: json['completed_orders'] as int? ?? 0,
    );
  }
}
