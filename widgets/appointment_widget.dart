import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart' as fcp;
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sunrise_app/providers/appointment_provider.dart';
import 'package:sunrise_app/providers/firms_information_provider.dart';
import 'package:sunrise_app/providers/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:sunrise_app/models/service_model.dart';
import 'package:sunrise_app/models/transaction_model.dart';
import 'package:sunrise_app/providers/address_book_provider.dart';
import 'package:sunrise_app/providers/user_information_provider.dart';
import '../models/client_model.dart';
import '../screens/appointments_main_screen.dart';
import '../screens/firm_screen.dart';
import '../screens/partner_history_screen.dart';
import '../widgets/buttom_button_large.dart';
import 'add_address_book_widget.dart';

Uuid uuid = const Uuid();

class AppointmentWidget extends ConsumerStatefulWidget {
  const AppointmentWidget(
      {required this.isView,
      required this.firebaseFirestore,
      required this.collection,
      required this.isTransaction,
      required this.docID,
      required this.storedClients,
      required this.servicesList,
      this.transactionModel,
      this.dateTime,
      required this.ownerCui,
      required this.userRole,
      Key? key})
      : super(key: key);

  final bool isView;
  final FirebaseFirestore firebaseFirestore;
  final TransactionModel? transactionModel;
  final String collection;
  final bool isTransaction;
  final String docID;
  final DateTime? dateTime;
  final List<ClientModel> storedClients;
  final List<ServiceModel> servicesList;
  final String ownerCui;
  final String userRole;

  @override
  ConsumerState<AppointmentWidget> createState() => _AppointmentWidgetState();
}

class _AppointmentWidgetState extends ConsumerState<AppointmentWidget> {
  final _formKeyAddAddressBook = GlobalKey<FormState>();
  final _appWidgetFormKey = GlobalKey<FormState>();
  late bool _isEdit = false;
  late bool _isDelete = false;
  List<ClientModel> _phoneContactsList = [];
  List<ClientModel> _filteredClients = [];
  late List<ClientModel>? _storedClients = widget.storedClients;
  late List<ServiceModel>? _servicesList = widget.servicesList;
  List<ServiceModel> _filteredServices = [];
  late String? _clientName = widget.transactionModel?.partnerName;
  late String? _serviceName = widget.transactionModel?.serviceProductName;
  late String? _partnerTelNo = widget.transactionModel?.telNo;
  late double? _price = widget.transactionModel?.price;
  late String? _transactionSign = widget.transactionModel?.transactionSign;
  late DateTime? _dateTime =
      widget.transactionModel?.dateTime ?? widget.dateTime;
  late String _observations = widget.transactionModel!.observations;
  late String errorMessage = '';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _serviceController = TextEditingController();
  bool clientsLabel = false;
  bool servicesLabel = false;
  bool dateLabel = false;
  bool _isLoading = false;
  late bool _isEditPartner = widget.isView;
  late bool _isEditService = widget.isView;
  late bool _phoneContacts = false;
  late bool _isTransaction = widget.isTransaction;
  late String _tranzTitle = '';
  late bool _isPartnerJuridicPerson = false;
  late String _partnerAddress = '';
  late String _partenerCui = '';
  late bool _isPartnerTVAPayer = false;
  final String _collection = '';

  ///Doesn't work on Huawei phones, switched to _pickPhoneContacts();
  // void _getPhoneContact() async {
  //   List<ClientModel> phoneContactsList = [];
  //   // Request contact permission
  //   if (await FlutterContacts.requestPermission()) {
  //     // Get all contacts (lightly fetched)
  //     List<Contact> contacts =
  //         await FlutterContacts.getContacts(withProperties: true);
  //     for (Contact contact in contacts) {
  //       phoneContactsList.add(
  //         ClientModel(
  //           name: contact.displayName.toString(),
  //           telNo: contact.phones[0].number,
  //           loggedUserEmail: ref.read(userInformationProvider).loggedUser,
  //           ownerFirm: ref.read(firmsInformationProvider).cui,
  //           address: '',
  //           cui: '',
  //           isJuridic: false,
  //           isTVAPayer: false,
  //         ),
  //       );
  //     }
  //   }
  //   setState(() {
  //     _phoneContactsList = phoneContactsList;
  //   });
  // }

