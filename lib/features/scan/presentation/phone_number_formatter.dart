import 'package:flutter/services.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Only allow digits
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    
    // Limit length to 11 digits
    if (text.length > 11) {
      text = text.substring(0, 11);
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  static bool isValid(String text, bool isPhoneNumberType) {
    if (!isPhoneNumberType) return text.isNotEmpty;
    
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('02')) {
      return digits.length >= 9 && digits.length <= 10;
    } else {
      return digits.length >= 10 && digits.length <= 11;
    }
  }
}
