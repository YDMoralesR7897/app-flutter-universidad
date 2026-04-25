import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _entered = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _entered = true);
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthBloc>().add(
          AuthRegisterRequested(
            email: _email.text.trim(),
            password: _password.text,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(gradient: AppGradients.authBackground),
            ),
          ),
          const _CampusBackdrop(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: AnimatedSlide(
                    duration: const Duration(milliseconds: 550),
                    curve: Curves.easeOutCubic,
                    offset: _entered ? Offset.zero : const Offset(0, 0.08),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: _entered ? 1 : 0,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x290F172A),
                              blurRadius: 28,
                              offset: Offset(0, 14),
                            ),
                          ],
                        ),
                        child: BlocConsumer<AuthBloc, AuthState>(
                          listener: (ctx, s) {
                            if (s.status == AuthStatus.error &&
                                s.error != null) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text(s.error!)),
                              );
                            }
                          },
                          builder: (ctx, s) {
                            final loading = s.status == AuthStatus.loading;
                            return Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Icon(
                                    Icons.how_to_reg_rounded,
                                    size: 44,
                                    color: AppColors.brand,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Crear cuenta de la U',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Regístrate para habilitar check-in de clase y seguimiento de asistencia.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                            color: const Color(0xFF4B5563)),
                                  ),
                                  const SizedBox(height: 24),
                                  TextFormField(
                                    controller: _email,
                                    keyboardType: TextInputType.emailAddress,
                                    autocorrect: false,
                                    decoration: const InputDecoration(
                                      labelText: 'Correo institucional',
                                      prefixIcon:
                                          Icon(Icons.alternate_email_rounded),
                                    ),
                                    validator: (v) =>
                                        (v == null || !v.contains('@'))
                                            ? 'Email inválido'
                                            : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _password,
                                    obscureText: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Contraseña',
                                      prefixIcon:
                                          Icon(Icons.lock_outline_rounded),
                                    ),
                                    validator: (v) =>
                                        (v == null || v.length < 8)
                                            ? 'Mínimo 8 caracteres'
                                            : null,
                                  ),
                                  const SizedBox(height: 22),
                                  FilledButton(
                                    onPressed: loading ? null : _submit,
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      child: loading
                                          ? const SizedBox(
                                              key: ValueKey('loading'),
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text(
                                              key: ValueKey('text'),
                                              'Registrarme ahora',
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: loading
                                        ? null
                                        : () => Navigator.of(context).pop(),
                                    child: const Text('Ya tengo cuenta'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CampusBackdrop extends StatelessWidget {
  const _CampusBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: _BlurOrb(
              size: 230,
              color: AppColors.brand.withValues(alpha: 0.18),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -40,
            child: _BlurOrb(
              size: 260,
              color: AppColors.accent.withValues(alpha: 0.22),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  final double size;
  final Color color;
  const _BlurOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size),
      ),
    );
  }
}
