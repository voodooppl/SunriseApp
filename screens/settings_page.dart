import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sunrise_app/providers/theme_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:sunrise_app/providers/user_information_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({required this.loggedUser, Key? key}) : super(key: key);

  final String loggedUser;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // late Color _currentColor =
  //     widget.currentColor ?? Color.fromRGBO(138, 52, 134, 50);
  late Color _selectedColor;

  @override
  Widget build(BuildContext context) {
    late Color currentColor = ref.watch(colorSchemeProvider).primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setari aplicatie'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Text(
              'Culoare tema',
              style: TextStyle(
                fontSize: 22,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            content: SingleChildScrollView(
                              child: ColorPicker(
                                pickerColor: currentColor,
                                onColorChanged: (Color value) {
                                  setState(() {
                                    _selectedColor = value;
                                    currentColor = value;
                                  });
                                },
                              ),
                            ),
                            actions: [
                              ButtonBar(
                                alignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  TextButton(
                                    onPressed: () async {
                                      ///update the theme color
                                      await ref
                                          .read(colorSchemeProvider.notifier)
                                          .updateColor(
                                              widget.loggedUser, currentColor);

                                      ///update the db entry
                                      await ref
                                          .read(colorSchemeProvider.notifier)
                                          .updateDBColor(
                                              widget.loggedUser, currentColor);
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    child: const Text('Alege'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Renunta'),
                                  ),
                                  TextButton(
                                    onPressed: () async {
                                      currentColor = const Color.fromRGBO(
                                          138, 52, 134, 255);
                                      await ref
                                          .read(colorSchemeProvider.notifier)
                                          .updateColor(
                                              widget.loggedUser, currentColor);

                                      ///update the db entry
                                      await ref
                                          .read(colorSchemeProvider.notifier)
                                          .updateDBColor(
                                              widget.loggedUser, currentColor);
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    child: const Text('Default'),
                                  ),
                                ],
                              )
                            ],
                          );
                        });
                  },
                  child: CircleAvatar(
                    backgroundColor: currentColor,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                const Text('Alege o culoare'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
