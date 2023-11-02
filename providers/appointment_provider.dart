import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunrise_app/models/transaction_model.dart';

class AppointmentProvider extends StateNotifier<TransactionModel> {
  AppointmentProvider()
      : super(
          TransactionModel(
              partnerName: '',
              serviceProductName: '',
              price: 0,
              dateTime: DateTime.now(),
              transactionSign: '',
              cui: '',
              userEmail: '',
              observations: '',
              telNo: '',
              isTransaction: false),
        );

  bool isLoading = false;
  String errorMessage = '';

  void saveTransactionEntry(
    TransactionModel transactionModel,
    FirebaseFirestore firebaseFirestore,
    String collection,
  ) async {
    isLoading = true;

    var transactionData = {
      'partner_name': transactionModel.partnerName,
      'service_product_name': transactionModel.serviceProductName,
      'price': transactionModel.price,
      'date_time': transactionModel.dateTime,
      'transaction_sign': transactionModel.transactionSign,
      'cui': transactionModel.cui,
      'user_email': transactionModel.userEmail,
      'observations': transactionModel.observations,
      'partner_tel_number': transactionModel.telNo,
      'is_collected': transactionModel.isTransaction,
    };

    if (collection == 'appointment' && transactionModel.isTransaction) {
      await firebaseFirestore.collection('transactions').add(transactionData);
    }
    state = TransactionModel(
        partnerName: transactionModel.partnerName,
        serviceProductName: transactionModel.serviceProductName,
        price: transactionModel.price,
        dateTime: transactionModel.dateTime,
        transactionSign: transactionModel.transactionSign,
        cui: transactionModel.cui,
        userEmail: transactionModel.userEmail,
        observations: transactionModel.observations,
        telNo: transactionModel.telNo,
        isTransaction: transactionModel.isTransaction);
    await firebaseFirestore.collection(collection).add(transactionData);
    isLoading = false;
  }

  void editTransactionEntry({
    required TransactionModel transactionModel,
    required FirebaseFirestore firebaseFirestore,
    required String docID,
    required String collection,
  }) async {
    isLoading = true;

    var transactionData = {
      'partner_name': transactionModel.partnerName,
      'service_product_name': transactionModel.serviceProductName,
      'price': transactionModel.price,
      'date_time': transactionModel.dateTime,
      'transaction_sign': transactionModel.transactionSign,
      'cui': transactionModel.cui,
      'user_email': transactionModel.userEmail,
      'observations': transactionModel.observations,
      'partner_tel_number': transactionModel.telNo,
      'is_collected': transactionModel.isTransaction,
    };

    try {
      DocumentReference transactionDocRef =
          firebaseFirestore.collection('transactions').doc(docID);
      transactionDocRef.get().then((value) {
        if (value.exists) {
          transactionDocRef.update(transactionData);
        }
      });
      DocumentReference appointmentDocRef =
          firebaseFirestore.collection('appointments').doc(docID);
      appointmentDocRef.get().then((value) {
        if (value.exists) {
          appointmentDocRef.update(transactionData);
        }
      });
    } catch (e) {
      return null;
    }
    isLoading = false;
  }

  void deleteTransaction({
    required String collection,
    required String docID,
    required FirebaseFirestore firebaseFirestore,
  }) async {
    await firebaseFirestore.collection(collection).doc(docID).delete();

    if (collection == 'transactions') {
      try {
        await firebaseFirestore.collection('appointments').doc(docID).update({
          'is_collected': false,
        });
      } catch (e) {
        return null;
      }
    }
  }

  void collectAppointment({
    required String docID,
    required FirebaseFirestore firebaseFirestore,
    required TransactionModel transactionModel,
  }) async {
    await firebaseFirestore.collection('transactions').doc(docID).set({
      'partner_name': transactionModel.partnerName,
      'service_product_name': transactionModel.serviceProductName,
      'partner_tel_number': transactionModel.telNo,
      'price': transactionModel.price,
      'transaction_sign': transactionModel.transactionSign,
      'date_time': transactionModel.dateTime,
      'cui': transactionModel.cui,
      'user_email': transactionModel.userEmail,
      'observations': transactionModel.observations,
      'is_collected': true,
    });
    await firebaseFirestore.collection('appointments').doc(docID).update({
      'is_collected': true,
    });
  }
}

final appointmentProvider =
    StateNotifierProvider<AppointmentProvider, TransactionModel>(
  (ref) => AppointmentProvider(),
);
