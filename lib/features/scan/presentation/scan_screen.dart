import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dot/core/design_system/app_responsive_layout.dart';
import 'package:dot/core/design_system/app_theme.dart';
import 'package:dot/features/scan/presentation/dot_animation.dart';
import 'package:dot/features/scan/presentation/scan_controller.dart';
import 'package:dot/features/scan/domain/scan_type.dart';
import 'package:dot/features/scan/presentation/phone_number_formatter.dart';
import 'package:flutter/services.dart';



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
    if (text.isNotEmpty) {
      ref.read(scanProvider.notifier).analyzeText(text);
      _textController.clear();
      FocusScope.of(context).unfocus();
    }
  }

  void _onReset() {
    ref.read(scanProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);
    final dotState = scanState.dotState;

    return AppResponsiveLayout(
      // Ensure the background is light gray for the whole screen
      child: Container(
        color: const Color(0xFFF5F5F7), // Light Gray (iOS System Gray 6ish)
        child: SafeArea( // Apply SafeArea as requested
          child: Stack(
            children: [
              // Content Layout
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: scanState.scanType == null
                    ? _buildMenuLayout(context, scanState)
                    : dotState == DotState.idle || dotState == DotState.analyzing
                        ? _buildInputLayout(context, scanState)
                        : _buildResultLayout(context, scanState),
              ),
              
              // Loading Overlay (Overlaying the input field during analysis)
              if (dotState == DotState.analyzing)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withOpacity(0.8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        DotAnimation(state: dotState, size: 240),
                        const SizedBox(height: 24),
                        const Text(
                          '위협 분석 중...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.analyzing,
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
    );
  }

  Widget _buildMenuLayout(BuildContext context, ScanState scanState) {
    return Center( 
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20), // Added horizontal padding
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
             _buildMenuCard(
               label: '전화번호', 
               description: '발신자 번호를 조회하여 안전성을 확인하세요.',
               type: ScanType.phoneNumber,
               icon: CupertinoIcons.phone_fill,
             ),
             const SizedBox(height: 16),
             _buildMenuCard(
               label: '문자메시지', 
               description: '의심스러운 문자 내용이나 URL의 위험성을 분석합니다.',
               type: ScanType.message,
               icon: CupertinoIcons.bubble_left_fill,
             ),
             const SizedBox(height: 16),
             _buildMenuCard(
               label: '웹사이트 검색', 
               description: '사이트 주소를 조회하여 피싱 여부를 확인하세요.',
               type: ScanType.address,
               icon: CupertinoIcons.globe,
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String label,
    String? description,
    required ScanType type,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(scanProvider.notifier).changeScanType(type);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Ensure Icon is visible
            Icon(icon, color: AppTheme.analyzing, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                         fontSize: 13,
                         color: Colors.black54,
                         height: 1.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Trailing arrow
            const Icon(CupertinoIcons.chevron_right, color: Colors.black26, size: 20),
          ],
        ),
      ),
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
      body: state.scanType == ScanType.phoneNumber
          ? Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildSegmentedPhoneInput(state),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: _buildAnalyzeButton(state),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Other types (Message, Address) - Keep Box Style
                  Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
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
                  const Spacer(),
                  _buildAnalyzeButton(state),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildAnalyzeButton(ScanState state) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: PhoneNumberFormatter.isValid(
          _textController.text, 
          state.scanType == ScanType.phoneNumber
        ) ? _onSubmit : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.analyzing,
          disabledBackgroundColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: Text(
          state.scanType == ScanType.phoneNumber ? '검색하기' : '분석하기',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
            Text(
              _getStatusLabel(dotState, state.scanType),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),

            const SizedBox(height: 12),
            Text(
              state.message ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.4,
              ),
            ),
            
            if (state.score != null && state.score! >= 0) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
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
            ],

            const Spacer(),

            // Actions
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _onReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  '목록으로 돌아가기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                ref.read(scanProvider.notifier).reset();
              },
              child: const Text(
                '다시 분석하기',
                style: TextStyle(
                  color: Colors.black45,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(DotState state, ScanType? type) {
    if (type == ScanType.phoneNumber && state == DotState.safe) {
      return AppTheme.analyzing; // Blue for verified info
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
      case ScanType.phoneNumber: return '전화번호 분석';
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
        return '의심되는 웹사이트 주소를 입력하세요...'; // Updated Hint
    }
  }

  Widget _buildSegmentedPhoneInput(ScanState state) {
    final text = _textController.text;
    final clean = text.replaceAll('-', '');
    
    String p1 = '';
    String p2 = '';
    String p3 = '';

    if (clean.isNotEmpty) {
      if (clean.startsWith('02')) {
        // Seoul 02-XXX-XXXX or 02-XXXX-XXXX
        p1 = clean.substring(0, clean.length < 2 ? clean.length : 2);
        if (clean.length > 2) {
          int mid = clean.length <= 9 ? 5 : 6;
          p2 = clean.substring(2, clean.length < mid ? clean.length : mid);
          if (clean.length > mid) {
            p3 = clean.substring(mid);
          }
        }
      } else {
        // Standard 000-0000-0000 (3-4-4)
        p1 = clean.substring(0, clean.length < 3 ? clean.length : 3);
        if (clean.length > 3) {
          // Changed mid to handle 3-4-4 correctly
          int mid = clean.length <= 6 ? clean.length : 7; 
          p2 = clean.substring(3, clean.length < 7 ? clean.length : 7);
          if (clean.length > 7) {
            p3 = clean.substring(7);
          }
        }
      }
    }

    return Container(
      height: 100, // Adjusted height
      width: double.infinity,
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Display UI (Back)
          IgnorePointer(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center, // Ensure center alignment
              children: [
                _buildUnderlineBox(p1, clean.startsWith('02') ? 2 : 3),
                _buildSeparator(),
                _buildUnderlineBox(p2, clean.startsWith('02') ? (clean.length <= 9 ? 3 : 4) : 4), 
                _buildSeparator(),
                _buildUnderlineBox(p3, 4),
              ],
            ),
          ),

          // Hidden TextField (Front)
          Positioned.fill(
            child: Opacity(
              opacity: 0,
              child: TextField(
                controller: _textController,
                focusNode: _phoneFocusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [PhoneNumberFormatter()],
                autofocus: true,
                style: const TextStyle(fontSize: 1),
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildUnderlineBox(String value, int maxLength) {
    return Container(
      width: maxLength == 2 ? 60 : (maxLength == 3 ? 80 : 100),
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: value.length == maxLength ? AppTheme.analyzing : Colors.black12,
            width: 2,
          ),
        ),
      ),
      child: Center(
        child: Text(
          value.isEmpty ? '0' * maxLength : value,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: value.isEmpty ? Colors.black12 : Colors.black87,
            letterSpacing: 2,
            height: 1.0, // Force line height to 1.0 for better centering
          ),
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return const SizedBox(
      height: 60,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            '-',
            style: TextStyle(
              fontSize: 24, 
              color: Colors.black26, 
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

}

