import 'package:web/web.dart' as web;

Future<bool> launchPrintDialogImpl() async {
  web.window.print();
  return true;
}
