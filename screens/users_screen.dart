import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sunrise_app/models/firm_identification_data.dart';
import 'package:sunrise_app/models/user_info_model.dart';
import 'package:sunrise_app/providers/theme_provider.dart';
import 'package:sunrise_app/providers/user_information_provider.dart';
import 'package:sunrise_app/screens/manage_users.dart';
import 'package:sunrise_app/screens/reset_password.dart';

import 'main_screen.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen(
      {required this.loggedUser,
      required this.alias,
      required this.firebaseFirestore,
      Key? key})
      : super(key: key);

  final String loggedUser;
  final String alias;
  final FirebaseFirestore firebaseFirestore;

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _alias = widget.alias;
  late bool _isEditAlias = false;
  late bool _isLoading = false;

  final List<FirmIdentificationData> _adminList = [];
  final List<FirmIdentificationData> _managerList = [];
  final List<FirmIdentificationData> _userList = [];

  void _checkUserLevel() async {
    setState(() {
      _isLoading = true;
    });

    var usersData = await widget.firebaseFirestore
        .collection('users')
        .get()
        .then((value) => value.docs.where(
            (element) => element.data()['user_email'] == widget.loggedUser));
    var userAssignedFirms =
        usersData.map((e) => e.data()['firms'].cast<String>());
    for (var firmCuiList in userAssignedFirms) {
      for (var firmCui in firmCuiList) {
        var firmData = await widget.firebaseFirestore
            .collection('firme')
            .doc(firmCui)
            .get();
        if (firmData.data() == null) {
          setState(() {
            _isLoading = false;
          });
          return;
        }
        FirmIdentificationData firmIdentificationData = FirmIdentificationData(
          firmName: firmData.data()!['firm_name'],
          address: firmData.data()!['address'],
          isJuridic: firmData.data()!['is_juridic_person'],
          cui: firmData.data()!['CUI'],
          isTVAPayer: firmData.data()!['TVA'],
          telNo: firmData.data()!['tel_number'],
          admin: firmData.data()!['admin'],
          managers: firmData.data()!['managers'],
          users: firmData.data()!['users'],
          notificationMessage: firmData.data()!['notification_message'],
        );
        if (firmData.data()!['admin'] == widget.loggedUser) {
          _adminList.add(firmIdentificationData);
        } else if (firmData.data()!['managers'].contains(widget.loggedUser)) {
          _managerList.add(firmIdentificationData);
        } else if (firmData.data()!['users'].contains(widget.loggedUser)) {
          _userList.add(firmIdentificationData);
        }
      }
    }
    await ref.read(userInformationProvider.notifier).getUserInfo(
          widget.firebaseFirestore,
          ref.read(firebaseAuth),
        );
    setState(() {
      _isLoading = false;
    });
  }

  void _setAliasName() async {
    var isValid = _formKey.currentState!.validate();

    if (!isValid) {
      return;
    }
    _formKey.currentState!.save();

    var myData = await widget.firebaseFirestore.collection('users').get();

    if (myData.docs.isEmpty) {
      await widget.firebaseFirestore.collection('users').doc().set({
        'user_email': widget.loggedUser,
        'alias': _alias,
        'firms': [],
      });
    }
    for (var data in myData.docs.where(
        (element) => element.data()['user_email'] == widget.loggedUser)) {
      if (data.exists) {
        if (_alias.isNotEmpty || _alias != '') {
          if (data.data()['user_email'] == widget.loggedUser) {
            String id = data.id;
            await widget.firebaseFirestore.collection('users').doc(id).update({
              'alias': _alias,
            });
          }
        }
      } else {
        if (_alias.isNotEmpty || _alias != '') {
          await widget.firebaseFirestore.collection('users').doc().set({
            'user_email': widget.loggedUser,
            'alias': _alias,
            'firms': data.data()['firms'],
          });
        }
      }
    }
    // setState(() {
    //   _isEditAlias = false;
    // });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _checkUserLevel();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.primary;
    return WillPopScope(
      onWillPop: () async {
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => const MainScreen(),
            ),
          );
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pagina utilizator'),
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Form(
                key: _formKey,
                child: ListView(
                  children: [
                    ListTile(
                      leading: FaIcon(
                        FontAwesomeIcons.at,
                        color: iconColor,
                      ),
                      title: const Text('E-mail:'),
                      subtitle: Text(widget.loggedUser),
                      trailing: FaIcon(
                        FontAwesomeIcons.pen,
                        color: iconColor,
                      ),
                    ),
                    ListTile(
                      leading: FaIcon(
                        FontAwesomeIcons.user,
                        color: iconColor,
                      ),
                      title: const Text('Alias:'),
                      subtitle: _isEditAlias
                          ? TextFormField(
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    value == '') {
                                  return 'Introdu un nume corect';
                                }
                                return null;
                              },
                              onSaved: (value) {
                                setState(() {
                                  _alias = value!;
                                });
                              },
                              autofocus: true,
                              textCapitalization: TextCapitalization.words,
                              initialValue: _alias,
                              decoration: InputDecoration(
                                  hintText: 'Introdu un alias/username',
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        onPressed: () async {
                                          setState(() {
                                            _isEditAlias = true;
                                          });
                                          _setAliasName();
                                          await ref
                                              .read(
                                                  colorSchemeProvider.notifier)
                                              .createDB(widget.loggedUser);
                                          await ref
                                              .read(
                                                  colorSchemeProvider.notifier)
                                              .updateUserInfoFromDB(
                                                  widget.loggedUser,
                                                  UserInformation(
                                                      loggedUser:
                                                          widget.loggedUser,
                                                      alias: _alias,
                                                      userFirms: []));
                                          print(ref
                                              .read(
                                                  colorSchemeProvider.notifier)
                                              .userInformation!
                                              .alias);
                                          setState(() {
                                            _isEditAlias = false;
                                          });
                                        },
                                        icon: _isLoading
                                            ? const CircularProgressIndicator()
                                            : Icon(
                                                Icons.check,
                                                color: iconColor,
                                              ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _isEditAlias = false;
                                          });
                                        },
                                        icon: Icon(
                                          Icons.close,
                                          color: iconColor,
                                        ),
                                      ),
                                    ],
                                  )),
                            )
                          : Text(_alias),
                      trailing: _isEditAlias
                          ? null
                          : IconButton(
                              icon: FaIcon(
                                FontAwesomeIcons.userPen,
                                color: iconColor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isEditAlias = !_isEditAlias;
                                });
                              },
                            ),
                    ),
                    ListTile(
                      leading: FaIcon(
                        FontAwesomeIcons.lock,
                        color: iconColor,
                      ),
                      title: const Text('Reseteaza parola'),
                      subtitle: const Text('*****'),
                      trailing: IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (ctx) => const ResetPasswordScreen(),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.lock_reset,
                          color: iconColor,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Admin role:'),
                          SizedBox(
                            height: _adminList.isEmpty
                                ? 55
                                : _adminList.length * 55,
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ListView.builder(
                                    shrinkWrap:
                                        true, // Ensure the ListView occupies only the necessary space
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemBuilder: (ctx, index) {
                                      _adminList.sort((a, b) =>
                                          a.firmName.compareTo(b.firmName));
                                      return ListTile(
                                        title: Text(_adminList[index].firmName),
                                        trailing: IconButton(
                                          onPressed: () async {
                                            var firmData = await widget
                                                .firebaseFirestore
                                                .collection('firme')
                                                .doc(_adminList[index].cui)
                                                .get();
                                            if (context.mounted) {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (ctx) => ManageUsers(
                                                    loggedUser:
                                                        widget.loggedUser,
                                                    userRole: 'admin',
                                                    firmIdentificationData:
                                                        FirmIdentificationData(
                                                      firmName: firmData
                                                          .data()!['firm_name'],
                                                      address: firmData
                                                          .data()!['address'],
                                                      isJuridic: firmData
                                                              .data()![
                                                          'is_juridic_person'],
                                                      cui: firmData
                                                          .data()!['CUI'],
                                                      isTVAPayer: firmData
                                                          .data()!['TVA'],
                                                      telNo: firmData.data()![
                                                          'tel_number'],
                                                      admin: firmData
                                                          .data()!['admin'],
                                                      managers: firmData
                                                          .data()!['managers'],
                                                      users: firmData
                                                          .data()!['users'],
                                                      notificationMessage: firmData
                                                              .data()![
                                                          'notification_message'],
                                                    ),
                                                    firebaseFirestore: widget
                                                        .firebaseFirestore,
                                                    alias: _alias,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          icon: FaIcon(
                                            FontAwesomeIcons.userGear,
                                            color: iconColor,
                                          ),
                                        ),
                                      );
                                    },
                                    itemCount: _adminList.length,
                                  ),
                          ),
                          const Text('Manager role:'),
                          SizedBox(
                            height: _managerList.isEmpty
                                ? 55
                                : _managerList.length * 55,
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ListView.builder(
                                    shrinkWrap:
                                        true, // Ensure the ListView occupies only the necessary space
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemBuilder: (ctx, index) {
                                      _managerList.sort((a, b) =>
                                          a.firmName.compareTo(b.firmName));
                                      return ListTile(
                                        title:
                                            Text(_managerList[index].firmName),
                                        trailing: IconButton(
                                          onPressed: () async {
                                            var firmData = await widget
                                                .firebaseFirestore
                                                .collection('firme')
                                                .doc(_managerList[index].cui)
                                                .get();
                                            if (context.mounted) {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (ctx) => ManageUsers(
                                                    loggedUser:
                                                        widget.loggedUser,
                                                    userRole: 'manager',
                                                    firmIdentificationData:
                                                        FirmIdentificationData(
                                                      firmName: firmData
                                                          .data()!['firm_name'],
                                                      address: firmData
                                                          .data()!['address'],
                                                      isJuridic: firmData
                                                              .data()![
                                                          'is_juridic_person'],
                                                      cui: firmData
                                                          .data()!['CUI'],
                                                      isTVAPayer: firmData
                                                          .data()!['TVA'],
                                                      telNo: firmData.data()![
                                                          'tel_number'],
                                                      admin: firmData
                                                          .data()!['admin'],
                                                      managers: firmData
                                                          .data()!['managers'],
                                                      users: firmData
                                                          .data()!['users'],
                                                      notificationMessage: firmData
                                                              .data()![
                                                          'notification_message'],
                                                    ),
                                                    firebaseFirestore: widget
                                                        .firebaseFirestore,
                                                    alias: _alias,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          icon: FaIcon(
                                            FontAwesomeIcons.userPlus,
                                            color: iconColor,
                                          ),
                                        ),
                                      );
                                    },
                                    itemCount: _managerList.length,
                                  ),
                          ),
                          const Text('User role:'),
                          SizedBox(
                            height:
                                _userList.isEmpty ? 55 : _userList.length * 55,
                            child: _isLoading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : ListView.builder(
                                    shrinkWrap:
                                        true, // Ensure the ListView occupies only the necessary space
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemBuilder: (ctx, index) {
                                      _userList.sort((a, b) =>
                                          a.firmName.compareTo(b.firmName));
                                      return ListTile(
                                        title: Text(_userList[index].firmName),
                                        trailing: IconButton(
                                          onPressed: () async {
                                            var firmData = await widget
                                                .firebaseFirestore
                                                .collection('firme')
                                                .doc(_userList[index].cui)
                                                .get();
                                            if (context.mounted) {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (ctx) => ManageUsers(
                                                    loggedUser:
                                                        widget.loggedUser,
                                                    userRole: 'user',
                                                    firmIdentificationData:
                                                        FirmIdentificationData(
                                                      firmName: firmData
                                                          .data()!['firm_name'],
                                                      address: firmData
                                                          .data()!['address'],
                                                      isJuridic: firmData
                                                              .data()![
                                                          'is_juridic_person'],
                                                      cui: firmData
                                                          .data()!['CUI'],
                                                      isTVAPayer: firmData
                                                          .data()!['TVA'],
                                                      telNo: firmData.data()![
                                                          'tel_number'],
                                                      admin: firmData
                                                          .data()!['admin'],
                                                      managers: firmData
                                                          .data()!['managers'],
                                                      users: firmData
                                                          .data()!['users'],
                                                      notificationMessage: firmData
                                                              .data()![
                                                          'notification_message'],
                                                    ),
                                                    firebaseFirestore: widget
                                                        .firebaseFirestore,
                                                    alias: _alias,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          icon: FaIcon(
                                            FontAwesomeIcons.solidUser,
                                            color: iconColor,
                                          ),
                                        ),
                                      );
                                    },
                                    itemCount: _userList.length,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
