import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sunrise_app/providers/theme_provider.dart';
import 'package:sunrise_app/providers/user_information_provider.dart';
import 'package:sunrise_app/screens/main_screen.dart';
import 'package:sunrise_app/screens/users_screen.dart';

import '../models/user_info_model.dart';

class LoadingScreen extends ConsumerStatefulWidget {
  const LoadingScreen(this.navigatorKey, {Key? key}) : super(key: key);

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  ConsumerState<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends ConsumerState<LoadingScreen> {
  late Future<UserInformation?> _userInformation;

  Future<UserInformation?> _getInitialData() async {
    await ref.read(colorSchemeProvider.notifier).createDB(
          ref.read(firebaseAuth).currentUser!.email.toString(),
        );
    UserInformation userInfo =
        await ref.read(userInformationProvider.notifier).getUserInfo(
              ref.read(firebaseFirestore),
              ref.read(firebaseAuth),
            );
    if (userInfo.loggedUser.isNotEmpty) {
      print('in the if');
      Color dbColor =
          await ref.read(colorSchemeProvider.notifier).getColorFromDB(
                userInfo.loggedUser,
              );
      print(dbColor.value);
      await ref.read(colorSchemeProvider.notifier).updateUserInfoFromDB(
            ref.read(firebaseAuth).currentUser!.email.toString(),
            userInfo,
          );
      // await ref.read(colorSchemeProvider.notifier).updateColor(
      //     ref.read(firebaseAuth).currentUser!.email.toString(), dbColor);
      return userInfo;
    }

    print('loading page here');
    return null;
  }

  // @override
  // void initState() {
  //   // TODO: implement initState
  //   super.initState();
  //   _userInformation = _getInitialData();
  // }
  //
  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _userInformation = _getInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(),
      body: FutureBuilder(
        future: _userInformation,
        builder: (context, snapshot) {
          try {
            print('in the try');
            if (snapshot.connectionState == ConnectionState.done) {
              print(snapshot.data!.loggedUser);
              // UserInformation? userInfo = snapshot.data;
              // print(userInfo);
              return const MainScreen();
            }
          } catch (e) {
            print('error: $e');
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          print('final return');
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
    );
  }
}
