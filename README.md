# Route Pires Flutter

App da equipe. A API **não pede senha**. Backend: [RoutePires](https://github.com/josevictoraraujorojas/RoutePires) (`master`).

- API: https://routepires.otavio.win
- Swagger: https://routepires.otavio.win/swagger-ui/index.html
- Saúde: https://routepires.otavio.win/actuator/health/liveness

A tela pronta é o **login** (`POST /login`). Cadastro e “esqueci senha” ainda não fazem nada.

No campus do IF o `.win` às vezes reseta. Aí use a API **no PC**.

## 1. Rodar o app

```text
git clone https://github.com/josevictoraraujorojas/route_pires_flutter.git
cd route_pires_flutter
flutter pub get
```

Padrão em Android, iOS e Chrome: `https://routepires.otavio.win`.

```text
flutter run
flutter run -d chrome
```

API no PC (quando o `.win` não abrir):

```text
rem Emulador Android
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

rem Simulador iOS / Chrome contra o PC
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080

rem Celular na mesma Wi‑Fi (troque o IP)
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8080
```

Sem barra no final da URL. Emulador Android **não** usa `localhost`; usa `10.0.2.2`.

Android já permite HTTP local (`INTERNET` + `usesCleartextTraffic`).

No Google Cloud da chave do mapa, ligue **Maps SDK for Android**, **Maps SDK for iOS** e **Maps JavaScript API** (Chrome). Sem isso o mapa fica cinza.

## 2. API no PC (quando o .win não abrir)

Na pasta do backend `RoutePires`:

1. JDK **17** (Temurin). O Java 25 do Android Studio **não serve**.
2. `firebase-runtime.json` em `secrets/firebase-runtime.json` (não vai para o Git).
3. `scripts\run-local.cmd`

Swagger local: http://localhost:8080/swagger-ui/index.html

```text
curl http://127.0.0.1:8080/actuator/health/liveness
```

Tem que voltar `{"status":"UP"}`.

## 3. Consumir a API (Dio)

Cliente: `lib/config/api_client.dart` (`ApiConfig.baseUrl`). Caminhos **relativos**. Sem header de senha. Sem CSRF.

### Saúde

```dart
final response = await ApiClient().dio.get(ApiConfig.health);
// 200 → { "status": "UP" }
```

### Login

A tela já chama isto (`lib/repositories/login_repository.dart`):

```dart
final response = await ApiClient().dio.post(
  '/login',
  data: {'email': email, 'senha': senha},
);
```

| HTTP | Significado |
|---|---|
| 200 | `id`, `nome`, `email`, `telefone`, `tipo` (`PASSAGEIRO` ou `MOTOTAXISTA`), `fotoUrl`, `dataCadastro`, `historicoCorridas` |
| 400 | email/senha em branco |
| 401 | senha errada |
| 404 | email não cadastrado no Firestore |

O `tipo` na resposta decide o diálogo de boas-vindas (passageiro vs mototaxista).

### Listar passageiros

```dart
final response = await ApiClient().dio.get(ApiConfig.passageiros);
// 200 lista JSON, ou 204 se vazio
```

### Cadastrar passageiro

`POST /passageiros` cria dado **de verdade** no Firestore. Não use como lixo de teste.

```json
{
  "nome": "João Gomes",
  "telefone": "64999558833",
  "senha": "senh4b0a",
  "fotoUrl": "https://exemplo.com/fotos/passageiro.jpg",
  "metodoPagamentoPreferido": "PIX"
}
```

Pagamento: `CREDITO`, `DEBITO`, `PIX`, `DINHEIRO`. Resposta **201**.

Outras rotas no Swagger: `/mototaxistas`, `/corridas-passageiro`, `/corrida-frete`, `/chat`, `/mensagem`, `/denuncias`, `/avaliacoes-mototaxista`.

## 4. Se não conectar

- API no ar? Liveness ou Swagger.
- Campus / `.win` resetando → API no PC.
- Emulador Android → `10.0.2.2`, não `localhost`.
- Celular e PC na mesma rede; firewall do Windows liberando 8080.
- `API_BASE_URL` **sem** barra no final.
- Sem header de senha. Sem CSRF neste ambiente.
- Flutter web só tem CORS para `http://localhost:*` (e `127.0.0.1`). Não abre a API de um site em outro domínio.
