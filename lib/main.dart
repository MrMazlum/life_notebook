import 'package:flutter/material.dart';

// Ensure these point to your actual file structure
import 'pages/gym_page.dart';
import 'pages/book_page.dart';
import 'pages/finance_page.dart';
import 'pages/schedule_page.dart';
import 'pages/dashboard_page.dart';

void main() {
  runApp(const LifeNotebookApp());
}

// Global Theme Mode Controller
final ValueNotifier<ThemeMode> _themeNotifier = ValueNotifier(ThemeMode.light);

// Global Page Index Controller
final ValueNotifier<int> _pageIndexNotifier = ValueNotifier(2); 

// Global Color List
const List<Color> globalPageColors = [
  Colors.deepOrange, // 0: Gym
  Colors.blue,       // 1: Books
  Colors.teal,       // 2: Home
  Colors.green,      // 3: Finance
  Colors.deepPurple, // 4: Schedule
];

class LifeNotebookApp extends StatelessWidget {
  const LifeNotebookApp({super.key});

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

  // Your actual pages
  static const List<Widget> _pages = <Widget>[
    GymPage(),       // 0
    BookPage(),      // 1
    DashboardPage(), // 2
    FinancePage(),   // 3
    SchedulePage(),  // 4
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
                    // If Dark Mode: Text takes the page color
                    // If Light Mode: Text stays White
                    color: isDark ? activeColor : Colors.white, 
                  )
                ),
                centerTitle: true,
                
                iconTheme: IconThemeData(color: isDark ? activeColor : Colors.white),
                actions: [
                  IconButton(
                    icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                    color: isDark ? activeColor : Colors.white,
                    onPressed: () {
                      _themeNotifier.value = isDark ? ThemeMode.light : ThemeMode.dark;
                    },
                  ),
                ],
              ),
              
              body: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: _pages,
              ),

              // REMOVED THE FLOATING ACTION BUTTON FROM HERE
              // The SchedulePage has its own FAB, and we don't want to block it.

              bottomNavigationBar: BottomAppBar(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                elevation: 20, 
                height: 70,    
                padding: EdgeInsets.zero, 
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                  children: <Widget>[
                    _buildNavButton(icon: Icons.fitness_center_rounded, index: 0, label: 'Gym', activeColor: activeColor, currentIndex: currentIndex),
                    _buildNavButton(icon: Icons.menu_book_rounded, index: 1, label: 'Books', activeColor: activeColor, currentIndex: currentIndex),
                    
                    _buildCenterHomeButton(currentIndex: currentIndex, activeColor: activeColor, isDark: isDark), 

                    _buildNavButton(icon: Icons.account_balance_wallet_rounded, index: 3, label: 'Finance', activeColor: activeColor, currentIndex: currentIndex),
                    _buildNavButton(icon: Icons.calendar_month_rounded, index: 4, label: 'Schedule', activeColor: activeColor, currentIndex: currentIndex),
                  ],
                ),
              ),
            );
          },
        );
      }
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
    required bool isDark
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