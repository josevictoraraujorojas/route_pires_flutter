# QA — avaliações (10/11/2026)

## Ambiente

- API na branch `feature/avaliacoes` rodando local com o perfil `emulator` (Firestore Emulator, projeto `demo-routepires`). Nenhum dado real foi tocado.
- Flutter Web da branch `feature/avaliacoes` (`flutter build web --base-href /app/`), servido na mesma origem da API por um proxy local.
- Contas sintéticas criadas pela própria API: 2 passageiros e 2 mototaxistas.
- Sem Firebase Web configurado: notificações push ficaram desligadas.

## API, por requisições HTTP reais (75 de 75 passaram)

| Grupo | O que foi conferido |
| --- | --- |
| Estado da corrida | Avaliar corrida PENDENTE, em ANDAMENTO ou CANCELADA devolve 400, dos dois lados. |
| Autorização | Sem token: 401. Outro passageiro, outro mototaxista ou papel trocado: 403. Terceiro não lê avaliação alheia. Avaliado não edita a nota. |
| Validação | Nota 0, 6 ou ausente, comentário com 501 caracteres e id de corrida inválido: 400. |
| Envio | Passageiro avalia mototaxista e mototaxista avalia passageiro: 201. Segunda tentativa: 400. |
| Simultâneo | 6 envios ao mesmo tempo para a mesma corrida geram 1 avaliação, dos dois lados. |
| Médias | 5 e 2 viram 3,5; 4 e 5 viram 4,5. A média aparece no perfil, no resumo e na busca. Editar o perfil do passageiro não apaga a média. |
| Frete | Mesmas rotas e regras, usando o solicitante. |
| Respostas | Corrida e históricos devolvem os ids das avaliações. `DELETE` de avaliação não existe mais. |

## Telas, clicando no Flutter Web

| Jornada | Resultado |
| --- | --- |
| Passageiro, Minhas corridas | Só a corrida finalizada e sem avaliação mostra **Avaliar mototaxista**. Cancelada e já avaliada não mostram. |
| Diálogo | **Enviar** sem estrelas não envia nada. **Agora não** fecha e mantém o botão. Trocar de 4 para 2 estrelas funciona. Comentário com acento chega certo na API. |
| Passageiro, envio | 2 estrelas com comentário: 201, o botão some da lista. |
| Passageiro, acompanhando a corrida | Ao atualizar depois da finalização, a tela vira **Corrida finalizada** e o pedido de avaliação abre com o nome do mototaxista. |
| Corrida já avaliada por fora | O envio mostra **Esta corrida já foi avaliada** e o diálogo passa a oferecer **Fechar**. |
| Mototaxista, finalizar no Web | Ao tocar em **Finalizar corrida**, o pedido **Avaliar passageiro** abre com o nome do passageiro. |
| Mototaxista, Histórico de corridas | Depois de **Agora não**, a corrida continua com **Avaliar passageiro**. Enviar 1 estrela: 201, o botão some. |
| Aba Avaliações | **Falhou e foi corrigida**: era uma tela vazia. Agora mostra a média, a quantidade e cada avaliação recebida, para os dois papéis. Conferido: mototaxista 3,0 com 4 avaliações; passageiro 3,3 com 3. |
| Sessão | Recarregar a página mantém o usuário logado nos dois papéis. |

## O que não foi coberto

- Android e iOS: nada foi testado em aparelho. O pedido de avaliação por cima da navegação nativa do Google continua sem teste manual.
- Atualização automática por push: sem Firebase no ambiente local, a tela de acompanhamento só mudou ao tocar em **Atualizar**.
- Firestore real: o emulador segue as mesmas regras de transação, mas não é o banco de produção.
- Cadastro e solicitação de corrida pela interface: contas e corridas foram criadas pela API.
