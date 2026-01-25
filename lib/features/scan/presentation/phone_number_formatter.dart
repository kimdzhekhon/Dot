import 'package:flutter/services.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text.replaceAll(RegExp(r'\D'), '');
    var offset = newValue.selection.end;

    if (text.isEmpty) {
      return newValue.copyWith(text: '', selection: const TextSelection.collapsed(offset: 0));
    }

    String formatted = '';

    if (text.startsWith('02')) {
      // Seoul (02-XXX-XXXX or 02-XXXX-XXXX)
      if (text.length <= 2) {
        formatted = text;
      } else if (text.length <= 5) {
        formatted = '${text.substring(0, 2)}-${text.substring(2)}';
      } else if (text.length <= 9) {
        formatted = '${text.substring(0, 2)}-${text.substring(2, 5)}-${text.substring(5)}';
      } else {
        formatted = '${text.substring(0, 2)}-${text.substring(2, 6)}-${text.substring(6, 10)}';
      }
    } else {
      // Others (XXX-XXX-XXXX or XXX-XXXX-XXXX)
      if (text.length <= 3) {
        formatted = text;
      } else if (text.length <= 6) {
        formatted = '${text.substring(0, 3)}-${text.substring(3)}';
      } else if (text.length <= 10) {
        formatted = '${text.substring(0, 3)}-${text.substring(3, 6)}-${text.substring(6)}';
      } else {
        formatted = '${text.substring(0, 3)}-${text.substring(3, 7)}-${text.substring(7, 11)}';
      }
    }

    // Limit length (010-XXXX-XXXX is max 13 chars including hyphens)
    if (formatted.length > 13) {
      formatted = formatted.substring(0, 13);
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
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
