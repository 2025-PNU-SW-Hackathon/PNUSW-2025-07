import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';

class MindCheckScreen extends StatelessWidget {
  final String accessToken;
  const MindCheckScreen({super.key, required this.accessToken});

  static const String _formUrl = 'https://forms.gle/RM8vijEWkqgPo1de9';

  Future<void> _openForm() async {
    try {
      final uri = Uri.parse(_formUrl);
      
      // 먼저 canLaunchUrl로 확인
      if (await canLaunchUrl(uri)) {
        // 외부 브라우저로 열기 시도
        final launched = await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
        );
        
        if (!launched) {
          // 외부 브라우저 실패 시 inApp 브라우저로 시도
          await launchUrl(
            uri, 
            mode: LaunchMode.inAppWebView,
          );
        }
      } else {
        // 링크를 열 수 없는 경우 클립보드에 복사하고 사용자에게 알림
        await Clipboard.setData(ClipboardData(text: _formUrl));
        throw Exception('브라우저를 열 수 없습니다. 링크가 클립보드에 복사되었습니다.');
      }
    } catch (e) {
      // 에러 처리 - 사용자에게 알림
      if (e.toString().contains('클립보드에 복사되었습니다')) {
        _showErrorDialog('링크가 클립보드에 복사되었습니다.\n브라우저에서 직접 열어주세요.');
      } else {
        _showErrorDialog('링크를 열 수 없습니다.\n네트워크 연결을 확인해주세요.');
      }
    }
  }

  void _showErrorDialog(String message) {
    // BuildContext가 필요하므로 별도 메서드로 분리
    // 실제로는 StatefulWidget으로 변경하거나 다른 방법 사용 필요
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('마음 체크하기'),
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
            colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isTablet ? 32 : 24),
            child: Column(
              children: [
                Card(
                  elevation: 6,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 28 : 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.favorite, color: Colors.purple, size: 28),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                '효원 상담원 마음체크',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          '요즘의 마음 상태를 짧게 돌아볼 수 있는 설문입니다. 3분 - 16문항 정도로 간단하며, 필요할 때 스스로를 돌보는 시작점이 될 수 있어요.',
                          style: TextStyle(fontSize: 15, height: 1.5),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          '매주 금요일 오후에 효원상담원에서 결과 및 피드백 문자를 전송합니다. (개별 휴대전화로 문자가 발송되며 정확한 정보 입력 요망)',
                          style: TextStyle(fontSize: 15, height: 1.3),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '참여 전 안내',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        const _Bullet(text: '응답 내용은 SimLog와 자동 연동되지 않습니다.'),
                        const _Bullet(text: '필요시 상담 선생님께 직접 보여주실 수 있습니다.'),
                        const _Bullet(text: '네트워크 환경에 따라 링크 접속이 지연될 수 있어요.'),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () async {
                              try {
                                final uri = Uri.parse(_formUrl);
                                
                                // 먼저 canLaunchUrl로 확인
                                if (await canLaunchUrl(uri)) {
                                  // 외부 브라우저로 열기 시도
                                  final launched = await launchUrl(
                                    uri, 
                                    mode: LaunchMode.externalApplication,
                                  );
                                  
                                  if (!launched) {
                                    // 외부 브라우저 실패 시 inApp 브라우저로 시도
                                    await launchUrl(
                                      uri, 
                                      mode: LaunchMode.inAppWebView,
                                    );
                                  }
                                } else {
                                  // 링크를 열 수 없는 경우 클립보드에 복사하고 사용자에게 알림
                                  await Clipboard.setData(ClipboardData(text: _formUrl));
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('링크가 클립보드에 복사되었습니다. 브라우저에서 직접 열어주세요.'),
                                        duration: Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('링크를 열 수 없습니다: ${e.toString()}'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('설문 열기'),
                            style: FilledButton.styleFrom(padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 6,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: EdgeInsets.all(isTablet ? 28 : 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.link, color: Colors.blue, size: 28),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                '최근 7일 요약 링크 생성',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '예전에 만든 링크를 잊었거나 복사하지 못했다면 여기에서 언제든 새로 생성할 수 있어요. (7일 후 자동 만료, 본문은 포함되지 않습니다)',
                          style: TextStyle(fontSize: 14, height: 1.5),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () async {
                              await _handleCreateShare(context);
                            },
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('요약 링크 만들기'),
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
    );
  }

  Future<void> _handleCreateShare(BuildContext context) async {
    try {
      // 동의 여부 확인
      final consent = await ApiService.getConsent(accessToken: accessToken);
      final consented = consent['consented'] == true;
      if (!consented) {
        final agree = await _askConsent(context);
        if (agree != true) return;
        await ApiService.setConsent(accessToken: accessToken, consented: true);
      }
      final created = await ApiService.createWeeklyShare(accessToken: accessToken);
      final sharePath = created['share_path'] as String;
      final shareUrl = '${ApiService.baseUrl}$sharePath';
      if (context.mounted) {
        _showShareResult(context, shareUrl);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('링크 생성 실패: $e')),
        );
      }
    }
  }

  Future<bool?> _askConsent(BuildContext context) async {
    bool agreed = true;
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('요약 공유 동의'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('최근 7일 요약을 링크로 공유하는 데 동의하시나요? (본문 미포함, 7일 후 자동 만료)'),
              const SizedBox(height: 8),
              Row(children: [
                Checkbox(value: agreed, onChanged: (v) { agreed = v ?? false; }),
                const Text('동의합니다')
              ])
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(agreed), child: const Text('동의')),
          ],
        );
      },
    );
  }

  void _showShareResult(BuildContext context, String shareUrl) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('공유 링크가 준비됐어요'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('상담 선생님께 직접 보여주거나 전달해 주세요. (7일 후 자동 만료)'),
              const SizedBox(height: 10),
              SelectableText(shareUrl, style: const TextStyle(fontSize: 14, color: Colors.blue)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: shareUrl));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('복사되었습니다')));
                }
              },
              child: const Text('복사'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final uri = Uri.parse(shareUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    await Clipboard.setData(ClipboardData(text: shareUrl));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('링크가 클립보드에 복사되었습니다')),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('링크 열기 실패: $e')),
                    );
                  }
                }
              },
              child: const Text('열기'),
            ),
            FilledButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('닫기')),
          ],
        );
      },
    );
  }
}

class _Bullet extends StatelessWidget {
  final String text;
  
  const _Bullet({required this.text});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4))),
        ],
      ),
    );
  }
}

