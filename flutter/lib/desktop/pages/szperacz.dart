// Szperacz (MINITEL): wszystkie okna w stylu „rdzawe okno 3D na zielonym tle” (200.x).
// Wzór: podglądy zaakceptowane 20.10.2026 (okno klienta = podgląd 9, komplet = podgląd 24/25).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart' hide Dialog;
import 'package:flutter_hbb/consts.dart' show kWindowMainId;
import 'package:flutter_hbb/main.dart' show kWindowId;
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/utils/multi_window_manager.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

/// Wybrany tryb: null = ekran wyboru, 'klient' = ktoś łączy się ze mną, 'operator' = łączę się z kimś.
final szperaczTryb = RxnString();

/// Wersja Szperacza (141.x). SZPERACZ_BUDOWA podmienia workflow GitHub Actions
/// na numer budowy, datę i skrót commita; przy budowie lokalnej zostaje „lokalna”.
const szperaczWersja = '0.11.0';
const szperaczBudowa = 'SZPERACZ_BUDOWA';

/// Napis z wersją do stopek okien.
String get szperaczOpisWersji =>
    szperaczBudowa == 'SZPERACZ_' 'BUDOWA'
        ? 'wersja $szperaczWersja · budowa lokalna'
        : 'wersja $szperaczWersja · budowa $szperaczBudowa';

// ───────────────────────────── kolory ─────────────────────────────

class _K {
  static const butelkaCiemna = Color(0xFF04190F);
  static const butelka = Color(0xFF0B3A24);
  static const butelkaJasna = Color(0xFF17603C);
  static const refleks = Color(0xFF2E8A5C);
  static const krem = Color(0xFFF3E7C9);
  static const kremJasny = Color(0xFFFFF3D6);
  static const napis = Color(0xFFF0D9A8);
  static const opis = Color(0xFFEAD7B0);
  static const zloto = Color(0xFFC9A227);
  static const zlotoJasne = Color(0xFFF2D77A);
  static const zlotoBlysk = Color(0xFFFBE8A0);
  static const zlotoSrednie = Color(0xFFE0BC45);
  static const zlotoCiemne = Color(0xFF8C6D12);
  static const zlotoBraz = Color(0xFF5E4709);
  static const zlotoCien = Color(0xFF3A2A06);
  static const tusz = Color(0xFF2A170C);
  static const czerwien = Color(0xFF9E1B1B);
  // Tekst wpisywany w pola — w kolorze złotej ramki (ciemniejszy odcień, czytelny na kremie).
  static const wpis = Color(0xFFA58219);
}

/// Warstwy wytłoczenia napisów 3D (od góry do dołu).
const _warstwy = [
  Color(0xFFE8D39A),
  Color(0xFFD9BC5C),
  Color(0xFFC9A227),
  Color(0xFFA58219),
  Color(0xFF7C5F10),
  Color(0xFF4F3B08),
];

const _gradientZloty = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [_K.zlotoBlysk, _K.zlotoSrednie, _K.zloto, _K.zlotoCiemne],
  stops: [0.0, 0.35, 0.6, 1.0],
);

// ───────────────────────────── tło i okno ─────────────────────────────

/// Zielone tło jak butelka (zostaje z wersji „etykieta piwa”).
class SzperaczTlo extends StatelessWidget {
  final Widget child;
  const SzperaczTlo({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _K.butelkaCiemna,
            _K.butelka,
            _K.butelkaJasna,
            _K.refleks,
            _K.butelkaJasna,
            _K.butelka,
            _K.butelkaCiemna,
          ],
          stops: [0.0, 0.22, 0.40, 0.46, 0.52, 0.75, 1.0],
        ),
      ),
      child: child,
    );
  }
}

/// Rdzawe okno 3D: złota rama, tekstura rdzy, wewnętrzna złota linia,
/// rozmyty stempel pocztowy w rogu (197.5) i wersja na dole (197.3).
class SzperaczOkno extends StatelessWidget {
  final Widget child;
  final double maxSzerokosc;
  final EdgeInsets padding;
  final bool wersja;
  final bool stempel;
  final bool wyrownajDoLewej;
  const SzperaczOkno({
    Key? key,
    required this.child,
    this.maxSzerokosc = 380,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 12),
    this.wersja = true,
    this.stempel = true,
    this.wyrownajDoLewej = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxSzerokosc),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _K.zloto, width: 4),
              image: const DecorationImage(
                image: AssetImage('assets/szperacz_rdza.png'),
                fit: BoxFit.cover,
              ),
              boxShadow: const [
                BoxShadow(color: _K.zlotoCiemne, offset: Offset(0, 3)),
                BoxShadow(color: _K.zlotoBraz, offset: Offset(0, 6)),
                BoxShadow(
                    color: Color(0xA6000000),
                    offset: Offset(0, 12),
                    blurRadius: 22),
              ],
            ),
            child: Container(
              margin: const EdgeInsets.all(7),
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: const Color(0xB3C9A227), width: 1),
                // Wewnętrzny cień — rdza „wgłębiona” w złotą ramę.
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x99000000),
                    Color(0x00000000),
                    Color(0x00000000),
                    Color(0x40000000),
                  ],
                  stops: [0.0, 0.05, 0.92, 1.0],
                ),
              ),
              child: DefaultTextStyle(
                style: const TextStyle(
                  fontFamily: 'SzperaczSerif',
                  color: _K.krem,
                  fontSize: 13,
                  shadows: [Shadow(offset: Offset(0, 1), blurRadius: 1)],
                ),
                textAlign:
                    wyrownajDoLewej ? TextAlign.left : TextAlign.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: wyrownajDoLewej
                      ? CrossAxisAlignment.stretch
                      : CrossAxisAlignment.center,
                  children: [
                    const SzperaczWstegaNowejWersji(),
                    child,
                    if (wersja) _stopkaWersji(),
                  ],
                ),
              ),
            ),
          ),
          if (stempel)
            Positioned(
              top: -26,
              right: -22,
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: 0.28,
                  child: Opacity(
                    opacity: 0.55,
                    child: Image.asset('assets/szperacz_stempel.png',
                        width: 104, height: 104),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _stopkaWersji() => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        szperaczOpisWersji,
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontFamily: 'SzperaczSerif', fontSize: 10, color: _K.opis),
      ),
    );

// ───────────────────────────── napisy ─────────────────────────────

/// Napis wytłoczony w 3D (złote warstwy pod kremowym licem).
class Napis3D extends StatelessWidget {
  final String tekst;
  final double rozmiar;
  final double odstep;
  const Napis3D(this.tekst, {Key? key, this.rozmiar = 30, this.odstep = 3})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final glebokosc = (rozmiar / 5).clamp(3.0, 7.0).round();
    TextStyle styl(Color c, {List<Shadow>? cienie}) => TextStyle(
          fontFamily: 'SzperaczSlab',
          fontSize: rozmiar,
          letterSpacing: odstep,
          color: c,
          height: 1.15,
          shadows: cienie,
        );
    return Padding(
      padding: EdgeInsets.only(bottom: glebokosc.toDouble()),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = glebokosc; i >= 1; i--)
            Transform.translate(
              offset: Offset(0, i.toDouble()),
              child: Text(
                tekst,
                textAlign: TextAlign.center,
                style: styl(
                  _warstwy[((i - 1) * (_warstwy.length - 1) / (glebokosc - 1 == 0 ? 1 : glebokosc - 1)).round()],
                  cienie: i == glebokosc
                      ? const [
                          Shadow(
                              color: Color(0xB3000000),
                              offset: Offset(0, 2),
                              blurRadius: 8)
                        ]
                      : null,
                ),
              ),
            ),
          Text(tekst,
              textAlign: TextAlign.center, style: styl(_K.kremJasny)),
        ],
      ),
    );
  }
}

/// Mały wytłoczony podpis (etykiety pól i sekcji).
Widget szperaczEtykieta(String tekst, {TextAlign align = TextAlign.center}) =>
    Text(
      tekst,
      textAlign: align,
      style: const TextStyle(
        fontFamily: 'SzperaczSlab',
        fontSize: 10,
        letterSpacing: 2,
        color: _K.napis,
        shadows: [
          Shadow(color: Color(0xFF6B4E0D), offset: Offset(0, 1)),
          Shadow(color: _K.zlotoCien, offset: Offset(0, 2)),
          Shadow(color: Color(0xCC000000), offset: Offset(0, 3), blurRadius: 3),
        ],
      ),
    );

Widget _opis(String tekst, {double rozmiar = 12}) => Text(
      tekst,
      textAlign: TextAlign.center,
      style: TextStyle(
          fontFamily: 'SzperaczSerif', fontSize: rozmiar, color: _K.opis),
    );

