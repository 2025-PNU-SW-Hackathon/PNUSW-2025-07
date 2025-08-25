import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'analysis_screen.dart';
import 'garden_screen.dart';
import 'profile_screen.dart';
import 'emotion_record_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final String? nickname;
  final String? email;
  final String accessToken;
  final int initialIndex;
  
  const MainNavigationScreen({
    Key? key, 
    this.nickname, 
    this.email, 
    required this.accessToken,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _selectedIndex;
  late final List<Widget> _screens;
  
  // GlobalKey를 사용하여 화면에 접근
  final GlobalKey<AnalysisScreenState> _analysisKey = GlobalKey<AnalysisScreenState>();
  final GlobalKey<GardenScreenState> _gardenKey = GlobalKey<GardenScreenState>();

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _screens = [
      AnalysisScreen(key: _analysisKey, accessToken: widget.accessToken),
      GardenScreen(key: _gardenKey, accessToken: widget.accessToken),
      ProfileScreen(
        nickname: widget.nickname,
        email: widget.email,
        accessToken: widget.accessToken,
      ),
    ];
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index && mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  void _onHomeTapped() {
    if (mounted) {
      setState(() {
        _selectedIndex = -1;
      });
    }
  }

  void _onFloatingActionButtonPressed() {
    Future.delayed(Duration.zero, () {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmotionRecordScreen(accessToken: widget.accessToken),
          ),
        ).then((_) {
          // 일기 작성 후 돌아오면 캐시 갱신
          _refreshCache();
        });
      }
    });
  }

  void _refreshCache() {
    // AnalysisScreen과 GardenScreen의 캐시를 갱신
    _analysisKey.currentState?.refreshCache();
    _gardenKey.currentState?.refreshCache();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isPhone = screenWidth < 400;
    
    return Scaffold(
      body: _selectedIndex == -1
          ? HomeScreen(
              nickname: widget.nickname,
              email: widget.email,
              accessToken: widget.accessToken,
              onNavTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            )
          : _screens[_selectedIndex],
      bottomNavigationBar: _selectedIndex == -1
          ? null
          : SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 32.0 : 16.0, 
                    vertical: isTablet ? 12.0 : 8.0
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: _buildNavIconButton(
                          icon: Icons.home,
                          isSelected: false,
                          onTap: _onHomeTapped,
                          isTablet: isTablet,
                          isPhone: isPhone,
                        ),
                      ),
                      Expanded(
                        child: _buildNavIconButton(
                          icon: Icons.analytics,
                          isSelected: _selectedIndex == 0,
                          onTap: () => _onItemTapped(0),
                          isTablet: isTablet,
                          isPhone: isPhone,
                        ),
                      ),
                      // + 버튼을 네비게이션 바에 직접 추가
                      Container(
                        width: isTablet ? 70 : 60,
                        height: isTablet ? 70 : 60,
                        margin: EdgeInsets.only(bottom: isTablet ? 25 : 20),
                        child: FloatingActionButton(
                          onPressed: _onFloatingActionButtonPressed,
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          child: Icon(Icons.add, size: isTablet ? 32 : 28),
                        ),
                      ),
                      Expanded(
                        child: _buildNavIconButton(
                          icon: Icons.eco,
                          isSelected: _selectedIndex == 1,
                          onTap: () => _onItemTapped(1),
                          isTablet: isTablet,
                          isPhone: isPhone,
                        ),
                      ),
                      Expanded(
                        child: _buildNavIconButton(
                          icon: Icons.person,
                          isSelected: _selectedIndex == 2,
                          onTap: () => _onItemTapped(2),
                          isTablet: isTablet,
                          isPhone: isPhone,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isTablet,
    required bool isPhone,
  }) {
    final iconSize = isTablet ? 26.0 : (isPhone ? 20.0 : 22.0);
    final fontSize = isTablet ? 13.0 : (isPhone ? 10.0 : 11.0);
    final padding = isTablet ? 12.0 : 8.0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.deepPurple : Colors.grey,
              size: iconSize,
            ),
            SizedBox(height: isTablet ? 4 : 2),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.deepPurple : Colors.grey,
                  fontSize: fontSize,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavIconButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isTablet,
    required bool isPhone,
  }) {
    final iconSize = isTablet ? 34.0 : (isPhone ? 26.0 : 30.0);
    final padding = isTablet ? 12.0 : 8.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: padding),
        child: Icon(
          icon,
          color: isSelected ? Colors.deepPurple : Colors.grey,
          size: iconSize,
        ),
      ),
    );
  }
} 