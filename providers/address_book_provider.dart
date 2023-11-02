import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunrise_app/models/client_model.dart';
import '../models/service_model.dart';

class AddressBookProvider extends StateNotifier<String> {
  AddressBookProvider() : super('');

  List<ClientModel> cloudAddressBook = [];
  List<ServiceModel> cloudServicesBook = [];
  List<dynamic> cloudContactsIdList = [];
  List<dynamic> cloudServicesIdList = [];
  ClientModel clientModel = ClientModel(
    name: '',
    telNo: '',
    loggedUserEmail: '',
    ownerFirm: '',
    address: '',
    cui: '',
    isJuridic: false,
    isTVAPayer: false,
  );
  ServiceModel serviceModel =
      const ServiceModel(name: '', loggedUserEmail: '', ownerFirm: '');
  String errorMessage = '';
  bool isLoading = false;

  void resetErrorMessage() {
    errorMessage = '';
    isLoading = false;
  }

  Future<List> getCloudData(String collectionPath, List userFirms,
      FirebaseFirestore firebaseFirestore) async {
    List<ClientModel> tempClientsList = [];
    List<ServiceModel> tempServicesList = [];
    List<dynamic> idList = [];

    var myData = await firebaseFirestore
        .collection(collectionPath)
        .orderBy('name', descending: false)
        .get()
        .then(
          (value) => value.docs.where((element) {
            return userFirms.contains(element.data()['owner_firm']);
          }),
        );
    if (collectionPath == 'clients') {
      tempClientsList = myData
          .map(
            (e) => ClientModel(
              name: e.data()['name'],
              telNo: e.data()['tel_number'],
              loggedUserEmail: e.data()['logged_user'],
              ownerFirm: e.data()['owner_firm'],
              isTVAPayer: e.data()['is_tva_payer'],
              address: e.data()['address'],
              isJuridic: e.data()['is_juridic_person'],
              cui: e.data()['cui'],
            ),
          )
          .toList();
      idList = myData.map((e) => e.id).toList();
    } else if (collectionPath == 'services') {
      tempServicesList = myData
          .map(
            (e) => ServiceModel(
              name: e.data()['name'],
              loggedUserEmail: e.data()['logged_user'],
              ownerFirm: e.data()['owner_firm'],
            ),
          )
          .toList();
      idList = myData.map((e) => e.id).toList();
    }

    // isLoading = false;
    if (collectionPath == 'clients') {
      cloudAddressBook = tempClientsList;
      cloudContactsIdList = idList;
      return cloudAddressBook;
    } else if (collectionPath == 'services') {
      cloudServicesBook = tempServicesList;
      cloudServicesIdList = idList;
      return cloudServicesBook;
    }
    return [];
  }

  Future<bool> addClientFunction({
    required String name,
    required String telNo,
    required bool isJuridic,
    required String? address,
    required String cui,
    required bool isTVAPayer,
    required String ownerFirm,
    required String collection,
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firebaseFirestore,
  }) async {
    clientModel = ClientModel(
      name: name,
      telNo: telNo.replaceAll(RegExp(r'\D+'), ''),
      loggedUserEmail: firebaseAuth.currentUser!.email.toString(),
      address: address,
      isJuridic: isJuridic,
      cui: cui.replaceAll(RegExp(r'\D+'), ''),
      isTVAPayer: isTVAPayer,
      ownerFirm: ownerFirm,
    );

    cloudAddressBook.add(clientModel);

    try {
      DocumentReference newDocRef =
          await firebaseFirestore.collection('clients').add({
        'name': name,
        'tel_number': telNo.replaceAll(RegExp(r'\D+'), ''),
        'logged_user': firebaseAuth.currentUser!.email.toString(),
        'is_juridic_person': isJuridic,
        'address': address,
        'cui': cui.replaceAll(RegExp(r'\D+'), ''),
        'is_tva_payer': isTVAPayer,
        'owner_firm': ownerFirm,
      });
      cloudContactsIdList.add(newDocRef.id);
    } catch (e) {
      errorMessage = e.toString();
      return false;
    }
    return true;
  }

  Future<bool> addClientInClientsList({
    required String collection,
    required String name,
    required String telNo,
    required bool isJuridic,
    required String? address,
    required String cui,
    required bool isTVAPayer,
    required String ownerFirm,
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firebaseFirestore,
  }) async {
    bool isCompleted = false;
    if (!cloudAddressBook.any((element) =>
        element.telNo.replaceAll(RegExp(r'\D+'), '') ==
        telNo.replaceAll(RegExp(r'\D+'), ''))) {
      if (isJuridic) {
        if (cloudAddressBook.any((element) =>
            element.cui!.replaceAll(RegExp(r'\D+'), '') ==
            cui.replaceAll(RegExp(r'\D+'), ''))) {
          var existingName = cloudAddressBook
              .firstWhere((element) =>
                  element.cui!.replaceAll(RegExp(r'\D+'), '') ==
                  cui.replaceAll(RegExp(r'\D+'), ''))
              .name;
          errorMessage =
              'Furnizorul cu acest CUI ${cui.replaceAll(RegExp(r'\D+'), '')} exista deja in lista ta.\nNumele: $existingName';
          isCompleted = false;
          return isCompleted;
        } else {
          isCompleted = await addClientFunction(
            name: name,
            telNo: telNo,
            isJuridic: isJuridic,
            address: address,
            cui: cui,
            isTVAPayer: isTVAPayer,
            ownerFirm: ownerFirm,
            collection: collection,
            firebaseAuth: firebaseAuth,
            firebaseFirestore: firebaseFirestore,
          );
          isCompleted = true;
          return isCompleted;
        }
      } else {
        isCompleted = await addClientFunction(
          name: name,
          telNo: telNo,
          isJuridic: isJuridic,
          address: address,
          cui: cui,
          isTVAPayer: isTVAPayer,
          ownerFirm: ownerFirm,
          collection: collection,
          firebaseAuth: firebaseAuth,
          firebaseFirestore: firebaseFirestore,
        );
        isCompleted = true;
        // return isCompleted;
      }
    } else {
      var existingName = cloudAddressBook
          .firstWhere((element) =>
              element.telNo.replaceAll(RegExp(r'\D+'), '') ==
              telNo.replaceAll(RegExp(r'\D+'), ''))
          .name;
      errorMessage =
          'Nr. de telefon ${telNo.replaceAll(RegExp(r'\D+'), '')} exista deja in lista ta.\nNumele: $existingName';
      isCompleted = false;
      // return false;
    }
    return isCompleted;
  }

