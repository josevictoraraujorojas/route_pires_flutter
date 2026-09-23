# Route Pires Flutter

Cliente Flutter da API Route Pires. Login, cadastro, corridas e perfis existem para passageiro e mototaxista.

## Executar

```text
flutter pub get
flutter run
```

No Android e iOS, a API padrão é `https://routepires.otavio.win`. Para usar uma API local durante desenvolvimento, informe `--dart-define=API_BASE_URL=http://10.0.2.2:8080` no emulador Android ou a URL alcançável pelo aparelho. O Android permite HTTP local apenas no build de debug. Configure `GOOGLE_MAPS_API_KEY` em `android/local.properties` para compilar o app Android; não versione a chave.

## Autenticação

- Mobile: `POST /login` recebe e-mail e senha, retorna o perfil com `accessToken`. O token fica no `flutter_secure_storage`; após abrir o app, `GET /auth/me` valida o token antes de mostrar a home. Chamadas protegidas usam `Authorization: Bearer`.
- Web: `POST /auth/web/login` cria uma sessão em cookie HttpOnly. O cliente busca `GET /auth/web/csrf` e envia o header retornado nas escritas autenticadas. O navegador não salva nem recebe JWT em armazenamento JavaScript. `GET /auth/me` valida o cookie ao abrir o app; `POST /auth/web/logout` encerra a sessão.
- `401` em chamada protegida limpa a sessão local e volta ao login. `403` mostra erro de permissão e preserva a sessão. Cadastro de passageiro e mototaxista continua público.
- O cliente de geocodificação acessa `photon.komoot.io` separadamente, sem credenciais da Route Pires.

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
