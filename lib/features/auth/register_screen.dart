import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/backend_scope.dart';
import '../../theme/theme.dart';
import '../../widgets/app_text.dart';

final RegExp _usernamePattern = RegExp(r'^[a-z0-9_]{3,20}$');

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _displayName = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _checkEmailSent = false;

  @override
  void dispose() {
    _username.dispose();
    _displayName.dispose();
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
    final backend = BackendScope.readOf(context);
    final username = _username.text.trim().toLowerCase();
    try {
      final available = await backend.auth.isUsernameAvailable(username);
      if (!available) {
        setState(() => _error = 'Username già in uso, scegline un altro.');
        return;
      }
      final response = await backend.auth.signUp(
        email: _email.text.trim(),
        password: _password.text,
        username: username,
        displayName: _displayName.text.trim().isEmpty ? username : _displayName.text.trim(),
      );
      if (!mounted) return;
      if (response.session == null) {
        // Email confirmation is required by this Supabase project's auth
        // settings — there's no session yet until the user confirms.
        setState(() => _checkEmailSent = true);
      } else {
        // Signed in immediately: pop this screen (and the login screen
        // beneath it) off the stack so AuthGate's fresh evaluation — now
        // showing onboarding/home — becomes visible instead of staying
        // hidden underneath the login/register routes.
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthRetryableFetchException catch (_) {
      setState(() => _error = 'Connessione non disponibile. Controlla la rete e riprova.');
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Registrazione non riuscita. Controlla la connessione e riprova.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkEmailSent) {
      return Container(
        decoration: const BoxDecoration(gradient: AppGradients.background),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(AppIcons.envelopeSimple, size: 48, color: AppColors.fuchsia),
                  const SizedBox(height: AppSpacing.lg),
                  AppText(
                    'Controlla la tua email per confermare l\'account, poi torna qui e accedi.',
                    textAlign: TextAlign.center,
                    style: AppTypography.body(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const AppText('TORNA AL LOGIN'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(gradient: AppGradients.background),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(AppIcons.arrowLeft),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppText('CREA IL TUO', style: AppTypography.display())
                      .animate()
                      .fadeIn(duration: AppMotion.base, curve: AppMotion.enter)
                      .slideY(begin: 0.2, end: 0, duration: AppMotion.base, curve: AppMotion.emphasized),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: AppText('account', style: AppTypography.accent(fontSize: 36)),
                  )
                      .animate(delay: AppMotion.staggerStep)
                      .fadeIn(duration: AppMotion.base, curve: AppMotion.enter)
                      .slideY(begin: 0.2, end: 0, duration: AppMotion.base, curve: AppMotion.emphasized),
                  const SizedBox(height: AppSpacing.xl),
                  TextFormField(
                    controller: _username,
                    style: AppTypography.body(),
                    decoration: const InputDecoration(labelText: 'Username', prefixText: '@ '),
                    autocorrect: false,
                    validator: (v) {
                      final value = (v ?? '').trim().toLowerCase();
                      if (!_usernamePattern.hasMatch(value)) {
                        return '3-20 caratteri: lettere minuscole, numeri, _';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _displayName,
                    style: AppTypography.body(),
                    decoration: const InputDecoration(labelText: 'Nome (facoltativo)'),
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                    validator: (v) => (v == null || v.length < 6) ? 'Almeno 6 caratteri' : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppText(_error!, style: AppTypography.bodySmall(color: AppColors.berry)),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.white),
                          )
                        : const AppText('REGISTRATI'),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ]
                    .animate(delay: AppMotion.staggerStep * 2, interval: Duration.zero)
                    .fadeIn(duration: AppMotion.base, curve: AppMotion.enter),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
