# 🍽️ Esa Eats - Campus Food Ordering App

A scalable Flutter application for campus food ordering built with Clean Architecture, Riverpod, and Supabase.

## 📱 Features

### 👤 User Roles

1. **Admin**
   - Manage platform
   - Register seller accounts
   - View platform statistics
   - Manage categories

2. **Seller (Penjual)**
   - Manage products/menu
   - View and process orders
   - Update order status
   - View sales statistics

3. **Buyer (Pembeli)**
   - Browse food categories
   - Add items to cart
   - Place orders
   - QRIS payment
   - Track order status
   - View notifications
   - Manage profile

## 🏗️ Architecture

This project follows **Clean Architecture** with **Feature-First** organization:

```
lib/
├── core/              # Shared utilities, theme, routing
└── features/          # Feature modules
    ├── auth/          # Authentication
    ├── admin/         # Admin functionality
    ├── seller/        # Seller dashboard
    ├── home/          # Buyer home
    ├── cart/          # Shopping cart
    ├── qris/          # Payment
    └── ...
```

Each feature follows the 3-layer architecture:
- **Presentation**: UI (Pages, Widgets, Providers)
- **Domain**: Business Logic (Entities, Use Cases, Repository Interfaces)
- **Data**: Data Access (Models, Data Sources, Repository Implementations)

## 🎨 Design System

### Colors
- **Primary**: Blue (#5B8DEE)
- **Secondary**: Orange (#FA842B)
- **Background**: #F5F7FA

### Tech Stack
- **Framework**: Flutter
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Backend**: Supabase (Auth, PostgreSQL, Storage)
- **Architecture**: Clean Architecture

## 📦 Dependencies

```yaml
dependencies:
  flutter_riverpod: ^2.4.0
  go_router: ^12.0.0
  supabase_flutter: ^2.0.0
  dartz: ^0.10.1
  equatable: ^2.0.5
  intl: ^0.18.1
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Supabase account

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd esa_eats
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Create a Supabase project at [supabase.com](https://supabase.com)
   - Copy your project URL and anon key
   - Update `lib/core/config/app_config.dart`:
   ```dart
   static const String supabaseUrl = 'YOUR_SUPABASE_URL';
   static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

4. **Set up database**
   - Follow instructions in `SUPABASE_SCHEMA.md`
   - Run the SQL scripts in your Supabase SQL editor

5. **Run the app**
   ```bash
   flutter run
   ```

## 📚 Documentation

- [Architecture Guide](ARCHITECTURE.md) - Detailed architecture documentation
- [Supabase Schema](SUPABASE_SCHEMA.md) - Database schema and RLS policies

## 🔑 Key Features Implementation

### Admin Seller Registration
Admins can create seller accounts through the admin dashboard. The flow:
1. Admin fills seller registration form
2. System creates auth user via Supabase Admin API
3. Seller profile is created with role='seller'
4. Seller receives credentials to log in

### Role-Based Access Control
- Implemented via Supabase RLS policies
- Each role has specific permissions
- Enforced at database level for security

### Bottom Navigation (Buyer)
- Home (Dashboard with categories and recommendations)
- Keranjang (Shopping cart)
- QRIS (Payment)
- Notifikasi (Notifications)
- Akun (Profile)

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test
```

## 📱 Screenshots

[Add your app screenshots here]

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 👥 Team

- Your Name - Developer

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Supabase for the backend infrastructure
- Riverpod for state management
