import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sunrise_app/models/client_model.dart';
import 'package:sunrise_app/models/service_model.dart';
import 'package:sunrise_app/providers/address_book_provider.dart';
import 'package:sunrise_app/providers/firms_information_provider.dart';
import 'package:sunrise_app/providers/user_information_provider.dart';
import 'package:sunrise_app/widgets/add_address_book_widget.dart';
import 'package:sunrise_app/widgets/delete_book_entry_widget.dart';
import '../widgets/buttom_button_large.dart';

class AddressBookScreen extends ConsumerStatefulWidget {
  const AddressBookScreen(
      {required this.firebaseFirestore,
      required this.managedFirmsList,
      Key? key})
      : super(key: key);

  final FirebaseFirestore firebaseFirestore;
  final List<dynamic> managedFirmsList;

  @override
  ConsumerState<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends ConsumerState<AddressBookScreen> {
  final _formKey = GlobalKey<FormState>();
  late List<dynamic> _userFirms;
  late bool _isViewListOfClients = false;
  final List<String> _listOfButtons = ['Agenda', 'Servicii'];
  late String _selectedButton = '';
  late String _collection = '';
  late List<dynamic> _listOfDisplayedItems = [];
  late FaIcon _selectedIcon = const FaIcon(FontAwesomeIcons.person);
  late bool _hasTelNo = false;
  late String _name = '';
  late String _telNo = '';
  late bool _isJuridicPerson = false;
  late String _cui = '';
  late bool _isTVA = false;
  final String _address = '';
  late String _ownerFirm = '';
  // late bool _isLoading = false;
  late List<dynamic> _filterredList = [];
  late List<dynamic> _initialList = [];
  late bool _isSearch = false;
  late String _userRole = '';

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
    required bool hasTelNo,
    required ownerFirm,
  }) async {
    bool isCompleted = await showModalBottomSheet(
        isScrollControlled: screenWidth < 600 ? false : true,
        context: context,
        builder: (ctx) {
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
            collection: _collection,
            ownerFirm: ownerFirm,
            createListTile: (collection) {},
            userRole: _userRole,
          );
        });
    return isCompleted;
  }

  Future<bool> _openDeleteMessage(
      int index, List<dynamic> contactsID, List<dynamic> servicesID) async {
    bool isCompletedDialog = await showDialog(
        context: (context),
        builder: (ctx) {
          return DeleteBookEntryAlertDialog(
            collection: _collection,
            index: index,
            contactsID: contactsID,
            servicesID: servicesID,
            listOfDisplayedItems: _listOfDisplayedItems,
          );
        });
    return isCompletedDialog;
  }

  void _filterList(String searchText, List<dynamic> initialList) {
    setState(() {
      _filterredList = initialList
          .where((entry) =>
              entry.name.toLowerCase().contains(searchText.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    _userFirms = ref.read(userInformationProvider).userFirms;

    final iconColor = Theme.of(context).colorScheme.primary;
    var screenWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      appBar: AppBar(
        title: !_isViewListOfClients
            ? const Text('Alege o firma')
            : const Text('Selecteaza pentru editare'),
        centerTitle: true,
        actions: [
          if (_isViewListOfClients)
            IconButton(
              onPressed: () {
                setState(() {
                  _isViewListOfClients = false;
                });
              },
              icon: const FaIcon(
                FontAwesomeIcons.backward,
              ),
            )
        ],
      ),
      body: !_isViewListOfClients
          ? ListView.builder(
              itemBuilder: (ctx, index) {
                return ListTile(
                  onTap: () async {
                    await ref
                        .read(firmsInformationProvider.notifier)
                        .getCloudFirmInformation(
                          widget.managedFirmsList[index][0]['CUI'],
                          ref.read(userInformationProvider),
                          ref.read(firebaseFirestore),
                        );
                    setState(() {
                      _ownerFirm = widget.managedFirmsList[index][0]['CUI'];
                      _isViewListOfClients = true;
                      _userRole = ref
                          .read(firmsInformationProvider.notifier)
                          .getUserRole(
                            ref.read(userInformationProvider).loggedUser,
                            ref.read(firmsInformationProvider),
                          );
                    });
                  },
                  leading: FaIcon(
                    FontAwesomeIcons.solidAddressBook,
                    color: iconColor,
                  ),
                  title: Text(widget.managedFirmsList[index][0]['firm_name']),
                  subtitle: Text(widget.managedFirmsList[index][1]
                      .toString()
                      .toUpperCase()),
                );
              },
              itemCount: widget.managedFirmsList.length,
            )
          : Column(
              children: [
                Row(
                  children: _listOfButtons.map((element) {
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedButton = element;
                            _isSearch = false;
                            _filterredList = _listOfDisplayedItems;
                          });
                          if (element == 'Agenda') {
                            setState(() {
                              _collection = 'clients';
                              _hasTelNo = true;

                              _selectedIcon = FaIcon(
                                FontAwesomeIcons.personCirclePlus,
                                color: iconColor,
                              );
                            });
                          }
                          if (element == 'Servicii') {
                            setState(() {
                              _collection = 'services';
                              _hasTelNo = false;
                              _selectedIcon = FaIcon(
                                FontAwesomeIcons.userGear,
                                color: iconColor,
                              );
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: _selectedButton == element
                                  ? Theme.of(context)
                                      .colorScheme
                                      .inversePrimary
                                      .withOpacity(0.5)
                                  : null),
                          child: Text(
                            element,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontWeight: _selectedButton == element
                                    ? FontWeight.bold
                                    : null),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_collection != '')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: _isSearch
                        ? TextFormField(
                            onChanged: (value) {
                              _filterList(value, _initialList);
                            },
                            decoration: InputDecoration(
                              label: const Text('Cauta'),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isSearch = false;
                                    _filterredList = _listOfDisplayedItems;
                                  });
                                },
                                icon: Icon(
                                  Icons.clear,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              const Text('Cauta'),
                              IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _isSearch = true;
                                      _filterredList =
                                          _initialList = _listOfDisplayedItems;
                                    });
                                  },
                                  icon: Icon(
                                    Icons.search,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ))
                            ],
                          ),
                  ),

                ///de aici
                Expanded(
                  child: _collection != ''
                      ? FutureBuilder(
                          future: ref
                              .read(addressBookProvider.notifier)
                              .getCloudData(
                                _collection,
                                ref.read(userInformationProvider).userFirms,
                                ref.read(firebaseFirestore),
                              ),
                          builder: (BuildContext context,
                              AsyncSnapshot<dynamic> snapshot) {
                            if (!snapshot.hasData || snapshot.data == null) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            var myTempList = [];
                            var myData = snapshot.data;
                            List<dynamic> contactsID = [];
                            List<dynamic> servicesID = [];
                            return ListView.builder(
                                itemCount: _isSearch
                                    ? _filterredList.length
                                    : myData.length,
                                itemBuilder: (ctx, index) {
                                  try {
                                    if (_collection != 'services') {
                                      contactsID = ref
                                          .read(addressBookProvider.notifier)
                                          .cloudContactsIdList;
                                      myTempList.add(
                                        ClientModel(
                                          name: myData[index].name,
                                          telNo: myData[index].telNo,
                                          loggedUserEmail: ref
                                              .read(userInformationProvider)
                                              .loggedUser,
                                          ownerFirm: myData[index].ownerFirm,
                                          address: myData[index].address,
                                          isJuridic: myData[index].isJuridic,
                                          cui: myData[index].cui,
                                          isTVAPayer: myData[index].isTVAPayer,
                                        ),
                                      );
                                    } else if (_collection == 'services') {
                                      servicesID = ref
                                          .read(addressBookProvider.notifier)
                                          .cloudServicesIdList;
                                      myTempList.add(
                                        ServiceModel(
                                          name: myData[index].name,
                                          loggedUserEmail: ref
                                              .read(userInformationProvider)
                                              .loggedUser,
                                          ownerFirm: myData[index].ownerFirm,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }
                                  if (_isSearch) {
                                    _listOfDisplayedItems = _filterredList;
                                  } else {
                                    _listOfDisplayedItems = myTempList;
                                  }

                                  return ListTile(
                                    onTap: () async {
                                      var isCompleted = await _openBottomSheet(
                                        formKey: _formKey,
                                        isCreate: false,
                                        isCreateListTile: false,
                                        screenWidth: screenWidth,
                                        firmsList: _listOfDisplayedItems,
                                        index: index,
                                        name: _listOfDisplayedItems[index].name,
                                        telNo: _collection == 'services'
                                            ? ''
                                            : _listOfDisplayedItems[index]
                                                .telNo,
                                        isJuridic: _collection == 'services'
                                            ? false
                                            : _listOfDisplayedItems[index]
                                                .isJuridic,
                                        cui: _collection == 'services'
                                            ? ''
                                            : _listOfDisplayedItems[index].cui,
                                        isTVA: _collection == 'services'
                                            ? false
                                            : _listOfDisplayedItems[index]
                                                .isTVAPayer,
                                        address: _collection == 'services'
                                            ? ''
                                            : _listOfDisplayedItems[index]
                                                .address,
                                        hasTelNo: _hasTelNo,
                                        ownerFirm: _ownerFirm,
                                      );

                                      setState(() {
                                        _isViewListOfClients = isCompleted;
                                      });
                                    },
                                    leading: _selectedIcon,
                                    title:
                                        Text(_listOfDisplayedItems[index].name),
                                    subtitle: _hasTelNo
                                        ? Text(_listOfDisplayedItems[index]
                                                .isJuridic
                                            ? '${_listOfDisplayedItems[index].address} - CUI: ${_listOfDisplayedItems[index].cui}'
                                            : _listOfDisplayedItems[index]
                                                .telNo)
                                        : const Text(''),
                                    trailing: IconButton(
                                      onPressed: () async {
                                        var currentItem =
                                            _listOfDisplayedItems[index];
                                        await _openDeleteMessage(
                                            index, contactsID, servicesID);

                                        if (_collection == 'clients') {
                                          setState(() {
                                            _listOfDisplayedItems = ref
                                                .read(addressBookProvider
                                                    .notifier)
                                                .cloudAddressBook;
                                          });
                                        } else {
                                          setState(() {
                                            _listOfDisplayedItems = ref
                                                .read(addressBookProvider
                                                    .notifier)
                                                .cloudServicesBook;
                                          });
                                        }

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(_collection == 'clients'
                                                      ? 'Client sters'
                                                      : 'Serviciu sters'),
                                                  TextButton.icon(
                                                    onPressed: () async {
                                                      List currentIDList = [];

                                                      if (_collection ==
                                                          'clients') {
                                                        currentIDList =
                                                            contactsID;
                                                        await widget
                                                            .firebaseFirestore
                                                            .collection(
                                                                _collection)
                                                            .doc(currentIDList[
                                                                index])
                                                            .set({
                                                          'name':
                                                              currentItem.name,
                                                          'tel_number':
                                                              currentItem.telNo,
                                                          'logged_user':
                                                              currentItem
                                                                  .loggedUserEmail,
                                                          'is_juridic_person':
                                                              currentItem
                                                                  .isJuridic,
                                                          'address': currentItem
                                                              .address,
                                                          'cui':
                                                              currentItem.cui,
                                                          'is_tva_payer':
                                                              currentItem
                                                                  .isTVAPayer,
                                                          'owner_firm':
                                                              currentItem
                                                                  .ownerFirm,
                                                        });
                                                      } else {
                                                        currentIDList =
                                                            servicesID;
                                                        await widget
                                                            .firebaseFirestore
                                                            .collection(
                                                                _collection)
                                                            .doc(currentIDList[
                                                                index])
                                                            .set({
                                                          'name':
                                                              currentItem.name,
                                                          'logged_user':
                                                              currentItem
                                                                  .loggedUserEmail,
                                                          'owner_firm':
                                                              currentItem
                                                                  .ownerFirm,
                                                        });
                                                      }

                                                      setState(() {
                                                        _listOfDisplayedItems
                                                            .insert(index,
                                                                currentItem);
                                                      });
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .hideCurrentSnackBar();
                                                      }
                                                    },
                                                    icon:
                                                        const Icon(Icons.undo),
                                                    label:
                                                        const Text('Anulare'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      icon: Icon(
                                        Icons.delete,
                                        color: iconColor,
                                      ),
                                    ),
                                  );
                                });
                          },
                        )
                      : const Text(''),
                ),
                if (_collection != '')
                  BottomLargeButton(
                    buttonName: 'Adauga',
                    myIcon: const Icon(Icons.add_circle_outline_outlined),
                    onTapFunction: () async {
                      setState(() {
                        _isJuridicPerson = false;
                        _cui = '';
                        _isTVA = false;
                        _name = '';
                        _telNo = '';
                      });
                      var isCompleted = await _openBottomSheet(
                        formKey: _formKey,
                        isCreate: true,
                        isCreateListTile: false,
                        screenWidth: screenWidth,
                        firmsList: _listOfDisplayedItems.isEmpty
                            ? _userFirms
                            : _listOfDisplayedItems,
                        index: 0,
                        name: _name,
                        telNo: _telNo,
                        isJuridic: _isJuridicPerson,
                        cui: _cui,
                        isTVA: _isTVA,
                        address: _address,
                        hasTelNo: _hasTelNo,
                        ownerFirm: _ownerFirm,
                      );
                      setState(() {
                        _isViewListOfClients = isCompleted;
                      });
                    },
                  )
              ],
            ),
    );
  }
}
