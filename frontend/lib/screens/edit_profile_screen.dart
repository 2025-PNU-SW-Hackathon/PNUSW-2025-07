import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String? currentNickname;
  final String accessToken;
  const EditProfileScreen({Key? key, this.currentNickname, required this.accessToken}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nicknameController;
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.currentNickname ?? '');
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; });
    try {
      // 닉네임 변경
      if (_nicknameController.text.trim() != (widget.currentNickname ?? '')) {
        await ApiService.updateProfile(
          accessToken: widget.accessToken,
          nickname: _nicknameController.text.trim(),
        );
      }
      // 비밀번호 변경
      if (_newPasswordController.text.isNotEmpty) {
        await ApiService.updateProfile(
          accessToken: widget.accessToken,
          password: _newPasswordController.text,
        );
      }
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로필이 저장되었습니다.')),
        );
        Navigator.pop(context, true); // 성공 시 이전 화면으로 이동
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 정보 수정'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('닉네임 변경', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '새 닉네임',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return '닉네임을 입력하세요.';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text('비밀번호 변경', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _currentPasswordController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '현재 비밀번호',
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '새 비밀번호',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length < 6) return '6자 이상 입력하세요.';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: '새 비밀번호 확인',
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (_newPasswordController.text.isNotEmpty && value != _newPasswordController.text) return '비밀번호가 일치하지 않습니다.';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    child: _isLoading ? const CircularProgressIndicator() : const Text('저장'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 