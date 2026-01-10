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
import 'pages/dashboard_page.dart'; // Standard import now
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
  Color(0xFF424242), // 2: Home (Dark Gray)
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

          // LIGHT THEME
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF5F5F5),
            appBarTheme: const AppBarTheme(
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            popupMenuTheme: PopupMenuThemeData(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 10,
            ),
          ),

          // DARK THEME
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF1E1E1E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            popupMenuTheme: PopupMenuThemeData(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 10,
            ),
          ),

          themeMode: currentMode,
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
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _pageIndexNotifier.value);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // This function switches the tab
  void _onItemTapped(int index) {
    _pageIndexNotifier.value = index;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    _pageIndexNotifier.value = index;
  }

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

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  // Helper to build the pages list dynamically so we can pass the function
  List<Widget> _getPages() {
    return [
      const HealthPage(),
      const BookPage(),
      // We pass the function here so the dashboard buttons work!
      DashboardPage(onNavigate: _onItemTapped),
      const FinancePage(),
      const SchedulePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (context, ThemeMode currentMode, _) {
        final bool isDark = currentMode == ThemeMode.dark;

        return ValueListenableBuilder<int>(
          valueListenable: _pageIndexNotifier,
          builder: (context, int currentIndex, _) {
            // Determine active color for center button based on theme
            final Color centerActiveColor = isDark
                ? Colors.grey[600]!
                : const Color(0xFF424242);

            Color appBarColor;
            if (currentIndex == 2) {
              appBarColor = isDark
                  ? const Color(0xFF1E1E1E)
                  : const Color(0xFF424242);
            } else {
              appBarColor = isDark
                  ? const Color(0xFF1E1E1E)
                  : globalPageColors[currentIndex];
            }

            return Scaffold(
              appBar: AppBar(
                backgroundColor: appBarColor,
                title: const Text(
                  'Life Notebook',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                centerTitle: true,
                iconTheme: const IconThemeData(color: Colors.white),
                leading: PopupMenuButton<String>(
                  icon: const Icon(Icons.settings_rounded, color: Colors.white),
                  onSelected: (String value) {
                    if (value == 'theme') _toggleTheme(isDark);
                    if (value == 'logout') _signOut();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'theme',
                      child: Text(isDark ? "Light Mode" : "Dark Mode"),
                    ),
                    const PopupMenuItem(
                      value: 'logout',
                      child: Text(
                        "Log Out",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

              body: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: _getPages(), // Using our helper function
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
                        Icons.favorite_rounded,
                        0,
                        'Health',
                        Colors.deepOrange,
                        currentIndex,
                      ),
                    ),
                    Expanded(
                      child: _buildNavButton(
                        Icons.menu_book_rounded,
                        1,
                        'Books',
                        Colors.blue,
                        currentIndex,
                      ),
                    ),

                    // --- CENTER BUTTON ---
                    Expanded(
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _onItemTapped(2),
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: currentIndex == 2
                                  ? centerActiveColor
                                  : Colors.transparent,
                              shape: BoxShape.circle,
                              border: currentIndex == 2
                                  ? null
                                  : Border.all(
                                      color: Colors.grey.withOpacity(0.5),
                                      width: 2,
                                    ),
                            ),
                            child: Icon(
                              Icons.home_rounded,
                              color: currentIndex == 2
                                  ? Colors.white
                                  : Colors.grey,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),

                    Expanded(
                      child: _buildNavButton(
                        Icons.account_balance_wallet_rounded,
                        3,
                        'Finance',
                        Colors.green,
                        currentIndex,
                      ),
                    ),
                    Expanded(
                      child: _buildNavButton(
                        Icons.calendar_month_rounded,
                        4,
                        'Schedule',
                        Colors.deepPurple,
                        currentIndex,
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

  Widget _buildNavButton(
    IconData icon,
    int index,
    String label,
    Color color,
    int currentIndex,
  ) {
    final bool isSelected = currentIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(50),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: isSelected ? color : Colors.grey, size: 26),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
