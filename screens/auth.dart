import 'package:flutter/material.dart';
import 'package:sunrise_app/widgets/authentication_widget.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  Future _authenticate(bool isLogin) {
    return showModalBottomSheet(
        context: (context),
        builder: (ctx) {
          return AuthenticationSheet(
            isLogin: isLogin,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primary,
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 130,
                    backgroundImage: AssetImage('images/Just for You.png'),
                  ),
                  const SizedBox(
                    height: 80,
                  ),
                  SizedBox(
                    width: 160,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _authenticate(true);
                          },
                          child: const Text('Log In'),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _authenticate(false);
                          },
                          child: const Text('Register'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
