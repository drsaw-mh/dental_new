import 'package:web/web.dart' as web;

Future<bool> launchPhoneNumberImpl(String phoneNumber) async {
  final dialableNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
  if (dialableNumber.isEmpty) {
    return false;
  }

  web.window.location.href = 'tel:$dialableNumber';
  return true;
}
