class ClientModel {
  ClientModel({
    this.isJuridic,
    this.address,
    this.cui,
    this.isTVAPayer,
    required this.name,
    required this.telNo,
    required this.loggedUserEmail,
    required this.ownerFirm,
  });
  final String name;
  final String telNo;
  final String loggedUserEmail;
  final String ownerFirm;
  bool? isJuridic = false;
  String? address = '';
  String? cui = '';
  bool? isTVAPayer = false;
}
