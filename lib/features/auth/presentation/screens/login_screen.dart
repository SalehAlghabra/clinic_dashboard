import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/l10n/app_translations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/bloc/language_cubit.dart';
import '../../../dashboard/presentation/bloc/theme_cubit.dart';
import '../../data/repositories/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_events_states.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@clinic.com');
  final _passwordController = TextEditingController(text: 'password123');
  final _otpController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController(text: _emailController.text.trim());
    final otpController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    int step = 1;
    bool isLoading = false;
    String? errorMsg;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(context.tr('forgot_password')),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (errorMsg != null) ...[
                      Text(errorMsg!, style: const TextStyle(color: AppColors.danger)),
                      const SizedBox(height: 12),
                    ],
                    if (step == 1) ...[
                      TextFormField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: context.tr('email'),
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                      ),
                    ] else if (step == 2) ...[
                      Text(
                        '${context.tr('otp_sent_msg')}\n${emailController.text}',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: otpController,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, letterSpacing: 4),
                        decoration: const InputDecoration(hintText: '000000'),
                      ),
                    ] else ...[
                      TextFormField(
                        controller: passwordController,
                        obscureText: true,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: context.tr('new_password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        textDirection: TextDirection.ltr,
                        decoration: InputDecoration(
                          labelText: context.tr('confirm_password'),
                          prefixIcon: const Icon(Icons.lock_outline),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text(context.tr('cancel')),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          setDialogState(() {
                            isLoading = true;
                            errorMsg = null;
                          });

                          try {
                            final authRepo = RepositoryProvider.of<AuthRepository>(context);
                            if (step == 1) {
                              await authRepo.forgotPassword(emailController.text.trim());
                              setDialogState(() {
                                step = 2;
                                isLoading = false;
                              });
                            } else if (step == 2) {
                              await authRepo.verifyResetOtp(
                                emailController.text.trim(),
                                otpController.text.trim(),
                              );
                              setDialogState(() {
                                step = 3;
                                isLoading = false;
                              });
                            } else {
                              if (passwordController.text != confirmPasswordController.text) {
                                throw Exception('Passwords do not match');
                              }
                              await authRepo.resetPassword(
                                email: emailController.text.trim(),
                                otp: otpController.text.trim(),
                                password: passwordController.text.trim(),
                                passwordConfirmation: confirmPasswordController.text.trim(),
                              );
                              if (context.mounted) {
                                Navigator.pop(dialogCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password reset successfully! Please log in.'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            setDialogState(() {
                              isLoading = false;
                              errorMsg = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(step == 1 ? 'Send OTP' : (step == 2 ? 'Verify' : 'Reset')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _submitLogin() {

    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthBloc>().add(
            LoginSubmitted(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            ),
          );
    }
  }

  void _submitOtp(String email) {
    final otp = _otpController.text.trim();
    if (otp.length == 6) {
      context.read<AuthBloc>().add(
            OtpSubmitted(
              email: email,
              otp: otp,
            ),
          );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 6-digit OTP code'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = context.watch<ThemeCubit>().state.isDarkMode;
    final primaryColor = theme.primaryColor;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Language switcher
          TextButton.icon(
            onPressed: () {
              context.read<LanguageCubit>().toggleLanguage();
            },
            icon: Icon(Icons.language, size: 18, color: primaryColor),
            label: Text(
              context.tr('switch_language'),
              style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
            ),
          ),
          const SizedBox(width: 8),

          // Theme switcher
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            tooltip: isDark ? context.tr('light_mode') : context.tr('dark_mode'),
            onPressed: () {
              context.read<ThemeCubit>().toggleTheme();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppColors.danger,
                    ),
                  );
                }
              },
              builder: (context, state) {
                final isOtpStep = state is AuthOtpRequired;
                final emailForOtp = isOtpStep ? (state).email : _emailController.text.trim();

                return Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isOtpStep ? Icons.mark_email_read_outlined : Icons.local_hospital_rounded,
                          color: primaryColor,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.tr('app_title'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isOtpStep ? context.tr('enter_otp') : context.tr('login_title'),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      if (!isOtpStep) ...[
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: context.tr('email'),
                            prefixIcon: const Icon(Icons.email_outlined),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            labelText: context.tr('password'),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: primaryColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: Text(
                              context.tr('forgot_password'),
                              style: TextStyle(color: primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: state is AuthLoading ? null : _submitLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: state is AuthLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  context.tr('login_button'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${context.tr('otp_sent_msg')}\n$emailForOtp',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            letterSpacing: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            hintText: '000000',
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: state is AuthLoading ? null : () => _submitOtp(emailForOtp),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: state is AuthLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  context.tr('verify_otp'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            context.read<AuthBloc>().add(CheckAuthStatus());
                          },
                          child: Text(context.tr('cancel')),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
