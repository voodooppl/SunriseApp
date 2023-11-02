import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sunrise_app/providers/firms_information_provider.dart';
import 'package:sunrise_app/providers/user_information_provider.dart';
import 'package:sunrise_app/screens/add_edit_firms.dart';
import 'package:sunrise_app/screens/main_screen.dart';
import 'package:sunrise_app/widgets/appointment_widget.dart';
import 'package:sunrise_app/widgets/buttom_button_large.dart';
import 'package:sunrise_app/widgets/firm_summary_widget.dart';
import 'package:uuid/uuid.dart';
import '../models/firm_identification_data.dart';
import '../models/transaction_model.dart';
import '../providers/address_book_provider.dart';
import '../widgets/transaction_widget.dart';

Uuid uuid = const Uuid();

class FirmScreen extends ConsumerStatefulWidget {
  const FirmScreen(
      {required this.loggedUserEmail,
      required this.firmIdentificationData,
      required this.firebaseFirestore,
      required this.userRole,
      Key? key})
      : super(key: key);
  final String loggedUserEmail;
  final FirmIdentificationData firmIdentificationData;
  final FirebaseFirestore firebaseFirestore;
  final String userRole;

  @override
  ConsumerState<FirmScreen> createState() => _FirmScreenState();
}

class _FirmScreenState extends ConsumerState<FirmScreen> {
  late DateTime _date = DateTime.now();
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  late Widget _transactionsListWidgets;
  late final String _firmName = widget.firmIdentificationData.firmName;
  double _income = 0;
  double _outcome = 0;
  late double _monthlyBalance;
  double _yearlyBalance = 0;
  // late bool _isLoading = false;
  String randomTransactionId = uuid.v4();

  bool _isDifferentDay(String date1, String date2) {
    return _extractDate(date1) != _extractDate(date2);
  }

  String _extractDate(String dateTime) {
    return dateTime.split(' ')[0];
  }

