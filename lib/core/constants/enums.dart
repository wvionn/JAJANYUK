/// User roles in the system
enum UserRole {
  admin,
  seller,
  buyer;

  String get value {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.seller:
        return 'seller';
      case UserRole.buyer:
        return 'buyer';
    }
  }

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'seller':
        return UserRole.seller;
      case 'buyer':
        return UserRole.buyer;
      default:
        return UserRole.buyer;
    }
  }
}

/// Order status
enum OrderStatus {
  pending,
  processing,
  ready,
  completed,
  cancelled;

  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.processing:
        return 'processing';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'processing':
        return OrderStatus.processing;
      case 'ready':
        return OrderStatus.ready;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }
}

/// Payment method
enum PaymentMethod {
  qris,
  cash;

  String get value {
    switch (this) {
      case PaymentMethod.qris:
        return 'qris';
      case PaymentMethod.cash:
        return 'cash';
    }
  }
}

/// Payment status
enum PaymentStatus {
  pending,
  paid,
  failed;

  String get value {
    switch (this) {
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.failed:
        return 'failed';
    }
  }
}
