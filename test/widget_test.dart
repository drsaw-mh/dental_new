import 'package:dental_app/dental_app/dental_user/dental_user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('starts on the default page for the login role', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const DentalApp(initialRole: RoleFilter.owner));
    await tester.pumpAndSettle();
    expect(find.text('Clinic Live Status'), findsOneWidget);

    await tester.pumpWidget(const DentalApp(initialRole: RoleFilter.admin));
    await tester.pumpAndSettle();
    expect(find.text('Clinic Live Status'), findsOneWidget);

    await tester.pumpWidget(const DentalApp(initialRole: RoleFilter.cashier));
    await tester.pumpAndSettle();
    expect(find.text('Payment Queue'), findsOneWidget);
    expect(find.text('Checkout Tools'), findsOneWidget);

    await tester.pumpWidget(const DentalApp(initialRole: RoleFilter.doctor));
    await tester.pumpAndSettle();
    expect(find.text('New Appointment'), findsOneWidget);
    expect(find.text('Available Slots'), findsOneWidget);
  });

  testWidgets('cashier can print an invoice from invoice history', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const DentalApp(initialRole: RoleFilter.cashier));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Print receipt'));
    await tester.pumpAndSettle();

    expect(find.text('Invoice History'), findsOneWidget);
    expect(find.text('INV-1048'), findsOneWidget);

    await tester.tap(find.text('Aina Rahman').first);
    await tester.pumpAndSettle();

    expect(find.text('INVOICE'), findsOneWidget);
    expect(find.text('INV-1048'), findsOneWidget);
    expect(find.text('Print'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Print'));
    await tester.pumpAndSettle();

    expect(find.text('<< Patient Info >>'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Create Invoice'), findsOneWidget);
  });

  testWidgets(
    'done closes printable invoice without printing and keeps history',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const DentalApp(initialRole: RoleFilter.cashier));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Print receipt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aina Rahman').first);
      await tester.pumpAndSettle();

      expect(find.text('INVOICE'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Done'));
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(FilledButton, 'Create Invoice'),
        findsOneWidget,
      );
      await tester.tap(find.text('Back to cash'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(OutlinedButton, 'Print receipt'));
      await tester.pumpAndSettle();

      expect(find.text('Invoice History'), findsOneWidget);
      expect(find.text('INV-1048'), findsOneWidget);
    },
  );

  testWidgets('create invoice payment list starts with clinic charges', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const DentalApp(initialRole: RoleFilter.cashier));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Create invoice'));
    await tester.pumpAndSettle();

    expect(find.text('Doctor Fee'), findsWidgets);
    expect(find.text('Service Charge'), findsWidgets);
    expect(find.text('Doctor Fees'), findsNothing);
  });

  testWidgets('print invoice includes doctor fee and service charge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const DentalApp(initialRole: RoleFilter.cashier));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Create invoice'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Name (required)'),
      'Nora Aziz',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Service Charge'),
      '50',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Doctor Fee'),
      '1850',
    );
    await tester.tap(find.text('Add Product'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ibuprofen'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('400'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tablet').last);
    await tester.pumpAndSettle();
    expect(find.text('Sell as'), findsOneWidget);
    expect(find.textContaining('Smallest'), findsWidgets);
    await tester.tap(find.byTooltip('Increase amount'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add Product'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Create Invoice'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create Invoice'));
    await tester.pumpAndSettle();

    expect(find.text('INVOICE'), findsOneWidget);
    expect(find.text('Doctor Fee'), findsOneWidget);
    expect(find.text('Service Charge'), findsOneWidget);
    expect(find.text('Quantity'), findsOneWidget);
    expect(find.text('Procedure'), findsWidgets);
    expect(find.text('RM 1850'), findsOneWidget);
    expect(find.textContaining('Tablet - Smallest x'), findsNothing);
    expect(find.text('Doctor Fees'), findsNothing);
  });

  testWidgets('Dental app shows dashboard, booking, and cashier', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const DentalApp());

    expect(find.text('DentalOps'), findsWidgets);
    expect(find.text('Today Appointments'), findsOneWidget);
    expect(find.text('Pending Follow Ups'), findsOneWidget);
    expect(find.text('Clinic Live Status'), findsOneWidget);
    expect(find.text('Queue now'), findsOneWidget);
    expect(find.text('Now Serving'), findsOneWidget);
    expect(find.text('Aina Rahman'), findsWidgets);
    expect(find.text('Next Booking'), findsOneWidget);
    expect(find.text('B-104'), findsWidgets);
    expect(find.text('Estimated Wait'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('profile-button')));
    await tester.pumpAndSettle();

    expect(find.text('Profile Overview'), findsOneWidget);
    expect(find.text('Owner Account'), findsWidgets);
    expect(find.text('Clinic Access'), findsOneWidget);
    expect(find.text('Contact Profile'), findsOneWidget);
    expect(find.text('Preferences'), findsOneWidget);

    await tester.tap(find.text('Back to app'));
    await tester.pumpAndSettle();
    expect(find.text('Clinic Live Status'), findsOneWidget);

    Future<void> openDashboardDetail(
      String metric,
      List<String> detailTexts,
    ) async {
      await tester.ensureVisible(find.text(metric).first);
      await tester.tap(find.text(metric).first);
      await tester.pumpAndSettle();

      expect(find.text('Back to dashboard'), findsOneWidget);
      for (final detailText in detailTexts) {
        expect(find.text(detailText), findsWidgets);
      }

      await tester.tap(find.text('Back to dashboard'));
      await tester.pumpAndSettle();
      expect(find.text('Clinic Live Status'), findsOneWidget);
    }

    await openDashboardDetail('Today Appointments', [
      'Aina Rahman',
      '+60 12-410 8801',
      'Dr. Wong',
    ]);
    await openDashboardDetail('Pending Follow Ups', [
      'Ben Tan',
      '+60 12-550 7712',
      'Dr. Lee',
    ]);
    await tester.ensureVisible(find.text('Cash Collected').first);
    await tester.tap(find.text('Cash Collected').first);
    await tester.pumpAndSettle();

    expect(find.text('Paid today detail'), findsOneWidget);
    expect(find.text('Aina Rahman'), findsWidgets);
    expect(find.text('RM 280'), findsWidgets);

    await tester.tap(find.text('Pending').first);
    await tester.pumpAndSettle();
    expect(find.text('Pending cash detail'), findsOneWidget);
    expect(find.text('Ravi Kumar'), findsWidgets);
    expect(find.text('Deposit due'), findsWidgets);

    await tester.tap(find.text('Invoices').first);
    await tester.pumpAndSettle();
    expect(find.text('Invoice list'), findsOneWidget);
    expect(find.text('INV-1051'), findsWidgets);

    await tester.tap(find.text('Back to dashboard'));
    await tester.pumpAndSettle();
    expect(find.text('Clinic Live Status'), findsOneWidget);

    await openDashboardDetail('Active Procedures', ['Root Canal']);

    Future<void> openBottomPage(String label, String expectedText) async {
      await tester.tap(find.byKey(ValueKey('nav-$label')));
      await tester.pumpAndSettle();
      expect(find.text(expectedText), findsWidgets);
    }

    await openBottomPage('Users', 'Users & Roles');
    expect(find.text('New User'), findsOneWidget);
    expect(find.text('Aina Rahman'), findsWidgets);
    expect(find.text('Ben Tan'), findsNothing);
    await openBottomPage('Patients', 'Patients');
    expect(find.text('Search patients'), findsOneWidget);
    await tester.ensureVisible(find.text('Ben Tan').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ben Tan').first);
    await tester.pumpAndSettle();

    expect(find.text('Patient Record'), findsOneWidget);
    expect(find.text('Appointment History'), findsOneWidget);
    expect(find.text('Treatment & Procedures'), findsOneWidget);
    expect(find.text('Billing & Pharmacy'), findsOneWidget);
    expect(find.text('Root Canal'), findsWidgets);
    expect(
      find.text('Pain score check after root canal review'),
      findsOneWidget,
    );

    await tester.tap(find.text('Back to patients'));
    await tester.pumpAndSettle();
    expect(find.text('Patients'), findsWidgets);
    await openBottomPage('Users', 'Users & Roles');

    await tester.tap(find.widgetWithText(FilledButton, 'New User'));
    await tester.pumpAndSettle();

    expect(find.text('Create User'), findsOneWidget);
    expect(find.text('Created by role'), findsOneWidget);
    expect(find.text('New user role'), findsOneWidget);
    expect(find.text('Users can create User role only'), findsOneWidget);

    expect(find.widgetWithText(TextField, 'Name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Age'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Phone'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Address'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Maya User');
    await tester.enterText(find.widgetWithText(TextField, 'Age'), '29');
    await tester.enterText(
      find.widgetWithText(TextField, 'Phone'),
      '+60 12-700 1111',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Address'),
      '12 Jalan Klinik',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Status'), 'Active');

    await tester.tap(find.widgetWithText(FilledButton, 'Create User'));
    await tester.pumpAndSettle();

    expect(find.text('Maya User'), findsOneWidget);
    expect(find.text('Age 29'), findsOneWidget);
    expect(find.text('+60 12-700 1111'), findsOneWidget);
    expect(find.text('12 Jalan Klinik'), findsOneWidget);
    expect(find.text('User'), findsWidgets);

    await tester.tap(find.widgetWithText(FilledButton, 'New User'));
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<RoleFilter>), findsNWidgets(2));
    await tester.tap(find.byType(DropdownButtonFormField<RoleFilter>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Owner').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<RoleFilter>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Admin').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextField, 'Name'),
      'Security Admin',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Age'), '37');
    await tester.enterText(
      find.widgetWithText(TextField, 'Phone'),
      '+60 12-800 2222',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Address'),
      'Admin Office',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Status'),
      'Operations',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Create User'));
    await tester.pumpAndSettle();

    expect(find.text('Security Admin'), findsOneWidget);
    expect(find.text('Age 37'), findsOneWidget);
    expect(find.text('+60 12-800 2222'), findsOneWidget);
    expect(find.text('Admin Office'), findsOneWidget);
    expect(find.text('Admin'), findsWidgets);

    await openBottomPage('Doctors', 'Dr. Marcus Lee');
    await openBottomPage('Follow Up', 'Follow Up Board');
    expect(find.widgetWithText(TextField, 'Patient name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Doctor'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Speciality'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Patient name'),
      'Ben',
    );
    await tester.pumpAndSettle();
    expect(find.text('Ben Tan'), findsOneWidget);
    expect(find.text('Mei Chen'), findsNothing);
    await tester.enterText(find.widgetWithText(TextField, 'Doctor'), 'Lee');
    await tester.pumpAndSettle();
    expect(find.text('Dr. Lee'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Speciality'),
      'Orthodontics',
    );
    await tester.pumpAndSettle();
    expect(find.text('Orthodontics'), findsWidgets);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Clear'));
    await tester.pumpAndSettle();
    expect(find.text('Mei Chen'), findsWidgets);
    await openBottomPage('Products', 'Dispensing Queue');
    expect(find.text('Products Inventory'), findsOneWidget);
    expect(find.text('Products Tools'), findsOneWidget);
    expect(find.text('Products Cashier'), findsOneWidget);
    expect(find.text('Products Checkout'), findsOneWidget);
    expect(find.text('Create medicine invoice'), findsOneWidget);
    expect(find.text('Record medicine payment'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Add product'));
    await tester.pumpAndSettle();
    expect(find.text('Add Product'), findsWidgets);
    expect(find.widgetWithText(TextField, 'Product name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Subclass'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Child class'), findsOneWidget);
    expect(
      find.widgetWithText(TextField, 'Category (optional)'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextField, 'Tag (optional)'), findsOneWidget);
    expect(find.text('Price nature'), findsOneWidget);
    expect(find.text('Add price nature'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Price'), findsWidgets);
    expect(find.text('Discount type'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Product name'),
      'Blumox',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Subclass'), '500');
    await tester.enterText(
      find.widgetWithText(TextField, 'Child class'),
      'Capsule',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Category (optional)'),
      'Antibiotic',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Tag (optional)'),
      'Prescription',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Price').first,
      '100',
    );
    await tester.tap(find.text('No discount'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Net Price').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Net Price'), '85');
    await tester.enterText(find.widgetWithText(TextField, 'Stock'), '30');
    await tester.enterText(find.widgetWithText(TextField, 'Capacity'), '60');
    await tester.enterText(
      find.widgetWithText(TextField, 'Unit').last,
      'bottles',
    );
    await tester.enterText(find.widgetWithText(TextField, 'Batch'), 'DR-001');
    await tester.enterText(
      find.widgetWithText(TextField, 'Expiry'),
      'Dec 2028',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add Product'));
    await tester.pumpAndSettle();
    expect(find.text('Blumox 500 Capsule'), findsWidgets);
    expect(find.text('RM 85'), findsOneWidget);
    expect(find.text('Net price RM 85 from RM 100'), findsOneWidget);
    expect(find.text('Prescription'), findsOneWidget);
    expect(find.text('Blumox 500 Capsule'), findsWidgets);

    expect(find.text('Drug Detail'), findsOneWidget);
    expect(find.text('Batch & Expiry'), findsOneWidget);
    expect(find.text('Batch number'), findsOneWidget);
    expect(find.text('DR-001'), findsWidgets);
    expect(find.text('Drug Actions'), findsOneWidget);
    expect(find.text('Dispense drug'), findsOneWidget);

    await tester.tap(find.text('Back to pharmacy'));
    await tester.pumpAndSettle();
    expect(find.text('Products Inventory'), findsOneWidget);
    await openBottomPage('Dashboard', 'Clinic Live Status');
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.event_available_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('New Appointment'), findsOneWidget);
    expect(find.text('Available Slots'), findsOneWidget);
    expect(find.text('Book appointment'), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, 'Book appointment'),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextField, 'Patient age'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Phone number'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Patient age'), '32');
    await tester.enterText(
      find.widgetWithText(TextField, 'Phone number'),
      '+60 12-410 8801',
    );
    expect(find.text('32'), findsOneWidget);
    expect(find.text('+60 12-410 8801'), findsWidgets);
    expect(find.widgetWithText(TextField, 'Doctor'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Doctor'), 'Priya');
    await tester.pumpAndSettle();
    expect(find.text('Dr. Priya Menon'), findsWidgets);
    await tester.tap(find.text('Dr. Priya Menon').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Choose doctor from Doctor Page'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Search Doctor'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Procedure'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Procedure'), 'Root');
    await tester.pumpAndSettle();
    expect(find.text('Root Canal'), findsWidgets);
    await tester.tap(find.text('Root Canal').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Choose procedure from Procedure Page'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Search Procedure'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Date and time'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Date and time'),
      'Tomorrow, 10:45',
    );
    expect(find.text('Tomorrow, 10:45'), findsOneWidget);
    await tester.tap(find.byTooltip('Pick appointment date'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Pick appointment time'));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Booking Patients'));
    await tester.pumpAndSettle();
    expect(find.text('Booking Patients'), findsOneWidget);
    expect(find.text('4 patients'), findsOneWidget);
    expect(find.text('+60 12-550 7712'), findsWidgets);
    await tester.ensureVisible(find.text('Aina Rahman').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aina Rahman').first);
    await tester.pumpAndSettle();

    expect(find.text('Appointment Detail'), findsOneWidget);
    expect(find.text('+60 12-410 8801'), findsWidgets);
    expect(find.text('Scaling and polish'), findsWidgets);
    expect(find.text('Dr. Wong'), findsWidgets);
    expect(find.text('Confirmed'), findsOneWidget);

    await tester.tap(find.text('Back to booking'));
    await tester.pumpAndSettle();
    expect(find.text('Appointment Queue'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.point_of_sale_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Payment Queue'), findsOneWidget);
    expect(find.text('Checkout Tools'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Create invoice'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Name (required)'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Invoice Number'), findsOneWidget);
    expect(find.text('Payment method'), findsOneWidget);
    expect(find.text('WalletPay'), findsNothing);
    expect(find.widgetWithText(TextField, 'Status'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'PAY Amount'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Follow Up'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Name (required)'),
      'Nora Aziz',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Invoice Number'),
      'INV-1052',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Status'),
      'Ready to pay',
    );
    await tester.enterText(find.widgetWithText(TextField, 'PAY Amount'), '950');
    await tester.enterText(
      find.widgetWithText(TextField, 'Follow Up'),
      'Root canal balance',
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Create Invoice'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Create Invoice'));
    await tester.pumpAndSettle();

    expect(find.text('INVOICE'), findsOneWidget);
    expect(find.text('Nora Aziz'), findsWidgets);
    expect(find.text('INV-1052'), findsWidgets);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back to cash'));
    await tester.pumpAndSettle();

    expect(find.text('Payment Queue'), findsOneWidget);
    expect(find.text('Nora Aziz'), findsOneWidget);
    expect(find.text('INV-1052'), findsOneWidget);
    expect(find.text('Cash'), findsWidgets);
    expect(find.text('RM 950'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Record payment'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Record Payment'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'PAY Amount'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Payment Date'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Reference Number'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Follow Up'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Name (required)'),
      'Nora Aziz',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Invoice Number'),
      'INV-1052',
    );
    await tester.enterText(find.widgetWithText(TextField, 'PAY Amount'), '950');
    await tester.enterText(
      find.widgetWithText(TextField, 'Payment Date'),
      'Today',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Reference Number'),
      'PAY-2041',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Follow Up'),
      'Paid by card',
    );
    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'Record Payment'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Record Payment'));
    await tester.pumpAndSettle();

    expect(find.text('Payment Queue'), findsOneWidget);
    expect(find.text('Paid today'), findsWidgets);
    expect(find.text('Cash'), findsWidgets);

    await openBottomPage('Procedure', 'Procedure Pipeline');
    expect(find.text('New Procedure'), findsOneWidget);
    expect(find.text('Owner/Admin CRUD'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Edit'), findsWidgets);
    expect(find.widgetWithText(OutlinedButton, 'Delete'), findsWidgets);
    expect(find.text('Braces Plan'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Delete').last);
    await tester.pumpAndSettle();
    expect(find.text('Braces Plan'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'New Procedure'));
    await tester.pumpAndSettle();

    expect(find.text('Create Procedure'), findsWidgets);
    expect(find.widgetWithText(TextField, 'First step'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Second step'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Third step'), findsOneWidget);
    expect(find.text('Discount type'), findsOneWidget);

    expect(find.widgetWithText(TextField, 'Procedure name'), findsNothing);
    expect(
      find.widgetWithText(TextField, 'Procedure name - first step (optional)'),
      findsNothing,
    );
    expect(find.widgetWithText(TextField, 'Patient'), findsNothing);
    expect(find.widgetWithText(TextField, 'Stage'), findsNothing);
    expect(find.widgetWithText(TextField, 'Doctor'), findsNothing);
    await tester.enterText(find.widgetWithText(TextField, 'Price'), '950');
    await tester.tap(find.text('No discount'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Percent %').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Discount %'), '10');
    await tester.enterText(
      find.widgetWithText(TextField, 'Estimated time'),
      '50 min',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'First step'),
      'Therapeutic',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Second step'),
      'Endodontics',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Third step'),
      'Root canal',
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Create Procedure'));
    await tester.pumpAndSettle();

    expect(find.text('Complete all procedure fields'), findsNothing);
    expect(find.text('Root canal'), findsWidgets);
    expect(find.text('Nora Aziz'), findsNothing);
    expect(find.text('RM 855'), findsOneWidget);
    expect(find.text('10% discount from RM 950'), findsOneWidget);
    expect(find.text('Estimated time: 50 min'), findsOneWidget);
    expect(find.text('Therapeutic / Endodontics / Root canal'), findsOneWidget);
    await tester.tap(find.widgetWithText(OutlinedButton, 'Edit').first);
    await tester.pumpAndSettle();

    expect(find.text('Edit Procedure'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'First step'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Price'), '1050');
    await tester.tap(find.widgetWithText(FilledButton, 'Update Procedure'));
    await tester.pumpAndSettle();

    expect(find.text('10% discount from RM 1050'), findsOneWidget);
  });
}
