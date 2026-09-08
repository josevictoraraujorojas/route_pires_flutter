# Route Pires Flutter

App da equipe. A API **não pede senha**. Base: [RoutePires](https://github.com/josevictoraraujorojas/RoutePires).

## 1. Subir a API no PC

Na pasta do backend `RoutePires`:

1. JDK **17** (não o Java do Android Studio).
2. Colocar `firebase-runtime.json` em `secrets/firebase-runtime.json`.
3. `scripts\run-local.cmd`

Swagger: http://localhost:8080/swagger-ui/index.html

Teste rápido:

```text
curl http://127.0.0.1:8080/actuator/health/liveness
```

Tem que voltar `{"status":"UP"}`.

## 2. Apontar o Flutter para a API

O endereço fica em `lib/config/api_config.dart`, com `--dart-define`.

| Onde você roda o app | `API_BASE_URL` |
|---|---|
| Emulador Android | `http://10.0.2.2:8080` (padrão) |
| Simulador iOS | `http://127.0.0.1:8080` |
| Celular na mesma Wi‑Fi | `http://IP_DO_PC:8080` (ipconfig) |
| API na nuvem (fora do campus) | `https://routepires.otavio.win` |

```text
flutter pub get

rem Emulador Android (padrão 10.0.2.2)
flutter run

rem Simulador iOS
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080

rem Celular físico (troque o IP)
flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8080

rem Servidor
flutter run --dart-define=API_BASE_URL=https://routepires.otavio.win
```

No campus do IF o `.win` pode resetar. Use a API **local**.

Android já permite HTTP local (`INTERNET` + `usesCleartextTraffic`).

## 3. Consumir a API (Dio)

O cliente já existe: `lib/config/api_client.dart`. Ele usa `ApiConfig.baseUrl`. Os caminhos são **relativos**.

### Saúde

```dart
final response = await ApiClient().dio.get(ApiConfig.health);
// 200 → { "status": "UP" }
```

### Listar passageiros

```dart
final response = await ApiClient().dio.get(ApiConfig.passageiros);
// 200 lista JSON, ou 204 se vazio
```

### Cadastrar passageiro

`POST /passageiros` com JSON:

```json
{
  "nome": "João Gomes",
  "telefone": "64999558833",
  "senha": "senh4b0a",
  "fotoUrl": "https://exemplo.com/fotos/passageiro.jpg",
  "metodoPagamentoPreferido": "PIX"
}
```

Valores de pagamento: `CREDITO`, `DEBITO`, `PIX`, `DINHEIRO`. Resposta **201**.

Outros recursos no Swagger: `/mototaxistas`, `/corridas-passageiro`, `/corrida-frete`, `/chat`, `/mensagem`, `/denuncias`, `/avaliacoes-mototaxista`.

**Não existe `POST /login` no backend.** A tela de login do app ainda chama `/login`. Enquanto isso não for criado na API, use o Swagger e `GET /passageiros` para validar a conexão.

## 4. Se não conectar

- API subiu? `curl` na liveness.
- Emulador Android usa `10.0.2.2`, não `localhost`.
- Celular e PC na mesma rede; firewall do Windows liberando 8080.
- `API_BASE_URL` **sem** barra no final.
- Sem header de senha. Sem CSRF neste ambiente.
