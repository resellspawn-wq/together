import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/backend_scope.dart';
import '../../theme/theme.dart';
import 'register_screen.dart';
import '../../widgets/app_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await BackendScope.readOf(context).auth.signIn(
            email: _email.text.trim(),
            password: _password.text,
          );
      // AuthGate reacts to the auth state change and swaps the screen.
    } on AuthRetryableFetchException catch (_) {
      setState(() => _error = 'Connessione non disponibile. Controlla la rete e riprova.');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Impossibile accedere. Controlla la connessione e riprova.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppGradients.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(AppIcons.heart, size: 48, color: AppColors.fuchsia)
                        .animate()
                        .fadeIn(duration: AppMotion.base, curve: AppMotion.enter)
                        .scaleXY(begin: 0.8, end: 1, duration: AppMotion.base, curve: AppMotion.emphasized),
                    const SizedBox(height: AppSpacing.md),
                    AppText('TOGETHER', textAlign: TextAlign.center, style: AppTypography.hero())
                        .animate(delay: AppMotion.staggerStep)
                        .fadeIn(duration: AppMotion.base, curve: AppMotion.enter)
                        .slideY(begin: 0.2, end: 0, duration: AppMotion.base, curve: AppMotion.emphasized),
                    const SizedBox(height: AppSpacing.md),
                    AppText(
                      'Accedi per ritrovare il tuo alfabeto e le tue conversazioni.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body(color: AppColors.inkSoft),
                    )
                        .animate(delay: AppMotion.staggerStep * 2)
                        .fadeIn(duration: AppMotion.base, curve: AppMotion.enter)
                        .slideY(begin: 0.2, end: 0, duration: AppMotion.base, curve: AppMotion.emphasized),
                    const SizedBox(height: AppSpacing.xxl),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      style: AppTypography.body(),
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (v) => (v == null || !v.contains('@')) ? 'Inserisci un\'email valida' : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      style: AppTypography.body(),
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Inserisci la password' : null,
                      onFieldSubmitted: (_) => _submit(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      AppText(_error!, style: AppTypography.bodySmall(color: AppColors.berry)),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white),
                            )
                          : const AppText('ACCEDI'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                      child: const AppText('Non hai un account? Registrati'),
                    ),
                  ]
                      .animate(delay: AppMotion.staggerStep * 3, interval: Duration.zero)
                      .fadeIn(duration: AppMotion.base, curve: AppMotion.enter),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
