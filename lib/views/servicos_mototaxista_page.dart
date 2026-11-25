import 'package:flutter/cupertino.dart';
import 'package:route_pires_flutter/repositories/mototaxista_repository.dart';
import 'package:route_pires_flutter/views/seletor_servicos.dart';

class ServicosMototaxistaPage extends StatefulWidget {
  const ServicosMototaxistaPage({
    super.key,
    required this.mototaxistaId,
  });

  final String mototaxistaId;

  @override
  State<ServicosMototaxistaPage> createState() =>
      _ServicosMototaxistaPageState();
}

class _ServicosMototaxistaPageState extends State<ServicosMototaxistaPage> {
  final MototaxistaRepository _repository = MototaxistaRepository();
  Set<String> _selecionados = <String>{};
  bool _carregando = true;
  bool _salvando = false;
  bool _falhouCarregamento = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _falhouCarregamento = false;
      _erro = null;
    });
    try {
      final servicos = await _repository.buscarServicosOferecidos(
        id: widget.mototaxistaId,
      );
      if (!mounted) return;
      setState(() {
        // Mantém serviços adicionais eventualmente presentes no backend.
        _selecionados = servicos;
        _carregando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregando = false;
        _falhouCarregamento = true;
        _erro = 'Não foi possível carregar os serviços oferecidos.';
      });
    }
  }

  Future<void> _salvar() async {
    if (_salvando || _carregando) return;
    final temServicoVisivel = _selecionados.contains(
          ServicosMototaxista.transportePassageiro,
        ) ||
        _selecionados.contains(ServicosMototaxista.frete);
    if (!temServicoVisivel) {
      setState(() => _erro = 'Selecione pelo menos um serviço.');
      return;
    }
    setState(() {
      _salvando = true;
      _erro = null;
    });
    try {
      await _repository.atualizarServicosOferecidos(
        id: widget.mototaxistaId,
        servicos: _selecionados,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _erro = 'Não foi possível salvar os serviços.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Serviços oferecidos'),
      ),
      child: SafeArea(
        child: _carregando
            ? const Center(child: CupertinoActivityIndicator())
            : _falhouCarregamento
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_erro!, textAlign: TextAlign.center),
                          CupertinoButton(
                            onPressed: _carregar,
                            child: const Text('Tentar novamente'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      SeletorServicos(
                        selecionados: _selecionados,
                        habilitado: !_salvando,
                        onChanged: (novos) => setState(() {
                          _selecionados = novos;
                          _erro = null;
                        }),
                      ),
                      if (_erro != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _erro!,
                          style: const TextStyle(color: CupertinoColors.systemRed),
                        ),
                      ],
                      const SizedBox(height: 24),
                      CupertinoButton.filled(
                        onPressed: _salvando ? null : _salvar,
                        child: _salvando
                            ? const CupertinoActivityIndicator(
                                color: CupertinoColors.white,
                              )
                            : const Text('Salvar serviços'),
                      ),
                    ],
                  ),
      ),
    );
  }
}
