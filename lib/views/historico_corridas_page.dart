import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:route_pires_flutter/viewmodel/login_viewmodel.dart';
import 'package:route_pires_flutter/viewmodel/historico_corridas_viewmodel.dart';

class HistoricoCorridasPage extends StatefulWidget {
  const HistoricoCorridasPage({super.key});

  @override
  State<HistoricoCorridasPage> createState() => _HistoricoCorridasPageState();
}

class _HistoricoCorridasPageState extends State<HistoricoCorridasPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final usuario = context.read<LoginViewModel>().usuario;
      if (usuario != null) {
        context.read<HistoricoCorridasViewModel>().carregarHistoricoInicial(usuario.id);
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 50) {
        final usuario = context.read<LoginViewModel>().usuario;
        if (usuario != null) {
          context.read<HistoricoCorridasViewModel>().carregarMaisHistorico(usuario.id);
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatarData(DateTime? data) {
    if (data == null) return 'Data não disponível';
    return DateFormat('dd/MM/yyyy HH:mm').format(data.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HistoricoCorridasViewModel>();

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.white,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: CupertinoColors.white,
        previousPageTitle: 'Voltar',
        middle: Text('Histórico de Corridas', style: TextStyle(fontWeight: FontWeight.w400)),
        border: null,
      ),
      child: SafeArea(
        child: _buildBody(viewModel),
      ),
    );
  }

  Widget _buildBody(HistoricoCorridasViewModel viewModel) {
    if (viewModel.carregando) {
      return const Center(child: CupertinoActivityIndicator(radius: 16));
    }

    if (viewModel.erro != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(CupertinoIcons.exclamationmark_triangle, size: 40, color: CupertinoColors.systemGrey),
            const SizedBox(height: 12),
            Text(viewModel.erro!, style: const TextStyle(color: CupertinoColors.systemGrey)),
            CupertinoButton(
              child: const Text('Tentar novamente'),
              onPressed: () {
                final usuario = context.read<LoginViewModel>().usuario;
                if (usuario != null) {
                  viewModel.carregarHistoricoInicial(usuario.id);
                }
              },
            ),
          ],
        ),
      );
    }

    if (viewModel.corridas.isEmpty) {
      return const Center(
        child: Text(
          'Você ainda não possui corridas finalizadas ou canceladas.',
          style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ListView.separated(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      itemCount: viewModel.corridas.length + (viewModel.carregandoMais ? 1 : 0),
      separatorBuilder: (context, index) => Container(
        height: 1,
        color: CupertinoColors.systemGrey5,
        margin: const EdgeInsets.symmetric(vertical: 12),
      ),
      itemBuilder: (context, index) {
        if (index == viewModel.corridas.length) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: CupertinoActivityIndicator(),
          );
        }

        final solicitacao = viewModel.corridas[index];
        
        final nome = viewModel.getNomeMototaxista(solicitacao.mototaxistaId);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatarData(solicitacao.dataHoraSolicitacao),
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  // Mostramos o status real que veio do banco (FINALIZADO, CANCELADO, etc)
                  solicitacao.status,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: solicitacao.status == 'CANCELADO' || solicitacao.status == 'CANCELADA'
                        ? CupertinoColors.systemRed
                        : CupertinoColors.systemGreen,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}