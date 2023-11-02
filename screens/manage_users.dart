import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sunrise_app/models/firm_identification_data.dart';
import 'package:sunrise_app/screens/users_screen.dart';

class ManageUsers extends StatefulWidget {
  const ManageUsers(
      {required this.loggedUser,
      required this.userRole,
      required this.firmIdentificationData,
      required this.firebaseFirestore,
      required this.alias,
      Key? key})
      : super(key: key);

  final String loggedUser;
  final String userRole;
  final FirmIdentificationData firmIdentificationData;
  final FirebaseFirestore firebaseFirestore;
  final String alias;

  @override
  State<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers> {
  final TextEditingController _emailEditingController = TextEditingController();
  late bool _isAddManager = false;
  late bool _isAddUser = false;
  late bool _isLoading = false;
  late bool _userExists = false;
  late String _hintText = 'Cauta o adresa de email';
  late String _userToBeAdded = '';
  late String _userToBeAddedID = '';
  late String _firmToBeAddedCui = '';
  late List<dynamic> _userFirmsList = [];

  void _searchUserEmail() async {
    setState(() {
      _isLoading = true;
    });

    var myData = await widget.firebaseFirestore.collection('users').get();
    for (var data in myData.docs) {
      if (data.data()['user_email'].toString().toLowerCase() ==
          _emailEditingController.text.toLowerCase()) {
        var firmData = await widget.firebaseFirestore
            .collection('firme')
            .get()
            .then((value) => value.docs.where((element) =>
                element.data()['CUI'] == widget.firmIdentificationData.cui));
        for (var data in firmData) {
          if (data.data()['admin'] == _emailEditingController.text ||
              data.data()['managers'].contains(_emailEditingController.text) ||
              data.data()['users'].contains(_emailEditingController.text)) {
            setState(() {
              _hintText = 'Acest user este deja asignat acestei firme.';
              _isLoading = false;
            });
            _emailEditingController.clear();
            return;
          }
        }

        setState(() {
          _userExists = true;
          _isLoading = false;
          _userToBeAdded = _emailEditingController.text;
          _userToBeAddedID = data.id;
          _userFirmsList = data.data()['firms'];
          _firmToBeAddedCui = widget.firmIdentificationData.cui;
        });
        return;
      }
    }

    setState(() {
      _hintText = 'Userul acesta nu exista';
      _isLoading = false;
    });
    _emailEditingController.clear();
  }

  void _dialogForAddingUser(
    String action,
    String userToAdd,
    String userRole,
    String accessLevel,
    bool isLoading,
  ) {
    showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text(
              'Administrare rol utilizator',
              textAlign: TextAlign.center,
            ),
            content: Text(
              action == 'adding'
                  ? 'Esti sigur ca vrei sa adaugi utilizatorul $userToAdd in rolul de $userRole pentru aceasta firma?'
                  : 'Esti sigur ca vrei sa stergi utilizatorul $userToAdd din rolul de $userRole al aceastei firme?',
              textAlign: TextAlign.center,
            ),
            actions: [
              ButtonBar(
                alignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      action == 'adding'
                          ? _addUserToFirm(accessLevel, isLoading)
                          : _deleteUserfromFirm(
                              accessLevel, isLoading, userToAdd);
                    },
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : const Text('Da'),
                  ),
                  TextButton(
                    onPressed: () {
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

  void _addUserToFirm(String accessLevel, bool isLoading) async {
    setState(() {
      _isLoading = true;
    });

    await widget.firebaseFirestore
        .collection('users')
        .doc(_userToBeAddedID)
        .update({
      'firms': [..._userFirmsList, _firmToBeAddedCui],
    });

    var myData = await widget.firebaseFirestore
        .collection('firme')
        .doc(widget.firmIdentificationData.cui)
        .get();

    var listOfEmails = myData.data()![accessLevel];
    await widget.firebaseFirestore
        .collection('firme')
        .doc(widget.firmIdentificationData.cui)
        .update({
      accessLevel: [...listOfEmails, _userToBeAdded],
    });
    setState(() {
      _isLoading = false;
      isLoading = false;
    });

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => UsersScreen(
              loggedUser: widget.loggedUser,
              alias: widget.alias,
              firebaseFirestore: widget.firebaseFirestore),
        ),
      );
    }
  }

  void _deleteUserfromFirm(
    String accessLevel,
    bool isLoading,
    String selectedEmail,
  ) async {
    setState(() {
      _isLoading = true;
    });

    var selectedUser = await widget.firebaseFirestore
        .collection('users')
        .get()
        .then((value) => value.docs
            .where((element) => element.data()['user_email'] == selectedEmail));
    var userId = selectedUser.first.id;
    List<dynamic> userFirms = selectedUser.first.data()['firms'];
    userFirms.remove(widget.firmIdentificationData.cui);

    await widget.firebaseFirestore.collection('users').doc(userId).update({
      'firms': userFirms,
    });

    var firmData = await widget.firebaseFirestore
        .collection('firme')
        .doc(widget.firmIdentificationData.cui)
        .get();
    List<dynamic> firmUsers = firmData.data()![accessLevel];
    firmUsers.remove(selectedEmail);

    await widget.firebaseFirestore
        .collection('firme')
        .doc(widget.firmIdentificationData.cui)
        .update({
      accessLevel: firmUsers,
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Utilizator sters'),
              TextButton.icon(
                onPressed: () async {
                  userFirms.add(widget.firmIdentificationData.cui);
                  firmUsers.add(selectedEmail);
                  await widget.firebaseFirestore
                      .collection('users')
                      .doc(userId)
                      .update({
                    'firms': userFirms,
                  });
                  await widget.firebaseFirestore
                      .collection('firme')
                      .doc(widget.firmIdentificationData.cui)
                      .update({
                    accessLevel: firmUsers,
                  });

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  }
                },
                icon: const Icon(Icons.undo),
                label: const Text('Anuleaza'),
              ),
            ],
          ),
        ),
      );
    }

    setState(() {
      _isLoading = false;
      isLoading = false;
    });

    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => UsersScreen(
              loggedUser: widget.loggedUser,
              alias: widget.alias,
              firebaseFirestore: widget.firebaseFirestore),
        ),
      );
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _emailEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Administrare useri\n${widget.firmIdentificationData.firmName}',
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: ListView(
          children: [
            const SizedBox(
              height: 40,
            ),
            const Text('ADMIN'),
            const SizedBox(
              height: 20,
            ),
            ListTile(
              leading: FaIcon(
                FontAwesomeIcons.crown,
                color: iconColor,
              ),
              title: Text(widget.firmIdentificationData.admin),
              subtitle: const Text('ADMIN'),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text('MANAGERS'),
                const SizedBox(
                  height: 20,
                ),
                if (widget.userRole == 'admin')
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isAddManager = !_isAddManager;
                      });
                    },
                    icon: Icon(
                      Icons.add,
                      color: iconColor,
                    ),
                  ),
              ],
            ),
            if (widget.firmIdentificationData.managers.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                child: const Text('-'),
              ),
            if (_isAddManager)
              TextField(
                controller: _emailEditingController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                decoration: InputDecoration(
                    hintText: _hintText,
                    hintStyle: TextStyle(
                        color: _hintText == 'Cauta o adresa de email'
                            ? null
                            : Colors.red),
                    suffixIcon: IconButton(
                      onPressed: _searchUserEmail,
                      icon: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : _userExists
                              ? IconButton(
                                  onPressed: () {
                                    _dialogForAddingUser(
                                      'adding',
                                      _userToBeAdded,
                                      'MANAGER',
                                      'managers',
                                      _isAddManager,
                                    );
                                  },
                                  icon: Icon(
                                    Icons.check,
                                    color: iconColor,
                                  ),
                                )
                              : Icon(
                                  Icons.search,
                                  color: iconColor,
                                ),
                    )),
              ),
            if (_isAddManager)
              const SizedBox(
                height: 10,
              ),
            ListView.builder(
              shrinkWrap:
                  true, // Ensure the ListView occupies only the necessary space
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (ctx, index) => ListTile(
                leading: FaIcon(
                  FontAwesomeIcons.solidStar,
                  color: iconColor,
                ),
                title: Text(
                  widget.firmIdentificationData.managers[index],
                ),
                subtitle: const Text('Manager'),
                trailing: widget.userRole == 'admin'
                    ? IconButton(
                        onPressed: () {
                          _dialogForAddingUser(
                            'delete',
                            widget.firmIdentificationData.managers[index],
                            'MANAGER',
                            'managers',
                            _isAddManager,
                          );

                          // ScaffoldMessenger.of(context).showSnackBar(
                          //   SnackBar(
                          //     content: Row(
                          //       children: [
                          //         const Text(
                          //             'Permisiunile userului au fost revocate'),
                          //         TextButton.icon(
                          //           onPressed: () {
                          //             _addUserToFirm('managers', _isAddManager);
                          //           },
                          //           icon: const Icon(Icons.undo),
                          //           label: const Text('Anuleaza'),
                          //         ),
                          //       ],
                          //     ),
                          //   ),
                          // );
                        },
                        icon: Icon(
                          Icons.delete,
                          color: iconColor,
                        ),
                      )
                    : null,
              ),
              itemCount: widget.firmIdentificationData.managers.length,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Text('USERS'),
                const SizedBox(
                  height: 10,
                ),
                if (widget.userRole == 'admin' || widget.userRole == 'manager')
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isAddUser = !_isAddUser;
                      });
                    },
                    icon: Icon(
                      Icons.add,
                      color: iconColor,
                    ),
                  ),
              ],
            ),
            if (widget.firmIdentificationData.users.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                child: const Text('-'),
              ),
            if (_isAddUser)
              TextField(
                controller: _emailEditingController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                decoration: InputDecoration(
                    hintText: _hintText,
                    hintStyle: TextStyle(
                        color: _hintText == 'Cauta o adresa de email'
                            ? null
                            : Colors.red),
                    suffixIcon: IconButton(
                      onPressed: _searchUserEmail,
                      icon: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(),
                            )
                          : _userExists
                              ? IconButton(
                                  onPressed: () {
                                    _dialogForAddingUser(
                                      'adding',
                                      _userToBeAdded,
                                      'USER',
                                      'users',
                                      _isAddManager,
                                    );
                                  },
                                  icon: Icon(
                                    Icons.check,
                                    color: iconColor,
                                  ),
                                )
                              : Icon(
                                  Icons.search,
                                  color: iconColor,
                                ),
                    )),
              ),
            if (_isAddUser)
              const SizedBox(
                height: 10,
              ),
            ListView.builder(
              shrinkWrap:
                  true, // Ensure the ListView occupies only the necessary space
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (ctx, index) => ListTile(
                leading: FaIcon(
                  FontAwesomeIcons.solidChessPawn,
                  color: iconColor,
                ),
                title: Text(
                  widget.firmIdentificationData.users[index],
                ),
                subtitle: const Text('User'),
                trailing:
                    widget.userRole == 'admin' || widget.userRole == 'manager'
                        ? IconButton(
                            onPressed: () {
                              _dialogForAddingUser(
                                'delete',
                                widget.firmIdentificationData.users[index],
                                'USER',
                                'users',
                                _isAddUser,
                              );
                            },
                            icon: Icon(
                              Icons.delete,
                              color: iconColor,
                            ),
                          )
                        : null,
              ),
              itemCount: widget.firmIdentificationData.users.length,
            ),
          ],
        ),
      ),
    );
  }
}
