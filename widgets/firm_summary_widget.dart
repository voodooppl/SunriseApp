import 'package:flutter/material.dart';

class FirmSummaryWidget extends StatelessWidget {
  const FirmSummaryWidget(
      {required this.date,
      required this.firmName,
      required this.income,
      required this.outcome,
      required this.monthlyBalance,
      required this.yearlyBalance,
      Key? key})
      : super(key: key);

  final DateTime date;
  final String firmName;
  final double income;
  final double outcome;
  final double monthlyBalance;
  final double yearlyBalance;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Container(
            margin:
                const EdgeInsets.only(left: 10, right: 2.5, top: 5, bottom: 5),
            child: Card(
              elevation: 2,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sold ${date.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    Text(
                      yearlyBalance.toStringAsFixed(2),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin:
                const EdgeInsets.only(left: 2.5, right: 10, top: 5, bottom: 5),
            // height: 150,
            // width: 150,
            child: Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      'Incasari : $income',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    Text(
                      'Plati : $outcome',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    Text(
                      'Sold : $monthlyBalance',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}
