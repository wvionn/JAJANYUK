import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/constants/enums.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient supabaseClient;

  AuthRepositoryImpl({required this.supabaseClient});

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        return const Left(ServerFailure('Login gagal: User tidak ditemukan'));
      }

      // Fetch user profile dari tabel public.users
      final profileResponse = await supabaseClient
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileResponse == null) {
        // Jika profile belum terbuat di database, daftarkan default pembeli (buyer)
        final profileData = {
          'id': user.id,
          'email': email,
          'full_name': user.userMetadata?['full_name'] ?? 'User',
          'role': 'buyer',
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
        };
        try {
          await supabaseClient.from('users').insert(profileData);
        } catch (_) {
          // Hiraukan error jika RLS menolak, kembalikan user metadata sementara
        }

        return Right(UserModel(
          id: user.id,
          email: email,
          fullName: user.userMetadata?['full_name'] ?? 'User',
          role: UserRole.buyer,
          createdAt: DateTime.now(),
        ));
      }

      return Right(UserModel.fromJson(profileResponse));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? campusId,
  }) async {
    try {
      final response = await supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': 'buyer',
        },
      );

      final user = response.user;
      if (user == null) {
        return const Left(ServerFailure('Registrasi gagal: Gagal membuat user'));
      }

      // Langsung simpan di public.users sebagai fallback jika trigger db belum disetup
      final profileData = {
        'id': user.id,
        'email': email,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'role': 'buyer',
        'campus_id': campusId,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      try {
        await supabaseClient.from('users').upsert(profileData);
      } catch (_) {
        // Hiraukan error jika trigger database sudah mengeksekusi ini
      }

      final userModel = UserModel(
        id: user.id,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        role: UserRole.buyer,
        campusId: campusId,
        createdAt: DateTime.now(),
      );

      return Right(userModel);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logout() async {
    try {
      await supabaseClient.auth.signOut();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final authUser = supabaseClient.auth.currentUser;
      if (authUser == null) {
        return const Right(null);
      }

      final profileResponse = await supabaseClient
          .from('users')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      if (profileResponse == null) {
        return const Right(null);
      }

      return Right(UserModel.fromJson(profileResponse));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetPassword(String email) async {
    try {
      await supabaseClient.auth.resetPasswordForEmail(email);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      final data = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (fullName != null) data['full_name'] = fullName;
      if (phoneNumber != null) data['phone_number'] = phoneNumber;
      if (profileImageUrl != null) data['profile_image_url'] = profileImageUrl;

      final response = await supabaseClient
          .from('users')
          .update(data)
          .eq('id', userId)
          .select()
          .single();

      return Right(UserModel.fromJson(response));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
