import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:onnxruntime/onnxruntime.dart';
import 'package:dot/features/scan/data/wordpiece_tokenizer.dart';

class OnnxEmbeddingService {
  OrtSession? _session;
  final WordPieceTokenizer _tokenizer = WordPieceTokenizer();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      OrtEnv.instance.init();
      final sessionOptions = OrtSessionOptions();
      final modelData = await rootBundle.load('assets/models/model_quantized.onnx');
      _session = OrtSession.fromBuffer(modelData.buffer.asUint8List(), sessionOptions);
      await _tokenizer.loadVocab();
      _isInitialized = true;
      debugPrint('✅ [OnnxEmbeddingService] ONNX Service Initialized.');
    } catch (e) {
      debugPrint('❌ [OnnxEmbeddingService] Initialization Error: $e');
    }
  }

  Future<List<double>> getEmbedding(String text) async {
    if (!_isInitialized) await init();
    if (_session == null) throw Exception("ONNX Session not loaded");

    final tokens = _tokenizer.tokenize(text);
    final inputShape = [1, 128];
    final inputIdsData = Int64List.fromList(tokens);
    final attentionMaskData = Int64List.fromList(tokens.map((id) => id != 0 ? 1 : 0).toList());
    final tokenTypeIdsData = Int64List.fromList(List.filled(128, 0));

    final inputOrtIds = OrtValueTensor.createTensorWithDataList(inputIdsData, inputShape);
    final inputOrtMask = OrtValueTensor.createTensorWithDataList(attentionMaskData, inputShape);
    final inputOrtType = OrtValueTensor.createTensorWithDataList(tokenTypeIdsData, inputShape);

    final inputs = {
      'input_ids': inputOrtIds,
      'attention_mask': inputOrtMask,
      'token_type_ids': inputOrtType,
    };

    try {
      final runOptions = OrtRunOptions();
      final outputs = _session!.run(runOptions, inputs);
      final resultValue = outputs[0]?.value;
      
      inputOrtIds.release();
      inputOrtMask.release();
      inputOrtType.release();
      runOptions.release();

      if (resultValue is List<List<double>>) {
        return resultValue[0];
      } else if (resultValue is List<List<List<double>>>) {
        final seq = resultValue[0]; 
        final dim = seq[0].length;
        final pooled = List.filled(dim, 0.0);
        int count = 0;
        for (var i = 0; i < seq.length; i++) {
          if (tokens[i] != 0) { 
            for (var d = 0; d < dim; d++) {
              pooled[d] += seq[i][d];
            }
            count++;
          }
        }
        if (count == 0) return pooled;
        return pooled.map((v) => v / count).toList();
      }
      throw Exception("Unexpected output format");
    } catch (e) {
      debugPrint('❌ [OnnxEmbeddingService] Inference Error: $e');
      rethrow;
    }
  }

  void dispose() {
    _session?.release();
    OrtEnv.instance.release();
  }
}