/// Złota wstęga 3D z „ogonami” (POMOC ZDALNA, STAŁY DOSTĘP, mój numer).
class SzperaczWstega extends StatelessWidget {
  final String tekst;
  final bool cyfry;
  const SzperaczWstega(this.tekst, {Key? key, this.cyfry = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget ogon(bool prawy) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(prawy ? -1.0 : 1.0, 1.0),
          child: ClipPath(
            clipper: _Ogon(),
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFA58219), _K.zlotoBraz],
                ),
              ),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Positioned(left: -14, top: 8, child: ogon(false)),
          Positioned(right: -14, top: 8, child: ogon(true)),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              gradient: _gradientZloty,
              boxShadow: [
                BoxShadow(color: Color(0xFF4F3B08), offset: Offset(0, 4)),
                BoxShadow(
                    color: Color(0xB3000000),
                    offset: Offset(0, 7),
                    blurRadius: 8),
              ],
            ),
            child: Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 22, vertical: cyfry ? 2 : 4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFDF5),
                    Color(0xFFF6EBD0),
                    Color(0xFFCDB383)
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
              child: Text(
                tekst,
                style: cyfry
                    ? const TextStyle(
                        fontFamily: 'SzperaczMono',
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        letterSpacing: 1,
                        color: Color(0xFF2E1B0D),
                        shadows: [])
                    : const TextStyle(
                        fontFamily: 'SzperaczSlab',
                        fontSize: 12,
                        letterSpacing: 3,
                        color: Color(0xFF2E1B0D),
                        shadows: [
                          Shadow(color: Colors.white, offset: Offset(0, 1))
                        ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Ogon extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(0, 0)
    ..lineTo(s.width, 0)
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..lineTo(s.width * 0.3, s.height / 2)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Nagłówek okien: ★ MINITEL · WROCŁAW ★, SZPERACZ 3D, wstęga.
Widget _naglowek(String wstega, {bool cyfry = false, String? podpis}) => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        szperaczEtykieta('★ MINITEL · WROCŁAW ★'),
        const SizedBox(height: 2),
        const Napis3D('SZPERACZ', rozmiar: 30),
        SzperaczWstega(wstega, cyfry: cyfry),
        if (podpis != null) ...[
          szperaczEtykieta(podpis),
          const SizedBox(height: 10),
        ],
      ],
    );

// ───────────────────────────── przyciski ─────────────────────────────

enum RodzajKlawisza { zielony, czerwony, zloty, ciemny }

/// Wypukły przycisk 3D (połysk u góry, gruba podstawa, „wciska się” przy kliknięciu).
class Klawisz3D extends StatefulWidget {
  final String tekst;
  final IconData? ikona;
  final RodzajKlawisza rodzaj;
  final VoidCallback onTap;
  final double wysokosc;
  final double rozmiarNapisu;
  final bool doLewej;
  final bool aktywny;
  final String? podpowiedz;
  const Klawisz3D({
    Key? key,
    required this.tekst,
    required this.onTap,
    this.ikona,
    this.rodzaj = RodzajKlawisza.zielony,
    this.wysokosc = 34,
    this.rozmiarNapisu = 10,
    this.doLewej = false,
    this.aktywny = false,
    this.podpowiedz,
  }) : super(key: key);

  @override
  State<Klawisz3D> createState() => _Klawisz3DState();
}

class _Klawisz3DState extends State<Klawisz3D> {
  bool _wcisniety = false;
  bool _najechany = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.aktywny ? RodzajKlawisza.zloty : widget.rodzaj;
    late final List<Color> g;
    late final Color podstawa1, podstawa2, napis;
    switch (r) {
      case RodzajKlawisza.zielony:
        g = const [
          Color(0xFF5CC08A),
          Color(0xFF1F8A50),
          Color(0xFF0B5A33),
          Color(0xFF053A1D)
        ];
        podstawa1 = const Color(0xFF02200F);
        podstawa2 = const Color(0xFF011208);
        napis = Colors.white;
        break;
      case RodzajKlawisza.czerwony:
        g = const [
          Color(0xFFF07070),
          Color(0xFFC02C2C),
          Color(0xFF9E1B1B),
          Color(0xFF5E0B0B)
        ];
        podstawa1 = const Color(0xFF4A0A0A);
        podstawa2 = const Color(0xFF2A0505);
        napis = Colors.white;
        break;
      case RodzajKlawisza.zloty:
        g = const [_K.zlotoJasne, _K.zloto, _K.zlotoCiemne, _K.zlotoBraz];
        podstawa1 = const Color(0xFF3E2A05);
        podstawa2 = const Color(0xFF241802);
        napis = const Color(0xFF2E1B0D);
        break;
      case RodzajKlawisza.ciemny:
        g = const [
          Color(0xFF3A2716),
          Color(0xFF1F140A),
          Color(0xFF140C06),
          Color(0xFF080402)
        ];
        podstawa1 = const Color(0xFF050301);
        podstawa2 = Colors.black;
        napis = const Color(0xFFF6E9C8);
        break;
    }
    final przesuniecie = _wcisniety ? 4.0 : 0.0;
    final tresc = Row(
      mainAxisAlignment:
          widget.doLewej ? MainAxisAlignment.start : MainAxisAlignment.center,
      children: [
        if (widget.ikona != null) ...[
          Icon(widget.ikona,
              size: widget.rozmiarNapisu + 5,
              color: r == RodzajKlawisza.ciemny ? _K.zlotoJasne : napis),
          if (widget.tekst.isNotEmpty) const SizedBox(width: 6),
        ],
        if (widget.tekst.isNotEmpty)
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.tekst,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontFamily: 'SzperaczSlab',
                  fontSize: widget.rozmiarNapisu,
                  letterSpacing: 0.5,
                  color: napis,
                  shadows: [
                    Shadow(
                        color: r == RodzajKlawisza.zloty
                            ? const Color(0x80FFFFFF)
                            : const Color(0x99000000),
                        offset: Offset(0, r == RodzajKlawisza.zloty ? 1 : -1)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
    final przycisk = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _najechany = true),
      onExit: (_) => setState(() {
        _najechany = false;
        _wcisniety = false;
      }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _wcisniety = true),
        onTapCancel: () => setState(() => _wcisniety = false),
        onTapUp: (_) => setState(() => _wcisniety = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 60),
          height: widget.wysokosc,
          transform: Matrix4.translationValues(0, przesuniecie, 0),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
                color: r == RodzajKlawisza.ciemny ? _K.zloto : _K.zlotoSrednie,
                width: 2),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _najechany
                  ? g.map((c) => Color.lerp(c, Colors.white, 0.08)!).toList()
                  : g,
              stops: const [0.0, 0.3, 0.7, 1.0],
            ),
            boxShadow: _wcisniety
                ? [BoxShadow(color: podstawa1, offset: const Offset(0, 1))]
                : [
                    BoxShadow(color: podstawa1, offset: const Offset(0, 5)),
                    BoxShadow(color: podstawa2, offset: const Offset(0, 7)),
                    const BoxShadow(
                        color: Color(0xB3000000),
                        offset: Offset(0, 10),
                        blurRadius: 12),
                  ],
          ),
          // Połysk u góry i cień u dołu (wrażenie wypukłości).
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x73FFFFFF),
                Color(0x00FFFFFF),
                Color(0x00000000),
                Color(0x66000000),
              ],
              stops: [0.0, 0.12, 0.85, 1.0],
            ),
          ),
          child: tresc,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: widget.podpowiedz == null
          ? przycisk
          : Tooltip(message: widget.podpowiedz!, child: przycisk),
    );
  }
}

/// Zgodność ze starszym kodem (server_page.dart, dialog.dart).
Widget szperaczKlawisz({
  required String tekst,
  required bool zielony,
  required VoidCallback onTap,
  bool zloty = false,
}) =>
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Klawisz3D(
        tekst: tekst,
        onTap: onTap,
        ikona: zloty
            ? Icons.security_rounded
            : (zielony ? Icons.check_rounded : Icons.close_rounded),
        rodzaj: zloty
            ? RodzajKlawisza.zloty
            : (zielony ? RodzajKlawisza.zielony : RodzajKlawisza.czerwony),
      ),
    );

// ───────────────────────────── pola ─────────────────────────────

