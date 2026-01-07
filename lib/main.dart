import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

// PAGE IMPORTS
import 'pages/health_page.dart';
import 'pages/book_page.dart';
import 'pages/finance_page.dart';
import 'pages/schedule_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LifeNotebookApp());
}

// Global Theme Mode Controller
final ValueNotifier<ThemeMode> _themeNotifier = ValueNotifier(ThemeMode.light);

// Global Page Index Controller
final ValueNotifier<int> _pageIndexNotifier = ValueNotifier(2);

// Global Color List
const List<Color> globalPageColors = [
  Colors.deepOrange, // 0: Health
  Colors.blue, // 1: Books
  Colors.teal, // 2: Home
  Colors.green, // 3: Finance
  Colors.deepPurple, // 4: Schedule
];

class LifeNotebookApp extends StatefulWidget {
  const LifeNotebookApp({super.key});

  @override
  State<LifeNotebookApp> createState() => _LifeNotebookAppState();
}

class _LifeNotebookAppState extends State<LifeNotebookApp> {
  @override
  void initState() {
    super.initState();
    _loadUserTheme();
  }

  // --- Load Theme from Firestore ---
  Future<void> _loadUserTheme() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists &&
          doc.data() != null &&
          doc.data()!.containsKey('isDarkMode')) {
        bool isDark = doc.data()!['isDarkMode'];
        _themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
      }
    } catch (e) {
      print("Error loading theme: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (context, ThemeMode currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Life Notebook',

          // 1. LIGHT THEME
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            appBarTheme: const AppBarTheme(
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            // Default popup menu style for light mode
            popupMenuTheme: PopupMenuThemeData(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 10,
            ),
          ),

          // 2. DARK THEME
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: Brightness.dark,
              surface: const Color(0xFF1E1E1E),
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            // Default popup menu style for dark mode
            popupMenuTheme: PopupMenuThemeData(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 10,
            ),
          ),

          themeMode: currentMode,

          // --- AUTH GATE ---
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasData) {
                return const HomePage();
              }
              return const LoginPage();
            },
          ),
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // We declare the controller here but initialize it in initState
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Initialize with the current global index so it doesn't reset to dashboard (2)
    _pageController = PageController(initialPage: _pageIndexNotifier.value);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    _pageIndexNotifier.value = index;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _onPageChanged(int index) {
    _pageIndexNotifier.value = index;
  }

  // --- Save Theme to Firestore ---
  void _toggleTheme(bool isCurrentlyDark) {
    final newMode = isCurrentlyDark ? ThemeMode.light : ThemeMode.dark;
    _themeNotifier.value = newMode;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'isDarkMode': !isCurrentlyDark,
      }, SetOptions(merge: true));
    }
  }

  // --- Sign Out Function ---
  void _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // Your actual pages
  static const List<Widget> _pages = <Widget>[
    HealthPage(),
    BookPage(),
    DashboardPage(),
    FinancePage(),
    SchedulePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (context, ThemeMode currentMode, _) {
        final bool isDark = currentMode == ThemeMode.dark;

        return ValueListenableBuilder<int>(
          valueListenable: _pageIndexNotifier,
          builder: (context, int currentIndex, _) {
            final Color activeColor = globalPageColors[currentIndex];

            return Scaffold(
              appBar: AppBar(
                backgroundColor: isDark ? const Color(0xFF1E1E1E) : activeColor,
                title: Text(
                  'Life Notebook',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDark ? activeColor : Colors.white,
                  ),
                ),
                centerTitle: true,
                iconTheme: IconThemeData(
                  color: isDark ? activeColor : Colors.white,
                ),

                // === NEW STYLED SETTINGS MENU ===
                leading: Theme(
                  // Override specific theme data just for this popup to ensure it matches the cards
                  data: Theme.of(context).copyWith(
                    popupMenuTheme: PopupMenuThemeData(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: isDark
                            ? BorderSide(color: Colors.grey.withOpacity(0.1))
                            : BorderSide.none,
                      ),
                      elevation: 10,
                    ),
                  ),
                  child: PopupMenuButton<String>(
                    icon: const Icon(Icons.settings_rounded),
                    tooltip: 'Settings',
                    offset: const Offset(
                      10,
                      50,
                    ), // Shifts menu slightly for better placement
                    onSelected: (String value) {
                      if (value == 'theme') {
                        _toggleTheme(isDark);
                      } else if (value == 'logout') {
                        _signOut();
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          // 1. Theme Toggle
                          PopupMenuItem<String>(
                            value: 'theme',
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.grey[800]
                                        : Colors.grey[200],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isDark
                                        ? Icons.light_mode_rounded
                                        : Icons.dark_mode_rounded,
                                    color: isDark
                                        ? Colors.yellow
                                        : Colors.grey[800],
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isDark ? 'Light Mode' : 'Dark Mode',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const PopupMenuDivider(),

                          // 2. Log Out
                          PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.logout_rounded,
                                    color: Colors.red,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Log Out',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                  ),
                ),

                actions: [], // Cleared old actions
              ),

              body: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: _pages,
              ),

              bottomNavigationBar: BottomAppBar(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                elevation: 20,
                height: 70,
                padding: EdgeInsets.zero,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: _buildNavButton(
                        icon: Icons.favorite_rounded,
                        index: 0,
                        label: 'Health',
                        activeColor: activeColor,
                        currentIndex: currentIndex,
                      ),
                    ),
                    Expanded(
                      child: _buildNavButton(
                        icon: Icons.menu_book_rounded,
                        index: 1,
                        label: 'Books',
                        activeColor: activeColor,
                        currentIndex: currentIndex,
                      ),
                    ),

                    Expanded(
                      child: Center(
                        child: _buildCenterHomeButton(
                          currentIndex: currentIndex,
                          activeColor: activeColor,
                          isDark: isDark,
                        ),
                      ),
                    ),

                    Expanded(
                      child: _buildNavButton(
                        icon: Icons.account_balance_wallet_rounded,
                        index: 3,
                        label: 'Finance',
                        activeColor: activeColor,
                        currentIndex: currentIndex,
                      ),
                    ),
                    Expanded(
                      child: _buildNavButton(
                        icon: Icons.calendar_month_rounded,
                        index: 4,
                        label: 'Schedule',
                        activeColor: activeColor,
                        currentIndex: currentIndex,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required int index,
    required String label,
    required Color activeColor,
    required int currentIndex,
  }) {
    final bool isSelected = currentIndex == index;
    final Color inactiveColor = Colors.grey;

    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 26,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterHomeButton({
    required int currentIndex,
    required Color activeColor,
    required bool isDark,
  }) {
    final bool isSelected = currentIndex == 2;
    return GestureDetector(
      onTap: () => _onItemTapped(2),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          shape: BoxShape.circle,
          border: isSelected
              ? null
              : Border.all(color: Colors.grey.withOpacity(0.5), width: 2),
        ),
        child: Icon(
          Icons.home_rounded,
          color: isSelected ? Colors.white : Colors.grey,
          size: 30,
        ),
      ),
    );
  }
}
