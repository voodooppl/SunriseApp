import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunrise_app/models/transaction_model.dart';
import '../providers/address_book_provider.dart';
import 'appointment_widget.dart';

class TransactionWidget extends ConsumerWidget {
  const TransactionWidget(
      {required this.transactionModel,
      required this.firebaseFirestore,
      required this.collection,
      required this.docID,
      required this.userRole,
      required this.ownerCui,
      Key? key})
      : super(key: key);

  final TransactionModel transactionModel;
  final FirebaseFirestore firebaseFirestore;
  final String collection;
  final String docID;
  final String ownerCui;
  final String userRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      tileColor: const Color.fromRGBO(240, 223, 242, 155),
      onTap: () async {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => AppointmentWidget(
              isView: true,
              firebaseFirestore: firebaseFirestore,
              transactionModel: transactionModel,
              collection: collection,
              isTransaction: transactionModel.isTransaction,
              docID: docID,
              storedClients:
                  ref.watch(addressBookProvider.notifier).cloudAddressBook,
              servicesList:
                  ref.watch(addressBookProvider.notifier).cloudServicesBook,
              ownerCui: ownerCui,
              userRole: userRole,
            ),
          ),
        );
      },
      leading: Container(
        decoration: BoxDecoration(
          border: Border.all(
              width: 1, color: Theme.of(context).colorScheme.primary),
          borderRadius: const BorderRadius.all(
            Radius.circular(5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Text(
          '${transactionModel.dateTime.hour.toString().padLeft(2, '0')} : ${transactionModel.dateTime.minute.toString().padLeft(2, '0')}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ),
      title: Text(
        transactionModel.partnerName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        transactionModel.serviceProductName,
      ),
      trailing: Text(
        '${transactionModel.transactionSign} ${transactionModel.price.toStringAsFixed(2)}',
        style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: transactionModel.transactionSign == '+'
                ? (transactionModel.isTransaction
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary)
                : Colors.red),
      ),
    );
  }
}
