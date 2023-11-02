import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunrise_app/models/firm_identification_data.dart';
import 'package:sunrise_app/providers/firms_information_provider.dart';
import 'package:sunrise_app/providers/user_information_provider.dart';
import 'package:sunrise_app/widgets/buttom_button_large.dart';

import 'main_screen.dart';

class AddEditFirms extends ConsumerStatefulWidget {
  const AddEditFirms(
      {required this.loggedUser,
      required this.isCreate,
      required this.firebaseFirestore,
      this.firmIdentificationData,
      required this.userRole,
      Key? key})
      : super(key: key);

  final FirebaseFirestore firebaseFirestore;
  final String loggedUser;
  final bool isCreate;
  final FirmIdentificationData? firmIdentificationData;
  final String userRole;

  @override
  ConsumerState<AddEditFirms> createState() => _AddEditFirmsState();
}

class _AddEditFirmsState extends ConsumerState<AddEditFirms> {
  final _formKey = GlobalKey<FormState>();
  late String _firmName = widget.firmIdentificationData?.firmName ?? '';
  late String _address = widget.firmIdentificationData?.address ?? '';
  late String _cui = widget.firmIdentificationData?.cui ?? '';
  late String _telNo = widget.firmIdentificationData?.telNo ?? '';
  late bool _isJuridic = widget.firmIdentificationData?.isJuridic ?? false;
  late bool _isTVA = widget.firmIdentificationData?.isTVAPayer ?? false;
  late String _notificationMessage =
      widget.firmIdentificationData?.notificationMessage ?? '';
  String _errorMessage = '';
  late bool _isLoading = false;
  late bool _isEdit = widget.isCreate;
  late bool _isDelete = false;

  void _registerNewFirm() async {
    _isLoading = true;
    final isValid = _formKey.currentState!.validate();

    if (!isValid) {
      return;
    }
    _formKey.currentState!.save();
    if (!_isJuridic && _cui.isEmpty) {
      _cui = _firmName.replaceAll(' ', '_').toLowerCase();
    }

    if (widget.isCreate) {
      var snapshots =
          await widget.firebaseFirestore.collection('firme').doc(_cui).get();
      if (snapshots.data() != null) {
        setState(() {
          _errorMessage = 'Aceasta firma exista deja in baza noastra de date.';
        });
        _isLoading = false;
        return;
      }
      var myData = await widget.firebaseFirestore.collection('users').get();
      for (var data in myData.docs) {
        if (data.data()['user_email'] == widget.loggedUser) {
          List<String> firmsList = data.data()['firms'].cast<String>();
          firmsList.add(_cui);
          var id = data.id;
          await widget.firebaseFirestore.collection('users').doc(id).update({
            'firms': firmsList,
          });
        }
      }
    }
    await widget.firebaseFirestore.collection('firme').doc(_cui).set({
      'firm_name': _firmName,
      'address': _address,
      'is_juridic_person': _isJuridic,
      'CUI': _cui,
      'TVA': _isTVA,
      'tel_number': _telNo,
      'admin': widget.loggedUser,
      'managers': [],
      'users': [],
      'notification_message': _notificationMessage,
    });

    _isLoading = false;
    if (context.mounted) Navigator.of(context).pop();
  }

