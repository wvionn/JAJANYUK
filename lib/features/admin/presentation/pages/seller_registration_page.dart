import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../../../../core/utils/validators.dart';

class SellerRegistrationPage extends ConsumerStatefulWidget {
  const SellerRegistrationPage({super.key});

  @override
  ConsumerState<SellerRegistrationPage> createState() =>
      _SellerRegistrationPageState();
}

class _SellerRegistrationPageState
    extends ConsumerState<SellerRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleRegisterSeller() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement seller registration logic with Riverpod
      // ref.read(adminControllerProvider.notifier).registerSeller(...)

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Seller registered successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Seller')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Seller Account',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Fill in the details to create a new seller account',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              CustomTextField(
                label: 'Full Name',
                hint: 'Enter seller full name',
                controller: _fullNameController,
                prefixIcon: Icons.person,
                validator: (value) => Validators.required(value, 'Full name'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Email',
                hint: 'Enter seller email',
                controller: _emailController,
                prefixIcon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.email,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Phone Number',
                hint: 'Enter phone number',
                controller: _phoneController,
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: Validators.phoneNumber,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Password',
                hint: 'Create password',
                controller: _passwordController,
                prefixIcon: Icons.lock,
                obscureText: true,
                validator: Validators.password,
              ),
              const SizedBox(height: 8),
              const Text(
                'Password must be at least 8 characters',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              CustomButton(
                text: 'Register Seller',
                onPressed: _handleRegisterSeller,
                icon: Icons.person_add,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'The seller will receive these credentials to log in to their account.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
