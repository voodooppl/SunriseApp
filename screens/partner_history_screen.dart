import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sunrise_app/providers/firms_information_provider.dart';
import 'package:sunrise_app/widgets/transaction_widget.dart';
import '../models/transaction_model.dart';

class PartnerHistoryScreen extends ConsumerStatefulWidget {
  const PartnerHistoryScreen(
      {required this.transactionModel,
      required this.firebaseFirestore,
      required this.collection,
      required this.isClientHistory,
      // required this.isCollected,
      required this.userRole,
      required this.ownerCui,
      Key? key})
      : super(key: key);

  final TransactionModel transactionModel;
  final FirebaseFirestore firebaseFirestore;
  final String collection;
  final bool isClientHistory;
  // final bool isCollected;
  final String userRole;
  final String ownerCui;

  @override
  ConsumerState<PartnerHistoryScreen> createState() =>
      _PartnerHistoryScreenState();
}

class _PartnerHistoryScreenState extends ConsumerState<PartnerHistoryScreen> {
  List<TransactionModel> _historyList = [];
  List<String> _docIDList = [];
  late bool _isLoading = false;

  void _getHistoryList() async {
    setState(() {
      _isLoading = true;
    });
    List<TransactionModel> myList = [];
    List<String> docIDList = [];
    var myData = await widget.firebaseFirestore
        .collection(widget.collection)
        .orderBy('date_time', descending: true)
        .get();
    for (var docs in myData.docs) {
      if (widget.isClientHistory &&
          docs.data()['cui'] == widget.ownerCui &&
          docs.data()['partner_tel_number'] == widget.transactionModel.telNo) {
        docIDList.add(docs.id);
        myList.add(
          TransactionModel(
            partnerName: docs.data()['partner_name'],
            serviceProductName: docs.data()['service_product_name'],
            price: docs.data()['price'],
            dateTime: docs.data()['date_time'].toDate(),
            transactionSign: docs.data()['transaction_sign'],
            cui: docs.data()['cui'],
            userEmail: docs.data()['user_email'],
            observations: docs.data()['observations'],
            telNo: docs.data()['partner_tel_number'],
            isTransaction: docs.data()['is_collected'],
          ),
        );
      }
      if (!widget.isClientHistory &&
          docs.data()['cui'] == ref.read(firmsInformationProvider).cui &&
          docs.data()['service_product_name'] ==
              widget.transactionModel.serviceProductName) {
        docIDList.add(docs.id);
        myList.add(
          TransactionModel(
            partnerName: docs.data()['partner_name'],
            serviceProductName: docs.data()['service_product_name'],
            price: docs.data()['price'],
            dateTime: docs.data()['date_time'].toDate(),
            transactionSign: docs.data()['transaction_sign'],
            cui: docs.data()['cui'],
            userEmail: docs.data()['user_email'],
            observations: docs.data()['observations'],
            telNo: docs.data()['partner_tel_number'],
            isTransaction: docs.data()['is_collected'],
          ),
        );
      }
    }
    setState(() {
      _historyList = myList;
      _docIDList = docIDList;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getHistoryList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.isClientHistory
            ? Text(widget.transactionModel.partnerName)
            : Text(widget.transactionModel.serviceProductName),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemBuilder: (ctx, index) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 5),
                            child: Text(
                              'Ziua ${DateFormat('dd/MM/yyyy').format(_historyList[index].dateTime)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          TransactionWidget(
                            transactionModel: TransactionModel(
                              partnerName: _historyList[index].partnerName,
                              serviceProductName:
                                  _historyList[index].serviceProductName,
                              price: _historyList[index].price,
                              dateTime: _historyList[index].dateTime,
                              transactionSign:
                                  _historyList[index].transactionSign,
                              cui: _historyList[index].cui,
                              userEmail: _historyList[index].userEmail,
                              observations: _historyList[index].observations,
                              telNo: _historyList[index].telNo,
                              isTransaction: _historyList[index].isTransaction,
                            ),
                            firebaseFirestore: widget.firebaseFirestore,
                            collection: widget.collection,
                            docID: _docIDList[index],
                            ownerCui: widget.ownerCui,
                            userRole: widget.userRole,
                          ),
                        ],
                      );
                    },
                    itemCount: _historyList.length,
                  ),
                )
              ],
            ),
    );
  }
}
