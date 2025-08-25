import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  bool isLogin = true;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  bool isLoading = false;
  
  // 애니메이션 컨트롤러
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nicknameController.dispose();
    confirmPasswordController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void toggleForm() {
    setState(() {
      isLogin = !isLogin;
    });
  }

  Future<void> onSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() { isLoading = true; });
      try {
        if (isLogin) {
          // 네트워크 연결 확인
          try {
            final result = await ApiService.login(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
            );
            final accessToken = result['access_token'];
            final userInfo = await ApiService.getMyInfo(accessToken);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => MainNavigationScreen(
                  nickname: userInfo['nickname'],
                  email: userInfo['email'],
                  accessToken: accessToken,
                  initialIndex: -1, // 홈 화면부터 시작
                ),
              ),
            );
          } catch (e) {
            // 네트워크 오류 시 오프라인 모드로 진행
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('네트워크 연결을 확인해주세요. 오프라인 모드로 진행합니다.'),
                backgroundColor: Colors.orange,
              ),
            );
            
            // 오프라인 모드로 메인 화면 이동 (임시 사용자 정보)
            await Future.delayed(const Duration(seconds: 1));
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => MainNavigationScreen(
                    nickname: '사용자',
                    email: emailController.text.trim(),
                    accessToken: 'offline_mode',
                    initialIndex: -1,
                  ),
                ),
              );
            }
          }
        } else {
          try {
            final result = await ApiService.signup(
              email: emailController.text.trim(),
              password: passwordController.text.trim(),
              nickname: nicknameController.text.trim(),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('회원가입 성공! 이제 로그인 해주세요.')),
            );
            setState(() { isLogin = true; });
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('회원가입 실패: ${e.toString().replaceAll('Exception: ', '')}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류가 발생했습니다: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() { isLoading = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667eea),
              Color(0xFF764ba2),
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 앱 로고 및 제목
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.2),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'SimLog',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isLogin ? '마음의 정원에 오신 것을 환영합니다' : '새로운 정원을 만들어보세요',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),
                      
                      // 로그인/회원가입 카드
                      Card(
                        elevation: 12,
                        shadowColor: Colors.black38,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              // 토글 버튼
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          if (!isLogin) toggleForm();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          decoration: BoxDecoration(
                                            color: isLogin ? Colors.blue : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '로그인',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isLogin ? Colors.white : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          if (isLogin) toggleForm();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          decoration: BoxDecoration(
                                            color: !isLogin ? Colors.blue : Colors.transparent,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '회원가입',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: !isLogin ? Colors.white : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 32),
                              
                              // 폼
                              Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    _buildTextField(
                                      controller: emailController,
                                      label: '이메일',
                                      icon: Icons.email,
                                      keyboardType: TextInputType.emailAddress,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return '이메일을 입력하세요';
                                        }
                                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(value)) {
                                          return '유효한 이메일을 입력하세요';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    if (!isLogin) ...[
                                      _buildTextField(
                                        controller: nicknameController,
                                        label: '닉네임',
                                        icon: Icons.person,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return '닉네임을 입력하세요';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                    _buildTextField(
                                      controller: passwordController,
                                      label: '비밀번호',
                                      icon: Icons.lock,
                                      isPassword: true,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return '비밀번호를 입력하세요';
                                        }
                                        if (value.length < 6) {
                                          return '비밀번호는 6자 이상이어야 합니다';
                                        }
                                        return null;
                                      },
                                    ),
                                    if (!isLogin) ...[
                                      const SizedBox(height: 16),
                                      _buildTextField(
                                        controller: confirmPasswordController,
                                        label: '비밀번호 확인',
                                        icon: Icons.lock_outline,
                                        isPassword: true,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return '비밀번호 확인을 입력하세요';
                                          }
                                          if (value != passwordController.text) {
                                            return '비밀번호가 일치하지 않습니다';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                    const SizedBox(height: 32),
                                    _buildSubmitButton(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.withOpacity(0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF667eea),
            Color(0xFF764ba2),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                isLogin ? '로그인' : '회원가입',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
} 