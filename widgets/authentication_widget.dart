import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunrise_app/providers/user_information_provider.dart';
import 'package:sunrise_app/screens/not_allowed_screen.dart';
import '../models/user_auth_errors.dart';

FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

class AuthenticationSheet extends ConsumerStatefulWidget {
  const AuthenticationSheet({required this.isLogin, Key? key})
      : super(key: key);
  final bool isLogin;

  @override
  ConsumerState<AuthenticationSheet> createState() =>
      _AuthenticationSheetState();
}

class _AuthenticationSheetState extends ConsumerState<AuthenticationSheet> {
  final formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late String _errorMessage = '';
  late bool _isLoading = false;
  late bool _isPasswordHidden = true;
  late bool _isConfirmPasswordHidden = true;

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        height: 600,
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                ),
                autofocus: true,
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _isPasswordHidden = !_isPasswordHidden;
                      });
                    },
                    icon: Icon(
                      Icons.remove_red_eye,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                obscureText: _isPasswordHidden,
                controller: _passwordController,
              ),
              if (!widget.isLogin)
                TextFormField(
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Parolele nu se potrivesc';
                    }
                    return null;
                  },
                  obscureText: _isConfirmPasswordHidden,
                  decoration: InputDecoration(
                    labelText: 'Confirm password',
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordHidden = !_isConfirmPasswordHidden;
                        });
                      },
                      icon: Icon(
                        Icons.remove_red_eye,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              const SizedBox(
                height: 10,
              ),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
              Container(
                padding: const EdgeInsets.only(top: 20),
                // width: 160,
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 160,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary),
                              onPressed: () async {
                                setState(() {
                                  _isLoading = true;
                                });
                                var validation =
                                    formKey.currentState!.validate();
                                if (!validation) {
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  return;
                                }
                                try {
                                  if (widget.isLogin) {
                                    await _firebaseAuth
                                        .signInWithEmailAndPassword(
                                            email: _emailController.text,
                                            password: _passwordController.text);
                                  } else {
                                    await _firebaseAuth
                                        .createUserWithEmailAndPassword(
                                            email: _emailController.text,
                                            password: _passwordController.text);
                                    ref
                                        .read(userInformationProvider.notifier)
                                        .createUser(
                                          _emailController.text,
                                          ref.read(firebaseFirestore),
                                        );
                                  }
                                  final user =
                                      FirebaseAuth.instance.currentUser;
                                  if (!user!.emailVerified) {
                                    await user.sendEmailVerification();
                                  }

                                  ///get user information from the cloud
                                  // await ref
                                  //     .read(userInformationProvider.notifier)
                                  //     .getUserInfo(ref.read(firebaseFirestore),
                                  //         _firebaseAuth);
                                  _passwordController.clear();
                                  _emailController.clear();
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                } catch (error) {
                                  setState(() {
                                    _errorMessage = displayErrorMessages(error);
                                  });
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  return;
                                }
                              },
                              child: widget.isLogin
                                  ? const Text(
                                      'Log In',
                                    )
                                  : const Text('Register'),
                            ),
                          ),
                          if (widget.isLogin)
                            SizedBox(
                              width: 160,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  if (_emailController.text.isNotEmpty &&
                                      _emailController.text.contains('@') &&
                                      _emailController.text.contains('.')) {
                                    FirebaseAuth.instance
                                        .sendPasswordResetEmail(
                                            email: _emailController.text);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (ctx) => NotAllowedScreen(
                                            isReset: true,
                                            email: _emailController.text),
                                      ),
                                    );
                                  } else {
                                    setState(() {
                                      _errorMessage =
                                          'Introdu o adresa de email valida.';
                                    });
                                    return;
                                  }
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  // _emailController.clear();
                                },
                                child: const Text('Reseteaza parola'),
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
