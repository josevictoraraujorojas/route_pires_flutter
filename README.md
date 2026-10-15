# Route Pires Flutter

Cliente Flutter da API Route Pires. Login, cadastro, corridas e perfis existem para passageiro e mototaxista.

## Executar

```text
flutter pub get
flutter run
```

No Android e iOS, a API padrão é `https://siqs5nq4jauaxmdzdotn0jsj.62.171.158.2.sslip.io`. Para usar uma API local durante desenvolvimento, informe `--dart-define=API_BASE_URL=http://10.0.2.2:8080` no emulador Android ou a URL alcançável pelo aparelho. O Android permite HTTP local apenas no build de debug. Configure `GOOGLE_MAPS_API_KEY` em `android/local.properties` para compilar o app Android; não versione a chave.

## Autenticação

- Mobile: `POST /login` recebe e-mail e senha, retorna o perfil com `accessToken`. O token fica no `flutter_secure_storage`; após abrir o app, `GET /auth/me` valida o token antes de mostrar a home. Chamadas protegidas usam `Authorization: Bearer`.
- Web: `POST /auth/web/login` cria uma sessão em cookie HttpOnly. O cliente busca `GET /auth/web/csrf` e envia o header retornado nas escritas autenticadas. O navegador não salva nem recebe JWT em armazenamento JavaScript. `GET /auth/me` valida o cookie ao abrir o app; `POST /auth/web/logout` encerra a sessão.
- `401` em chamada protegida limpa a sessão local e volta ao login. `403` mostra erro de permissão e preserva a sessão. Cadastro de passageiro e mototaxista continua público.
- O cliente de geocodificação acessa `photon.komoot.io` separadamente, sem credenciais da Route Pires.

## Corridas

- O passageiro escolhe Corrida ou Frete e informa PIX, débito, crédito ou dinheiro. O pagamento é apenas informativo; o aplicativo não cobra valores.
- Fretes exigem descrição e peso da carga. Em **Minhas corridas**, o passageiro atualiza os estados, consulta o histórico e cancela solicitações pendentes sem apagar o registro.
- O mototaxista vê categoria, pagamento e dados da carga. Se a navegação nativa não iniciar, as ações da corrida permanecem disponíveis e o botão permite tentar novamente.
- **Restaurar** na solicitação volta à categoria, pagamento e locais recebidos da tela anterior.

O passageiro busca motoristas pelo embarque; a API aplica raio de 2 km e GPS
recebido nos últimos 120 segundos. O motorista publica GPS ao ficar disponível,
a cada 30 segundos com movimento acumulado de pelo menos 20 metros, ou a cada
60 segundos parado. Depois do aceite, o
SDK calcula a previsão até o próximo ponto e o app envia os valores no PUT
existente da corrida, no máximo a cada 30 segundos; primeiro valor e mudança
de etapa são imediatos. `pontoAtual: 0` representa
embarque e `1` representa destino final.

O polling do passageiro mostra minutos arredondados para cima e distância,
mesmo sem mudança de status. Sem previsão ou após 120 segundos, mostra
**Aguardando previsão**. O crédito **Google Maps** acompanha os valores do SDK;
as [políticas oficiais](https://developers.google.com/maps/documentation/navigation/android-sdk/policies)
orientam sua exibição. GPS, SDK e publicação podem falhar sem impedir as ações
da corrida. O Web lê a previsão produzida pelo SDK Android/iOS.

Motorista online consulta solicitações a cada 15 segundos; em atendimento,
a cada 30 segundos. Offline, sem atendimento, encerra o polling após a consulta
inicial. Passageiro consulta a cada 3 segundos enquanto aguarda o aceite, com
prazo de 60 segundos, e a cada 15 segundos após o aceite. Background pausa os
ciclos, sem zerar os intervalos e a espera após falhas. `503` preserva a sessão;
a espera progressiva respeita `Retry-After`, inclusive nos resumos.

O histórico carrega dez registros por modalidade, combina por data/ID e
exibe dez por página. O botão para carregar mais usa o último ID exibido como
cursor comum; não há polling do histórico. Consulte os payloads e requisitos
da API em [firebase-consumo.md](https://github.com/josevictoraraujorojas/RoutePires/blob/develop/docs/firebase-consumo.md).

## Publicar Flutter Web em `/app/`

```powershell
./scripts/build-web.ps1
```

Publique o conteúdo de `build/web` em `/app/` no mesmo domínio da API. O build usa `<base href="/app/">`; se o proxy remover o prefixo `/app` ao encaminhar, os arquivos devem estar na raiz do servidor estático (`/assets`, `/flutter_bootstrap.js` etc.). O código Web usa a origem da página como URL da API, portanto `/login`, `/auth/*` e os demais endpoints devem chegar ao backend na mesma origem. Para validar login por cookie em desenvolvimento, sirva o build por esse proxy ou pela API; `flutter run -d chrome` em outra origem não reproduz a sessão de produção.

No Coolify, a aplicação estática pode usar `Dockerfile.web` (porta 80) e encaminhar `/app/` para ela. O Dockerfile compila o Flutter no servidor; `deploy/nginx-web.conf` aceita tanto URLs com `/app/` quanto o prefixo removido pelo proxy e devolve `index.html` para rotas do app. Encaminhe as rotas da API separadamente ao backend.

O Web usa URLs por caminho (sem `#`). Qualquer acesso direto ou atualização em `/app/...` retorna o app, que valida `/auth/me` antes de mostrar a tela do usuário.

A navegação passo a passo do Google fica no Android/iOS. No Web, o mototaxista vê as solicitações e altera seu status sem a SDK nativa; o passageiro escolhe o local pela busca de endereço, coordenadas ou geolocalização.

## Verificar

```text
flutter analyze
flutter test
flutter build web --release --base-href /app/ --no-wasm-dry-run
```
