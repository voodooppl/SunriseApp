String displayErrorMessages(e) {
  late String errorMessage;
  if (e.toString() ==
      '[firebase_auth/invalid-email] The email address is badly formatted.') {
    errorMessage = 'Error: The email address is badly formatted.';
  } else if (e.toString() ==
      '[firebase_auth/user-not-found] There is no user record corresponding to this identifier. The user may have been deleted.') {
    errorMessage = 'Error: The user does not exist or may have been deleted.';
  } else if (e.toString() ==
      '[firebase_auth/wrong-password] The password is invalid or the user does not have a password.') {
    errorMessage = 'Error: The password is invalid';
  } else if (e.toString() ==
      "LateInitializationError: Field 'email' has not been initialized.") {
    errorMessage = 'Error: Please fill in the email.';
  } else if (e.toString() ==
      "LateInitializationError: Field 'password' has not been initialized.") {
    errorMessage = 'Error: Please fill in the password.';
  } else if (e.toString() ==
      '[firebase_auth/email-already-in-use] The email address is already in use by another account.') {
    errorMessage =
        'Error: The email address is already in use by another account.';
  } else if (e.toString() ==
      '[firebase_auth/weak-password] Password should be at least 6 characters') {
    errorMessage = 'Error: Password should be at least 6 characters.';
  } else if (e.toString() ==
      '[firebase_auth/unknown] Given String is empty or null') {
    errorMessage = 'Error: Your input is empty or null.';
  } else {
    errorMessage = e.toString();
  }
  return errorMessage;
}
