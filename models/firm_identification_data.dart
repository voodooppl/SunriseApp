class FirmIdentificationData {
  FirmIdentificationData({
    required this.firmName,
    required this.address,
    required this.isJuridic,
    required this.cui,
    required this.isTVAPayer,
    required this.telNo,
    required this.admin,
    required this.managers,
    required this.users,
    required this.notificationMessage,
  });
  final String firmName;
  final String address;
  final bool isJuridic;
  final String cui;
  final bool isTVAPayer;
  final String telNo;
  final String admin;
  final List<dynamic> managers;
  final List<dynamic> users;
  final String notificationMessage;
}
