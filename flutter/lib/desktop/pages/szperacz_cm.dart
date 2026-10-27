// Szperacz (240–244): okno akceptacji połączenia u klienta i małe okienko
// „ŁĄCZY SIĘ … ROZŁĄCZ” w prawym dolnym rogu. Zastępuje panel CM RustDeska.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart' hide Dialog;
import 'package:flutter_hbb/desktop/pages/szperacz.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:window_manager/window_manager.dart';

class SzperaczCm extends StatefulWidget {
  final ServerModel model;
  const SzperaczCm({Key? key, required this.model}) : super(key: key);

  @override
  State<SzperaczCm> createState() => _SzperaczCmState();
}

class _SzperaczCmState extends State<SzperaczCm> {
  static const _rozmiarAkceptacji = Size(440, 400);
  static const _szerokoscMalego = 300.0;

  final _poczatek = <int, DateTime>{};
  final _klikniete = <int>{};
  String _tryb = '';
  Timer? _zegar;

  @override
  void initState() {
    super.initState();
    _zegar = Timer.periodic(Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
      szperaczZapiszSesje(_aktywni.length);
    });
  }

  @override
  void dispose() {
    _zegar?.cancel();
    szperaczZapiszSesje(0);
    super.dispose();
  }

  List<Client> get _oczekujacy => widget.model.clients
      .where((c) => !c.authorized && !c.disconnected)
      .toList();
  List<Client> get _aktywni =>
      widget.model.clients.where((c) => c.authorized && !c.disconnected).toList();

  /// Ustawienie okna przy zmianie trybu (akceptacja / małe okienko).
  void _ustawOkno(String tryb, int ile) {
    final klucz = '$tryb$ile';
    if (klucz == _tryb) return;
    _tryb = klucz;
    // Z opóźnieniem: showCmWindow() ustawia swój rozmiar asynchronicznie.
    Future.delayed(Duration(milliseconds: 800), () async {
      try {
        if (tryb == 'akceptacja') {
          await windowManager.setAlwaysOnTop(false);
          await windowManager.setSize(_rozmiarAkceptacji);
          await windowManager.center();
          await windowManager.restore();
          await windowManager.show();
          await windowManager.focus();
        } else if (tryb == 'male') {
          final wys = 58.0 + 66.0 * ile;
          await windowManager.setSize(Size(_szerokoscMalego, wys));
          await windowManager.setAlignment(Alignment.bottomRight);
          await windowManager.restore();
          await windowManager.show();
          await windowManager.setAlwaysOnTop(true);
        }
      } catch (_) {}
    });
  }

  void _akceptuj(Client c, {bool administrator = false}) {
    if (!_klikniete.add(c.id)) return;
    widget.model.sendLoginResponse(c, true);
    if (administrator && bind.cmCanElevate()) {
      widget.model.setShowElevation(false);
      bind.cmElevatePortable(connId: c.id);
    }
  }

  void _rozlacz(Client c) => bind.cmCloseConnection(connId: c.id);

  String _kto(Client c) {
    final n = c.name.trim();
    return n.isEmpty ? c.peerId : '$n (${c.peerId})';
  }

  String _czas(Client c) {
    final p = _poczatek.putIfAbsent(c.id, () => DateTime.now());
    final s = DateTime.now().difference(p).inSeconds;
    String dw(int x) => x.toString().padLeft(2, '0');
    return s >= 3600
        ? '${s ~/ 3600}:${dw(s % 3600 ~/ 60)}:${dw(s % 60)}'
        : '${dw(s ~/ 60)}:${dw(s % 60)}';
  }

  @override
  Widget build(BuildContext context) {
    // Rozłączone wpisy sprzątamy od razu — u klienta nie ma czego oglądać.
    for (final c in widget.model.clients.where((c) => c.disconnected)) {
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => bind.cmRemoveDisconnectedConnection(connId: c.id));
    }
    final oczekujacy = _oczekujacy;
    final aktywni = _aktywni;
    if (oczekujacy.isNotEmpty) {
      _ustawOkno('akceptacja', 1);
      return _akceptacja(oczekujacy.first);
    }
    if (aktywni.isNotEmpty) {
      _ustawOkno('male', aktywni.length);
      return _male(aktywni);
    }
    return SzperaczTlo(child: SizedBox.expand());
  }

  // 240.x: kto się łączy + AKCEPTUJ / ODRZUĆ / AKCEPTUJ JAKO ADMINISTRATOR.
  Widget _akceptacja(Client c) {
    return SzperaczTlo(
      child: DragToMoveArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(38),
            child: SzperaczOkno(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Napis3D('POŁĄCZENIE', rozmiar: 22),
                  szperaczEtykieta('ŁĄCZY SIĘ Z TOBĄ SERWISANT'),
                  SizedBox(height: 8),
                  Text(_kto(c),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontFamily: 'SzperaczMono',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: sk(0xFFFFF3D6))),
                  SizedBox(height: 14),
                  Klawisz3D(
                    tekst: 'AKCEPTUJ JAKO ADMINISTRATOR',
                    ikona: Icons.security_rounded,
                    rodzaj: RodzajKlawisza.zloty,
                    onTap: () => _akceptuj(c, administrator: true),
                  ),
                  SizedBox(height: 4),
                  Row(children: [
                    Expanded(
                      child: Klawisz3D(
                          tekst: 'AKCEPTUJ',
                          ikona: Icons.check_rounded,
                          onTap: () => _akceptuj(c)),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Klawisz3D(
                          tekst: 'ODRZUĆ',
                          ikona: Icons.close_rounded,
                          rodzaj: RodzajKlawisza.czerwony,
                          onTap: () => _rozlacz(c)),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 241.x / 244.2: małe okienko z listą połączeń, czasem i ROZŁĄCZ.
  Widget _male(List<Client> aktywni) {
    return DragToMoveArea(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: sk(0xFFC9A227), width: 3),
          image: szperaczTekstura(),
                color: szperaczKolorOkna(),
        ),
        padding: EdgeInsets.fromLTRB(10, 6, 10, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            szperaczEtykieta('★ SZPERACZ · POMOC ZDALNA ★'),
            SizedBox(height: 6),
            for (final c in aktywni)
              SizedBox(
                height: 62,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('ŁĄCZY SIĘ: ${_kto(c)}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontFamily: 'SzperaczSlab',
                                  fontSize: 10,
                                  color: sk(0xFFF0D9A8))),
                          SizedBox(height: 2),
                          Text(_czas(c),
                              style: TextStyle(
                                  fontFamily: 'SzperaczMono',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: sk(0xFFFFF3D6))),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 104,
                      child: Klawisz3D(
                        tekst: 'ROZŁĄCZ',
                        ikona: Icons.call_end_rounded,
                        rodzaj: RodzajKlawisza.czerwony,
                        wysokosc: 32,
                        onTap: () => _rozlacz(c),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
