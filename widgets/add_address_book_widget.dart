import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunrise_app/models/transaction_model.dart';
import 'package:sunrise_app/providers/address_book_provider.dart';
import 'package:sunrise_app/providers/user_information_provider.dart';
import 'package:flutter/services.dart';
import 'package:sunrise_app/screens/partner_history_screen.dart';

class AddAddressBook extends ConsumerStatefulWidget {
  const AddAddressBook({
    Key? key,
    required this.formKey,
    required this.isCreate,
    required this.isCreateListTile,
    required this.index,
    required this.name,
    required this.telNo,
    required this.address,
    required this.isJuridic,
    required this.cui,
    required this.isTVA,
    required this.firmsList,
    required this.collection,
    required this.ownerFirm,
    required this.createListTile,
    required this.userRole,
  }) : super(key: key);

  final GlobalKey<FormState> formKey;
  final bool isCreate;
  final bool isCreateListTile;
  final int index;
  final String name;
  final String telNo;
  final String address;
  final bool isJuridic;
  final String cui;
  final bool isTVA;
  final List firmsList;
  final String collection;
  final String ownerFirm;
  final void Function(
    String? collection,
  ) createListTile;
  final String userRole;

  @override
  ConsumerState<AddAddressBook> createState() => _AddAddressBookState();
}

