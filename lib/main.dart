import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/viewmodel/cadastro_passageiro_viewmodel.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';
import 'package:route_pires_flutter/viewmodel/mototaxista_viewmodel.dart';
import 'package:route_pires_flutter/views/login_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => MototaxistaViewModel()),
        ChangeNotifierProvider(create: (_) => CadastroPassageiroViewModel()),
      ],
      child: const MeuApp(),
    ),
  );
}

class MeuApp extends StatelessWidget {
  const MeuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,

      theme: CupertinoThemeData(
        primaryColor: CupertinoColors.systemBlue,
        textTheme: CupertinoTextThemeData(textStyle: GoogleFonts.inter()),
      ),

      home: const LoginPage(),
    );
  }
}