/// Pole w złotej wypukłej ramie z wklęsłym kremowym wnętrzem (192.2).
class Pole3D extends StatelessWidget {
  final TextEditingController kontroler;
  final String podpowiedz;
  final bool cyfry;
  final bool duze;
  final bool autoFocus;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  const Pole3D({
    Key? key,
    required this.kontroler,
    this.podpowiedz = '',
    this.cyfry = true,
    this.duze = false,
    this.autoFocus = false,
    this.onSubmitted,
    this.onChanged,
    this.tylkoCyfry = false,
  }) : super(key: key);

  /// 368.2: pole przyjmuje wyłącznie cyfry (kod od klienta).
  final bool tylkoCyfry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        gradient: _gradientZloty,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: _K.zlotoBraz, offset: Offset(0, 3)),
          BoxShadow(color: _K.zlotoCien, offset: Offset(0, 5)),
          BoxShadow(
              color: Color(0xB3000000), offset: Offset(0, 8), blurRadius: 10),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFD9C79F), Color(0xFFFFFBEE), Color(0xFFF7EDD3)],
            stops: [0.0, 0.25, 1.0],
          ),
        ),
        child: TextField(
          controller: kontroler,
          autofocus: autoFocus,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: tylkoCyfry ? TextInputType.number : null,
          inputFormatters:
              tylkoCyfry ? [FilteringTextInputFormatter.digitsOnly] : null,
          obscureText: false,
          textAlign: duze ? TextAlign.center : TextAlign.left,
          onSubmitted: onSubmitted,
          onChanged: onChanged,
          style: TextStyle(
            fontFamily: cyfry ? 'SzperaczMono' : 'SzperaczSerif',
            fontWeight: cyfry ? FontWeight.w700 : FontWeight.w400,
            fontSize: duze ? 24 : (cyfry ? 16 : 14),
            letterSpacing: duze ? 4 : (cyfry ? 1 : 0),
            color: _K.wpis,
            shadows: const [],
          ),
          cursorColor: _K.wpis,
          decoration: InputDecoration(
            isDense: true,
            border: InputBorder.none,
            hintText: podpowiedz,
            hintStyle: const TextStyle(color: Color(0xFF8A7A5A), shadows: []),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
      ),
    );
  }
}

/// Kupon z wartością (numer, kod) czytaną na żywo z kontrolera RustDesk.
Widget _kupon(TextEditingController kontroler,
    {double rozmiar = 24, bool przerywany = true}) {
  return ValueListenableBuilder<TextEditingValue>(
    valueListenable: kontroler,
    builder: (context, w, _) => GestureDetector(
      onDoubleTap: () {
        Clipboard.setData(ClipboardData(text: w.text.replaceAll(' ', '')));
        showToast(translate('Copied'));
      },
      child: Container(
        margin: const EdgeInsets.only(top: 5, bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _K.zloto, width: 2),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFFBEE), Color(0xFFF4E8C8)],
          ),
          boxShadow: const [
            BoxShadow(color: _K.zlotoBraz, offset: Offset(0, 3)),
            BoxShadow(
                color: Color(0x99000000), offset: Offset(0, 5), blurRadius: 6),
          ],
        ),
        child: SelectableText(
          w.text.isEmpty ? '...' : (przerywany ? w.text.replaceAll(' ', '') : w.text),
          style: TextStyle(
            fontFamily: 'SzperaczMono',
            fontWeight: FontWeight.w700,
            fontSize: rozmiar,
            letterSpacing: przerywany ? 0 : 3,
            color: _K.tusz,
            shadows: const [],
          ),
        ),
      ),
    ),
  );
}

/// Ciemna sekcja „wgłębiona” w rdzawą blachę (ustawienia, książka).
class SzperaczSekcja extends StatelessWidget {
  final String? tytul;
  final Widget child;
  const SzperaczSekcja({Key? key, this.tytul, required this.child})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xBFC9A227)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xEB080402), Color(0xE60E0804)],
        ),
        boxShadow: const [
          BoxShadow(color: Color(0x80000000), offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (tytul != null) ...[
            szperaczEtykieta(tytul!, align: TextAlign.left),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }
}

// ───────────────────────────── okno dialogowe ─────────────────────────────

/// Okienko dialogowe w stylu Szperacza (zamiast CustomAlertDialog RustDeska).
class SzperaczDialog extends CustomAlertDialog {
  final String tytul;
  final Widget tresc;
  final List<Widget> akcje;
  final double szerokosc;
  final VoidCallback? onEnter;
  final VoidCallback? onEscape;
  const SzperaczDialog({
    Key? key,
    required this.tytul,
    required this.tresc,
    this.akcje = const [],
    this.szerokosc = 340,
    this.onEnter,
    this.onEscape,
  }) : super(key: key, content: const SizedBox());

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        if (onEscape != null)
          const SingleActivator(LogicalKeyboardKey.escape): onEscape!,
      },
      // 289.1: zielone tło na całe okno — spod okienka nic nie prześwituje.
      child: Stack(children: [
        const Positioned.fill(child: SzperaczTlo(child: SizedBox.expand())),
        Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 26, right: 22),
          child: _PowiekszOkno(child: SzperaczOkno(
            maxSzerokosc: szerokosc,
            child: Theme(
              data: MyTheme.lightTheme,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Napis3D(tytul, rozmiar: 19),
                  const SizedBox(height: 6),
                  tresc,
                  if (akcje.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        for (var i = 0; i < akcje.length; i++) ...[
                          if (i > 0) const SizedBox(width: 10),
                          Expanded(child: akcje[i]),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          )),
        ),
      )]),
    );
  }
}

/// Zgodność: tytuł okienka (dialog.dart).
Widget szperaczTytulOkna(String tekst) => Napis3D(tekst, rozmiar: 19);

/// Okienko „KOD OD KLIENTA” u serwisanta (193.1) — treść; dialog.dart buduje SzperaczDialog.
Widget szperaczPoleKodu({
  required TextEditingController kontroler,
  required bool autoFocus,
  required VoidCallback onSubmit,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      szperaczEtykieta('WPISZ KOD Z EKRANU KLIENTA'),
      const SizedBox(height: 8),
      Pole3D(
        kontroler: kontroler,
        podpowiedz: '4 cyfry',
        tylkoCyfry: true,
        duze: true,
        autoFocus: autoFocus,
        onSubmitted: (_) => onSubmit(),
      ),
      const SizedBox(height: 8),
      _opis('Kod zmienia się po każdej sesji.', rozmiar: 11),
    ],
  );
}

// ───────────────────────────── sprawdzanie wersji (197.4, 199) ─────────────────────────────

/// Informacja o nowszej wersji na szperacz.minitel24.pl/wersja.json.
class _NowaWersja {
  final String wersja;
  final String nazwa;
  final String url;
  final String sha256;
  _NowaWersja(this.wersja, this.nazwa, this.url, this.sha256);
}

final _nowaWersja = Rxn<_NowaWersja>();
Timer? _timerWersji;
const _adresWersji = 'https://szperacz.minitel24.pl/wersja.json';

int _porownajWersje(String a, String b) {
  final pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  final pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0, y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

Future<void> _sprawdzWersje() async {
  try {
    final r = await http
        .get(Uri.parse(_adresWersji))
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) return;
    final j = jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
    final w = (j['wersja'] ?? '').toString();
    if (w.isNotEmpty && _porownajWersje(w, szperaczWersja) > 0) {
      _nowaWersja.value = _NowaWersja(
        w,
        (j['nazwa'] ?? 'SZPERACZ $w').toString(),
        (j['plik'] ?? 'https://szperacz.minitel24.pl/Szperacz.exe').toString(),
        (j['sha256'] ?? '').toString().toLowerCase(),
      );
    }
  } catch (_) {}
}

/// Uruchamiane raz przy starcie okna głównego: teraz i potem co 24 godziny.
void szperaczStartSprawdzaniaWersji() {
  if (_timerWersji != null) return;
  _sprawdzWersje();
  _timerWersji =
      Timer.periodic(const Duration(hours: 24), (_) => _sprawdzWersje());
}

