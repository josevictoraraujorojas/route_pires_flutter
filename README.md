# Route Pires Flutter

App da equipe. A API **não pede senha**. Backend: [RoutePires](https://github.com/josevictoraraujorojas/RoutePires) (`master`).

- API: https://routepires.otavio.win
- Swagger: https://routepires.otavio.win/swagger-ui/index.html
- Saúde: https://routepires.otavio.win/actuator/health/liveness

Telas prontas: **login** (`POST /login`) e **cadastro de passageiro** (`POST /passageiros`). “Esqueci senha” e cadastro de mototaxista ainda não fazem a chamada da API.

O app usa **https://routepires.otavio.win**. Não use API local no dia a dia.

## 1. Rodar o app

```text
git clone https://github.com/josevictoraraujorojas/route_pires_flutter.git
cd route_pires_flutter
git checkout cadastro_passageiro
flutter pub get
flutter run
```

Web: `flutter run -d chrome`. Sem `--dart-define`. A URL da API já está no código.

## 2. Consumir a API (Dio)

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

### Cadastrar passageiro

A tela de cadastro chama isto (`lib/repositories/cadastro_passageiro_repository.dart`). `POST /passageiros` cria dado **de verdade** no Firestore.

A tela pede nome, e-mail, telefone, senha e termos. O app envia só isso. Telefone vai só com dígitos; email em minúsculo. Foto é opcional. Pagamento omitido vira `PIX` no servidor.

```dart
final response = await ApiClient().dio.post(
  ApiConfig.passageiros,
  data: {
    'nome': nome,
    'email': email,
    'telefone': telefone,
    'senha': senha,
  },
);
```

| HTTP | Significado |
|---|---|
| 201 | passageiro criado (`id`, `nome`, `email`, `telefone`, `tipo`) |
| 400 | validação (telefone, senha, email duplicado, etc.) |

Senha: mínimo 8 caracteres, com letras e números. Depois do 201 o app volta para o login.

### Listar passageiros

```dart
final response = await ApiClient().dio.get(ApiConfig.passageiros);
// 200 lista JSON, ou 204 se vazio
```

Outras rotas no Swagger: `/mototaxistas`, `/corridas-passageiro`, `/corrida-frete`, `/chat`, `/mensagem`, `/denuncias`, `/avaliacoes-mototaxista`.

## 3. Se não conectar

- API no ar? https://routepires.otavio.win/actuator/health/liveness
- Sem header de senha. Sem CSRF neste ambiente.
- Flutter web só tem CORS para `http://localhost:*` (e `127.0.0.1`).
- Só se o `.win` estiver fora: `flutter run --dart-define=API_BASE_URL=...` (sem barra no final).
