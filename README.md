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

| Onde o app roda | `API_BASE_URL` |
|---|---|
| Chrome / Flutter web | `https://routepires.otavio.win` (padrão no web) |
| Emulador Android + API no PC | `http://10.0.2.2:8080` (padrão no Android) |
| Simulador iOS + API no PC | `http://127.0.0.1:8080` |
| Celular na mesma Wi‑Fi | `http://IP_DO_PC:8080` (`ipconfig`) |
| API na nuvem (qualquer device) | `https://routepires.otavio.win` |

```text
rem Web / Chrome (já cai na API da nuvem)
flutter run -d chrome

rem Emulador Android + API no PC (padrão 10.0.2.2)
flutter run

rem API na nuvem (emulador, celular, etc.)
flutter run --dart-define=API_BASE_URL=https://routepires.otavio.win

rem Celular físico (troque o IP)
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8080
```

Sem barra no final da URL. Emulador Android **não** usa `localhost`; usa `10.0.2.2`.

Android já permite HTTP local (`INTERNET` + `usesCleartextTraffic`).

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