/// Złota wstęga „NOWA WERSJA … JEST GOTOWA — POBIERZ” u góry każdego okna.
class SzperaczWstegaNowejWersji extends StatelessWidget {
  const SzperaczWstegaNowejWersji({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final n = _nowaWersja.value;
      if (n == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
          decoration: BoxDecoration(
            gradient: _gradientZloty,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _K.zlotoSrednie, width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0xFF3E2A05), offset: Offset(0, 4)),
              BoxShadow(
                  color: Color(0x99000000),
                  offset: Offset(0, 6),
                  blurRadius: 8),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.card_giftcard, size: 16, color: Color(0xFF2E1B0D)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'NOWA WERSJA ${n.wersja} JEST GOTOWA',
                  textAlign: TextAlign.left,
                  style: const TextStyle(
                      fontFamily: 'SzperaczSlab',
                      fontSize: 10,
                      color: Color(0xFF2E1B0D),
                      shadows: []),
                ),
              ),
              SizedBox(
                width: 90,
                child: Klawisz3D(
                  tekst: 'POBIERZ',
                  wysokosc: 26,
                  rozmiarNapisu: 9,
                  onTap: () => _potwierdzAktualizacje(n),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

void _potwierdzAktualizacje(_NowaWersja n) {
  final polaczenia = gFFI.serverModel.clients.isNotEmpty;
  gFFI.dialogManager.show((setState, close, context) {
    return SzperaczDialog(
      tytul: 'AKTUALIZACJA',
      onEscape: close,
      tresc: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _opis('Zaktualizować Szperacza do wersji ${n.wersja}?\n'
              'Program uruchomi się ponownie.'),
          if (polaczenia) ...[
            const SizedBox(height: 8),
            _opis('Trwa połączenie — lepiej zaktualizować po jego zakończeniu.',
                rozmiar: 11),
          ],
        ],
      ),
      akcje: [
        Klawisz3D(
            tekst: 'PÓŹNIEJ',
            ikona: Icons.close_rounded,
            rodzaj: RodzajKlawisza.czerwony,
            onTap: close),
        Klawisz3D(
            tekst: 'AKTUALIZUJ',
            ikona: Icons.download_rounded,
            onTap: () {
              close();
              _aktualizuj(n);
            }),
      ],
    );
  });
}

/// Pobiera nowy Szperacz.exe, sprawdza SHA-256 i podmienia plik (199.3).
Future<void> _aktualizuj(_NowaWersja n) async {
  final plik = bind.mainGetEnv(key: 'SZPERACZ_PLIK');
  if (!Platform.isWindows || plik.isEmpty || bind.mainIsInstalled()) {
    // Wersja zainstalowana lub brak ścieżki: pobranie ze strony.
    launchUrl(Uri.parse('https://szperacz.minitel24.pl'));
    return;
  }
  gFFI.dialogManager.showLoading('Pobieranie wersji ${n.wersja}…');
  try {
    final r = await http.get(Uri.parse(n.url)).timeout(const Duration(minutes: 5));
    if (r.statusCode != 200) throw 'HTTP ${r.statusCode}';
    final nowy = '$plik.nowy';
    await File(nowy).writeAsBytes(r.bodyBytes, flush: true);
    final suma = bind.szperaczSha256Pliku(sciezka: nowy);
    if (n.sha256.isNotEmpty && suma != n.sha256) {
      await File(nowy).delete();
      throw 'zła suma kontrolna';
    }
    // Skrypt: zamknij Szperacza, podmień plik, uruchom ponownie.
    final katalog = File(Platform.resolvedExecutable).parent.path;
    final skrypt = '${Directory.systemTemp.path}\\szperacz_aktualizacja.cmd';
    await File(skrypt).writeAsString('@echo off\r\n'
        'timeout /t 2 /nobreak >nul\r\n'
        'powershell -NoProfile -Command "Get-Process | Where-Object { \$_.Path -like \'$katalog*\' } | Stop-Process -Force"\r\n'
        'timeout /t 2 /nobreak >nul\r\n'
        'move /y "$nowy" "$plik" >nul\r\n'
        'start "" "$plik"\r\n');
    await Process.start('cmd', ['/c', skrypt],
        mode: ProcessStartMode.detached);
    gFFI.dialogManager.dismissAll();
    exit(0);
  } catch (e) {
    gFFI.dialogManager.dismissAll();
    showToast('Aktualizacja nie powiodła się ($e). Pobierz ze strony szperacz.minitel24.pl.');
  }
}

// ───────────────────────────── okno 1: wybór trybu ─────────────────────────────

Widget _naSrodku(Widget okno) => _DopasujOkno(okno: okno);

/// 232.x: okno programu dopasowuje się do rdzawego okna — zielone tło
/// wystaje ok. 1 cm (38 px) z każdej strony; okno ustawia się na środku ekranu.
class _DopasujOkno extends StatefulWidget {
  final Widget okno;
  const _DopasujOkno({required this.okno});

  @override
  State<_DopasujOkno> createState() => _DopasujOknoState();
}

class _DopasujOknoState extends State<_DopasujOkno> {
  static const _margines = 38.0;
  final _obszar = GlobalKey();
  final _tresc = GlobalKey();
  Size? _ostatni;

  void _dopasuj() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final o = _obszar.currentContext?.findRenderObject() as RenderBox?;
      final t = _tresc.currentContext?.findRenderObject() as RenderBox?;
      if (o == null || t == null || !o.hasSize || !t.hasSize) return;
      try {
        final okno = await windowManager.getSize();
        // Różnica między oknem a obszarem tła = pasek tytułu i ramki.
        final cel = Size(
          (okno.width - o.size.width + t.size.width + 2 * _margines)
              .roundToDouble(),
          (okno.height - o.size.height + t.size.height + 2 * _margines)
              .roundToDouble(),
        );
        if (_ostatni != null &&
            (cel.width - _ostatni!.width).abs() < 3 &&
            (cel.height - _ostatni!.height).abs() < 3) {
          return;
        }
        if ((cel.width - okno.width).abs() < 3 &&
            (cel.height - okno.height).abs() < 3) {
          _ostatni = cel;
          return;
        }
        _ostatni = cel;
        await windowManager.setMinimumSize(const Size(200, 200));
        await windowManager.setSize(cel);
        await windowManager.center();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    _dopasuj();
    return SzperaczTlo(
      key: _obszar,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(_margines),
          child: NotificationListener<SizeChangedLayoutNotification>(
            onNotification: (_) {
              _dopasuj();
              return false;
            },
            child: SizeChangedLayoutNotifier(
              child: KeyedSubtree(key: _tresc, child: widget.okno),
            ),
          ),
        ),
      ),
    );
  }
}

class SzperaczWybor extends StatefulWidget {
  const SzperaczWybor({Key? key}) : super(key: key);

  @override
  State<SzperaczWybor> createState() => _SzperaczWyborState();
}

class _SzperaczWyborState extends State<SzperaczWybor> {
  // 215.x: czerwony klawisz „ŁĄCZĘ SIĘ Z KIMŚ” zamienia się w pole PIN.
  bool _pin = false;
  bool _czekam = false;
  String _komunikat = '';
  final _kontroler = TextEditingController();

  @override
  void dispose() {
    _kontroler.dispose();
    super.dispose();
  }

  void _anuluj() => setState(() {
        _pin = false;
        _komunikat = '';
        _kontroler.clear();
      });

  Future<void> _wejdz() async {
    if (_czekam) return;
    setState(() {
      _czekam = true;
      _komunikat = 'Sprawdzam…';
    });
    final blad = await szperaczSprawdzPin(_kontroler.text.trim());
    if (!mounted) return;
    setState(() {
      _czekam = false;
      _komunikat = blad ?? '';
      _kontroler.clear();
      if (blad == null) _pin = false;
    });
  }

