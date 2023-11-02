import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunrise_app/models/user_info_model.dart';

final firebaseAuth = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firebaseFirestore =
    Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);

class UserInformationProvider extends StateNotifier<UserInformation> {
  UserInformationProvider()
      : super(
          UserInformation(
            loggedUser: '',
            alias: '',
            userFirms: [],
          ),
        );
  String errorMessage = '';
  String userDocID = '';

  late UserInformation userInformation =
      UserInformation(loggedUser: '', alias: '', userFirms: []);

  void createUser(
      String loggedUser, FirebaseFirestore firebaseFirestore) async {
    await firebaseFirestore.collection('users').add({
      'user_email': loggedUser,
      'alias': '',
      'firms': [],
    });
  }

  Future<bool> changePassword(FirebaseFirestore firebaseFirestore,
      String currentPassword, String newPassword) async {
    bool success = false;

    //Create an instance of the current user.
    var user = FirebaseAuth.instance.currentUser!;
    //Must re-authenticate user before updating the password. Otherwise it may fail or user get signed out.

    final cred = EmailAuthProvider.credential(
        email: user.email!, password: currentPassword);
    await user.reauthenticateWithCredential(cred).then((value) async {
      await user.updatePassword(newPassword).then((_) {
        success = true;
      }).catchError((error) {
        errorMessage = error;
      });
    }).catchError((err) {
      errorMessage = err;
    });

    return success;
  }

  Future<UserInformation> getUserInfo(
      FirebaseFirestore firebaseFirestore, FirebaseAuth firebaseAuth) async {
    var userInfo = await firebaseFirestore.collection('users').get().then(
        (value) => value.docs.where((element) =>
            element.data()['user_email'] == firebaseAuth.currentUser!.email));
    state = UserInformation(
        loggedUser: userInfo.first.data()['user_email'],
        alias: userInfo.first.data()['alias'],
        userFirms: userInfo.first.data()['firms']);
    userDocID = userInfo.first.id;
    return state;
  }
}

final userInformationProvider =
    StateNotifierProvider<UserInformationProvider, UserInformation>(
  (ref) => UserInformationProvider(),
);
