import 'package:flutter/material.dart';

import '../../frontend/features/project_history/view_models/project_history_view_model.dart';
import 'phone_launcher.dart';
import 'print_launcher.dart';

Future<void> _openPhoneNumber(BuildContext context, String phoneNumber) async {
  final opened = await launchPhoneNumber(phoneNumber);

  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Phone dialing is not available here')),
    );
  }
}

class DentalApp extends StatelessWidget {
  const DentalApp({super.key, this.initialRole = RoleFilter.owner});

  final RoleFilter initialRole;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF0B7285);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DentalOps',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: const Color(0xFF17212B),
          displayColor: const Color(0xFF17212B),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: Color(0xFFE1E7EC)),
          ),
        ),
      ),
      home: ClinicShell(initialRole: initialRole),
    );
  }
}

class ClinicShell extends StatefulWidget {
  const ClinicShell({super.key, this.initialRole = RoleFilter.owner});

  final RoleFilter initialRole;

  @override
  State<ClinicShell> createState() => _ClinicShellState();
}

class _ClinicShellState extends State<ClinicShell> {
  int selectedIndex = 0;
  RoleFilter selectedRole = RoleFilter.all;
  var users = [...sampleUsers];
  var procedures = [...sampleProcedures];
  var projectHistoryInvoices = <Invoice>[];
  final projectHistoryViewModel = ProjectHistoryViewModel();
  var showProfile = false;

  final pages = const [
    _NavigationItem(
      Icons.dashboard_outlined,
      Icons.dashboard,
      'Dashboard',
      'Dash',
    ),
    _NavigationItem(
      Icons.people_alt_outlined,
      Icons.people_alt,
      'Users',
      'Users',
    ),
    _NavigationItem(
      Icons.event_available_outlined,
      Icons.event_available,
      'Booking',
      'Book',
    ),
    _NavigationItem(Icons.groups_2_outlined, Icons.groups_2, 'Queue', 'Queue'),
    _NavigationItem(
      Icons.medical_services_outlined,
      Icons.medical_services,
      'Doctors',
      'Doctors',
    ),
    _NavigationItem(
      Icons.point_of_sale_outlined,
      Icons.point_of_sale,
      'Cashier',
      'Cash',
    ),
    _NavigationItem(
      Icons.event_repeat_outlined,
      Icons.event_repeat,
      'Follow Up',
      'Follow',
    ),
    _NavigationItem(
      Icons.local_pharmacy_outlined,
      Icons.local_pharmacy,
      'Products',
      'Products',
    ),
    _NavigationItem(Icons.healing_outlined, Icons.healing, 'Procedure', 'Proc'),
    _NavigationItem(
      Icons.work_outline,
      Icons.work,
      'Project History',
      'History',
    ),
  ];

  @override
  void initState() {
    super.initState();
    selectedIndex = _defaultPageIndexForRole(widget.initialRole);
    loadProjectHistory();
  }

  @override
  void dispose() {
    projectHistoryViewModel.dispose();
    super.dispose();
  }

  Future<void> loadProjectHistory() async {
    await projectHistoryViewModel.load();
    if (!mounted) {
      return;
    }

    setState(() {
      projectHistoryInvoices = projectHistoryViewModel.records
          .map(Invoice.fromProjectHistoryJson)
          .toList();
    });
  }

  Future<void> saveProjectHistoryInvoice(Invoice invoice) async {
    setState(() {
      projectHistoryInvoices = [invoice, ...projectHistoryInvoices];
      showProfile = false;
    });

    await projectHistoryViewModel.save(invoice.toProjectHistoryJson());
    if (!mounted) {
      return;
    }

    setState(() {
      projectHistoryInvoices = projectHistoryViewModel.records
          .map(Invoice.fromProjectHistoryJson)
          .toList();
    });
  }

  @override
  void didUpdateWidget(covariant ClinicShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRole != widget.initialRole) {
      selectedIndex = _defaultPageIndexForRole(widget.initialRole);
      showProfile = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              _SideNav(
                items: pages,
                selectedIndex: selectedIndex,
                onSelected: (index) => setState(() {
                  selectedIndex = index;
                  showProfile = false;
                }),
              ),
            Expanded(
              child: _ClinicPage(
                title: pages[selectedIndex].label,
                selectedIndex: selectedIndex,
                showProfile: showProfile,
                onProfilePressed: () => setState(() => showProfile = true),
                onProfileBack: () => setState(() => showProfile = false),
                selectedRole: selectedRole,
                onRoleChanged: (role) => setState(() => selectedRole = role),
                users: users,
                onUserAdded: (user) {
                  setState(() => users = [user, ...users]);
                },
                procedures: procedures,
                onProcedureAdded: (procedure) {
                  setState(() => procedures = [procedure, ...procedures]);
                },
                onProcedureUpdated: (index, procedure) {
                  setState(() {
                    procedures = [...procedures]..[index] = procedure;
                  });
                },
                onProcedureDeleted: (index) {
                  setState(() {
                    procedures = [...procedures]..removeAt(index);
                  });
                },
                projectHistoryInvoices: projectHistoryInvoices,
                onProjectInvoiceCreated: saveProjectHistoryInvoice,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => setState(() {
                selectedIndex = index;
                showProfile = false;
              }),
              destinations: [
                for (final item in pages)
                  NavigationDestination(
                    key: ValueKey('nav-${item.label}'),
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: item.shortLabel,
                    tooltip: item.label,
                  ),
              ],
            ),
    );
  }
}

int _defaultPageIndexForRole(RoleFilter role) {
  return switch (role) {
    RoleFilter.cashier => 5,
    RoleFilter.doctor => 2,
    RoleFilter.admin || RoleFilter.owner => 0,
    RoleFilter.all || RoleFilter.user => 0,
  };
}

class _ClinicPage extends StatelessWidget {
  const _ClinicPage({
    required this.title,
    required this.selectedIndex,
    required this.showProfile,
    required this.onProfilePressed,
    required this.onProfileBack,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.users,
    required this.onUserAdded,
    required this.procedures,
    required this.onProcedureAdded,
    required this.onProcedureUpdated,
    required this.onProcedureDeleted,
    required this.projectHistoryInvoices,
    required this.onProjectInvoiceCreated,
  });

  final String title;
  final int selectedIndex;
  final bool showProfile;
  final VoidCallback onProfilePressed;
  final VoidCallback onProfileBack;
  final RoleFilter selectedRole;
  final ValueChanged<RoleFilter> onRoleChanged;
  final List<ClinicUser> users;
  final ValueChanged<ClinicUser> onUserAdded;
  final List<DentalProcedure> procedures;
  final ValueChanged<DentalProcedure> onProcedureAdded;
  final void Function(int index, DentalProcedure procedure) onProcedureUpdated;
  final ValueChanged<int> onProcedureDeleted;
  final List<Invoice> projectHistoryInvoices;
  final ValueChanged<Invoice> onProjectInvoiceCreated;

  @override
  Widget build(BuildContext context) {
    final content = showProfile
        ? ProfileView(onBack: onProfileBack)
        : switch (selectedIndex) {
            0 => const DashboardView(),
            1 => UsersView(
              selectedRole: selectedRole,
              onRoleChanged: onRoleChanged,
              users: users,
            ),
            2 => const BookingView(),
            3 => const QueueView(),
            4 => const DoctorsView(),
            5 => CashierView(onProjectInvoiceCreated: onProjectInvoiceCreated),
            6 => const FollowUpView(),
            7 => const PharmacyView(),
            8 => ProcedureView(
              users: users,
              procedures: procedures,
              onProcedureUpdated: onProcedureUpdated,
              onProcedureDeleted: onProcedureDeleted,
            ),
            _ => ProjectsView(projectInvoices: projectHistoryInvoices),
          };
    final action = switch (selectedIndex) {
      1 => _HeaderAction(
        icon: Icons.person_add_alt_1,
        label: 'New User',
        onPressed: () async {
          final user = await showDialog<ClinicUser>(
            context: context,
            builder: (context) => const _NewUserDialog(),
          );

          if (user == null || !context.mounted) {
            return;
          }

          onUserAdded(user);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${user.name} added')));
        },
      ),
      8 => _HeaderAction(
        icon: Icons.add,
        label: 'New Procedure',
        onPressed: () async {
          final procedure = await showDialog<DentalProcedure>(
            context: context,
            builder: (context) => const _NewProcedureDialog(),
          );

          if (procedure == null || !context.mounted) {
            return;
          }

          onProcedureAdded(procedure);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${procedure.name} added')));
        },
      ),
      _ => null,
    };

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _Header(
            title: showProfile ? 'Profile' : title,
            action: showProfile ? null : action,
            onProfilePressed: onProfilePressed,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverToBoxAdapter(child: content),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.onProfilePressed,
    this.action,
  });

  final String title;
  final _HeaderAction? action;
  final VoidCallback onProfilePressed;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 620;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: compact ? double.infinity : 360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DentalOps',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: action == null ? 520 : 680),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Flexible(child: _HeaderSearchField()),
                if (action != null) ...[
                  const SizedBox(width: 10),
                  FilledButton.icon(
                    onPressed: action!.onPressed,
                    icon: Icon(action!.icon),
                    label: Text(action!.label),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 10),
                Tooltip(
                  message: 'Profile',
                  child: IconButton.filledTonal(
                    key: const ValueKey('profile-button'),
                    onPressed: onProfilePressed,
                    icon: const Icon(Icons.person),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderSearchField extends StatelessWidget {
  const _HeaderSearchField();

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search patient, invoice, doctor, project',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          tooltip: 'Filters',
          onPressed: () {},
          icon: const Icon(Icons.tune),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDCE3EA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDCE3EA)),
        ),
      ),
    );
  }
}

class _HeaderAction {
  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  DashboardDetail? selectedDetail;

