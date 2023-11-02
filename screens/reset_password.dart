import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../providers/user_information_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  late bool _oldPasswordObscure = true;
  late bool _newPasswordObscure = true;

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reseteaza parola'),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
          child: Column(
            children: [
              TextFormField(
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Introdu parola curenta';
                  }
                  return null;
                },
                obscureText: _oldPasswordObscure,
                controller: _oldPasswordController,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _oldPasswordObscure = !_oldPasswordObscure;
                      });
                    },
                    icon: Icon(
                      Icons.remove_red_eye,
                      color: iconColor,
                    ),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary)),
                  label: const Text('Parola veche'),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              TextFormField(
                obscureText: _newPasswordObscure,
                controller: _newPasswordController,
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.length < 8 ||
                      !value.contains(RegExp(r'[A-Z0-9!@#$%^&*()_+]'))) {
                    return 'Parola trebuie sa contina o litera de tipar, \nun numar si un caracter special (!@#\$%^&*()_+)';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _newPasswordObscure = !_newPasswordObscure;
                      });
                    },
                    icon: Icon(
                      Icons.remove_red_eye,
                      color: iconColor,
                    ),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary)),
                  label: const Text('Parola noua'),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              TextFormField(
                obscureText: _newPasswordObscure,
                validator: (value) {
                  if (_newPasswordController.text != value) {
                    return 'Parolele nu se potrivesc';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  suffixIcon: FaIcon(
                    FontAwesomeIcons.solidEyeSlash,
                    color: iconColor,
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary)),
                  label: const Text('Repeta parola noua'),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll(iconColor)),
                    onPressed: () async {
                      var isValid = _formKey.currentState!.validate();
                      if (!isValid) {
                        return;
                      }
                      var isComplete = await ref
                          .read(userInformationProvider.notifier)
                          .changePassword(
                              ref.read(firebaseFirestore),
                              _oldPasswordController.text,
                              _newPasswordController.text);

                      if (!isComplete) {
                        return;
                      }
                      if (mounted) Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Schimba',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (mounted) Navigator.of(context).pop();
                    },
                    child: const Text('Renunta'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