  Future<void> _pickPhoneContacts() async {
    // Request permission to access contacts
    if (await Permission.contacts.request().isGranted) {
      // Permission granted, open the contact picker
    } else {
      await Permission.contacts.request();
    }
    final myContact = await fcp.FlutterContactPicker.pickPhoneContact();

    setState(() {
      _clientName = myContact.fullName.toString();
      _partnerTelNo =
          myContact.phoneNumber.toString().replaceAll(RegExp(r'\D+'), '');
      _partnerAddress = '';
      _isPartnerJuridicPerson = false;
      _partenerCui = '';
      _isPartnerTVAPayer = false;
    });
  }

  void _filterClients(String searchText, List<ClientModel> clientList) {
    setState(() {
      _filteredClients = clientList
          .where((client) =>
              client.name.toLowerCase().contains(searchText.toLowerCase()))
          .toList();
    });
  }

  void _filterServices(String searchText) {
    setState(() {
      _filteredServices = _servicesList!
          .where((client) =>
              client.name.toLowerCase().contains(searchText.toLowerCase()))
          .toList();
    });
  }

  void _showDateTimePicker() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: _dateTime!,
      firstDate: DateTime(2019, 1, 1),
      lastDate: DateTime(2099, 1, 1),
    );

    if (selectedDate == null) return null;

    if (!mounted) return null;

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime!),
    );
    if (selectedTime == null) {
      return null;
    }
    var mySelectedDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    setState(() {
      _dateTime = mySelectedDateTime;
      errorMessage = '';
      dateLabel = false;
    });
  }

  void _deleteItem() {
    if (_isDelete) {
      showDialog(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: widget.collection == 'transactions'
                  ? const Text(
                      'Sterge tranzactie?',
                      textAlign: TextAlign.center,
                    )
                  : const Text(
                      'Sterge programare?',
                      textAlign: TextAlign.center,
                    ),
              content: widget.collection == 'transactions'
                  ? const Text(
                      'Esti sigur ca vrei sa stergi aceasta tranzactie?',
                      textAlign: TextAlign.center,
                    )
                  : const Text(
                      'Esti sigur ca vrei sa stergi aceasta programare?',
                      textAlign: TextAlign.center,
                    ),
              actionsAlignment: MainAxisAlignment.spaceEvenly,
              actions: [
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : ButtonBar(
                        alignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                              onPressed: () async {
                                setState(() {
                                  _isLoading = true;
                                });
                                ref
                                    .read(appointmentProvider.notifier)
                                    .deleteTransaction(
                                        collection: widget.collection,
                                        docID: widget.docID,
                                        firebaseFirestore:
                                            widget.firebaseFirestore);

                                ///SnackBar message here
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(widget.collection == 'appointments'
                                            ? 'Programare stearsa'
                                            : 'Tranzactie stearsa'),
                                        TextButton.icon(
                                          onPressed: () {
                                            ref
                                                .read(appointmentProvider
                                                    .notifier)
                                                .saveTransactionEntry(
                                                    TransactionModel(
                                                        partnerName:
                                                            _clientName!,
                                                        serviceProductName:
                                                            _serviceName!,
                                                        price: _price!,
                                                        dateTime: _dateTime!,
                                                        transactionSign:
                                                            _transactionSign!,
                                                        cui: widget.ownerCui,
                                                        userEmail: ref
                                                            .read(
                                                                userInformationProvider)
                                                            .loggedUser,
                                                        observations:
                                                            _observations,
                                                        telNo: _partnerTelNo!,
                                                        isTransaction:
                                                            _isTransaction),
                                                    ref.read(firebaseFirestore),
                                                    widget.collection);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .hideCurrentSnackBar();
                                            }
                                          },
                                          icon: const Icon(Icons.undo),
                                          label: const Text('Anulare'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );

                                setState(() {
                                  _isLoading = false;
                                });

                                if (context.mounted) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (ctx) {
                                      return widget.collection == 'transactions'
                                          ? FirmScreen(
                                              firmIdentificationData: ref.read(
                                                  firmsInformationProvider),
                                              loggedUserEmail: ref
                                                  .read(userInformationProvider)
                                                  .loggedUser,
                                              firebaseFirestore:
                                                  widget.firebaseFirestore,
                                              userRole: widget.userRole,
                                            )
                                          : AppointmentsMainScreen(
                                              userInformation: ref.read(
                                                  userInformationProvider),
                                              ownerFirmCui:
                                                  widget.ownerCui.toString(),
                                              ownerFirmName: ref
                                                  .read(
                                                      firmsInformationProvider)
                                                  .firmName,
                                              firebaseFirestore:
                                                  widget.firebaseFirestore,
                                              userRole: widget.userRole,
                                            );
                                    }),
                                  );
                                }
                              },
                              child: _isLoading
                                  ? const Center(
                                      child: CircularProgressIndicator(),
                                    )
                                  : const Text('Da')),
                          TextButton(
                            onPressed: () {
                              _isDelete = false;
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            child: const Text('Nu'),
                          ),
                        ],
                      ),
              ],
            );
          });
    }
  }

  void _verifyTransactionSign() async {
    if (widget.transactionModel?.transactionSign == null) {
      setState(() {
        _transactionSign = '';
      });
    }

    if (widget.transactionModel?.transactionSign == '+' ||
        widget.collection == 'appointments') {
      setState(() {
        _transactionSign = '+';
        _tranzTitle = 'programarea';
      });
    }
    if (widget.collection == 'transactions') {
      setState(() {
        _tranzTitle = 'tranzactia';
      });
    }
    if (widget.transactionModel?.transactionSign == '-') {
      setState(() {
        _transactionSign = '-';
      });
    }
  }

  Future<bool> _verifyDataForSaving(String collection, bool isView) async {
    _isLoading = true;

    if (_clientName == '' || _clientName == null) {
      setState(() {
        errorMessage = 'Introdu un client valid';
        clientsLabel = true;
      });
      _isLoading = false;
      return false;
    }
    if (_serviceName == '' || _serviceName == null) {
      setState(() {
        errorMessage = 'Alege un serviciu valid';
        servicesLabel = true;
      });
      _isLoading = false;
      return false;
    }
    bool validation = _appWidgetFormKey.currentState!.validate();
    if (!validation) {
      _isLoading = false;
      return false;
    }
    _appWidgetFormKey.currentState!.save();

    if (_price!.isNaN || _price!.isNegative) {
      setState(() {
        errorMessage = 'Introdu pretul serviciului';
      });
      _isLoading = false;
      return false;
    }

    if (_transactionSign == '') {
      setState(() {
        errorMessage = 'Alege tipul tranzactiei';
        _isLoading = false;
      });
      return false;
    }
    if (widget.isView) {
      ref.read(appointmentProvider.notifier).editTransactionEntry(
            collection: collection,
            firebaseFirestore: ref.read(firebaseFirestore),
            docID: widget.docID,
            transactionModel: TransactionModel(
                partnerName: _clientName!,
                serviceProductName: _serviceName!,
                price: _price!,
                dateTime: _dateTime!,
                transactionSign: _transactionSign!,
                cui: widget.ownerCui,
                userEmail: ref.read(userInformationProvider).loggedUser,
                observations: _observations,
                telNo: _partnerTelNo!,
                isTransaction: _isTransaction),
          );
    } else {
      ref.read(appointmentProvider.notifier).saveTransactionEntry(
          TransactionModel(
              partnerName: _clientName!,
              serviceProductName: _serviceName!,
              price: _price!,
              dateTime: _dateTime!,
              transactionSign: _transactionSign!,
              cui: widget.ownerCui,
              userEmail: ref.read(userInformationProvider).loggedUser,
              observations: _observations,
              telNo: _partnerTelNo!,
              isTransaction: _isTransaction),
          ref.read(firebaseFirestore),
          collection);
    }

    if (_phoneContacts) {
      ref.read(addressBookProvider.notifier).addClientInClientsList(
            collection: _collection,
            name: _clientName!,
            telNo: _partnerTelNo!.replaceAll(RegExp(r'\D+'), ''),
            isJuridic: false,
            address: '',
            cui: '',
            isTVAPayer: false,
            ownerFirm: widget.ownerCui,
            firebaseAuth: ref.read(firebaseAuth),
            firebaseFirestore: ref.read(firebaseFirestore),
          );
    }
    _isLoading = false;
    return true;
  }

  Future<bool> _openBottomSheet({
    required GlobalKey<FormState> formKey,
    required double screenWidth,
    required bool isCreate,
    required bool isCreateListTile,
    required int index,
    required String name,
    required String telNo,
    required String address,
    required bool isJuridic,
    required String cui,
    required bool isTVA,
    required List firmsList,
    required ownerFirm,
    required String collection,
  }) async {
    var isCompleted = await showModalBottomSheet(
        isScrollControlled: screenWidth < 600 ? false : true,
        context: context,
        builder: (ctx) {
          ref.read(addressBookProvider.notifier).resetErrorMessage();
          return AddAddressBook(
            formKey: formKey,
            isCreate: isCreate,
            isCreateListTile: isCreateListTile,
            index: index,
            name: name,
            telNo: telNo,
            address: address,
            isJuridic: isJuridic,
            cui: cui,
            isTVA: isTVA,
            firmsList: firmsList,
            collection: collection,
            ownerFirm: ownerFirm,
            createListTile: _createListTile,
            userRole: widget.userRole,
          );
        });
    return isCompleted;
  }

  void _createListTile(
    String? collection,
  ) {
    if (collection != 'services') {
      setState(() {
        _clientName = ref.read(addressBookProvider.notifier).clientModel.name;
        _partnerTelNo =
            ref.read(addressBookProvider.notifier).clientModel.telNo;
        _partenerCui = ref.read(addressBookProvider.notifier).clientModel.cui!;
        _partnerAddress =
            ref.read(addressBookProvider.notifier).clientModel.address!;
        _isPartnerJuridicPerson =
            ref.read(addressBookProvider.notifier).clientModel.isJuridic!;
      });
    } else {
      setState(() {
        _serviceName = ref.read(addressBookProvider.notifier).serviceModel.name;
      });
    }
  }

  _sendInWhatsApp(String phoneNumber, String message) async {
    final encodedPhoneNumber = Uri.encodeFull(phoneNumber);
    String url = 'whatsapp://send?phone=$encodedPhoneNumber&text=$message';

    if (await canLaunchUrl(Uri.parse(url))) {
      return launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    await launchUrl(launchUri);
  }

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
                Navigator.of(context).pop();
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
    _verifyTransactionSign();
    _checkInternetConnection();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _nameController.dispose();
    _serviceController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double contactsSearchHeight = 0;
    double servicesSearchHeight = 0;
    if (_filteredClients.length > 5) {
      contactsSearchHeight = 270;
    } else {
      contactsSearchHeight = _filteredClients.length * 70;
    }
    if (_filteredServices.length > 5) {
      servicesSearchHeight = 170;
    } else {
      servicesSearchHeight = _filteredServices.length * 70;
    }
    final iconColor = Theme.of(context).colorScheme.primary;
    var screenWidth = MediaQuery.sizeOf(context).width;

    // bool isHuaweiDevice = Platform.environment.

    return Scaffold(
      appBar: AppBar(
        title: widget.isView
            ? (_isEdit
                ? Text(
                    'Editeaza $_tranzTitle',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  )
                : Text(
                    'Vizualizeaza $_tranzTitle',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ))
            : Text(
                'Adauga $_tranzTitle',
                maxLines: 2,
                textAlign: TextAlign.center,
              ),
        centerTitle: true,
        actions: widget.isView
            ? [
                PopupMenuButton(
                  onSelected: (value) {
                    _deleteItem();
                  },
                  itemBuilder: (item) {
                    return [
                      PopupMenuItem(
                        value: _isEdit,
                        onTap: () {
                          setState(() {
                            _isEdit = !_isEdit;
                          });
                        },
                        child: Text(
                          'Editeaza',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      PopupMenuItem(
                        value: _isDelete,
                        onTap: () {
                          setState(() {
                            _isDelete = true;
                          });
                        },
                        child: Text(
                          'Sterge',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      if (widget.collection == 'appointments')
                        PopupMenuItem(
                          onTap: () async {
                            var firmData = await widget.firebaseFirestore
                                .collection('firme')
                                .doc(widget.ownerCui)
                                .get();
                            String initialMessage =
                                firmData.data()!['notification_message'];
                            String date = DateFormat('dd/MM/yyyy HH:mm')
                                .format(_dateTime!);
                            String finalMessage = initialMessage
                                .replaceAll('<data>', date)
                                .replaceAll('<serviciu>', _serviceName!);
                            // String mapsLocation =
                            //     'https://goo.gl/maps/sxDsug2rGyXBSJH88';
                            // String notificationMessage =
                            //     'Buna ziua. Va asteptam in data de ${DateFormat('dd/MM/yyyy HH:mm').format(_dateTime!)} pentru sedinta de $_serviceName la salonul JustForYou - Esthetic Center.\n$mapsLocation';
                            _sendInWhatsApp(
                                '+4${_partnerTelNo!}', finalMessage);
                          },
                          child: Text(
                            'Notifica',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary),
                          ),
                        )
                    ];
                  },
                )
              ]
            : null,
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: widget.collection == 'appointments' && widget.isView
                    ? GestureDetector(
                        onTap: _isTransaction
                            ? null
                            : () async {
                                setState(() {
                                  _isTransaction = true;
                                  _isLoading = true;
                                });
                                ref
                                    .read(appointmentProvider.notifier)
                                    .collectAppointment(
                                      docID: widget.docID,
                                      firebaseFirestore:
                                          widget.firebaseFirestore,
                                      transactionModel: TransactionModel(
                                          partnerName: widget
                                              .transactionModel!.partnerName,
                                          serviceProductName: widget
                                              .transactionModel!
                                              .serviceProductName,
                                          price: widget.transactionModel!.price,
                                          dateTime:
                                              widget.transactionModel!.dateTime,
                                          transactionSign: widget
                                              .transactionModel!
                                              .transactionSign,
                                          cui: widget.transactionModel!.cui,
                                          userEmail: widget
                                              .transactionModel!.userEmail,
                                          observations: widget
                                              .transactionModel!.observations,
                                          telNo: widget.transactionModel!.telNo,
                                          isTransaction: true),
                                    );
                                setState(() {
                                  _isLoading = false;
                                });
                              },
                        child: Container(
                          color: _isTransaction == true
                              ? Colors.green.withOpacity(0.5)
                              : Theme.of(context)
                                  .colorScheme
                                  .inversePrimary
                                  .withOpacity(0.5),
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            _isTransaction == true ? 'Incasat' : 'Incaseaza',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: _isTransaction == true
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: _isEdit || !widget.isView
                            ? () {
                                setState(() {
                                  _transactionSign = '+';
                                  errorMessage = '';
                                });
                              }
                            : null,
                        child: Container(
                          color: _transactionSign == '+'
                              ? Theme.of(context)
                                  .colorScheme
                                  .inversePrimary
                                  .withOpacity(0.5)
                              : null,
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'Incasare',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: _transactionSign == '+'
                                  ? FontWeight.bold
                                  : null,
                            ),
                          ),
                        ),
                      ),
              ),
              if (widget.collection == 'transactions')
                Expanded(
                  child: GestureDetector(
                    onTap: _isEdit || !widget.isView
                        ? () {
                            setState(() {
                              _transactionSign = '-';
                              errorMessage = '';
                            });
                          }
                        : null,
                    child: Container(
                      color: _transactionSign == '-'
                          ? Theme.of(context)
                              .colorScheme
                              .inversePrimary
                              .withOpacity(0.5)
                          : null,
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Cheltuiala',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight:
                              _transactionSign == '-' ? FontWeight.bold : null,
                        ),
                      ),
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: SingleChildScrollView(
                child: Form(
                  key: _appWidgetFormKey,
                  child: Column(
                    children: [
                      if (_clientName == '' && !_isEditPartner ||
                          _clientName == null && !_isEditPartner)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: TextFormField(
                            controller: _nameController,
                            onChanged: (value) {
                              if (!_phoneContacts) {
                                _filterClients(value, _storedClients!);
                              } else {
                                _filterClients(value, _phoneContactsList);
                              }
                            },
                            decoration: InputDecoration(
                                labelText: !_phoneContacts
                                    ? (widget.collection == 'transactions'
                                        ? 'Lista parteneri'
                                        : 'Lista clienti')
                                    : 'Agenda telefonului',
                                labelStyle: clientsLabel
                                    ? const TextStyle(color: Colors.red)
                                    : null,
                                hintText: !_phoneContacts
                                    ? 'Cauta in lista de clienti din applicatie...'
                                    : 'Cauta in agenda telefonului...',
                                suffixIcon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        _nameController.clear();
                                      },
                                      icon: Icon(
                                        Icons.clear,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        setState(() {
                                          _nameController.clear();
                                        });

                                        bool isCompleted =
                                            await _openBottomSheet(
                                                formKey: _formKeyAddAddressBook,
                                                screenWidth: screenWidth,
                                                isCreateListTile: true,
                                                isCreate: true,
                                                index: 0,
                                                name: '',
                                                telNo: '',
                                                address: '',
                                                isJuridic: false,
                                                cui: '',
                                                isTVA: false,
                                                firmsList: [],
                                                ownerFirm: ref
                                                    .read(
                                                        firmsInformationProvider)
                                                    .cui,
                                                collection: 'clients');
                                        setState(() {
                                          _isLoading = !isCompleted;
                                        });
                                      },
                                      icon: Icon(
                                        Icons.person_add,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    ),
                                  ],
                                ),
                                prefixIcon: _isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(),
                                      )
                                    : Column(
                                        children: [
                                          Transform.scale(
                                            scale: 0.6,
                                            child: Switch(
                                              value: _phoneContacts,
                                              onChanged: (value) {
                                                setState(() {
                                                  _phoneContacts = value;
                                                  if (value) {
                                                    // _getPhoneContact();
                                                    _pickPhoneContacts();
                                                  } else {
                                                    _filteredClients =
                                                        _phoneContactsList;
                                                  }

                                                  _nameController.clear();
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      )),
                          ),
                        ),
                      if (!_isEditPartner)
                        Visibility(
                          visible: _nameController.text.isNotEmpty,
                          child: SizedBox(
                            height: contactsSearchHeight,
                            width: double.infinity,
                            child: ListView.builder(
                              shrinkWrap: _filteredClients.length < 5
                                  ? true
                                  : false, // Ensure the ListView occupies only the necessary space
                              physics: _filteredClients.length < 5
                                  ? const NeverScrollableScrollPhysics()
                                  : null,
                              itemBuilder: (ctx, index) {
                                return Row(
                                  children: [
                                    Expanded(
                                      child: ListTile(
                                        onTap: () {
                                          setState(() {
                                            _clientName =
                                                _filteredClients[index].name;
                                            _partnerTelNo =
                                                _filteredClients[index].telNo;
                                            _isPartnerJuridicPerson =
                                                _filteredClients[index]
                                                        .isJuridic ??
                                                    false;
                                            _partnerAddress =
                                                _filteredClients[index]
                                                        .address ??
                                                    '';
                                            _partenerCui =
                                                _filteredClients[index].cui ??
                                                    '';
                                            _isPartnerTVAPayer =
                                                _filteredClients[index]
                                                        .isTVAPayer ??
                                                    false;
                                            _nameController.clear();
                                            errorMessage = '';
                                            clientsLabel = false;
                                          });
                                        },
                                        minVerticalPadding: 0,
                                        leading: Icon(
                                          Icons.person,
                                          color: iconColor,
                                        ),
                                        title:
                                            Text(_filteredClients[index].name),
                                        subtitle: Text(!_filteredClients[index]
                                                .isJuridic!
                                            ? _filteredClients[index].telNo
                                            : '${_filteredClients[index].address} - CUI: ${_filteredClients[index].cui}'),
                                      ),
                                    ),
                                  ],
                                );
                              },
                              itemCount: _filteredClients.length,
                            ),
                          ),
                        ),
                      if (_clientName != '' && _clientName != null)
                        Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Nume client'),
                            ),
                            ListTile(
                              tileColor:
                                  const Color.fromRGBO(240, 223, 242, 155),
                              onTap: widget.isView && !_isEdit
                                  ? () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PartnerHistoryScreen(
                                            firebaseFirestore:
                                                widget.firebaseFirestore,
                                            collection: widget.collection,
                                            transactionModel:
                                                widget.transactionModel
                                                    as TransactionModel,
                                            isClientHistory: true,
                                            // isCollected: widget.isTransaction,
                                            userRole:
                                                widget.userRole.toString(),
                                            ownerCui: widget.ownerCui,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              title: Text(_clientName.toString()),
                              subtitle: Text(!_isPartnerJuridicPerson
                                  ? _partnerTelNo.toString()
                                  : '$_partnerAddress - $_partenerCui'),
                              trailing: _isEdit || !widget.isView
                                  ? IconButton(
                                      onPressed: () {
                                        if (!_isEditPartner) {
                                          setState(() {
                                            _clientName = '';
                                          });
                                        } else {
                                          setState(() {
                                            _isEditPartner = false;
                                            _clientName = '';
                                          });
                                        }
                                        _nameController.clear();
                                      },
                                      icon: Icon(
                                        Icons.close,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () async {
                                            await _sendInWhatsApp(
                                                '+4${_partnerTelNo!}', '');
                                          },
                                          icon: FaIcon(
                                            FontAwesomeIcons.whatsapp,
                                            color:
                                                Colors.green.withOpacity(0.7),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            _makePhoneCall(_partnerTelNo!);
                                          },
                                          icon: FaIcon(
                                            Icons.phone_in_talk,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ],
                        ),
                      if (_serviceName == '' && !_isEditService ||
                          _serviceName == null && !_isEditService)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: TextFormField(
                            controller: _serviceController,
                            onChanged: (value) {
                              _filterServices(value);
                            },
                            decoration: InputDecoration(
                              label: const Text('Lista servicii'),
                              labelStyle: servicesLabel
                                  ? const TextStyle(color: Colors.red)
                                  : null,
                              hintText: 'Cauta in lista de servicii...',
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      _serviceController.clear();
                                    },
                                    icon: Icon(
                                      Icons.clear,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  if (ref
                                              .read(firmsInformationProvider
                                                  .notifier)
                                              .getUserRole(
                                                ref
                                                    .read(
                                                        userInformationProvider)
                                                    .loggedUser,
                                                ref.read(
                                                    firmsInformationProvider),
                                              ) ==
                                          'Admin' ||
                                      ref
                                              .read(firmsInformationProvider
                                                  .notifier)
                                              .getUserRole(
                                                ref
                                                    .read(
                                                        userInformationProvider)
                                                    .loggedUser,
                                                ref.read(
                                                    firmsInformationProvider),
                                              ) ==
                                          'Manager')
                                    IconButton(
                                      onPressed: () async {
                                        setState(() {
                                          _serviceController.clear();
                                        });
                                        bool isCompleted =
                                            await _openBottomSheet(
                                                formKey: _formKeyAddAddressBook,
                                                screenWidth: screenWidth,
                                                isCreate: true,
                                                isCreateListTile: true,
                                                index: 0,
                                                name: _clientName.toString(),
                                                telNo: _partnerTelNo.toString(),
                                                address: _partnerAddress,
                                                isJuridic:
                                                    _isPartnerJuridicPerson,
                                                cui: _partenerCui,
                                                isTVA: _isPartnerTVAPayer,
                                                firmsList: [],
                                                ownerFirm: ref
                                                    .read(
                                                        firmsInformationProvider)
                                                    .cui,
                                                collection: 'services');
                                        setState(() {
                                          _isLoading = !isCompleted;
                                        });
                                      },
                                      icon: Icon(
                                        Icons.playlist_add,
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
                      if (!_isEditService)
                        Visibility(
                          visible: _serviceController.text.isNotEmpty,
                          child: SizedBox(
                            height: servicesSearchHeight,
                            width: double.infinity,
                            child: ListView.builder(
                              itemBuilder: (ctx, index) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: ListTile(
                                    onTap: () {
                                      setState(() {
                                        _serviceName =
                                            _filteredServices[index].name;
                                        _serviceController.clear();
                                        errorMessage = '';
                                        servicesLabel = false;
                                      });
                                    },
                                    // leading: const Icon(Icons.spa),
                                    leading: FaIcon(
                                      FontAwesomeIcons.rightLong,
                                      color: iconColor,
                                    ),
                                    title: Text(_filteredServices[index].name),
                                  ),
                                );
                              },
                              itemCount: _filteredServices.length,
                            ),
                          ),
                        ),
                      if (_serviceName != '' && _serviceName != null)
                        Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text('Numele serviciului efectuat'),
                            ),
                            ListTile(
                              tileColor:
                                  const Color.fromRGBO(240, 223, 242, 155),
                              onTap: widget.isView && !_isEdit
                                  ? () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              PartnerHistoryScreen(
                                            firebaseFirestore:
                                                widget.firebaseFirestore,
                                            collection: widget.collection,
                                            transactionModel:
                                                widget.transactionModel
                                                    as TransactionModel,
                                            isClientHistory: false,
                                            // isCollected: widget.isTransaction,
                                            ownerCui: widget.ownerCui,
                                            userRole: widget.userRole,
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                              title: Text(_serviceName.toString()),
                              trailing: _isEdit || !widget.isView
                                  ? IconButton(
                                      onPressed: () {
                                        if (!_isEditService) {
                                          setState(() {
                                            _serviceName = '';
                                          });
                                        } else {
                                          setState(() {
                                            _isEditService = false;
                                            _serviceName = '';
                                          });
                                        }
                                        _serviceController.clear();
                                      },
                                      icon: Icon(
                                        Icons.clear,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                    )
                                  : null,
                            )
                          ],
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 100,
                              child: TextFormField(
                                enabled: _isEdit || !widget.isView,
                                initialValue: widget.isView
                                    ? _price?.toStringAsFixed(2)
                                    : null,
                                decoration: const InputDecoration(
                                  label: Text('Pret'),
                                  suffix: Text(' Lei'),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null ||
                                      value.isEmpty ||
                                      double.parse(value) < 0) {
                                    return 'Introdu o valoare corecta';
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  _price = double.parse(value!);
                                },
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _isEdit || !widget.isView
                                  ? _showDateTimePicker
                                  : null,
                              icon: const Icon(Icons.calendar_month),
                              label: Text(
                                DateFormat('dd/MM/yyyy HH:mm')
                                    .format(_dateTime!),
                              ),
                              style: dateLabel
                                  ? ButtonStyle(
                                      foregroundColor:
                                          MaterialStateColor.resolveWith(
                                              (states) => Colors.red),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        errorMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: TextFormField(
                          enabled: _isEdit || !widget.isView,
                          initialValue: widget.isView ? _observations : null,
                          minLines: 6,
                          maxLines: null,
                          decoration: InputDecoration(
                            label: const Text('Observatii'),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide(width: 1),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(10),
                              ),
                              borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2),
                            ),
                          ),
                          onSaved: (value) {
                            _observations = value!;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (!_isLoading && _isEdit || !_isLoading && !widget.isView)
            BottomLargeButton(
                buttonName: widget.isView
                    ? 'Editeaza $_tranzTitle'
                    : 'Adauga $_tranzTitle',
                myIcon: const Icon(Icons.calendar_month_sharp),
                onTapFunction: () async {
                  bool isCompleted = await _verifyDataForSaving(
                      widget.collection, widget.isView);
                  if (isCompleted && context.mounted) {
                    Navigator.of(context).pop();
                  } else {
                    return;
                  }
                }),
        ],
      ),
    );
  }
}
