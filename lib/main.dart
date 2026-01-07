import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

// PAGE IMPORTS
import 'pages/health_page.dart'; // CHANGE 1: Imported HealthPage instead of GymPage
import 'pages/book_page.dart';
import 'pages/finance_page.dart';
import 'pages/schedule_page.dart';
import 'pages/dashboard_page.dart';

void main() async {
  // 1. Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const LifeNotebookApp());
}

// Global Theme Mode Controller
final ValueNotifier<ThemeMode> _themeNotifier = ValueNotifier(ThemeMode.light);

// Global Page Index Controller
final ValueNotifier<int> _pageIndexNotifier = ValueNotifier(2);

// Global Color List
const List<Color> globalPageColors = [
  Colors.deepOrange, // 0: Health (was Gym)
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
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc('test_user') // Hardcoded user for now
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
        return ValueListenableBuilder<int>(
          valueListenable: _pageIndexNotifier,
          builder: (context, int pageIndex, _) {
            final Color activeColor = globalPageColors[pageIndex];

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              title: 'Life Notebook',

              // 1. LIGHT THEME
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: activeColor,
                  primary: activeColor,
                  brightness: Brightness.light,
                ),
                useMaterial3: true,
                scaffoldBackgroundColor: const Color(0xFFF5F5F5),
                appBarTheme: AppBarTheme(
                  backgroundColor: activeColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
              ),

              // 2. DARK THEME
              darkTheme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: activeColor,
                  brightness: Brightness.dark,
                  primary: activeColor,
                  secondary: activeColor,
                  surface: const Color(0xFF1E1E1E),
                ),
                useMaterial3: true,
                scaffoldBackgroundColor: const Color(0xFF121212),

                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFF1E1E1E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                iconTheme: IconThemeData(color: activeColor),
              ),

              themeMode: currentMode,
              home: const HomePage(),
            );
          },
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
  final PageController _pageController = PageController(initialPage: 2);

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

    // Save preference to cloud
    FirebaseFirestore.instance.collection('users').doc('test_user').set({
      'isDarkMode': !isCurrentlyDark,
    }, SetOptions(merge: true));
  }

  // Your actual pages
  static const List<Widget> _pages = <Widget>[
    HealthPage(), // CHANGE 2: Used HealthPage instead of GymPage
    BookPage(), // 1
    DashboardPage(), // 2
    FinancePage(), // 3
    SchedulePage(), // 4
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
                actions: [
                  IconButton(
                    icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                    color: isDark ? activeColor : Colors.white,
                    onPressed: () => _toggleTheme(isDark),
                  ),
                ],
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
                        icon: Icons
                            .favorite_rounded, // You already had this correct!
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