  @override
  Widget build(BuildContext context) {
    final detail = selectedDetail;
    if (detail != null) {
      return _DashboardDetailView(
        detail: detail,
        onBack: () => setState(() => selectedDetail = null),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Panel(
          title: 'Clinic Live Status',
          action: 'Queue now',
          child: Column(
            children: [
              _ResponsiveGrid(
                compactMinTileWidth: 150,
                compactAspectRatio: 1.12,
                minTileWidth: 170,
                wideAspectRatio: 1.35,
                children: const [
                  _ClinicStatusCard(
                    title: 'Now Serving',
                    value: 'B-103',
                    detail: 'Aina Rahman',
                    icon: Icons.campaign_outlined,
                    color: Color(0xFFC2410C),
                  ),
                  _ClinicStatusCard(
                    title: 'Next Booking',
                    value: 'B-104',
                    detail: 'Ben Tan - 10:15',
                    icon: Icons.skip_next_outlined,
                    color: Color(0xFF0B7285),
                  ),
                  _ClinicStatusCard(
                    title: 'Estimated Wait',
                    value: '14m',
                    detail: 'For waiting patients',
                    icon: Icons.timer_outlined,
                    color: Color(0xFF166534),
                  ),
                  _ClinicStatusCard(
                    title: 'Queue Count',
                    value: '17',
                    detail: '8 waiting, 9 in chair',
                    icon: Icons.groups_2_outlined,
                    color: Color(0xFF7C3AED),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _QueueFlow(items: sampleQueueStatuses),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _ResponsiveGrid(
          compactMinTileWidth: 170,
          compactAspectRatio: 0.95,
          minTileWidth: 210,
          wideAspectRatio: 1.15,
          children: [
            _MetricCard(
              'Today Appointments',
              '38',
              '+12%',
              Icons.calendar_month,
              const Color(0xFF0B7285),
              onTap: () =>
                  setState(() => selectedDetail = DashboardDetail.appointments),
            ),
            _MetricCard(
              'Pending Follow Ups',
              '14',
              '6 urgent',
              Icons.event_repeat,
              const Color(0xFFC2410C),
              onTap: () =>
                  setState(() => selectedDetail = DashboardDetail.followUps),
            ),
            _MetricCard(
              'Cash Collected',
              'RM 18,420',
              '+8%',
              Icons.payments,
              const Color(0xFF166534),
              onTap: () =>
                  setState(() => selectedDetail = DashboardDetail.cash),
            ),
            _MetricCard(
              'Active Procedures',
              '27',
              '9 in chair',
              Icons.healing,
              const Color(0xFF7C3AED),
              onTap: () =>
                  setState(() => selectedDetail = DashboardDetail.procedures),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _TwoColumn(
          left: _Panel(
            title: 'Live Chair Schedule',
            action: 'Today',
            child: Column(
              children: [
                for (final appointment in sampleAppointments)
                  _AppointmentTile(appointment: appointment),
              ],
            ),
          ),
          right: _Panel(
            title: 'Operations Pulse',
            action: 'Clinic',
            child: Column(
              children: const [
                _ProgressRow(
                  label: 'Doctor utilization',
                  value: 0.82,
                  detail: '82%',
                ),
                _ProgressRow(
                  label: 'Procedure room load',
                  value: 0.64,
                  detail: '64%',
                ),
                _ProgressRow(
                  label: 'Cashier queue cleared',
                  value: 0.71,
                  detail: '17 / 24',
                ),
                _ProgressRow(
                  label: 'Follow-up completion',
                  value: 0.58,
                  detail: '58%',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    const profileColor = Color(0xFF0B7285);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to app'),
        ),
        const SizedBox(height: 8),
        _TwoColumn(
          left: _Panel(
            title: 'Profile Overview',
            action: 'Owner',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: profileColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'OA',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Owner Account',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          const Text('Clinic owner - full access'),
                          const SizedBox(height: 8),
                          const _StatusPill(
                            label: 'Active profile',
                            color: profileColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _DetailSummaryRow(
                  items: [
                    DetailSummary('Role', 'Owner', Color(0xFF0B7285)),
                    DetailSummary('Today', '38 visits', Color(0xFF166534)),
                    DetailSummary('Access', 'Full', Color(0xFF7C3AED)),
                  ],
                ),
              ],
            ),
          ),
          right: _Panel(
            title: 'Clinic Access',
            action: 'Permissions',
            child: const Column(
              children: [
                _ProfileLine(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'User management',
                  value: 'Admin, Owner',
                ),
                _ProfileLine(
                  icon: Icons.point_of_sale_outlined,
                  label: 'Cashier tools',
                  value: 'Allowed',
                ),
                _ProfileLine(
                  icon: Icons.medical_services_outlined,
                  label: 'Clinical records',
                  value: 'Allowed',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _TwoColumn(
          left: _Panel(
            title: 'Contact Profile',
            action: 'Account',
            child: const Column(
              children: [
                _ProfileLine(
                  icon: Icons.call_outlined,
                  label: 'Phone',
                  value: '+60 12-555 0108',
                ),
                _ProfileLine(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  value: 'owner@dentalops.local',
                ),
                _ProfileLine(
                  icon: Icons.home_outlined,
                  label: 'Address',
                  value: 'Owner suite',
                ),
              ],
            ),
          ),
          right: _Panel(
            title: 'Preferences',
            action: 'Clinic',
            child: const Column(
              children: [
                _ProfileLine(
                  icon: Icons.notifications_active_outlined,
                  label: 'Follow up alerts',
                  value: 'On',
                ),
                _ProfileLine(
                  icon: Icons.schedule_outlined,
                  label: 'Queue updates',
                  value: 'Live',
                ),
                _ProfileLine(
                  icon: Icons.language_outlined,
                  label: 'Language',
                  value: 'English',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E7EC)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF52606D)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF667085),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardDetailView extends StatelessWidget {
  const _DashboardDetailView({required this.detail, required this.onBack});

  final DashboardDetail detail;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to dashboard'),
        ),
        const SizedBox(height: 8),
        switch (detail) {
          DashboardDetail.appointments => _Panel(
            title: 'Today Appointments',
            action: '${sampleAppointments.length} booked',
            child: const _AppointmentDashboardDetail(),
          ),
          DashboardDetail.followUps => _Panel(
            title: 'Pending Follow Ups',
            action: '6 urgent',
            child: const _FollowUpDashboardDetail(),
          ),
          DashboardDetail.cash => const _CashDashboardDetail(),
          DashboardDetail.procedures => _Panel(
            title: 'Active Procedures',
            action: '9 in chair',
            child: const _ProcedureDashboardDetail(),
          ),
        },
      ],
    );
  }
}

class _AppointmentDashboardDetail extends StatefulWidget {
  const _AppointmentDashboardDetail();

  @override
  State<_AppointmentDashboardDetail> createState() =>
      _AppointmentDashboardDetailState();
}

class _AppointmentDashboardDetailState
    extends State<_AppointmentDashboardDetail> {
  final detailScrollController = ScrollController();
  AppointmentStatusFilter selectedFilter = AppointmentStatusFilter.inChair;
  AppointmentStatusDetail? selectedDetail;

  List<AppointmentStatusDetail> get visibleDetails {
    return sampleAppointmentStatusDetails
        .where((item) => item.filter == selectedFilter)
        .toList();
  }

  @override
  void dispose() {
    detailScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedPatient = selectedDetail;
    if (selectedPatient != null) {
      return _AppointmentStatusPatientDetail(
        detail: selectedPatient,
        onBack: () => setState(() => selectedDetail = null),
      );
    }

    final details = visibleDetails;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailSummaryRow(
          items: [
            for (final filter in AppointmentStatusFilter.values)
              DetailSummary(
                filter.label,
                filter.count,
                filter.color,
                selected: selectedFilter == filter,
                onTap: () {
                  setState(() {
                    selectedFilter = filter;
                    selectedDetail = null;
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          selectedFilter.detailTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 420,
          child: Scrollbar(
            controller: detailScrollController,
            thumbVisibility: true,
            child: ListView.builder(
              controller: detailScrollController,
              padding: EdgeInsets.zero,
              itemCount: details.length,
              itemBuilder: (context, index) {
                final detail = details[index];

                return Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => selectedDetail = detail),
                    child: _ContactDetailBlock(
                      leading: detail.filter.icon,
                      title: detail.patient,
                      phone: detail.phone,
                      details:
                          '${detail.bookingId} - ${detail.time} - ${detail.procedure} - ${detail.note}',
                      doctor: detail.doctor,
                      color: detail.filter.color,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _AppointmentStatusPatientDetail extends StatelessWidget {
  const _AppointmentStatusPatientDetail({
    required this.detail,
    required this.onBack,
  });

  final AppointmentStatusDetail detail;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to patients'),
        ),
        const SizedBox(height: 8),
        _ContactDetailBlock(
          leading: detail.filter.icon,
          title: detail.patient,
          phone: detail.phone,
          details: '${detail.bookingId} - ${detail.procedure}',
          doctor: detail.doctor,
          color: detail.filter.color,
        ),
        const SizedBox(height: 8),
        _DetailSummaryRow(
          items: [
            DetailSummary('Booking', detail.bookingId, detail.filter.color),
            DetailSummary('Time', detail.time, const Color(0xFF0B7285)),
            DetailSummary('Status', detail.filter.label, detail.filter.color),
          ],
        ),
        const SizedBox(height: 14),
        _AppointmentDetailLine(
          icon: Icons.call_outlined,
          label: 'Phone number',
          value: detail.phone,
          onTap: () => _openPhoneNumber(context, detail.phone),
        ),
        _AppointmentDetailLine(
          icon: Icons.medical_services_outlined,
          label: 'Procedure',
          value: detail.procedure,
        ),
        _AppointmentDetailLine(
          icon: Icons.person_outline,
          label: 'Doctor',
          value: detail.doctor,
        ),
        _AppointmentDetailLine(
          icon: Icons.schedule_outlined,
          label: 'Appointment time',
          value: detail.time,
        ),
        _AppointmentDetailLine(
          icon: Icons.notes_outlined,
          label: 'Status note',
          value: detail.note,
        ),
      ],
    );
  }
}

class _FollowUpDashboardDetail extends StatefulWidget {
  const _FollowUpDashboardDetail();

  @override
  State<_FollowUpDashboardDetail> createState() =>
      _FollowUpDashboardDetailState();
}

class _FollowUpDashboardDetailState extends State<_FollowUpDashboardDetail> {
  final detailScrollController = ScrollController();
  FollowUpDetailFilter selectedFilter = FollowUpDetailFilter.urgent;
  FollowUp? selectedFollowUp;

  List<FollowUp> get visibleFollowUps {
    return sampleFollowUps
        .where((followUp) => selectedFilter.matches(followUp))
        .toList();
  }

  @override
  void dispose() {
    detailScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final followUp = selectedFollowUp;
    if (followUp != null) {
      return _FollowUpPatientDetail(
        followUp: followUp,
        onBack: () => setState(() => selectedFollowUp = null),
      );
    }

    final followUps = visibleFollowUps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailSummaryRow(
          items: [
            for (final filter in FollowUpDetailFilter.values)
              DetailSummary(
                filter.label,
                filter.value,
                filter.color,
                selected: selectedFilter == filter,
                onTap: () {
                  setState(() {
                    selectedFilter = filter;
                    selectedFollowUp = null;
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          selectedFilter.detailTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 420,
          child: Scrollbar(
            controller: detailScrollController,
            thumbVisibility: true,
            child: ListView.builder(
              controller: detailScrollController,
              padding: EdgeInsets.zero,
              itemCount: followUps.length,
              itemBuilder: (context, index) {
                final followUp = followUps[index];

                return Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => selectedFollowUp = followUp),
                    child: _ContactDetailBlock(
                      leading: Icons.event_repeat,
                      title: followUp.patient,
                      phone: followUp.phone,
                      details: '${followUp.due} - ${followUp.reason}',
                      doctor: followUp.doctor,
                      color: followUp.color,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _FollowUpPatientDetail extends StatelessWidget {
  const _FollowUpPatientDetail({required this.followUp, required this.onBack});

  final FollowUp followUp;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to follow ups'),
        ),
        const SizedBox(height: 8),
        _ContactDetailBlock(
          leading: Icons.event_repeat,
          title: followUp.patient,
          phone: followUp.phone,
          details: '${followUp.due} - ${followUp.reason}',
          doctor: followUp.doctor,
          color: followUp.color,
        ),
        const SizedBox(height: 8),
        _DetailSummaryRow(
          items: [
            DetailSummary('Due', followUp.due, followUp.color),
            DetailSummary('Priority', followUp.priority, followUp.color),
            DetailSummary('Channel', followUp.channel, const Color(0xFF0B7285)),
          ],
        ),
        const SizedBox(height: 14),
        _AppointmentDetailLine(
          icon: Icons.call_outlined,
          label: 'Phone number',
          value: followUp.phone,
          onTap: () => _openPhoneNumber(context, followUp.phone),
        ),
        _AppointmentDetailLine(
          icon: Icons.person_outline,
          label: 'Doctor',
          value: followUp.doctor,
        ),
        _AppointmentDetailLine(
          icon: Icons.notes_outlined,
          label: 'Follow-up reason',
          value: followUp.reason,
        ),
      ],
    );
  }
}

class _ProcedureDashboardDetail extends StatefulWidget {
  const _ProcedureDashboardDetail();

  @override
  State<_ProcedureDashboardDetail> createState() =>
      _ProcedureDashboardDetailState();
}

class _ProcedureDashboardDetailState extends State<_ProcedureDashboardDetail> {
  final detailScrollController = ScrollController();
  ProcedureDetailFilter selectedFilter = ProcedureDetailFilter.all;
  DentalProcedure? selectedProcedure;

  List<DentalProcedure> get visibleProcedures {
    return sampleDashboardProcedures
        .where((procedure) => selectedFilter.matches(procedure))
        .toList();
  }

  @override
  void dispose() {
    detailScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final procedure = selectedProcedure;
    if (procedure != null) {
      return _ProcedureDetailView(
        procedure: procedure,
        onBack: () => setState(() => selectedProcedure = null),
      );
    }

    final procedures = visibleProcedures;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailSummaryRow(
          items: [
            for (final filter in ProcedureDetailFilter.values)
              DetailSummary(
                filter.label,
                filter.value,
                filter.color,
                selected: selectedFilter == filter,
                onTap: () {
                  setState(() {
                    selectedFilter = filter;
                    selectedProcedure = null;
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          selectedFilter.detailTitle,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 460,
          child: Scrollbar(
            controller: detailScrollController,
            thumbVisibility: true,
            child: ListView.builder(
              controller: detailScrollController,
              padding: EdgeInsets.zero,
              itemCount: procedures.length,
              itemBuilder: (context, index) {
                final procedure = procedures[index];

                return Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => selectedProcedure = procedure),
                    child: _ListBlock(
                      leading: procedure.icon,
                      title: procedure.name,
                      subtitle: '${procedure.stage} - ${procedure.doctor}',
                      trailing: '${(procedure.progress * 100).round()}%',
                      color: procedure.color,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ProcedureDetailView extends StatelessWidget {
  const _ProcedureDetailView({required this.procedure, required this.onBack});

  final DentalProcedure procedure;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to procedures'),
        ),
        const SizedBox(height: 8),
        _ListBlock(
          leading: procedure.icon,
          title: procedure.name,
          subtitle: '${procedure.stage} - ${procedure.categoryPath}',
          trailing: procedure.netPrice,
          color: procedure.color,
        ),
        const SizedBox(height: 8),
        _DetailSummaryRow(
          items: [
            DetailSummary(
              'Progress',
              '${(procedure.progress * 100).round()}%',
              procedure.color,
            ),
            DetailSummary(
              'Estimate',
              procedure.estimate,
              const Color(0xFF0B7285),
            ),
            DetailSummary('Doctor', procedure.doctor, const Color(0xFF7C3AED)),
          ],
        ),
        const SizedBox(height: 14),
        _AppointmentDetailLine(
          icon: Icons.medical_services_outlined,
          label: 'Procedure',
          value: procedure.name,
        ),
        _AppointmentDetailLine(
          icon: Icons.timeline,
          label: 'Stage',
          value: procedure.stage,
        ),
        _AppointmentDetailLine(
          icon: Icons.category_outlined,
          label: 'Category',
          value: procedure.categoryPath,
        ),
        _AppointmentDetailLine(
          icon: Icons.payments_outlined,
          label: 'Price',
          value: procedure.netPrice,
        ),
        if (procedure.hasDiscount)
          _AppointmentDetailLine(
            icon: Icons.discount_outlined,
            label: 'Discount',
            value: '${procedure.discountLabel} from ${procedure.price}',
          ),
      ],
    );
  }
}

class _CashDashboardDetail extends StatefulWidget {
  const _CashDashboardDetail();

  @override
  State<_CashDashboardDetail> createState() => _CashDashboardDetailState();
}

class _CashDashboardDetailState extends State<_CashDashboardDetail> {
  final detailScrollController = ScrollController();
  CashDetailFilter selectedFilter = CashDetailFilter.paidToday;
  Invoice? selectedInvoice;

  List<Invoice> get visibleInvoices {
    return switch (selectedFilter) {
      CashDetailFilter.paidToday =>
        sampleCashDashboardInvoices
            .where((invoice) => invoice.filter == CashDetailFilter.paidToday)
            .toList()
          ..sort((a, b) => b.number.compareTo(a.number)),
      CashDetailFilter.pending =>
        sampleCashDashboardInvoices
            .where((invoice) => invoice.filter == CashDetailFilter.pending)
            .toList(),
      CashDetailFilter.invoices =>
        sampleCashDashboardInvoices.toList()
          ..sort((a, b) => b.number.compareTo(a.number)),
    };
  }

  String get sectionTitle {
    return switch (selectedFilter) {
      CashDetailFilter.paidToday => 'Paid today detail',
      CashDetailFilter.pending => 'Pending cash detail',
      CashDetailFilter.invoices => 'Invoice list',
    };
  }

  @override
  void dispose() {
    detailScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoice = selectedInvoice;
    if (invoice != null) {
      return _CashInvoiceDetail(
        invoice: invoice,
        onBack: () => setState(() => selectedInvoice = null),
      );
    }

    return _Panel(
      title: 'Cash Collected',
      action: 'RM 18,420',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DetailSummaryRow(
            items: [
              DetailSummary(
                'Paid today',
                'RM 18,420',
                const Color(0xFF166534),
                selected: selectedFilter == CashDetailFilter.paidToday,
                onTap: () {
                  setState(() {
                    selectedFilter = CashDetailFilter.paidToday;
                    selectedInvoice = null;
                  });
                },
              ),
              DetailSummary(
                'Pending',
                'RM 4,180',
                const Color(0xFFC2410C),
                selected: selectedFilter == CashDetailFilter.pending,
                onTap: () {
                  setState(() {
                    selectedFilter = CashDetailFilter.pending;
                    selectedInvoice = null;
                  });
                },
              ),
              DetailSummary(
                'Invoices',
                '24',
                const Color(0xFF0B7285),
                selected: selectedFilter == CashDetailFilter.invoices,
                onTap: () {
                  setState(() {
                    selectedFilter = CashDetailFilter.invoices;
                    selectedInvoice = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sectionTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 420,
            child: Scrollbar(
              controller: detailScrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: detailScrollController,
                padding: EdgeInsets.zero,
                itemCount: visibleInvoices.length,
                itemBuilder: (context, index) {
                  final invoice = visibleInvoices[index];

                  return Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => selectedInvoice = invoice),
                      child: _InvoiceTile(invoice: invoice),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CashInvoiceDetail extends StatelessWidget {
  const _CashInvoiceDetail({
    required this.invoice,
    required this.onBack,
    this.backLabel = 'Back to invoices',
  });

  final Invoice invoice;
  final VoidCallback onBack;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          label: Text(backLabel),
        ),
        const SizedBox(height: 8),
        _CashDetailBlock(
          leading: Icons.receipt,
          title: invoice.patient,
          invoiceNumber: invoice.number,
          method: invoice.method,
          status: invoice.status,
          amount: invoice.amount,
          color: invoice.color,
        ),
        const SizedBox(height: 8),
        _DetailSummaryRow(
          items: [
            DetailSummary('Invoice', invoice.number, invoice.color),
            DetailSummary('Amount', invoice.amount, const Color(0xFF166534)),
            DetailSummary('Status', invoice.status, invoice.color),
          ],
        ),
        const SizedBox(height: 14),
        _AppointmentDetailLine(
          icon: Icons.person_outline,
          label: 'Patient',
          value: invoice.patient,
        ),
        _AppointmentDetailLine(
          icon: Icons.payments_outlined,
          label: 'Payment method',
          value: invoice.method,
        ),
        if (invoice.procedure.isNotEmpty)
          _AppointmentDetailLine(
            icon: Icons.medical_services_outlined,
            label: 'Procedure',
            value: invoice.procedure,
          ),
        if (invoice.doctor.isNotEmpty)
          _AppointmentDetailLine(
            icon: Icons.person_outline,
            label: 'Doctor',
            value: invoice.doctor,
          ),
        if (invoice.price.isNotEmpty)
          _AppointmentDetailLine(
            icon: Icons.sell_outlined,
            label: 'Doctor Fee',
            value: invoice.price,
          ),
        if (invoice.procedurePrice.isNotEmpty)
          _AppointmentDetailLine(
            icon: Icons.healing_outlined,
            label: 'Procedure Price',
            value: invoice.procedurePrice,
          ),
        if (invoice.serviceFee.isNotEmpty)
          _AppointmentDetailLine(
            icon: Icons.room_service_outlined,
            label: 'Service Charge',
            value: invoice.serviceFee,
          ),
        if (invoice.tooth.isNotEmpty)
          _AppointmentDetailLine(
            icon: Icons.healing_outlined,
            label: 'Tooth',
            value: '${invoice.dentition} ${invoice.tooth}',
          ),
        if (invoice.clinicalNote.isNotEmpty)
          _AppointmentDetailLine(
            icon: Icons.notes_outlined,
            label: 'Clinical note',
            value: invoice.clinicalNote,
          ),
        if (invoice.pharmacyItems.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            'Pharmacy items',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          for (final item in invoice.pharmacyItems)
            _AppointmentDetailLine(
              icon: Icons.local_pharmacy_outlined,
              label: item.name,
              value: item.price,
            ),
        ],
        _AppointmentDetailLine(
          icon: Icons.receipt_long_outlined,
          label: 'Invoice number',
          value: invoice.number,
        ),
      ],
    );
  }
}

class _PrintableInvoiceSheet extends StatelessWidget {
  const _PrintableInvoiceSheet({
    required this.invoice,
    required this.onBack,
    required this.onDone,
    required this.onPrinted,
  });

  final Invoice invoice;
  final VoidCallback onBack;
  final VoidCallback onDone;
  final VoidCallback onPrinted;

  @override
  Widget build(BuildContext context) {
    final patient = _patientForInvoice(invoice);
    final items = _invoiceSheetItems(invoice);
    final total = items.fold<double>(0, (sum, item) => sum + item.amount);
    final displayTotal = total == 0
        ? (invoice.amount.isEmpty ? 'RM 0' : invoice.amount)
        : _formatCurrencyValue(total);
    final teal = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      child: Container(
        color: const Color(0xFFF4F7F6),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TextButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to cash'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () async {
                    final printed = await launchPrintDialog();
                    if (!printed && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Printing is available in the browser preview',
                          ),
                        ),
                      );
                    }
                    if (context.mounted) {
                      onPrinted();
                    }
                  },
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onDone,
                  icon: const Icon(Icons.done),
                  label: const Text('Done'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 860),
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD7E4E1)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x14000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 58,
                          height: 58,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: teal,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.medical_services_outlined,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'DentalOps Clinic',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text('22 Jalan Ampang, Kuala Lumpur'),
                              Text('+60 12-555 0100'),
                            ],
                          ),
                        ),
                        Text(
                          'INVOICE',
                          style: TextStyle(
                            color: teal,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _InvoiceInfoBlock(
                            title: 'Invoice To',
                            rows: [
                              _InvoiceInfoLine('Patient', invoice.patient),
                              _InvoiceInfoLine('Phone', patient?.phone ?? '-'),
                              _InvoiceInfoLine(
                                'Address',
                                patient?.address ?? '-',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _InvoiceInfoBlock(
                            title: 'Invoice Details',
                            rows: [
                              _InvoiceInfoLine('Invoice No', invoice.number),
                              _InvoiceInfoLine('Date', _todayLabel()),
                              _InvoiceInfoLine('Status', invoice.status),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _PrintableInvoiceTable(items: items),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 320,
                        child: Column(
                          children: [
                            _PrintableTotalLine('Sub Total', displayTotal),
                            _PrintableTotalLine('Tax', 'RM 0'),
                            _PrintableTotalLine(
                              'Total',
                              displayTotal,
                              emphasized: true,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (invoice.doctor.isNotEmpty ||
                        invoice.tooth.isNotEmpty ||
                        invoice.clinicalNote.isNotEmpty)
                      _InvoiceInfoBlock(
                        title: 'Treatment Notes',
                        rows: [
                          if (invoice.doctor.isNotEmpty)
                            _InvoiceInfoLine('Doctor', invoice.doctor),
                          if (invoice.tooth.isNotEmpty)
                            _InvoiceInfoLine(
                              'Tooth',
                              '${invoice.dentition} ${invoice.tooth}',
                            ),
                          if (invoice.clinicalNote.isNotEmpty)
                            _InvoiceInfoLine('Note', invoice.clinicalNote),
                        ],
                      ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Payment method: ${invoice.method}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const Text(
                          'Thank you.',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceInfoBlock extends StatelessWidget {
  const _InvoiceInfoBlock({required this.title, required this.rows});

  final String title;
  final List<_InvoiceInfoLine> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFD7E4E1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 10),
          for (final row in rows) _PrintableInfoRow(row: row),
        ],
      ),
    );
  }
}

class _PrintableInfoRow extends StatelessWidget {
  const _PrintableInfoRow({required this.row});

  final _InvoiceInfoLine row;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              row.label,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              row.value,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrintableInvoiceTable extends StatelessWidget {
  const _PrintableInvoiceTable({required this.items});

  final List<_InvoiceSheetItem> items;

  @override
  Widget build(BuildContext context) {
    final teal = Theme.of(context).colorScheme.primary;
    final rows = items.isEmpty
        ? const [_InvoiceSheetItem('Treatment fee', 1, 0)]
        : items;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Table(
        columnWidths: const {
          0: FixedColumnWidth(62),
          1: FlexColumnWidth(3.5),
          2: FixedColumnWidth(96),
          3: FlexColumnWidth(1.4),
        },
        border: TableBorder.all(color: teal.withValues(alpha: 0.75)),
        children: [
          TableRow(
            decoration: BoxDecoration(color: teal),
            children: const [
              _PrintableTableCell('No', header: true),
              _PrintableTableCell('Description', header: true),
              _PrintableTableCell('Quantity', header: true),
              _PrintableTableCell('Price', header: true),
            ],
          ),
          for (var index = 0; index < rows.length; index++)
            TableRow(
              decoration: BoxDecoration(
                color: index.isOdd ? const Color(0xFFE0F4F1) : Colors.white,
              ),
              children: [
                _PrintableTableCell('${index + 1}'),
                _PrintableTableCell(rows[index].description, alignLeft: true),
                _PrintableTableCell('${rows[index].quantity}'),
                _PrintableTableCell(_formatCurrencyValue(rows[index].amount)),
              ],
            ),
        ],
      ),
    );
  }
}

class _PrintableTableCell extends StatelessWidget {
  const _PrintableTableCell(
    this.text, {
    this.header = false,
    this.alignLeft = false,
  });

  final String text;
  final bool header;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: header ? 48 : 46),
      alignment: alignLeft ? Alignment.centerLeft : Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Text(
        text,
        textAlign: alignLeft ? TextAlign.left : TextAlign.center,
        style: TextStyle(
          color: header ? Colors.white : const Color(0xFF17212B),
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _PrintableTotalLine extends StatelessWidget {
  const _PrintableTotalLine(this.label, this.value, {this.emphasized = false});

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final teal = Theme.of(context).colorScheme.primary;

    return Container(
      height: 42,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: emphasized ? teal : Colors.white,
        border: Border.all(color: teal.withValues(alpha: 0.75)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label,
                style: TextStyle(
                  color: emphasized ? Colors.white : teal,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          Container(
            width: 130,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              value,
              style: TextStyle(
                color: emphasized ? Colors.white : const Color(0xFF17212B),
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceInfoLine {
  const _InvoiceInfoLine(this.label, this.value);

  final String label;
  final String value;
}

class _InvoiceSheetItem {
  const _InvoiceSheetItem(this.description, this.quantity, this.amount);

  final String description;
  final int quantity;
  final double amount;
}

ClinicUser? _patientForInvoice(Invoice invoice) {
  for (final user in sampleUsers) {
    if (user.name.toLowerCase() == invoice.patient.toLowerCase()) {
      return user;
    }
  }
  return null;
}

List<_InvoiceSheetItem> _invoiceSheetItems(Invoice invoice) {
  return [
    if (invoice.price.isNotEmpty)
      _InvoiceSheetItem('Doctor Fee', 1, _currencyValue(invoice.price)),
    if (invoice.serviceFee.isNotEmpty)
      _InvoiceSheetItem(
        'Service Charge',
        1,
        _currencyValue(invoice.serviceFee),
      ),
    if (invoice.procedure.isNotEmpty || invoice.procedurePrice.isNotEmpty)
      _InvoiceSheetItem(
        invoice.procedure.isEmpty ? 'Procedure' : invoice.procedure,
        1,
        _currencyValue(invoice.procedurePrice),
      ),
    for (final item in invoice.pharmacyItems)
      _InvoiceSheetItem(item.name, item.quantity, _currencyValue(item.price)),
  ];
}

String _todayLabel() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
}

String _formatDate(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

String _formatTimeOfDay(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

String _combineFollowUpNote(String note, String date, String time) {
  final trimmedNote = note.trim();
  final trimmedDate = date.trim();
  final trimmedTime = time.trim();
  final schedule = [
    if (trimmedDate.isNotEmpty) trimmedDate,
    if (trimmedTime.isNotEmpty) trimmedTime,
  ].join(' ');

  return [
    if (trimmedNote.isNotEmpty) trimmedNote,
    if (schedule.isNotEmpty) 'Follow up: $schedule',
  ].join(' - ');
}

class _DetailSummaryRow extends StatelessWidget {
  const _DetailSummaryRow({required this.items});

  final List<DetailSummary> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            children: [
              for (final item in items) _DetailSummaryTile(summary: item),
            ],
          );
        }

        return Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              Expanded(child: _DetailSummaryTile(summary: items[index])),
              if (index < items.length - 1) const SizedBox(width: 10),
            ],
          ],
        );
      },
    );
  }
}

class _DetailSummaryTile extends StatelessWidget {
  const _DetailSummaryTile({required this.summary});

  final DetailSummary summary;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(8);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: summary.color.withValues(alpha: summary.selected ? 0.14 : 0.08),
        borderRadius: borderRadius,
        child: InkWell(
          onTap: summary.onTap,
          borderRadius: borderRadius,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: summary.color.withValues(
                  alpha: summary.selected ? 0.42 : 0.16,
                ),
                width: summary.selected ? 1.4 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    summary.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  summary.value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: summary.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (summary.onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, size: 18, color: summary.color),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class UsersView extends StatelessWidget {
  const UsersView({
    super.key,
    required this.selectedRole,
    required this.onRoleChanged,
    required this.users,
  });

  final RoleFilter selectedRole;
  final ValueChanged<RoleFilter> onRoleChanged;
  final List<ClinicUser> users;

  @override
  Widget build(BuildContext context) {
    final visibleUsers = users.where((user) {
      return selectedRole == RoleFilter.all || user.role == selectedRole.label;
    }).toList();

    return _Panel(
      title: 'Users & Roles',
      action: '${visibleUsers.length} people',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<RoleFilter>(
              segments: [
                for (final role in RoleFilter.values)
                  ButtonSegment(
                    value: role,
                    label: Text(role.label),
                    icon: Icon(role.icon),
                  ),
              ],
              selected: {selectedRole},
              onSelectionChanged: (selection) => onRoleChanged(selection.first),
            ),
          ),
          const SizedBox(height: 16),
          _ResponsiveGrid(
            compactAspectRatio: 0.92,
            minTileWidth: 260,
            wideAspectRatio: 1.05,
            children: [for (final user in visibleUsers) _UserCard(user: user)],
          ),
        ],
      ),
    );
  }
}

class _NewUserDialog extends StatefulWidget {
  const _NewUserDialog();

  @override
  State<_NewUserDialog> createState() => _NewUserDialogState();
}

class _NewUserDialogState extends State<_NewUserDialog> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final statusController = TextEditingController(text: 'Active');
  RoleFilter creatorRole = RoleFilter.user;
  RoleFilter newUserRole = RoleFilter.user;

  List<RoleFilter> get creatableRoles {
    if (creatorRole.canCreateAllRoles) {
      return RoleFilter.creatableRoles;
    }

    return const [RoleFilter.user];
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    phoneController.dispose();
    addressController.dispose();
    statusController.dispose();
    super.dispose();
  }

  void setCreatorRole(RoleFilter? role) {
    if (role == null) {
      return;
    }

    setState(() {
      creatorRole = role;
      if (!creatableRoles.contains(newUserRole)) {
        newUserRole = RoleFilter.user;
      }
    });
  }

  void submit() {
    final name = nameController.text.trim();
    final age = ageController.text.trim();
    final phone = phoneController.text.trim();
    final address = addressController.text.trim();
    final status = statusController.text.trim();

    if ([name, age, phone, address, status].any((value) => value.isEmpty)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Complete all user fields')));
      return;
    }

    if (newUserRole != RoleFilter.user && !creatorRole.canCreateAllRoles) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin or Owner required for this role')),
      );
      return;
    }

    Navigator.of(context).pop(
      ClinicUser(
        name,
        newUserRole.label,
        status,
        initialsForName(name),
        newUserRole.color,
        age,
        phone,
        address,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allowedRoles = creatableRoles;

    return AlertDialog(
      title: const Text('New User'),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _UserTextField(
                controller: nameController,
                label: 'Name',
                icon: Icons.person_outline,
              ),
              _UserTextField(
                controller: ageController,
                label: 'Age',
                icon: Icons.cake_outlined,
                keyboardType: TextInputType.number,
              ),
              _UserTextField(
                controller: phoneController,
                label: 'Phone',
                icon: Icons.call_outlined,
                keyboardType: TextInputType.phone,
              ),
              _UserTextField(
                controller: addressController,
                label: 'Address',
                icon: Icons.home_outlined,
              ),
              _UserTextField(
                controller: statusController,
                label: 'Status',
                icon: Icons.verified_user_outlined,
              ),
              _RoleDropdown(
                label: 'Created by role',
                value: creatorRole,
                roles: RoleFilter.creatorRoles,
                onChanged: setCreatorRole,
              ),
              _RoleDropdown(
                label: 'New user role',
                value: newUserRole,
                roles: allowedRoles,
                onChanged: (role) {
                  if (role != null) {
                    setState(() => newUserRole = role);
                  }
                },
              ),
              const SizedBox(height: 2),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  creatorRole.canCreateAllRoles
                      ? 'Admin and Owner can create any role'
                      : 'Users can create User role only',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF52606D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: submit,
          icon: const Icon(Icons.person_add_alt_1),
          label: const Text('Create User'),
        ),
      ],
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({
    required this.label,
    required this.value,
    required this.roles,
    required this.onChanged,
  });

  final String label;
  final RoleFilter value;
  final List<RoleFilter> roles;
  final ValueChanged<RoleFilter?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<RoleFilter>(
        initialValue: value,
        items: [
          for (final role in roles)
            DropdownMenuItem(
              value: role,
              child: Row(
                children: [
                  Icon(role.icon, size: 18),
                  const SizedBox(width: 8),
                  Text(role.label),
                ],
              ),
            ),
        ],
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.admin_panel_settings_outlined),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class _UserTextField extends StatelessWidget {
  const _UserTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class DoctorsView extends StatelessWidget {
  const DoctorsView({super.key});

  @override
  Widget build(BuildContext context) {
    return _ResponsiveGrid(
      minTileWidth: 300,
      children: [
        for (final doctor in sampleDoctors) _DoctorCard(doctor: doctor),
      ],
    );
  }
}

class BookingView extends StatefulWidget {
  const BookingView({super.key});

  @override
  State<BookingView> createState() => _BookingViewState();
}

class _BookingViewState extends State<BookingView> {
  Appointment? selectedAppointment;

  @override
  Widget build(BuildContext context) {
    final appointment = selectedAppointment;
    if (appointment != null) {
      return _BookingAppointmentDetail(
        appointment: appointment,
        onBack: () => setState(() => selectedAppointment = null),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResponsiveGrid(
          compactMinTileWidth: 170,
          compactAspectRatio: 1.22,
          minTileWidth: 220,
          wideAspectRatio: 1.45,
          children: const [
            _MetricCard(
              'Open Slots',
              '3',
              'Today',
              Icons.event_available,
              Color(0xFF0B7285),
            ),
            _MetricCard(
              'Confirmed',
              '4',
              '+1',
              Icons.check_circle_outline,
              Color(0xFF166534),
            ),
            _MetricCard(
              'Walk-ins',
              '6',
              '2 waiting',
              Icons.directions_walk,
              Color(0xFFC2410C),
            ),
            _MetricCard(
              'Chair Load',
              '68%',
              '4 rooms',
              Icons.chair_alt,
              Color(0xFF7C3AED),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _TwoColumn(
          left: _Panel(
            title: 'New Appointment',
            action: 'Booking',
            child: const _BookingForm(),
          ),
          right: _Panel(
            title: 'Available Slots',
            action: 'Today',
            child: Column(
              children: [
                for (final slot in sampleBookingSlots)
                  _BookingSlotTile(slot: slot),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Booking Patients',
          action: '${sampleAppointments.length} patients',
          child: Column(
            children: [
              for (final appointment in sampleAppointments)
                _BookingPatientTile(
                  appointment: appointment,
                  onTap: () =>
                      setState(() => selectedAppointment = appointment),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Appointment Queue',
          action: '${sampleAppointments.length} booked',
          child: Column(
            children: [
              for (final appointment in sampleAppointments)
                _AppointmentTile(
                  appointment: appointment,
                  onTap: () =>
                      setState(() => selectedAppointment = appointment),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookingAppointmentDetail extends StatelessWidget {
  const _BookingAppointmentDetail({
    required this.appointment,
    required this.onBack,
  });

  final Appointment appointment;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to booking'),
        ),
        const SizedBox(height: 8),
        _Panel(
          title: 'Appointment Detail',
          action: appointment.time,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ContactDetailBlock(
                leading: Icons.chair_alt,
                title: appointment.patient,
                phone: appointment.phone,
                details: appointment.procedure,
                doctor: appointment.doctor,
                color: appointment.color,
              ),
              const SizedBox(height: 8),
              _DetailSummaryRow(
                items: [
                  DetailSummary(
                    'Patient',
                    appointment.patient,
                    appointment.color,
                  ),
                  DetailSummary(
                    'Time',
                    appointment.time,
                    const Color(0xFF0B7285),
                  ),
                  DetailSummary(
                    'Doctor',
                    appointment.doctor,
                    const Color(0xFF7C3AED),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _AppointmentDetailLine(
                icon: Icons.call_outlined,
                label: 'Phone number',
                value: appointment.phone,
                onTap: () => _openPhoneNumber(context, appointment.phone),
              ),
              _AppointmentDetailLine(
                icon: Icons.medical_services_outlined,
                label: 'Procedure',
                value: appointment.procedure,
              ),
              _AppointmentDetailLine(
                icon: Icons.check_circle_outline,
                label: 'Status',
                value: 'Confirmed',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class QueueView extends StatefulWidget {
  const QueueView({super.key});

  @override
  State<QueueView> createState() => _QueueViewState();
}

class _QueueViewState extends State<QueueView> {
  final scrollController = ScrollController();
  AppointmentStatusFilter selectedFilter = AppointmentStatusFilter.inChair;
  AppointmentStatusDetail? selectedDetail;

  List<AppointmentStatusDetail> get visibleDetails {
    return sampleAppointmentStatusDetails
        .where((detail) => detail.filter == selectedFilter)
        .toList();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patient = selectedDetail;
    if (patient != null) {
      return _Panel(
        title: 'Queue Patient Detail',
        action: patient.bookingId,
        child: _AppointmentStatusPatientDetail(
          detail: patient,
          onBack: () => setState(() => selectedDetail = null),
        ),
      );
    }

    final patients = visibleDetails;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Panel(
          title: 'Queue System',
          action: 'Live',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DetailSummaryRow(
                items: [
                  for (final filter in AppointmentStatusFilter.values)
                    DetailSummary(
                      filter.label,
                      filter.count,
                      filter.color,
                      selected: selectedFilter == filter,
                      onTap: () {
                        setState(() {
                          selectedFilter = filter;
                          selectedDetail = null;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _QueueFlow(items: sampleQueueStatuses),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: selectedFilter.detailTitle,
          action: '${patients.length} patients',
          child: SizedBox(
            height: 460,
            child: Scrollbar(
              controller: scrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: scrollController,
                padding: EdgeInsets.zero,
                itemCount: patients.length,
                itemBuilder: (context, index) {
                  final detail = patients[index];

                  return Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => setState(() => selectedDetail = detail),
                      child: _ContactDetailBlock(
                        leading: detail.filter.icon,
                        title: detail.patient,
                        phone: detail.phone,
                        details:
                            '${detail.bookingId} - ${detail.time} - ${detail.procedure} - ${detail.note}',
                        doctor: detail.doctor,
                        color: detail.filter.color,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AppointmentDetailLine extends StatelessWidget {
  const _AppointmentDetailLine({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(8);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: const Color(0xFFF8FAFC),
        borderRadius: borderRadius,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(color: const Color(0xFFE1E7EC)),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF52606D)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onTap == null ? null : const Color(0xFF0B7285),
                      fontWeight: FontWeight.w900,
                      decoration: onTap == null
                          ? TextDecoration.none
                          : TextDecoration.underline,
                    ),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.call_outlined,
                    color: Color(0xFF0B7285),
                    size: 18,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CashierView extends StatefulWidget {
  const CashierView({super.key, required this.onProjectInvoiceCreated});

  final ValueChanged<Invoice> onProjectInvoiceCreated;

  @override
  State<CashierView> createState() => _CashierViewState();
}

class _CashierViewState extends State<CashierView> {
  var invoices = [...sampleInvoices];
  var showCreateInvoice = false;
  var showRecordPayment = false;
  var showInvoiceHistory = false;
  Invoice? printableInvoice;

  @override
  Widget build(BuildContext context) {
    final invoiceSheet = printableInvoice;
    if (invoiceSheet != null) {
      return _PrintableInvoiceSheet(
        invoice: invoiceSheet,
        onBack: () => setState(() => printableInvoice = null),
        onDone: () {
          setState(() {
            printableInvoice = null;
            showCreateInvoice = true;
          });
        },
        onPrinted: () {
          setState(() {
            printableInvoice = null;
            showCreateInvoice = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${invoiceSheet.number} ready to print')),
          );
        },
      );
    }

    if (showCreateInvoice) {
      return _CreateInvoiceDetail(
        initialInvoiceNumber: _nextInvoiceNumber,
        onBack: () => setState(() => showCreateInvoice = false),
        onCreated: (invoice) {
          setState(() {
            invoices = [invoice, ...invoices];
            showCreateInvoice = false;
            showInvoiceHistory = false;
            printableInvoice = invoice;
          });
          widget.onProjectInvoiceCreated(invoice);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('${invoice.number} created')));
        },
      );
    }

    if (showRecordPayment) {
      return _RecordPaymentDetail(
        onBack: () => setState(() => showRecordPayment = false),
        onRecorded: (invoice) {
          setState(() {
            invoices = [invoice, ...invoices];
            showRecordPayment = false;
            showInvoiceHistory = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${invoice.number} payment recorded')),
          );
        },
      );
    }

    if (showInvoiceHistory) {
      return _InvoiceHistoryView(
        invoices: invoices,
        onBack: () => setState(() => showInvoiceHistory = false),
        onPrintInvoice: (invoice) => setState(() {
          showInvoiceHistory = false;
          printableInvoice = invoice;
        }),
      );
    }

    return _TwoColumn(
      left: _Panel(
        title: 'Payment Queue',
        action: 'RM 6,910 due',
        child: Column(
          children: [
            for (final invoice in invoices) _InvoiceTile(invoice: invoice),
          ],
        ),
      ),
      right: _Panel(
        title: 'Checkout Tools',
        action: 'Cashier',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ActionButton(
              icon: Icons.receipt_long,
              label: 'Create invoice',
              onPressed: () => setState(() => showCreateInvoice = true),
            ),
            _ActionButton(
              icon: Icons.credit_card,
              label: 'Record payment',
              onPressed: () => setState(() => showRecordPayment = true),
            ),
            const _ActionButton(
              icon: Icons.discount,
              label: 'Apply package credit',
            ),
            _ActionButton(
              icon: Icons.print,
              label: 'Print receipt',
              onPressed: () => setState(() => showInvoiceHistory = true),
            ),
          ],
        ),
      ),
    );
  }

  String get _nextInvoiceNumber {
    final maxNumber = invoices
        .map((invoice) => RegExp(r'^INV-(\d+)$').firstMatch(invoice.number))
        .whereType<RegExpMatch>()
        .map((match) => int.tryParse(match.group(1) ?? '') ?? 0)
        .fold<int>(1051, (max, value) => value > max ? value : max);
    return 'INV-${maxNumber + 1}';
  }
}

class _InvoiceHistoryView extends StatelessWidget {
  const _InvoiceHistoryView({
    required this.invoices,
    required this.onBack,
    required this.onPrintInvoice,
  });

  final List<Invoice> invoices;
  final VoidCallback onBack;
  final ValueChanged<Invoice> onPrintInvoice;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Invoice History',
      action: '${invoices.length} invoices',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton.icon(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Back to cash'),
          ),
          const SizedBox(height: 8),
          for (final invoice in invoices)
            Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onPrintInvoice(invoice),
                child: _InvoiceTile(invoice: invoice),
              ),
            ),
        ],
      ),
    );
  }
}

class _CreateInvoiceDetail extends StatefulWidget {
  const _CreateInvoiceDetail({
    required this.initialInvoiceNumber,
    required this.onBack,
    required this.onCreated,
  });

  final String initialInvoiceNumber;
  final VoidCallback onBack;
  final ValueChanged<Invoice> onCreated;

  @override
  State<_CreateInvoiceDetail> createState() => _CreateInvoiceDetailState();
}

class _CreateInvoiceDetailState extends State<_CreateInvoiceDetail> {
  final patientController = TextEditingController();
  final numberController = TextEditingController();
  final doctorController = TextEditingController();
  final procedureController = TextEditingController();
  final priceController = TextEditingController();
  final procedurePriceController = TextEditingController();
  final serviceFeeController = TextEditingController();
  final methodController = TextEditingController(text: 'Cash');
  final secondaryMethodController = TextEditingController(text: 'Bank');
  final statusController = TextEditingController(text: 'Ready to pay');
  final amountController = TextEditingController();
  final cashAmountController = TextEditingController();
  final secondaryAmountController = TextEditingController();
  final detailController = TextEditingController();
  final followUpDateController = TextEditingController();
  final followUpTimeController = TextEditingController();
  ClinicUser? selectedPatient;
  var serviceChargeItems = <ServiceChargeItem>[];
  var procedureItems = <ProcedureInvoiceItem>[];
  var pharmacyItems = <PharmacyInvoiceItem>[];
  var selectedDentition = DentitionType.adult;
  var selectedTooth = 'Tooth 11';
  var primaryProcedureTeeth = '';
  DentalProcedure? lastProcedure;

  @override
  void initState() {
    super.initState();
    numberController.text = widget.initialInvoiceNumber;
    priceController.text = cashierDefaultDoctorFee;
    serviceFeeController.text = cashierDefaultServiceCharge;
    amountController.text = _formatCurrencyValue(
      _formChargeTotal(),
    ).replaceFirst('RM ', '');
  }

  @override
  void dispose() {
    patientController.dispose();
    numberController.dispose();
    doctorController.dispose();
    procedureController.dispose();
    priceController.dispose();
    procedurePriceController.dispose();
    serviceFeeController.dispose();
    methodController.dispose();
    secondaryMethodController.dispose();
    statusController.dispose();
    amountController.dispose();
    cashAmountController.dispose();
    secondaryAmountController.dispose();
    detailController.dispose();
    followUpDateController.dispose();
    followUpTimeController.dispose();
    super.dispose();
  }

  void submit() {
    final patient = patientController.text.trim();
    final number = numberController.text.trim();
    final doctor = doctorController.text.trim();
    final procedure = procedureController.text.trim();
    final price = priceController.text.trim();
    final procedurePrice = procedurePriceController.text.trim();
    final serviceFee = serviceFeeController.text.trim();
    final method = methodController.text.trim();
    final secondaryMethod = secondaryMethodController.text.trim();
    final status = statusController.text.trim();
    final amount = amountController.text.trim();
    final cashAmount = cashAmountController.text.trim();
    final secondaryAmount = secondaryAmountController.text.trim();
    final isSplitPayment = method == 'Both';

    final defaultPayAmount = _formatCurrencyValue(
      _formChargeTotal(
        doctorFee: price,
        procedurePrice: procedurePrice,
        serviceFee: serviceFee,
      ),
    );
    final standardAmount =
        amount.isEmpty &&
            [price, procedurePrice, serviceFee].any((value) => value.isNotEmpty)
        ? defaultPayAmount
        : amount;
    final missingStandardPayment = !isSplitPayment && standardAmount.isEmpty;
    final missingSplitPayment =
        isSplitPayment &&
        [
          cashAmount,
          secondaryMethod,
          secondaryAmount,
        ].any((value) => value.isEmpty);

    if ([patient, number, method, status].any((value) => value.isEmpty) ||
        missingStandardPayment ||
        missingSplitPayment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all invoice fields')),
      );
      return;
    }

    final paymentMethod = isSplitPayment
        ? 'Both: Cash + $secondaryMethod'
        : method;
    final formattedAmount = isSplitPayment
        ? 'Cash ${_formatCurrency(cashAmount)} + $secondaryMethod ${_formatCurrency(secondaryAmount)}'
        : _formatCurrency(standardAmount);

    widget.onCreated(
      Invoice(
        patient,
        number,
        paymentMethod,
        status,
        formattedAmount,
        const Color(0xFF0B7285),
        CashDetailFilter.pending,
        procedure: procedure,
        price: price.isEmpty ? '' : _formatCurrency(price),
        procedurePrice: procedurePrice.isEmpty
            ? ''
            : _formatCurrency(procedurePrice),
        serviceFee: serviceFee.isEmpty ? '' : _formatCurrency(serviceFee),
        serviceChargeItems: serviceChargeItems,
        procedureItems: procedureItems,
        doctor: doctor,
        dentition: selectedDentition.label,
        tooth: primaryProcedureTeeth.isEmpty
            ? selectedTooth
            : primaryProcedureTeeth,
        clinicalNote: _combineFollowUpNote(
          detailController.text,
          followUpDateController.text,
          followUpTimeController.text,
        ),
        pharmacyItems: pharmacyItems,
      ),
    );
  }

  void choosePatient(ClinicUser? patient) {
    setState(() {
      selectedPatient = patient;
      patientController.text = patient?.name ?? '';

      final billing = patient == null ? null : billingForPatient(patient.name);
      procedureController.text = billing?.procedure ?? '';
      doctorController.text = billing?.doctor ?? '';
      if (billing?.price.isNotEmpty ?? false) {
        procedurePriceController.text = billing!.price;
      }
      if (methodController.text != 'Both') {
        updateAmount();
      }
    });
  }

  Future<void> pickWaitingPatient() async {
    final detail = await showWaitingCashPatientPicker(context);
    if (detail == null) {
      return;
    }

    final billing = billingForPatient(detail.patient);
    setState(() {
      selectedPatient = null;
      patientController.text = detail.patient;
      doctorController.text = detail.doctor;
      procedureController.text = detail.procedure;
      procedurePriceController.text =
          billing?.price ?? priceForProcedureName(detail.procedure);
      if (detailController.text.trim().isEmpty) {
        detailController.text = '${detail.bookingId}: ${detail.note}';
      }
      if (methodController.text != 'Both') {
        updateAmount();
      }
    });
  }

  void chooseProcedure(DentalProcedure? procedure) {
    setState(() {
      final currentProcedure = procedureController.text.trim();
      final currentProcedurePrice = procedurePriceController.text.trim();
      if (currentProcedure.isNotEmpty &&
          currentProcedure != 'Doctor Fees' &&
          primaryProcedureTeeth.isNotEmpty) {
        procedureItems = [
          ...procedureItems,
          ProcedureInvoiceItem(
            currentProcedure,
            primaryProcedureTeeth,
            currentProcedurePrice,
          ),
        ];
      }

      procedureController.text = procedure?.name ?? '';
      doctorController.text = procedure?.doctor ?? doctorController.text;
      lastProcedure = procedure;
      primaryProcedureTeeth = '';
      if (procedure?.price.isNotEmpty ?? false) {
        procedurePriceController.text = procedure!.price;
      }
      if (methodController.text != 'Both') {
        updateAmount();
      }
    });
  }

  void joinProcedureWithSelection() {
    final procedureName = procedureController.text.trim();
    final procedurePrice = procedurePriceController.text.trim();
    final joinedTeeth = '${selectedDentition.label} $selectedTooth';

    if (procedureName.isEmpty || procedureName == 'Doctor Fees') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose procedure before joining teeth')),
      );
      return;
    }

    setState(() {
      primaryProcedureTeeth = joinedTeeth;
      if (methodController.text != 'Both') {
        updateAmount();
      }
    });
  }

  void chooseDoctor(Doctor? doctor) {
    setState(() {
      doctorController.text = doctor?.name ?? '';
    });
  }

  Future<void> addMedicine(Medicine medicine) async {
    final item = await showMedicineAmountDialog(context, medicine);
    if (item == null) {
      return;
    }

    setState(() {
      pharmacyItems = [...pharmacyItems, item];
      if (methodController.text != 'Both') {
        updateAmount();
      }
    });
  }

  Future<void> editMedicineItem(int index) async {
    final item = await showPharmacyInvoiceItemEditor(
      context,
      pharmacyItems[index],
    );
    if (item == null) {
      return;
    }

    setState(() {
      pharmacyItems = [...pharmacyItems]..[index] = item;
      if (methodController.text != 'Both') {
        updateAmount();
      }
    });
  }

  Future<void> editServiceChargeItem(int index) async {
    final item = await showServiceChargeItemEditor(
      context,
      serviceChargeItems[index],
    );
    if (item == null) {
      return;
    }

    setState(() {
      serviceChargeItems = [...serviceChargeItems]..[index] = item;
      if (methodController.text != 'Both') {
        updateAmount();
      }
    });
  }

  Future<void> addServiceCharge() async {
    final fee = await showServiceChargePicker(context);
    if (fee == null) {
      return;
    }

    setState(() {
      serviceChargeItems = [
        ...serviceChargeItems,
        ServiceChargeItem(fee.name, fee.price),
      ];
      if (methodController.text != 'Both') {
        updateAmount();
      }
    });
  }

  Future<void> editProcedureItem(int index) async {
    final item = await showProcedureInvoiceItemEditor(
      context,
      procedureItems[index],
    );
    if (item == null) {
      return;
    }

    setState(() {
      procedureItems = [...procedureItems]..[index] = item;
      if (methodController.text != 'Both') {
        updateAmount();
      }
    });
  }

  Future<void> openMedicinePicker() async {
    final medicine = await showMedicinePicker(context);
    if (medicine != null) {
      await addMedicine(medicine);
    }
  }

  Future<void> openPatientPicker() async {
    final patient = await showPatientPicker(context);
    if (patient != null) {
      choosePatient(patient);
    }
  }

  Future<void> openProcedurePicker() async {
    final procedure = await showProcedurePicker(context);
    if (procedure != null) {
      chooseProcedure(procedure);
    }
  }

  Future<void> openDoctorPicker() async {
    final doctor = await showDoctorPicker(context);
    if (doctor != null) {
      chooseDoctor(doctor);
    }
  }

  Future<void> openDoctorFeePicker() async {
    final fee = await showDoctorFeePicker(context);
    if (fee == null) {
      return;
    }

    setState(() {
      priceController.text = fee.displayLabel;
      cashierDefaultDoctorFee = fee.displayLabel;
      if (methodController.text != 'Both') {
        updateAmount();
      }
    });
  }

  Future<void> openServiceChargePicker() async {
    final fee = await showServiceChargePicker(context);
    if (fee == null) {
      return;
    }

    setState(() {
      serviceFeeController.text = fee.displayLabel;
      cashierDefaultServiceCharge = fee.displayLabel;
      if (methodController.text != 'Both') {
        updateAmount();
      }
    });
  }

  double _formChargeTotal({
    String? doctorFee,
    String? procedurePrice,
    String? serviceFee,
  }) {
    return _currencyValue(doctorFee ?? priceController.text) +
        _currencyValue(procedurePrice ?? procedurePriceController.text) +
        _currencyValue(serviceFee ?? serviceFeeController.text) +
        procedureItems.fold<double>(
          0,
          (sum, item) => sum + _currencyValue(item.price),
        ) +
        serviceChargeItems.fold<double>(
          0,
          (sum, item) => sum + _currencyValue(item.price),
        ) +
        pharmacyItems.fold<double>(
          0,
          (sum, item) => sum + _currencyValue(item.price),
        );
  }

  void updateAmount() {
    amountController.text = _formatCurrencyValue(
      _formChargeTotal(),
    ).replaceFirst('RM ', '');
  }

  @override
  Widget build(BuildContext context) {
    return _MtdCashierDetailScaffold(
      primaryActionLabel: 'Create Invoice',
      primaryActionIcon: Icons.add_card,
      onBack: widget.onBack,
      onSubmit: submit,
      showWaitingToCash: true,
      onPickWaitingPatient: pickWaitingPatient,
      patientController: patientController,
      invoiceController: numberController,
      doctorController: doctorController,
      procedureController: procedureController,
      priceController: priceController,
      procedurePriceController: procedurePriceController,
      primaryProcedureTeeth: primaryProcedureTeeth,
      serviceFeeController: serviceFeeController,
      serviceChargeItems: serviceChargeItems,
      procedureItems: procedureItems,
      methodController: methodController,
      secondaryMethodController: secondaryMethodController,
      amountController: amountController,
      cashAmountController: cashAmountController,
      secondaryAmountController: secondaryAmountController,
      statusController: statusController,
      noteController: detailController,
      followUpDateController: followUpDateController,
      followUpTimeController: followUpTimeController,
      pharmacyItems: pharmacyItems,
      selectedDentition: selectedDentition,
      selectedTooth: selectedTooth,
      onPickPatient: openPatientPicker,
      onPickDoctor: openDoctorPicker,
      onPickDoctorFee: openDoctorFeePicker,
      onPickServiceFee: openServiceChargePicker,
      onAddServiceCharge: addServiceCharge,
      onPickProcedure: openProcedurePicker,
      onJoinProcedure: joinProcedureWithSelection,
      onPickMedicine: openMedicinePicker,
      onEditMedicine: editMedicineItem,
      onEditServiceCharge: editServiceChargeItem,
      onEditProcedure: editProcedureItem,
      onRemoveMedicine: (index) {
        setState(() {
          pharmacyItems = [...pharmacyItems]..removeAt(index);
          if (methodController.text != 'Both') {
            updateAmount();
          }
        });
      },
      onRemoveServiceCharge: (index) {
        setState(() {
          serviceChargeItems = [...serviceChargeItems]..removeAt(index);
          if (methodController.text != 'Both') {
            updateAmount();
          }
        });
      },
      onRemoveProcedure: (index) {
        setState(() {
          procedureItems = [...procedureItems]..removeAt(index);
          if (methodController.text != 'Both') {
            updateAmount();
          }
        });
      },
      onPaymentMethodChanged: (_) => setState(() {}),
      onDentitionChanged: (dentition) => setState(() {
        selectedDentition = dentition;
        selectedTooth = dentition.teeth.first;
      }),
      onToothChanged: (tooth) => setState(() => selectedTooth = tooth),
    );
  }
}

class _RecordPaymentDetail extends StatefulWidget {
  const _RecordPaymentDetail({required this.onBack, required this.onRecorded});

  final VoidCallback onBack;
  final ValueChanged<Invoice> onRecorded;

  @override
  State<_RecordPaymentDetail> createState() => _RecordPaymentDetailState();
}

class _RecordPaymentDetailState extends State<_RecordPaymentDetail> {
  final patientController = TextEditingController();
  final invoiceNumberController = TextEditingController(text: 'INV-1052');
  final procedureController = TextEditingController();
  final priceController = TextEditingController();
  final procedurePriceController = TextEditingController();
  final serviceFeeController = TextEditingController();
  final methodController = TextEditingController(text: 'Cash');
  final secondaryMethodController = TextEditingController(text: 'Bank');
  final amountController = TextEditingController();
  final cashAmountController = TextEditingController();
  final secondaryAmountController = TextEditingController();
  final paidDateController = TextEditingController(text: 'Today');
  final referenceController = TextEditingController(text: 'PAY-2041');
  final noteController = TextEditingController();
  final followUpDateController = TextEditingController();
  final followUpTimeController = TextEditingController();
  ClinicUser? selectedPatient;
  var serviceChargeItems = <ServiceChargeItem>[];
  var pharmacyItems = <PharmacyInvoiceItem>[];

  @override
  void initState() {
    super.initState();
    priceController.text = cashierDefaultDoctorFee;
    serviceFeeController.text = cashierDefaultServiceCharge;
    amountController.text = _formatCurrencyValue(
      _formChargeTotal(),
    ).replaceFirst('RM ', '');
  }

  @override
  void dispose() {
    patientController.dispose();
    invoiceNumberController.dispose();
    procedureController.dispose();
    priceController.dispose();
    procedurePriceController.dispose();
    serviceFeeController.dispose();
    methodController.dispose();
    secondaryMethodController.dispose();
    amountController.dispose();
    cashAmountController.dispose();
    secondaryAmountController.dispose();
    paidDateController.dispose();
    referenceController.dispose();
    noteController.dispose();
    followUpDateController.dispose();
    followUpTimeController.dispose();
    super.dispose();
  }

  void submit() {
    final patient = patientController.text.trim();
    final invoiceNumber = invoiceNumberController.text.trim();
    final procedure = procedureController.text.trim();
    final price = priceController.text.trim();
    final procedurePrice = procedurePriceController.text.trim();
    final serviceFee = serviceFeeController.text.trim();
    final method = methodController.text.trim();
    final secondaryMethod = secondaryMethodController.text.trim();
    final amount = amountController.text.trim();
    final cashAmount = cashAmountController.text.trim();
    final secondaryAmount = secondaryAmountController.text.trim();
    final paidDate = paidDateController.text.trim();
    final reference = referenceController.text.trim();
    final isSplitPayment = method == 'Both';

    final defaultPayAmount = _formatCurrencyValue(
      _formChargeTotal(
        doctorFee: price,
        procedurePrice: procedurePrice,
        serviceFee: serviceFee,
      ),
    );
    final standardAmount =
        amount.isEmpty &&
            [price, procedurePrice, serviceFee].any((value) => value.isNotEmpty)
        ? defaultPayAmount
        : amount;
    final missingStandardPayment = !isSplitPayment && standardAmount.isEmpty;
    final missingSplitPayment =
        isSplitPayment &&
        [
          cashAmount,
          secondaryMethod,
          secondaryAmount,
        ].any((value) => value.isEmpty);

    if ([
          patient,
          invoiceNumber,
          method,
          paidDate,
          reference,
        ].any((value) => value.isEmpty) ||
        missingStandardPayment ||
        missingSplitPayment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all payment fields')),
      );
      return;
    }

    final paymentMethod = isSplitPayment
        ? 'Both: Cash + $secondaryMethod'
        : method;
    final formattedAmount = isSplitPayment
        ? 'Cash ${_formatCurrency(cashAmount)} + $secondaryMethod ${_formatCurrency(secondaryAmount)}'
        : _formatCurrency(standardAmount);

    widget.onRecorded(
      Invoice(
        patient,
        invoiceNumber,
        paymentMethod,
        'Paid today',
        formattedAmount,
        const Color(0xFF166534),
        CashDetailFilter.paidToday,
        procedure: procedure,
        price: price.isEmpty ? '' : _formatCurrency(price),
        procedurePrice: procedurePrice.isEmpty
            ? ''
            : _formatCurrency(procedurePrice),
        serviceFee: serviceFee.isEmpty ? '' : _formatCurrency(serviceFee),
        serviceChargeItems: serviceChargeItems,
        clinicalNote: _combineFollowUpNote(
          noteController.text,
          followUpDateController.text,
          followUpTimeController.text,
        ),
        pharmacyItems: pharmacyItems,
      ),
    );
  }

  void choosePatient(ClinicUser? patient) {
    setState(() {
      selectedPatient = patient;
      patientController.text = patient?.name ?? '';

      final billing = patient == null ? null : billingForPatient(patient.name);
      procedureController.text = billing?.procedure ?? '';
      if (billing?.price.isNotEmpty ?? false) {
        procedurePriceController.text = billing!.price;
      }
      if (methodController.text != 'Both') {
        updateAmount();
      }
    });
  }

  void chooseProcedure(DentalProcedure? procedure) {
    setState(() {
      procedureController.text = procedure?.name ?? '';
      if (procedure?.price.isNotEmpty ?? false) {
        procedurePriceController.text = procedure!.price;
      }
      if (methodController.text != 'Both') {
        updateAmount();
      }
    });
  }

  Future<void> addMedicine(Medicine medicine) async {
    final item = await showMedicineAmountDialog(context, medicine);
    if (item == null) {
      return;
    }

    setState(() {
      pharmacyItems = [...pharmacyItems, item];
      if (methodController.text != 'Both') {
        updateAmount();
      }
    });
  }

  Future<void> editMedicineItem(int index) async {
    final item = await showPharmacyInvoiceItemEditor(
      context,
      pharmacyItems[index],
    );
    if (item == null) {
      return;
    }

    setState(() {
      pharmacyItems = [...pharmacyItems]..[index] = item;
      if (methodController.text != 'Both') {
        updateAmount();
      }
    });
  }

  Future<void> addServiceCharge() async {
    final fee = await showServiceChargePicker(context);
    if (fee == null) {
      return;
    }

    setState(() {
      serviceChargeItems = [
        ...serviceChargeItems,
        ServiceChargeItem(fee.name, fee.price),
      ];
      if (methodController.text != 'Both') {
        updateAmount();
      }
    });
  }

  Future<void> editServiceChargeItem(int index) async {
    final item = await showServiceChargeItemEditor(
      context,
      serviceChargeItems[index],
    );
    if (item == null) {
      return;
    }

    setState(() {
      serviceChargeItems = [...serviceChargeItems]..[index] = item;
      if (methodController.text != 'Both') {
        updateAmount();
      }
    });
  }

  Future<void> openMedicinePicker() async {
    final medicine = await showMedicinePicker(context);
    if (medicine != null) {
      await addMedicine(medicine);
    }
  }

  Future<void> openPatientPicker() async {
    final patient = await showPatientPicker(context);
    if (patient != null) {
      choosePatient(patient);
    }
  }

  Future<void> openProcedurePicker() async {
    final procedure = await showProcedurePicker(context);
    if (procedure != null) {
      chooseProcedure(procedure);
    }
  }

  Future<void> openDoctorFeePicker() async {
    final fee = await showDoctorFeePicker(context);
    if (fee == null) {
      return;
    }

    setState(() {
      priceController.text = fee.displayLabel;
      cashierDefaultDoctorFee = fee.displayLabel;
      if (methodController.text != 'Both') {
        updateAmount();
      }
    });
  }

  Future<void> openServiceChargePicker() async {
    final fee = await showServiceChargePicker(context);
    if (fee == null) {
      return;
    }

    setState(() {
      serviceFeeController.text = fee.displayLabel;
      cashierDefaultServiceCharge = fee.displayLabel;
      if (methodController.text != 'Both') {
        updateAmount();
      }
    });
  }

  double _formChargeTotal({
    String? doctorFee,
    String? procedurePrice,
    String? serviceFee,
  }) {
    return _currencyValue(doctorFee ?? priceController.text) +
        _currencyValue(procedurePrice ?? procedurePriceController.text) +
        _currencyValue(serviceFee ?? serviceFeeController.text) +
        serviceChargeItems.fold<double>(
          0,
          (sum, item) => sum + _currencyValue(item.price),
        ) +
        pharmacyItems.fold<double>(
          0,
          (sum, item) => sum + _currencyValue(item.price),
        );
  }

  void updateAmount() {
    amountController.text = _formatCurrencyValue(
      _formChargeTotal(),
    ).replaceFirst('RM ', '');
  }

  @override
  Widget build(BuildContext context) {
    return _MtdCashierDetailScaffold(
      primaryActionLabel: 'Record Payment',
      primaryActionIcon: Icons.payments,
      onBack: widget.onBack,
      onSubmit: submit,
      patientController: patientController,
      invoiceController: invoiceNumberController,
      procedureController: procedureController,
      priceController: priceController,
      procedurePriceController: procedurePriceController,
      serviceFeeController: serviceFeeController,
      serviceChargeItems: serviceChargeItems,
      procedureItems: const [],
      methodController: methodController,
      secondaryMethodController: secondaryMethodController,
      amountController: amountController,
      cashAmountController: cashAmountController,
      secondaryAmountController: secondaryAmountController,
      paidDateController: paidDateController,
      referenceController: referenceController,
      noteController: noteController,
      followUpDateController: followUpDateController,
      followUpTimeController: followUpTimeController,
      pharmacyItems: pharmacyItems,
      onPickPatient: openPatientPicker,
      onPickDoctorFee: openDoctorFeePicker,
      onPickServiceFee: openServiceChargePicker,
      onAddServiceCharge: addServiceCharge,
      onPickProcedure: openProcedurePicker,
      onPickMedicine: openMedicinePicker,
      onEditMedicine: editMedicineItem,
      onEditServiceCharge: editServiceChargeItem,
      onEditProcedure: (_) {},
      onRemoveProcedure: (_) {},
      onRemoveMedicine: (index) {
        setState(() {
          pharmacyItems = [...pharmacyItems]..removeAt(index);
          if (methodController.text != 'Both') {
            updateAmount();
          }
        });
      },
      onRemoveServiceCharge: (index) {
        setState(() {
          serviceChargeItems = [...serviceChargeItems]..removeAt(index);
          if (methodController.text != 'Both') {
            updateAmount();
          }
        });
      },
      onPaymentMethodChanged: (_) => setState(() {}),
    );
  }
}

class _MtdCashierDetailScaffold extends StatelessWidget {
  const _MtdCashierDetailScaffold({
    required this.primaryActionLabel,
    required this.primaryActionIcon,
    required this.onBack,
    required this.onSubmit,
    required this.patientController,
    required this.invoiceController,
    required this.procedureController,
    required this.priceController,
    required this.procedurePriceController,
    this.primaryProcedureTeeth = '',
    required this.serviceFeeController,
    required this.serviceChargeItems,
    required this.procedureItems,
    required this.methodController,
    required this.secondaryMethodController,
    required this.amountController,
    required this.cashAmountController,
    required this.secondaryAmountController,
    required this.noteController,
    required this.followUpDateController,
    required this.followUpTimeController,
    required this.pharmacyItems,
    required this.onPickPatient,
    required this.onPickProcedure,
    required this.onPickMedicine,
    required this.onAddServiceCharge,
    required this.onEditMedicine,
    required this.onEditServiceCharge,
    required this.onEditProcedure,
    required this.onRemoveMedicine,
    required this.onRemoveServiceCharge,
    required this.onRemoveProcedure,
    required this.onPaymentMethodChanged,
    this.doctorController,
    this.statusController,
    this.paidDateController,
    this.referenceController,
    this.selectedDentition,
    this.selectedTooth,
    this.onPickDoctor,
    this.onPickDoctorFee,
    this.onPickServiceFee,
    this.onJoinProcedure,
    this.onDentitionChanged,
    this.onToothChanged,
    this.showWaitingToCash = false,
    this.onPickWaitingPatient,
  });

  final String primaryActionLabel;
  final IconData primaryActionIcon;
  final VoidCallback onBack;
  final VoidCallback onSubmit;
  final TextEditingController patientController;
  final TextEditingController invoiceController;
  final TextEditingController? doctorController;
  final TextEditingController procedureController;
  final TextEditingController priceController;
  final TextEditingController procedurePriceController;
  final String primaryProcedureTeeth;
  final TextEditingController serviceFeeController;
  final TextEditingController methodController;
  final TextEditingController secondaryMethodController;
  final TextEditingController amountController;
  final TextEditingController cashAmountController;
  final TextEditingController secondaryAmountController;
  final TextEditingController? statusController;
  final TextEditingController? paidDateController;
  final TextEditingController? referenceController;
  final TextEditingController noteController;
  final TextEditingController followUpDateController;
  final TextEditingController followUpTimeController;
  final List<ServiceChargeItem> serviceChargeItems;
  final List<ProcedureInvoiceItem> procedureItems;
  final List<PharmacyInvoiceItem> pharmacyItems;
  final DentitionType? selectedDentition;
  final String? selectedTooth;
  final VoidCallback onPickPatient;
  final VoidCallback? onPickDoctor;
  final VoidCallback? onPickDoctorFee;
  final VoidCallback? onPickServiceFee;
  final VoidCallback onPickProcedure;
  final VoidCallback? onJoinProcedure;
  final VoidCallback onPickMedicine;
  final VoidCallback onAddServiceCharge;
  final ValueChanged<int> onEditMedicine;
  final ValueChanged<int> onEditServiceCharge;
  final ValueChanged<int> onEditProcedure;
  final ValueChanged<int> onRemoveMedicine;
  final ValueChanged<int> onRemoveServiceCharge;
  final ValueChanged<int> onRemoveProcedure;
  final ValueChanged<String> onPaymentMethodChanged;
  final ValueChanged<DentitionType>? onDentitionChanged;
  final ValueChanged<String>? onToothChanged;
  final bool showWaitingToCash;
  final VoidCallback? onPickWaitingPatient;

  @override
  Widget build(BuildContext context) {
    final listenables = List<Listenable>.of([
      patientController,
      invoiceController,
      procedureController,
      priceController,
      procedurePriceController,
      serviceFeeController,
      methodController,
      secondaryMethodController,
      amountController,
      cashAmountController,
      secondaryAmountController,
      noteController,
      followUpDateController,
      followUpTimeController,
    ]);
    if (doctorController != null) listenables.add(doctorController!);
    if (statusController != null) listenables.add(statusController!);
    if (paidDateController != null) listenables.add(paidDateController!);
    if (referenceController != null) listenables.add(referenceController!);

    return AnimatedBuilder(
      animation: Listenable.merge(listenables),
      builder: (context, _) {
        final splitPayment = methodController.text == 'Both';

        return SingleChildScrollView(
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to cash'),
                  ),
                ),
                const SizedBox(height: 8),
                if (showWaitingToCash)
                  _MtdCashWaitingHeader(
                    onPickWaitingPatient: onPickWaitingPatient,
                  )
                else
                  _MtdSectionStrip(label: 'Patient Info'),
                const SizedBox(height: 14),
                _MtdCashierField(
                  controller: patientController,
                  label: 'Name (required)',
                  icon: Icons.person_outline,
                  onPick: onPickPatient,
                ),
                _MtdCashierField(
                  controller: invoiceController,
                  label: 'Invoice Number',
                  icon: Icons.receipt_long,
                ),
                if (doctorController != null)
                  _MtdCashierField(
                    controller: doctorController!,
                    label: 'Doctor',
                    icon: Icons.medical_services_outlined,
                    onPick: onPickDoctor,
                  ),
                _MtdCashierField(
                  controller: priceController,
                  label: 'Doctor Fee',
                  icon: Icons.sell_outlined,
                  onPick: onPickDoctorFee,
                ),
                _MtdCashierField(
                  controller: serviceFeeController,
                  label: 'Service Charge',
                  icon: Icons.room_service_outlined,
                  keyboardType: TextInputType.number,
                  onPick: onPickServiceFee,
                ),
                if (selectedDentition != null && selectedTooth != null) ...[
                  _ToothSelector(
                    dentition: selectedDentition!,
                    selectedTooth: selectedTooth!,
                    onDentitionChanged: onDentitionChanged ?? (_) {},
                    onToothChanged: onToothChanged ?? (_) {},
                    onJoinProcedure: onJoinProcedure,
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: _MtdOutlineCommand(
                        label: 'Add Procedure',
                        icon: Icons.add_circle_outline,
                        onPressed: onPickProcedure,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MtdOutlineCommand(
                        label: 'Add Product',
                        icon: Icons.add_shopping_cart_outlined,
                        onPressed: onPickMedicine,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MtdOutlineCommand(
                        label: 'More Service Charge',
                        icon: Icons.room_service_outlined,
                        onPressed: onAddServiceCharge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _MtdInvoiceTable(
                  procedure: procedureController.text.trim().isEmpty
                      ? 'Doctor Fees'
                      : procedureController.text.trim(),
                  doctorFee: priceController.text.trim(),
                  procedurePrice: procedurePriceController.text.trim(),
                  primaryProcedureTeeth: primaryProcedureTeeth,
                  serviceFee: serviceFeeController.text.trim(),
                  serviceChargeItems: serviceChargeItems,
                  procedureItems: procedureItems,
                  pharmacyItems: pharmacyItems,
                  onEditServiceCharge: onEditServiceCharge,
                  onEditProcedure: onEditProcedure,
                  onEditMedicine: onEditMedicine,
                  onRemoveServiceCharge: onRemoveServiceCharge,
                  onRemoveProcedure: onRemoveProcedure,
                  onRemoveMedicine: onRemoveMedicine,
                  paidAmount: splitPayment
                      ? _formatCurrencyValue(
                          _currencyValue(cashAmountController.text) +
                              _currencyValue(secondaryAmountController.text),
                        )
                      : amountController.text.trim(),
                ),
                const SizedBox(height: 14),
                _PaymentMethodSelectField(
                  controller: methodController,
                  onChanged: onPaymentMethodChanged,
                ),
                if (splitPayment) ...[
                  _MtdCashierField(
                    controller: cashAmountController,
                    label: 'Cash Amount',
                    icon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  _PaymentMethodSelectField(
                    controller: secondaryMethodController,
                    methods: secondaryPaymentMethods,
                    label: 'Other method',
                    icon: Icons.account_balance_outlined,
                    onChanged: onPaymentMethodChanged,
                  ),
                  _MtdCashierField(
                    controller: secondaryAmountController,
                    label: '${secondaryMethodController.text} Amount',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                  ),
                ] else
                  _MtdCashierField(
                    controller: amountController,
                    label: 'PAY Amount',
                    icon: Icons.attach_money,
                    keyboardType: TextInputType.number,
                  ),
                if (statusController != null)
                  _MtdCashierField(
                    controller: statusController!,
                    label: 'Status',
                    icon: Icons.fact_check_outlined,
                  ),
                if (paidDateController != null)
                  _MtdCashierField(
                    controller: paidDateController!,
                    label: 'Payment Date',
                    icon: Icons.today_outlined,
                  ),
                if (referenceController != null)
                  _MtdCashierField(
                    controller: referenceController!,
                    label: 'Reference Number',
                    icon: Icons.confirmation_number_outlined,
                  ),
                _MtdSectionStrip(label: 'Follow Up'),
                const SizedBox(height: 12),
                _MtdFollowUpScheduleRow(
                  noteController: noteController,
                  dateController: followUpDateController,
                  timeController: followUpTimeController,
                ),
                FilledButton.icon(
                  onPressed: onSubmit,
                  icon: Icon(primaryActionIcon),
                  label: Text(primaryActionLabel),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MtdSectionStrip extends StatelessWidget {
  const _MtdSectionStrip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '<< $label >>',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _MtdCashWaitingHeader extends StatelessWidget {
  const _MtdCashWaitingHeader({this.onPickWaitingPatient});

  final VoidCallback? onPickWaitingPatient;

  @override
  Widget build(BuildContext context) {
    final cashQueue = sampleQueueStatuses.last;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final fields = [
          _MtdCashWaitingField(
            icon: Icons.person_outline,
            label: 'Cash patient',
            value: cashQueue.currentPatient,
          ),
          _MtdCashWaitingField(
            icon: Icons.receipt_long_outlined,
            label: 'Booking',
            value: cashQueue.currentBooking,
          ),
          _MtdCashWaitingField(
            icon: Icons.schedule_outlined,
            label: 'Wait',
            value: cashQueue.estimatedTime,
          ),
        ];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(child: _MtdSectionStrip(label: 'Patient Info')),
            if (!compact) ...[
              const SizedBox(width: 12),
              SizedBox(
                width: 410,
                child: Row(
                  children: [
                    for (var index = 0; index < fields.length; index++) ...[
                      if (index > 0) const SizedBox(width: 8),
                      Expanded(child: fields[index]),
                    ],
                    const SizedBox(width: 8),
                    Tooltip(
                      message:
                          'Add ${cashQueue.currentPatient} from waiting list',
                      child: IconButton.filledTonal(
                        onPressed: onPickWaitingPatient,
                        icon: const Icon(Icons.person_add_alt_1),
                        style: IconButton.styleFrom(
                          minimumSize: const Size(52, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (compact) ...[
              const SizedBox(width: 8),
              Tooltip(
                message: 'Add ${cashQueue.currentPatient} from waiting list',
                child: IconButton.filledTonal(
                  onPressed: onPickWaitingPatient,
                  icon: const Icon(Icons.person_add_alt_1),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(52, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _MtdCashWaitingField extends StatelessWidget {
  const _MtdCashWaitingField({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final teal = Theme.of(context).colorScheme.primary;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCE3EA)),
      ),
      child: Row(
        children: [
          Icon(icon, color: teal, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MtdCashierField extends StatelessWidget {
  const _MtdCashierField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.onPick,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final teal = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: 1,
        style: const TextStyle(fontWeight: FontWeight.w800),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: teal),
          suffixIcon: onPick == null
              ? null
              : IconButton(
                  tooltip: 'Select',
                  onPressed: onPick,
                  icon: const Icon(Icons.add_circle_outline),
                ),
          filled: true,
          fillColor: const Color(0xFFEAF8F6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF7A8691), width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: teal, width: 1.6),
          ),
        ),
      ),
    );
  }
}

class _MtdFollowUpScheduleRow extends StatelessWidget {
  const _MtdFollowUpScheduleRow({
    required this.noteController,
    required this.dateController,
    required this.timeController,
  });

  final TextEditingController noteController;
  final TextEditingController dateController;
  final TextEditingController timeController;

  Future<void> pickDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (picked == null) {
      return;
    }

    dateController.text = _formatDate(picked);
  }

  Future<void> pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) {
      return;
    }

    timeController.text = _formatTimeOfDay(picked);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 720;
        final noteField = _MtdCashierField(
          controller: noteController,
          label: 'Follow Up',
          icon: Icons.event_repeat_outlined,
        );
        final dateField = _MtdCashierField(
          controller: dateController,
          label: 'Date',
          icon: Icons.calendar_month_outlined,
          onPick: () => pickDate(context),
        );
        final timeField = _MtdCashierField(
          controller: timeController,
          label: 'Time',
          icon: Icons.schedule_outlined,
          onPick: () => pickTime(context),
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [noteField, dateField, timeField],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: noteField),
            const SizedBox(width: 10),
            Expanded(child: dateField),
            const SizedBox(width: 10),
            Expanded(child: timeField),
          ],
        );
      },
    );
  }
}

class _MtdOutlineCommand extends StatelessWidget {
  const _MtdOutlineCommand({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final teal = Theme.of(context).colorScheme.primary;

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: teal,
        minimumSize: const Size.fromHeight(48),
        side: BorderSide(color: teal),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _MtdInvoiceTable extends StatelessWidget {
  const _MtdInvoiceTable({
    required this.procedure,
    required this.doctorFee,
    required this.procedurePrice,
    required this.primaryProcedureTeeth,
    required this.serviceFee,
    required this.serviceChargeItems,
    required this.procedureItems,
    required this.pharmacyItems,
    required this.onEditServiceCharge,
    required this.onEditProcedure,
    required this.onEditMedicine,
    required this.onRemoveServiceCharge,
    required this.onRemoveProcedure,
    required this.onRemoveMedicine,
    required this.paidAmount,
  });

  final String procedure;
  final String doctorFee;
  final String procedurePrice;
  final String primaryProcedureTeeth;
  final String serviceFee;
  final List<ServiceChargeItem> serviceChargeItems;
  final List<ProcedureInvoiceItem> procedureItems;
  final List<PharmacyInvoiceItem> pharmacyItems;
  final ValueChanged<int> onEditServiceCharge;
  final ValueChanged<int> onEditProcedure;
  final ValueChanged<int> onEditMedicine;
  final ValueChanged<int> onRemoveServiceCharge;
  final ValueChanged<int> onRemoveProcedure;
  final ValueChanged<int> onRemoveMedicine;
  final String paidAmount;

  Widget _rowActions({
    required VoidCallback onEdit,
    required VoidCallback onRemove,
    required String editTooltip,
    required String removeTooltip,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: editTooltip,
          onPressed: onEdit,
          icon: const Icon(Icons.edit_outlined, size: 17),
        ),
        IconButton(
          tooltip: removeTooltip,
          onPressed: onRemove,
          icon: const Icon(Icons.close, size: 18),
        ),
      ],
    );
  }

  Widget _productActions(int index) {
    return _rowActions(
      editTooltip: 'Edit product',
      removeTooltip: 'Remove product',
      onEdit: () => onEditMedicine(index),
      onRemove: () => onRemoveMedicine(index),
    );
  }

  Widget _serviceChargeActions(int index) {
    return _rowActions(
      editTooltip: 'Edit service charge',
      removeTooltip: 'Remove service charge',
      onEdit: () => onEditServiceCharge(index),
      onRemove: () => onRemoveServiceCharge(index),
    );
  }

  Widget _procedureActions(int index) {
    return _rowActions(
      editTooltip: 'Edit joined procedure',
      removeTooltip: 'Remove joined procedure',
      onEdit: () => onEditProcedure(index),
      onRemove: () => onRemoveProcedure(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasProcedureRow = procedure.isNotEmpty && procedure != 'Doctor Fees';
    var rowNumber = 1;
    String nextNumber() => '${rowNumber++}';
    final rows = <_MtdInvoiceRow>[
      _MtdInvoiceRow(nextNumber(), 'Doctor Fee', 1, doctorFee),
      _MtdInvoiceRow(nextNumber(), 'Service Charge', 1, serviceFee),
      for (var i = 0; i < serviceChargeItems.length; i++)
        _MtdInvoiceRow(
          nextNumber(),
          serviceChargeItems[i].name,
          1,
          serviceChargeItems[i].price,
          trailing: _serviceChargeActions(i),
        ),
      if (hasProcedureRow)
        _MtdInvoiceRow(
          nextNumber(),
          primaryProcedureTeeth.isEmpty
              ? procedure
              : '$primaryProcedureTeeth - $procedure',
          1,
          procedurePrice,
        ),
      for (var i = 0; i < procedureItems.length; i++)
        _MtdInvoiceRow(
          nextNumber(),
          '${procedureItems[i].teeth} - ${procedureItems[i].name}',
          1,
          procedureItems[i].price,
          trailing: _procedureActions(i),
        ),
      for (var i = 0; i < pharmacyItems.length; i++)
        _MtdInvoiceRow(
          nextNumber(),
          pharmacyItems[i].name,
          pharmacyItems[i].quantity,
          pharmacyItems[i].price,
          trailing: _productActions(i),
        ),
    ];
    while (rows.length < 7) {
      rows.add(_MtdInvoiceRow('${rows.length + 1}', '', 0, ''));
    }

    final total =
        _currencyValue(doctorFee) +
        _currencyValue(procedurePrice) +
        _currencyValue(serviceFee) +
        procedureItems.fold<double>(
          0,
          (sum, item) => sum + _currencyValue(item.price),
        ) +
        serviceChargeItems.fold<double>(
          0,
          (sum, item) => sum + _currencyValue(item.price),
        ) +
        pharmacyItems.fold<double>(
          0,
          (sum, item) => sum + _currencyValue(item.price),
        );
    final paid = _currencyValue(paidAmount);
    final balance = (total - paid).clamp(0, double.infinity);
    final teal = Theme.of(context).colorScheme.primary;

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Table(
            columnWidths: const {
              0: FixedColumnWidth(58),
              1: FlexColumnWidth(3),
              2: FixedColumnWidth(92),
              3: FlexColumnWidth(1.6),
              4: FlexColumnWidth(1.6),
            },
            border: TableBorder.all(color: teal.withValues(alpha: 0.75)),
            children: [
              TableRow(
                decoration: BoxDecoration(color: teal),
                children: const [
                  _MtdTableCell('No', header: true),
                  _MtdTableCell('Description', header: true),
                  _MtdTableCell('Quantity', header: true),
                  _MtdTableCell('Price', header: true),
                  _MtdTableCell('Amount', header: true),
                ],
              ),
              for (var i = 0; i < rows.length; i++)
                TableRow(
                  decoration: BoxDecoration(
                    color: i.isOdd ? const Color(0xFFD5F0ED) : Colors.white,
                  ),
                  children: [
                    _MtdTableCell(rows[i].number),
                    _MtdTableCell(
                      rows[i].description,
                      trailing: rows[i].trailing,
                    ),
                    _MtdTableCell(
                      rows[i].quantity == 0 ? '---' : '${rows[i].quantity}',
                    ),
                    _MtdTableCell(
                      rows[i].price.isEmpty
                          ? '---'
                          : _formatCurrencyValue(_currencyValue(rows[i].price)),
                    ),
                    _MtdTableCell(
                      rows[i].price.isEmpty
                          ? '---'
                          : _formatCurrencyValue(_currencyValue(rows[i].price)),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _MtdTotalRow(label: 'Total', value: _formatCurrencyValue(total)),
        _MtdTotalRow(
          label: 'PAY Amount',
          value: paid == 0 ? '---' : _formatCurrencyValue(paid),
          valueIsInput: true,
        ),
        _MtdTotalRow(label: 'Balance', value: _formatCurrencyValue(balance)),
      ],
    );
  }
}

class _MtdInvoiceRow {
  const _MtdInvoiceRow(
    this.number,
    this.description,
    this.quantity,
    this.price, {
    this.trailing,
  });

  final String number;
  final String description;
  final int quantity;
  final String price;
  final Widget? trailing;
}

class _MtdTableCell extends StatelessWidget {
  const _MtdTableCell(this.text, {this.header = false, this.trailing});

  final String text;
  final bool header;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      text,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: header ? Colors.white : const Color(0xFF17212B),
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    );

    return Container(
      height: header ? 48 : 46,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      child: trailing == null
          ? child
          : Row(
              children: [
                Expanded(child: child),
                trailing!,
              ],
            ),
    );
  }
}

class _MtdTotalRow extends StatelessWidget {
  const _MtdTotalRow({
    required this.label,
    required this.value,
    this.valueIsInput = false,
  });

  final String label;
  final String value;
  final bool valueIsInput;

  @override
  Widget build(BuildContext context) {
    final teal = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: teal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 2,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: valueIsInput ? Colors.white : teal,
                borderRadius: BorderRadius.circular(8),
                border: valueIsInput
                    ? Border.all(color: const Color(0xFF7A8691))
                    : null,
              ),
              child: Text(
                value,
                style: TextStyle(
                  color: valueIsInput ? const Color(0xFF17212B) : Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

double _currencyValue(String value) {
  final numeric = value.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(numeric) ?? 0;
}

String _formatCurrencyValue(num value) {
  final rounded = value.round();
  return 'RM ${rounded.toString()}';
}

Future<ClinicUser?> showPatientPicker(BuildContext context) {
  final patients = sampleUsers
      .where((user) => user.role == RoleFilter.user.label)
      .toList();

  return showDialog<ClinicUser>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Choose patient'),
      children: [
        for (final patient in patients)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(patient),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: patient.color.withValues(alpha: 0.14),
                child: Text(
                  patient.initials,
                  style: TextStyle(
                    color: patient.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              title: Text(patient.name),
              subtitle: Text(patient.phone),
            ),
          ),
      ],
    ),
  );
}

Future<AppointmentStatusDetail?> showWaitingCashPatientPicker(
  BuildContext context,
) {
  final waitingPatients = sampleAppointmentStatusDetails
      .where((detail) => detail.filter == AppointmentStatusFilter.waiting)
      .toList();

  return showDialog<AppointmentStatusDetail>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Add from waiting list'),
      children: [
        for (final detail in waitingPatients)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(detail),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: const Color(
                  0xFF0B7285,
                ).withValues(alpha: 0.14),
                child: const Icon(
                  Icons.hourglass_top_outlined,
                  color: Color(0xFF0B7285),
                ),
              ),
              title: Text('${detail.bookingId} - ${detail.patient}'),
              subtitle: Text(
                '${detail.time} - ${detail.procedure} - ${detail.doctor}',
              ),
            ),
          ),
      ],
    ),
  );
}

Future<DentalProcedure?> showProcedurePicker(BuildContext context) {
  return showDialog<DentalProcedure>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Choose procedure'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final procedureClass in nestedProcedureDatabase)
                _NestedProcedureClassTile(procedureClass: procedureClass),
            ],
          ),
        ),
      ),
    ),
  );
}

class _NestedProcedureClassTile extends StatelessWidget {
  const _NestedProcedureClassTile({required this.procedureClass});

  final NestedProcedureClass procedureClass;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: procedureClass.color.withValues(alpha: 0.14),
        child: Icon(procedureClass.icon, color: procedureClass.color),
      ),
      title: Text(
        procedureClass.name,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(procedureClass.description),
      children: [
        for (final feature in procedureClass.features)
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 4, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  feature.name,
                  style: TextStyle(
                    color: procedureClass.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                for (final value in feature.values)
                  Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      title: Text(value.name),
                      subtitle: Text(value.estimate),
                      trailing: Text(
                        value.price,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      onTap: () => Navigator.of(context).pop(
                        DentalProcedure(
                          '${procedureClass.name} / ${feature.name} / ${value.name}',
                          value.stage,
                          value.doctor,
                          value.progress,
                          procedureClass.icon,
                          procedureClass.color,
                          value.price,
                          value.estimate,
                          procedureClass.name,
                          feature.name,
                          value.name,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

Future<Doctor?> showDoctorPicker(BuildContext context) {
  return showDialog<Doctor>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Choose doctor'),
      children: [
        for (final doctor in sampleDoctors)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(doctor),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: doctor.color.withValues(alpha: 0.14),
                child: Icon(Icons.medical_services, color: doctor.color),
              ),
              title: Text(doctor.name),
              subtitle: Text('${doctor.specialty} - ${doctor.status}'),
            ),
          ),
      ],
    ),
  );
}

Future<DoctorFeeOption?> showDoctorFeePicker(BuildContext context) {
  return showDialog<DoctorFeeOption>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Choose doctor fee'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final feeClass in nestedDoctorFeeDatabase)
                _NestedDoctorFeeClassTile(feeClass: feeClass),
            ],
          ),
        ),
      ),
    ),
  );
}

Future<DoctorFeeOption?> showServiceChargePicker(BuildContext context) {
  return showDialog<DoctorFeeOption>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Choose service charge'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final feeClass in nestedServiceChargeDatabase)
                _NestedDoctorFeeClassTile(feeClass: feeClass),
            ],
          ),
        ),
      ),
    ),
  );
}

class _NestedDoctorFeeClassTile extends StatelessWidget {
  const _NestedDoctorFeeClassTile({required this.feeClass});

  final NestedDoctorFeeClass feeClass;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: feeClass.color.withValues(alpha: 0.14),
        child: Icon(feeClass.icon, color: feeClass.color),
      ),
      title: Text(
        feeClass.name,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(feeClass.description),
      children: [
        for (final feature in feeClass.features)
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 4, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  feature.name,
                  style: TextStyle(
                    color: feeClass.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                for (final option in feature.options)
                  Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      title: Text(option.name),
                      subtitle: Text(option.note),
                      trailing: Text(
                        option.price,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      onTap: () => Navigator.of(context).pop(option),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

Future<Medicine?> showMedicinePicker(BuildContext context) {
  return showDialog<Medicine>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Choose pharmacy item'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final productClass in nestedProductDatabase)
                _NestedProductClassTile(productClass: productClass),
            ],
          ),
        ),
      ),
    ),
  );
}

class _NestedProductClassTile extends StatelessWidget {
  const _NestedProductClassTile({required this.productClass});

  final NestedProductClass productClass;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: productClass.color.withValues(alpha: 0.14),
        child: Icon(productClass.icon, color: productClass.color),
      ),
      title: Text(
        productClass.name,
        style: const TextStyle(fontWeight: FontWeight.w900),
      ),
      subtitle: Text(productClass.description),
      children: [
        for (final feature in productClass.features)
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 4, bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  feature.name,
                  style: TextStyle(
                    color: productClass.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                for (final option in feature.options)
                  Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      title: Text(option.name),
                      subtitle: Text(
                        '${option.stock} ${option.unit} available',
                      ),
                      trailing: Text(
                        option.price,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      onTap: () => Navigator.of(context).pop(
                        Medicine(
                          '${productClass.name} ${feature.name} ${option.name}',
                          productClass.name,
                          option.stock,
                          option.stock,
                          option.unit,
                          option.batch,
                          option.expiry,
                          option.status,
                          productClass.color,
                          price: option.price,
                          productClass: productClass.name,
                          productFeature: feature.name,
                          productOption: option.name,
                          priceNature: _defaultPriceNatures(
                            option.price,
                            option.unit,
                          ).first,
                          priceNatures: _defaultPriceNatures(
                            option.price,
                            option.unit,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

Future<PharmacyInvoiceItem?> showMedicineAmountDialog(
  BuildContext context,
  Medicine medicine,
) {
  final priceNatures = medicine.priceNatures.isEmpty
      ? [
          medicine.priceNature ??
              PriceNature(
                'Smallest',
                1,
                medicine.unit,
                medicine.hasPrice
                    ? medicine.price
                    : medicinePrice(medicine.name),
              ),
        ]
      : medicine.priceNatures;
  var selectedPriceNature = priceNatures.firstWhere(
    (nature) => nature.name.toLowerCase() == 'smallest',
    orElse: () => priceNatures.first,
  );
  final quantityController = TextEditingController(text: '1');
  final amountController = TextEditingController(
    text: _formatCurrencyValue(_currencyValue(selectedPriceNature.price)),
  );

  void syncAmount() {
    final quantity = int.tryParse(quantityController.text.trim()) ?? 1;
    amountController.text = _formatCurrencyValue(
      _currencyValue(selectedPriceNature.price) * quantity,
    );
  }

  return showDialog<PharmacyInvoiceItem>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) {
        void changeQuantity(int delta) {
          final current = int.tryParse(quantityController.text.trim()) ?? 1;
          final next = (current + delta).clamp(1, medicine.stock);
          setDialogState(() {
            quantityController.text = next.toString();
            syncAmount();
          });
        }

        void submit() {
          final quantity = int.tryParse(quantityController.text.trim()) ?? 1;
          final safeQuantity = quantity.clamp(1, medicine.stock);
          final amount = amountController.text.trim();
          if (amount.isEmpty || _currencyValue(amount) == 0) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Enter product amount')),
            );
            return;
          }

          Navigator.of(context).pop(
            PharmacyInvoiceItem(
              '${_lastPathSegment(medicine.name)} - ${selectedPriceNature.name}',
              safeQuantity,
              _formatCurrency(amount),
            ),
          );
        }

        return AlertDialog(
          title: const Text('Product Amount'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: medicine.color.withValues(alpha: 0.14),
                  child: Icon(Icons.local_pharmacy, color: medicine.color),
                ),
                title: Text(medicine.name),
                subtitle: Text(
                  '${selectedPriceNature.price} per ${selectedPriceNature.label} - ${medicine.stock} ${medicine.unit} available',
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PriceNature>(
                initialValue: selectedPriceNature,
                decoration: const InputDecoration(
                  labelText: 'Sell as',
                  prefixIcon: Icon(Icons.inventory_outlined),
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final nature in priceNatures)
                    DropdownMenuItem(
                      value: nature,
                      child: Text(
                        '${nature.name} - ${nature.quantity} ${nature.unit} - ${nature.price}',
                      ),
                    ),
                ],
                onChanged: (nature) {
                  if (nature == null) {
                    return;
                  }
                  setDialogState(() {
                    selectedPriceNature = nature;
                    syncAmount();
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  IconButton.outlined(
                    tooltip: 'Decrease amount',
                    onPressed: () => changeQuantity(-1),
                    icon: const Icon(Icons.remove),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setDialogState(syncAmount),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Increase amount',
                    onPressed: () => changeQuantity(1),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              onPressed: submit,
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: const Text('Add Product'),
            ),
          ],
        );
      },
    ),
  ).whenComplete(() {
    quantityController.dispose();
    amountController.dispose();
  });
}

Future<ServiceChargeItem?> showServiceChargeItemEditor(
  BuildContext context,
  ServiceChargeItem item,
) {
  final nameController = TextEditingController(text: item.name);
  final priceController = TextEditingController(text: item.price);

  return showDialog<ServiceChargeItem>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Service Charge'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(Icons.room_service_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Price',
              prefixIcon: Icon(Icons.payments_outlined),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            final name = nameController.text.trim();
            final price = priceController.text.trim();
            if (name.isEmpty || price.isEmpty) {
              return;
            }
            Navigator.of(
              context,
            ).pop(ServiceChargeItem(name, _formatCurrency(price)));
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save'),
        ),
      ],
    ),
  ).whenComplete(() {
    nameController.dispose();
    priceController.dispose();
  });
}

Future<ProcedureInvoiceItem?> showProcedureInvoiceItemEditor(
  BuildContext context,
  ProcedureInvoiceItem item,
) {
  final nameController = TextEditingController(text: item.name);
  final teethController = TextEditingController(text: item.teeth);
  final priceController = TextEditingController(text: item.price);

  return showDialog<ProcedureInvoiceItem>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Procedure Item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Procedure',
              prefixIcon: Icon(Icons.healing_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: teethController,
            decoration: const InputDecoration(
              labelText: 'Teeth',
              prefixIcon: Icon(Icons.image_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Price',
              prefixIcon: Icon(Icons.payments_outlined),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            final name = nameController.text.trim();
            final teeth = teethController.text.trim();
            final price = priceController.text.trim();
            if (name.isEmpty || teeth.isEmpty || price.isEmpty) {
              return;
            }
            Navigator.of(
              context,
            ).pop(ProcedureInvoiceItem(name, teeth, _formatCurrency(price)));
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save'),
        ),
      ],
    ),
  ).whenComplete(() {
    nameController.dispose();
    teethController.dispose();
    priceController.dispose();
  });
}

Future<PharmacyInvoiceItem?> showPharmacyInvoiceItemEditor(
  BuildContext context,
  PharmacyInvoiceItem item,
) {
  final nameController = TextEditingController(text: item.name);
  final quantityController = TextEditingController(text: '${item.quantity}');
  final priceController = TextEditingController(text: item.price);

  return showDialog<PharmacyInvoiceItem>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Edit Product'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Product',
              prefixIcon: Icon(Icons.local_pharmacy_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Quantity',
              prefixIcon: Icon(Icons.numbers_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Price',
              prefixIcon: Icon(Icons.payments_outlined),
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: () {
            final name = nameController.text.trim();
            final quantity = (int.tryParse(quantityController.text.trim()) ?? 1)
                .clamp(1, 999);
            final price = priceController.text.trim();
            if (name.isEmpty || price.isEmpty) {
              return;
            }
            Navigator.of(
              context,
            ).pop(PharmacyInvoiceItem(name, quantity, _formatCurrency(price)));
          },
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save'),
        ),
      ],
    ),
  ).whenComplete(() {
    nameController.dispose();
    quantityController.dispose();
    priceController.dispose();
  });
}

const paymentMethods = ['Both', 'Cash', 'Bank', 'WalletPay'];
const secondaryPaymentMethods = ['Bank', 'WalletPay'];
String cashierDefaultDoctorFee = 'First Visit - RM 80';
String cashierDefaultServiceCharge = 'Registration Service - RM 20';

String _formatCurrency(String amount) {
  return amount.toUpperCase().contains('RM') ? amount : 'RM $amount';
}

String medicinePrice(String medicineName) {
  final normalized = medicineName.toLowerCase();
  for (final productClass in nestedProductDatabase) {
    for (final feature in productClass.features) {
      for (final option in feature.options) {
        final optionName = option.name.toLowerCase();
        final nestedName =
            '${productClass.name} / ${feature.name} / ${option.name}'
                .toLowerCase();
        if (normalized == optionName || normalized == nestedName) {
          return option.price;
        }
      }
    }
  }

  if (normalized.contains('amoxicillin')) {
    return 'RM 120';
  }
  if (normalized.contains('ibuprofen')) {
    return 'RM 80';
  }
  if (normalized.contains('chlorhexidine')) {
    return 'RM 90';
  }
  if (normalized.contains('lidocaine')) {
    return 'RM 65';
  }
  if (normalized.contains('paracetamol')) {
    return 'RM 40';
  }
  if (normalized.contains('gauze')) {
    return 'RM 35';
  }
  return 'RM 0';
}

List<PriceNature> _defaultPriceNatures(String basePrice, String unit) {
  final singlePrice = _currencyValue(basePrice);
  final normalizedUnit = unit.isEmpty ? 'item' : unit;
  return [
    PriceNature(
      'Smallest',
      1,
      normalizedUnit,
      _formatCurrencyValue(singlePrice),
    ),
    PriceNature(
      'Card',
      10,
      normalizedUnit,
      _formatCurrencyValue(singlePrice * 10),
    ),
    PriceNature(
      'Bottle',
      100,
      normalizedUnit,
      _formatCurrencyValue(singlePrice * 100),
    ),
  ];
}

String _lastPathSegment(String value) {
  return value.split('/').map((part) => part.trim()).last;
}

class _PaymentMethodSelectField extends StatelessWidget {
  const _PaymentMethodSelectField({
    required this.controller,
    this.methods = paymentMethods,
    this.label = 'Payment method',
    this.icon = Icons.payments_outlined,
    this.onChanged,
  });

  final TextEditingController controller;
  final List<String> methods;
  final String label;
  final IconData icon;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedMethod = methods.contains(controller.text)
        ? controller.text
        : methods.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        initialValue: selectedMethod,
        items: [
          for (final method in methods)
            DropdownMenuItem(value: method, child: Text(method)),
        ],
        onChanged: (method) {
          if (method != null) {
            controller.text = method;
            onChanged?.call(method);
          }
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}

class FollowUpView extends StatelessWidget {
  const FollowUpView({super.key});

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Follow Up Board',
      action: '14 open',
      child: _ResponsiveGrid(
        compactAspectRatio: 0.95,
        minTileWidth: 290,
        wideAspectRatio: 1.05,
        children: [
          for (final followUp in sampleFollowUps)
            _FollowUpCard(followUp: followUp),
        ],
      ),
    );
  }
}

class PharmacyView extends StatefulWidget {
  const PharmacyView({super.key});

  @override
  State<PharmacyView> createState() => _PharmacyViewState();
}

class _PharmacyViewState extends State<PharmacyView> {
  Medicine? selectedMedicine;
  var medicines = [...sampleMedicines];

  Future<void> openAddMedicinePage() async {
    final medicine = await showDialog<Medicine>(
      context: context,
      builder: (context) => const _AddMedicineDialog(),
    );

    if (medicine == null || !mounted) {
      return;
    }

    setState(() {
      medicines = [medicine, ...medicines];
      selectedMedicine = medicine;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${medicine.name} added')));
  }

  @override
  Widget build(BuildContext context) {
    final medicine = selectedMedicine;
    if (medicine != null) {
      return _MedicineDetailView(
        medicine: medicine,
        onBack: () => setState(() => selectedMedicine = null),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResponsiveGrid(
          compactMinTileWidth: 170,
          compactAspectRatio: 1.12,
          minTileWidth: 220,
          wideAspectRatio: 1.35,
          children: const [
            _MetricCard(
              'Medicines',
              '42',
              'In stock',
              Icons.medication_outlined,
              Color(0xFF0B7285),
            ),
            _MetricCard(
              'Low Stock',
              '6',
              'Reorder',
              Icons.inventory_2_outlined,
              Color(0xFFC2410C),
            ),
            _MetricCard(
              'Dispensed Today',
              '18',
              '+5',
              Icons.local_pharmacy_outlined,
              Color(0xFF166534),
            ),
            _MetricCard(
              'Pending Pickup',
              '4',
              'Ready',
              Icons.shopping_bag_outlined,
              Color(0xFF7C3AED),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _TwoColumn(
          left: _Panel(
            title: 'Dispensing Queue',
            action: '4 pending',
            child: Column(
              children: [
                for (final dispense in samplePharmacyDispenses)
                  _PharmacyDispenseTile(dispense: dispense),
              ],
            ),
          ),
          right: _Panel(
            title: 'Products Tools',
            action: 'Inventory',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ActionButton(
                  icon: Icons.add_box_outlined,
                  label: 'Add product',
                  onPressed: openAddMedicinePage,
                ),
                const _ActionButton(
                  icon: Icons.assignment_return_outlined,
                  label: 'Create reorder',
                ),
                const _ActionButton(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan batch',
                ),
                const _ActionButton(
                  icon: Icons.receipt_long,
                  label: 'Dispense history',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _TwoColumn(
          left: _Panel(
            title: 'Products Cashier',
            action: 'RM 1,260 today',
            child: Column(
              children: [
                const _DetailSummaryRow(
                  items: [
                    DetailSummary('Paid', 'RM 840', Color(0xFF166534)),
                    DetailSummary('Due', 'RM 420', Color(0xFFC2410C)),
                    DetailSummary('Orders', '12', Color(0xFF0B7285)),
                  ],
                ),
                const SizedBox(height: 14),
                for (final payment in samplePharmacyPayments)
                  _PharmacyPaymentTile(payment: payment),
              ],
            ),
          ),
          right: _Panel(
            title: 'Products Checkout',
            action: 'Cashier',
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ActionButton(
                  icon: Icons.receipt_long,
                  label: 'Create medicine invoice',
                ),
                _ActionButton(
                  icon: Icons.payments_outlined,
                  label: 'Record medicine payment',
                ),
                _ActionButton(
                  icon: Icons.print_outlined,
                  label: 'Print medicine receipt',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Products Inventory',
          action: '${medicines.length} tracked',
          child: _ResponsiveGrid(
            compactAspectRatio: 0.78,
            minTileWidth: 260,
            wideAspectRatio: 0.84,
            children: [
              for (final medicine in medicines)
                _MedicineCard(
                  medicine: medicine,
                  onTap: () => setState(() => selectedMedicine = medicine),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MedicineDetailView extends StatelessWidget {
  const _MedicineDetailView({required this.medicine, required this.onBack});

  final Medicine medicine;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final stockRatio = (medicine.stock / medicine.capacity).clamp(0.0, 1.0);
    final reorderPoint = (medicine.capacity * 0.3).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          label: const Text('Back to pharmacy'),
        ),
        const SizedBox(height: 8),
        _TwoColumn(
          left: _Panel(
            title: 'Drug Detail',
            action: medicine.status,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: medicine.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.medication,
                        color: medicine.color,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicine.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            medicine.productPath.isEmpty
                                ? medicine.category
                                : medicine.productPath,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailSummaryRow(
                  items: [
                    DetailSummary('Stock', '${medicine.stock}', medicine.color),
                    DetailSummary(
                      'Capacity',
                      '${medicine.capacity}',
                      const Color(0xFF0B7285),
                    ),
                    DetailSummary(
                      'Reorder',
                      '$reorderPoint',
                      const Color(0xFFC2410C),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                LinearProgressIndicator(
                  value: stockRatio,
                  color: medicine.color,
                  backgroundColor: medicine.color.withValues(alpha: 0.12),
                ),
                const SizedBox(height: 16),
                Text(
                  'Description',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  medicine.description.isEmpty
                      ? 'No description added.'
                      : medicine.description,
                  style: const TextStyle(
                    color: Color(0xFF475467),
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Drug Images',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                _MedicineImageGallery(imageUrls: medicine.imageUrls),
              ],
            ),
          ),
          right: _Panel(
            title: 'Batch & Expiry',
            action: medicine.batch,
            child: Column(
              children: [
                _ProfileLine(
                  icon: Icons.qr_code_2_outlined,
                  label: 'Batch number',
                  value: medicine.batch,
                ),
                _ProfileLine(
                  icon: Icons.event_outlined,
                  label: 'Expiry date',
                  value: medicine.expiry,
                ),
                _ProfileLine(
                  icon: Icons.inventory_2_outlined,
                  label: 'Unit',
                  value: medicine.unit,
                ),
                if (medicine.productPath.isNotEmpty)
                  _ProfileLine(
                    icon: Icons.account_tree_outlined,
                    label: 'Product path',
                    value: medicine.productPath,
                  ),
                if (medicine.category.isNotEmpty)
                  _ProfileLine(
                    icon: Icons.category_outlined,
                    label: 'Category',
                    value: medicine.category,
                  ),
                if (medicine.chemicalName.isNotEmpty)
                  _ProfileLine(
                    icon: Icons.science_outlined,
                    label: 'Chemical name',
                    value: medicine.chemicalName,
                  ),
                if (medicine.tag.isNotEmpty)
                  _ProfileLine(
                    icon: Icons.sell_outlined,
                    label: 'Tag',
                    value: medicine.tag,
                  ),
                if (medicine.hasPrice)
                  _ProfileLine(
                    icon: Icons.payments_outlined,
                    label: 'Price',
                    value: medicine.netPrice,
                  ),
                if (medicine.priceNature != null)
                  _ProfileLine(
                    icon: Icons.inventory_outlined,
                    label: 'Price nature',
                    value:
                        '${medicine.priceNature!.label} - ${medicine.priceNature!.price}',
                  ),
                if (medicine.hasDiscount)
                  _ProfileLine(
                    icon: Icons.discount_outlined,
                    label: 'Discount',
                    value: '${medicine.discountLabel} from ${medicine.price}',
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Drug Actions',
          action: 'Products',
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ActionButton(
                icon: Icons.add_shopping_cart_outlined,
                label: 'Add stock',
              ),
              _ActionButton(
                icon: Icons.assignment_return_outlined,
                label: 'Create reorder',
              ),
              _ActionButton(
                icon: Icons.local_pharmacy_outlined,
                label: 'Dispense drug',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AddMedicineDialog extends StatefulWidget {
  const _AddMedicineDialog();

  @override
  State<_AddMedicineDialog> createState() => _AddMedicineDialogState();
}

class _AddMedicineDialogState extends State<_AddMedicineDialog> {
  final nameController = TextEditingController();
  final subclassController = TextEditingController();
  final childClassController = TextEditingController();
  final categoryController = TextEditingController();
  final chemicalNameController = TextEditingController();
  final tagController = TextEditingController();
  final descriptionController = TextEditingController();
  final imageUrlsController = TextEditingController();
  final stockController = TextEditingController();
  final capacityController = TextEditingController();
  final unitController = TextEditingController();
  final batchController = TextEditingController();
  final expiryController = TextEditingController();
  final statusController = TextEditingController(text: 'In stock');
  final discountController = TextEditingController();
  var discountMode = ProcedureDiscountMode.none;
  final priceNatureControllers = [
    _PriceNatureControllers('Smallest', '1', 'tablet', '1'),
    _PriceNatureControllers('Card', '10', 'tablets', '10'),
    _PriceNatureControllers('Bottle', '100', 'tablets', '100'),
  ];
  var updatingCalculatedPrices = false;

  @override
  void initState() {
    super.initState();
    final nature = _buildPriceNature(0);
    unitController.text = nature.unit;
    priceNatureControllers.first.price.addListener(
      _updateCalculatedPriceNatures,
    );
    for (final controllerSet in priceNatureControllers) {
      controllerSet.quantity.addListener(_updateCalculatedPriceNatures);
    }
    _updateCalculatedPriceNatures();
  }

  @override
  void dispose() {
    nameController.dispose();
    subclassController.dispose();
    childClassController.dispose();
    categoryController.dispose();
    chemicalNameController.dispose();
    tagController.dispose();
    descriptionController.dispose();
    imageUrlsController.dispose();
    stockController.dispose();
    capacityController.dispose();
    unitController.dispose();
    batchController.dispose();
    expiryController.dispose();
    statusController.dispose();
    discountController.dispose();
    priceNatureControllers.first.price.removeListener(
      _updateCalculatedPriceNatures,
    );
    for (final controllerSet in priceNatureControllers) {
      controllerSet.quantity.removeListener(_updateCalculatedPriceNatures);
      controllerSet.dispose();
    }
    super.dispose();
  }

  void submit() {
    final productName = nameController.text.trim();
    final subclass = subclassController.text.trim();
    final childClass = childClassController.text.trim();
    final category = categoryController.text.trim();
    final chemicalName = chemicalNameController.text.trim();
    final tag = tagController.text.trim();
    final description = descriptionController.text.trim();
    final imageUrls = _medicineImageUrls(imageUrlsController.text);
    final displayName = [
      productName,
      if (subclass.isNotEmpty) subclass,
      if (childClass.isNotEmpty) childClass,
    ].join(' ');
    final stock = int.tryParse(stockController.text.trim());
    final capacity = int.tryParse(capacityController.text.trim());
    final unit = unitController.text.trim();
    final batch = batchController.text.trim();
    final expiry = expiryController.text.trim();
    final status = statusController.text.trim();
    final discount = discountController.text.trim();
    final priceNatures = _priceNatures();

    if ([
          productName,
          unit,
          batch,
          expiry,
          status,
        ].any((value) => value.isEmpty) ||
        priceNatures.isEmpty ||
        stock == null ||
        capacity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all medicine fields')),
      );
      return;
    }

    if (discountMode != ProcedureDiscountMode.none && discount.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Complete discount value')));
      return;
    }

    final priceNature = priceNatures.first;

    Navigator.of(context).pop(
      Medicine(
        displayName,
        category.isEmpty ? productName : category,
        stock,
        capacity,
        unit,
        batch,
        expiry,
        status,
        status.toLowerCase().contains('low')
            ? const Color(0xFFC2410C)
            : const Color(0xFF166534),
        price: priceNature.price,
        productClass: productName,
        productFeature: subclass,
        productOption: childClass,
        chemicalName: chemicalName,
        tag: tag,
        priceNature: priceNature,
        priceNatures: priceNatures,
        discountMode: discountMode,
        discountValue: discount,
        description: description,
        imageUrls: imageUrls,
      ),
    );
  }

  PriceNature _buildPriceNature(int index) {
    final controllers = priceNatureControllers[index];
    final rawPrice = controllers.price.text.trim();
    return PriceNature(
      controllers.name.text.trim(),
      int.tryParse(controllers.quantity.text.trim()) ?? 1,
      controllers.unit.text.trim(),
      rawPrice.startsWith('RM')
          ? rawPrice
          : _formatCurrencyValue(_currencyValue(rawPrice)),
    );
  }

  List<PriceNature> _priceNatures() {
    return [
      for (var index = 0; index < priceNatureControllers.length; index++)
        if (_buildPriceNature(index).name.isNotEmpty &&
            _buildPriceNature(index).unit.isNotEmpty &&
            _currencyValue(_buildPriceNature(index).price) > 0)
          _buildPriceNature(index),
    ];
  }

  void addPriceNature() {
    setState(() {
      final controllerSet = _PriceNatureControllers('', '1', '', '');
      controllerSet.quantity.addListener(_updateCalculatedPriceNatures);
      priceNatureControllers.add(controllerSet);
      _updateCalculatedPriceNatures();
    });
  }

  void removePriceNature(int index) {
    if (index == 0 || index >= priceNatureControllers.length) {
      return;
    }

    setState(() {
      final controllerSet = priceNatureControllers.removeAt(index);
      controllerSet.quantity.removeListener(_updateCalculatedPriceNatures);
      controllerSet.dispose();
      _updateCalculatedPriceNatures();
    });
  }

  void _updateCalculatedPriceNatures() {
    if (updatingCalculatedPrices || priceNatureControllers.isEmpty) {
      return;
    }

    final smallestPrice = _currencyValue(
      priceNatureControllers.first.price.text,
    );
    final smallestValue =
        int.tryParse(priceNatureControllers.first.quantity.text.trim()) ?? 1;
    final unitPrice = smallestValue <= 0 ? 0 : smallestPrice / smallestValue;
    updatingCalculatedPrices = true;
    for (var index = 1; index < priceNatureControllers.length; index++) {
      final controllers = priceNatureControllers[index];
      final value = int.tryParse(controllers.quantity.text.trim()) ?? 0;
      final calculatedPrice = unitPrice <= 0 || value <= 0
          ? ''
          : _formatCurrencyValue(unitPrice * value);
      if (controllers.price.text != calculatedPrice) {
        controllers.price.text = calculatedPrice;
      }
    }
    updatingCalculatedPrices = false;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.86;

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 620, maxHeight: height),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Add Product',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _ProjectInput(
                        icon: Icons.medication_outlined,
                        label: 'Product name',
                        hintText: 'e.g. Blumox',
                        controller: nameController,
                      ),
                      _ProjectInput(
                        icon: Icons.schema_outlined,
                        label: 'Subclass',
                        hintText: 'e.g. 250 or 500',
                        controller: subclassController,
                      ),
                      _ProjectInput(
                        icon: Icons.subdirectory_arrow_right,
                        label: 'Child class',
                        hintText: 'e.g. Capsule or Syrup',
                        controller: childClassController,
                      ),
                      _ProjectInput(
                        icon: Icons.category_outlined,
                        label: 'Category (optional)',
                        hintText: 'e.g. Antibiotic',
                        controller: categoryController,
                      ),
                      _ProjectInput(
                        icon: Icons.science_outlined,
                        label: 'Chemical Name (optional)',
                        hintText: 'e.g. Amoxicillin trihydrate',
                        controller: chemicalNameController,
                      ),
                      _ProjectInput(
                        icon: Icons.sell_outlined,
                        label: 'Tag (optional)',
                        hintText: 'e.g. Prescription',
                        controller: tagController,
                      ),
                      _ProjectInput(
                        icon: Icons.notes_outlined,
                        label: 'Description (optional)',
                        hintText: 'Dosage notes, indications, storage guidance',
                        controller: descriptionController,
                        keyboardType: TextInputType.multiline,
                        maxLines: 3,
                      ),
                      _ProjectInput(
                        icon: Icons.image_outlined,
                        label: 'Image URLs (optional)',
                        hintText: 'Paste multiple URLs, one per line',
                        controller: imageUrlsController,
                        keyboardType: TextInputType.multiline,
                        maxLines: 3,
                      ),
                      _PriceNatureEditor(
                        controllers: priceNatureControllers,
                        onAdd: addPriceNature,
                        onRemove: removePriceNature,
                      ),
                      _ProcedureDiscountFields(
                        discountMode: discountMode,
                        discountController: discountController,
                        onModeChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            discountMode = value;
                            if (discountMode == ProcedureDiscountMode.none) {
                              discountController.clear();
                            }
                          });
                        },
                      ),
                      _TwoFieldRow(
                        first: _ProjectInput(
                          icon: Icons.inventory_2_outlined,
                          label: 'Stock',
                          hintText: '80',
                          controller: stockController,
                          keyboardType: TextInputType.number,
                        ),
                        second: _ProjectInput(
                          icon: Icons.warehouse_outlined,
                          label: 'Capacity',
                          hintText: '120',
                          controller: capacityController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      _ProjectInput(
                        icon: Icons.straighten_outlined,
                        label: 'Unit',
                        hintText: 'tablets, bottles, packs',
                        controller: unitController,
                      ),
                      _TwoFieldRow(
                        first: _ProjectInput(
                          icon: Icons.qr_code_2_outlined,
                          label: 'Batch',
                          hintText: 'AMX-24A',
                          controller: batchController,
                        ),
                        second: _ProjectInput(
                          icon: Icons.event_outlined,
                          label: 'Expiry',
                          hintText: 'Jan 2028',
                          controller: expiryController,
                        ),
                      ),
                      _ProjectInput(
                        icon: Icons.verified_outlined,
                        label: 'Status',
                        hintText: 'In stock',
                        controller: statusController,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: submit,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Product'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<String> _medicineImageUrls(String value) {
  return value
      .split(RegExp(r'[\n,]+'))
      .map((url) => url.trim())
      .where((url) => url.isNotEmpty)
      .toList(growable: false);
}

class _MedicineImageGallery extends StatelessWidget {
  const _MedicineImageGallery({required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return Container(
        height: 112,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDCE3EA)),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image_outlined, color: Color(0xFF667085)),
              SizedBox(width: 8),
              Text(
                'No images added.',
                style: TextStyle(
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth < 420
            ? constraints.maxWidth
            : (constraints.maxWidth - 10) / 2;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final imageUrl in imageUrls)
              SizedBox(
                width: itemWidth,
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: const Color(0xFFF1F5F9),
                        child: const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TwoFieldRow extends StatelessWidget {
  const _TwoFieldRow({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < 560) {
      return Column(children: [first, second]);
    }

    return Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: 10),
        Expanded(child: second),
      ],
    );
  }
}

class _PriceNatureEditor extends StatelessWidget {
  const _PriceNatureEditor({
    required this.controllers,
    required this.onAdd,
    required this.onRemove,
  });

  final List<_PriceNatureControllers> controllers;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Price nature',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < controllers.length; index++)
            _PriceNatureRow(
              index: index,
              controllers: controllers[index],
              onRemove: index == 0 ? null : () => onRemove(index),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add price nature'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PriceNatureRow extends StatelessWidget {
  const _PriceNatureRow({
    required this.index,
    required this.controllers,
    this.onRemove,
  });

  final int index;
  final _PriceNatureControllers controllers;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;
    final nameField = _CompactTextField(
      controller: controllers.name,
      label: 'Name',
      hintText: index == 0 ? 'Smallest' : 'Bottle',
    );
    final valueField = _CompactTextField(
      controller: controllers.quantity,
      label: 'Value',
      hintText: '1',
      keyboardType: TextInputType.number,
    );
    final unitField = _CompactTextField(
      controller: controllers.unit,
      label: 'Unit',
      hintText: 'tablet',
    );
    final priceField = _CompactTextField(
      controller: controllers.price,
      label: 'Price',
      hintText: index == 0 ? '10' : 'Auto',
      keyboardType: TextInputType.number,
      readOnly: index > 0,
    );
    final removeButton = onRemove == null
        ? const SizedBox.shrink()
        : Tooltip(
            message: 'Delete price nature',
            child: IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline),
            ),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(width: 140, child: nameField),
                    SizedBox(width: 100, child: valueField),
                    SizedBox(width: 140, child: unitField),
                    SizedBox(width: 100, child: priceField),
                    SizedBox(width: 42, child: removeButton),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Expanded(flex: 3, child: nameField),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: valueField),
                const SizedBox(width: 8),
                Expanded(flex: 3, child: unitField),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: priceField),
                const SizedBox(width: 8),
                SizedBox(width: 42, child: removeButton),
              ],
            ),
    );
  }
}

class _CompactTextField extends StatelessWidget {
  const _CompactTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.keyboardType,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputType? keyboardType;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDCE3EA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFDCE3EA)),
        ),
      ),
    );
  }
}

class _PriceNatureControllers {
  _PriceNatureControllers(
    String name,
    String quantity,
    String unit,
    String price,
  ) : name = TextEditingController(text: name),
      quantity = TextEditingController(text: quantity),
      unit = TextEditingController(text: unit),
      price = TextEditingController(text: price);

  final TextEditingController name;
  final TextEditingController quantity;
  final TextEditingController unit;
  final TextEditingController price;

  void dispose() {
    name.dispose();
    quantity.dispose();
    unit.dispose();
    price.dispose();
  }
}

class ProcedureView extends StatelessWidget {
  const ProcedureView({
    super.key,
    required this.users,
    required this.procedures,
    required this.onProcedureUpdated,
    required this.onProcedureDeleted,
  });

  final List<ClinicUser> users;
  final List<DentalProcedure> procedures;
  final void Function(int index, DentalProcedure procedure) onProcedureUpdated;
  final ValueChanged<int> onProcedureDeleted;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      title: 'Procedure Pipeline',
      action: 'Owner/Admin CRUD',
      child: _ResponsiveGrid(
        compactAspectRatio: 0.68,
        minTileWidth: 280,
        wideAspectRatio: 0.72,
        children: [
          for (var index = 0; index < procedures.length; index++)
            _ProcedureCard(
              procedure: procedures[index],
              onEdit: () async {
                final procedure = await showDialog<DentalProcedure>(
                  context: context,
                  builder: (context) =>
                      _NewProcedureDialog(procedure: procedures[index]),
                );

                if (procedure == null || !context.mounted) {
                  return;
                }

                onProcedureUpdated(index, procedure);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${procedure.name} updated')),
                );
              },
              onDelete: () {
                final deletedName = procedures[index].name;
                onProcedureDeleted(index);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('$deletedName deleted')));
              },
            ),
        ],
      ),
    );
  }
}

class _NewProcedureDialog extends StatefulWidget {
  const _NewProcedureDialog({this.procedure});

  final DentalProcedure? procedure;

  @override
  State<_NewProcedureDialog> createState() => _NewProcedureDialogState();
}

class _NewProcedureDialogState extends State<_NewProcedureDialog> {
  final priceController = TextEditingController();
  final discountController = TextEditingController();
  final estimateController = TextEditingController();
  final firstStepController = TextEditingController();
  final secondStepController = TextEditingController();
  final thirdStepController = TextEditingController();
  final categoryController = TextEditingController();
  final tagController = TextEditingController();
  var discountMode = ProcedureDiscountMode.none;

  @override
  void initState() {
    super.initState();

    final procedure = widget.procedure;
    if (procedure == null) {
      return;
    }

    priceController.text = procedure.price.replaceFirst('RM ', '');
    discountController.text = procedure.discountValue;
    discountMode = procedure.discountMode;
    estimateController.text = procedure.estimate;
    firstStepController.text = procedure.category;
    secondStepController.text = procedure.subcategory;
    thirdStepController.text = procedure.childCategory.isEmpty
        ? procedure.name
        : procedure.childCategory;
    categoryController.text = procedure.procedureCategory;
    tagController.text = procedure.tag;
  }

  @override
  void dispose() {
    priceController.dispose();
    discountController.dispose();
    estimateController.dispose();
    firstStepController.dispose();
    secondStepController.dispose();
    thirdStepController.dispose();
    categoryController.dispose();
    tagController.dispose();
    super.dispose();
  }

  void submit() {
    final price = priceController.text.trim();
    final discount = discountController.text.trim();
    final estimate = estimateController.text.trim();
    final firstStep = firstStepController.text.trim();
    final secondStep = secondStepController.text.trim();
    final thirdStep = thirdStepController.text.trim();
    final procedureCategory = categoryController.text.trim();
    final tag = tagController.text.trim();
    final procedureName = [
      thirdStep,
      secondStep,
      firstStep,
    ].firstWhere((value) => value.isNotEmpty, orElse: () => 'New procedure');
    final category = firstStep;
    final subcategory = secondStep;
    final childCategory = thirdStep;

    if ([price, estimate].any((value) => value.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complete all procedure fields')),
      );
      return;
    }

    if (discountMode != ProcedureDiscountMode.none && discount.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Complete discount value')));
      return;
    }

    Navigator.of(context).pop(
      DentalProcedure(
        procedureName,
        '',
        '',
        widget.procedure?.progress ?? 0,
        Icons.healing,
        widget.procedure?.color ?? const Color(0xFF0B7285),
        price.startsWith('RM') ? price : 'RM $price',
        estimate,
        category,
        subcategory,
        childCategory,
        discountMode: discountMode,
        discountValue: discount,
        procedureCategory: procedureCategory,
        tag: tag,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.78;
    final editing = widget.procedure != null;

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 540, maxHeight: height),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                editing ? 'Edit Procedure' : 'Create Procedure',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _ProjectInput(
                        icon: Icons.account_tree_outlined,
                        label: 'First step',
                        hintText: 'e.g. Therapeutic',
                        controller: firstStepController,
                      ),
                      _ProjectInput(
                        icon: Icons.schema_outlined,
                        label: 'Second step',
                        hintText: 'e.g. Endodontics',
                        controller: secondStepController,
                      ),
                      _ProjectInput(
                        icon: Icons.subdirectory_arrow_right,
                        label: 'Third step',
                        hintText: 'e.g. Root canal',
                        controller: thirdStepController,
                      ),
                      _ProjectInput(
                        icon: Icons.category_outlined,
                        label: 'Category (optional)',
                        hintText: 'e.g. Surgery, Hygiene, Restorative',
                        controller: categoryController,
                      ),
                      _ProjectInput(
                        icon: Icons.sell_outlined,
                        label: 'Tag (optional)',
                        hintText: 'e.g. Surgery, Pediatric, High priority',
                        controller: tagController,
                      ),
                      _ProjectInput(
                        icon: Icons.payments_outlined,
                        label: 'Price',
                        hintText: '950',
                        controller: priceController,
                        keyboardType: TextInputType.number,
                      ),
                      _ProcedureDiscountFields(
                        discountMode: discountMode,
                        discountController: discountController,
                        onModeChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() {
                            discountMode = value;
                            if (discountMode == ProcedureDiscountMode.none) {
                              discountController.clear();
                            }
                          });
                        },
                      ),
                      _ProjectInput(
                        icon: Icons.schedule_outlined,
                        label: 'Estimated time',
                        hintText: '50 min',
                        controller: estimateController,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: submit,
                    icon: Icon(editing ? Icons.save_outlined : Icons.add),
                    label: Text(
                      editing ? 'Update Procedure' : 'Create Procedure',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ApplyProcedureProjectDialog extends StatefulWidget {
  const _ApplyProcedureProjectDialog({
    required this.users,
    required this.procedure,
  });

  final List<ClinicUser> users;
  final DentalProcedure procedure;

  @override
  State<_ApplyProcedureProjectDialog> createState() =>
      _ApplyProcedureProjectDialogState();
}

class _ProcedureDiscountFields extends StatelessWidget {
  const _ProcedureDiscountFields({
    required this.discountMode,
    required this.discountController,
    required this.onModeChanged,
  });

  final ProcedureDiscountMode discountMode;
  final TextEditingController discountController;
  final ValueChanged<ProcedureDiscountMode?> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 560;
    final valueField = _ProjectInput(
      icon: discountMode == ProcedureDiscountMode.percent
          ? Icons.percent
          : Icons.price_change_outlined,
      label: discountMode == ProcedureDiscountMode.percent
          ? 'Discount %'
          : 'Net Price',
      hintText: discountMode == ProcedureDiscountMode.percent ? '10' : '850',
      controller: discountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );

    final modeField = Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<ProcedureDiscountMode>(
        initialValue: discountMode,
        decoration: _inputDecoration(
          icon: Icons.discount_outlined,
          label: 'Discount type',
          hintText: 'Choose discount type',
        ),
        items: [
          for (final mode in ProcedureDiscountMode.values)
            DropdownMenuItem(value: mode, child: Text(mode.label)),
        ],
        onChanged: onModeChanged,
      ),
    );

    if (discountMode == ProcedureDiscountMode.none) {
      return modeField;
    }

    if (compact) {
      return Column(children: [modeField, valueField]);
    }

    return Row(
      children: [
        Expanded(child: modeField),
        const SizedBox(width: 10),
        Expanded(child: valueField),
      ],
    );
  }
}

class _ApplyProcedureProjectDialogState
    extends State<_ApplyProcedureProjectDialog> {
  late final TextEditingController summaryController;
  var priority = 'Medium';
  String? selectedPatient;
  String? selectedDoctor;
  var selectedDentition = DentitionType.adult;
  var selectedTooth = 'Tooth 11';

  List<ClinicUser> get patients {
    return widget.users
        .where((user) => user.role == RoleFilter.user.label)
        .toList();
  }

  String? get _firstPatientName =>
      patients.isEmpty ? null : patients.first.name;

  String? get _firstDoctorName =>
      sampleDoctors.isEmpty ? null : sampleDoctors.first.name;

  String? get selectedPatientDetail {
    for (final patient in patients) {
      if (patient.name == selectedPatient) {
        return '${patient.phone} - ${patient.status}';
      }
    }
    return null;
  }

  String? get selectedDoctorDetail {
    for (final doctor in sampleDoctors) {
      if (doctor.name == selectedDoctor) {
        return '${doctor.specialty} - ${doctor.status}';
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    selectedPatient = _firstPatientName;
    selectedDoctor =
        sampleDoctors.any((doctor) => doctor.name == widget.procedure.doctor)
        ? widget.procedure.doctor
        : _firstDoctorName;
    summaryController = TextEditingController(
      text:
          '${widget.procedure.name} - ${widget.procedure.estimate} - ${widget.procedure.netPrice}',
    );
  }

  @override
  void dispose() {
    summaryController.dispose();
    super.dispose();
  }

  void submit() {
    if (selectedPatient == null || selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient name and doctor are required')),
      );
      return;
    }

    Navigator.of(context).pop(
      ClinicProject(
        generatedProjectId(),
        selectedPatient!,
        selectedDoctor!,
        'Next visit',
        widget.procedure.name,
        selectedDentition.label,
        selectedTooth,
        '',
        '',
        '',
        '',
        '',
        0,
        widget.procedure.color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.86;

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: height),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Apply Procedure to Project',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _ProjectEntitySelector(
                        icon: Icons.person_outline,
                        title: 'Patient Name',
                        source: 'From Patient Page',
                        selectedValue: selectedPatient,
                        selectedDetail:
                            selectedPatientDetail ?? 'Select patient',
                        options: [
                          for (final patient in patients)
                            _ProjectSelectionOption(
                              value: patient.name,
                              label: patient.name,
                              detail: patient.phone,
                            ),
                        ],
                        onSelected: (value) =>
                            setState(() => selectedPatient = value),
                      ),
                      const SizedBox(height: 10),
                      _ProjectEntitySelector(
                        icon: Icons.medical_services_outlined,
                        title: 'Doctor',
                        source: 'From Doctor Page',
                        selectedValue: selectedDoctor,
                        selectedDetail: selectedDoctorDetail ?? 'Select doctor',
                        options: [
                          for (final doctor in sampleDoctors)
                            _ProjectSelectionOption(
                              value: doctor.name,
                              label: doctor.name,
                              detail: doctor.specialty,
                            ),
                        ],
                        onSelected: (value) =>
                            setState(() => selectedDoctor = value),
                      ),
                      _ProfileLine(
                        icon: Icons.healing_outlined,
                        label: 'Procedure',
                        value: widget.procedure.name,
                      ),
                      const SizedBox(height: 10),
                      _ToothSelector(
                        dentition: selectedDentition,
                        selectedTooth: selectedTooth,
                        onDentitionChanged: (dentition) => setState(() {
                          selectedDentition = dentition;
                          selectedTooth = dentition.teeth.first;
                        }),
                        onToothChanged: (tooth) =>
                            setState(() => selectedTooth = tooth),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: priority,
                        decoration: _inputDecoration(
                          icon: Icons.flag_outlined,
                          label: 'Priority',
                          hintText: 'Medium',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Low', child: Text('Low')),
                          DropdownMenuItem(
                            value: 'Medium',
                            child: Text('Medium'),
                          ),
                          DropdownMenuItem(value: 'High', child: Text('High')),
                        ],
                        onChanged: (value) =>
                            setState(() => priority = value ?? priority),
                      ),
                      const SizedBox(height: 10),
                      _ProjectInput(
                        controller: summaryController,
                        icon: Icons.notes_outlined,
                        label: 'Summary',
                        hintText: 'Procedure plan, tooth, and next step',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: submit,
                    icon: const Icon(Icons.work_outline),
                    label: const Text('Apply Procedure'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProjectsView extends StatefulWidget {
  const ProjectsView({super.key, required this.projectInvoices});

  final List<Invoice> projectInvoices;

  @override
  State<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<ProjectsView> {
  Invoice? selectedInvoice;

  List<Invoice> get projectInvoices => widget.projectInvoices;

  @override
  Widget build(BuildContext context) {
    final invoice = selectedInvoice;
    if (invoice != null) {
      return _CashInvoiceDetail(
        invoice: invoice,
        backLabel: 'Back to project history',
        onBack: () => setState(() => selectedInvoice = null),
      );
    }

    return Column(
      children: [
        _ResponsiveGrid(
          compactMinTileWidth: 170,
          compactAspectRatio: 1.22,
          minTileWidth: 220,
          wideAspectRatio: 1.45,
          children: [
            _MetricCard(
              'Project History',
              '${projectInvoices.length}',
              'From cashier',
              Icons.work,
              const Color(0xFF0B7285),
            ),
            _MetricCard(
              'Invoice Source',
              '${projectInvoices.length}',
              'Invoices',
              Icons.receipt_long,
              const Color(0xFFC2410C),
            ),
            _MetricCard(
              'Total Amount',
              _formatCurrencyValue(
                projectInvoices.fold<double>(
                  0,
                  (sum, invoice) => sum + _currencyValue(invoice.amount),
                ),
              ),
              'Saved',
              Icons.payments_outlined,
              const Color(0xFF166534),
            ),
            _MetricCard(
              'Follow Up',
              '${projectInvoices.where((invoice) => invoice.clinicalNote.isNotEmpty).length}',
              'With note',
              Icons.event_repeat_outlined,
              const Color(0xFF7C3AED),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Panel(
          title: 'Project History',
          action: '${projectInvoices.length} saved',
          child: Column(
            children: projectInvoices.isEmpty
                ? const [
                    _EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No cashier projects yet',
                      message:
                          'Create an invoice in Cashier to add project history here.',
                    ),
                  ]
                : [
                    for (final invoice in projectInvoices)
                      _ProjectInvoiceTile(
                        invoice: invoice,
                        onViewDetails: () =>
                            setState(() => selectedInvoice = invoice),
                      ),
                  ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            children: [
              Icon(icon, size: 40, color: const Color(0xFF64748B)),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<_NavigationItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 236,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE1E7EC))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'DentalOps',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++)
            _SideNavButton(
              item: items[i],
              selected: selectedIndex == i,
              onTap: () => onSelected(i),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('New visit'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideNavButton extends StatelessWidget {
  const _SideNavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavigationItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selected ? const Color(0xFFE6F6F8) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  selected ? item.selectedIcon : item.icon,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : const Color(0xFF52606D),
                ),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : const Color(0xFF344054),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
    this.label,
    this.value,
    this.delta,
    this.icon,
    this.color, {
    this.onTap,
  });

  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const Spacer(),
                  Text(
                    delta,
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              if (onTap != null)
                Text(
                  'View details',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.action,
    required this.child,
  });

  final String title;
  final String action;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(action, style: Theme.of(context).textTheme.labelLarge),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _TwoColumn extends StatelessWidget {
  const _TwoColumn({required this.left, required this.right});

  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 840) {
          return Column(children: [left, const SizedBox(height: 16), right]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: left),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: right),
          ],
        );
      },
    );
  }
}

class _ClinicStatusCard extends StatelessWidget {
  const _ClinicStatusCard({
    required this.title,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(color: color, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF667085)),
          ),
        ],
      ),
    );
  }
}

class _QueueFlow extends StatelessWidget {
  const _QueueFlow({required this.items});

  final List<QueueStatus> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;

        if (compact) {
          return Column(
            children: [
              for (final item in items) _QueueStatusTile(status: item),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < items.length; index++) ...[
              Expanded(child: _QueueStatusTile(status: items[index])),
              if (index < items.length - 1)
                const Padding(
                  padding: EdgeInsets.only(top: 20),
                  child: Icon(
                    Icons.chevron_right,
                    color: Color(0xFF98A2B3),
                    size: 22,
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _QueueStatusTile extends StatelessWidget {
  const _QueueStatusTile({required this.status});

  final QueueStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E7EC)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(status.icon, color: status.color, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.stage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  'Now ${status.currentBooking} - ${status.currentPatient}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Next ${status.nextBooking} - ETA ${status.estimatedTime}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF344054),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                status.currentBooking,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: status.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                status.estimatedTime,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF667085),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    required this.children,
    this.compactMinTileWidth,
    this.minTileWidth = 240,
    this.compactAspectRatio = 1.45,
    this.wideAspectRatio = 1.35,
  });

  final List<Widget> children;
  final double? compactMinTileWidth;
  final double minTileWidth;
  final double compactAspectRatio;
  final double wideAspectRatio;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = constraints.maxWidth < 520
            ? compactMinTileWidth ?? minTileWidth
            : minTileWidth;
        final count = (constraints.maxWidth / tileWidth).floor().clamp(1, 4);
        return GridView.count(
          crossAxisCount: count,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: constraints.maxWidth < 520
              ? compactAspectRatio
              : wideAspectRatio,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.appointment, this.onTap});

  final Appointment appointment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: _ContactDetailBlock(
          leading: Icons.chair_alt,
          title: appointment.patient,
          phone: appointment.phone,
          details: '${appointment.time} - ${appointment.procedure}',
          doctor: appointment.doctor,
          color: appointment.color,
        ),
      ),
    );
  }
}

class _BookingPatientTile extends StatelessWidget {
  const _BookingPatientTile({required this.appointment, this.onTap});

  final Appointment appointment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: _ContactDetailBlock(
          leading: Icons.person_pin_circle_outlined,
          title: appointment.patient,
          phone: appointment.phone,
          details: '${appointment.procedure} - ${appointment.time}',
          doctor: appointment.doctor,
          color: appointment.color,
        ),
      ),
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  const _InvoiceTile({required this.invoice});

  final Invoice invoice;

  @override
  Widget build(BuildContext context) {
    return _CashDetailBlock(
      leading: Icons.receipt,
      title: invoice.patient,
      invoiceNumber: invoice.number,
      method: invoice.method,
      status: invoice.status,
      amount: invoice.amount,
      color: invoice.color,
    );
  }
}

class _ContactDetailBlock extends StatelessWidget {
  const _ContactDetailBlock({
    required this.leading,
    required this.title,
    required this.phone,
    required this.details,
    required this.doctor,
    required this.color,
  });

  final IconData leading;
  final String title;
  final String phone;
  final String details;
  final String doctor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E7EC)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(leading, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _openPhoneNumber(context, phone),
                    child: Text(
                      phone,
                      style: const TextStyle(
                        color: Color(0xFF0B7285),
                        fontWeight: FontWeight.w800,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(details, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(doctor, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _CashDetailBlock extends StatelessWidget {
  const _CashDetailBlock({
    required this.leading,
    required this.title,
    required this.invoiceNumber,
    required this.method,
    required this.status,
    required this.amount,
    required this.color,
  });

  final IconData leading;
  final String title;
  final String invoiceNumber;
  final String method;
  final String status;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E7EC)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(leading, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  invoiceNumber,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _StatusPill(label: method, color: color),
                    _StatusPill(label: status, color: const Color(0xFF667085)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(amount, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _BookingSlotTile extends StatelessWidget {
  const _BookingSlotTile({required this.slot});

  final BookingSlot slot;

  @override
  Widget build(BuildContext context) {
    return _ListBlock(
      leading: Icons.schedule,
      title: '${slot.time} - ${slot.room}',
      subtitle: '${slot.doctor} - ${slot.type}',
      trailing: slot.status,
      color: slot.color,
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project, this.onViewDetails});

  final ClinicProject project;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    final note = project.clinicalNote.isEmpty
        ? ''
        : ' - Note: ${project.clinicalNote}';
    final followUp = project.followUpReason.isEmpty
        ? ''
        : ' - Follow up: ${project.followUpDue} ${project.followUpChannel} (${project.followUpPriority})';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onViewDetails,
              child: _ListBlock(
                leading: Icons.work,
                title: '${project.projectId} - ${project.name}',
                subtitle:
                    '${project.owner} - ${project.deadline} - ${project.procedure} - ${project.dentition} ${project.tooth}$note$followUp',
                trailing: '${(project.progress * 100).round()}%',
                trailingWidget: onViewDetails == null
                    ? null
                    : Tooltip(
                        message: 'View invoice detail',
                        child: IconButton.filledTonal(
                          onPressed: onViewDetails,
                          icon: const Icon(Icons.chevron_right),
                          style: IconButton.styleFrom(
                            minimumSize: const Size(36, 36),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                color: project.color,
              ),
            ),
          ),
          LinearProgressIndicator(value: project.progress),
        ],
      ),
    );
  }
}

class _ProjectInvoiceTile extends StatelessWidget {
  const _ProjectInvoiceTile({
    required this.invoice,
    required this.onViewDetails,
  });

  final Invoice invoice;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final procedure = invoice.procedure.isEmpty
        ? 'Invoice saved from cashier'
        : invoice.procedure;
    final tooth = invoice.tooth.isEmpty
        ? ''
        : ' - ${invoice.dentition} ${invoice.tooth}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onViewDetails,
              child: _ListBlock(
                leading: Icons.receipt_long,
                title: '${invoice.number} - ${invoice.patient}',
                subtitle: '${invoice.doctor} - $procedure$tooth',
                trailing: invoice.amount,
                trailingWidget: Tooltip(
                  message: 'View invoice detail',
                  child: IconButton.filledTonal(
                    onPressed: onViewDetails,
                    icon: const Icon(Icons.chevron_right),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(36, 36),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                color: invoice.color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ListBlock extends StatelessWidget {
  const _ListBlock({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.color,
    this.trailingWidget,
  });

  final IconData leading;
  final String title;
  final String subtitle;
  final String trailing;
  final Color color;
  final Widget? trailingWidget;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E7EC)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(leading, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(subtitle, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 10),
          trailingWidget ??
              Text(
                trailing,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
        ],
      ),
    );
  }
}

class _BookingForm extends StatefulWidget {
  const _BookingForm();

  @override
  State<_BookingForm> createState() => _BookingFormState();
}

class _BookingFormState extends State<_BookingForm> {
  final patientAgeController = TextEditingController();
  final phoneNumberController = TextEditingController();

  @override
  void dispose() {
    patientAgeController.dispose();
    phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FormFieldStub(
          icon: Icons.person_outline,
          label: 'Patient name',
          value: 'Search or add patient',
        ),
        _ProjectInput(
          controller: patientAgeController,
          icon: Icons.cake_outlined,
          label: 'Patient age',
          hintText: 'Age',
          keyboardType: TextInputType.number,
        ),
        _ProjectInput(
          controller: phoneNumberController,
          icon: Icons.call_outlined,
          label: 'Phone number',
          hintText: '+60...',
          keyboardType: TextInputType.phone,
        ),
        const _BookingDoctorField(),
        const _BookingProcedureField(),
        const _BookingDateTimeField(),
        const _FormFieldStub(
          icon: Icons.notes_outlined,
          label: 'Notes',
          value: 'Symptoms, referral, or billing note',
        ),
        const SizedBox(height: 6),
        const _ActionButton(
          icon: Icons.event_available,
          label: 'Book appointment',
          color: Color(0xFF0B7285),
        ),
      ],
    );
  }
}

class _BookingDateTimeField extends StatefulWidget {
  const _BookingDateTimeField();

  @override
  State<_BookingDateTimeField> createState() => _BookingDateTimeFieldState();
}

class _BookingDateTimeFieldState extends State<_BookingDateTimeField> {
  final controller = TextEditingController(text: 'Today, 15:30');
  DateTime? selectedDate;
  TimeOfDay? selectedTime = const TimeOfDay(hour: 15, minute: 30);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  String get formattedDate {
    final date = selectedDate;
    if (date == null) {
      return 'Today';
    }

    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String get formattedTime {
    final time = selectedTime;
    if (time == null) {
      return '';
    }

    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void syncController() {
    final time = formattedTime;
    controller.text = time.isEmpty ? formattedDate : '$formattedDate, $time';
  }

  Future<void> pickBookingDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 730)),
    );

    if (pickedDate == null) {
      return;
    }

    setState(() {
      selectedDate = pickedDate;
      syncController();
    });
  }

  Future<void> pickBookingTime() async {
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );

    if (pickedTime == null) {
      return;
    }

    setState(() {
      selectedTime = pickedTime;
      syncController();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        decoration: _inputDecoration(
          icon: Icons.event_outlined,
          label: 'Date and time',
          hintText: 'Type date/time or pick',
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Pick appointment date',
                onPressed: pickBookingDate,
                icon: const Icon(Icons.calendar_month_outlined),
              ),
              IconButton(
                tooltip: 'Pick appointment time',
                onPressed: pickBookingTime,
                icon: const Icon(Icons.schedule_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingDoctorField extends StatelessWidget {
  const _BookingDoctorField();

  Future<void> openDoctorPicker(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final selectedDoctor = await showDialog<String>(
      context: context,
      builder: (context) => _ProjectEntityPicker(
        title: 'Doctor',
        icon: Icons.medical_services_outlined,
        source: 'From Doctor Page',
        selectedValue: controller.text.trim().isEmpty
            ? null
            : controller.text.trim(),
        options: [
          for (final doctor in sampleDoctors)
            _ProjectSelectionOption(
              value: doctor.name,
              label: doctor.name,
              detail: '${doctor.specialty} - ${doctor.status}',
            ),
        ],
      ),
    );

    if (selectedDoctor != null) {
      controller.text = selectedDoctor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Autocomplete<String>(
        initialValue: const TextEditingValue(text: 'Dr. Marcus Lee'),
        optionsBuilder: (textEditingValue) {
          final query = textEditingValue.text.trim().toLowerCase();
          if (query.isEmpty) {
            return sampleDoctors.map((doctor) => doctor.name);
          }

          return sampleDoctors
              .where((doctor) {
                return doctor.name.toLowerCase().contains(query) ||
                    doctor.specialty.toLowerCase().contains(query) ||
                    doctor.status.toLowerCase().contains(query);
              })
              .map((doctor) => doctor.name);
        },
        onSelected: (_) {},
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: _inputDecoration(
              icon: Icons.medical_services_outlined,
              label: 'Doctor',
              hintText: 'Type doctor name or choose from Doctor Page',
              suffixIcon: IconButton(
                tooltip: 'Choose doctor from Doctor Page',
                onPressed: () => openDoctorPicker(context, controller),
                icon: const Icon(Icons.manage_search_outlined),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookingProcedureField extends StatelessWidget {
  const _BookingProcedureField();

  Future<void> openProcedurePicker(
    BuildContext context,
    TextEditingController controller,
  ) async {
    final selectedProcedure = await showDialog<String>(
      context: context,
      builder: (context) => _ProjectEntityPicker(
        title: 'Procedure',
        icon: Icons.healing_outlined,
        source: 'From Procedure Page',
        selectedValue: controller.text.trim().isEmpty
            ? null
            : controller.text.trim(),
        options: [
          for (final procedure in sampleProcedures)
            _ProjectSelectionOption(
              value: procedure.name,
              label: procedure.name,
              detail:
                  '${procedure.categoryPath.isEmpty ? procedure.stage : procedure.categoryPath} - ${procedure.estimate}',
            ),
        ],
      ),
    );

    if (selectedProcedure != null) {
      controller.text = selectedProcedure;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Autocomplete<String>(
        initialValue: const TextEditingValue(text: 'Consultation'),
        optionsBuilder: (textEditingValue) {
          final query = textEditingValue.text.trim().toLowerCase();
          if (query.isEmpty) {
            return sampleProcedures.map((procedure) => procedure.name);
          }

          return sampleProcedures
              .where((procedure) {
                return procedure.name.toLowerCase().contains(query) ||
                    procedure.stage.toLowerCase().contains(query) ||
                    procedure.categoryPath.toLowerCase().contains(query) ||
                    procedure.estimate.toLowerCase().contains(query);
              })
              .map((procedure) => procedure.name);
        },
        onSelected: (_) {},
        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: _inputDecoration(
              icon: Icons.healing_outlined,
              label: 'Procedure',
              hintText: 'Type procedure or choose from Procedure Page',
              suffixIcon: IconButton(
                tooltip: 'Choose procedure from Procedure Page',
                onPressed: () => openProcedurePicker(context, controller),
                icon: const Icon(Icons.manage_search_outlined),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FormFieldStub extends StatelessWidget {
  const _FormFieldStub({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          hintText: value,
          prefixIcon: Icon(icon),
          suffixIcon: const Icon(Icons.keyboard_arrow_down),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDCE3EA)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFDCE3EA)),
          ),
        ),
      ),
    );
  }
}

class _ProjectForm extends StatefulWidget {
  const _ProjectForm({
    required this.users,
    required this.procedures,
    required this.isSaving,
    required this.onSubmit,
  });

  final List<ClinicUser> users;
  final List<DentalProcedure> procedures;
  final bool isSaving;
  final Future<bool> Function(ProjectDraft draft) onSubmit;

  @override
  State<_ProjectForm> createState() => _ProjectFormState();
}

class _ProjectFormState extends State<_ProjectForm> {
  final projectIdController = TextEditingController();
  final clinicalNoteController = TextEditingController();
  final followUpReasonController = TextEditingController();
  final followUpDueController = TextEditingController();
  final summaryController = TextEditingController();
  var priority = 'Medium';
  var followUpChannel = 'Phone call';
  var followUpPriority = 'Medium';
  String? selectedPatient;
  String? selectedDoctor;
  String? selectedProcedure;
  var selectedDentition = DentitionType.adult;
  var selectedTooth = 'Tooth 11';

  @override
  void initState() {
    super.initState();
    projectIdController.text = _nextProjectId;
    selectedPatient = _firstPatientName;
    selectedDoctor = _firstDoctorName;
    selectedProcedure = _firstProcedureName;
  }

  @override
  void didUpdateWidget(covariant _ProjectForm oldWidget) {
    super.didUpdateWidget(oldWidget);

    final hasSelectedProcedure = widget.procedures.any(
      (procedure) => procedure.name == selectedProcedure,
    );
    if (!hasSelectedProcedure) {
      selectedProcedure = _firstProcedureName;
    }

    final hasSelectedPatient = patients.any(
      (patient) => patient.name == selectedPatient,
    );
    if (!hasSelectedPatient) {
      selectedPatient = _firstPatientName;
    }
  }

  List<ClinicUser> get patients {
    return widget.users
        .where((user) => user.role == RoleFilter.user.label)
        .toList();
  }

  String? get _firstPatientName =>
      patients.isEmpty ? null : patients.first.name;

  String? get _firstDoctorName =>
      sampleDoctors.isEmpty ? null : sampleDoctors.first.name;

  String? get selectedPatientDetail {
    for (final patient in patients) {
      if (patient.name == selectedPatient) {
        return '${patient.phone} - ${patient.status}';
      }
    }
    return null;
  }

  String? get selectedDoctorDetail {
    for (final doctor in sampleDoctors) {
      if (doctor.name == selectedDoctor) {
        return '${doctor.specialty} - ${doctor.status}';
      }
    }
    return null;
  }

  String? get selectedProcedureDetail {
    for (final procedure in widget.procedures) {
      if (procedure.name == selectedProcedure) {
        return '${procedure.categoryPath} - ${procedure.netPrice}';
      }
    }
    return null;
  }

  String? get _firstProcedureName =>
      widget.procedures.isEmpty ? null : widget.procedures.first.name;

  String? get _projectProcedureName => selectedProcedure;

  String get _nextProjectId {
    final now = DateTime.now();
    final date =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
    return 'PRJ-$date-${(widget.procedures.length + 1).toString().padLeft(3, '0')}';
  }

  Future<void> pickFollowUpDueDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 30)),
      lastDate: now.add(const Duration(days: 730)),
    );

    if (pickedDate == null) {
      return;
    }

    final formattedDate =
        '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
    followUpDueController.text = formattedDate;
  }

  Future<void> pickPatient() async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => _ProjectEntityPicker(
        title: 'Patient Name',
        icon: Icons.person_outline,
        source: 'From Patient Page',
        selectedValue: selectedPatient,
        options: [
          for (final patient in patients)
            _ProjectSelectionOption(
              value: patient.name,
              label: patient.name,
              detail: patient.phone,
            ),
        ],
      ),
    );

    if (value != null) {
      setState(() => selectedPatient = value);
    }
  }

  Future<void> pickDoctor() async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => _ProjectEntityPicker(
        title: 'Doctor',
        icon: Icons.medical_services_outlined,
        source: 'From Doctor Page',
        selectedValue: selectedDoctor,
        options: [
          for (final doctor in sampleDoctors)
            _ProjectSelectionOption(
              value: doctor.name,
              label: doctor.name,
              detail: doctor.specialty,
            ),
        ],
      ),
    );

    if (value != null) {
      setState(() => selectedDoctor = value);
    }
  }

  Future<void> pickProcedure() async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => _ProjectEntityPicker(
        title: 'Procedure',
        icon: Icons.healing_outlined,
        source: 'From Procedure Page',
        selectedValue: selectedProcedure,
        options: [
          for (final procedure in widget.procedures)
            _ProjectSelectionOption(
              value: procedure.name,
              label: procedure.name,
              detail:
                  '${procedure.categoryPath.isEmpty ? procedure.stage : procedure.categoryPath} - ${procedure.netPrice}',
            ),
        ],
      ),
    );

    if (value != null) {
      setState(() => selectedProcedure = value);
    }
  }

  @override
  void dispose() {
    projectIdController.dispose();
    clinicalNoteController.dispose();
    followUpReasonController.dispose();
    followUpDueController.dispose();
    summaryController.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final projectId = projectIdController.text.trim();
    final projectProcedure = _projectProcedureName;

    if (projectId.isEmpty ||
        selectedPatient == null ||
        selectedDoctor == null ||
        projectProcedure == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Project ID, patient name, doctor, and procedure are required',
          ),
        ),
      );
      return;
    }

    final created = await widget.onSubmit(
      ProjectDraft(
        projectId: projectId,
        name: selectedPatient!,
        owner: selectedDoctor!,
        deadline: 'Next visit',
        procedure: projectProcedure,
        dentition: selectedDentition.label,
        tooth: selectedTooth,
        priority: priority,
        clinicalNote: clinicalNoteController.text.trim(),
        followUpReason: followUpReasonController.text.trim(),
        followUpDue: followUpDueController.text.trim(),
        followUpChannel: followUpChannel,
        followUpPriority: followUpPriority,
        summary: summaryController.text.trim(),
      ),
    );

    if (!mounted || !created) {
      return;
    }

    summaryController.clear();
    clinicalNoteController.clear();
    followUpReasonController.clear();
    followUpDueController.clear();
    setState(() {
      priority = 'Medium';
      followUpChannel = 'Phone call';
      followUpPriority = 'Medium';
      selectedPatient = _firstPatientName;
      selectedDoctor = _firstDoctorName;
      selectedProcedure = _firstProcedureName;
      selectedDentition = DentitionType.adult;
      selectedTooth = 'Tooth 11';
      projectIdController.text = _nextProjectId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ProjectInput(
          controller: projectIdController,
          icon: Icons.tag_outlined,
          label: 'Project ID',
          hintText: 'PRJ-20260803-001',
        ),
        _ProjectPickerInput(
          icon: Icons.person_outline,
          label: 'Patient Name',
          value: selectedPatient,
          detail: selectedPatientDetail ?? 'Select patient',
          hintText: 'Choose patient from Patient Page',
          suffixTooltip: 'Choose patient from Patient Page',
          enabled: !widget.isSaving && patients.isNotEmpty,
          onPick: pickPatient,
        ),
        _ProjectPickerInput(
          icon: Icons.medical_services_outlined,
          label: 'Doctor',
          value: selectedDoctor,
          detail: selectedDoctorDetail ?? 'Select doctor',
          hintText: 'Choose doctor from Doctor Page',
          suffixTooltip: 'Choose doctor from Doctor Page',
          enabled: !widget.isSaving,
          onPick: pickDoctor,
        ),
        _ProjectPickerInput(
          icon: Icons.healing_outlined,
          label: 'Procedure',
          value: selectedProcedure,
          detail: selectedProcedureDetail ?? 'Select procedure',
          hintText: 'Choose procedure from Procedure Page',
          suffixTooltip: 'Choose procedure from Procedure Page',
          enabled: !widget.isSaving && widget.procedures.isNotEmpty,
          onPick: pickProcedure,
        ),
        const SizedBox(height: 10),
        _ToothSelector(
          dentition: selectedDentition,
          selectedTooth: selectedTooth,
          onDentitionChanged: (dentition) => setState(() {
            selectedDentition = dentition;
            selectedTooth = dentition.teeth.first;
          }),
          onToothChanged: (tooth) => setState(() => selectedTooth = tooth),
        ),
        const SizedBox(height: 10),
        _ProjectInput(
          controller: clinicalNoteController,
          icon: Icons.medical_information_outlined,
          label: 'Clinical Note',
          hintText: 'Symptoms, diagnosis, treatment plan, or clinical findings',
          maxLines: 3,
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFDCE3EA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.event_repeat_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Follow Up',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const _StatusPill(
                    label: 'Optional',
                    color: Color(0xFF0B7285),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ProjectInput(
                controller: followUpReasonController,
                icon: Icons.assignment_outlined,
                label: 'Follow up reason',
                hintText: 'Pain check, recall, payment reminder',
                maxLines: 2,
              ),
              _ProjectInput(
                controller: followUpDueController,
                icon: Icons.event_outlined,
                label: 'Follow up due',
                hintText: 'Type date or pick from calendar',
                suffixIcon: IconButton(
                  tooltip: 'Pick follow up date',
                  onPressed: widget.isSaving ? null : pickFollowUpDueDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                ),
              ),
              DropdownButtonFormField<String>(
                initialValue: followUpChannel,
                decoration: _inputDecoration(
                  icon: Icons.mark_chat_unread_outlined,
                  label: 'Follow up channel',
                  hintText: 'Phone call',
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Phone call',
                    child: Text('Phone call'),
                  ),
                  DropdownMenuItem(value: 'WhatsApp', child: Text('WhatsApp')),
                  DropdownMenuItem(value: 'SMS', child: Text('SMS')),
                  DropdownMenuItem(value: 'In-app', child: Text('In-app')),
                ],
                onChanged: widget.isSaving
                    ? null
                    : (value) => setState(
                        () => followUpChannel = value ?? followUpChannel,
                      ),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: followUpPriority,
                decoration: _inputDecoration(
                  icon: Icons.priority_high_outlined,
                  label: 'Follow up priority',
                  hintText: 'Medium',
                ),
                items: const [
                  DropdownMenuItem(value: 'Routine', child: Text('Routine')),
                  DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'High', child: Text('High')),
                ],
                onChanged: widget.isSaving
                    ? null
                    : (value) => setState(
                        () => followUpPriority = value ?? followUpPriority,
                      ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: priority,
          decoration: _inputDecoration(
            icon: Icons.flag_outlined,
            label: 'Priority',
            hintText: 'Medium',
          ),
          items: const [
            DropdownMenuItem(value: 'Low', child: Text('Low')),
            DropdownMenuItem(value: 'Medium', child: Text('Medium')),
            DropdownMenuItem(value: 'High', child: Text('High')),
          ],
          onChanged: (value) => setState(() => priority = value ?? priority),
        ),
        const SizedBox(height: 10),
        _ProjectInput(
          controller: summaryController,
          icon: Icons.notes_outlined,
          label: 'Summary',
          hintText: 'Scope, expected result, and blockers',
        ),
        const SizedBox(height: 6),
        FilledButton.icon(
          onPressed: widget.isSaving ? null : submit,
          icon: widget.isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.add_task),
          label: Text(widget.isSaving ? 'Adding project' : 'Add project'),
        ),
      ],
    );
  }
}

class _ToothSelector extends StatelessWidget {
  const _ToothSelector({
    required this.dentition,
    required this.selectedTooth,
    required this.onDentitionChanged,
    required this.onToothChanged,
    this.onJoinProcedure,
  });

  final DentitionType dentition;
  final String selectedTooth;
  final ValueChanged<DentitionType> onDentitionChanged;
  final ValueChanged<String> onToothChanged;
  final VoidCallback? onJoinProcedure;

  @override
  Widget build(BuildContext context) {
    final selectedTeeth = _selectedTeethFromValue(selectedTooth, dentition);
    final selectedToothLabel = selectedTeeth.join(', ');
    final archLabel = _selectedArchLabel(dentition, selectedTeeth);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCE3EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Select tooth',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                'Selected tooth: $selectedToothLabel',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: const Color(0xFF0B7285),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<DentitionType>(
            segments: const [
              ButtonSegment(
                value: DentitionType.adult,
                label: Text('Adult'),
                icon: Icon(Icons.badge_outlined),
              ),
              ButtonSegment(
                value: DentitionType.child,
                label: Text('Child'),
                icon: Icon(Icons.child_care),
              ),
            ],
            selected: {dentition},
            onSelectionChanged: (selection) {
              onDentitionChanged(selection.first);
            },
          ),
          const SizedBox(height: 12),
          _InteractiveDentalChart(
            dentition: dentition,
            selectedTeeth: selectedTeeth.toSet(),
            onToothChanged: (tooth) {
              final nextTeeth = _toggleSelectedTooth(selectedTeeth, tooth);
              onToothChanged(nextTeeth.join(', '));
            },
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 640;
              final joinWidth = onJoinProcedure == null || compact
                  ? 0.0
                  : 112.0;
              final fieldWidth = compact
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 24 - joinWidth) / 3;

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ToothSelectionField(
                    width: fieldWidth,
                    icon: Icons.badge_outlined,
                    label: 'Dentition',
                    value: dentition.label,
                  ),
                  _ToothSelectionField(
                    width: fieldWidth,
                    icon: Icons.vertical_align_center,
                    label: 'Arch',
                    value: archLabel,
                  ),
                  _ToothSelectionField(
                    width: fieldWidth,
                    icon: Icons.radio_button_checked,
                    label: 'Selected tooth',
                    value: selectedToothLabel,
                  ),
                  if (onJoinProcedure != null)
                    SizedBox(
                      width: compact ? constraints.maxWidth : joinWidth,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: onJoinProcedure,
                        icon: const Icon(Icons.link, size: 18),
                        label: const Text('Join'),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ToothSelectionField extends StatelessWidget {
  const _ToothSelectionField({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InputDecorator(
        decoration: _inputDecoration(icon: icon, label: label, hintText: label),
        child: Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _InteractiveDentalChart extends StatelessWidget {
  const _InteractiveDentalChart({
    required this.dentition,
    required this.selectedTeeth,
    required this.onToothChanged,
  });

  final DentitionType dentition;
  final Set<String> selectedTeeth;
  final ValueChanged<String> onToothChanged;

  @override
  Widget build(BuildContext context) {
    final chartHeight = dentition == DentitionType.adult ? 380.0 : 280.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE1E7EC)),
      ),
      child: Column(
        children: [
          _ArchTitle('Upper Teeth', color: const Color(0xFF0B7285)),
          const SizedBox(height: 8),
          SizedBox(
            height: chartHeight / 2,
            child: _ToothArch(
              teeth: dentition.upperTeeth,
              selectedTeeth: selectedTeeth,
              onToothChanged: onToothChanged,
              lower: false,
            ),
          ),
          const SizedBox(height: 12),
          _ArchTitle('Lower Teeth', color: const Color(0xFFC2410C)),
          const SizedBox(height: 8),
          SizedBox(
            height: chartHeight / 2,
            child: _ToothArch(
              teeth: dentition.lowerTeeth,
              selectedTeeth: selectedTeeth,
              onToothChanged: onToothChanged,
              lower: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _ArchTitle extends StatelessWidget {
  const _ArchTitle(this.label, {required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ToothArch extends StatelessWidget {
  const _ToothArch({
    required this.teeth,
    required this.selectedTeeth,
    required this.onToothChanged,
    required this.lower,
  });

  final List<String> teeth;
  final Set<String> selectedTeeth;
  final ValueChanged<String> onToothChanged;
  final bool lower;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final points = _archPoints(
          teeth.length,
          constraints.maxWidth,
          constraints.maxHeight,
          lower,
        );

        return Stack(
          children: [
            CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _ArchGuidePainter(lower: lower),
            ),
            for (var index = 0; index < teeth.length; index++)
              Positioned(
                left: points[index].dx - 18,
                top: points[index].dy - 18,
                child: _ToothNumberButton(
                  tooth: teeth[index],
                  selected: selectedTeeth.contains(teeth[index]),
                  onTap: () => onToothChanged(teeth[index]),
                ),
              ),
          ],
        );
      },
    );
  }

  List<Offset> _archPoints(int count, double width, double height, bool lower) {
    final points = <Offset>[];
    for (var index = 0; index < count; index++) {
      final t = count == 1 ? 0.5 : index / (count - 1);
      final x = width * (0.08 + t * 0.84);
      final curve = 1 - (2 * t - 1).abs();
      final y = lower
          ? height * (0.18 + curve * 0.56)
          : height * (0.76 - curve * 0.56);
      points.add(Offset(x, y));
    }
    return points;
  }
}

class _ToothNumberButton extends StatelessWidget {
  const _ToothNumberButton({
    required this.tooth,
    required this.selected,
    required this.onTap,
  });

  final String tooth;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF0B7285) : const Color(0xFF344054);
    return Semantics(
      button: true,
      selected: selected,
      label: tooth,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFDDF4F7) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? const Color(0xFF0B7285)
                  : const Color(0xFFD0D5DD),
              width: selected ? 2 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            _toothNumber(tooth),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _ArchGuidePainter extends CustomPainter {
  const _ArchGuidePainter({required this.lower});

  final bool lower;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = const Color(0xFFE8F3F5)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFFB8CBD2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path();
    if (lower) {
      path
        ..moveTo(size.width * 0.08, size.height * 0.18)
        ..quadraticBezierTo(
          size.width * 0.5,
          size.height * 0.88,
          size.width * 0.92,
          size.height * 0.18,
        )
        ..quadraticBezierTo(
          size.width * 0.5,
          size.height * 0.68,
          size.width * 0.08,
          size.height * 0.18,
        );
    } else {
      path
        ..moveTo(size.width * 0.08, size.height * 0.76)
        ..quadraticBezierTo(
          size.width * 0.5,
          size.height * 0.06,
          size.width * 0.92,
          size.height * 0.76,
        )
        ..quadraticBezierTo(
          size.width * 0.5,
          size.height * 0.42,
          size.width * 0.08,
          size.height * 0.76,
        );
    }

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _ArchGuidePainter oldDelegate) {
    return oldDelegate.lower != lower;
  }
}

String _toothNumber(String tooth) {
  return tooth.replaceFirst('Child Tooth ', '').replaceFirst('Tooth ', '');
}

List<String> _selectedTeethFromValue(String value, DentitionType dentition) {
  final selected = value
      .split(', ')
      .map((tooth) => tooth.trim())
      .where(dentition.teeth.contains)
      .toList();

  if (selected.isEmpty) {
    return [dentition.teeth.first];
  }
  return selected;
}

List<String> _toggleSelectedTooth(List<String> selectedTeeth, String tooth) {
  if (selectedTeeth.contains(tooth)) {
    if (selectedTeeth.length == 1) {
      return selectedTeeth;
    }
    return [...selectedTeeth]..remove(tooth);
  }

  return [...selectedTeeth, tooth];
}

String _selectedArchLabel(DentitionType dentition, List<String> selectedTeeth) {
  final selected = selectedTeeth.toSet();
  final hasUpper = selected.any(dentition.upperTeeth.contains);
  final hasLower = selected.any(dentition.lowerTeeth.contains);

  if (hasUpper && hasLower) {
    return 'Upper + Lower';
  }
  if (hasUpper) {
    return 'Upper';
  }
  if (hasLower) {
    return 'Lower';
  }
  return 'None';
}

class _ProjectSelectionOption {
  const _ProjectSelectionOption({
    required this.value,
    required this.label,
    required this.detail,
  });

  final String value;
  final String label;
  final String detail;
}

class _ProjectEntitySelector extends StatelessWidget {
  const _ProjectEntitySelector({
    required this.icon,
    required this.title,
    required this.source,
    required this.selectedValue,
    required this.selectedDetail,
    required this.options,
    required this.onSelected,
  });

  final IconData icon;
  final String title;
  final String source;
  final String? selectedValue;
  final String selectedDetail;
  final List<_ProjectSelectionOption> options;
  final ValueChanged<String> onSelected;

  Future<void> openPicker(BuildContext context) async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => _ProjectEntityPicker(
        title: title,
        icon: icon,
        source: source,
        selectedValue: selectedValue,
        options: options,
      ),
    );

    if (value != null) {
      onSelected(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDCE3EA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              _StatusPill(label: source, color: const Color(0xFF0B7285)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE1E7EC)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedValue ?? 'No selection',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        selectedDetail,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Color(0xFF52606D)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.check_circle_outline,
                  color: Color(0xFF166534),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => openPicker(context),
            icon: const Icon(Icons.manage_search_outlined),
            label: Text('Select $title'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectEntityPicker extends StatefulWidget {
  const _ProjectEntityPicker({
    required this.title,
    required this.icon,
    required this.source,
    required this.selectedValue,
    required this.options,
  });

  final String title;
  final IconData icon;
  final String source;
  final String? selectedValue;
  final List<_ProjectSelectionOption> options;

  @override
  State<_ProjectEntityPicker> createState() => _ProjectEntityPickerState();
}

class _ProjectEntityPickerState extends State<_ProjectEntityPicker> {
  final searchController = TextEditingController();

  List<_ProjectSelectionOption> get filteredOptions {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.options;
    }

    return widget.options.where((option) {
      return option.label.toLowerCase().contains(query) ||
          option.detail.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final options = filteredOptions;

    return AlertDialog(
      title: Row(
        children: [
          Icon(widget.icon),
          const SizedBox(width: 10),
          Expanded(child: Text('Select ${widget.title}')),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: _inputDecoration(
                icon: Icons.search,
                label: 'Search ${widget.title}',
                hintText: 'Type name, phone, or specialty',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: _StatusPill(
                label: widget.source,
                color: const Color(0xFF0B7285),
              ),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: options.isEmpty
                  ? const Center(child: Text('No matching names'))
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: options.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final selected = option.value == widget.selectedValue;

                        return ListTile(
                          leading: Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: selected
                                ? const Color(0xFF166534)
                                : const Color(0xFF98A2B3),
                          ),
                          title: Text(option.label),
                          subtitle: Text(option.detail),
                          onTap: () => Navigator.of(context).pop(option.value),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class _ProjectPickerInput extends StatelessWidget {
  const _ProjectPickerInput({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.hintText,
    required this.suffixTooltip,
    required this.onPick,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final String? value;
  final String detail;
  final String hintText;
  final String suffixTooltip;
  final VoidCallback onPick;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        key: ValueKey('project-picker-$label-$value'),
        initialValue: value,
        readOnly: true,
        onTap: enabled ? onPick : null,
        decoration: _inputDecoration(
          icon: icon,
          label: label,
          hintText: hintText,
          suffixIcon: IconButton(
            tooltip: suffixTooltip,
            onPressed: enabled ? onPick : null,
            icon: const Icon(Icons.manage_search_outlined),
          ),
        ).copyWith(helperText: detail),
      ),
    );
  }
}

class _ProjectInput extends StatelessWidget {
  const _ProjectInput({
    required this.controller,
    required this.icon,
    required this.label,
    required this.hintText,
    this.keyboardType,
    this.maxLines = 1,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final IconData icon;
  final String label;
  final String hintText;
  final TextInputType? keyboardType;
  final int maxLines;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: _inputDecoration(
          icon: icon,
          label: label,
          hintText: hintText,
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration({
  required IconData icon,
  required String label,
  required String hintText,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hintText,
    prefixIcon: Icon(icon),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFDCE3EA)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFDCE3EA)),
    ),
  );
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.value,
    required this.detail,
  });

  final String label;
  final double value;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(detail, style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: value),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final ClinicUser user;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: user.color.withValues(alpha: 0.15),
                  child: Text(
                    user.initials,
                    style: TextStyle(
                      color: user.color,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      Text(user.role),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Age ${user.age}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(user.phone, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(user.address, maxLines: 1, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(
              children: [
                _StatusPill(label: user.status, color: user.color),
                const Spacer(),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_horiz),
                  tooltip: 'Actions',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  const _DoctorCard({required this.doctor});

  final Doctor doctor;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: doctor.color.withValues(alpha: 0.15),
                  child: Icon(Icons.medical_services, color: doctor.color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    doctor.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                _StatusPill(label: doctor.status, color: doctor.color),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              doctor.specialty,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${doctor.patientsToday} patients today - Room ${doctor.room}',
            ),
            const Spacer(),
            LinearProgressIndicator(value: doctor.utilization),
          ],
        ),
      ),
    );
  }
}

class _FollowUpCard extends StatelessWidget {
  const _FollowUpCard({required this.followUp});

  final FollowUp followUp;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _StatusPill(
                      label: followUp.priority,
                      color: followUp.color,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  followUp.due,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              followUp.patient,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              followUp.phone,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              followUp.doctor,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(followUp.reason, maxLines: 2, overflow: TextOverflow.ellipsis),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.call_outlined, size: 18),
                const SizedBox(width: 6),
                Expanded(child: Text(followUp.channel)),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: 'Complete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PharmacyDispenseTile extends StatelessWidget {
  const _PharmacyDispenseTile({required this.dispense});

  final PharmacyDispense dispense;

  @override
  Widget build(BuildContext context) {
    return _ListBlock(
      leading: Icons.local_pharmacy,
      title: dispense.patient,
      subtitle: '${dispense.medicine} - ${dispense.dose}',
      trailing: dispense.status,
      color: dispense.color,
    );
  }
}

class _PharmacyPaymentTile extends StatelessWidget {
  const _PharmacyPaymentTile({required this.payment});

  final PharmacyPayment payment;

  @override
  Widget build(BuildContext context) {
    return _CashDetailBlock(
      leading: Icons.point_of_sale,
      title: payment.patient,
      invoiceNumber: payment.invoiceNumber,
      method: payment.method,
      status: payment.status,
      amount: payment.amount,
      color: payment.color,
    );
  }
}

class _MedicineCard extends StatelessWidget {
  const _MedicineCard({required this.medicine, this.onTap});

  final Medicine medicine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final stockRatio = (medicine.stock / medicine.capacity).clamp(0.0, 1.0);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: medicine.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.medication, color: medicine.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      medicine.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  _StatusPill(label: medicine.status, color: medicine.color),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                medicine.productPath.isEmpty
                    ? medicine.category
                    : medicine.productPath,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (medicine.hasPrice) ...[
                const SizedBox(height: 8),
                Text(
                  medicine.netPrice,
                  style: TextStyle(
                    color: medicine.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (medicine.priceNature != null)
                  Text(
                    medicine.priceNature!.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (medicine.hasDiscount)
                  Text(
                    '${medicine.discountLabel} from ${medicine.price}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF667085),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
              if (medicine.tag.isNotEmpty) ...[
                const SizedBox(height: 8),
                _StatusPill(label: medicine.tag, color: medicine.color),
              ],
              const SizedBox(height: 8),
              Text(
                '${medicine.stock} ${medicine.unit} - Batch ${medicine.batch}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Expires ${medicine.expiry}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              LinearProgressIndicator(
                value: stockRatio,
                color: medicine.color,
                backgroundColor: medicine.color.withValues(alpha: 0.12),
              ),
              if (onTap != null) ...[
                const SizedBox(height: 8),
                Text(
                  'View details',
                  style: TextStyle(
                    color: medicine.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProcedureCard extends StatelessWidget {
  const _ProcedureCard({
    required this.procedure,
    this.onApplyToProject,
    this.onEdit,
    this.onDelete,
  });

  final DentalProcedure procedure;
  final VoidCallback? onApplyToProject;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(procedure.icon, color: procedure.color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    procedure.name,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  procedure.netPrice,
                  style: TextStyle(
                    color: procedure.color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (procedure.hasDiscount) ...[
              const SizedBox(height: 6),
              Text(
                '${procedure.discountLabel} from ${procedure.price}',
                style: const TextStyle(
                  color: Color(0xFF667085),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (procedure.procedureCategory.isNotEmpty) ...[
              const SizedBox(height: 8),
              _StatusPill(
                label: procedure.procedureCategory,
                color: procedure.color,
              ),
            ],
            if (procedure.tag.isNotEmpty) ...[
              const SizedBox(height: 8),
              _StatusPill(label: procedure.tag, color: procedure.color),
            ],
            const SizedBox(height: 12),
            if (procedure.stage.isNotEmpty || procedure.doctor.isNotEmpty) ...[
              Text(
                [
                  if (procedure.stage.isNotEmpty) procedure.stage,
                  if (procedure.doctor.isNotEmpty) procedure.doctor,
                ].join(' - '),
              ),
            ],
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule_outlined, size: 16, color: procedure.color),
                const SizedBox(width: 6),
                Expanded(child: Text('Estimated time: ${procedure.estimate}')),
              ],
            ),
            if (procedure.categoryPath.isNotEmpty &&
                procedure.stage.isEmpty &&
                procedure.doctor.isEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.account_tree_outlined,
                    size: 16,
                    color: procedure.color,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      procedure.categoryPath,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ],
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(value: procedure.progress),
                ),
                const SizedBox(width: 10),
                Text('${(procedure.progress * 100).round()}%'),
              ],
            ),
            if (onApplyToProject != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onApplyToProject,
                    icon: const Icon(Icons.work_outline),
                    label: const Text('Apply to project'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final buttonColor = color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: buttonColor == null
          ? OutlinedButton.icon(
              onPressed: onPressed ?? () {},
              icon: Icon(icon),
              label: Text(label),
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          : FilledButton.icon(
              onPressed: onPressed ?? () {},
              icon: Icon(icon),
              label: Text(label),
              style: FilledButton.styleFrom(
                alignment: Alignment.centerLeft,
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _NavigationItem {
  const _NavigationItem(
    this.icon,
    this.selectedIcon,
    this.label,
    this.shortLabel,
  );

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String shortLabel;
}

enum RoleFilter {
  all('All', Icons.groups_outlined),
  user('User', Icons.person_outline),
  doctor('Doctor', Icons.medical_services_outlined),
  cashier('Cashier', Icons.point_of_sale_outlined),
  admin('Admin', Icons.admin_panel_settings_outlined),
  owner('Owner', Icons.workspace_premium_outlined);

  const RoleFilter(this.label, this.icon);

  final String label;
  final IconData icon;

  bool get canCreateAllRoles {
    return this == RoleFilter.admin || this == RoleFilter.owner;
  }

  Color get color {
    return switch (this) {
      RoleFilter.all => const Color(0xFF0B7285),
      RoleFilter.user => const Color(0xFF0B7285),
      RoleFilter.doctor => const Color(0xFF7C3AED),
      RoleFilter.cashier => const Color(0xFF166534),
      RoleFilter.admin => const Color(0xFFC2410C),
      RoleFilter.owner => const Color(0xFF2563EB),
    };
  }

  static List<RoleFilter> get creatableRoles {
    return RoleFilter.values.where((role) => role != RoleFilter.all).toList();
  }

  static List<RoleFilter> get creatorRoles {
    return const [RoleFilter.user, RoleFilter.admin, RoleFilter.owner];
  }
}

enum DashboardDetail { appointments, followUps, cash, procedures }

enum AppointmentStatusFilter {
  waiting(
    'Waiting',
    '8',
    'Waiting patients',
    Icons.hourglass_top,
    Color(0xFFC2410C),
  ),
  inChair(
    'In chair',
    '9',
    'Patients in chair',
    Icons.chair_alt,
    Color(0xFF0B7285),
  ),
  completed(
    'Completed',
    '21',
    'Completed appointments',
    Icons.task_alt,
    Color(0xFF166534),
  ),
  booked(
    'Booked',
    '4',
    'Booked appointments',
    Icons.event_available,
    Color(0xFF7C3AED),
  );

  const AppointmentStatusFilter(
    this.label,
    this.count,
    this.detailTitle,
    this.icon,
    this.color,
  );

  final String label;
  final String count;
  final String detailTitle;
  final IconData icon;
  final Color color;
}

enum DentitionType {
  adult('Adult', [
    'Tooth 1',
    'Tooth 2',
    'Tooth 3',
    'Tooth 4',
    'Tooth 5',
    'Tooth 6',
    'Tooth 7',
    'Tooth 8',
    'Tooth 9',
    'Tooth 10',
    'Tooth 11',
    'Tooth 12',
    'Tooth 13',
    'Tooth 14',
    'Tooth 15',
    'Tooth 16',
    'Tooth 17',
    'Tooth 18',
    'Tooth 19',
    'Tooth 20',
    'Tooth 21',
    'Tooth 22',
    'Tooth 23',
    'Tooth 24',
    'Tooth 25',
    'Tooth 26',
    'Tooth 27',
    'Tooth 28',
    'Tooth 29',
    'Tooth 30',
    'Tooth 31',
    'Tooth 32',
  ]),
  child('Child', [
    'Child Tooth 1',
    'Child Tooth 2',
    'Child Tooth 3',
    'Child Tooth 4',
    'Child Tooth 5',
    'Child Tooth 6',
    'Child Tooth 7',
    'Child Tooth 8',
    'Child Tooth 9',
    'Child Tooth 10',
  ]);

  const DentitionType(this.label, this.teeth);

  final String label;
  final List<String> teeth;

  List<String> get upperTeeth {
    return switch (this) {
      DentitionType.adult => teeth.take(16).toList(),
      DentitionType.child => teeth.take(5).toList(),
    };
  }

  List<String> get lowerTeeth {
    return switch (this) {
      DentitionType.adult => teeth.skip(16).toList().reversed.toList(),
      DentitionType.child => teeth.skip(5).toList().reversed.toList(),
    };
  }
}

class DetailSummary {
  const DetailSummary(
    this.label,
    this.value,
    this.color, {
    this.onTap,
    this.selected = false,
  });

  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;
  final bool selected;
}

enum CashDetailFilter { paidToday, pending, invoices }

enum FollowUpDetailFilter {
  urgent('Urgent', '6', 'Urgent follow ups', Color(0xFFC2410C)),
  today('Today', '4', 'Due today', Color(0xFF0B7285)),
  all('All', '14', 'All pending follow ups', Color(0xFF166534));

  const FollowUpDetailFilter(
    this.label,
    this.value,
    this.detailTitle,
    this.color,
  );

  final String label;
  final String value;
  final String detailTitle;
  final Color color;

  bool matches(FollowUp followUp) {
    return switch (this) {
      FollowUpDetailFilter.urgent => followUp.priority == 'High',
      FollowUpDetailFilter.today => followUp.due == 'Today',
      FollowUpDetailFilter.all => true,
    };
  }
}

enum ProcedureDetailFilter {
  inChair('In chair', '9', 'Procedures in chair', Color(0xFF0B7285)),
  review('Review', '11', 'Procedure reviews', Color(0xFFC2410C)),
  all('All', '27', 'All active procedures', Color(0xFF166534));

  const ProcedureDetailFilter(
    this.label,
    this.value,
    this.detailTitle,
    this.color,
  );

  final String label;
  final String value;
  final String detailTitle;
  final Color color;

  bool matches(DentalProcedure procedure) {
    final stage = procedure.stage.toLowerCase();

    return switch (this) {
      ProcedureDetailFilter.inChair =>
        stage.contains('chair') || stage.contains('fitting'),
      ProcedureDetailFilter.review =>
        stage.contains('review') || stage.contains('pending'),
      ProcedureDetailFilter.all => true,
    };
  }
}

class ClinicUser {
  const ClinicUser(
    this.name,
    this.role,
    this.status,
    this.initials,
    this.color,
    this.age,
    this.phone,
    this.address,
  );

  final String name;
  final String role;
  final String status;
  final String initials;
  final Color color;
  final String age;
  final String phone;
  final String address;
}

String initialsForName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return 'U';
  }

  if (parts.length == 1) {
    return parts.first.characters.first.toUpperCase();
  }

  return '${parts.first.characters.first}${parts.last.characters.first}'
      .toUpperCase();
}

class Doctor {
  const Doctor(
    this.name,
    this.specialty,
    this.status,
    this.room,
    this.patientsToday,
    this.utilization,
    this.color,
  );

  final String name;
  final String specialty;
  final String status;
  final String room;
  final int patientsToday;
  final double utilization;
  final Color color;
}

class Appointment {
  const Appointment(
    this.patient,
    this.phone,
    this.time,
    this.procedure,
    this.doctor,
    this.color,
  );

  final String patient;
  final String phone;
  final String time;
  final String procedure;
  final String doctor;
  final Color color;
}

class AppointmentStatusDetail {
  const AppointmentStatusDetail(
    this.filter,
    this.bookingId,
    this.patient,
    this.phone,
    this.time,
    this.procedure,
    this.doctor,
    this.note,
  );

  final AppointmentStatusFilter filter;
  final String bookingId;
  final String patient;
  final String phone;
  final String time;
  final String procedure;
  final String doctor;
  final String note;
}

class QueueStatus {
  const QueueStatus(
    this.stage,
    this.currentBooking,
    this.currentPatient,
    this.nextBooking,
    this.estimatedTime,
    this.icon,
    this.color,
  );

  final String stage;
  final String currentBooking;
  final String currentPatient;
  final String nextBooking;
  final String estimatedTime;
  final IconData icon;
  final Color color;
}

class BookingSlot {
  const BookingSlot(
    this.time,
    this.room,
    this.doctor,
    this.type,
    this.status,
    this.color,
  );

  final String time;
  final String room;
  final String doctor;
  final String type;
  final String status;
  final Color color;
}

class Invoice {
  const Invoice(
    this.patient,
    this.number,
    this.method,
    this.status,
    this.amount,
    this.color,
    this.filter, {
    this.procedure = '',
    this.price = '',
    this.procedurePrice = '',
    this.serviceFee = '',
    this.doctor = '',
    this.dentition = '',
    this.tooth = '',
    this.clinicalNote = '',
    this.serviceChargeItems = const [],
    this.procedureItems = const [],
    this.pharmacyItems = const [],
  });

  final String patient;
  final String number;
  final String method;
  final String status;
  final String amount;
  final Color color;
  final CashDetailFilter filter;
  final String procedure;
  final String price;
  final String procedurePrice;
  final String serviceFee;
  final String doctor;
  final String dentition;
  final String tooth;
  final String clinicalNote;
  final List<ServiceChargeItem> serviceChargeItems;
  final List<ProcedureInvoiceItem> procedureItems;
  final List<PharmacyInvoiceItem> pharmacyItems;

  factory Invoice.fromProjectHistoryJson(Map<String, dynamic> json) {
    return Invoice(
      json['patient'] as String? ?? '',
      json['number'] as String? ?? '',
      json['method'] as String? ?? '',
      json['status'] as String? ?? '',
      json['amount'] as String? ?? '',
      _parseHexColor(json['color'] as String? ?? '#0B7285'),
      CashDetailFilter.pending,
      procedure: json['procedure'] as String? ?? '',
      price: json['price'] as String? ?? '',
      procedurePrice: json['procedurePrice'] as String? ?? '',
      serviceFee: json['serviceFee'] as String? ?? '',
      doctor: json['doctor'] as String? ?? '',
      dentition: json['dentition'] as String? ?? '',
      tooth: json['tooth'] as String? ?? '',
      clinicalNote: json['clinicalNote'] as String? ?? '',
      serviceChargeItems:
          (json['serviceChargeItems'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(ServiceChargeItem.fromJson)
              .toList(),
      procedureItems: (json['procedureItems'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ProcedureInvoiceItem.fromJson)
          .toList(),
      pharmacyItems: (json['pharmacyItems'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(PharmacyInvoiceItem.fromJson)
          .toList(),
    );
  }

  Map<String, Object> toProjectHistoryJson() {
    return {
      'patient': patient,
      'number': number,
      'method': method,
      'status': status,
      'amount': amount,
      'procedure': procedure,
      'price': price,
      'procedurePrice': procedurePrice,
      'serviceFee': serviceFee,
      'doctor': doctor,
      'dentition': dentition,
      'tooth': tooth,
      'clinicalNote': clinicalNote,
      'serviceChargeItems': [
        for (final item in serviceChargeItems) item.toJson(),
      ],
      'procedureItems': [for (final item in procedureItems) item.toJson()],
      'pharmacyItems': [for (final item in pharmacyItems) item.toJson()],
      'color': _colorToHex(color),
    };
  }
}

class ServiceChargeItem {
  const ServiceChargeItem(this.name, this.price);

  final String name;
  final String price;

  factory ServiceChargeItem.fromJson(Map<String, dynamic> json) {
    return ServiceChargeItem(
      json['name'] as String? ?? '',
      json['price'] as String? ?? '',
    );
  }

  Map<String, Object> toJson() {
    return {'name': name, 'price': price};
  }
}

class ProcedureInvoiceItem {
  const ProcedureInvoiceItem(this.name, this.teeth, this.price);

  final String name;
  final String teeth;
  final String price;

  factory ProcedureInvoiceItem.fromJson(Map<String, dynamic> json) {
    return ProcedureInvoiceItem(
      json['name'] as String? ?? '',
      json['teeth'] as String? ?? '',
      json['price'] as String? ?? '',
    );
  }

  Map<String, Object> toJson() {
    return {'name': name, 'teeth': teeth, 'price': price};
  }
}

class PharmacyInvoiceItem {
  const PharmacyInvoiceItem(this.name, this.quantity, this.price);

  final String name;
  final int quantity;
  final String price;

  factory PharmacyInvoiceItem.fromJson(Map<String, dynamic> json) {
    return PharmacyInvoiceItem(
      json['name'] as String? ?? '',
      json['quantity'] as int? ?? 1,
      json['price'] as String? ?? '',
    );
  }

  Map<String, Object> toJson() {
    return {'name': name, 'quantity': quantity, 'price': price};
  }
}

class PatientBillingInfo {
  const PatientBillingInfo(this.procedure, this.price, this.doctor);

  final String procedure;
  final String price;
  final String doctor;
}

PatientBillingInfo? billingForPatient(String patientName) {
  final appointment = sampleAppointmentStatusDetails
      .where((detail) => detail.patient == patientName)
      .firstOrNull;
  if (appointment == null) {
    return null;
  }

  final procedureName = appointment.procedure;

  final procedure = sampleDashboardProcedures
      .where(
        (item) =>
            item.name.toLowerCase() == procedureName.toLowerCase() ||
            procedureName.toLowerCase().contains(item.name.toLowerCase()) ||
            item.name.toLowerCase().contains(procedureName.toLowerCase()),
      )
      .firstOrNull;

  return PatientBillingInfo(
    procedureName,
    procedure?.price ?? priceForProcedureName(procedureName),
    appointment.doctor,
  );
}

String priceForProcedureName(String procedureName) {
  final normalized = procedureName.toLowerCase();
  if (normalized.contains('scaling') || normalized.contains('hygiene')) {
    return 'RM 280';
  }
  if (normalized.contains('root canal')) {
    return 'RM 1,850';
  }
  if (normalized.contains('implant')) {
    return 'RM 4,180';
  }
  if (normalized.contains('extraction') || normalized.contains('wisdom')) {
    return 'RM 600';
  }
  if (normalized.contains('braces') || normalized.contains('aligner')) {
    return 'RM 2,400';
  }
  if (normalized.contains('filling')) {
    return 'RM 760';
  }
  if (normalized.contains('crown')) {
    return 'RM 3,020';
  }
  if (normalized.contains('whitening')) {
    return 'RM 930';
  }
  return '';
}

class FollowUp {
  const FollowUp(
    this.patient,
    this.phone,
    this.doctor,
    this.reason,
    this.due,
    this.channel,
    this.priority,
    this.color,
  );

  final String patient;
  final String phone;
  final String doctor;
  final String reason;
  final String due;
  final String channel;
  final String priority;
  final Color color;
}

class PharmacyDispense {
  const PharmacyDispense(
    this.patient,
    this.medicine,
    this.dose,
    this.status,
    this.color,
  );

  final String patient;
  final String medicine;
  final String dose;
  final String status;
  final Color color;
}

class PharmacyPayment {
  const PharmacyPayment(
    this.patient,
    this.invoiceNumber,
    this.method,
    this.status,
    this.amount,
    this.color,
  );

  final String patient;
  final String invoiceNumber;
  final String method;
  final String status;
  final String amount;
  final Color color;
}

class PriceNature {
  const PriceNature(this.name, this.quantity, this.unit, this.price);

  final String name;
  final int quantity;
  final String unit;
  final String price;

  String get label => '$name: $quantity $unit';
}

class Medicine {
  const Medicine(
    this.name,
    this.category,
    this.stock,
    this.capacity,
    this.unit,
    this.batch,
    this.expiry,
    this.status,
    this.color, {
    this.price = '',
    this.productClass = '',
    this.productFeature = '',
    this.productOption = '',
    this.chemicalName = '',
    this.tag = '',
    this.priceNature,
    this.priceNatures = const [],
    this.discountMode = ProcedureDiscountMode.none,
    this.discountValue = '',
    this.description = '',
    this.imageUrls = const [],
  });

  final String name;
  final String category;
  final int stock;
  final int capacity;
  final String unit;
  final String batch;
  final String expiry;
  final String status;
  final Color color;
  final String price;
  final String productClass;
  final String productFeature;
  final String productOption;
  final String chemicalName;
  final String tag;
  final PriceNature? priceNature;
  final List<PriceNature> priceNatures;
  final ProcedureDiscountMode discountMode;
  final String discountValue;
  final String description;
  final List<String> imageUrls;

  String get productPath {
    return [
      if (productClass.isNotEmpty) productClass,
      if (productFeature.isNotEmpty) productFeature,
      if (productOption.isNotEmpty) productOption,
    ].join(' / ');
  }

  bool get hasPrice => price.isNotEmpty;

  bool get hasDiscount =>
      discountMode != ProcedureDiscountMode.none && discountValue.isNotEmpty;

  double get netPriceValue {
    final basePrice = _currencyValue(price);
    final discountAmount = _currencyValue(discountValue);
    if (!hasDiscount) {
      return basePrice;
    }
    return switch (discountMode) {
      ProcedureDiscountMode.percent =>
        basePrice * (1 - discountAmount.clamp(0, 100) / 100),
      ProcedureDiscountMode.netPrice => discountAmount,
      ProcedureDiscountMode.none => basePrice,
    };
  }

  String get netPrice => _formatCurrencyValue(netPriceValue);

  String get discountLabel {
    if (!hasDiscount) {
      return '';
    }
    return switch (discountMode) {
      ProcedureDiscountMode.percent => '$discountValue% discount',
      ProcedureDiscountMode.netPrice => 'Net price $netPrice',
      ProcedureDiscountMode.none => '',
    };
  }
}

class NestedProductClass {
  const NestedProductClass(
    this.name,
    this.description,
    this.icon,
    this.color,
    this.features,
  );

  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<NestedProductFeature> features;
}

class NestedProductFeature {
  const NestedProductFeature(this.name, this.options);

  final String name;
  final List<NestedProductOption> options;
}

class NestedProductOption {
  const NestedProductOption(
    this.name,
    this.price,
    this.stock,
    this.unit,
    this.batch,
    this.expiry,
    this.status,
  );

  final String name;
  final String price;
  final int stock;
  final String unit;
  final String batch;
  final String expiry;
  final String status;
}

class DentalProcedure {
  const DentalProcedure(
    this.name,
    this.stage,
    this.doctor,
    this.progress,
    this.icon,
    this.color,
    this.price,
    this.estimate,
    this.category,
    this.subcategory,
    this.childCategory, {
    this.discountMode = ProcedureDiscountMode.none,
    this.discountValue = '',
    this.procedureCategory = '',
    this.tag = '',
  });

  final String name;
  final String stage;
  final String doctor;
  final double progress;
  final IconData icon;
  final Color color;
  final String price;
  final String estimate;
  final String category;
  final String subcategory;
  final String childCategory;
  final ProcedureDiscountMode discountMode;
  final String discountValue;
  final String procedureCategory;
  final String tag;

  String get categoryPath {
    return [
      if (category.isNotEmpty) category,
      if (subcategory.isNotEmpty) subcategory,
      if (childCategory.isNotEmpty) childCategory,
    ].join(' / ');
  }

  bool get hasDiscount =>
      discountMode != ProcedureDiscountMode.none && discountValue.isNotEmpty;

  double get netPriceValue {
    final basePrice = _currencyValue(price);
    final discountAmount = _currencyValue(discountValue);
    if (!hasDiscount) {
      return basePrice;
    }
    return switch (discountMode) {
      ProcedureDiscountMode.percent =>
        basePrice * (1 - discountAmount.clamp(0, 100) / 100),
      ProcedureDiscountMode.netPrice => discountAmount,
      ProcedureDiscountMode.none => basePrice,
    };
  }

  String get netPrice => _formatCurrencyValue(netPriceValue);

  String get discountLabel {
    if (!hasDiscount) {
      return '';
    }
    return switch (discountMode) {
      ProcedureDiscountMode.percent => '$discountValue% discount',
      ProcedureDiscountMode.netPrice => 'Net price $netPrice',
      ProcedureDiscountMode.none => '',
    };
  }
}

enum ProcedureDiscountMode {
  none('No discount'),
  percent('Percent %'),
  netPrice('Net Price');

  const ProcedureDiscountMode(this.label);

  final String label;
}

class NestedDoctorFeeClass {
  const NestedDoctorFeeClass(
    this.name,
    this.description,
    this.icon,
    this.color,
    this.features,
  );

  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<NestedDoctorFeeFeature> features;
}

class NestedDoctorFeeFeature {
  const NestedDoctorFeeFeature(this.name, this.options);

  final String name;
  final List<DoctorFeeOption> options;
}

class DoctorFeeOption {
  const DoctorFeeOption(this.name, this.price, this.note);

  final String name;
  final String price;
  final String note;

  String get displayLabel => '$name - $price';
}

class NestedProcedureClass {
  const NestedProcedureClass(
    this.name,
    this.description,
    this.icon,
    this.color,
    this.features,
  );

  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final List<NestedProcedureFeature> features;
}

class NestedProcedureFeature {
  const NestedProcedureFeature(this.name, this.values);

  final String name;
  final List<NestedProcedureValue> values;
}

class NestedProcedureValue {
  const NestedProcedureValue(
    this.name,
    this.price,
    this.estimate,
    this.stage,
    this.doctor,
    this.progress,
  );

  final String name;
  final String price;
  final String estimate;
  final String stage;
  final String doctor;
  final double progress;
}

class ClinicProject {
  const ClinicProject(
    this.projectId,
    this.name,
    this.owner,
    this.deadline,
    this.procedure,
    this.dentition,
    this.tooth,
    this.clinicalNote,
    this.followUpReason,
    this.followUpDue,
    this.followUpChannel,
    this.followUpPriority,
    this.progress,
    this.color,
  );

  final String projectId;
  final String name;
  final String owner;
  final String deadline;
  final String procedure;
  final String dentition;
  final String tooth;
  final String clinicalNote;
  final String followUpReason;
  final String followUpDue;
  final String followUpChannel;
  final String followUpPriority;
  final double progress;
  final Color color;

  factory ClinicProject.fromJson(Map<String, dynamic> json) {
    return ClinicProject(
      json['projectId'] as String? ?? json['id'] as String? ?? 'PRJ-UNKNOWN',
      json['name'] as String? ?? 'Untitled project',
      json['owner'] as String? ?? 'Unassigned',
      json['deadline'] as String? ?? 'TBD',
      json['procedure'] as String? ?? 'General dentistry',
      json['dentition'] as String? ?? 'Adult',
      json['tooth'] as String? ?? 'Tooth 11',
      json['clinicalNote'] as String? ?? '',
      json['followUpReason'] as String? ?? '',
      json['followUpDue'] as String? ?? '',
      json['followUpChannel'] as String? ?? '',
      json['followUpPriority'] as String? ?? '',
      (json['progress'] as num?)?.toDouble() ?? 0,
      _parseHexColor(json['color'] as String? ?? '#0B7285'),
    );
  }
}

String generatedProjectId() {
  final now = DateTime.now();
  final date =
      '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
  final tick = now.millisecondsSinceEpoch
      .remainder(1000)
      .toString()
      .padLeft(3, '0');
  return 'PRJ-$date-$tick';
}

ClinicProject projectFromProcedure(DentalProcedure procedure) {
  return ClinicProject(
    generatedProjectId(),
    '${procedure.name} treatment project',
    procedure.doctor.isEmpty ? 'Treatment coordinator' : procedure.doctor,
    'Next visit',
    procedure.name,
    'Adult',
    'Tooth 11',
    '',
    '',
    '',
    '',
    '',
    0,
    procedure.color,
  );
}

List<ClinicProject> projectsFromInvoice(Invoice invoice) {
  final rows = <({String procedure, String dentition, String tooth})>[];

  if (invoice.procedure.trim().isNotEmpty) {
    rows.add((
      procedure: invoice.procedure.trim(),
      dentition: _projectDentition(invoice.dentition, invoice.tooth),
      tooth: _projectTooth(invoice.tooth),
    ));
  }

  for (final item in invoice.procedureItems) {
    rows.add((
      procedure: item.name,
      dentition: _projectDentition('', item.teeth),
      tooth: _projectTooth(item.teeth),
    ));
  }

  if (rows.isEmpty) {
    rows.add((
      procedure: 'Cashier invoice',
      dentition: invoice.dentition.isEmpty ? 'Adult' : invoice.dentition,
      tooth: invoice.tooth.isEmpty ? '-' : invoice.tooth,
    ));
  }

  return [
    for (var index = 0; index < rows.length; index++)
      ClinicProject(
        '${invoice.number}-P${(index + 1).toString().padLeft(2, '0')}',
        invoice.patient,
        invoice.doctor.isEmpty ? 'Cashier' : invoice.doctor,
        'Invoice ${invoice.number}',
        rows[index].procedure,
        rows[index].dentition,
        rows[index].tooth,
        invoice.clinicalNote,
        '',
        '',
        '',
        '',
        1,
        invoice.color,
      ),
  ];
}

String _projectDentition(String dentition, String tooth) {
  if (dentition.isNotEmpty) {
    return dentition;
  }
  if (tooth.startsWith('Child ')) {
    return 'Child';
  }
  return 'Adult';
}

String _projectTooth(String tooth) {
  return tooth
      .replaceFirst(RegExp(r'^Adult\s+'), '')
      .replaceFirst(RegExp(r'^Child\s+'), '')
      .trim();
}

class ProjectDraft {
  const ProjectDraft({
    required this.projectId,
    required this.name,
    required this.owner,
    required this.deadline,
    required this.procedure,
    required this.dentition,
    required this.tooth,
    required this.priority,
    required this.clinicalNote,
    required this.followUpReason,
    required this.followUpDue,
    required this.followUpChannel,
    required this.followUpPriority,
    required this.summary,
  });

  final String projectId;
  final String name;
  final String owner;
  final String deadline;
  final String procedure;
  final String dentition;
  final String tooth;
  final String priority;
  final String clinicalNote;
  final String followUpReason;
  final String followUpDue;
  final String followUpChannel;
  final String followUpPriority;
  final String summary;

  Map<String, Object> toJson() {
    return {
      'projectId': projectId,
      'name': name,
      'owner': owner,
      'deadline': deadline,
      'procedure': procedure,
      'dentition': dentition,
      'tooth': tooth,
      'priority': priority,
      'clinicalNote': clinicalNote,
      'followUpReason': followUpReason,
      'followUpDue': followUpDue,
      'followUpChannel': followUpChannel,
      'followUpPriority': followUpPriority,
      'summary': summary,
      'progress': 0,
      'color': switch (priority) {
        'High' => '#C2410C',
        'Low' => '#166534',
        _ => '#0B7285',
      },
    };
  }
}

Color _parseHexColor(String value) {
  final normalized = value.replaceFirst('#', '');
  final parsed = int.tryParse('FF$normalized', radix: 16);
  return Color(parsed ?? 0xFF0B7285);
}

String _colorToHex(Color color) {
  final value = color.toARGB32() & 0xFFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}

const sampleUsers = [
  ClinicUser(
    'Aina Rahman',
    'User',
    'Active',
    'AR',
    Color(0xFF0B7285),
    '32',
    '+60 12-555 0101',
    '22 Jalan Ampang',
  ),
  ClinicUser(
    'Dr. Marcus Lee',
    'Doctor',
    'In clinic',
    'ML',
    Color(0xFF7C3AED),
    '41',
    '+60 12-555 0102',
    'Room 2A',
  ),
  ClinicUser(
    'Siti Noor',
    'Cashier',
    'Front desk',
    'SN',
    Color(0xFF166534),
    '28',
    '+60 12-555 0103',
    'Front counter',
  ),
  ClinicUser(
    'Dr. Priya Menon',
    'Doctor',
    'Surgery',
    'PM',
    Color(0xFFC2410C),
    '39',
    '+60 12-555 0104',
    'Room 3B',
  ),
  ClinicUser(
    'Ben Tan',
    'User',
    'New patient',
    'BT',
    Color(0xFF2563EB),
    '25',
    '+60 12-555 0105',
    '7 Jalan Sentral',
  ),
  ClinicUser(
    'Farah Lim',
    'Cashier',
    'Insurance',
    'FL',
    Color(0xFF9333EA),
    '34',
    '+60 12-555 0106',
    'Finance desk',
  ),
  ClinicUser(
    'Clinic Admin',
    'Admin',
    'Operations',
    'CA',
    Color(0xFFC2410C),
    '36',
    '+60 12-555 0107',
    'Admin office',
  ),
  ClinicUser(
    'Owner Account',
    'Owner',
    'Full access',
    'OA',
    Color(0xFF2563EB),
    '45',
    '+60 12-555 0108',
    'Owner suite',
  ),
];

const sampleDoctors = [
  Doctor(
    'Dr. Marcus Lee',
    'Orthodontics',
    'Available',
    '2A',
    9,
    0.78,
    Color(0xFF0B7285),
  ),
  Doctor(
    'Dr. Priya Menon',
    'Oral surgery',
    'In procedure',
    '3B',
    6,
    0.88,
    Color(0xFFC2410C),
  ),
  Doctor(
    'Dr. Hannah Wong',
    'Paediatric dentistry',
    'Reviewing',
    '1C',
    8,
    0.63,
    Color(0xFF7C3AED),
  ),
  Doctor(
    'Dr. Amir Zain',
    'Implantology',
    'Available',
    '4A',
    4,
    0.52,
    Color(0xFF166534),
  ),
];

const sampleAppointments = [
  Appointment(
    'Aina Rahman',
    '+60 12-410 8801',
    '09:00',
    'Scaling and polish',
    'Dr. Wong',
    Color(0xFF0B7285),
  ),
  Appointment(
    'Ben Tan',
    '+60 12-550 7712',
    '10:15',
    'Root canal review',
    'Dr. Lee',
    Color(0xFF7C3AED),
  ),
  Appointment(
    'Mei Chen',
    '+60 13-802 4410',
    '11:30',
    'Implant consult',
    'Dr. Amir',
    Color(0xFF166534),
  ),
  Appointment(
    'Ravi Kumar',
    '+60 17-225 0983',
    '14:00',
    'Extraction',
    'Dr. Priya',
    Color(0xFFC2410C),
  ),
];

const sampleAppointmentStatusDetails = [
  AppointmentStatusDetail(
    AppointmentStatusFilter.waiting,
    'B-108',
    'Nadia Hassan',
    '+60 12-340 1120',
    '09:35',
    'Hygiene check',
    'Dr. Wong',
    'Checked in at reception',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.waiting,
    'B-109',
    'Liew Wei',
    '+60 16-772 4418',
    '09:45',
    'Filling review',
    'Dr. Lee',
    'Waiting for X-ray room',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.waiting,
    'B-110',
    'Sofia Ismail',
    '+60 13-889 2014',
    '10:00',
    'Braces adjustment',
    'Dr. Amir',
    'Consent form pending',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.waiting,
    'B-111',
    'Daniel Ong',
    '+60 19-230 5571',
    '10:10',
    'Night guard fitting',
    'Dr. Priya',
    'Waiting for lab tray',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.waiting,
    'B-112',
    'Amira Yusof',
    '+60 18-611 2044',
    '10:20',
    'Pediatric recall',
    'Dr. Wong',
    'Guardian completing form',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.waiting,
    'B-113',
    'Kevin Lim',
    '+60 11-245 7803',
    '10:30',
    'Toothache triage',
    'Dr. Lee',
    'Pain score recorded',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.waiting,
    'B-114',
    'Priya Das',
    '+60 12-990 3316',
    '10:40',
    'Retainer check',
    'Dr. Amir',
    'Waiting for chair assignment',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.waiting,
    'B-115',
    'Omar Hakim',
    '+60 17-678 1209',
    '10:50',
    'Emergency consult',
    'Dr. Priya',
    'Nurse pre-check complete',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.inChair,
    'B-103',
    'Aina Rahman',
    '+60 12-410 8801',
    '09:00',
    'Scaling and polish',
    'Dr. Wong',
    'Chair 1, polishing',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.inChair,
    'B-104',
    'Ben Tan',
    '+60 12-550 7712',
    '10:15',
    'Root canal review',
    'Dr. Lee',
    'Chair 2, clinical review',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.inChair,
    'B-105',
    'Mei Chen',
    '+60 13-802 4410',
    '11:30',
    'Implant consult',
    'Dr. Amir',
    'Chair 4, CBCT notes',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.inChair,
    'B-106',
    'Sara Wong',
    '+60 12-334 8787',
    '11:45',
    'Aligner fitting',
    'Dr. Lee',
    'Chair 3, attachments check',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.inChair,
    'B-107',
    'Nur Iman',
    '+60 13-445 7200',
    '12:00',
    'Fluoride treatment',
    'Dr. Wong',
    'Chair 1, treatment started',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.inChair,
    'B-116',
    'Jason Teo',
    '+60 16-443 1188',
    '12:15',
    'Composite filling',
    'Dr. Priya',
    'Chair 5, anesthesia active',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.inChair,
    'B-117',
    'Leena Krishnan',
    '+60 11-870 9921',
    '12:30',
    'Crown impression',
    'Dr. Amir',
    'Chair 2, impression tray',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.inChair,
    'B-118',
    'Marcus Ho',
    '+60 12-715 8802',
    '12:45',
    'Root canal prep',
    'Dr. Lee',
    'Chair 6, rubber dam placed',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.inChair,
    'B-119',
    'Carmen Low',
    '+60 18-335 9106',
    '13:00',
    'Bridge review',
    'Dr. Amir',
    'Chair 4, bite check',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.completed,
    'B-096',
    'Ravi Kumar',
    '+60 17-225 0983',
    '08:20',
    'Extraction review',
    'Dr. Priya',
    'Discharge advice given',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.completed,
    'B-097',
    'Farah Lim',
    '+60 18-420 3321',
    '08:40',
    'Crown fitting',
    'Dr. Lee',
    'Invoice ready',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.completed,
    'B-098',
    'Arun Patel',
    '+60 11-907 6504',
    '08:55',
    'Pain review',
    'Dr. Wong',
    'Medication dispensed',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.completed,
    'B-099',
    'Chong Mei Lin',
    '+60 12-408 1204',
    '09:05',
    'Routine exam',
    'Dr. Amir',
    'Six-month recall booked',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.completed,
    'B-100',
    'Hafiz Rahman',
    '+60 17-604 8821',
    '09:20',
    'Scaling',
    'Dr. Wong',
    'Paid at cashier',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.completed,
    'B-101',
    'Elaine Goh',
    '+60 19-445 6018',
    '09:40',
    'Whitening review',
    'Dr. Lee',
    'Before-after photos saved',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.completed,
    'B-102',
    'Nur Iman',
    '+60 13-445 7200',
    '10:05',
    'Pediatric check',
    'Dr. Wong',
    'Parent advice completed',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.completed,
    'B-083',
    'Lim Zhi Kai',
    '+60 12-671 2230',
    '07:30',
    'Denture adjustment',
    'Dr. Amir',
    'Comfort check passed',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.completed,
    'B-084',
    'Asha Menon',
    '+60 13-908 7781',
    '07:40',
    'Molar filling',
    'Dr. Priya',
    'Composite shade recorded',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.completed,
    'B-085',
    'Tan Kok Wei',
    '+60 16-441 2209',
    '07:55',
    'Crown cementation',
    'Dr. Lee',
    'Occlusion adjusted',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.completed,
    'B-086',
    'Mariam Binti Ali',
    '+60 17-820 4412',
    '08:05',
    'Gum assessment',
    'Dr. Wong',
    'Periodontal chart updated',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.completed,
    'B-087',
    'Jonathan Ng',
    '+60 11-604 3390',
    '08:10',
    'Implant review',
    'Dr. Amir',
    'Healing cap stable',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.completed,
    'B-088',
    'Yasmin Rahim',
    '+60 18-904 2108',
    '08:15',
    'Emergency dressing',
    'Dr. Priya',
    'Temporary filling placed',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.completed,
    'B-089',
    'Gopal Singh',
    '+60 12-703 5488',
    '08:25',
    'Oral surgery review',
    'Dr. Priya',
    'Sutures clean',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.completed,
    'B-090',
    'Emily Tan',
    '+60 19-440 3098',
    '08:30',
    'Retainer scan',
    'Dr. Lee',
    'Digital scan uploaded',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.completed,
    'B-091',
    'Mohd Azlan',
    '+60 13-775 6640',
    '08:35',
    'Fissure sealant',
    'Dr. Wong',
    'Preventive advice given',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.completed,
    'B-092',
    'Rachel Foo',
    '+60 16-201 7788',
    '08:45',
    'Root canal dressing',
    'Dr. Lee',
    'Next visit scheduled',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.completed,
    'B-093',
    'Ibrahim Salleh',
    '+60 11-320 9901',
    '08:50',
    'Extraction follow-up',
    'Dr. Priya',
    'Bleeding controlled',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.completed,
    'B-094',
    'Grace Chua',
    '+60 12-776 0145',
    '09:00',
    'Whitening tray issue',
    'Dr. Wong',
    'Tray trimmed',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.completed,
    'B-095',
    'Dev Kumar',
    '+60 17-501 2294',
    '09:10',
    'Scaling review',
    'Dr. Amir',
    'Recall reminder set',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.completed,
    'B-120',
    'Zara Ismail',
    '+60 18-330 1102',
    '13:15',
    'Emergency consult',
    'Dr. Priya',
    'Prescription sent to pharmacy',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.booked,
    'B-121',
    'Hana Salleh',
    '+60 12-665 2345',
    '14:30',
    'Whitening consult',
    'Dr. Wong',
    'Deposit paid',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.booked,
    'B-122',
    'Victor Tan',
    '+60 19-771 8455',
    '15:15',
    'Implant follow-up',
    'Dr. Amir',
    'Reminder sent',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.booked,
    'B-123',
    'Maya Chong',
    '+60 16-884 4501',
    '16:00',
    'New patient exam',
    'Dr. Priya',
    'Insurance details requested',
  ),
  AppointmentStatusDetail(
    AppointmentStatusFilter.booked,
    'B-124',
    'Adam Faiz',
    '+60 12-780 3340',
    '16:45',
    'Root canal consult',
    'Dr. Lee',
    'New booking confirmed',
  ),
];

const sampleQueueStatuses = [
  QueueStatus(
    'Check-in',
    'B-103',
    'Aina Rahman',
    'B-104',
    '10:15',
    Icons.how_to_reg_outlined,
    Color(0xFFC2410C),
  ),
  QueueStatus(
    'Pre-check',
    'B-102',
    'Nur Iman',
    'B-103',
    '09:52',
    Icons.fact_check_outlined,
    Color(0xFF0B7285),
  ),
  QueueStatus(
    'Treatment',
    'B-101',
    'Ravi Kumar',
    'B-102',
    '18 min',
    Icons.healing_outlined,
    Color(0xFF7C3AED),
  ),
  QueueStatus(
    'Payment',
    'B-100',
    'Mei Chen',
    'B-101',
    '6 min',
    Icons.receipt_long_outlined,
    Color(0xFF166534),
  ),
];

const sampleBookingSlots = [
  BookingSlot(
    '12:30',
    'Room 1C',
    'Dr. Hannah Wong',
    'Hygiene review',
    'Open',
    Color(0xFF166534),
  ),
  BookingSlot(
    '15:30',
    'Room 2A',
    'Dr. Marcus Lee',
    'Orthodontic consult',
    'Open',
    Color(0xFF0B7285),
  ),
  BookingSlot(
    '16:15',
    'Room 4A',
    'Dr. Amir Zain',
    'Implant consult',
    'Hold',
    Color(0xFFC2410C),
  ),
  BookingSlot(
    '17:00',
    'Room 3B',
    'Dr. Priya Menon',
    'Surgery review',
    'Open',
    Color(0xFF7C3AED),
  ),
];

const sampleInvoices = [
  Invoice(
    'Aina Rahman',
    'INV-1048',
    'Cash',
    'Paid today',
    'RM 280',
    Color(0xFF166534),
    CashDetailFilter.paidToday,
  ),
  Invoice(
    'Ben Tan',
    'INV-1049',
    'Insurance',
    'Insurance check',
    'RM 1,850',
    Color(0xFF7C3AED),
    CashDetailFilter.pending,
  ),
  Invoice(
    'Ravi Kumar',
    'INV-1050',
    'Card',
    'Deposit due',
    'RM 600',
    Color(0xFFC2410C),
    CashDetailFilter.pending,
  ),
  Invoice(
    'Mei Chen',
    'INV-1051',
    'Online',
    'Package balance',
    'RM 4,180',
    Color(0xFF0B7285),
    CashDetailFilter.pending,
  ),
];

const sampleCashDashboardInvoices = [
  Invoice(
    'Nur Iman',
    'INV-1042',
    'Card',
    'Paid today',
    'RM 1,260',
    Color(0xFF166534),
    CashDetailFilter.paidToday,
  ),
  Invoice(
    'Sara Wong',
    'INV-1043',
    'Online',
    'Paid today',
    'RM 2,400',
    Color(0xFF166534),
    CashDetailFilter.paidToday,
  ),
  Invoice(
    'Jason Teo',
    'INV-1044',
    'Cash',
    'Paid today',
    'RM 760',
    Color(0xFF166534),
    CashDetailFilter.paidToday,
  ),
  Invoice(
    'Leena Krishnan',
    'INV-1045',
    'Insurance',
    'Paid today',
    'RM 3,020',
    Color(0xFF166534),
    CashDetailFilter.paidToday,
  ),
  Invoice(
    'Hana Salleh',
    'INV-1046',
    'Bank transfer',
    'Paid today',
    'RM 10,700',
    Color(0xFF166534),
    CashDetailFilter.paidToday,
  ),
  ...sampleInvoices,
  Invoice(
    'Daniel Ong',
    'INV-1027',
    'Card',
    'Reviewed',
    'RM 540',
    Color(0xFF0B7285),
    CashDetailFilter.invoices,
  ),
  Invoice(
    'Amira Yusof',
    'INV-1028',
    'Cash',
    'Reviewed',
    'RM 320',
    Color(0xFF0B7285),
    CashDetailFilter.invoices,
  ),
  Invoice(
    'Kevin Lim',
    'INV-1029',
    'Online',
    'Reviewed',
    'RM 890',
    Color(0xFF0B7285),
    CashDetailFilter.invoices,
  ),
  Invoice(
    'Priya Das',
    'INV-1030',
    'Insurance',
    'Claim filed',
    'RM 1,120',
    Color(0xFF7C3AED),
    CashDetailFilter.invoices,
  ),
  Invoice(
    'Omar Hakim',
    'INV-1031',
    'Cash',
    'Reviewed',
    'RM 680',
    Color(0xFF0B7285),
    CashDetailFilter.invoices,
  ),
  Invoice(
    'Marcus Ho',
    'INV-1032',
    'Card',
    'Reviewed',
    'RM 1,480',
    Color(0xFF0B7285),
    CashDetailFilter.invoices,
  ),
  Invoice(
    'Carmen Low',
    'INV-1033',
    'Bank transfer',
    'Reviewed',
    'RM 2,050',
    Color(0xFF0B7285),
    CashDetailFilter.invoices,
  ),
  Invoice(
    'Lim Zhi Kai',
    'INV-1034',
    'Cash',
    'Reviewed',
    'RM 420',
    Color(0xFF0B7285),
    CashDetailFilter.invoices,
  ),
  Invoice(
    'Asha Menon',
    'INV-1035',
    'Online',
    'Reviewed',
    'RM 760',
    Color(0xFF0B7285),
    CashDetailFilter.invoices,
  ),
  Invoice(
    'Tan Kok Wei',
    'INV-1036',
    'Card',
    'Reviewed',
    'RM 1,960',
    Color(0xFF0B7285),
    CashDetailFilter.invoices,
  ),
  Invoice(
    'Mariam Binti Ali',
    'INV-1037',
    'Insurance',
    'Claim approved',
    'RM 2,340',
    Color(0xFF166534),
    CashDetailFilter.invoices,
  ),
  Invoice(
    'Jonathan Ng',
    'INV-1038',
    'Bank transfer',
    'Reviewed',
    'RM 3,200',
    Color(0xFF0B7285),
    CashDetailFilter.invoices,
  ),
  Invoice(
    'Yasmin Rahim',
    'INV-1039',
    'Cash',
    'Reviewed',
    'RM 380',
    Color(0xFF0B7285),
    CashDetailFilter.invoices,
  ),
  Invoice(
    'Gopal Singh',
    'INV-1040',
    'Card',
    'Reviewed',
    'RM 640',
    Color(0xFF0B7285),
    CashDetailFilter.invoices,
  ),
  Invoice(
    'Emily Tan',
    'INV-1041',
    'Online',
    'Reviewed',
    'RM 930',
    Color(0xFF0B7285),
    CashDetailFilter.invoices,
  ),
];

const sampleFollowUps = [
  FollowUp(
    'Ben Tan',
    '+60 12-550 7712',
    'Dr. Lee',
    'Pain score check after root canal review',
    'Today',
    'Phone call',
    'High',
    Color(0xFFC2410C),
  ),
  FollowUp(
    'Mei Chen',
    '+60 13-802 4410',
    'Dr. Amir',
    'Confirm implant scan appointment and deposit',
    'Tomorrow',
    'WhatsApp',
    'Medium',
    Color(0xFF7C3AED),
  ),
  FollowUp(
    'Aina Rahman',
    '+60 12-410 8801',
    'Dr. Wong',
    'Six month hygiene recall',
    'Fri',
    'SMS',
    'Routine',
    Color(0xFF166534),
  ),
  FollowUp(
    'Ravi Kumar',
    '+60 17-225 0983',
    'Dr. Priya',
    'Post extraction bleeding and medication check',
    'Today',
    'Phone call',
    'High',
    Color(0xFFC2410C),
  ),
  FollowUp(
    'Nadia Hassan',
    '+60 12-340 1120',
    'Dr. Wong',
    'Review sensitivity after hygiene visit',
    'Today',
    'WhatsApp',
    'Medium',
    Color(0xFF0B7285),
  ),
  FollowUp(
    'Liew Wei',
    '+60 16-772 4418',
    'Dr. Lee',
    'Confirm filling bite adjustment',
    'Today',
    'SMS',
    'Routine',
    Color(0xFF166534),
  ),
  FollowUp(
    'Sofia Ismail',
    '+60 13-889 2014',
    'Dr. Amir',
    'Escalate braces wire discomfort',
    'Tomorrow',
    'Phone call',
    'High',
    Color(0xFFC2410C),
  ),
  FollowUp(
    'Daniel Ong',
    '+60 19-230 5571',
    'Dr. Priya',
    'Night guard pressure point check',
    'Thu',
    'WhatsApp',
    'High',
    Color(0xFFC2410C),
  ),
  FollowUp(
    'Amira Yusof',
    '+60 18-611 2044',
    'Dr. Wong',
    'Parent callback for pediatric recall plan',
    'Wed',
    'Phone call',
    'High',
    Color(0xFFC2410C),
  ),
  FollowUp(
    'Kevin Lim',
    '+60 11-245 7803',
    'Dr. Lee',
    'Toothache triage outcome review',
    'Thu',
    'Phone call',
    'High',
    Color(0xFFC2410C),
  ),
  FollowUp(
    'Priya Das',
    '+60 12-990 3316',
    'Dr. Amir',
    'Retainer pickup reminder',
    'Mon',
    'SMS',
    'Routine',
    Color(0xFF166534),
  ),
  FollowUp(
    'Omar Hakim',
    '+60 17-678 1209',
    'Dr. Priya',
    'Emergency consult medication review',
    'Tomorrow',
    'Phone call',
    'Medium',
    Color(0xFF7C3AED),
  ),
  FollowUp(
    'Marcus Ho',
    '+60 12-715 8802',
    'Dr. Lee',
    'Root canal prep consent follow-up',
    'Fri',
    'WhatsApp',
    'Medium',
    Color(0xFF7C3AED),
  ),
  FollowUp(
    'Carmen Low',
    '+60 18-335 9106',
    'Dr. Amir',
    'Bridge review lab shade confirmation',
    'Tue',
    'Email',
    'Routine',
    Color(0xFF166534),
  ),
];

const samplePharmacyDispenses = [
  PharmacyDispense(
    'Aina Rahman',
    'Blumox 500 Capsule',
    '1 capsule, 3 times daily',
    'Ready',
    Color(0xFF166534),
  ),
  PharmacyDispense(
    'Ben Tan',
    'Ibuprofen 400 Tablet',
    'After meal when needed',
    'Preparing',
    Color(0xFF0B7285),
  ),
  PharmacyDispense(
    'Ravi Kumar',
    'Chlorhexidine mouthwash',
    'Rinse twice daily',
    'Waiting doctor',
    Color(0xFFC2410C),
  ),
  PharmacyDispense(
    'Mei Chen',
    'Paracetamol 500mg',
    '2 tablets when needed',
    'Pickup',
    Color(0xFF7C3AED),
  ),
];

const samplePharmacyPayments = [
  PharmacyPayment(
    'Aina Rahman',
    'RX-2048',
    'Cash',
    'Paid',
    'RM 120',
    Color(0xFF166534),
  ),
  PharmacyPayment(
    'Ben Tan',
    'RX-2049',
    'Card',
    'Pending',
    'RM 180',
    Color(0xFFC2410C),
  ),
  PharmacyPayment(
    'Ravi Kumar',
    'RX-2050',
    'Online',
    'Paid',
    'RM 90',
    Color(0xFF0B7285),
  ),
];

const nestedProductDatabase = [
  NestedProductClass(
    'Blumox',
    'Generic antibiotic product class',
    Icons.medication_outlined,
    Color(0xFF166534),
    [
      NestedProductFeature('250', [
        NestedProductOption(
          'Capsule',
          'RM 90',
          64,
          'capsules',
          'AMX-25A',
          'Jan 2028',
          'In stock',
        ),
        NestedProductOption(
          'Syrup',
          'RM 75',
          34,
          'bottles',
          'BLX-25S',
          'Dec 2027',
          'In stock',
        ),
      ]),
      NestedProductFeature('500', [
        NestedProductOption(
          'Capsule',
          'RM 120',
          86,
          'capsules',
          'AMX-24A',
          'Jan 2028',
          'In stock',
        ),
      ]),
    ],
  ),
  NestedProductClass(
    'Ibuprofen',
    'Pain control product class',
    Icons.medication_liquid_outlined,
    Color(0xFFC2410C),
    [
      NestedProductFeature('400', [
        NestedProductOption(
          'Tablet',
          'RM 80',
          24,
          'tablets',
          'IBU-18C',
          'Nov 2027',
          'Low stock',
        ),
      ]),
      NestedProductFeature('200', [
        NestedProductOption(
          'Tablet',
          'RM 45',
          54,
          'tablets',
          'IBU-20T',
          'Jun 2028',
          'In stock',
        ),
      ]),
    ],
  ),
  NestedProductClass(
    'Paracetamol',
    'Analgesic and fever relief class',
    Icons.health_and_safety_outlined,
    Color(0xFF7C3AED),
    [
      NestedProductFeature('500', [
        NestedProductOption(
          'Tablet',
          'RM 40',
          112,
          'tablets',
          'PCM-32F',
          'Mar 2028',
          'In stock',
        ),
      ]),
    ],
  ),
  NestedProductClass(
    'Clinical Supply',
    'Disposable and treatment support items',
    Icons.inventory_2_outlined,
    Color(0xFF0B7285),
    [
      NestedProductFeature('Oral Rinse', [
        NestedProductOption(
          'Chlorhexidine mouthwash',
          'RM 90',
          38,
          'bottles',
          'CHX-77B',
          'Aug 2027',
          'In stock',
        ),
      ]),
      NestedProductFeature('Dressing', [
        NestedProductOption(
          'Gauze sterile pack',
          'RM 35',
          48,
          'packs',
          'GAU-41D',
          'Dec 2029',
          'In stock',
        ),
        NestedProductOption(
          'Lidocaine gel',
          'RM 65',
          14,
          'tubes',
          'LID-09M',
          'May 2027',
          'Low stock',
        ),
      ]),
    ],
  ),
  NestedProductClass(
    'Home Care',
    'Patient take-home dental care',
    Icons.shopping_bag_outlined,
    Color(0xFF7C3AED),
    [
      NestedProductFeature('Hygiene Kit', [
        NestedProductOption(
          'Soft brush kit',
          'RM 45',
          72,
          'sets',
          'SBK-11',
          'Dec 2029',
          'In stock',
        ),
        NestedProductOption(
          'Interdental brush pack',
          'RM 55',
          44,
          'packs',
          'IDB-08',
          'Oct 2028',
          'In stock',
        ),
      ]),
    ],
  ),
];

const sampleMedicines = [
  Medicine(
    'Blumox 500 Capsule',
    'Blumox',
    86,
    120,
    'capsules',
    'AMX-24A',
    'Jan 2028',
    'In stock',
    Color(0xFF166534),
    price: 'RM 120',
    productClass: 'Blumox',
    productFeature: '500',
    productOption: 'Capsule',
    description:
        'Broad-spectrum antibiotic commonly dispensed after dental infection review. Store below 25C and confirm allergy history before dispensing.',
    imageUrls: [
      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1471864190281-a93a3070b6de?auto=format&fit=crop&w=600&q=80',
    ],
  ),
  Medicine(
    'Ibuprofen 400 Tablet',
    'Ibuprofen',
    24,
    100,
    'tablets',
    'IBU-18C',
    'Nov 2027',
    'Low stock',
    Color(0xFFC2410C),
    price: 'RM 80',
    productClass: 'Ibuprofen',
    productFeature: '400',
    productOption: 'Tablet',
    description:
        'Non-steroidal anti-inflammatory used for short-term dental pain control. Review gastric history and dosage instructions before release.',
    imageUrls: [
      'https://images.unsplash.com/photo-1550572017-edd951aa8ca6?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1576671081837-49000212a370?auto=format&fit=crop&w=600&q=80',
    ],
  ),
  Medicine(
    'Chlorhexidine mouthwash',
    'Oral rinse',
    38,
    60,
    'bottles',
    'CHX-77B',
    'Aug 2027',
    'In stock',
    Color(0xFF0B7285),
    price: 'RM 90',
    productClass: 'Clinical Supply',
    productFeature: 'Oral Rinse',
    productOption: 'Chlorhexidine mouthwash',
    description:
        'Antimicrobial oral rinse for post-procedure hygiene support. Advise patient not to swallow and to follow prescribed rinse frequency.',
    imageUrls: [
      'https://images.unsplash.com/photo-1606811971618-4486d14f3f99?auto=format&fit=crop&w=600&q=80',
    ],
  ),
  Medicine(
    'Lidocaine gel',
    'Topical anesthetic',
    14,
    50,
    'tubes',
    'LID-09M',
    'May 2027',
    'Low stock',
    Color(0xFFC2410C),
    price: 'RM 65',
    productClass: 'Clinical Supply',
    productFeature: 'Dressing',
    productOption: 'Lidocaine gel',
    description:
        'Topical anesthetic gel for localized oral comfort during minor clinical handling. Keep capped and record use by batch.',
    imageUrls: [
      'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?auto=format&fit=crop&w=600&q=80',
    ],
  ),
  Medicine(
    'Paracetamol 500mg',
    'Pain control',
    112,
    140,
    'tablets',
    'PCM-32F',
    'Mar 2028',
    'In stock',
    Color(0xFF7C3AED),
    price: 'RM 40',
    productClass: 'Paracetamol',
    productFeature: '500',
    productOption: 'Tablet',
    description:
        'Analgesic and fever relief tablet used for routine dental pain management where NSAIDs are unsuitable.',
    imageUrls: [
      'https://images.unsplash.com/photo-1585435557343-3b092031a831?auto=format&fit=crop&w=600&q=80',
    ],
  ),
  Medicine(
    'Gauze sterile pack',
    'Clinical supply',
    48,
    80,
    'packs',
    'GAU-41D',
    'Dec 2029',
    'In stock',
    Color(0xFF2563EB),
    price: 'RM 35',
    productClass: 'Clinical Supply',
    productFeature: 'Dressing',
    productOption: 'Gauze sterile pack',
    description:
        'Sterile gauze supply for surgical dressing, pressure packs, and chairside procedure support.',
    imageUrls: [
      'https://images.unsplash.com/photo-1583947215259-38e31be8751f?auto=format&fit=crop&w=600&q=80',
    ],
  ),
];

const nestedProcedureDatabase = [
  NestedProcedureClass(
    'Therapeutic',
    'Pain relief and tooth-saving treatment',
    Icons.healing,
    Color(0xFF7C3AED),
    [
      NestedProcedureFeature('Endodontics', [
        NestedProcedureValue(
          'Anterior root canal',
          'RM 1,250',
          '70 min',
          'Access and cleaning',
          'Dr. Lee',
          0.48,
        ),
        NestedProcedureValue(
          'Molar root canal',
          'RM 1,850',
          '90 min',
          'Obturation scheduled',
          'Dr. Lee',
          0.72,
        ),
      ]),
      NestedProcedureFeature('Emergency Care', [
        NestedProcedureValue(
          'Temporary dressing',
          'RM 380',
          '35 min',
          'Pain relief dressing',
          'Dr. Priya',
          0.53,
        ),
      ]),
    ],
  ),
  NestedProcedureClass(
    'Surgical',
    'Extraction and implant procedures',
    Icons.local_hospital,
    Color(0xFFC2410C),
    [
      NestedProcedureFeature('Extraction', [
        NestedProcedureValue(
          'Simple extraction',
          'RM 420',
          '40 min',
          'Extraction planned',
          'Dr. Priya',
          0.44,
        ),
        NestedProcedureValue(
          'Wisdom tooth surgery',
          'RM 600',
          '60 min',
          'Recovery review',
          'Dr. Priya',
          0.84,
        ),
      ]),
      NestedProcedureFeature('Implant', [
        NestedProcedureValue(
          'Single implant consult',
          'RM 980',
          '45 min',
          'CBCT scan pending',
          'Dr. Amir',
          0.38,
        ),
        NestedProcedureValue(
          'Implant placement',
          'RM 4,180',
          '120 min',
          'Surgical placement',
          'Dr. Amir',
          0.46,
        ),
      ]),
    ],
  ),
  NestedProcedureClass(
    'Preventive',
    'Recall, hygiene, pediatric prevention',
    Icons.health_and_safety,
    Color(0xFF0B7285),
    [
      NestedProcedureFeature('Hygiene', [
        NestedProcedureValue(
          'Scaling and polish',
          'RM 280',
          '40 min',
          'Ultrasonic scaling',
          'Dr. Wong',
          0.69,
        ),
      ]),
      NestedProcedureFeature('Pediatric', [
        NestedProcedureValue(
          'Fluoride varnish',
          'RM 180',
          '25 min',
          'Preventive varnish',
          'Dr. Wong',
          0.81,
        ),
        NestedProcedureValue(
          'Space maintainer',
          'RM 2,400',
          '75 min',
          'Aligner fitting',
          'Dr. Lee',
          0.55,
        ),
      ]),
    ],
  ),
  NestedProcedureClass(
    'Restorative',
    'Filling, crown, bridge and repair',
    Icons.architecture,
    Color(0xFF166534),
    [
      NestedProcedureFeature('Filling', [
        NestedProcedureValue(
          'Composite filling',
          'RM 760',
          '50 min',
          'Shade matching',
          'Dr. Priya',
          0.64,
        ),
      ]),
      NestedProcedureFeature('Crown', [
        NestedProcedureValue(
          'Crown impression',
          'RM 3,020',
          '70 min',
          'Impression tray',
          'Dr. Amir',
          0.58,
        ),
      ]),
    ],
  ),
];

const nestedDoctorFeeDatabase = [
  NestedDoctorFeeClass(
    'Consultation Visits',
    'Standard doctor visit fees',
    Icons.medical_information_outlined,
    Color(0xFF0B7285),
    [
      NestedDoctorFeeFeature('General Visit', [
        DoctorFeeOption('First Visit', 'RM 80', 'Initial patient assessment'),
        DoctorFeeOption('Second Visit', 'RM 50', 'Follow-up consultation'),
        DoctorFeeOption('Review Visit', 'RM 40', 'Short progress review'),
      ]),
      NestedDoctorFeeFeature('Emergency Visit', [
        DoctorFeeOption('Emergency Visit', 'RM 120', 'Urgent pain assessment'),
        DoctorFeeOption('After Hours Visit', 'RM 180', 'Extended clinic visit'),
      ]),
    ],
  ),
  NestedDoctorFeeClass(
    'Specialist Visits',
    'Doctor fees by specialist appointment type',
    Icons.person_search_outlined,
    Color(0xFF7C3AED),
    [
      NestedDoctorFeeFeature('Dental Specialist', [
        DoctorFeeOption(
          'Specialist First Visit',
          'RM 150',
          'Specialist case review',
        ),
        DoctorFeeOption(
          'Specialist Follow Up',
          'RM 100',
          'Specialist follow-up',
        ),
      ]),
      NestedDoctorFeeFeature('Surgical Review', [
        DoctorFeeOption(
          'Pre Surgery Review',
          'RM 180',
          'Before procedure review',
        ),
        DoctorFeeOption(
          'Post Surgery Review',
          'RM 90',
          'After procedure review',
        ),
      ]),
    ],
  ),
];

const nestedServiceChargeDatabase = [
  NestedDoctorFeeClass(
    'Clinic Service Charges',
    'Common front-desk and facility service fees',
    Icons.room_service_outlined,
    Color(0xFF166534),
    [
      NestedDoctorFeeFeature('Counter Services', [
        DoctorFeeOption('Registration Service', 'RM 20', 'New visit setup'),
        DoctorFeeOption('Admin Service', 'RM 30', 'Billing and records'),
        DoctorFeeOption('Priority Service', 'RM 50', 'Priority queue support'),
      ]),
      NestedDoctorFeeFeature('Facility Services', [
        DoctorFeeOption(
          'Sterilization Service',
          'RM 25',
          'Instrument handling',
        ),
        DoctorFeeOption('Room Service', 'RM 40', 'Procedure room setup'),
      ]),
    ],
  ),
];

const sampleProcedures = [
  DentalProcedure(
    'Root Canal',
    'Obturation scheduled',
    'Dr. Lee',
    0.72,
    Icons.healing,
    Color(0xFF7C3AED),
    'RM 1,850',
    '90 min',
    'Therapeutic',
    'Endodontics',
    'Root canal',
  ),
  DentalProcedure(
    'Dental Implant',
    'CBCT scan pending',
    'Dr. Amir',
    0.38,
    Icons.biotech,
    Color(0xFF166534),
    'RM 4,180',
    '45 min',
    'Surgical',
    'Implant',
    'Single implant',
  ),
  DentalProcedure(
    'Wisdom Tooth',
    'Recovery review',
    'Dr. Priya',
    0.84,
    Icons.local_hospital,
    Color(0xFFC2410C),
    'RM 600',
    '60 min',
    'Surgical',
    'Extraction',
    'Wisdom tooth',
  ),
  DentalProcedure(
    'Braces Plan',
    'Aligner fitting',
    'Dr. Lee',
    0.55,
    Icons.timeline,
    Color(0xFF0B7285),
    'RM 2,400',
    '75 min',
    'Preventive',
    'Pediatric',
    'Space maintainer',
  ),
];

const sampleDashboardProcedures = [
  ...sampleProcedures,
  DentalProcedure(
    'Composite Filling',
    'In chair - shade matching',
    'Dr. Priya',
    0.64,
    Icons.medical_services,
    Color(0xFF0B7285),
    'RM 760',
    '50 min',
    'Restorative',
    'Filling',
    'Composite',
  ),
  DentalProcedure(
    'Crown Impression',
    'In chair - impression tray',
    'Dr. Amir',
    0.58,
    Icons.architecture,
    Color(0xFF7C3AED),
    'RM 3,020',
    '70 min',
    'Restorative',
    'Crown',
    'Ceramic crown',
  ),
  DentalProcedure(
    'Root Canal Prep',
    'In chair - rubber dam placed',
    'Dr. Lee',
    0.62,
    Icons.healing,
    Color(0xFF7C3AED),
    'RM 1,480',
    '80 min',
    'Therapeutic',
    'Endodontics',
    'Access prep',
  ),
  DentalProcedure(
    'Bridge Review',
    'In chair - bite check',
    'Dr. Amir',
    0.74,
    Icons.compare_arrows,
    Color(0xFF166534),
    'RM 2,050',
    '45 min',
    'Restorative',
    'Bridge',
    'Occlusion',
  ),
  DentalProcedure(
    'Fluoride Treatment',
    'In chair - varnish setting',
    'Dr. Wong',
    0.81,
    Icons.child_care,
    Color(0xFF0B7285),
    'RM 320',
    '30 min',
    'Preventive',
    'Pediatric',
    'Fluoride',
  ),
  DentalProcedure(
    'Dental Cleaning',
    'In chair - ultrasonic scaling',
    'Dr. Wong',
    0.69,
    Icons.cleaning_services,
    Color(0xFF166534),
    'RM 280',
    '40 min',
    'Preventive',
    'Hygiene',
    'Scaling',
  ),
  DentalProcedure(
    'Emergency Dressing',
    'In chair - temporary seal',
    'Dr. Priya',
    0.53,
    Icons.local_hospital,
    Color(0xFFC2410C),
    'RM 380',
    '35 min',
    'Urgent Care',
    'Pain relief',
    'Temporary dressing',
  ),
  DentalProcedure(
    'Whitening Tray',
    'In chair - final fitting',
    'Dr. Wong',
    0.77,
    Icons.auto_awesome,
    Color(0xFF0B7285),
    'RM 930',
    '45 min',
    'Cosmetic',
    'Whitening',
    'Tray fitting',
  ),
  DentalProcedure(
    'Implant Healing Check',
    'Osseointegration review',
    'Dr. Amir',
    0.46,
    Icons.biotech,
    Color(0xFF166534),
    'RM 540',
    '30 min',
    'Surgical',
    'Implant',
    'Healing review',
  ),
  DentalProcedure(
    'Filling Bite Adjustment',
    'Occlusion review',
    'Dr. Lee',
    0.44,
    Icons.tune,
    Color(0xFFC2410C),
    'RM 180',
    '20 min',
    'Restorative',
    'Filling',
    'Bite adjustment',
  ),
  DentalProcedure(
    'Night Guard',
    'Lab fit pending',
    'Dr. Priya',
    0.36,
    Icons.nights_stay,
    Color(0xFF7C3AED),
    'RM 890',
    '35 min',
    'Preventive',
    'Appliance',
    'Night guard',
  ),
  DentalProcedure(
    'Pediatric Recall',
    'Guardian review pending',
    'Dr. Wong',
    0.28,
    Icons.child_friendly,
    Color(0xFF0B7285),
    'RM 220',
    '25 min',
    'Preventive',
    'Pediatric',
    'Recall',
  ),
  DentalProcedure(
    'Retainer Check',
    'Fit review',
    'Dr. Amir',
    0.41,
    Icons.straighten,
    Color(0xFF7C3AED),
    'RM 260',
    '25 min',
    'Orthodontic',
    'Retainer',
    'Fit check',
  ),
  DentalProcedure(
    'Gum Assessment',
    'Periodontal review',
    'Dr. Wong',
    0.39,
    Icons.health_and_safety,
    Color(0xFFC2410C),
    'RM 420',
    '40 min',
    'Periodontal',
    'Assessment',
    'Pocket charting',
  ),
  DentalProcedure(
    'Denture Adjustment',
    'Comfort review',
    'Dr. Amir',
    0.33,
    Icons.sentiment_satisfied_alt,
    Color(0xFF166534),
    'RM 540',
    '30 min',
    'Prosthodontic',
    'Denture',
    'Adjustment',
  ),
  DentalProcedure(
    'Root Canal Dressing',
    'Dressing review',
    'Dr. Lee',
    0.48,
    Icons.healing,
    Color(0xFF7C3AED),
    'RM 640',
    '45 min',
    'Therapeutic',
    'Endodontics',
    'Dressing',
  ),
  DentalProcedure(
    'Sealant Treatment',
    'Scheduled for Room 1C',
    'Dr. Wong',
    0.22,
    Icons.shield_outlined,
    Color(0xFF0B7285),
    'RM 210',
    '25 min',
    'Preventive',
    'Sealant',
    'Fissure sealant',
  ),
  DentalProcedure(
    'Crown Cementation',
    'Scheduled for lab arrival',
    'Dr. Lee',
    0.31,
    Icons.hardware,
    Color(0xFF7C3AED),
    'RM 1,960',
    '50 min',
    'Restorative',
    'Crown',
    'Cementation',
  ),
  DentalProcedure(
    'Oral Surgery Review',
    'Scheduled after radiograph',
    'Dr. Priya',
    0.26,
    Icons.local_hospital,
    Color(0xFFC2410C),
    'RM 640',
    '35 min',
    'Surgical',
    'Review',
    'Post-op',
  ),
  DentalProcedure(
    'New Patient Exam',
    'Scheduled intake',
    'Dr. Priya',
    0.18,
    Icons.assignment_ind,
    Color(0xFF166534),
    'RM 300',
    '45 min',
    'General',
    'Exam',
    'New patient',
  ),
  DentalProcedure(
    'Whitening Consult',
    'Scheduled consultation',
    'Dr. Wong',
    0.16,
    Icons.auto_awesome,
    Color(0xFF0B7285),
    'RM 180',
    '30 min',
    'Cosmetic',
    'Whitening',
    'Consult',
  ),
  DentalProcedure(
    'Implant Follow-up',
    'Scheduled follow-up',
    'Dr. Amir',
    0.24,
    Icons.biotech,
    Color(0xFF166534),
    'RM 520',
    '35 min',
    'Surgical',
    'Implant',
    'Follow-up',
  ),
  DentalProcedure(
    'Emergency Consult',
    'Scheduled urgent slot',
    'Dr. Priya',
    0.12,
    Icons.emergency,
    Color(0xFFC2410C),
    'RM 250',
    '30 min',
    'Urgent Care',
    'Consult',
    'Pain triage',
  ),
];

const sampleProjects = [
  ClinicProject(
    'PRJ-20260612-001',
    'Digital consent rollout',
    'Operations',
    'Jun 12',
    'Root Canal',
    'Adult',
    'Tooth 11',
    'Consent review before treatment',
    'Confirm consent signed',
    'Today',
    'Phone call',
    'High',
    0.68,
    Color(0xFF0B7285),
  ),
  ClinicProject(
    'PRJ-20260604-002',
    'Sterilization audit',
    'Nursing lead',
    'Jun 04',
    'Dental Implant',
    'Adult',
    'Tooth 21',
    'Check sterilization tray logs',
    '',
    '',
    '',
    '',
    0.42,
    Color(0xFFC2410C),
  ),
  ClinicProject(
    'PRJ-20260701-003',
    'Doctor room refresh',
    'Facilities',
    'Jul 01',
    'Wisdom Tooth',
    'Adult',
    'Tooth 28',
    'Room layout affects surgical setup',
    '',
    '',
    '',
    '',
    0.31,
    Color(0xFF7C3AED),
  ),
  ClinicProject(
    'PRJ-20260620-004',
    'Cashier reconciliation upgrade',
    'Finance',
    'Jun 20',
    'Root Canal',
    'Adult',
    'Tooth 16',
    'Confirm outstanding treatment balance',
    'Call patient for balance',
    'Tomorrow',
    'WhatsApp',
    'Medium',
    0.76,
    Color(0xFF166534),
  ),
  ClinicProject(
    'PRJ-20260708-005',
    'Lab case tracking rollout',
    'Treatment coordinator',
    'Jul 08',
    'Dental Implant',
    'Adult',
    'Tooth 24',
    'Lab case pending shade match',
    '',
    '',
    '',
    '',
    0.18,
    Color(0xFF2563EB),
  ),
  ClinicProject(
    'PRJ-20260628-006',
    'Patient recall campaign',
    'Front desk',
    'Jun 28',
    'Braces Plan',
    'Child',
    'Child Tooth 3',
    'Recall family for pediatric review',
    'Book recall appointment',
    'Fri',
    'SMS',
    'Routine',
    0.44,
    Color(0xFF9333EA),
  ),
];
