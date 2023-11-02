import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sunrise_app/main.dart';

FirebaseAuth _user = FirebaseAuth.instance;

class NotAllowedScreen extends StatelessWidget {
  const NotAllowedScreen({required this.isReset, required this.email, Key? key})
      : super(key: key);

  final bool isReset;
  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isReset
            ? const Text('Resetare parola')
            : const Text('Email nevalidat'),
        actions: [
          IconButton(
            onPressed: () {
              _user.signOut();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => const MyApp(),
                ),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
          child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          isReset
              ? 'Ti-am trimis un email catre $email prin care iti poti reseta parola. \nVerifica si in casuta de spam.'
              : 'Ti-am trimis un email de verificare la adresa $email.\nCauta mesajul nostru si in casuta de Spam si apasa-l pentru verificare.',
          style: const TextStyle(
            fontSize: 25,
          ),
          textAlign: TextAlign.center,
        ),
      )),
    );
  }
}
