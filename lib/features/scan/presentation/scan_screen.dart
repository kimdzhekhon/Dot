import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dot/core/design_system/app_responsive_layout.dart';
import 'package:dot/core/design_system/app_theme.dart';
import 'package:dot/core/design_system/app_button.dart';
import 'package:go_router/go_router.dart';
import 'package:dot/features/scan/presentation/dot_animation.dart';
import 'package:dot/features/scan/presentation/scan_controller.dart';
import 'package:dot/features/scan/domain/scan_type.dart';
import 'package:dot/features/scan/presentation/phone_number_formatter.dart';
import 'package:dot/core/design_system/app_loading_overlay.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dot/core/utils/url_util.dart';
import 'package:dot/features/scan/presentation/scan_providers.dart';
import 'package:dot/features/scan/presentation/widgets/scan_stats_header.dart';
import 'package:dot/features/scan/presentation/widgets/scan_menu_card.dart';



class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    // Request focus if it's already phoneNumber mode (though it usually starts at null)
  }

  void _onTextChanged() {
    setState(() {}); // Rebuild for button activation and segmented display
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }



  void _onSubmit() {
    final text = _textController.text;
    final scanType = ref.read(scanProvider).scanType;

    if (text.isNotEmpty) {
      // Validation for Address Scan
      if (scanType == ScanType.address && !text.contains('.')) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(
             content: Text('올바른 도메인 형식이 아닙니다'),
             backgroundColor: Colors.black87,
             behavior: SnackBarBehavior.floating,
             duration: Duration(seconds: 2),
           )
         );
         return;
      }

      // [TEST] 문자 메시지 분석 시 URL 추출 테스트 -> 결과 화면으로 이동
      // Changed to direct analysis flow
      if (scanType == ScanType.message) {
        // Now using same flow as others
        ref.read(scanProvider.notifier).analyzeText(text);
        FocusScope.of(context).unfocus();
        return;
      }

      ref.read(scanProvider.notifier).analyzeText(text);
      // _textController.clear(); // Keep text for re-analysis
      FocusScope.of(context).unfocus();
    }
  }

  void _onReset() {
    _textController.clear();
    ref.read(scanProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);
    final dotState = scanState.dotState;

    return AppLoadingOverlay(
      isLoading: dotState == DotState.analyzing,
      message: '위협 분석 중...',
      child: AppResponsiveLayout(
        // Ensure the background is light gray for the whole screen
        child: Container(
          color: AppTheme.surface, // Use theme surface color (#F2F2F7)
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: scanState.scanType == null
                ? _buildMenuLayout(context, scanState)
                : SafeArea(
                    child: dotState == DotState.idle || dotState == DotState.analyzing
                        ? _buildInputLayout(context, scanState)
                        : _buildResultLayout(context, scanState),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuLayout(BuildContext context, ScanState scanState) {
    return Column(
      children: [
        const ScanStatsHeader(),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                   ScanMenuCard(
                     label: '공공기관 전화번호', 
                     description: '발신자 번호를 조회하여 안전성을 확인하세요.',
                     type: ScanType.phoneNumber,
                     icon: CupertinoIcons.phone_fill,
                     onTap: () => ref.read(scanProvider.notifier).changeScanType(ScanType.phoneNumber),
                   ),
                   const SizedBox(height: 16),
                   ScanMenuCard(
                     label: '문자메시지', 
                     description: '의심스러운 문자 내용이나 URL의 위험성을 분석합니다.',
                     type: ScanType.message,
                     icon: CupertinoIcons.bubble_left_fill,
                     onTap: () => ref.read(scanProvider.notifier).changeScanType(ScanType.message),
                   ),
                   const SizedBox(height: 16),
                   ScanMenuCard(
                     label: '웹사이트 검색', 
                     description: '사이트 주소를 조회하여 피싱 여부를 확인하세요.',
                     type: ScanType.address,
                     icon: CupertinoIcons.globe,
                     onTap: () => ref.read(scanProvider.notifier).changeScanType(ScanType.address),
                   ),
                   const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }


  // Import at top if not present, but CupertinoIcons is usually available if cupertino_icons pkg is in pubspec? 
  // Actually usually need 'package:flutter/cupertino.dart' for the types, or just 'package:flutter/material.dart' allows Icon widget but CupertinoIcons class needs import?
  // Standard flutter/material.dart does NOT export CupertinoIcons. 
  // I need to add import 'package:flutter/cupertino.dart'; at top of file? 
  // Wait, I can't add imports with replace_file_content easily unless I target top.
  // I will assume `CupertinoIcons` is available or I will add the import.
  // Let's check imports first.
  
  // Re-writing the build method parts.
  
  Widget _buildInputLayout(BuildContext context, ScanState state) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Uses parent container color
      appBar: AppBar(
        leadingWidth: 60, 
        leading: GestureDetector(
          onTap: () {
            _textController.clear();
            ref.read(scanProvider.notifier).changeScanType(null);
            FocusScope.of(context).unfocus();
          },
          child: Container(
            color: Colors.transparent, // Hit test area
            padding: const EdgeInsets.only(left: 16), // Padding from edge
            child: const Icon(CupertinoIcons.left_chevron, color: Colors.black54, size: 24),
          ),
        ),
        title: Text(
          _getTypeLabel(state.scanType!),
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
      ),
      body: (state.scanType == ScanType.phoneNumber || state.scanType == ScanType.address)
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  const Spacer(flex: 1),
                  state.scanType == ScanType.phoneNumber 
                    ? _buildPhoneInput(state)
                    : _buildAddressInput(state),
                  const Spacer(flex: 3),
                  _buildAnalyzeButton(state),
                ],
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Other types (Message) - Expanded Box Style
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _textController,
                        maxLines: null,
                        expands: true,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: _getHintText(state.scanType ?? ScanType.message),
                          hintStyle: const TextStyle(color: Colors.black38),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildAnalyzeButton(state),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildAnalyzeButton(ScanState state) {
    return AppButton(
      text: (state.scanType == ScanType.phoneNumber || state.scanType == ScanType.address) ? '검색하기' : '분석하기',
      onPressed: (state.scanType == ScanType.phoneNumber)
          ? (PhoneNumberFormatter.isValid(_textController.text, true) ? _onSubmit : null)
          : (_textController.text.isNotEmpty ? _onSubmit : null),
      backgroundColor: AppTheme.primary,
    );
  }


  Widget _buildResultLayout(BuildContext context, ScanState state) {
    final dotState = state.dotState;
    final color = _getStatusColor(dotState, state.scanType);


    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.multiply, color: Colors.black54),
          onPressed: _onReset,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(),
            
            // Result Animation
            DotAnimation(state: dotState, size: 200),
            const SizedBox(height: 40),
            
            // Result Message
            if (state.scanType != ScanType.phoneNumber || dotState == DotState.safe)
              Text(
                _getStatusLabel(dotState, state.scanType),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            
            // Spacing adjustment if title is hidden
            if (state.scanType == ScanType.phoneNumber && dotState != DotState.safe)
               const SizedBox(height: 10),

            // Hide description message for address scan if it's just repeating the title
            if (state.scanType != ScanType.address) ...[
               const SizedBox(height: 12),
               Text(
                 state.message ?? '',
                 textAlign: TextAlign.center,
                 style: const TextStyle(
                   fontSize: 20,
                   color: Colors.black87,
                   fontWeight: FontWeight.w500,
                   height: 1.4,
                 ),
               ),
            ],

            if (state.scanType == ScanType.phoneNumber) ...[
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  final url = Uri.parse('https://www.police.go.kr/www/security/cyber/cyber04.jsp#');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.search, size: 16, color: AppTheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '인터넷 사기 의심 전화·계좌번호 조회',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            if (state.score != null && state.score! >= 0 && state.scanType != ScanType.phoneNumber) ...[
              const SizedBox(height: 24),
              Column(
                children: [
                   // Only show score if NOT address type
                   if (state.scanType != ScanType.address)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '위험도 점수: ${state.score} / 100',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),

                  if (state.scanType == ScanType.address && state.details?['webList']?['found'] == true) ...[
                    const SizedBox(height: 16),
                    Text(
                      '등록 주체: ${state.details!['webList']['reg_subject'] ?? '정보 없음'}',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '등록일: ${state.details!['webList']['reg_date'] ?? '정보 없음'}',
                      style: const TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                  ] else if (state.scanType == ScanType.address && state.details?['whois']?.isNotEmpty == true) ...[
                     const SizedBox(height: 16),
                     if (state.details?['isNewDomain'] == true)
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.warning),
                          ),
                          child: Text(
                            "⚠️ 신규 생성 도메인 (48시간 이내)",
                            style: TextStyle(
                              color: AppTheme.warning,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                     // Detailed WHOIS Info
                     Container(
                       width: double.infinity,
                       padding: const EdgeInsets.all(16),
                       decoration: BoxDecoration(
                         color: Colors.white,
                         borderRadius: BorderRadius.circular(12),
                         border: Border.all(color: Colors.black12),
                       ),
                       child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text(
                             "도메인 상세 정보",
                             style: TextStyle(
                               fontSize: 15,
                               fontWeight: FontWeight.bold,
                               color: Colors.black87,
                             ),
                           ),
                           const SizedBox(height: 12),
                           _buildInfoRow('등록일', state.details!['whois']['regDate'] ?? '-'),
                           const SizedBox(height: 8),
                           _buildInfoRow('등록인/기관', state.details!['whois']['regName'] ?? '-'),
                           const SizedBox(height: 8),
                           _buildInfoRow('주소(국적)', state.details!['whois']['addr'] ?? '-'),
                           const SizedBox(height: 8),
                           _buildInfoRow('등록 대행자', state.details!['whois']['agency'] ?? '-'),
                         ],
                       ),
                     ),
                  ],
                ],
              ),
            ],
            
            const SizedBox(height: 24),
            // Disclaimer for all scans
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                '분석 결과는 참고용으로만 사용해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const Spacer(),

            // Actions
            AppButton(
              text: '다시 분석하기',
              onPressed: _onReset,
              backgroundColor: AppTheme.primary,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(DotState state, ScanType? type) {
    if (type == ScanType.phoneNumber && state == DotState.safe) {
      return AppTheme.primary; // Blue for verified info
    }
    switch (state) {
      case DotState.safe: return AppTheme.safe;
      case DotState.dangerous: return AppTheme.dangerous;
      case DotState.warning: return AppTheme.warning;
      default: return AppTheme.primary;
    }
  }


  String _getStatusLabel(DotState state, ScanType? type) {
    if (type == ScanType.phoneNumber && state == DotState.safe) {
      return '기관 정보 조회 결과';
    }
    switch (state) {
      case DotState.safe: return '안전한 정보입니다';
      case DotState.dangerous: return '위험이 감지되었습니다';
      case DotState.warning: return '경고: 주의가 필요합니다';
      default: return '분석 결과';
    }
  }


  String _getTypeLabel(ScanType type) {

    switch (type) {
      case ScanType.phoneNumber: return '공공기관 전화번호 분석';
      case ScanType.message: return '문자메시지 분석';
      case ScanType.address: return '웹사이트 검색'; // Updated Title
    }
  }

  String _getHintText(ScanType type) {
    switch (type) {
      case ScanType.phoneNumber:
        return '전화번호를 입력하세요\n(예: 010-1234-5678)';
      case ScanType.message:
        return '의심되는 문자 메시지 내용이나\nURL을 여기에 붙여넣으세요...';
      case ScanType.address:
        return '웹사이트 주소를 입력해 주세요'; // Updated Hint
    }
  }

  Widget _buildAddressInput(ScanState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '웹사이트 주소 입력',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.black12,
                width: 2,
              ),
            ),
          ),
          child: TextField(
            controller: _textController,
            focusNode: _phoneFocusNode,
            keyboardType: TextInputType.url,
            inputFormatters: [
               FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9\.\-\/\:\?\=\&\%]')),
            ],
            autofocus: true,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 24, // Slightly smaller than phone number for long URLs
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: '웹사이트 주소를 입력해 주세요',
              hintStyle: TextStyle(
                color: Colors.black12,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneInput(ScanState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '공공기관 전화번호 입력',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.black12,
                width: 2,
              ),
            ),
          ),
          child: TextField(
            controller: _textController,
            focusNode: _phoneFocusNode,
            keyboardType: TextInputType.number,
            inputFormatters: [PhoneNumberFormatter()],
            autofocus: true,
            textAlign: TextAlign.left,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: '전화번호를 입력해 주세요',
              hintStyle: TextStyle(
                color: Colors.black12,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

}


