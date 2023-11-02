class UserInformation {
  UserInformation({
    required this.loggedUser,
    required this.alias,
    required this.userFirms,
  });

  final String loggedUser;
  late final String alias;
  final List<dynamic> userFirms;
}
