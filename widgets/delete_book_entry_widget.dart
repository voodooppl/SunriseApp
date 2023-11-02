import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/address_book_provider.dart';
import '../providers/user_information_provider.dart';

class DeleteBookEntryAlertDialog extends ConsumerStatefulWidget {
  const DeleteBookEntryAlertDialog(
      {required this.listOfDisplayedItems,
      required this.index,
      required this.collection,
      required this.servicesID,
      required this.contactsID,
      Key? key})
      : super(key: key);

  final List<dynamic> listOfDisplayedItems;
  final int index;
  final String collection;
  final List<dynamic> contactsID;
  final List<dynamic> servicesID;
  // final

  @override
  ConsumerState<DeleteBookEntryAlertDialog> createState() =>
      _DeleteBookEntryAlertDialogState();
}

class _DeleteBookEntryAlertDialogState
    extends ConsumerState<DeleteBookEntryAlertDialog> {
  late bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      alignment: AlignmentDirectional.center,
      title: const Text(
        'Atentie!',
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Sigur vrei sa stergi aceasta intrare?',
            textAlign: TextAlign.center,
          ),
          const SizedBox(
            height: 15,
          ),
          Text(
            widget.listOfDisplayedItems[widget.index].name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      actions: [
        ButtonBar(alignment: MainAxisAlignment.spaceEvenly, children: [
          TextButton(
            onPressed: () async {
              bool isCompleted = false;

              ///delete entry from list
              if (widget.collection != 'services') {
                // _idList = contactsID;
                isCompleted = await ref
                    .read(addressBookProvider.notifier)
                    .deleteListEntry(
                      collection: widget.collection,
                      listId: widget.index,
                      cloudId: widget.contactsID[widget.index],
                      firebaseFirestore: ref.read(firebaseFirestore),
                    );
                if (isCompleted) {
                  setState(() {
                    // widget.listOfDisplayedItems =
                    //     ref.read(addressBookProvider.notifier).cloudAddressBook;
                    _isLoading = !isCompleted;
                  });
                }
              } else if (widget.collection == 'services') {
                // _idList = servicesID;
                isCompleted = await ref
                    .read(addressBookProvider.notifier)
                    .deleteListEntry(
                      collection: widget.collection,
                      listId: widget.index,
                      cloudId: widget.servicesID[widget.index],
                      firebaseFirestore: ref.read(firebaseFirestore),
                    );
                if (isCompleted) {
                  setState(() {
                    // widget.listOfDisplayedItems = ref
                    //     .read(addressBookProvider.notifier)
                    //     .cloudServicesBook;
                    _isLoading = !isCompleted;
                  });
                }
              }
              setState(() {
                _isLoading = !isCompleted;
              });

              if (context.mounted && isCompleted) {
                Navigator.of(context).pop(isCompleted);
              }
            },
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : const Text('Da'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('Nu'),
          ),
        ]),
      ],
    );
  }
}