  bool isCompleted = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isCreate ? 'Adauga un nou business' : 'Editeaza business-ul',
          maxLines: 2,
          textAlign: TextAlign.center,
        ),
        actions: widget.userRole == 'admin' && !widget.isCreate
            ? [
                PopupMenuButton(onSelected: (value) {
                  if (_isDelete) {
                    showDialog(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            title: const Text(
                              'Sterge firma?',
                              textAlign: TextAlign.center,
                            ),
                            content: const Text(
                              'Esti sigur ca vrei sa stergi aceasta firma? \nVor fi sterse toate tranzactiile asociate acesteia.',
                              textAlign: TextAlign.center,
                            ),
                            actionsAlignment: MainAxisAlignment.spaceEvenly,
                            actions: [
                              ButtonBar(
                                alignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  TextButton(
                                      onPressed: () async {
                                        setState(() {
                                          _isLoading = true;
                                        });

                                        isCompleted = await ref
                                            .read(firmsInformationProvider
                                                .notifier)
                                            .deleteFirmAndAllTraces(
                                              widget
                                                  .firmIdentificationData!.cui,
                                              ref.read(firebaseFirestore),
                                            );
                                        setState(() {
                                          _isLoading = false;
                                        });
                                        if (context.mounted && isCompleted) {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (ctx) =>
                                                  const MainScreen(),
                                            ),
                                          );
                                        }
                                      },
                                      child: isCompleted
                                          ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
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
                }, itemBuilder: (item) {
                  return [
                    PopupMenuItem(
                      value: _isEdit,
                      child: Text(
                        'Editeaza',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      onTap: () {
                        setState(() {
                          _isEdit = !_isEdit;
                        });
                      },
                    ),
                    PopupMenuItem(
                      value: true,
                      onTap: () {
                        _isDelete = true;
                      },
                      child: Text(
                        'Sterge',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.primary),
                      ),
                    ),
                  ];
                }),
              ]
            : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 20),
              child: Column(
                children: [
                  const Text(
                    'Introdu datele de identificare',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          TextFormField(
                            enabled: _isEdit,
                            initialValue: _firmName,
                            decoration: const InputDecoration(
                              labelText: 'Nume Business',
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (value) {
                              if (value == null ||
                                  value.isEmpty ||
                                  value.length < 4) {
                                return 'Introduceti numele complet al business-ului dvs.';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _firmName = value!;
                            },
                          ),
                          TextFormField(
                            enabled: _isEdit,
                            initialValue: _address,
                            decoration: const InputDecoration(
                              labelText: 'Adresa Business',
                            ),
                            textCapitalization: TextCapitalization.words,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Introduceti adresa completa a business-ului';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _address = value!;
                            },
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  enabled: _isEdit,
                                  initialValue: _telNo,
                                  decoration: const InputDecoration(
                                    labelText: 'Nr. Telefon',
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  validator: (value) {
                                    if (value == null ||
                                        value.isEmpty ||
                                        value.length != 10) {
                                      return 'Introduceti un numar de telefon valid';
                                    }
                                    return null;
                                  },
                                  onSaved: (value) {
                                    _telNo = value!;
                                  },
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _isEdit
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
                                label: const Text('Persoana juridica?'),
                              ),
                            ],
                          ),
                          if (_isJuridic)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
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
                                    initialValue: _isJuridic ? _cui : '',
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _isEdit
                                      ? () {
                                          setState(() {
                                            _isTVA = !_isTVA;
                                          });
                                        }
                                      : null,
                                  icon: _isTVA
                                      ? const Icon(Icons.check_box_outlined)
                                      : const Icon(
                                          Icons.check_box_outline_blank),
                                  label: const Text('Platitor TVA?'),
                                ),
                              ],
                            ),
                          const SizedBox(
                            height: 20,
                          ),
                          TextFormField(
                            minLines: 5,
                            maxLines: 10,
                            enabled: _isEdit,
                            initialValue: _notificationMessage,
                            decoration: InputDecoration(
                              label: const Text('Mesaj de notificare'),
                              hintText:
                                  'Mesajul de notificare care va fi trimis clientilor pentru programari. Se poate completa/edita ulterior.',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            onSaved: (value) {
                              setState(() {
                                _notificationMessage = value!;
                              });
                            },
                          ),
                          Center(
                            child: Text(
                              _errorMessage,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (!_isLoading)
            BottomLargeButton(
              buttonName: widget.isCreate ? 'Inregistreaza' : 'Modifica',
              onTapFunction: _registerNewFirm,
              myIcon: const Icon(Icons.add_business),
            ),
        ],
      ),
    );
  }
}
