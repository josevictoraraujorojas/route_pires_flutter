import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:route_pires_flutter/config/api_client.dart';
import 'package:route_pires_flutter/config/firebase_config.dart';
import 'package:route_pires_flutter/config/notificacoes_browser_stub.dart'
    if (dart.library.js_interop) 'package:route_pires_flutter/config/notificacoes_browser_web.dart'
    as browser;

import 'atualizacoes_service.dart';

@pragma('vm:entry-point')
Future<void> receberNotificacaoEmSegundoPlano(RemoteMessage message) async {
  if (FirebaseConfig.configurado) {
    await Firebase.initializeApp(options: FirebaseConfig.options);
  }
  // A interface sincroniza ao retomar. Alertas em background são exibidos pelo FCM.
}

class NotificacoesService extends ChangeNotifier with WidgetsBindingObserver {
  NotificacoesService._();
  static final _instance = NotificacoesService._();
  factory NotificacoesService() => _instance;
  final _atualizacoes = AtualizacoesService();
  final _locais = FlutterLocalNotificationsPlugin();
  final _vistos = <String>{};
  Future<void>? _inicio;
  Future<void> _fila = Future.value();
  CancelToken? _cancelRegistro;
  String? _usuarioId;
  String? _tokenRegistrado;
  String? _dispositivoId;
  int _geracao = 0;
  bool _firebasePronto = false;
  bool _observando = false;
  bool _semRede = false;
  bool _ativando = false;
  bool _saindo = false;
  Map<String, dynamic>? _aberturaPendente;
  void Function(Map<String, dynamic>)? onAbrir;
  VoidCallback? onAbrirCorridas;
  bool get ativo => _atualizacoes.porEventos;
  bool get ativando => _ativando;
  bool get disponivel =>
      FirebaseConfig.configurado &&
      (kIsWeb ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> inicializar() => _inicio ??= _inicializar();

  Future<void> _inicializar() async {
    if (!_observando) {
      _observando = true;
      WidgetsBinding.instance.addObserver(this);
      Connectivity().onConnectivityChanged.listen((resultados) {
        final semRede = resultados.every((r) => r == ConnectivityResult.none);
        if (_semRede && !semRede && _usuarioId != null) {
          _atualizacoes.sincronizar();
          unawaited(ativar());
        }
        _semRede = semRede;
      }, onError: (Object _) {});
    }
    if (!disponivel) return;
    try {
      await Firebase.initializeApp(options: FirebaseConfig.options)
          .timeout(const Duration(seconds: 10));
      if (!await FirebaseMessaging.instance.isSupported()) return;
      if (kIsWeb) {
        browser.ouvirAbertura(_abrir);
      } else {
        await _locais.initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('ic_notification'),
            iOS: DarwinInitializationSettings(
              requestAlertPermission: false,
              requestBadgePermission: false,
              requestSoundPermission: false,
            ),
          ),
          onDidReceiveNotificationResponse: (response) {
            try {
              _abrir(
                Map<String, dynamic>.from(
                  jsonDecode(response.payload ?? '') as Map,
                ),
              );
            } catch (_) {
              /* Alerta sem evento associado. */
            }
          },
        );
        await _locais
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(
              const AndroidNotificationChannel(
                'routepires_notificacoes',
                'Corridas e mensagens',
                importance: Importance.high,
              ),
            );
        final localInicial = await _locais.getNotificationAppLaunchDetails();
        if (localInicial?.didNotificationLaunchApp == true) {
          final payload = localInicial?.notificationResponse?.payload;
          if (payload != null) {
            _abrir(Map<String, dynamic>.from(jsonDecode(payload) as Map));
          }
        }
      }
      _firebasePronto = true;
      FirebaseMessaging.onBackgroundMessage(receberNotificacaoEmSegundoPlano);
      FirebaseMessaging.onMessage.listen((message) => _receber(message));
      FirebaseMessaging.onMessageOpenedApp.listen(
        (message) => _receber(message, abrir: true),
      );
      // O backend atual (firebase-admin 9.2) recebe tokens de registro FCM.
      // ignore: deprecated_member_use
      FirebaseMessaging.instance.onTokenRefresh.listen(
        (_) => unawaited(ativar()),
      );
      final inicial = await FirebaseMessaging.instance.getInitialMessage();
      if (inicial != null) _receber(inicial, abrir: true);
    } catch (_) {
      if (!_firebasePronto) _inicio = null;
      debugPrint('Não foi possível inicializar as notificações.');
    }
  }

  void definirUsuario(String? id) {
    if (id == _usuarioId) return;
    if (id == null) {
      unawaited(encerrarSessao());
      return;
    }
    _geracao++;
    _cancelRegistro?.cancel();
    _usuarioId = id;
    _atualizacoes.usuarioId = id;
    _tokenRegistrado = null;
    _dispositivoId = null;
    _vistos.clear();
    _atualizacoes.definirRecebimento(false);
    unawaited(ativar());
    _abrirPendente();
  }

  Future<void> ativar() {
    if (_saindo) return Future.value();
    final usuario = _usuarioId;
    final geracao = _geracao;
    _fila = _fila.then((_) => _registrar(usuario, geracao)).catchError((
      Object _,
    ) {
      debugPrint('Não foi possível ativar as notificações.');
    });
    return _fila;
  }

  Future<void> _registrar(String? usuario, int geracao) async {
    await inicializar();
    if (!_firebasePronto || usuario == null || geracao != _geracao) return;
    _ativando = true;
    notifyListeners();
    try {
      final messaging = FirebaseMessaging.instance;
      final permissao = await messaging.requestPermission();
      if (permissao.authorizationStatus != AuthorizationStatus.authorized &&
          permissao.authorizationStatus != AuthorizationStatus.provisional) {
        if (geracao == _geracao) _atualizacoes.definirRecebimento(false);
        return;
      }
      if (kIsWeb && FirebaseConfig.vapidKey.isEmpty) return;
      // Compatibilidade com o contrato /dispositivos da API atual.
      // ignore: deprecated_member_use
      final token = await messaging
          // ignore: deprecated_member_use
          .getToken(
            vapidKey: kIsWeb ? FirebaseConfig.vapidKey : null,
            serviceWorkerScriptPath: kIsWeb ? FirebaseConfig.workerUrl : null,
          )
          .timeout(const Duration(seconds: 10));
      if (geracao != _geracao) return;
      if (token == null) {
        _atualizacoes.definirRecebimento(false);
        return;
      }
      if (token == _tokenRegistrado && _dispositivoId != null) {
        _atualizacoes.definirRecebimento(true);
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      if (geracao != _geracao) return;
      _cancelRegistro = CancelToken();
      final response = await ApiClient().dio.post(
        '/dispositivos',
        data: {
          'token': token,
          'plataforma': kIsWeb
              ? 'WEB'
              : defaultTargetPlatform == TargetPlatform.iOS
              ? 'IOS'
              : 'ANDROID',
          if (prefs.getString('fcm_usuario') == usuario &&
              prefs.getString('fcm_dispositivo') != null)
            'substituirId': prefs.getString('fcm_dispositivo'),
        },
        cancelToken: _cancelRegistro,
      );
      if (geracao != _geracao) return;
      final id = (response.data as Map)['id']?.toString();
      if (id == null || !RegExp(r'^[a-f0-9]{64}$').hasMatch(id)) return;
      await prefs.setString('fcm_usuario', usuario);
      await prefs.setString('fcm_dispositivo', id);
      if (geracao != _geracao) return;
      _dispositivoId = id;
      _tokenRegistrado = token;
      _atualizacoes.definirRecebimento(true);
    } catch (_) {
      if (geracao == _geracao) _atualizacoes.definirRecebimento(false);
      debugPrint('Notificações aguardam configuração ou conexão com a API.');
    } finally {
      _ativando = false;
      notifyListeners();
    }
  }

  /// Deve ser chamado antes de limpar JWT/cookie.
  Future<void> desvincular() async {
    final usuario = _usuarioId;
    final id = _dispositivoId;
    _geracao++;
    _saindo = true;
    _cancelRegistro?.cancel();
    try {
      if (usuario != null) {
        final prefs = await SharedPreferences.getInstance();
        final registro =
            id ??
            (prefs.getString('fcm_usuario') == usuario
                ? prefs.getString('fcm_dispositivo')
                : null);
        if (registro != null) {
          try {
            await ApiClient().dio.delete(
              '/dispositivos/$registro',
              options: Options(receiveTimeout: const Duration(seconds: 5)),
            );
          } on DioException catch (e) {
            if (![401, 403, 404].contains(e.response?.statusCode)) rethrow;
          }
        }
      }
      unawaited(encerrarSessao());
    } finally {
      _saindo = false;
    }
  }

  Future<void> encerrarSessao() {
    _geracao++;
    _cancelRegistro?.cancel();
    _usuarioId = null;
    _atualizacoes.usuarioId = null;
    _tokenRegistrado = null;
    _dispositivoId = null;
    _aberturaPendente = null;
    _vistos.clear();
    _atualizacoes.definirRecebimento(false);
    _fila = _fila.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('fcm_usuario');
        await prefs.remove('fcm_dispositivo');
        if (_firebasePronto) {
          if (!kIsWeb) await _locais.cancelAll();
          // A API atual utiliza tokens de registro; migrar junto com o backend.
          // ignore: deprecated_member_use
          await FirebaseMessaging.instance.deleteToken();
        }
      } catch (_) {
        /* A sessão local já foi encerrada. */
      }
    });
    notifyListeners();
    return _fila;
  }

  bool _valido(Map<String, dynamic> dados) =>
      dados['versao'] == '1' &&
      dados['usuarioId'] == _usuarioId &&
      _usuarioId != null &&
      const {
        'CORRIDAS_ATUALIZADAS',
        'CHATS_ATUALIZADOS',
        'MENSAGENS_ATUALIZADAS',
      }.contains(dados['tipo']) &&
      dados.values.every((valor) => valor is String);

  void _receber(RemoteMessage message, {bool abrir = false}) {
    final dados = message.data;
    if (abrir) _abrir(dados);
    if (!_valido(dados)) return;
    final eventoId = dados['eventoId'] as String?;
    if (eventoId == null || !_vistos.add(eventoId)) return;
    if (_vistos.length > 256) _vistos.remove(_vistos.first);
    _atualizacoes.publicar(dados);
    final alerta = message.notification;
    if (abrir || alerta == null) return;
    final titulo = alerta.title ?? 'Route Pires';
    final corpo = alerta.body ?? '';
    if (kIsWeb) {
      browser.mostrarAlerta(titulo, corpo, () => _abrir(dados));
    } else {
      unawaited(
        _locais
            .show(
              id: eventoId.hashCode & 0x7fffffff,
              title: titulo,
              body: corpo,
              notificationDetails: const NotificationDetails(
                android: AndroidNotificationDetails(
                  'routepires_notificacoes',
                  'Corridas e mensagens',
                  importance: Importance.high,
                  priority: Priority.high,
                  icon: 'ic_notification',
                ),
                iOS: DarwinNotificationDetails(),
              ),
              payload: jsonEncode(dados),
            )
            .catchError((Object _) {
              debugPrint('Não foi possível apresentar o alerta.');
            }),
      );
    }
  }

  void _abrir(Map<String, dynamic> dados) {
    _aberturaPendente = dados;
    _abrirPendente();
  }

  void _abrirPendente() {
    final dados = _aberturaPendente;
    if (dados == null || _usuarioId == null) return;
    _aberturaPendente = null;
    if (_valido(dados)) {
      _atualizacoes.publicar(dados);
      onAbrir?.call(dados);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _atualizacoes.appAtivo = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed && _usuarioId != null) {
      _atualizacoes.sincronizar();
      unawaited(ativar());
    }
  }
}