  Future<bool> addServiceInServicesList({
    required String collection,
    required String name,
    required String ownerFirm,
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firebaseFirestore,
  }) async {
    bool isCompleted = false;
    try {
      if (!cloudServicesBook
          .any((element) => element.name.toLowerCase() == name.toLowerCase())) {
        cloudServicesBook.add(ServiceModel(
            name: name,
            loggedUserEmail: firebaseAuth.currentUser!.email.toString(),
            ownerFirm: ownerFirm));
        DocumentReference serviceDocRef =
            await firebaseFirestore.collection(collection).add({
          'name': name,
          'logged_user': firebaseAuth.currentUser!.email.toString(),
          'owner_firm': ownerFirm,
        });
        cloudServicesIdList.add(serviceDocRef.id);

        isCompleted = true;
      } else {
        errorMessage = 'Acest serviciu exista deja';
        isCompleted = false;
      }
      serviceModel = ServiceModel(
          name: name,
          loggedUserEmail: firebaseAuth.currentUser!.email.toString(),
          ownerFirm: ownerFirm);
    } catch (e) {
      errorMessage = e.toString();
    }
    return isCompleted;
  }

  Future<bool> editExistingEntry({
    required String collection,
    required String name,
    required String oldName,
    required String telNo,
    required bool isJuridic,
    required String? address,
    required String cui,
    required bool isTVAPayer,
    required String ownerFirm,
    required int index,
    required FirebaseAuth firebaseAuth,
    required FirebaseFirestore firebaseFirestore,
  }) async {
    bool isCompleted = false;
    try {
      if (collection != 'services') {
        // var oldTelNo = cloudAddressBook[index].telNo;
        // var oldCui = cloudAddressBook[index].cui;
        cloudAddressBook[index] = ClientModel(
            name: name,
            telNo: telNo,
            address: address,
            cui: cui,
            isJuridic: isJuridic,
            isTVAPayer: isTVAPayer,
            loggedUserEmail: firebaseAuth.currentUser!.email.toString(),
            ownerFirm: ownerFirm);

        await firebaseFirestore
            .collection(collection)
            .doc(cloudContactsIdList[index])
            .update({
          'name': name,
          'is_tva_payer': isTVAPayer,
        });

        var sameNameTransactions = await firebaseFirestore
            .collection('transactions')
            .get()
            .then((value) => value.docs.where((element) {
                  return element.data()['partner_name'] == oldName &&
                      ownerFirm.contains(element.data()['cui']);
                }));
        for (var transaction in sameNameTransactions) {
          await firebaseFirestore
              .collection('transactions')
              .doc(transaction.id)
              .update({
            'partner_name': name,
          });
        }
        var sameNameAppointments = await firebaseFirestore
            .collection('appointments')
            .get()
            .then((value) => value.docs
                .where(
                  (element) =>
                      element.data()['partner_name'] == oldName &&
                      ownerFirm.contains(element.data()['cui']),
                )
                .toList());
        for (var transaction in sameNameAppointments) {
          await firebaseFirestore
              .collection('appointments')
              .doc(transaction.id)
              .update({
            'partner_name': name,
          });
        }
        isCompleted = true;
        return isCompleted;
      } else {
        cloudServicesBook[index] = ServiceModel(
            name: name[0].toUpperCase() + name.substring(1).toLowerCase(),
            loggedUserEmail: firebaseAuth.currentUser!.email.toString(),
            ownerFirm: ownerFirm);

        await firebaseFirestore
            .collection(collection)
            .doc(cloudServicesIdList[index])
            .update({
          'name': name[0].toUpperCase() + name.substring(1).toLowerCase(),
        });
        isCompleted = true;
        return isCompleted;
      }
    } catch (e) {
      errorMessage = e.toString();
    }
    return isCompleted;
  }

  Future<bool> deleteListEntry({
    required String collection,
    required int listId,
    required String cloudId,
    required FirebaseFirestore firebaseFirestore,
  }) async {
    // isLoading = true;
    if (collection == 'services') {
      cloudServicesBook.removeAt(listId);
    } else {
      cloudAddressBook.removeAt(listId);
    }
    await firebaseFirestore.collection(collection).doc(cloudId).delete();
    // isLoading = false;
    return true;
  }
}

final addressBookProvider = StateNotifierProvider<AddressBookProvider, String>(
  (ref) => AddressBookProvider(),
);
