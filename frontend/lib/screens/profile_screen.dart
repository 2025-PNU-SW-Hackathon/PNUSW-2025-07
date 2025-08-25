import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/api_service.dart';
import 'edit_profile_screen.dart';
import 'app_settings_screen.dart';
import 'notification_settings_screen.dart';
import 'help_screen.dart';
import 'mind_check_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? nickname;
  final String? email;
  final String accessToken;
  const ProfileScreen({Key? key, this.nickname, this.email, required this.accessToken}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String? _nickname;
  String? _email;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();

    // 사용자 정보 로드
    _loadUserInfo();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final info = await ApiService.getMyInfo(widget.accessToken);
      if (!mounted) return;
      setState(() {
        _nickname = info['nickname'] as String?;
        _email = info['email'] as String?;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _nickname = widget.nickname;
        _email = widget.email;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE3F2FD),
              Color(0xFFF3E5F5),
              Colors.white,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 프로필 정보 카드
                  _buildProfileCard(),
                  const SizedBox(height: 32),
                  // 설정 메뉴
                  _buildSettingsSection(),
                  const SizedBox(height: 32),
                  // 로그아웃 버튼
                  _buildLogoutButton(),
                  const SizedBox(height: 24), // 하단 여백 추가
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Card(
      elevation: 8,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
      ),
              child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667eea),
                Color(0xFF764ba2),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 32.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: isTablet ? 80 : 60,
                    height: isTablet ? 80 : 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.person,
                      size: isTablet ? 40 : 30,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _nickname ?? widget.nickname ?? '설정되지 않음',
                          style: TextStyle(
                            fontSize: isTablet ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _email ?? widget.email ?? '설정되지 않음',
                          style: TextStyle(
                            fontSize: isTablet ? 16 : 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
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

  Widget _buildSettingsSection() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '설정',
          style: TextStyle(
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        _buildSettingsCard(),
      ],
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildSettingsTile(
            icon: Icons.edit,
            title: '내 정보 수정',
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditProfileScreen(
                    currentNickname: widget.nickname,
                    accessToken: widget.accessToken,
                  ),
                ),
              );
              if (result == true) {
                // 편집 후 사용자 정보 재로드
                await _loadUserInfo();
              }
            },
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.settings,
            title: '앱 설정',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppSettingsScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.notifications,
            title: '알림 설정',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationSettingsScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.favorite,
            title: '마음 체크하기',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MindCheckScreen(accessToken: widget.accessToken)),
              );
            },
          ),
          _buildDivider(),
          _buildSettingsTile(
            icon: Icons.help,
            title: '도움말',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HelpScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: Colors.blue,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        height: 1,
        color: Colors.grey.withOpacity(0.2),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFff6b6b),
            Color(0xFFee5a52),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFff6b6b).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              '로그아웃',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 