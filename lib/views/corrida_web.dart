import 'package:flutter/cupertino.dart';
import 'package:route_pires_flutter/model/solicitacao_corrida.dart';
import 'package:route_pires_flutter/viewmodel/solicitacoes_viewmodel.dart';
import 'package:route_pires_flutter/views/lista_passageiros.dart';

/// No navegador, mantém as solicitações e mudanças de status sem carregar a
/// SDK de navegação nativa.
class Corrida extends StatefulWidget {
  const Corrida({super.key, required this.onTituloChanged, this.mototaxistaId});

  final ValueChanged<String> onTituloChanged;
  final String? mototaxistaId;

  @override
  State<Corrida> createState() => _CorridaWebState();
}

class _CorridaWebState extends State<Corrida> {
  SolicitacoesViewModel? _viewModel;
  SolicitacaoCorrida? _selecionada;

  @override
  void initState() {
    super.initState();
    final id = widget.mototaxistaId;
    if (id != null && id.isNotEmpty) {
      _viewModel = SolicitacoesViewModel(mototaxistaId: id)
        ..addListener(_atualizar)
        ..carregar();
    }
  }

  void _atualizar() {
    if (mounted) setState(() {});
  }

  void _selecionar(SolicitacaoCorrida solicitacao) {
    setState(() => _selecionada = solicitacao);
    widget.onTituloChanged(
      solicitacao.ehEntrega ? 'Detalhes da Entrega' : 'Detalhes da Corrida',
    );
  }

  void _voltar() {
    setState(() => _selecionada = null);
    widget.onTituloChanged('Procurando Corrida');
  }

  Future<void> _executar(Future<bool> Function() acao) async {
    final viewModel = _viewModel;
    if (viewModel == null) return;
    final sucesso = await acao();
    if (!mounted) return;
    if (sucesso) {
      _voltar();
      await viewModel.carregar();
      return;
    }
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Erro'),
        content: Text(viewModel.erro ?? 'Não foi possível atualizar a corrida'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return const Center(
        child: Text('Faça login como mototaxista para ver solicitações.'),
      );
    }
    final selecionada = _selecionada;
    return SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: CupertinoButton(
              onPressed: viewModel.carregando ? null : viewModel.carregar,
              child: const Text('Atualizar'),
            ),
          ),
          Expanded(
            child: selecionada == null
                ? ListaPassageiros(
                    solicitacoes: viewModel.solicitacoes,
                    onPassageiroSelecionado: _selecionar,
                    carregando: viewModel.carregando,
                    erro: viewModel.erro,
                  )
                : _detalhes(selecionada, viewModel),
          ),
        ],
      ),
    );
  }

  Widget _detalhes(
    SolicitacaoCorrida solicitacao,
    SolicitacoesViewModel viewModel,
  ) {
    final emAndamento = solicitacao.status.toUpperCase() == 'ANDAMENTO';
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        CupertinoButton(
          onPressed: _voltar,
          child: const Text('Voltar às solicitações'),
        ),
        Text('Passageiro: ${solicitacao.passageiroNome}'),
        const SizedBox(height: 8),
        Text('Status: ${solicitacao.status}'),
        const SizedBox(height: 8),
        Text(
          'Origem: ${solicitacao.origem.latitude.toStringAsFixed(5)}, '
          '${solicitacao.origem.longitude.toStringAsFixed(5)}',
        ),
        const SizedBox(height: 8),
        Text(
          'Destino: ${solicitacao.destino.latitude.toStringAsFixed(5)}, '
          '${solicitacao.destino.longitude.toStringAsFixed(5)}',
        ),
        const SizedBox(height: 16),
        const Text('Navegação passo a passo disponível no aplicativo mobile.'),
        const SizedBox(height: 16),
        CupertinoButton.filled(
          onPressed: viewModel.atualizandoStatus
              ? null
              : () => _executar(
                  () => emAndamento
                      ? viewModel.finalizar(solicitacao)
                      : viewModel.aceitar(solicitacao),
                ),
          child: Text(emAndamento ? 'Finalizar corrida' : 'Iniciar corrida'),
        ),
        const SizedBox(height: 8),
        CupertinoButton(
          onPressed: viewModel.atualizandoStatus
              ? null
              : () => _executar(() => viewModel.cancelar(solicitacao)),
          child: const Text('Cancelar corrida'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _viewModel?.removeListener(_atualizar);
    _viewModel?.dispose();
    super.dispose();
  }
}
