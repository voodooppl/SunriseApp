import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunrise_app/providers/theme_provider.dart';
import 'package:sunrise_app/providers/user_information_provider.dart';
import 'package:sunrise_app/screens/auth.dart';
import 'package:sunrise_app/screens/loading_screen.dart';
import 'package:sunrise_app/screens/main_screen.dart';
import 'package:sunrise_app/screens/not_allowed_screen.dart';
import 'firebase_options.dart';

// final kColorScheme = ColorScheme.fromSeed(
//   seedColor: const Color.fromRGBO(138, 52, 134, 255),
// );
// final theme = ThemeData().copyWith(
//   colorScheme: kColorScheme,
//   useMaterial3: true,
//   appBarTheme: const AppBarTheme().copyWith(
//       backgroundColor: kColorScheme.primary,
//       foregroundColor: Colors.white,
//       centerTitle: true),
//   textTheme: const TextTheme().copyWith(
//     titleMedium: TextStyle(color: kColorScheme.primary),
//     titleLarge: TextStyle(color: kColorScheme.primary),
//     titleSmall: TextStyle(color: kColorScheme.primary),
//
//     ///asta este de la listtile - title
//     bodyLarge:
//         TextStyle(color: kColorScheme.primary, fontWeight: FontWeight.bold),
//     bodyMedium: TextStyle(color: kColorScheme.primary),
//     bodySmall: TextStyle(color: kColorScheme.primary),
//     displayLarge: TextStyle(color: kColorScheme.primary),
//     displayMedium: TextStyle(color: kColorScheme.primary),
//     displaySmall: TextStyle(color: kColorScheme.primary),
//     labelLarge: TextStyle(color: kColorScheme.primary),
//     labelMedium: TextStyle(color: kColorScheme.primary),
//
//     ///asta este textul de la listtile - leading
//     labelSmall: TextStyle(color: kColorScheme.primary),
//     headlineLarge: TextStyle(color: kColorScheme.primary),
//     headlineMedium: TextStyle(color: kColorScheme.primary),
//     headlineSmall: TextStyle(color: kColorScheme.primary),
//   ),
//   inputDecorationTheme: const InputDecorationTheme().copyWith(
//     labelStyle: TextStyle(color: kColorScheme.primary),
//   ),
//   iconTheme: const IconThemeData().copyWith(color: Colors.white),
// );

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Sunrise App',
        // theme: ref.watch(colorSchemeProvider.notifier).staticThemeData(),
        theme: ref.watch(theThemeProvider),
        home: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (ctx, snapshot) {
            print('main');
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasData &&
                !FirebaseAuth.instance.currentUser!.emailVerified) {
              return NotAllowedScreen(
                isReset: false,
                email: FirebaseAuth.instance.currentUser!.email.toString(),
              );
            }
            // if (snapshot.hasData) {
            //   return const MainScreen(null);
            // }
            if (snapshot.hasData) {
              return LoadingScreen(navigatorKey);
            }
            return const AuthScreen();
          },
        ),
      ),
      // ),
    );
  }
}
