import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/config/api_config.dart';
import 'package:route_pires_flutter/repositories/mototaxista_repository.dart';

class MockDio extends Mock implements Dio {}

void main() {
  test(
    'Passageiro consulta o perfil do mototaxista pela rota permitida',
    () async {
      final dio = MockDio();
      final path = ApiConfig.perfilMototaxistaParaPassageiro('moto-1');
      when(
        () => dio.get<dynamic>(path, cancelToken: any(named: 'cancelToken')),
      ).thenAnswer(
        (_) async => Response<dynamic>(
          requestOptions: RequestOptions(path: path),
          data: {
            'nome': 'Ana',
            'avaliacaoMedia': 4.5,
            'disponivel': true,
            'veiculo': {'modelo': 'CG 160', 'ano': 2022, 'placa': 'ABC1D23'},
          },
        ),
      );

      final perfil = await MototaxistaRepository(dio: dio)
          .buscarPerfilParaPassageiro(id: 'moto-1');

      expect(perfil.id, 'moto-1');
      expect(perfil.nome, 'Ana');
      expect(perfil.modelo, 'CG 160');
      expect(perfil.placa, 'ABC1D23');
      verify(
        () => dio.get<dynamic>(path, cancelToken: any(named: 'cancelToken')),
      ).called(1);
    },
  );
}
