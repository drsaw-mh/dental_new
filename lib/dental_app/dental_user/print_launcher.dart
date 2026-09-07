import 'print_launcher_stub.dart'
    if (dart.library.html) 'print_launcher_web.dart';

Future<bool> launchPrintDialog() {
  return launchPrintDialogImpl();
}
