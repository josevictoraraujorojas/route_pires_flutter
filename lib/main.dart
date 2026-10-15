import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/config/url_strategy_stub.dart'
    if (dart.library.js_interop) 'package:route_pires_flutter/config/url_strategy_web.dart'
    as url_strategy;
import 'package:route_pires_flutter/viewmodel/cadastro_passageiro_viewmodel.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';
import 'package:route_pires_flutter/viewmodel/mototaxista_viewmodel.dart';
import 'package:route_pires_flutter/views/login_page.dart';
import 'package:route_pires_flutter/views/principal_page_mototaxista.dart';
import 'package:route_pires_flutter/views/principal_page_passageiro.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  url_strategy.configureUrlStrategy();
  final loginViewModel = LoginViewModel();
  final navigatorKey = GlobalKey<NavigatorState>();
  bindSessionNavigator(loginViewModel, navigatorKey);
  ApiClient().onUnauthorized = loginViewModel.invalidarSessao;
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: loginViewModel),
        ChangeNotifierProvider(create: (_) => MototaxistaViewModel()),
        ChangeNotifierProvider(create: (_) => CadastroPassageiroViewModel()),
      ],
      child: MeuApp(navigatorKey: navigatorKey),
    ),
  );
}

void bindSessionNavigator(
  LoginViewModel loginViewModel,
  GlobalKey<NavigatorState> navigatorKey,
) {
  loginViewModel.onSessionEnded = () {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigatorKey.currentState?.popUntil((route) => route.isFirst);
    });
  };
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key, this.navigatorKey});

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,

      theme: CupertinoThemeData(
        brightness: Brightness.light,
        primaryColor: CupertinoColors.systemBlue,
        scaffoldBackgroundColor: CupertinoColors.white,
        barBackgroundColor: CupertinoColors.white,
        textTheme: CupertinoTextThemeData(
          textStyle: GoogleFonts.inter(color: const Color(0xFF1F2024)),
        ),
      ),
      home: const _SessionGate(),
    );
  }
}

class _SessionGate extends StatelessWidget {
  const _SessionGate();

  @override
  Widget build(BuildContext context) {
    final login = context.watch<LoginViewModel>();
    if (login.inicializando) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (login.erroInicializacao case final erro?) {
      return CupertinoPageScaffold(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(erro),
              CupertinoButton(
                onPressed: login.carregarUsuarioSalvo,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return switch (login.usuario?.tipo) {
      'PASSAGEIRO' => const PrincipalPagePassageiro(),
      'MOTOTAXISTA' => const PrincipalPageMototaxista(),
      _ => const LoginPage(),
    };
  }
}
