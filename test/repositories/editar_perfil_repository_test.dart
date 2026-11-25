import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/repositories/editar_perfil_repository.dart';

class _Dio extends Mock implements Dio {}

void main() {
  Future<String> rotaDe(String tipo) async {
    final dio = _Dio();
    when(() => dio.patch<dynamic>(any(), data: any(named: 'data'))).thenAnswer(
      (_) async => Response<dynamic>(requestOptions: RequestOptions(path: '')),
    );

    await EditarPerfilRepository(dio: dio).atualizarPerfil(
      id: 'u-1',
      tipo: tipo,
      nome: 'Ana',
      email: 'ana@teste.com',
      telefone: '64999558833',
    );

    return verify(
          () => dio.patch<dynamic>(captureAny(), data: any(named: 'data')),
        ).captured.single
        as String;
  }

  test('Mototaxista atualiza o perfil na própria rota', () async {
    expect(await rotaDe('MOTOTAXISTA'), '/mototaxistas/u-1');
  });

  test('Passageiro continua usando a rota de passageiros', () async {
    expect(await rotaDe('PASSAGEIRO'), '/passageiros/u-1');
  });
}
