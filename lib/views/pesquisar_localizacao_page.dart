import 'package:flutter/cupertino.dart';
import 'package:route_pires_flutter/views/botao_primario.dart';
import 'package:route_pires_flutter/views/mapa_corrida_mock.dart';
import 'package:route_pires_flutter/views/rodape_navegacao.dart';

class PesquisarLocalizacaoPage extends StatefulWidget {
  const PesquisarLocalizacaoPage({super.key, this.valorInicial});

  final String? valorInicial;

  @override
  State<PesquisarLocalizacaoPage> createState() =>
      _PesquisarLocalizacaoPageState();
}

class _PesquisarLocalizacaoPageState extends State<PesquisarLocalizacaoPage> {
  static const enderecos = [
    'Rua Exemplo - Setor Exemplo',
    'Rua Exemplo Filho Neto',
    'Rua Exp - Centro',
    'Rua Inicial - Setor Universitário',
    'Rua Final - Centro',
  ];

  late final TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.valorInicial);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void selecionar(String endereco) => Navigator.pop(context, endereco);

  @override
  Widget build(BuildContext context) {
    final termo = controller.text.trim().toLowerCase();
    final sugestoes = termo.isEmpty
        ? <String>[]
        : enderecos
              .where((endereco) => endereco.toLowerCase().contains(termo))
              .toList();

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        middle: Text(
          'Pesquisar Localização',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: CupertinoSearchTextField(
                controller: controller,
                autofocus: true,
                placeholder: 'Rua Exemplo',
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (sugestoes.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sugestoes.length,
                  itemBuilder: (context, index) {
                    final endereco = sugestoes[index];
                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      onPressed: () => selecionar(endereco),
                      child: Row(
                        children: [
                          const Icon(
                            CupertinoIcons.location_solid,
                            color: Color(0xFFFF3B4E),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              endereco,
                              style: const TextStyle(
                                color: Color(0xFF1F2024),
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            else ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Text(
                  'Selecionar Localização',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: MapaCorridaMock(
                    onTap: (ponto) => selecionar(
                      '${ponto.latitude.toStringAsFixed(6)}, '
                      '${ponto.longitude.toStringAsFixed(6)}',
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: BotaoPrimario(
                  texto: 'Selecionar este local',
                  onPressed: () => selecionar('Local selecionado no mapa'),
                ),
              ),
              const RodapeNavegacao(),
            ],
          ],
        ),
      ),
    );
  }
}
