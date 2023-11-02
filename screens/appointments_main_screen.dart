import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
// import 'package:flutter_pdfview/flutter_pdfview.dart';
// import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:sunrise_app/models/client_model.dart';
import 'package:sunrise_app/models/service_model.dart';
import 'package:sunrise_app/models/transaction_model.dart';
import 'package:sunrise_app/models/user_info_model.dart';
import 'package:sunrise_app/widgets/appointment_widget.dart';
import 'package:uuid/uuid.dart';
import '../providers/address_book_provider.dart';
import '../widgets/transaction_widget.dart';
import 'main_screen.dart';

Uuid uuid = const Uuid();

class AppointmentsMainScreen extends ConsumerStatefulWidget {
  const AppointmentsMainScreen(
      {required this.userInformation,
      required this.ownerFirmName,
      required this.ownerFirmCui,
      required this.firebaseFirestore,
      required this.userRole,
      Key? key})
      : super(key: key);

  final UserInformation userInformation;
  final String ownerFirmName;
  final String ownerFirmCui;
  final FirebaseFirestore firebaseFirestore;
  final String userRole;

  @override
  ConsumerState<AppointmentsMainScreen> createState() =>
      _AppointmentsMainScreenState();
}

class _AppointmentsMainScreenState
    extends ConsumerState<AppointmentsMainScreen> {
  late DateTime _date = DateTime.now();
  late String monday;
  late String tuesday;
  late String wednesday;
  late String thursday;
  late String friday;
  late String saturday;
  late String sunday;
  var _weekDaysList = [];
  late bool _isLoading = false;
  final Map<String, List<TransactionModel>> _forPdfMapList = {};

  void _getThisWeek() {
    var daysList = [];
    var weekday = _date.weekday;
    var daysAfter = 7 - weekday;

    for (var i = weekday - 1; i > 0; i--) {
      daysList.add(DateFormat('dd/MM/yyyy')
          .format(DateTime(_date.year, _date.month, _date.day - i)));
    }
    daysList.add(
      DateFormat('dd/MM/yyyy')
          .format(DateTime(_date.year, _date.month, _date.day)),
    );
    for (var i = 1; i <= daysAfter; i++) {
      daysList.add(DateFormat('dd/MM/yyyy')
          .format(DateTime(_date.year, _date.month, _date.day + i)));
    }

    setState(() {
      _weekDaysList = daysList;

      monday = daysList[0].toString().split(' ')[0];
      tuesday = daysList[1].toString().split(' ')[0];
      wednesday = daysList[2].toString().split(' ')[0];
      thursday = daysList[3].toString().split(' ')[0];
      friday = daysList[4].toString().split(' ')[0];
      saturday = daysList[5].toString().split(' ')[0];
      sunday = daysList[6].toString().split(' ')[0];
    });
  }

  void _modifyDate(String operation) {
    if (operation == '+') {
      var newDate = DateTime(_date.year, _date.month, _date.day + 7);
      setState(() {
        _date = newDate;
      });
    } else if (operation == '-') {
      var newDate = DateTime(_date.year, _date.month, _date.day - 7);
      setState(() {
        _date = newDate;
      });
    }
    _getThisWeek();
  }

  Future<File> _generatePdfDocument() async {
    setState(() {
      _isLoading = true;
    });

    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoExtraLight();
    List<pw.Widget> widget = [];
    final primaryColor = Theme.of(context).colorScheme.primary;
    String luni = '';
    String duminica = '';
    for (var day in _forPdfMapList.entries) {
      String weekDay = '';

      DateTime currentDay = DateFormat('dd/MM/yyyy').parse(day.key);
      if (currentDay.weekday == 1) {
        weekDay = 'Luni';
        luni = DateFormat('dd.MM.yyyy').format(currentDay);
      }
      if (currentDay.weekday == 2) {
        weekDay = 'Marti';
      }
      if (currentDay.weekday == 3) {
        weekDay = 'Miercuri';
      }
      if (currentDay.weekday == 4) {
        weekDay = 'Joi';
      }
      if (currentDay.weekday == 5) {
        weekDay = 'Vineri';
      }
      if (currentDay.weekday == 6) {
        weekDay = 'Sambata';
      }
      if (currentDay.weekday == 7) {
        weekDay = 'Duminica';
        duminica = DateFormat('dd.MM.yyyy').format(currentDay);
      }
      widget.add(
        pw.Column(
          children: [
            pw.Text(
              '$weekDay - ${day.key.toString()}',
              style: pw.TextStyle(
                  font: pw.Font.helveticaBold(),
                  color: PdfColor.fromInt(primaryColor.value),
                  fontWeight: pw.FontWeight.bold),
            ),
            pw.Column(children: [
              ...day.value
                  .map(
                    (e) => pw.Row(
                      children: [
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          child: pw.Container(
                            padding:
                                const pw.EdgeInsets.symmetric(horizontal: 10),
                            child: pw.Text(
                              DateFormat('HH:mm').format(e.dateTime),
                              textAlign: pw.TextAlign.center,
                              style: pw.TextStyle(
                                font: font,
                                color: PdfColor.fromInt(primaryColor.value),
                              ),
                            ),
                            decoration: pw.BoxDecoration(
                              borderRadius: pw.BorderRadius.circular(5),
                              border: pw.Border.all(
                                color: PdfColor.fromInt(primaryColor.value),
                              ),
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          child: pw.Container(
                            padding:
                                const pw.EdgeInsets.symmetric(horizontal: 10),
                            child: pw.Text(
                              e.partnerName.toString(),
                              style: pw.TextStyle(
                                font: font,
                                color: PdfColor.fromInt(primaryColor.value),
                              ),
                            ),
                            decoration: pw.BoxDecoration(
                              borderRadius: pw.BorderRadius.circular(5),
                              border: pw.Border.all(
                                color: PdfColor.fromInt(primaryColor.value),
                              ),
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          child: pw.Container(
                            padding:
                                const pw.EdgeInsets.symmetric(horizontal: 10),
                            child: pw.Text(
                              e.serviceProductName.toString(),
                              style: pw.TextStyle(
                                font: font,
                                color: PdfColor.fromInt(primaryColor.value),
                              ),
                            ),
                            decoration: pw.BoxDecoration(
                              borderRadius: pw.BorderRadius.circular(5),
                              border: pw.Border.all(
                                color: PdfColor.fromInt(primaryColor.value),
                              ),
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        pw.Expanded(
                          child: pw.Container(
                            padding:
                                const pw.EdgeInsets.symmetric(horizontal: 10),
                            child: pw.Text(
                              e.observations.toString(),
                              maxLines: 9,
                              style: pw.TextStyle(
                                font: font,
                                color: PdfColor.fromInt(primaryColor.value),
                              ),
                            ),
                            decoration: pw.BoxDecoration(
                              borderRadius: pw.BorderRadius.circular(5),
                              border: pw.Border.all(
                                color: PdfColor.fromInt(primaryColor.value),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ]),
          ],
        ),
      );
    }

    pdf.addPage(pw.Page(build: (pw.Context context) {
      return pw.Center(
          child: pw.Column(children: [
        pw.Text('Saptamana $luni - $duminica',
            style: pw.TextStyle(
                font: pw.Font.helveticaBold(),
                color: PdfColor.fromInt(primaryColor.value))),
        pw.SizedBox(height: 10),
        pw.Row(children: [
          pw.Expanded(
              child: pw.Container(
                  decoration: pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColor.fromInt(primaryColor.value),
                              width: 2))),
                  child: pw.Text('ORA',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        font: pw.Font.helveticaBold(),
                        color: PdfColor.fromInt(primaryColor.value),
                      )))),
          pw.Expanded(
              child: pw.Container(
                  decoration: pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColor.fromInt(primaryColor.value),
                              width: 2))),
                  child: pw.Text('CLIENT',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          font: pw.Font.helveticaBold(),
                          color: PdfColor.fromInt(primaryColor.value))))),
          pw.Expanded(
              child: pw.Container(
                  decoration: pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColor.fromInt(primaryColor.value),
                              width: 2))),
                  child: pw.Text('SERVICIU',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          font: pw.Font.helveticaBold(),
                          color: PdfColor.fromInt(primaryColor.value))))),
          pw.Expanded(
              child: pw.Container(
                  decoration: pw.BoxDecoration(
                      border: pw.Border(
                          bottom: pw.BorderSide(
                              color: PdfColor.fromInt(primaryColor.value),
                              width: 2))),
                  child: pw.Text('OBSERVATII',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                          font: pw.Font.helveticaBold(),
                          color: PdfColor.fromInt(primaryColor.value))))),
        ]),
        ...widget,
      ]));
    }));

    // Get the temporary directory on the device.
    final tempDir = await getTemporaryDirectory();
    String downloadHourMinute = DateFormat('HH:mm').format(DateTime.now());

    // Generate a unique filename for the PDF.
    final pdfFile = File(
        '${tempDir.path}/programari_sapt_$luni-$duminica-$downloadHourMinute.pdf');

    // Write the PDF content to the file.
    await pdfFile.writeAsBytes(await pdf.save());

    setState(() {
      _isLoading = false;
    });

    // Now you can use pdfFile to share the PDF.
    return pdfFile;
  }

  // Future<void> downloadPdf() async {
  //   final pdfFile = await _generatePdfDocument();
  //   print(pdfFile);
  //   try {
  //     const downloadDir = "/storage/emulated/0/Download";
  //     final downloadedPdfFile =
  //         await pdfFile.copy("$downloadDir/my_generated_pdf.pdf");
  //     print("Downloaded to: ${downloadedPdfFile.path}");
  //   } catch (e) {
  //     print("Error downloading PDF: $e");
  //   }
  // }

  Future<void> _sharePdf() async {
    final pdfFile = await _generatePdfDocument();
    try {
      await Share.shareFiles(
        [pdfFile.path],
        text: 'Sharing the generated PDF file',
      );
    } catch (e) {
      // Handle the share error if needed.
      // print('Error sharing PDF: $e');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getThisWeek();
  }

  @override
  Widget build(BuildContext context) {
    ///get clients/services information

    _forPdfMapList.clear();

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
          ),
        );
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            children: [
              const Text(
                'Programari',
              ),
              Text(
                widget.ownerFirmName,
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () async {
                await _sharePdf();
              },
              icon: _isLoading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const FaIcon(
                      FontAwesomeIcons.solidFilePdf,
                      color: Colors.white,
                    ),
            ),
          ],
          leading: IconButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const MainScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_back)),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    _modifyDate('-');
                  },
                  icon: Icon(
                    Icons.chevron_left,
                    color: Theme.of(context).colorScheme.primary,
                    size: 35,
                  ),
                ),
                Expanded(
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        '$monday - $sunday',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _modifyDate('+');
                  },
                  icon: Icon(
                    Icons.chevron_right,
                    color: Theme.of(context).colorScheme.primary,
                    size: 35,
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(0.0),
                child: ListView.builder(
                    itemBuilder: (ctx, index) {
                      String namedWeekDay = '';
                      String currentDate = '';
                      if (index == 0) {
                        namedWeekDay = 'Luni';
                        currentDate = monday;
                      } else if (index == 1) {
                        namedWeekDay = 'Marti';
                        currentDate = tuesday;
                      } else if (index == 2) {
                        namedWeekDay = 'Miercuri';
                        currentDate = wednesday;
                      } else if (index == 3) {
                        namedWeekDay = 'Joi';
                        currentDate = thursday;
                      } else if (index == 4) {
                        namedWeekDay = 'Vineri';
                        currentDate = friday;
                      } else if (index == 5) {
                        namedWeekDay = 'Sambata';
                        currentDate = saturday;
                      } else {
                        namedWeekDay = 'Duminica';
                        currentDate = sunday;
                      }

                      // List<TransactionModel> myList = [];
                      return StreamBuilder(
                          stream: widget.firebaseFirestore
                              .collection('appointments')
                              .orderBy('date_time', descending: false)
                              .snapshots(),
                          builder: (ctx, snapshots) {
                            if (snapshots.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            } else if (snapshots.hasError) {
                              return Text('Error: ${snapshots.error}');
                            }
                            List<TransactionModel> myList = [];
                            List<String> docIDList = [];

                            for (var snapshot in snapshots.data!.docs) {
                              var dt = DateFormat('dd/MM/yyyy').format(
                                  snapshot.data()['date_time'].toDate());
                              if (dt == currentDate &&
                                  snapshot.data()['cui'] ==
                                      widget.ownerFirmCui) {
                                String docID = snapshot.id;
                                docIDList.add(docID);
                                myList.add(TransactionModel(
                                  partnerName: snapshot.data()['partner_name'],
                                  serviceProductName:
                                      snapshot.data()['service_product_name'],
                                  price: (snapshot.data()['price'] as num?)!
                                      .toDouble(),
                                  dateTime:
                                      snapshot.data()['date_time'].toDate(),
                                  transactionSign:
                                      snapshot.data()['transaction_sign'],
                                  cui: snapshot.data()['cui'],
                                  userEmail:
                                      snapshot.data()['user_email'] as String,
                                  observations:
                                      snapshot.data()['observations'] as String,
                                  telNo: snapshot.data()['partner_tel_number'],
                                  isTransaction:
                                      snapshot.data()['is_collected'],
                                ));
                              }
                            }

                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15, vertical: 5),
                                  child: Text(
                                    '${index + 1}. $namedWeekDay $currentDate',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                ListView.builder(
                                  shrinkWrap:
                                      true, // Ensure the ListView occupies only the necessary space
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (ctx, index) {
                                    if (_forPdfMapList[currentDate] == null) {
                                      _forPdfMapList[currentDate] = [];
                                    }
                                    _forPdfMapList[currentDate] = myList;
                                    // var mySelectedDateTime = DateTime.now();
                                    return GestureDetector(
                                      onLongPress: () async {
                                        final DateTime? selectedDate =
                                            await showDatePicker(
                                          context: context,
                                          initialDate: myList[index].dateTime,
                                          firstDate: DateTime(2019, 1, 1),
                                          lastDate: DateTime(2099, 1, 1),
                                        );

                                        if (selectedDate == null) return;

                                        if (!mounted) return;

                                        final TimeOfDay? selectedTime =
                                            await showTimePicker(
                                          context: context,
                                          initialTime: TimeOfDay.fromDateTime(
                                              myList[index].dateTime),
                                        );
                                        if (selectedTime == null) {
                                          return;
                                        }
                                        var mySelectedDateTime = DateTime(
                                          selectedDate.year,
                                          selectedDate.month,
                                          selectedDate.day,
                                          selectedTime.hour,
                                          selectedTime.minute,
                                        );

                                        await widget.firebaseFirestore
                                            .collection('appointments')
                                            .doc(docIDList[index])
                                            .update({
                                          'date_time': mySelectedDateTime,
                                        });
                                      },

                                      // myList[index].dateTime = mySelectedDateTime;

                                      child: TransactionWidget(
                                        transactionModel: myList[index],
                                        firebaseFirestore:
                                            widget.firebaseFirestore,
                                        collection: 'appointments',
                                        docID: docIDList[index],
                                        userRole: widget.userRole,
                                        ownerCui: widget.ownerFirmCui,
                                      ),
                                    );
                                  },
                                  itemCount: myList.length,
                                ),
                                if (!_isLoading)
                                  TextButton.icon(
                                    onPressed: () async {
                                      List<ClientModel> clients = ref
                                          .watch(addressBookProvider.notifier)
                                          .cloudAddressBook;
                                      List<ServiceModel> services = ref
                                          .watch(addressBookProvider.notifier)
                                          .cloudServicesBook;
                                      if (context.mounted) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (ctx) => AppointmentWidget(
                                              isView: false,
                                              firebaseFirestore:
                                                  widget.firebaseFirestore,
                                              collection: 'appointments',
                                              isTransaction: false,
                                              docID: '',
                                              dateTime: DateFormat('dd/MM/yyyy')
                                                  .parse(currentDate),
                                              storedClients: clients,
                                              servicesList: services,
                                              userRole: widget.userRole,
                                              ownerCui: widget.ownerFirmCui,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Adauga'),
                                  ),
                              ],
                            );
                          });
                    },
                    itemCount: _weekDaysList.length),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
