import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Um registro de uma chamada à API do Gemini (sucesso ou falha).
class GeminiLogEntry {
  /// Texto digitado pelo usuário (ex.: "eu quero um gato branco").
  final String message;

  /// Texto devolvido pelo modelo (ex.: {"tags":["white"]}). Null se a
  /// chamada falhou antes de haver resposta.
  final String? response;

  /// Tags finais, depois de validadas contra a lista da Cataas.
  final List<String> tags;

  /// Modelo solicitado e versão informada pela API na resposta (se houver).
  final String model;
  final String? modelVersion;

  /// Consumo de tokens informado pela API (usageMetadata).
  final int? promptTokens;
  final int? responseTokens;
  final int? thoughtsTokens;
  final int? cachedTokens;
  final int? totalTokens;

  final String? finishReason;
  final String? blockReason;
  final String? responseId;

  final bool success;
  final int? httpStatus;
  final String? error;
  final int latencyMs;
  final int availableTagsCount;

  /// JSON completo devolvido pela API, para não perder nenhum detalhe.
  final String? rawResponse;

  const GeminiLogEntry({
    required this.message,
    required this.model,
    required this.success,
    required this.latencyMs,
    required this.availableTagsCount,
    this.response,
    this.tags = const [],
    this.modelVersion,
    this.promptTokens,
    this.responseTokens,
    this.thoughtsTokens,
    this.cachedTokens,
    this.totalTokens,
    this.finishReason,
    this.blockReason,
    this.responseId,
    this.httpStatus,
    this.error,
    this.rawResponse,
  });

  static const int _maxRawLength = 20000;

  static int? _asInt(dynamic value) => value is num ? value.toInt() : null;
  static String? _asString(dynamic value) => value is String ? value : null;

  /// Monta o registro a partir do corpo (já decodificado) da resposta da API.
  /// Todos os campos de metadados são opcionais: o que a API não enviar fica
  /// de fora do log.
  factory GeminiLogEntry.fromApi({
    required String message,
    required String model,
    required int latencyMs,
    required int availableTagsCount,
    int? httpStatus,
    String? rawResponse,
    dynamic decoded,
    String? responseText,
    List<String> tags = const [],
    String? error,
  }) {
    final root = decoded is Map ? decoded : const {};
    final usage = root['usageMetadata'] is Map ? root['usageMetadata'] as Map : const {};
    final candidates = root['candidates'];
    final firstCandidate =
        candidates is List && candidates.isNotEmpty && candidates.first is Map
            ? candidates.first as Map
            : const {};
    final feedback =
        root['promptFeedback'] is Map ? root['promptFeedback'] as Map : const {};

    final raw = rawResponse == null || rawResponse.length <= _maxRawLength
        ? rawResponse
        : rawResponse.substring(0, _maxRawLength);

    return GeminiLogEntry(
      message: message,
      model: model,
      success: error == null,
      latencyMs: latencyMs,
      availableTagsCount: availableTagsCount,
      response: responseText,
      tags: tags,
      modelVersion: _asString(root['modelVersion']),
      promptTokens: _asInt(usage['promptTokenCount']),
      responseTokens: _asInt(usage['candidatesTokenCount']),
      thoughtsTokens: _asInt(usage['thoughtsTokenCount']),
      cachedTokens: _asInt(usage['cachedContentTokenCount']),
      totalTokens: _asInt(usage['totalTokenCount']),
      finishReason: _asString(firstCandidate['finishReason']),
      blockReason: _asString(feedback['blockReason']),
      responseId: _asString(root['responseId']),
      httpStatus: httpStatus,
      error: error,
      rawResponse: raw,
    );
  }

  /// Documento gravado no Firestore (campos sem valor não são gravados).
  Map<String, dynamic> toMap() {
    final tokens = <String, dynamic>{
      'prompt': promptTokens,
      'response': responseTokens,
      'thoughts': thoughtsTokens,
      'cached': cachedTokens,
      'total': totalTokens,
    }..removeWhere((_, value) => value == null);

    final map = <String, dynamic>{
      'message': message,
      'response': response,
      'tags': tags,
      'model': model,
      'modelVersion': modelVersion,
      'tokens': tokens,
      'finishReason': finishReason,
      'blockReason': blockReason,
      'responseId': responseId,
      'status': success ? 'success' : 'error',
      'httpStatus': httpStatus,
      'error': error,
      'latencyMs': latencyMs,
      'availableTagsCount': availableTagsCount,
      'rawResponse': rawResponse,
      'createdAt': FieldValue.serverTimestamp(),
    }..removeWhere((_, value) => value == null);

    return map;
  }
}

/// Grava o histórico de uso do Gemini em users/{uid}/geminiLogs.
class GeminiLogService {
  CollectionReference<Map<String, dynamic>>? _logs() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('geminiLogs');
  }

  /// Nunca lança exceção: um problema ao gravar o log não pode atrapalhar a
  /// busca de gatos. Quem chama não precisa esperar a gravação terminar.
  Future<void> log(GeminiLogEntry entry) async {
    try {
      final logs = _logs();
      if (logs == null) {
        debugPrint('Log do Gemini ignorado: usuário não autenticado.');
        return;
      }
      await logs.add(entry.toMap());
    } catch (e) {
      debugPrint('Não foi possível gravar o log do Gemini: $e');
    }
  }
}
