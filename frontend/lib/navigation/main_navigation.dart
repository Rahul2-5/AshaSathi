import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/constants/app_colors.dart';
import 'package:frontend/localization/app_localizations.dart';
import 'package:frontend/patient/family_model.dart';
import 'package:shimmer/shimmer.dart';

import '../widgets/common/common_widgets.dart';
import '../widgets/custom_bottom_nav_bar.dart';

import '../home/home_page.dart';
import '../app/app_settings_controller.dart';
import '../patient/add_patient_models.dart';
import '../patient/add_patient_page_new.dart';
import '../patient/family_details_page.dart';
import '../phc_dashboard/phc_dashboard_page.dart';
import '../providers/family_provider.dart';
import '../providers/login_provider.dart';
import '../providers/patient_provider.dart';
import '../providers/task_provider.dart';

class MainNavigation extends ConsumerStatefulWidget {
  final int initialIndex;

  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation>
    with TickerProviderStateMixin {
  static const Duration _themeTransitionDuration = Duration(milliseconds: 820);

  int _currentIndex = 0;
  late final PageController _pageController;
  late final AnimationController _drawerContentController;
  late final Animation<double> _drawerFadeAnimation;
  late final Animation<Offset> _drawerSlideAnimation;
  late final AnimationController _themeRevealController;
  Offset? _lastThemeToggleTapPosition;
  Offset _themeRevealCenter = Offset.zero;
  Color _themeRevealColor = Colors.transparent;
  bool _isThemeRevealActive = false;

  late final TextEditingController _familySearchController;
  String _familyQuery = '';
  _FamilyMemberFilter _familyMemberFilter = _FamilyMemberFilter.all;
  _FamilySortBy _familySortBy = _FamilySortBy.newest;

  Future<void> _loadFamiliesWithValidToken() async {
    final token = await ref.read(loginProvider.notifier).getValidToken();
    if (token != null && token.isNotEmpty) {
      // Initialize will check if online/offline and load accordingly
      await ref.read(familyListProvider.notifier).initialize(token);
    }
  }

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3);
    _familySearchController = TextEditingController();
    _pageController = PageController(initialPage: _currentIndex);
    _drawerContentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 300),
    );
    _drawerFadeAnimation = CurvedAnimation(
      parent: _drawerContentController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeOutCubic,
    );
    _drawerSlideAnimation =
        Tween<Offset>(begin: const Offset(-0.08, 0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _drawerContentController,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeOutCubic,
          ),
        );
    _themeRevealController =
        AnimationController(vsync: this, duration: _themeTransitionDuration)
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && mounted) {
              setState(() => _isThemeRevealActive = false);
              _themeRevealController.reset();
            }
          });

    if (_currentIndex == 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadFamiliesWithValidToken();
      });
    }
  }

  @override
  void dispose() {
    _familySearchController.dispose();
    _themeRevealController.dispose();
    _pageController.dispose();
    _drawerContentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeModeNotifier = ref.read(appThemeModeProvider.notifier);
    final l10n = context.l10n;
    const lightScaffoldBg = Color(0xFFF3F4F6);
    const darkScaffoldBg = Color(0xFF0F1419);

    final pages = [
      const HomePage(),
      const AddPatientPageNew(),
      _buildFamilyTab(),
      const PhcDashboardPage(),
    ];

    final scaffold = GradientScaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          _drawerContentController.forward(from: 0);
        } else {
          _drawerContentController.reverse();
        }
      },
      appBar: GlassAppBar(
        centerTitle: true,
        title: _currentIndex == 0
            ? _buildAppBarTitleWithLogout(isDark)
            : _buildAppBarTitle(isDark),
        actions: _currentIndex == 0
          ? [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : const Color(0xFFE9F3F0).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Builder(
                      builder: (buttonContext) {
                        return Listener(
                          onPointerDown: (event) {
                            _lastThemeToggleTapPosition = event.position;
                          },
                          child: IconButton(
                            onPressed: () {
                              final box =
                                  buttonContext.findRenderObject()
                                      as RenderBox?;
                              final center = box != null
                                  ? box.localToGlobal(
                                      box.size.center(Offset.zero),
                                    )
                                  : const Offset(0, 0);
                              final revealCenter =
                                  _lastThemeToggleTapPosition ?? center;
                              setState(() {
                                _themeRevealCenter = revealCenter;
                                _themeRevealColor = isDark
                                    ? darkScaffoldBg
                                    : lightScaffoldBg;
                                _isThemeRevealActive = true;
                              });
                              themeModeNotifier.setThemeMode(
                                isDark ? ThemeMode.light : ThemeMode.dark,
                              );
                              _themeRevealController.forward(from: 0);
                              _lastThemeToggleTapPosition = null;
                            },
                            icon: Icon(
                              isDark
                                  ? Icons.light_mode_rounded
                                  : Icons.dark_mode_rounded,
                              size: 20,
                              color: isDark
                                  ? const Color(0xFFFFD166)
                                  : const Color(0xFF1D2127),
                            ),
                            tooltip: isDark
                                ? l10n.tr('theme.switchToLight')
                                : l10n.tr('theme.switchToDark'),
                            padding: EdgeInsets.zero,
                            splashRadius: 20,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ]
            : null,
      ),
      drawer: _buildDrawer(context),

      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onDestinationSelected: (index) async {
          if (_currentIndex == index) return;
          final token = await ref.read(loginProvider.notifier).getValidToken();
          final patientNotifier = ref.read(patientListProvider.notifier);
          final taskNotifier = ref.read(taskListProvider.notifier);

          await _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );

          if (index == 0 && token != null) {
            patientNotifier.loadPatients(token);
            taskNotifier.loadTasks(token);
          }

          if (index == 2) {
            await _loadFamiliesWithValidToken();
          }
        },
      ),
      child: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          if (!mounted) return;
          setState(() => _currentIndex = index);
        },
        children: pages,
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxRadius = _maxRadiusForCenter(
          _themeRevealCenter,
          Size(constraints.maxWidth, constraints.maxHeight),
        );

        return Stack(
          fit: StackFit.expand,
          alignment: Alignment.topLeft,
          children: [
            scaffold,
            if (_isThemeRevealActive)
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _themeRevealController,
                  child: Container(
                    color: _themeRevealColor.withValues(alpha: 0.72),
                  ),
                  builder: (context, child) {
                    final progress = _themeRevealController.value;
                    final revealProgress = Curves.easeInOutCubic.transform(
                      progress,
                    );
                    final radius = maxRadius * revealProgress;

                    final fadeT = ((progress - 0.35) / 0.65).clamp(0.0, 1.0);
                    final overlayOpacity =
                        0.55 * (1.0 - Curves.easeInOutCubic.transform(fadeT));
                    return Opacity(
                      opacity: overlayOpacity,
                      child: ClipPath(
                        clipper: _InverseCircularRevealClipper(
                          center: _themeRevealCenter,
                          radius: radius,
                        ),
                        child: child,
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  double _maxRadiusForCenter(Offset center, Size size) {
    final distances = <double>[
      (center - const Offset(0, 0)).distance,
      (center - Offset(size.width, 0)).distance,
      (center - Offset(0, size.height)).distance,
      (center - Offset(size.width, size.height)).distance,
    ];
    distances.sort();
    return distances.last;
  }

  String _getPageTitle(BuildContext context) {
    final l10n = context.l10n;
    switch (_currentIndex) {
      case 0:
        return l10n.tr('nav.dashboardTitle');
      case 1:
        return l10n.tr('nav.addPatient');
      case 2:
        return 'Family Details';
      case 3:
        return l10n.tr('nav.phcPortal');
      default:
        return l10n.tr('app.name');
    }
  }

  Widget _buildFamilyTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer(
      builder: (context, ref, _) {
        final familyState = ref.watch(familyListProvider);

        if (familyState.error != null && familyState.families.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GlassContainer(
                padding: const EdgeInsets.all(24),
                borderRadius: BorderRadius.circular(20),
                blur: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 42,
                      color: isDark
                          ? const Color(0xFFF5A3A3)
                          : const Color(0xFFB94A4A),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Unable to load families',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFE6EDF3)
                            : const Color(0xFF1F252B),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      familyState.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFBFCBDA)
                            : const Color(0xFF667384),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: _loadFamiliesWithValidToken,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (familyState.loading && familyState.families.isEmpty) {
          return _buildFamilyLoadingSkeleton(isDark);
        }

        if (familyState.families.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: GlassContainer(
                padding: const EdgeInsets.all(24),
                borderRadius: BorderRadius.circular(20),
                blur: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.groups_rounded,
                      size: 48,
                      color: isDark
                          ? const Color(0xFF9FB2C4)
                          : const Color(0xFF6D7A88),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No family registered yet',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFFE6EDF3)
                            : const Color(0xFF1F252B),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Register a family from Add Patient to view details here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF9FB0C0)
                            : const Color(0xFF667384),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                        );
                      },
                      child: const Text('Go to Add Patient'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _loadFamiliesWithValidToken,
                      child: const Text('Refresh families'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final filteredFamilies = _applyFamilyFilters(familyState.families);

        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            MediaQuery.of(context).padding.top + 20,
            16,
            120,
          ),
          child: Column(
            children: [
              GlassContainer(
                borderRadius: BorderRadius.circular(16),
                blur: 14,
                child: TextField(
                  controller: _familySearchController,
                  onChanged: (value) {
                    if (!mounted) return;
                    setState(() => _familyQuery = value.trim().toLowerCase());
                  },
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFD5E1EB)
                        : const Color(0xFF1D232B),
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by family head or address',
                    hintStyle: TextStyle(
                      color: isDark
                          ? const Color(0xFF8B99A6)
                          : const Color(0xFF98A2AC),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: isDark
                          ? const Color(0xFFA5B3BF)
                          : const Color(0xFF14A7A0).withValues(alpha: 0.7),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    suffixIcon: _familyQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _familySearchController.clear();
                              setState(() => _familyQuery = '');
                            },
                            icon: Icon(
                              Icons.close,
                              color: isDark
                                  ? const Color(0xFFA5B3BF)
                                  : const Color(0xFF98A2AC),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _familyFilterChip('All', _FamilyMemberFilter.all),
                  _familyFilterChip(
                    '1-2 Members',
                    _FamilyMemberFilter.oneToTwo,
                  ),
                  _familyFilterChip(
                    '3-5 Members',
                    _FamilyMemberFilter.threeToFive,
                  ),
                  _familyFilterChip('6+ Members', _FamilyMemberFilter.sixPlus),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Showing ${filteredFamilies.length} of ${familyState.families.length} families',
                      style: TextStyle(
                        color: isDark
                            ? const Color(0xFF9FB0C0)
                            : const Color(0xFF667384),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  PopupMenuButton<_FamilySortBy>(
                    onSelected: (value) {
                      if (!mounted) return;
                      setState(() => _familySortBy = value);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(
                        value: _FamilySortBy.newest,
                        child: Text('Newest'),
                      ),
                      PopupMenuItem(
                        value: _FamilySortBy.oldest,
                        child: Text('Oldest'),
                      ),
                      PopupMenuItem(
                        value: _FamilySortBy.nameAZ,
                        child: Text('Name A-Z'),
                      ),
                    ],
                    child: Row(
                      children: [
                        Text(
                          _familySortLabel(),
                          style: const TextStyle(
                            color: Color(0xFF23A7CB),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down,
                          color: Color(0xFF23A7CB),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              Expanded(
                child: filteredFamilies.isEmpty
                    ? Center(
                        child: Text(
                          'No families match the selected filters.',
                          style: TextStyle(
                            color: isDark
                                ? const Color(0xFF9FB0C0)
                                : const Color(0xFF667384),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredFamilies.length,
                        itemBuilder: (context, index) {
                          final family = filteredFamilies[index];
                          return GlassContainer(
                            margin: const EdgeInsets.only(bottom: 10),
                            borderRadius: BorderRadius.circular(16),
                            blur: 14,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isDark
                                    ? const Color(0xFF2A3642)
                                    : const Color(0xFFE8EEF3),
                                child: Text(
                                  family.headOfFamily.isEmpty
                                      ? '?'
                                      : family.headOfFamily
                                            .substring(0, 1)
                                            .toUpperCase(),
                                ),
                              ),
                              title: Text(
                                family.headOfFamily.isEmpty
                                    ? 'Unnamed Family'
                                    : family.headOfFamily,
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFFE6EDF3)
                                      : const Color(0xFF1F252B),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${family.patients.length} members',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF9FB0C0)
                                      : const Color(0xFF667384),
                                ),
                              ),
                              trailing: SizedBox(
                                width: 72,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(
                                      Icons.chevron_right,
                                      color: isDark
                                          ? const Color(0xFF9FB0C0)
                                          : const Color(0xFF667384),
                                    ),
                                    PopupMenuButton<String>(
                                      icon: Icon(
                                        Icons.more_vert,
                                        color: isDark
                                            ? const Color(0xFF9FB0C0)
                                            : const Color(0xFF667384),
                                      ),
                                      tooltip: 'More actions',
                                      onSelected: (value) async {
                                        if (value == 'view') {
                                          if (!mounted) return;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => FamilyDetailsPage(
                                                familyInfo: _toFamilyInfo(
                                                  family,
                                                ),
                                                members: _toPatientDataModels(
                                                  family,
                                                ),
                                                showBackToDashboardButton:
                                                    false,
                                              ),
                                            ),
                                          );
                                          return;
                                        }

                                        if (value == 'delete') {
                                          final token = ref
                                              .read(loginProvider)
                                              .token;
                                          if (token == null || token.isEmpty) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Session expired. Please login again.',
                                                ),
                                              ),
                                            );
                                            return;
                                          }

                                          final shouldDelete =
                                              await _confirmDeleteFamily(
                                                context,
                                                family,
                                              );
                                          if (!shouldDelete || !context.mounted) {
                                            return;
                                          }

                                          final deleted = await ref
                                              .read(familyListProvider.notifier)
                                              .deleteFamily(
                                                familyId: family.id,
                                                token: token,
                                              );

                                          if (!context.mounted) return;

                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                deleted
                                                    ? 'Family deleted successfully'
                                                    : 'Unable to delete family',
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                      itemBuilder: (_) => const [
                                        PopupMenuItem<String>(
                                          value: 'view',
                                          child: Text('View details'),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Text('Delete family'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FamilyDetailsPage(
                                      familyInfo: _toFamilyInfo(family),
                                      members: _toPatientDataModels(family),
                                      showBackToDashboardButton: false,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFamilyLoadingSkeleton(bool isDark) {
    final baseColor = AppColors.shimmerBase(context);
    final highlightColor = AppColors.shimmerHighlight(context);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1200),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(
                4,
                (index) => Container(
                  width: index == 0 ? 72 : 96,
                  height: 34,
                  decoration: BoxDecoration(
                    color: baseColor,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: 220,
              height: 16,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (_, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 160,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: baseColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 110,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: baseColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _familyFilterChip(String label, _FamilyMemberFilter value) {
    final selected = _familyMemberFilter == value;

    return GlassChip(
      label: label,
      selected: selected,
      onTap: () {
        if (!mounted) return;
        setState(() => _familyMemberFilter = value);
      },
    );
  }

  String _familySortLabel() {
    switch (_familySortBy) {
      case _FamilySortBy.newest:
        return 'Newest';
      case _FamilySortBy.oldest:
        return 'Oldest';
      case _FamilySortBy.nameAZ:
        return 'A-Z';
    }
  }

  List<FamilyRecord> _applyFamilyFilters(List<FamilyRecord> families) {
    final filtered = families.where((family) {
      final head = family.headOfFamily.toLowerCase();
      final address = family.familyAddress.toLowerCase();
      final members = family.patients.length;

      final searchMatch =
          _familyQuery.isEmpty ||
          head.contains(_familyQuery) ||
          address.contains(_familyQuery);

      if (!searchMatch) {
        return false;
      }

      switch (_familyMemberFilter) {
        case _FamilyMemberFilter.all:
          return true;
        case _FamilyMemberFilter.oneToTwo:
          return members >= 1 && members <= 2;
        case _FamilyMemberFilter.threeToFive:
          return members >= 3 && members <= 5;
        case _FamilyMemberFilter.sixPlus:
          return members >= 6;
      }
    }).toList();

    switch (_familySortBy) {
      case _FamilySortBy.newest:
        filtered.sort((a, b) => b.id.compareTo(a.id));
        break;
      case _FamilySortBy.oldest:
        filtered.sort((a, b) => a.id.compareTo(b.id));
        break;
      case _FamilySortBy.nameAZ:
        filtered.sort(
          (a, b) => a.headOfFamily.toLowerCase().compareTo(
            b.headOfFamily.toLowerCase(),
          ),
        );
        break;
    }

    return filtered;
  }

  Future<bool> _confirmDeleteFamily(
    BuildContext context,
    FamilyRecord family,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Family'),
          content: Text(
            'Delete ${family.headOfFamily.isEmpty ? 'this family' : family.headOfFamily} and all members? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  FamilyInfo _toFamilyInfo(FamilyRecord family) {
    return FamilyInfo(
      headOfFamily: family.headOfFamily,
      numberOfMembers: family.numberOfMembers.toString(),
      familyAddress: family.familyAddress,
      sameAddressForAll: false,
    );
  }

  List<PatientDataModel> _toPatientDataModels(FamilyRecord family) {
    return family.patients.asMap().entries.map((entry) {
      final index = entry.key;
      final member = entry.value;

      return PatientDataModel(
        id: (member.id ?? (index + 1)).toString(),
        patientName: member.patientName,
        age: member.age.toString(),
        dateOfBirth: member.dateOfBirth,
        gender: member.gender,
        caste: member.caste,
        address: member.address,
        sameAsFamilyAddress: member.address.trim().isEmpty,
        phoneNumber: member.phoneNumber,
        isPregnant: member.isPregnant,
        monthsOfPregnancy: member.monthsOfPregnancy?.toString() ?? '1',
        expectedDeliveryDate: member.expectedDeliveryDate,
        photoPath: member.photoPath,
        diseases: member.diseases,
        declinedHealthInfo: member.declinedHealthInfo,
        notes: member.notes,
      );
    }).toList();
  }

  Widget _buildAppBarTitle(bool isDark) {
    if (_currentIndex != 0) {
      return Text(
        _getPageTitle(context),
        style: TextStyle(
          color: isDark ? const Color(0xFFDCE6EF) : const Color(0xFF23262B),
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFFDCE6EF) : const Color(0xFF1E2228),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.monitor_heart_outlined,
            size: 18,
            color: isDark ? const Color(0xFF1E2228) : Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          context.l10n.tr('nav.dashboard').toUpperCase(),
          style: TextStyle(
            color: isDark ? const Color(0xFFDCE6EF) : const Color(0xFF1F2329),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildAppBarTitleWithLogout(bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Logout',
          style: IconButton.styleFrom(
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.55),
            shape: const CircleBorder(),
          ),
          icon: Icon(
            Icons.logout_rounded,
            color: isDark ? AppColors.accentCyan : AppColors.teal,
          ),
          onPressed: () async {
            await ref.read(loginProvider.notifier).logout();
            if (!mounted) return;
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          },
        ),
        const SizedBox(width: 8),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFFDCE6EF) : const Color(0xFF1E2228),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.monitor_heart_outlined,
            size: 18,
            color: isDark ? const Color(0xFF1E2228) : Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          context.l10n.tr('nav.dashboard').toUpperCase(),
          style: TextStyle(
            color: isDark ? const Color(0xFFDCE6EF) : const Color(0xFF1F2329),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: 280,
      child: GlassContainer(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        blur: 24,
        child: SlideTransition(
          position: _drawerSlideAnimation,
          child: FadeTransition(
            opacity: _drawerFadeAnimation,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.white.withValues(alpha: 0.05),
                            ]
                          : [
                              const Color(0xFF14A7A0).withValues(alpha: 0.8),
                              const Color(0xFF2ED1B0).withValues(alpha: 0.6),
                            ],
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.health_and_safety_outlined,
                          size: 34,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AshaSathi',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFE6EDF3)
                              : Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Community care dashboard',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    context.l10n.tr('drawer.logout'),
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFE6EDF3)
                          : const Color(0xFF1F252B),
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    await ref.read(loginProvider.notifier).logout();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InverseCircularRevealClipper extends CustomClipper<Path> {
  const _InverseCircularRevealClipper({
    required this.center,
    required this.radius,
  });

  final Offset center;
  final double radius;

  @override
  Path getClip(Size size) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(Rect.fromCircle(center: center, radius: radius));
  }

  @override
  bool shouldReclip(covariant _InverseCircularRevealClipper oldClipper) {
    return oldClipper.center != center || oldClipper.radius != radius;
  }
}

enum _FamilyMemberFilter { all, oneToTwo, threeToFive, sixPlus }

enum _FamilySortBy { newest, oldest, nameAZ }
