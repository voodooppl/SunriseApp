import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sunrise_app/screens/auth.dart';
import 'package:sunrise_app/screens/main_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:sunrise_app/screens/settings_page.dart';
import 'package:sunrise_app/screens/users_screen.dart';

import '../screens/address_book_management.dart';

class MainDrawer extends StatelessWidget {
  const MainDrawer(
      {required this.alias,
      required this.auth,
      required this.firebaseFirestore,
      required this.managedFirmsList,
      Key? key})
      : super(key: key);

  final String alias;
  final FirebaseAuth auth;
  final FirebaseFirestore firebaseFirestore;
  final List<dynamic> managedFirmsList;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DrawerHeader(
            child: Padding(
              padding: EdgeInsets.only(bottom: 25),
              child: CircleAvatar(
                radius: 70,
                backgroundImage: AssetImage('images/Just for You_logo.png'),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Text(
                alias == '' ? auth.currentUser!.email.toString() : alias,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => const MainScreen(),
                      ),
                    );
                  },
                  leading: FaIcon(
                    FontAwesomeIcons.house,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text(
                    'Home',
                  ),
                ),
                // ListTile(
                //   onTap: () {},
                //   leading: FaIcon(
                //     FontAwesomeIcons.calendarDays,
                //     color: Theme.of(context).colorScheme.primary,
                //   ),
                //   title: const Text(
                //     'Programari',
                //   ),
                // ),
                // ListTile(
                //   onTap: () {},
                //   leading: FaIcon(
                //     FontAwesomeIcons.cashRegister,
                //     color: Theme.of(context).colorScheme.primary,
                //   ),
                //   title: const Text(
                //     'Balanta',
                //   ),
                // ),
                ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => AddressBookScreen(
                          firebaseFirestore: firebaseFirestore,
                          managedFirmsList: managedFirmsList,
                        ),
                      ),
                    );
                  },
                  leading: FaIcon(
                    FontAwesomeIcons.listUl,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text(
                    'Address Book',
                  ),
                ),
                ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => UsersScreen(
                          loggedUser: auth.currentUser!.email.toString(),
                          firebaseFirestore: firebaseFirestore,
                          alias: alias,
                        ),
                      ),
                    );
                  },
                  leading: FaIcon(
                    FontAwesomeIcons.usersGear,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text(
                    'Users Roles',
                  ),
                ),
                ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => SettingsScreen(
                            loggedUser: auth.currentUser!.email.toString()),
                      ),
                    );
                  },
                  leading: FaIcon(
                    FontAwesomeIcons.gear,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text(
                    'Setari',
                  ),
                ),
                ListTile(
                  onTap: () {
                    auth.signOut();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (ctx) => const AuthScreen(),
                      ),
                    );
                  },
                  leading: FaIcon(
                    FontAwesomeIcons.rightFromBracket,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: const Text(
                    'Log Out',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