  Widget _malyKlawisz(IconData ikona, List<Color> kolory, Color kolorIkony,
          VoidCallback onTap) =>
      MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 30,
            height: 28,
            margin: const EdgeInsets.only(left: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _K.zlotoSrednie, width: 2),
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: kolory),
            ),
            child: Icon(ikona, size: 16, color: kolorIkony),
          ),
        ),
      );

  Widget _polePin() {
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _anuluj},
      child: Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Container(
          height: 44,
          padding: const EdgeInsets.fromLTRB(10, 0, 6, 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: _K.zlotoSrednie, width: 2),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF07070),
                Color(0xFFC02C2C),
                Color(0xFF9E1B1B),
                Color(0xFF5E0B0B)
              ],
              stops: [0.0, 0.3, 0.7, 1.0],
            ),
            boxShadow: const [
              BoxShadow(color: Color(0xFF4A0A0A), offset: Offset(0, 5)),
              BoxShadow(color: Color(0xFF2A0505), offset: Offset(0, 7)),
              BoxShadow(
                  color: Color(0xB3000000),
                  offset: Offset(0, 10),
                  blurRadius: 12),
            ],
          ),
          child: Row(
            children: [
              const Text('PIN',
                  style: TextStyle(
                      fontFamily: 'SzperaczSlab',
                      fontSize: 11,
                      color: Colors.white)),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFD9C79F), Color(0xFFFFFBEE)],
                      stops: [0.0, 0.3],
                    ),
                  ),
                  child: TextField(
                    controller: _kontroler,
                    autofocus: true,
                    obscureText: true,
                    obscuringCharacter: '●',
                    readOnly: _czekam,
                    onSubmitted: (_) => _wejdz(),
                    style: const TextStyle(
                        fontFamily: 'SzperaczMono',
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        letterSpacing: 6,
                        color: _K.wpis,
                        shadows: []),
                    cursorColor: _K.wpis,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
                  ),
                ),
              ),
              _malyKlawisz(
                  Icons.arrow_forward_rounded,
                  const [
                    Color(0xFF5CC08A),
                    Color(0xFF1F8A50),
                    Color(0xFF053A1D)
                  ],
                  Colors.white,
                  _wejdz),
              _malyKlawisz(
                  Icons.close_rounded,
                  const [Color(0xFF3A2716), Color(0xFF140C06)],
                  _K.zlotoJasne,
                  _anuluj),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    szperaczStartSprawdzaniaWersji();
    return _naSrodku(
      SzperaczOkno(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _naglowek('POMOC ZDALNA'),
            szperaczEtykieta('CO CHCESZ ZROBIĆ?'),
            const SizedBox(height: 12),
            Klawisz3D(
              tekst: 'KTOŚ ŁĄCZY SIĘ ZE MNĄ',
              ikona: Icons.download_rounded,
              wysokosc: 40,
              rozmiarNapisu: 11,
              onTap: () => szperaczTryb.value = 'klient',
            ),
            const SizedBox(height: 6),
            if (_pin)
              _polePin()
            else
              Klawisz3D(
                tekst: 'ŁĄCZĘ SIĘ Z KIMŚ',
                ikona: Icons.upload_rounded,
                rodzaj: RodzajKlawisza.czerwony,
                wysokosc: 40,
                rozmiarNapisu: 11,
                onTap: () => setState(() {
                  _pin = true;
                  _komunikat = '';
                }),
              ),
            if (_komunikat.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(_komunikat,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _czekam ? _K.opis : const Color(0xFFFFB4A0),
                        fontWeight: FontWeight.w700,
                        fontSize: 11)),
              ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── okno 2: klient ─────────────────────────────

class SzperaczKlient extends StatefulWidget {
  const SzperaczKlient({Key? key}) : super(key: key);

  @override
  State<SzperaczKlient> createState() => _SzperaczKlientState();
}

class _SzperaczKlientState extends State<SzperaczKlient> {
  // 241.1: na czas połączenia główne okno znika; okno akceptacji / małe okienko
  // (osobny proces CM) zapisuje liczbę połączeń do pliku sesji.
  Timer? _timer;
  bool _schowane = false;
  bool _staly = false;
  bool _wysylam = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _sprawdzSesje());
    bind.mainGetOption(key: 'szperacz-kod-staly').then((v) {
      if (mounted) setState(() => _staly = v.isNotEmpty);
    });
  }

  /// 274.x: kłódka — kod przestaje się zmieniać i leci do książki serwisanta.
  Future<void> _przelaczKlodke() async {
    if (_wysylam) return;
    final kod = gFFI.serverModel.serverPasswd.text.trim();
    final numer = gFFI.serverModel.serverId.text.replaceAll(' ', '');
    if (kod.isEmpty || numer.isEmpty) return;
    setState(() => _wysylam = true);
    final zamknij = !_staly;
    await bind.mainSetOption(
        key: 'szperacz-kod-staly', value: zamknij ? kod : '');
    final o = await _zapytaj(
        'kod', {'komputer': numer, 'kod': zamknij ? kod : ''});
    if (!mounted) return;
    setState(() {
      _wysylam = false;
      _staly = zamknij;
    });
    if (zamknij && o == null) {
      showToast('Kod zablokowany, ale nie udało się wysłać go do serwisu.');
    }
  }

  Widget _klodka() {
    final tresc = _staly
        ? const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.lock_rounded, size: 18, color: Color(0xFF2E1B0D)),
            SizedBox(width: 6),
            Text('KOD STAŁY\nWYSŁANY DO SERWISU',
                style: TextStyle(
                    fontFamily: 'SzperaczSlab',
                    fontSize: 8,
                    height: 1.2,
                    color: Color(0xFF2E1B0D))),
          ])
        : const Icon(Icons.lock_open_rounded,
            size: 18, color: Color(0xFF2E1B0D));
    return Tooltip(
      message: _staly
          ? 'Odblokuj — kod zmieni się po następnym połączeniu'
          : 'Zablokuj kod — nie będzie się zmieniał i trafi do serwisu',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: _przelaczKlodke,
          child: Container(
            height: 34,
            margin: const EdgeInsets.only(top: 5, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _K.zlotoSrednie, width: 2),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_K.zlotoJasne, _K.zloto, _K.zlotoCiemne],
              ),
              boxShadow: const [
                BoxShadow(color: Color(0xFF3E2A05), offset: Offset(0, 4)),
                BoxShadow(
                    color: Color(0x99000000),
                    offset: Offset(0, 6),
                    blurRadius: 8),
              ],
            ),
            alignment: Alignment.center,
            child: _wysylam
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Color(0xFF2E1B0D)))
                : tresc,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _sprawdzSesje() async {
    final aktywne = await szperaczAktywneSesje();
    try {
      if (aktywne > 0 && !_schowane) {
        _schowane = true;
        await windowManager.hide();
      } else if (aktywne == 0 && _schowane) {
        // 245.1: po połączeniu wraca okno klienta z nowym kodem.
        _schowane = false;
        await windowManager.show();
        await windowManager.focus();
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final model = gFFI.serverModel;
    return _naSrodku(
      SzperaczOkno(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _naglowek('POMOC ZDALNA'),
            szperaczEtykieta('TWÓJ NUMER — PODAJ GO SERWISANTOWI'),
            _kupon(model.serverId, rozmiar: 26),
            szperaczEtykieta('KOD JEDNORAZOWY'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _kupon(model.serverPasswd, rozmiar: 20, przerywany: false),
                const SizedBox(width: 10),
                _klodka(),
              ],
            ),
            _opis('Gdy serwisant się połączy, pojawi się okienko —\n'
                'kliknij w nim AKCEPTUJ.'),
            const SizedBox(height: 6),
            TextButton(
              onPressed: () => szperaczTryb.value = null,
              child: szperaczEtykieta('◀ WRÓĆ DO WYBORU'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Plik sesji (241.x): CM zapisuje „liczba;czas” co 2 s, okno główne czyta.
String get _plikSesji =>
    '${Directory.systemTemp.path}${Platform.pathSeparator}szperacz_sesja.txt';

Future<void> szperaczZapiszSesje(int aktywne) async {
  try {
    await File(_plikSesji)
        .writeAsString('$aktywne;${DateTime.now().millisecondsSinceEpoch}');
  } catch (_) {}
}

/// Liczba aktywnych połączeń; wpis starszy niż 6 s = 0 (CM mógł się zamknąć).
Future<int> szperaczAktywneSesje() async {
  try {
    final c = (await File(_plikSesji).readAsString()).split(';');
    final czas = int.parse(c[1]);
    if (DateTime.now().millisecondsSinceEpoch - czas > 6000) return 0;
    return int.parse(c[0]);
  } catch (_) {
    return 0;
  }
}

/// Okienko „STAŁY DOSTĘP” u klienta (193.2): nagłówek SZPERACZ + wstęga, nowe hasło, powtórz, usuń.
void szperaczUstawHasloStale({
  required bool jestUstawione,
  required VoidCallback poZmianie,
}) {
  final p0 = TextEditingController();
  final p1 = TextEditingController();
  var blad = '';
  gFFI.dialogManager.show((setState, close, context) {
    Future<void> zapisz(String haslo) async {
      final ok = await bind.mainSetPermanentPasswordWithResult(password: haslo);
      if (!ok) {
        setState(() => blad = 'Nie udało się zapisać hasła.');
        return;
      }
      poZmianie();
      close();
      showToast(
          haslo.isEmpty ? 'Stały dostęp wyłączony' : 'Hasło stałe zapisane');
    }

    void ustaw() {
      final haslo = p0.text.trim();
      if (haslo.length < 10) {
        setState(() => blad = 'Hasło musi mieć co najmniej 10 znaków.');
        return;
      }
      if (p1.text.trim() != haslo) {
        setState(() => blad = 'Hasła nie są takie same.');
        return;
      }
      zapisz(haslo);
    }

    return _Surowy(CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): close},
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 26, right: 22),
          child: _PowiekszOkno(child: SzperaczOkno(
            maxSzerokosc: 340,
            child: Theme(
              data: MyTheme.lightTheme,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _naglowek('STAŁY DOSTĘP')),
                  _opis('Z hasłem stałym serwisant MINITEL połączy się bez kodu '
                      'i bez klikania AKCEPTUJ. Połączenie zawsze widać na ekranie.',
                      rozmiar: 11),
                  const SizedBox(height: 10),
                  szperaczEtykieta('NOWE HASŁO', align: TextAlign.left),
                  const SizedBox(height: 5),
                  Pole3D(
                      kontroler: p0,
                      podpowiedz: 'min. 10 znaków',
                      autoFocus: true),
                  const SizedBox(height: 10),
                  szperaczEtykieta('POWTÓRZ HASŁO', align: TextAlign.left),
                  const SizedBox(height: 5),
                  Pole3D(
                      kontroler: p1,
                      podpowiedz: 'to samo hasło',
                      onSubmitted: (_) => ustaw()),
                  if (blad.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(blad,
                          style: const TextStyle(
                              color: Color(0xFFFFB4A0),
                              fontWeight: FontWeight.w700,
                              fontSize: 11)),
                    ),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: Klawisz3D(
                            tekst: 'ANULUJ',
                            ikona: Icons.close_rounded,
                            rodzaj: RodzajKlawisza.czerwony,
                            onTap: close)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Klawisz3D(
                            tekst: 'ZAPISZ',
                            ikona: Icons.check_rounded,
                            onTap: ustaw)),
                  ]),
                  if (jestUstawione)
                    Klawisz3D(
                      tekst: 'USUŃ STAŁY DOSTĘP',
                      ikona: Icons.lock_open_rounded,
                      rodzaj: RodzajKlawisza.czerwony,
                      wysokosc: 30,
                      onTap: () => zapisz(''),
                    ),
                ],
              ),
            ),
          )),
        ),
      ),
    ));
  });
}

