import 'package:flutter/material.dart';

class BottomLargeButton extends StatelessWidget {
  const BottomLargeButton(
      {required this.buttonName,
      required this.onTapFunction,
      required this.myIcon,
      Key? key})
      : super(key: key);

  final String buttonName;
  final void Function() onTapFunction;
  final Icon myIcon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapFunction,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(5),
            topRight: Radius.circular(5),
          ),
          color: Theme.of(context).colorScheme.primary,
        ),
        padding: const EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            myIcon,
            Text(
              buttonName,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
