import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _isVerificationCodeLogin = true;
  String _detectedPhoneNumber = '';

  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _detectPhoneNumber();
  }

  Future<void> _detectPhoneNumber() async {
    try {
      // 在实际应用中，这里可以调用运营商API或使用其他方法获取本机号码
      // 目前使用模拟数据作为演示
      await Future.delayed(const Duration(milliseconds: 500));

      // 模拟检测到的手机号 - 在真实应用中，这里会调用实际的检测逻辑
      setState(() {
        _detectedPhoneNumber = '150****0730';
        _phoneController.text = '15012340730'; // 实际号码用于输入
      });
    } catch (e) {
      print('Failed to detect phone number: $e');
      // 如果检测失败，使用默认值
      setState(() {
        _detectedPhoneNumber = '****';
      });
    }
  }

  Future<void> _handleLogin() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请先同意隐私政策和用户协议')));
      return;
    }

    setState(() => _isLoading = true);

    // Simulate login process
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (mounted) {
      context.go('/home');
    }
  }

  void _handleSendCode() {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请输入手机号')));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('验证码已发送')));
  }

  void _handleQuickLogin() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('本机号码快捷登录'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('将使用本机号码进行快速登录', style: TextStyle(fontSize: 14)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _detectedPhoneNumber.isNotEmpty
                      ? _detectedPhoneNumber
                      : '检测中...',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (_detectedPhoneNumber.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: _detectedPhoneNumber.isNotEmpty
                  ? () {
                      Navigator.of(context).pop();
                      _handleLogin();
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
              child: const Text('确认登录'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9F6),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '登录/注册',
                    style: TextStyle(
                      color: Color(0xFF2C3E50),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Color(0xFF64748B),
                        size: 20,
                      ),
                    ),
                    onPressed: () => context.go('/home'),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Tabs with Animation
              Container(
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Animated Indicator
                    AnimatedAlign(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      alignment: _isVerificationCodeLogin
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        width:
                            MediaQuery.of(context).size.width / 2 -
                            32, // Half width minus padding
                        height: 48,
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14B8A6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    // Tab Buttons
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _isVerificationCodeLogin = true),
                            child: Container(
                              height: 56,
                              color: Colors.transparent,
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    '验证码登录',
                                    key: ValueKey(
                                      _isVerificationCodeLogin
                                          ? 'code'
                                          : 'code_inactive',
                                    ),
                                    style: TextStyle(
                                      color: _isVerificationCodeLogin
                                          ? Colors.white
                                          : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(
                              () => _isVerificationCodeLogin = false,
                            ),
                            child: Container(
                              height: 56,
                              color: Colors.transparent,
                              child: Center(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: Text(
                                    '密码登录',
                                    key: ValueKey(
                                      !_isVerificationCodeLogin
                                          ? 'password'
                                          : 'password_inactive',
                                    ),
                                    style: TextStyle(
                                      color: !_isVerificationCodeLogin
                                          ? Colors.white
                                          : const Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Input Fields Container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Phone Number Field
                    TextField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        hintText: '请输入手机号',
                        hintStyle: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF14B8A6),
                            width: 2,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Verification Code or Password Field
                    if (_isVerificationCodeLogin)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _codeController,
                              decoration: InputDecoration(
                                hintText: '请输入验证码',
                                hintStyle: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 16,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                    width: 1,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFF14B8A6),
                                    width: 2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF14B8A6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _handleSendCode,
                                borderRadius: BorderRadius.circular(12),
                                child: const Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    child: Text(
                                      '发送验证码',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          hintText: '请输入密码',
                          hintStyle: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF14B8A6),
                              width: 2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        obscureText: true,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Agreement Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(top: 2),
                    child: Checkbox(
                      value: _agreedToTerms,
                      onChanged: (bool? value) {
                        setState(() {
                          _agreedToTerms = value ?? false;
                        });
                      },
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: const Color(0xFF14B8A6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '已经阅读并同意隐私政策和用户协议',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '未注册绑定的手机号验证成功后将自动注册',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Login and Register Buttons
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF14B8A6),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF14B8A6).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading ? null : _handleLogin,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Text(
                                    '登录',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF14B8A6),
                          width: 2,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading ? null : _handleLogin,
                          borderRadius: BorderRadius.circular(14),
                          child: const Center(
                            child: Text(
                              '注册',
                              style: TextStyle(
                                color: Color(0xFF14B8A6),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),

              // Quick Login Section
              Column(
                children: [
                  const Text(
                    '其他登录方式',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _handleQuickLogin,
                        borderRadius: BorderRadius.circular(16),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.phone_android,
                                color: Color(0xFF14B8A6),
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                '本机号码快捷登录',
                                style: TextStyle(
                                  color: Color(0xFF2C3E50),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '未注册绑定的手机号验证成功后将自动注册',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildSocialLoginButton(String platform, String iconPath) {
  //   return GestureDetector(
  //     onTap: () => _handleSocialLogin(platform),
  //     child: Column(
  //       children: [
  //         Container(
  //           width: 48,
  //           height: 48,
  //           decoration: BoxDecoration(
  //             color: Colors.white,
  //             borderRadius: BorderRadius.circular(24),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: Colors.black.withOpacity(0.1),
  //                 blurRadius: 4,
  //                 offset: const Offset(0, 2),
  //               ),
  //             ],
  //           ),
  //           // child: Icon(
  //           //   _getIconForPlatform(platform),
  //           //   color: _getColorForPlatform(platform),
  //           //   size: 24,
  //           // ),
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           platform,
  //           style: const TextStyle(fontSize: 12, color: Colors.black54),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // IconData _getIconForPlatform(String platform) {
  //   switch (platform) {
  //     case '微信':
  //       return Icons.chat;
  //     case 'QQ':
  //       return Icons.message;
  //     case '微博':
  //       return Icons.share;
  //     case 'Apple':
  //       return Icons.apple;
  //     default:
  //       return Icons.person;
  //   }
  // }

  // Color _getColorForPlatform(String platform) {
  //   switch (platform) {
  //     case '微信':
  //       return Colors.green;
  //     case 'QQ':
  //       return Colors.blue;
  //     case '微博':
  //       return Colors.red;
  //     case 'Apple':
  //       return Colors.black;
  //     default:
  //       return Colors.grey;
  //   }
  // }
}
