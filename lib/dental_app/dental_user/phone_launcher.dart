import 'phone_launcher_stub.dart'
    if (dart.library.html) 'phone_launcher_web.dart';

Future<bool> launchPhoneNumber(String phoneNumber) {
  return launchPhoneNumberImpl(phoneNumber);
}
