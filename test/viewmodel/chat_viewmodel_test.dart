import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:route_pires_flutter/model/chat.dart';
import 'package:route_pires_flutter/repositories/chat_repository.dart';
import 'package:route_pires_flutter/services/atualizacoes_service.dart';
import 'package:route_pires_flutter/viewmodel/chat_viewmodel.dart';

class _ChatRepository extends Mock implements ChatRepository {}

void main() {
  testWidgets('Conversa carrega ao abrir e depois só atualiza por evento', (
    tester,
  ) async {
    final repository = _ChatRepository();
    var consultas = 0;
    when(() => repository.buscar('chat-1')).thenAnswer((_) async {
      consultas++;
      return Chat(id: 'chat-1', nomeOutroParticipante: 'Ana');
    });
    when(() => repository.listarMensagens('chat-1'))
        .thenAnswer((_) async => []);
    final viewModel = ChatViewModel(
      chatId: 'chat-1',
      encerrado: false,
      chatRepository: repository,
    );

    await viewModel.inicializar();
    expect(consultas, 1);
    await tester.pump(const Duration(minutes: 5));
    expect(consultas, 1);

    AtualizacoesService().publicar(const {
      'tipo': 'MENSAGENS_ATUALIZADAS',
      'chatId': 'outro-chat',
    });
    await tester.pump(const Duration(seconds: 1));
    expect(consultas, 1);

    AtualizacoesService().publicar(const {
      'tipo': 'MENSAGENS_ATUALIZADAS',
      'chatId': 'chat-1',
    });
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(consultas, 2);

    // Sem chatId: é assim que a conversa recupera o que chegou em segundo plano.
    AtualizacoesService().sincronizar();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(consultas, 3);
    viewModel.dispose();
  });
}
