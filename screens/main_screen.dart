import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunrise_app/models/firm_identification_data.dart';
import 'package:sunrise_app/providers/theme_provider.dart';
import 'package:sunrise_app/providers/user_information_provider.dart';
import 'package:sunrise_app/screens/firm_screen.dart';
import 'package:sunrise_app/screens/appointments_main_screen.dart';
import 'package:sunrise_app/widgets/buttom_button_large.dart';
import '../models/user_info_model.dart';
import '../providers/address_book_provider.dart';
import '../widgets/main_drawer.dart';
import 'add_edit_firms.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  // final UserInformation? userInformation;

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  late FirmIdentificationData _firmIdentificationData;
  late UserInformation? _userInformation;
  late String _userRole;
  final List<dynamic> _managedFirmsList = [];

  Future<void> _checkInternetConnection() async {
    final connectivityResult = await (Connectivity().checkConnectivity());

    _onConnectivityChanged(connectivityResult);
  }

  void _onConnectivityChanged(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'Lipsa conexiune la internet',
            textAlign: TextAlign.center,
          ),
          content: const Text(
            'Modificarile si adaugirile nu se vor urca in cloud si se vor pierde. Foloseste aplicatia doar pentru vizualizare, pana la remedierea conexiunii la internet.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // _userInformation = ref.watch(colorSchemeProvider.notifier).userInformation!;
    // _userInformation = UserInformation(
    //     loggedUser: 'romeo_oprescu@yahoo.com', alias: 'RR', userFirms: []);
    _checkInternetConnection();
  }

  @override
  Widget build(BuildContext context) {
    _userInformation = ref.watch(colorSchemeProvider.notifier).userInformation;
    print(_userInformation!.alias);
    print('main screen');
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Bine ai venit \n${_userInformation!.alias ?? ''}',
            textAlign: TextAlign.center,
          ),
          centerTitle: true,
        ),
        drawer: MainDrawer(
            alias: _userInformation!.alias,
            auth: _firebaseAuth,
            firebaseFirestore: _firebaseFirestore,
            managedFirmsList: _managedFirmsList),
        body: StreamBuilder(
          stream: _firebaseFirestore
              .collection('firme')
              .orderBy('firm_name', descending: false)
              .snapshots(),
          builder: (ctx, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
            var data = snapshot.data!.docs
                .where(
                  (element) =>
                      element['admin'] == _firebaseAuth.currentUser!.email ||
                      element['managers']
                          .contains(_firebaseAuth.currentUser!.email) ||
                      element['users']
                          .contains(_firebaseAuth.currentUser!.email),
                )
                .toList();
            // final List<dynamic> userMatchedFirmsList = [];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (data.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('Adauga o firma noua'),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemBuilder: (ctx, index) {
                        if (data[index].data()['admin'] ==
                            _firebaseAuth.currentUser!.email) {
                          _userRole = 'admin';
                          _managedFirmsList.add([
                            data[index].data(),
                            _userRole,
                            data[index].id,
                          ]);
                        } else if (data[index]
                            .data()['managers']
                            .contains(_firebaseAuth.currentUser!.email)) {
                          _userRole = 'manager';
                          _managedFirmsList.add([
                            data[index].data(),
                            _userRole,
                            data[index].id,
                          ]);
                        } else if (data[index]
                            .data()['users']
                            .contains(_firebaseAuth.currentUser!.email)) {
                          _userRole = 'user';
                          _managedFirmsList.add([
                            data[index].data(),
                            _userRole,
                            data[index].id,
                          ]);
                        }
                        return Container(
                          margin: const EdgeInsets.only(
                              top: 20, left: 10, right: 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(
                                  margin: const EdgeInsets.only(right: 5),
                                  height: 130,
                                  child: Card(
                                    elevation: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(20),
                                      child: Column(
                                        children: [
                                          const Text(
                                            'Progamari',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          IconButton(
                                            onPressed: () async {
                                              _firmIdentificationData =
                                                  FirmIdentificationData(
                                                firmName: data[index]
                                                    .data()['firm_name'],
                                                address: data[index]
                                                    .data()['address'],
                                                isJuridic: data[index].data()[
                                                    'is_juridic_person'],
                                                cui: data[index].data()['CUI'],
                                                isTVAPayer:
                                                    data[index].data()['TVA'],
                                                telNo: data[index]
                                                    .data()['tel_number'],
                                                admin: _userInformation!
                                                    .loggedUser,
                                                managers: data[index]
                                                    .data()['managers']
                                                    .cast<String>(),
                                                users: data[index]
                                                    .data()['users']
                                                    .cast<String>(),
                                                notificationMessage:
                                                    data[index].data()[
                                                        'notification_message'],
                                              );
                                              await ref
                                                  .read(addressBookProvider
                                                      .notifier)
                                                  .getCloudData(
                                                      'clients',
                                                      ref
                                                          .read(
                                                              userInformationProvider)
                                                          .userFirms,
                                                      _firebaseFirestore);
                                              await ref
                                                  .read(addressBookProvider
                                                      .notifier)
                                                  .getCloudData(
                                                      'services',
                                                      ref
                                                          .read(
                                                              userInformationProvider)
                                                          .userFirms,
                                                      _firebaseFirestore);
                                              if (context.mounted) {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                      builder: (ctx) {
                                                    return AppointmentsMainScreen(
                                                      ownerFirmCui:
                                                          _firmIdentificationData
                                                              .cui,
                                                      ownerFirmName:
                                                          _firmIdentificationData
                                                              .firmName,
                                                      userInformation:
                                                          _userInformation!,
                                                      firebaseFirestore:
                                                          _firebaseFirestore,
                                                      userRole:
                                                          _managedFirmsList[
                                                              index][1],
                                                    );
                                                  }),
                                                );
                                              }
                                            },
                                            icon: Icon(
                                              Icons.calendar_month,
                                              size: 45,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    GestureDetector(
                                      onTap: _userRole == 'admin' ||
                                              _userRole == 'manager'
                                          ? () async {
                                              _firmIdentificationData =
                                                  FirmIdentificationData(
                                                firmName: data[index]
                                                    .data()['firm_name'],
                                                address: data[index]
                                                    .data()['address'],
                                                isJuridic: data[index].data()[
                                                    'is_juridic_person'],
                                                cui: data[index].data()['CUI'],
                                                isTVAPayer:
                                                    data[index].data()['TVA'],
                                                telNo: data[index]
                                                    .data()['tel_number'],
                                                admin: _userInformation!
                                                    .loggedUser,
                                                managers: data[index]
                                                    .data()['managers']
                                                    .cast<String>(),
                                                users: data[index]
                                                    .data()['users']
                                                    .cast<String>(),
                                                notificationMessage:
                                                    data[index].data()[
                                                        'notification_message'],
                                              );

                                              await ref
                                                  .read(addressBookProvider
                                                      .notifier)
                                                  .getCloudData(
                                                      'clients',
                                                      ref
                                                          .read(
                                                              userInformationProvider)
                                                          .userFirms,
                                                      _firebaseFirestore);
                                              await ref
                                                  .read(addressBookProvider
                                                      .notifier)
                                                  .getCloudData(
                                                      'services',
                                                      ref
                                                          .read(
                                                              userInformationProvider)
                                                          .userFirms,
                                                      _firebaseFirestore);

                                              if (context.mounted) {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (ctx) =>
                                                        FirmScreen(
                                                      firmIdentificationData:
                                                          _firmIdentificationData,
                                                      loggedUserEmail:
                                                          _userInformation!
                                                              .loggedUser,
                                                      firebaseFirestore:
                                                          _firebaseFirestore,
                                                      userRole:
                                                          _managedFirmsList[
                                                              index][1],
                                                    ),
                                                  ),
                                                );
                                              }
                                            }
                                          : null,
                                      child: SizedBox(
                                        height: 130,
                                        child: Card(
                                          elevation: 2,
                                          child: Padding(
                                            padding: const EdgeInsets.all(19.0),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  data[index]
                                                      .data()['firm_name'],
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      itemCount: data.length,
                    ),
                  ),
                BottomLargeButton(
                  buttonName: 'Adauga Business',
                  onTapFunction: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddEditFirms(
                          loggedUser: _userInformation!.loggedUser,
                          firebaseFirestore: _firebaseFirestore,
                          isCreate: true,
                          userRole: _userRole,
                        ),
                      ),
                    );
                  },
                  myIcon: const Icon(Icons.add_circle_outline_outlined),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