// ───────────────────────────── okno 4: serwisant ─────────────────────────────

class SzperaczOperator extends StatefulWidget {
  const SzperaczOperator({Key? key}) : super(key: key);

  @override
  State<SzperaczOperator> createState() => _SzperaczOperatorState();
}

class _SzperaczOperatorState extends State<SzperaczOperator> {
  final _numer = TextEditingController();
  // 289.3: na czas sesji (okno ekranu klienta / plików) panel serwisanta się chowa.
  Timer? _timer;
  bool _schowany = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final sesja =
          rustDeskWinManager.getActiveWindows().any((id) => id != kWindowMainId);
      try {
        if (sesja && !_schowany) {
          _schowany = true;
          await windowManager.minimize();
        } else if (!sesja && _schowany) {
          _schowany = false;
          await windowManager.restore();
          await windowManager.show();
          await windowManager.focus();
        }
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _numer.dispose();
    super.dispose();
  }

  void _polacz() {
    final id = _numer.text.replaceAll(' ', '').trim();
    if (id.isEmpty) {
      showToast('Wpisz numer klienta');
      return;
    }
    // Bez kodu — program zapyta o kod w okienku „KOD OD KLIENTA” (186.4).
    connect(context, id);
    _zglosPolaczenie(id);
  }

  @override
  Widget build(BuildContext context) {
    final model = gFFI.serverModel;
    return _naSrodku(
      SzperaczOkno(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            szperaczEtykieta('★ MINITEL · WROCŁAW ★'),
            const SizedBox(height: 2),
            const Napis3D('SZPERACZ', rozmiar: 30),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: model.serverId,
              builder: (_, w, __) => SzperaczWstega(
                  w.text.isEmpty ? '...' : w.text.replaceAll(' ', ''),
                  cyfry: true),
            ),
            szperaczEtykieta('MÓJ IDENTYFIKATOR'),
            const SizedBox(height: 14),
            // Zielony klawisz = pole „ID KLIENTA” (186.2).
            Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: _K.zlotoSrednie, width: 2),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF5CC08A),
                    Color(0xFF1F8A50),
                    Color(0xFF0B5A33),
                    Color(0xFF053A1D)
                  ],
                  stops: [0.0, 0.3, 0.7, 1.0],
                ),
                boxShadow: const [
                  BoxShadow(color: Color(0xFF02200F), offset: Offset(0, 5)),
                  BoxShadow(color: Color(0xFF011208), offset: Offset(0, 7)),
                  BoxShadow(
                      color: Color(0xB3000000),
                      offset: Offset(0, 10),
                      blurRadius: 12),
                ],
              ),
              child: Row(
                children: [
                  const Text('ID KLIENTA',
                      style: TextStyle(
                          fontFamily: 'SzperaczSlab',
                          fontSize: 10,
                          color: Colors.white)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFD9C79F), Color(0xFFFFFBEE)],
                          stops: [0.0, 0.3],
                        ),
                      ),
                      child: TextField(
                        controller: _numer,
                        onSubmitted: (_) => _polacz(),
                        style: const TextStyle(
                            fontFamily: 'SzperaczMono',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: _K.wpis,
                            shadows: []),
                        cursorColor: _K.wpis,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          hintText: '123456789',
                          hintStyle:
                              TextStyle(color: Color(0xFF8A7A5A), shadows: []),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Klawisz3D(
                      tekst: 'POŁĄCZ',
                      ikona: Icons.power_rounded,
                      onTap: _polacz),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 44,
                  child: Klawisz3D(
                    tekst: '',
                    ikona: Icons.menu_book_rounded,
                    rozmiarNapisu: 14,
                    rodzaj: RodzajKlawisza.zloty,
                    podpowiedz: 'Książka klientów',
                    onTap: () => szperaczKsiazka(
                        context, (id) => _numer.text = id),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => szperaczTryb.value = null,
              child: szperaczEtykieta('◀ WYBÓR'),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────────── książka klientów (187–191) ─────────────────────────────

class _Klient {
  String id, nazwa, haslo, notatka;
  _Klient(this.id, this.nazwa, this.haslo, this.notatka);

  Map<String, String> doJson() => {
        'id': id,
        'nazwa': nazwa,
        'haslo': bind.szperaczSzyfruj(dane: haslo),
        'notatka': notatka,
      };

  static _Klient zJson(Map<String, dynamic> j) => _Klient(
        (j['id'] ?? '').toString(),
        (j['nazwa'] ?? '').toString(),
        bind.szperaczOdszyfruj(dane: (j['haslo'] ?? '').toString()),
        (j['notatka'] ?? '').toString(),
      );
}

const _kluczKsiazki = 'szperacz-ksiazka';

List<_Klient> _wczytajKsiazke() {
  try {
    final s = bind.mainGetLocalOption(key: _kluczKsiazki);
    if (s.isEmpty) return [];
    return (jsonDecode(s) as List)
        .map((e) => _Klient.zJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

void _zapiszKsiazke(List<_Klient> lista) {
  lista.sort((a, b) => a.nazwa.toLowerCase().compareTo(b.nazwa.toLowerCase()));
  bind.mainSetLocalOption(
      key: _kluczKsiazki,
      value: jsonEncode(lista.map((k) => k.doJson()).toList()));
}

/// Okno „KSIĄŻKA KLIENTÓW”: lista przewijana, szukaj, POŁĄCZ / DODAJ / ZAMKNIJ.
void szperaczKsiazka(BuildContext ctx, ValueChanged<String> wpiszNumer) {
  final lista = _wczytajKsiazke();
  final szukaj = TextEditingController();
  int? zaznaczony;
  void Function()? odswiez;
  // 275.x: nowe kody od klientów (kłódka) z serwera — znani klienci dostają
  // nowy kod od razu, nowi trafiają na górę jako „NOWY — DOPISZ NAZWĘ”.
  _pobierzKodyKlientow(lista).then((zmiana) {
    if (zmiana) odswiez?.call();
  });
  gFFI.dialogManager.show((setState, close, context) {
    odswiez = () => setState(() {});
    final f = szukaj.text.toLowerCase();
    final widoczni = [
      for (var i = 0; i < lista.length; i++)
        if (lista[i].nazwa.toLowerCase().contains(f) || lista[i].id.contains(f)) i
    ];
    void polacz(int i) {
      close();
      wpiszNumer(lista[i].id);
      connect(ctx, lista[i].id, password: lista[i].haslo);
      _zglosPolaczenie(lista[i].id);
    }

    final wysokosc = (MediaQuery.of(context).size.height * 0.45)
        .clamp(200.0, 900.0);
    return SzperaczDialog(
      tytul: 'KSIĄŻKA KLIENTÓW',
      szerokosc: 400,
      onEscape: close,
      tresc: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Pole3D(
            kontroler: szukaj,
            podpowiedz: 'szukaj: nazwa lub numer',
            cyfry: false,
            onChanged: (_) => setState(() => zaznaczony = null),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xB3C9A227)),
              borderRadius: BorderRadius.circular(6),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  height: 26,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFA58219), _K.zlotoBraz],
                    ),
                  ),
                  child: const Row(children: [
                    SizedBox(
                        width: 100,
                        child: Text('NUMER',
                            style: TextStyle(
                                fontFamily: 'SzperaczSlab',
                                fontSize: 10,
                                color: _K.kremJasny))),
                    Text('KLIENT',
                        style: TextStyle(
                            fontFamily: 'SzperaczSlab',
                            fontSize: 10,
                            color: _K.kremJasny)),
                  ]),
                ),
                SizedBox(
                  height: wysokosc,
                  child: widoczni.isEmpty
                      ? Center(
                          child: _opis(lista.isEmpty
                              ? 'Książka jest pusta — kliknij DODAJ.'
                              : 'Brak klientów pasujących do „${szukaj.text}”.'))
                      : Scrollbar(
                          thumbVisibility: true,
                          child: ListView.builder(
                            itemCount: widoczni.length,
                            itemExtent: 28,
                            itemBuilder: (_, n) {
                              final i = widoczni[n];
                              final k = lista[i];
                              final akt = zaznaczony == i;
                              return Tooltip(
                                message: k.notatka,
                                waitDuration: const Duration(milliseconds: 600),
                                child: InkWell(
                                  onTap: () => k.nazwa.isEmpty
                                      ? _edytujKlienta(lista, i, () => setState(() {}))
                                      : setState(() => zaznaczony = i),
                                  onDoubleTap: () => polacz(i),
                                  child: Container(
                                    padding: const EdgeInsets.only(left: 10),
                                    color: akt
                                        ? const Color(0x80C9A227)
                                        : (n.isEven
                                            ? const Color(0x4D000000)
                                            : const Color(0x73000000)),
                                    child: Row(children: [
                                      SizedBox(
                                        width: 100,
                                        child: Text(k.id,
                                            style: const TextStyle(
                                                fontFamily: 'SzperaczMono',
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: _K.kremJasny)),
                                      ),
                                      Expanded(
                                        child: Text(
                                            k.nazwa.isEmpty
                                                ? 'NOWY — DOPISZ NAZWĘ'
                                                : k.nazwa,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: k.nazwa.isEmpty
                                                    ? FontWeight.w700
                                                    : FontWeight.w400,
                                                color: k.nazwa.isEmpty
                                                    ? _K.zlotoJasne
                                                    : _K.opis)),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: const Icon(Icons.more_vert,
                                            size: 16, color: _K.zlotoSrednie),
                                        padding: EdgeInsets.zero,
                                        onSelected: (v) {
                                          if (v == 'zmien') {
                                            _edytujKlienta(lista, i, () => setState(() {}));
                                          } else {
                                            lista.removeAt(i);
                                            _zapiszKsiazke(lista);
                                            setState(() => zaznaczony = null);
                                          }
                                        },
                                        itemBuilder: (_) => const [
                                          PopupMenuItem(
                                              value: 'zmien', child: Text('Zmień')),
                                          PopupMenuItem(
                                              value: 'usun', child: Text('Usuń')),
                                        ],
                                      ),
                                    ]),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      akcje: [
        Klawisz3D(
          tekst: 'POŁĄCZ',
          ikona: Icons.power_rounded,
          onTap: () {
            if (zaznaczony != null) polacz(zaznaczony!);
          },
        ),
        Klawisz3D(
          tekst: 'DODAJ',
          ikona: Icons.add_rounded,
          rodzaj: RodzajKlawisza.zloty,
          onTap: () => _edytujKlienta(lista, null, () => setState(() {})),
        ),
        Klawisz3D(
          tekst: 'ZAMKNIJ',
          ikona: Icons.close_rounded,
          rodzaj: RodzajKlawisza.czerwony,
          onTap: close,
        ),
      ],
    );
  });
}

/// Okno „NOWY KLIENT” / „ZMIEŃ KLIENTA” (190, 191): numer, nazwa, hasło stałe (obowiązkowe), notatka.
void _edytujKlienta(List<_Klient> lista, int? indeks, VoidCallback poZapisie) {
  final k = indeks == null ? null : lista[indeks];
  final nr = TextEditingController(text: k?.id ?? '');
  final nazwa = TextEditingController(text: k?.nazwa ?? '');
  final haslo = TextEditingController(text: k?.haslo ?? '');
  final notatka = TextEditingController(text: k?.notatka ?? '');
  var blad = '';
  gFFI.dialogManager.show((setState, close, context) {
    // 230.3: każdy błąd widoczny u góry okienka i w dymku — wcześniej napis
    // pod polami bywał poza ekranem i ZAPISZ „nie reagowało”.
    void pokazBlad(String t) {
      setState(() => blad = t);
      showToast(t);
    }

    void zapisz() {
      // 275.5: długość numeru i kodu nie ma znaczenia — tylko niepuste.
      final id = nr.text.replaceAll(RegExp(r'\s'), '').trim();
      if (!RegExp(r'^\d+$').hasMatch(id)) {
        pokazBlad('Wpisz numer klienta (same cyfry).');
        return;
      }
      if (nazwa.text.trim().isEmpty) {
        pokazBlad('Wpisz nazwę klienta.');
        return;
      }
      if (haslo.text.trim().isEmpty) {
        pokazBlad('Wpisz hasło / kod klienta.');
        return;
      }
      final nowy =
          _Klient(id, nazwa.text.trim(), haslo.text.trim(), notatka.text.trim());
      try {
        if (indeks == null) {
          lista.add(nowy);
        } else {
          lista[indeks] = nowy;
        }
        _zapiszKsiazke(lista);
      } catch (e) {
        if (indeks == null) lista.remove(nowy);
        pokazBlad('Nie udało się zapisać: $e');
        return;
      }
      close();
      try {
        poZapisie();
      } catch (_) {}
      showToast('Zapisano: ${nowy.nazwa}');
    }

    Widget et(String t) => Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 5),
          child: szperaczEtykieta(t, align: TextAlign.left),
        );
    return SzperaczDialog(
      tytul: indeks == null ? 'NOWY KLIENT' : 'ZMIEŃ KLIENTA',
      onEscape: close,
      tresc: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (blad.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xCC5E0B0B),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _K.zlotoSrednie),
              ),
              child: Text(blad,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          et('NUMER KLIENTA (ID)'),
          Pole3D(kontroler: nr, podpowiedz: '123456789', autoFocus: true),
          et('NAZWA'),
          Pole3D(
              kontroler: nazwa, podpowiedz: 'np. Hostel recepcja', cyfry: false),
          et('HASŁO / KOD KLIENTA'),
          Pole3D(kontroler: haslo, podpowiedz: 'kod z kłódką od klienta'),
          const SizedBox(height: 4),
          _opis('przychodzi sam, gdy klient zamknie kłódkę przy kodzie',
              rozmiar: 10),
          et('NOTATKA (NIEOBOWIĄZKOWA)'),
          Pole3D(
              kontroler: notatka,
              podpowiedz: 'np. komputer w recepcji',
              cyfry: false,
              onSubmitted: (_) => zapisz()),
        ],
      ),
      akcje: [
        Klawisz3D(
            tekst: 'ANULUJ',
            ikona: Icons.close_rounded,
            rodzaj: RodzajKlawisza.czerwony,
            onTap: close),
        Klawisz3D(tekst: 'ZAPISZ', ikona: Icons.check_rounded, onTap: zapisz),
      ],
    );
  });
}

