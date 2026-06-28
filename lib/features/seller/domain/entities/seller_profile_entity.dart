import 'package:equatable/equatable.dart';

class SellerProfileEntity extends Equatable {
  final String id;
  final String userId;
  final String vendorId;
  final String sellerName;
  final String? phone;
  final String role;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const SellerProfileEntity({
    required this.id,
    required this.userId,
    required this.vendorId,
    required this.sellerName,
    this.phone,
    required this.role,
    required this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        vendorId,
        sellerName,
        phone,
        role,
        createdAt,
        updatedAt,
      ];
}
