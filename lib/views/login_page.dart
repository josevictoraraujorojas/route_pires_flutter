import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController senhaController = TextEditingController();

  bool isObscureText = true;

  @override
  void dispose() {
    emailController.dispose();
    senhaController.dispose();
    super.dispose();
  }

  Future<void> realizarLogin() async {
    final loginViewModel = context.read<LoginViewModel>();

    final requisicao = await loginViewModel.realizarLogin(
      email: emailController.text.trim(),
      senha: senhaController.text.trim(),
    );

    if (!mounted) return;

    if (requisicao) {
      final usuario = loginViewModel.usuario;

      if (usuario?.tipo == "PASSAGEIRO") {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text("Login realizado Passageiro!"),
            content: Text("Bem-vindo, ${usuario?.nome}!"),
            actions: [
              CupertinoDialogAction(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      } else {
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text("Login realizado! Mototaxista"),
            content: Text("Bem-vindo, ${usuario?.nome}!"),
            actions: [
              CupertinoDialogAction(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      }
    } else {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text("Erro"),
          content: Text(loginViewModel.erro ?? 'Erro ao realizar login'),
          actions: [
            CupertinoDialogAction(
              child: const Text("OK"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loginViewModel = context.watch<LoginViewModel>();

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFFFFFFFF),

      child: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          physics: ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.only(top: 40),
                width: double.infinity,
                color: const Color(0xFFEAF2FF),
                child: Row(
                  children: [
                    const Expanded(child: SizedBox()),

                    Expanded(
                      flex: 9,
                      child: Image.asset("assets/images/logo.png"),
                    ),

                    const Expanded(child: SizedBox()),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Column(
                children: [
                  Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 24),
                    child: const Text(
                      "Bem-vindo!",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF000000),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height * 0.06,
                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),

                          child: CupertinoTextField(
                            controller: emailController,

                            keyboardType: TextInputType.emailAddress,

                            style: const TextStyle(color: Color(0xFF1F2024)),

                            placeholder: "Email",

                            placeholderStyle: const TextStyle(
                              color: Color(0xFF8F9098),
                            ),

                            padding: const EdgeInsets.all(15),

                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFFC5C6CC)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // SENHA
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),

                          child: CupertinoTextField(
                            controller: senhaController,

                            obscureText: isObscureText,

                            style: const TextStyle(color: Color(0xFF1F2024)),

                            placeholder: "Senha",

                            placeholderStyle: const TextStyle(
                              color: Color(0xFF8F9098),
                            ),

                            suffix: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isObscureText = !isObscureText;
                                });
                              },

                              child: Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Icon(
                                  isObscureText
                                      ? CupertinoIcons.eye_slash_fill
                                      : CupertinoIcons.eye_fill,
                                  color: Color(0xFF8F9098),
                                ),
                              ),
                            ),

                            padding: const EdgeInsets.all(15),

                            decoration: BoxDecoration(
                              border: Border.all(color: Color(0xFFC5C6CC)),

                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Container(
                          width: double.infinity,
                          margin: EdgeInsets.symmetric(horizontal: 24),
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            alignment: Alignment.centerLeft,
                            onPressed: () {},
                            child: Text(
                              "Esqueceu sua senha?",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF006FFD),
                              ),
                            ),
                          ),
                        ),

                        // BOTÃO LOGIN
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(
                            left: 24,
                            right: 24,
                            top: 24,
                            bottom: 16,
                          ),
                          child: CupertinoButton(
                            color: const Color(0xFF006FFD),
                            borderRadius: BorderRadius.circular(10),

                            onPressed: loginViewModel.isLoading
                                ? null
                                : realizarLogin,

                            child: loginViewModel.isLoading
                                ? const CupertinoActivityIndicator(
                                    color: CupertinoColors.white,
                                  )
                                : const Text(
                                    "Login",
                                    style: TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Não é membro?",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF71727A),
                                ),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                alignment: Alignment.centerLeft,
                                onPressed: () {},
                                child: Text(
                                  " Registre-se agora",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF006FFD),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Divider(color: Color(0xFFC5C6CC), thickness: 1),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
