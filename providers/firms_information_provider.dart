import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunrise_app/models/user_info_model.dart';

import '../models/firm_identification_data.dart';

class FirmsInformationProvider extends StateNotifier<FirmIdentificationData> {
  FirmsInformationProvider()
      : super(
          FirmIdentificationData(
            firmName: '',
            address: '',
            isJuridic: false,
            cui: '',
            isTVAPayer: false,
            telNo: '',
            admin: '',
            managers: [],
            users: [],
            notificationMessage: '',
          ),
        );

  late bool isLoading = false;

  Future<void> getCloudFirmInformation(
      String cui,
      UserInformation userInformation,
      FirebaseFirestore firebaseFirestore) async {
    if (userInformation.userFirms.contains(cui)) {
      var firmData;
      try {
        firmData = await firebaseFirestore.collection('firme').get().then(
              (value) => value.docs
                  .firstWhere((element) => element.data()['CUI'] == cui),
            );
      } catch (e) {
        return;
      }

      if (!firmData.exists) {
        return;
      }
      state = FirmIdentificationData(
        firmName: firmData.data()['firm_name'],
        address: firmData.data()['address'],
        isJuridic: firmData.data()['is_juridic_person'],
        cui: firmData.data()['CUI'],
        isTVAPayer: firmData.data()['TVA'],
        telNo: firmData.data()['tel_number'],
        admin: firmData.data()['admin'],
        managers: firmData.data()['managers'],
        users: firmData.data()['users'],
        notificationMessage: firmData.data()['notification_message'],
      );
    }
  }

  String getUserRole(
      String loggedUser, FirmIdentificationData firmIdentificationData) {
    if (loggedUser == firmIdentificationData.admin) {
      return 'Admin';
    } else if (firmIdentificationData.managers.contains(loggedUser)) {
      return 'Manager';
    } else if (firmIdentificationData.users.contains(loggedUser)) {
      return 'User';
    }
    return 'Nu s-a putut determina rolul';
  }

  Future<bool> deleteFirmAndAllTraces(
    String cui,
    FirebaseFirestore firebaseFirestore,
  ) async {
    await firebaseFirestore.collection('firme').doc(cui).delete();
    var appData = await firebaseFirestore.collection('appointments').get().then(
        (value) => value.docs.where((element) => element.data()['cui'] == cui));
    for (var data in appData) {
      await firebaseFirestore.collection('appointments').doc(data.id).delete();
    }
    var tranzData = await firebaseFirestore
        .collection('transactions')
        .get()
        .then((value) =>
            value.docs.where((element) => element.data()['cui'] == cui));
    for (var data in tranzData) {
      await firebaseFirestore.collection('transactions').doc(data.id).delete();
    }
    var userData = await firebaseFirestore.collection('users').get().then(
        (value) => value.docs
            .where((element) => element.data()['firms'].contains(cui)));
    for (var user in userData) {
      List firmsList = user.data()['firms'];
      firmsList.removeWhere((element) => element == cui);
      await firebaseFirestore.collection('users').doc(user.id).update({
        'firms': firmsList,
      });
    }
    return true;
  }
}

final firmsInformationProvider =
    StateNotifierProvider<FirmsInformationProvider, FirmIdentificationData>(
        (ref) => FirmsInformationProvider());
