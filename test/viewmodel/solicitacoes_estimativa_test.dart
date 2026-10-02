import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/model/categoria_corrida.dart';
import 'package:route_pires_flutter/model/localizacao_ponto.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';
import 'package:route_pires_flutter/repositories/corrida_repository.dart';
import 'package:route_pires_flutter/viewmodel/solicitacoes_viewmodel.dart';

class _Dio extends Mock implements Dio {}

void main() {
  const ponto = LocalizacaoPonto(
    latitude: -17.3,
    longitude: -48.28,
    rotulo: 'Centro',
  );
  const corrida = SolicitacaoCorrida(
    id: 'corrida-1',
    categoria: CategoriaCorrida.corrida,
    status: 'ANDAMENTO',
    mototaxistaId: 'moto-1',
    passageiroId: 'passageiro-1',
    passageiroNome: 'Maria',
    origem: ponto,
    destino: ponto,
  );

  testWidgets('Publica o primeiro valor e coalesce eventos em 15 segundos', (
    tester,
  ) async {
    final envios = <Map<String, dynamic>>[];
    final dio = _Dio();
    when(
      () => dio.put<dynamic>(
        any(),
        data: any(named: 'data'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((call) async {
      envios.add(Map<String, dynamic>.from(call.namedArguments[#data]));
      return Response(
        requestOptions: RequestOptions(path: '/corridas-passageiro/corrida-1'),
      );
    });
    final viewModel = SolicitacoesViewModel(
      mototaxistaId: 'moto-1',
      repository: CorridaRepository(dio: dio),
    );
    addTearDown(viewModel.dispose);

    viewModel.publicarEstimativa(
      solicitacao: corrida,
      tempoRestanteSegundos: 120.2,
      distanciaRestanteMetros: 900,
      pontoAtual: 0,
    );
    await tester.pump();
    expect(envios, [
      {
        'tempoRestanteSegundos': 120,
        'distanciaRestanteMetros': 900.0,
        'pontoAtual': 0,
      },
    ]);

    viewModel.publicarEstimativa(
      solicitacao: corrida,
      tempoRestanteSegundos: 110,
      distanciaRestanteMetros: 800,
      pontoAtual: 0,
    );
    viewModel.publicarEstimativa(
      solicitacao: corrida,
      tempoRestanteSegundos: 100,
      distanciaRestanteMetros: 700,
      pontoAtual: 0,
    );
    await tester.pump(const Duration(seconds: 14));
    expect(envios, hasLength(1));
    await tester.pump(const Duration(seconds: 1));
    expect(envios, [
      {
        'tempoRestanteSegundos': 120,
        'distanciaRestanteMetros': 900.0,
        'pontoAtual': 0,
      },
      {
        'tempoRestanteSegundos': 100,
        'distanciaRestanteMetros': 700.0,
        'pontoAtual': 0,
      },
    ]);
    viewModel.pararPublicacaoEstimativa();
  });

  testWidgets('Ignora dados inválidos e publicações antes do aceite', (
    tester,
  ) async {
    final envios = <Map<String, dynamic>>[];
    final dio = _Dio();
    when(
      () => dio.put<dynamic>(
        any(),
        data: any(named: 'data'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((call) async {
      envios.add(Map<String, dynamic>.from(call.namedArguments[#data]));
      return Response(
        requestOptions: RequestOptions(path: '/corridas-passageiro/corrida-1'),
      );
    });
    final viewModel = SolicitacoesViewModel(
      mototaxistaId: 'moto-1',
      repository: CorridaRepository(dio: dio),
    );
    addTearDown(viewModel.dispose);
    for (final status in ['PENDENTE', 'CANCELADO', 'FINALIZADO']) {
      viewModel.publicarEstimativa(
        solicitacao: corrida.copyWith(status: status),
        tempoRestanteSegundos: 120,
        distanciaRestanteMetros: 900,
        pontoAtual: 0,
      );
    }
    for (final tempo in [double.nan, double.infinity, -1.0]) {
      expect(
        () => viewModel.publicarEstimativa(
          solicitacao: corrida,
          tempoRestanteSegundos: tempo,
          distanciaRestanteMetros: 900,
          pontoAtual: 0,
        ),
        returnsNormally,
      );
    }
    for (final distancia in [double.nan, double.infinity, -1.0]) {
      viewModel.publicarEstimativa(
        solicitacao: corrida,
        tempoRestanteSegundos: 120,
        distanciaRestanteMetros: distancia,
        pontoAtual: 0,
      );
    }
    viewModel.publicarEstimativa(
      solicitacao: corrida,
      tempoRestanteSegundos: 120,
      distanciaRestanteMetros: 900,
      pontoAtual: 2,
    );
    await tester.pump(const Duration(seconds: 15));
    expect(envios, isEmpty);
    viewModel.publicarEstimativa(
      solicitacao: corrida,
      tempoRestanteSegundos: 0,
      distanciaRestanteMetros: 0,
      pontoAtual: 0,
    );
    await tester.pump();
    expect(envios, [
      {
        'tempoRestanteSegundos': 0,
        'distanciaRestanteMetros': 0.0,
        'pontoAtual': 0,
      },
    ]);
    viewModel.pararPublicacaoEstimativa();
  });

  testWidgets('Não sobrepõe envio e descarta etapa anterior ao avançar', (
    tester,
  ) async {
    final envios = <Map<String, dynamic>>[];
    final tokens = <CancelToken>[];
    final resposta = Completer<Response<dynamic>>();
    final dio = _Dio();
    when(
      () => dio.put<dynamic>(
        any(),
        data: any(named: 'data'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((call) {
      envios.add(Map<String, dynamic>.from(call.namedArguments[#data]));
      tokens.add(call.namedArguments[#cancelToken] as CancelToken);
      return resposta.future;
    });
    final viewModel = SolicitacoesViewModel(
      mototaxistaId: 'moto-1',
      repository: CorridaRepository(dio: dio),
    );
    addTearDown(viewModel.dispose);
    viewModel.publicarEstimativa(
      solicitacao: corrida,
      tempoRestanteSegundos: 60,
      distanciaRestanteMetros: 500,
      pontoAtual: 0,
    );
    viewModel.publicarEstimativa(
      solicitacao: corrida,
      tempoRestanteSegundos: 20,
      distanciaRestanteMetros: 100,
      pontoAtual: 0,
    );
    await tester.pump(const Duration(seconds: 15));
    expect(envios, hasLength(1));
    viewModel.descartarEstimativaPendente();
    expect(tokens.single.isCancelled, isTrue);
    viewModel.publicarEstimativa(
      solicitacao: corrida,
      tempoRestanteSegundos: 180,
      distanciaRestanteMetros: 1200,
      pontoAtual: 1,
    );
    expect(envios, hasLength(1));
    resposta.complete(
      Response(
        requestOptions: RequestOptions(path: '/corridas-passageiro/corrida-1'),
      ),
    );
    await tester.pump();
    expect(envios.last, {
      'tempoRestanteSegundos': 180,
      'distanciaRestanteMetros': 1200.0,
      'pontoAtual': 1,
    });
    viewModel.publicarEstimativa(
      solicitacao: corrida,
      tempoRestanteSegundos: 170,
      distanciaRestanteMetros: 1100,
      pontoAtual: 1,
    );
    viewModel.pararPublicacaoEstimativa();
    expect(tokens.last.isCancelled, isTrue);
    await tester.pump(const Duration(seconds: 30));
    expect(envios, hasLength(2));
  });
}
