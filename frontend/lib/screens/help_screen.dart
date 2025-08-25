import 'package:flutter/material.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({Key? key}) : super(key: key);

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('도움말'),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  title: '앱 사용법',
                  icon: Icons.help_outline,
                  children: [
                    _buildHelpItem(
                      icon: Icons.edit_note,
                      title: '일기 작성',
                      description: '+ 버튼을 눌러 감정 일기를 작성하세요. 음성 입력도 지원됩니다.',
                    ),
                    _buildHelpItem(
                      icon: Icons.analytics,
                      title: '감정 분석',
                      description: '최근 감정 통계와 AI 분석 결과를 확인할 수 있습니다.',
                    ),
                    _buildHelpItem(
                      icon: Icons.eco,
                      title: '마음 정원',
                      description: '감정 기록이 꽃으로 표현됩니다. 정원을 꾸며보세요!',
                    ),
                    _buildHelpItem(
                      icon: Icons.person,
                      title: '내 정보',
                      description: '닉네임/비밀번호를 변경하고 앱 설정을 관리할 수 있습니다.',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: '정원 시스템',
                  icon: Icons.eco,
                  children: [
                    _buildHelpItem(
                      icon: Icons.eco,
                      title: '씨앗 획득',
                      description: '일기 작성 시 2씨앗, 출석 체크 시 2씨앗을 획득합니다.',
                    ),
                    _buildHelpItem(
                      icon: Icons.shopping_cart,
                      title: '아이템 구매',
                      description: '상점에서 씨앗으로 다양한 정원 아이템을 구매할 수 있습니다.',
                    ),
                    _buildHelpItem(
                      icon: Icons.sell,
                      title: '아이템 판매',
                      description: '인벤토리에서 불필요한 아이템을 판매하여 씨앗을 얻을 수 있습니다.',
                    ),
                    _buildHelpItem(
                      icon: Icons.grid_on,
                      title: '정원 배치',
                      description: '정원 탭에서 아이템을 클릭하여 원하는 위치에 배치하세요.',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: '정원 레이어링 시스템',
                  icon: Icons.layers,
                  children: [
                    _buildHelpItem(
                      icon: Icons.eco,
                      title: '4단계 레이어',
                      description: '정원은 배경(0), 중간(1), 식물(2), 동물(3) 4단계 레이어로 구성됩니다.',
                    ),
                    _buildHelpItem(
                      icon: Icons.landscape,
                      title: '배경 레이어',
                      description: '잔디, 모래, 돌, 자갈, 흙 등이 배경을 구성합니다.',
                    ),
                    _buildHelpItem(
                      icon: Icons.water,
                      title: '중간 레이어',
                      description: '연못, 울타리, 다리, 벤치 등이 중간에 위치합니다.',
                    ),
                    _buildHelpItem(
                      icon: Icons.local_florist,
                      title: '식물 레이어',
                      description: '꽃, 나무, 부시, 채소 등이 식물 레이어에 위치합니다.',
                    ),
                    _buildHelpItem(
                      icon: Icons.pets,
                      title: '동물 레이어',
                      description: '물고기, 새, 나비, 벌 등이 가장 앞에 표시됩니다.',
                    ),
                    _buildHelpItem(
                      icon: Icons.color_lens,
                      title: '조건부 배경색',
                      description: '연못 위의 아이템들은 연못색 배경으로 표시되어 자연스러운 효과를 줍니다.',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: '저작권 및 라이센스',
                  icon: Icons.copyright,
                  children: [
                    _buildHelpItem(
                      icon: Icons.image,
                      title: '정원 에셋',
                      description: '이 앱의 정원 아이템들은 Figma Community의 "Garden This - The Game" 에셋을 사용합니다.',
                    ),
                    _buildHelpItem(
                      icon: Icons.description,
                      title: '라이센스',
                      description: 'Creative Commons Attribution 4.0 International License에 따라 사용됩니다.',
                    ),
                    _buildHelpItem(
                      icon: Icons.link,
                      title: '원본 링크',
                      description: 'https://www.figma.com/community/file/1246272622386692939/garden-this-the-game',
                    ),
                    _buildHelpItem(
                      icon: Icons.info,
                      title: '저작자 표시',
                      description: '원작자에게 적절한 저작자 표시를 제공하고 있습니다.',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: '문의 및 지원',
                  icon: Icons.support_agent,
                  children: [
                    _buildHelpItem(
                      icon: Icons.email,
                      title: '문의하기',
                      description: '더 궁금한 점이 있으면 개발팀에 문의해 주세요.',
                    ),
                    _buildHelpItem(
                      icon: Icons.bug_report,
                      title: '버그 신고',
                      description: '앱에서 문제가 발생하면 버그 신고를 해주세요.',
                    ),
                    _buildHelpItem(
                      icon: Icons.mark_email_unread,
                      title: '버그/건의 메일',
                      description: '버그나 건의사항은 octopus121@pusan.ac.kr 로 메일을 보내주세요.',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.blue, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.green, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
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