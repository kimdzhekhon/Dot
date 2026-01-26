import 'dart:io';
import 'package:flutter/services.dart';

class WordPieceTokenizer {
  final Map<String, int> vocab = {};
  final int maxSeqLength = 128;

  Future<void> loadVocab() async {
    final vocabContent = await rootBundle.loadString('assets/models/vocab.txt');
    final lines = vocabContent.split('\n');
    for (int i = 0; i < lines.length; i++) {
      final token = lines[i].trim();
      if (token.isNotEmpty) {
        vocab[token] = i;
      }
    }
  }

  List<int> tokenize(String text) {
    if (vocab.isEmpty) return [];

    final tokens = ['[CLS]'];
    final words = text.toLowerCase().split(RegExp(r'\s+'));

    for (var word in words) {
      var start = 0;
      while (start < word.length) {
        var end = word.length;
        String? curToken;
        while (start < end) {
          var subStr = (start == 0) ? word.substring(start, end) : '##${word.substring(start, end)}';
          if (vocab.containsKey(subStr)) {
            curToken = subStr;
            break;
          }
          end--;
        }

        if (curToken == null) {
          tokens.add('[UNK]');
          break;
        } else {
          tokens.add(curToken);
          start = end;
        }
      }
    }

    tokens.add('[SEP]');

    // Map to IDs and pad
    final ids = tokens.map((t) => vocab[t] ?? vocab['[UNK]']!).toList();
    if (ids.length > maxSeqLength) {
      return ids.sublist(0, maxSeqLength);
    } else {
      while (ids.length < maxSeqLength) {
        ids.add(0); // [PAD]
      }
      return ids;
    }
  }
}