class _AddAddressBookState extends ConsumerState<AddAddressBook> {
  late String _name = widget.name;
  late String _telNo = widget.telNo;
  late bool _isJuridic = widget.isJuridic;
  late String _address = widget.address;
  late String _cui = widget.cui;
  late bool _isTVA = widget.isTVA;
  late bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: widget.formKey,
        child: ListView(
          children: [
            TextFormField(
              onSaved: (value) {
                setState(() {
                  _name = value!;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty || value.length < 4) {
                  return 'Introdu un nume corect';
                }
                return null;
              },
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                label: Text('Name'),
              ),
              initialValue:
                  widget.isCreate ? '' : widget.firmsList[widget.index].name,
            ),
            if (widget.collection != 'services')
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onLongPress: () {
                        Clipboard.setData(
                          ClipboardData(text: _telNo),
                        );
                      },
                      child: TextFormField(
                        enabled: widget.isCreate ? true : false,
                        onSaved: (value) {
                          setState(() {
                            _telNo = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value.length < 10) {
                            return 'Introdu un nr de tel corect';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          label: Text('Numarul de telefon'),
                        ),
                        initialValue: widget.isCreate
                            ? ''
                            : widget.firmsList[widget.index].telNo,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: widget.isCreate
                        ? () {
                            setState(() {
                              _isJuridic = !_isJuridic;
                            });
                          }
                        : null,
                    icon: Icon(
                      _isJuridic
                          ? Icons.check_box_outlined
                          : Icons.check_box_outline_blank,
                    ),
                    label: const Text('Persoana\njuridica?'),
                  ),
                ],
              ),
            if (widget.collection != 'services')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isJuridic)
                    GestureDetector(
                      onLongPress: () {
                        Clipboard.setData(
                          ClipboardData(text: _cui),
                        );
                      },
                      child: TextFormField(
                        enabled: widget.isCreate ? true : false,
                        onSaved: (value) {
                          setState(() {
                            _cui = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null ||
                              value.isEmpty ||
                              value.length < 5) {
                            return 'Introdu un CUI valid';
                          }
                          return null;
                        },
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          label: Text('CUI'),
                        ),
                        initialValue: widget.isCreate
                            ? ''
                            : widget.firmsList[widget.index].cui,
                      ),
                    ),
                  if (_isJuridic)
                    TextFormField(
                      textCapitalization: TextCapitalization.words,
                      initialValue: widget.isCreate
                          ? ''
                          : widget.firmsList[widget.index].address,
                      decoration: const InputDecoration(
                        label: Text('Adresa'),
                      ),
                      validator: (value) {
                        if (value == '' || value == null || value.length < 3) {
                          return 'Introdu o adresa corecta';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        setState(() {
                          _address = value!;
                        });
                      },
                    ),
                  if (_isJuridic)
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isTVA = !_isTVA;
                        });
                      },
                      icon: _isTVA
                          ? const Icon(Icons.check_box_outlined)
                          : const Icon(Icons.check_box_outline_blank),
                      label: const Text('Platitor TVA?'),
                    ),
                ],
              ),
            const SizedBox(
              height: 10,
            ),
            Text(
              ref.read(addressBookProvider.notifier).errorMessage,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });
                    bool isCompleted;
                    var validation = widget.formKey.currentState!.validate();
                    if (!validation) {
                      return;
                    }
                    widget.formKey.currentState!.save();

                    if (widget.collection == 'clients' && widget.isCreate) {
                      isCompleted = await ref
                          .read(addressBookProvider.notifier)
                          .addClientInClientsList(
                            collection: widget.collection,
                            name: _name,
                            telNo: _telNo,
                            isJuridic: _isJuridic,
                            address: _address,
                            cui: _cui,
                            isTVAPayer: _isTVA,
                            ownerFirm: widget.ownerFirm,
                            firebaseAuth: ref.read(firebaseAuth),
                            firebaseFirestore: ref.read(firebaseFirestore),
                          );
                      if (isCompleted) {
                        widget.createListTile(widget.collection);
                      }
                    } else if (widget.collection == 'services' &&
                        widget.isCreate) {
                      isCompleted = await ref
                          .read(addressBookProvider.notifier)
                          .addServiceInServicesList(
                            collection: widget.collection,
                            name: _name,
                            ownerFirm: widget.ownerFirm,
                            firebaseAuth: ref.read(firebaseAuth),
                            firebaseFirestore: ref.read(firebaseFirestore),
                          );
                      if (isCompleted) {
                        widget.createListTile(widget.collection);
                      }
                    } else {
                      isCompleted = await ref
                          .read(addressBookProvider.notifier)
                          .editExistingEntry(
                            collection: widget.collection,
                            name: _name,
                            telNo: _telNo,
                            isJuridic: _isJuridic,
                            address: _address,
                            cui: _cui,
                            isTVAPayer: _isTVA,
                            ownerFirm: widget.ownerFirm,
                            index: widget.index,
                            firebaseAuth: ref.read(firebaseAuth),
                            firebaseFirestore: ref.read(firebaseFirestore),
                            oldName: widget.name,
                          );
                    }
                    setState(() {
                      _isLoading = false;
                    });
                    if (context.mounted && isCompleted) {
                      Navigator.of(context).pop(isCompleted);
                    }
                  },
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(),
                        )
                      : (widget.isCreate
                          ? const Text('Adauga')
                          : const Text('Modifica')),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(addressBookProvider.notifier).resetErrorMessage();
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Renunta'),
                ),
              ],
            ),
            if (!widget.isCreate)
              Center(
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStatePropertyAll(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                    });
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => PartnerHistoryScreen(
                            transactionModel: TransactionModel(
                              partnerName: _name,
                              serviceProductName:
                                  widget.collection == 'services' ? _name : '',
                              price: 0,
                              dateTime: DateTime.now(),
                              transactionSign: '+',
                              cui: widget.ownerFirm,
                              userEmail:
                                  ref.read(userInformationProvider).loggedUser,
                              observations: '',
                              telNo: _telNo,
                              isTransaction: false,
                            ),
                            firebaseFirestore: ref.read(firebaseFirestore),
                            collection: 'appointments',
                            isClientHistory:
                                widget.collection == 'services' ? false : true,
                            // isCollected: isCollected,
                            userRole: widget.userRole,
                            ownerCui: widget.ownerFirm)));

                    setState(() {
                      _isLoading = false;
                    });
                  },
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text(
                          'Vezi istoric',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            const SizedBox(
              height: 200,
            ),
          ],
        ),
      ),
    );
  }
}
