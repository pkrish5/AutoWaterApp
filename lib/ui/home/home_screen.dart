import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../dashboard/dashboard_screen.dart';
import '../friends/friends_screen.dart';
import '../profile/profile_screen.dart';
import '../community/community_screen.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final PageController _pageController;

  List<Widget> get _screens => [
  const DashboardScreen(),
  FriendsScreen(onEdgeSwipe: _navigateByDirection),
  CommunityScreen(onEdgeSwipe: _navigateByDirection),
  const ProfileScreen(),
];
  void _navigateByDirection(int direction) {
  final newIndex = (_currentIndex + direction).clamp(0, _screens.length - 1);
  if (newIndex != _currentIndex) {
    _pageController.animateToPage(
      newIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }
}

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        children: _screens,
      ),
      bottomNavigationBar: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) {
          // Calculate which tab based on horizontal position
          final RenderBox box = context.findRenderObject() as RenderBox;
          final localPosition = box.globalToLocal(details.globalPosition);
          final screenWidth = box.size.width;
          final tabWidth = screenWidth / _screens.length;
          final targetIndex = (localPosition.dx / tabWidth).floor().clamp(0, _screens.length - 1);
          
          if (targetIndex != _currentIndex) {
            _pageController.animateToPage(
              targetIndex,
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
            );
          }
        },

      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppTheme.leafGreen.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.eco, 'Garden'),
                _buildNavItem(1, Icons.people, 'Friends'),
                _buildNavItem(2, Icons.groups, 'Community'),
                _buildNavItem(3, Icons.person, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    ),

    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.leafGreen.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppTheme.leafGreen
                  : AppTheme.soilBrown.withValues(alpha: 0.5),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.quicksand(
                fontSize: 12,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? AppTheme.leafGreen
                    : AppTheme.soilBrown.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