// ───────────────────────────── zgodność ze starszym kodem ─────────────────────────────

/// Karta okienka połączenia u klienta (server_page.dart) — teraz rdzawe okno bez stopki.
class SzperaczMalaKarta extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const SzperaczMalaKarta(
      {Key? key, required this.child, this.padding = const EdgeInsets.all(10)})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Okienko połączenia wypełnia całe okno CM (zawartość ma Expanded),
    // więc nie używamy SzperaczOkno (Column min) — tylko ten sam wygląd.
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 22, 18, 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _K.zloto, width: 4),
                image: const DecorationImage(
                  image: AssetImage('assets/szperacz_rdza.png'),
                  fit: BoxFit.cover,
                ),
                boxShadow: const [
                  BoxShadow(color: _K.zlotoCiemne, offset: Offset(0, 3)),
                  BoxShadow(color: _K.zlotoBraz, offset: Offset(0, 6)),
                ],
              ),
              child: Container(
                margin: const EdgeInsets.all(7),
                padding: padding,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  border:
                      Border.all(color: const Color(0xB3C9A227), width: 1),
                ),
                child: DefaultTextStyle(
                  style: const TextStyle(
                      fontFamily: 'SzperaczSerif',
                      color: _K.krem,
                      fontSize: 13),
                  child: Theme(data: MyTheme.lightTheme, child: child),
                ),
              ),
            ),
          ),
          Positioned(
            top: -26,
            right: -22,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: 0.28,
                child: Opacity(
                  opacity: 0.55,
                  child: Image.asset('assets/szperacz_stempel.png',
                      width: 90, height: 90),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kolory nagłówka okienka połączenia (czerwona wstęga 3D).
const szperaczNaglowekKolory = [Color(0xFFB32424), Color(0xFF7A1414)];
const szperaczZloto = _K.zlotoSrednie;

/// Opakowanie, bo menedżer okienek RustDeska przyjmuje tylko CustomAlertDialog.
class _Surowy extends CustomAlertDialog {
  final Widget dziecko;
  const _Surowy(this.dziecko) : super(content: const SizedBox());

  @override
  Widget build(BuildContext context) => dziecko;
}

// ───────────────────────────── strażnik trybu serwisanta (201–204, 209.3) ─────────────────────────────

const _adresStrazy = 'https://szperacz.minitel24.pl/api';
const _kluczStrazy = 'szperacz-straz';

String get _mojeId => gFFI.serverModel.serverId.text.replaceAll(' ', '');

/// Zapamiętane dopuszczenie: {nazwa, do, token} — zaszyfrowane.
Map<String, dynamic>? _dopuszczenie() {
  try {
    final s = bind.mainGetLocalOption(key: _kluczStrazy);
    if (s.isEmpty) return null;
    return jsonDecode(bind.szperaczOdszyfruj(dane: s)) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

void _zapamietaj(Map<String, dynamic>? d) => bind.mainSetLocalOption(
    key: _kluczStrazy,
    value: d == null ? '' : bind.szperaczSzyfruj(dane: jsonEncode(d)));

Future<Map<String, dynamic>?> _zapytaj(String sciezka, Map<String, dynamic> dane) async {
  try {
    final r = await http
        .post(Uri.parse('$_adresStrazy/$sciezka'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(dane))
        .timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) return null;
    return jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

/// Okno „ZABLOKOWANY” (204.3).
void _oknoBlokady(String tekst) {
  gFFI.dialogManager.show((setState, close, context) => SzperaczDialog(
        tytul: 'TRYB SERWISANTA ZABLOKOWANY',
        onEscape: close,
        tresc: Column(mainAxisSize: MainAxisSize.min, children: [
          _opis(tekst),
          const SizedBox(height: 8),
          _opis('Twój identyfikator: $_mojeId', rozmiar: 11),
          _opis('Skontaktuj się z MINITEL: biuro@minitel24.pl', rozmiar: 11),
        ]),
        akcje: [
          Klawisz3D(
              tekst: 'ZAMKNIJ',
              ikona: Icons.close_rounded,
              rodzaj: RodzajKlawisza.czerwony,
              onTap: close),
        ],
      ));
}

/// Sprawdzenie PIN-u serwisanta na serwerze (201.1, 203.2, 209.3).
/// Zwraca null, gdy wolno wejść (i przełącza w tryb serwisanta), albo komunikat błędu.
Future<String?> szperaczSprawdzPin(String pin) async {
  if (_mojeId.isEmpty) {
    return 'Program jeszcze nie ma identyfikatora — chwilę poczekaj.';
  }
  if (pin.isEmpty) return 'Wpisz PIN.';
  final o = await _zapytaj('wejscie', {'komputer': _mojeId, 'pin': pin});
  if (o == null) {
    // 209.3: bez serwera najwyżej 24 h od ostatniego udanego wejścia.
    final d = _dopuszczenie();
    final teraz = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (d != null && (d['do'] as int) > teraz) {
      final do_ = DateTime.fromMillisecondsSinceEpoch((d['do'] as int) * 1000)
          .toString()
          .substring(0, 16);
      szperaczTryb.value = 'operator';
      showToast('Serwer niedostępny — tryb serwisanta do $do_');
      return null;
    }
    return 'Brak połączenia z serwerem MINITEL.';
  }
  if (o['ok'] == true) {
    _zapamietaj({'nazwa': o['nazwa'], 'do': o['do'], 'token': o['token']});
    szperaczTryb.value = 'operator';
    showToast('Witaj, ${o['nazwa']}');
    return null;
  }
  switch (o['blad']) {
    case 'pin':
      return (o['zostalo'] ?? 0) > 0
          ? 'Zły PIN. Zostało prób: ${o['zostalo']}.'
          : 'Zły PIN. Wejście zablokowane na 15 minut.';
    case 'czekaj':
      return 'Za dużo błędnych PIN-ów. Spróbuj za ${o['minut']} min.';
    case 'niezatwierdzony':
      _oknoBlokady(
          'Ten komputer nie jest jeszcze zatwierdzony do trybu serwisanta. '
          'Podaj MINITEL swój identyfikator.');
      return 'Komputer niezatwierdzony.';
    default:
      _zapamietaj(null);
      _oknoBlokady('Dostęp do trybu serwisanta został zablokowany.');
      return 'Tryb serwisanta zablokowany.';
  }
}

/// Wpis połączenia do rejestru na serwerze (202.2); serwer może zgłosić blokadę (204.1).
Future<void> _zglosPolaczenie(String klient) async {
  final d = _dopuszczenie();
  if (d == null) return;
  final o = await _zapytaj('zdarzenie', {
    'komputer': _mojeId,
    'token': d['token'],
    'do': d['do'],
    'klient': klient,
  });
  if (o != null && o['zablokowany'] == true) {
    _zapamietaj(null);
    szperaczTryb.value = null;
    _oknoBlokady('Dostęp do trybu serwisanta został zablokowany.');
  }
}

/// 236.2: na czas otwarcia okienka główne okno powiększa się tak, żeby wokół
/// okienka było ok. 1 cm zieleni; po zamknięciu wraca do poprzedniego rozmiaru.
class _PowiekszOkno extends StatefulWidget {
  final Widget child;
  const _PowiekszOkno({required this.child});

  @override
  State<_PowiekszOkno> createState() => _PowiekszOknoState();
}

class _PowiekszOknoState extends State<_PowiekszOkno> {
  static const _margines = 38.0;
  final _klucz = GlobalKey();
  Size? _poprzedni;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final r = _klucz.currentContext?.findRenderObject() as RenderBox?;
      // Tylko okno główne (kWindowId == null), nie okno sesji ani CM.
      if (!mounted || r == null || !r.hasSize || kWindowId != null) return;
      if (desktopType != DesktopType.main) return;
      try {
        final widok = MediaQuery.of(context).size;
        final okno = await windowManager.getSize();
        // Okienko + margines + odstęp na stempel (26 px u góry i 22 px z prawej).
        final potrzeba = Size(r.size.width + 2 * _margines + 22,
            r.size.height + 2 * _margines + 26);
        final dw = potrzeba.width - widok.width, dh = potrzeba.height - widok.height;
        if (dw <= 0 && dh <= 0) return;
        _poprzedni = okno;
        await windowManager.setSize(Size(okno.width + (dw > 0 ? dw : 0),
            okno.height + (dh > 0 ? dh : 0)));
        await windowManager.center();
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    final p = _poprzedni;
    if (p != null) {
      windowManager.setSize(p).then((_) => windowManager.center());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _klucz, child: widget.child);
}

/// 275.x: pobiera z serwera kody, które klienci wysłali kłódką; zwraca true, gdy książka się zmieniła.
Future<bool> _pobierzKodyKlientow(List<_Klient> lista) async {
  final d = _dopuszczenie();
  if (d == null) return false;
  final pyt = {'komputer': _mojeId, 'token': d['token'], 'do': d['do']};
  final o = await _zapytaj('kody', pyt);
  if (o == null || o['ok'] != true) return false;
  var zmiana = false;
  for (final w in (o['kody'] as List? ?? [])) {
    final id = (w['klient'] ?? '').toString();
    final kod = (w['kod'] ?? '').toString();
    if (id.isEmpty || kod.isEmpty) continue;
    final i = lista.indexWhere((k) => k.id == id);
    if (i >= 0) {
      lista[i].haslo = kod;
    } else {
      lista.add(_Klient(id, '', kod, ''));
    }
    zmiana = true;
    await _zapytaj('kod-przejety', {...pyt, 'klient': id});
  }
  if (zmiana) _zapiszKsiazke(lista);
  return zmiana;
}
