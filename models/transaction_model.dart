class TransactionModel {
  TransactionModel({
    required this.partnerName,
    required this.serviceProductName,
    required this.price,
    required this.dateTime,
    required this.transactionSign,
    required this.cui,
    required this.userEmail,
    required this.observations,
    // this.docID,
    required this.telNo,
    required this.isTransaction,
  });

  final String partnerName;
  final String serviceProductName;
  final double price;
  final DateTime dateTime;
  final String transactionSign;
  final String cui;
  final String userEmail;
  final String observations;
  // final String? docID;
  final String telNo;
  final bool isTransaction;
}
