# Validação do consumo — 02/10/2026

Base Flutter `e686512`, branch `feature/solicitacao-timeout-cancelamento`.
API local usa Firestore Emulator `demo-routepires`, sem credenciais reais,
em `127.0.0.1:8085`; Android acessa `10.0.2.2:8085`.

Verificações concluídas:

- `flutter analyze --no-pub`: nenhum problema.
- `flutter test --no-pub --concurrency=2`: 150 testes passaram.
- `flutter build apk --debug --no-pub --dart-define=API_BASE_URL=http://10.0.2.2:8085`: passou com JDK 17.
- `flutter build web --no-pub --base-href /app/`: passou.
- API `clean verify`: 114 testes passaram, incluindo integração real com Firestore Emulator.

Os testes cobrem intervalos, ausência de operações sobrepostas, GPS em movimento
e parado, primeiro valor/mudança de etapa do SDK, pausa e retomada, `Retry-After`,
falhas de resumos, atualização da previsão sem mudança de status, expiração da
previsão, histórico entre modalidades, aceite, cancelamento e timeout.

A validação Android encontrou a disponibilidade capturada fora da rota em cache
do `CupertinoTabView`: ligar o motorista no Perfil não retomava as consultas na
aba Corrida. A leitura do Provider foi movida para dentro do builder da aba.
Um teste com o scaffold real reproduziu a falha e confirmou a retomada online,
parada offline e conservação do estado da tela. A revisão independente dessa
correção não encontrou novos problemas.

O piloto simulado para cinco motoristas durante oito horas projeta 35.978
leituras e 11.010 escritas diárias no cenário de atendimento contínuo, incluindo
reservas. A medição e suas limitações estão em
[consumo-piloto.json](https://github.com/josevictoraraujorojas/RoutePires/blob/develop/docs/consumo-piloto.json).

Validação pelas telas em dois emuladores Android isolados:

- Passageiro solicitou e motorista aceitou em 7,4 segundos; o passageiro recebeu
  a previsão real do Navigation SDK, com minutos, distância e atribuição Google Maps.
- No frete, o SDK publicou 83 segundos/281 metros para o embarque, com atualizações
  a cada 30 segundos. A chegada ao embarque avançou para `pontoAtual=1` e publicou
  103 segundos/389 metros para o destino; a finalização pelo motorista encerrou os envios de previsão.
- Consultas online a cada 15 segundos e em atendimento a cada 30 segundos observadas
  nos logs. Desligar a disponibilidade interrompeu consultas e GPS; religar retomou
  a busca e recebeu uma solicitação pela tela.
- Aceite, cancelamento, timeout de 60 segundos, pausa/retomada e troca de etapa
  foram exercitados. A atualização sem mudança de status e a expiração da previsão
  após 120 segundos também foram verificadas com valores sintéticos no emulador.

Contas e corridas eram sintéticas no projeto `demo-routepires`; o último aceite e
as métricas reais do SDK não usaram PUTs auxiliares. O host ficou com pouca memória,
portanto os intervalos observados não são uma medição de fluidez nem comprovam
precisão do heartbeat de GPS parado. Seus limites, backoff e a troca de etapa
durante uma pausa estão cobertos por testes automatizados com relógio controlado.
A última limpeza de dados foi feita pela API local após o UiAutomator deixar de
retornar a hierarquia; a finalização pelo botão já havia sido validada no frete.

A API também passou no build Docker Linux: 105 testes executados e nove de Emulator
ignorados nesse build, já aprovados no `clean verify` local. A ativação em produção
está pendente da criação dos índices e da conclusão da auditoria de datas antigas:
a credencial disponível recebeu `403` ao criar índices e a cota esgotada interrompeu
a auditoria após 40 registros, sem alteração de datas.

## Correções após a revisão

A home recupera automaticamente a disponibilidade quando a consulta inicial falha,
respeitando o backoff e `Retry-After`. A recuperação pausa em segundo plano e
termina após sucesso, logout ou saída da tela; motorista confirmado offline
continua sem consultas periódicas de solicitações. Na API, GPS atualizado entre
a montagem e a execução da busca deixa de excluir um motorista válido.

Nova validação: 154 testes Flutter, `flutter analyze` sem problemas, builds Android
debug e Web release aprovados. A API passou em 116 testes, incluindo nove com
Firestore Emulator. Os custos por operação e a projeção do piloto permaneceram iguais.