  StreamBuilder _transactionsStream() {
    return StreamBuilder(
      stream: _firebaseFirestore
          .collection('transactions')
          .orderBy('date_time', descending: false)
          .snapshots(),
      builder: (context, snapshots) {
        if (snapshots.connectionState == ConnectionState.waiting) {
          return const Expanded(
            child: Center(
              child: SizedBox(
                  height: 30, width: 30, child: CircularProgressIndicator()),
            ),
          );
        }
        if (!snapshots.hasData || snapshots.data!.docs.isEmpty) {
          return const Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('Nu sunt tranzactii in aceasta perioada'),
              ),
            ),
          );
        }
        if (snapshots.hasError) {
          return const Center(
            child: Text('A intervenit o eroare. Reincarca aplicatia'),
          );
        }
        Map<String, List<TransactionModel>> groupedData = {};
        List<String> docIDList = [];
        for (var snapshot in snapshots.data!.docs) {
          DateTime transactionDate = snapshot.data()['date_time'].toDate();
          if (transactionDate.year == _date.year &&
              snapshot.data()['cui'] == widget.firmIdentificationData.cui) {
            _executeYearlyCalculation(
              snapshot.data()['transaction_sign'],
              snapshot.data()['price'],
            );
          }
          if (!groupedData.containsKey(
                DateFormat('dd/MM/yyyy').format(transactionDate),
              ) &&
              transactionDate.month == _date.month &&
              transactionDate.year == _date.year &&
              snapshot.data()['cui'] == widget.firmIdentificationData.cui) {
            groupedData[DateFormat('dd/MM/yyyy').format(transactionDate)] = [];
          }

          if (transactionDate.month == _date.month &&
              transactionDate.year == _date.year &&
              snapshot.data()['cui'] == widget.firmIdentificationData.cui) {
            _executeMonthlyCalculation(
              snapshot.data()['transaction_sign'],
              snapshot.data()['price'],
            );
            docIDList.add(snapshot.id);
            groupedData[DateFormat('dd/MM/yyyy').format(transactionDate)]!.add(
              TransactionModel(
                partnerName: snapshot.data()['partner_name'],
                serviceProductName: snapshot.data()['service_product_name'],
                price: snapshot.data()['price'],
                dateTime: snapshot.data()['date_time'].toDate(),
                transactionSign: snapshot.data()['transaction_sign'],
                cui: snapshot.data()['cui'],
                userEmail: snapshot.data()['user_email'],
                observations: snapshot.data()['observations'],
                telNo: snapshot.data()['partner_tel_number'],
                isTransaction: snapshot.data()['is_collected'],
              ),
            );
          }
        }
        return Expanded(
          child: ListView.builder(
            itemCount: groupedData.length,
            itemBuilder: (ctx, index) {
              var myData = groupedData.keys.elementAt(index);
              var transactionsAtDay = groupedData[myData];
              bool isFirst = (index == 0 ||
                  _isDifferentDay(
                          myData, groupedData.keys.elementAt(index - 1)) &&
                      int.parse(myData.split('/')[1]) == _date.month &&
                      int.parse(myData.split('/')[2]) == _date.year);
              String transactionDay = myData.split('/')[0];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isFirst)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 5),
                      child: Text(
                        'Ziua $transactionDay',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color.fromRGBO(247, 238, 247, 255),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: transactionsAtDay!
                            .map<Widget>(
                              (transaction) => TransactionWidget(
                                transactionModel: transaction,
                                firebaseFirestore: _firebaseFirestore,
                                collection: 'transactions',
                                docID: docIDList[index],
                                userRole: widget.userRole,
                                ownerCui: widget.firmIdentificationData.cui,
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<List<double>> _calculateMontlyBalance(
      String transactionSign, double price) async {
    List<double> myList = [];
    if (transactionSign == '+') {
      _income = _income + price;
    } else if (transactionSign == '-') {
      _outcome = _outcome + price;
    }
    myList.add(_income);
    myList.add(_outcome);
    return myList;
  }

  Future<double> _calculateYearlyBalance(
      String transactionSign, double price) async {
    if (transactionSign == '+') {
      _yearlyBalance = _yearlyBalance + price;
    } else if (transactionSign == '-') {
      _yearlyBalance = _yearlyBalance - price;
    }
    return _yearlyBalance;
  }

  void _executeMonthlyCalculation(String transactionSign, double price) async {
    List<double> newList = [];
    newList = await _calculateMontlyBalance(transactionSign, price);
    setState(() {
      _income = newList[0];
      _outcome = newList[1];
      _monthlyBalance = _income - _outcome;
    });
  }

  void _executeYearlyCalculation(String transactionSign, double price) async {
    double balance;
    balance = await _calculateYearlyBalance(transactionSign, price);
    setState(() {
      _yearlyBalance = balance;
    });
  }

  void _modifyDate(String operation) {
    if (operation == '+') {
      var newDate = DateTime(_date.year, _date.month + 1, _date.day);
      setState(() {
        _date = newDate;
      });
    } else if (operation == '-') {
      var newDate = DateTime(_date.year, _date.month - 1, _date.day);
      setState(() {
        _date = newDate;
      });
    }
    setState(() {
      _income = 0;
      _outcome = 0;
      _monthlyBalance = 0;
      _yearlyBalance = 0;
      _transactionsListWidgets = _transactionsStream();
    });
  }

  void _getCloudData() async {
    await ref.read(addressBookProvider.notifier).getCloudData('clients',
        ref.read(userInformationProvider).userFirms, widget.firebaseFirestore);
    await ref.read(addressBookProvider.notifier).getCloudData('services',
        ref.read(userInformationProvider).userFirms, widget.firebaseFirestore);

    ///get firm information
    ref.read(firmsInformationProvider.notifier).getCloudFirmInformation(
        widget.firmIdentificationData.cui,
        ref.read(userInformationProvider),
        widget.firebaseFirestore);
  }

  @override
  void initState() {
    super.initState();
    _transactionsListWidgets = _transactionsStream();
    _monthlyBalance = _income - _outcome;
    _getCloudData();
  }

  @override
  Widget build(BuildContext context) {
    var screenWidth = MediaQuery.sizeOf(context).width;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
          ),
        );
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _firmName.toString().toUpperCase(),
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
          leading: IconButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const MainScreen()));
              },
              icon: const Icon(Icons.arrow_back)),
          actions: [
            IconButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (ctx) => AddEditFirms(
                      loggedUser: widget.loggedUserEmail,
                      isCreate: false,
                      firmIdentificationData: widget.firmIdentificationData,
                      firebaseFirestore: widget.firebaseFirestore,
                      userRole: widget.userRole,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.settings),
            ),
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    _modifyDate('-');
                  },
                  icon: Icon(
                    Icons.chevron_left,
                    color: Theme.of(context).colorScheme.primary,
                    size: 35,
                  ),
                ),
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '${_date.month.toString()} - ${_date.year.toString()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _modifyDate('+');
                  },
                  icon: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.primary,
                    size: 35,
                  ),
                ),
              ],
            ),
            if (screenWidth > 600)
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: FirmSummaryWidget(
                        date: _date,
                        firmName: _firmName,
                        income: _income,
                        outcome: _outcome,
                        monthlyBalance: _monthlyBalance,
                        yearlyBalance: _yearlyBalance,
                      ),
                    ),
                    _transactionsListWidgets,
                  ],
                ),
              ),
            if (screenWidth < 600)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.15,
                child: FirmSummaryWidget(
                  date: _date,
                  firmName: _firmName,
                  income: _income,
                  outcome: _outcome,
                  monthlyBalance: _monthlyBalance,
                  yearlyBalance: _yearlyBalance,
                ),
              ),
            if (screenWidth < 600) _transactionsListWidgets,
            BottomLargeButton(
              buttonName: 'Adauga tranzactie',
              onTapFunction: () async {
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => AppointmentWidget(
                        isView: false,
                        firebaseFirestore: widget.firebaseFirestore,
                        collection: 'transactions',
                        isTransaction: true,
                        docID: '',
                        dateTime: DateTime.now(),
                        storedClients: ref
                            .watch(addressBookProvider.notifier)
                            .cloudAddressBook,
                        servicesList: ref
                            .watch(addressBookProvider.notifier)
                            .cloudServicesBook,
                        ownerCui: widget.firmIdentificationData.cui,
                        userRole: widget.userRole,
                      ),
                    ),
                  );
                }
              },
              myIcon: const Icon(Icons.add_circle_outline_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
