import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:route_pires_flutter/config/api_error.dart';
import 'package:route_pires_flutter/config/safe_change_notifier.dart';
import 'package:route_pires_flutter/repositories/avaliacao_repository.dart';

class AvaliacaoViewModel extends ChangeNotifier with SafeChangeNotifier {
  final AvaliacaoRepository _repository;

  AvaliacaoViewModel({AvaliacaoRepository? repository})
    : _repository = repository ?? AvaliacaoRepository();

  bool _enviando = false;
  bool _avaliada = false;
  String? _erro;

  bool get enviando => _enviando;

  /// A corrida já tem avaliação deste lado: enviada agora ou antes.
  bool get avaliada => _avaliada;
  String? get erro => _erro;

  Future<bool> avaliar({
    required String corridaId,
    required bool doMototaxista,
    required int nota,
    String? comentario,
  }) async {
    if (_enviando || _avaliada) return false;
    if (nota < 1 || nota > 5) {
      _erro = 'Escolha uma nota de 1 a 5 estrelas';
      avisar();
      return false;
    }

    _enviando = true;
    _erro = null;
    avisar();

    try {
      final texto = comentario?.trim() ?? '';
      await _repository.avaliar(
        corridaId: corridaId,
        doMototaxista: doMototaxista,
        nota: nota,
        comentario: texto.isEmpty ? null : texto,
      );
      _avaliada = true;
      return true;
    } on DioException catch (e) {
      final mensagem = mensagemErroDio(
        e,
        fallback: 'Não foi possível enviar a avaliação',
        porStatus: const {
          400: 'Dados inválidos. Verifique a avaliação.',
          404: 'Corrida não encontrada',
        },
      );
      // A API devolve 400 (não 409) quando a corrida já foi avaliada.
      _avaliada =
          e.response?.statusCode == 400 &&
          mensagem.contains('já possui avaliação');
      _erro = _avaliada ? 'Esta corrida já foi avaliada' : mensagem;
      return false;
    } catch (_) {
      _erro = 'Não foi possível enviar a avaliação';
      return false;
    } finally {
      _enviando = false;
      avisar();
    }
  }
}
