// Szperacz (MINITEL): ekran wyboru trybu i okno klienta w stylu etykiety piwa.
// Wzór: grafika/makieta-okno-klienta-piwo.html (zaakceptowana 2026-10-19).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:get/get.dart';

/// Wybrany tryb: null = ekran wyboru, 'klient' = ktoś łączy się ze mną, 'operator' = łączę się z kimś.
final szperaczTryb = RxnString();

class _Kolory {
  static const butelkaCiemna = Color(0xFF04190F);
  static const butelka = Color(0xFF0B3A24);
  static const butelkaJasna = Color(0xFF17603C);
  static const refleks = Color(0xFF2E8A5C);
  static const krem = Color(0xFFF3E7C9);
  static const kupon = Color(0xFFFFF7DD);
  static const zloto = Color(0xFFC9A227);
  static const zlotoCiemne = Color(0xFF8C6D12);
  static const napisZloty = Color(0xFF6B5208);
  static const czerwien = Color(0xFF9E1B1B);
  static const czerwienCiemna = Color(0xFF4A0A0A);
  static const zielen = Color(0xFF0B5A33);
  static const zielenCiemna = Color(0xFF02200F);
  static const tusz = Color(0xFF2A1A0E);
}

/// Zielone tło jak butelka z kremową kartą-etykietą na środku.
class _Butelka extends StatelessWidget {
  final Widget child;
  const _Butelka({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _Kolory.butelkaCiemna,
            _Kolory.butelka,
            _Kolory.butelkaJasna,
            _Kolory.refleks,
            _Kolory.butelkaJasna,
            _Kolory.butelka,
            _Kolory.butelkaCiemna,
          ],
          stops: [0.0, 0.22, 0.40, 0.46, 0.52, 0.75, 1.0],
        ),
      ),
      alignment: Alignment.center,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _Kolory.krem,
              border: Border.all(color: _Kolory.zloto, width: 3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                border: Border.all(color: _Kolory.zlotoCiemne, width: 1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

Widget _maly(String tekst) => Text(
      tekst,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontFamily: 'SzperaczSerif',
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
        color: _Kolory.napisZloty,
      ),
    );

Widget _naglowek() => Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _maly('★ MINITEL · WROCŁAW ★'),
        const SizedBox(height: 2),
        const Text(
          'SZPERACZ',
          style: TextStyle(
            fontFamily: 'SzperaczSlab',
            fontSize: 28,
            letterSpacing: 3,
            color: _Kolory.czerwien,
          ),
        ),
        const SizedBox(height: 6),
        ClipPath(
          clipper: _Wstega(),
          child: Container(
            color: _Kolory.czerwien,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 6),
            child: const Text(
              'POMOC ZDALNA',
              style: TextStyle(
                fontFamily: 'SzperaczSlab',
                fontSize: 16,
                letterSpacing: 4,
                color: Colors.white,
                shadows: [Shadow(offset: Offset(1, 1), color: _Kolory.czerwienCiemna)],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );

/// Kształt wstęgi z wciętymi końcami.
class _Wstega extends CustomClipper<Path> {
  @override
  Path getClip(Size s) => Path()
    ..moveTo(0, 0)
    ..lineTo(s.width, 0)
    ..lineTo(s.width * 0.94, s.height / 2)
    ..lineTo(s.width, s.height)
    ..lineTo(0, s.height)
    ..lineTo(s.width * 0.06, s.height / 2)
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Duży przycisk: pełny kolor, złota ramka, cień 3D, biały napis z cieniem (makieta 98.x).
class _Klawisz extends StatefulWidget {
  final String tekst;
  final IconData ikona;
  final Color kolor;
  final Color cien;
  final VoidCallback onTap;
  final double wysokosc;
  const _Klawisz(
      {required this.tekst,
      required this.ikona,
      required this.kolor,
      required this.cien,
      required this.onTap,
      this.wysokosc = 56});

  @override
  State<_Klawisz> createState() => _KlawiszState();
}

class _KlawiszState extends State<_Klawisz> {
  bool _najechany = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _najechany = true),
      onExit: (_) => setState(() => _najechany = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: widget.wysokosc,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: _najechany
                ? Color.lerp(widget.kolor, Colors.white, 0.12)
                : widget.kolor,
            border: Border.all(color: _Kolory.zloto, width: 3),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: widget.cien, offset: const Offset(0, 5))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.ikona, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.tekst,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'SzperaczSlab',
                    fontSize: 16,
                    letterSpacing: 1,
                    color: Colors.white,
                    shadows: [
                      Shadow(offset: Offset(1, 2), color: Color(0x8C000000))
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Przycisk w stylu etykiety dla okienka połączenia (server_page.dart, 114.1):
/// zielony do akceptacji, czerwony do odrzucenia lub rozłączenia.
Widget szperaczKlawisz(
    {required String tekst, required bool zielony, required VoidCallback onTap}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 4, 9),
    child: _Klawisz(
      tekst: tekst,
      ikona: zielony ? Icons.check_rounded : Icons.close_rounded,
      kolor: zielony ? _Kolory.zielen : _Kolory.czerwien,
      cien: zielony ? _Kolory.zielenCiemna : _Kolory.czerwienCiemna,
      wysokosc: 44,
      onTap: onTap,
    ),
  );
}

/// Ekran startowy: wybór, kto się z kim łączy.
class SzperaczWybor extends StatelessWidget {
  const SzperaczWybor({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _Butelka(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _naglowek(),
          _maly('CO CHCESZ ZROBIĆ?'),
          const SizedBox(height: 14),
          _Klawisz(
            tekst: 'KTOŚ ŁĄCZY SIĘ ZE MNĄ',
            ikona: Icons.download_rounded,
            kolor: _Kolory.zielen,
            cien: _Kolory.zielenCiemna,
            onTap: () => szperaczTryb.value = 'klient',
          ),
          const SizedBox(height: 16),
          _Klawisz(
            tekst: 'ŁĄCZĘ SIĘ Z KIMŚ',
            ikona: Icons.upload_rounded,
            kolor: _Kolory.czerwien,
            cien: _Kolory.czerwienCiemna,
            onTap: () => szperaczTryb.value = 'operator',
          ),
          const SizedBox(height: 14),
          const Text(
            'jasna, pełna, szybka pomoc',
            style: TextStyle(
                fontFamily: 'SzperaczScript', fontSize: 16, color: Color(0xFF0E4A2E)),
          ),
        ],
      ),
    );
  }
}

/// Kupon z wartością (ID albo hasło) czytaną na żywo z kontrolera RustDesk.
Widget _kupon(TextEditingController kontroler,
    {required double rozmiar, required bool przerywana, bool szeroki = true}) {
  return ValueListenableBuilder<TextEditingValue>(
    valueListenable: kontroler,
    builder: (context, wartosc, _) => GestureDetector(
      onDoubleTap: () {
        Clipboard.setData(ClipboardData(text: wartosc.text));
        showToast(translate('Copied'));
      },
      child: Container(
        width: szeroki ? double.infinity : null,
        margin: const EdgeInsets.only(top: 6, bottom: 8),
        padding: EdgeInsets.symmetric(vertical: 6, horizontal: szeroki ? 0 : 18),
        decoration: BoxDecoration(
          color: _Kolory.kupon,
          border: Border.all(
              color: _Kolory.czerwien, width: 2, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(przerywana ? 8 : 6),
        ),
        child: SelectableText(
          wartosc.text.isEmpty ? '...' : wartosc.text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'SzperaczMono',
            fontWeight: FontWeight.w700,
            fontSize: rozmiar,
            letterSpacing: 3,
            color: _Kolory.tusz,
          ),
        ),
      ),
    ),
  );
}

/// Okno klienta: numer ID i hasło jednorazowe do podyktowania serwisantowi.
/// Akceptacja połączenia odbywa się w okienku, które pojawia się przy połączeniu.
class SzperaczKlient extends StatelessWidget {
  const SzperaczKlient({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = gFFI.serverModel;
    return _Butelka(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _naglowek(),
          _maly('TWÓJ NUMER — PODAJ GO SERWISANTOWI'),
          _kupon(model.serverId, rozmiar: 34, przerywana: true),
          _maly('HASŁO JEDNORAZOWE'),
          _kupon(model.serverPasswd, rozmiar: 24, przerywana: false, szeroki: false),
          const SizedBox(height: 6),
          const Text(
            'Gdy serwisant się połączy, pojawi się okienko —\nkliknij w nim AKCEPTUJ.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: 'SzperaczSerif', fontSize: 14, color: _Kolory.tusz),
          ),
          const SizedBox(height: 10),
          const Text(
            'jasna, pełna, szybka pomoc',
            style: TextStyle(
                fontFamily: 'SzperaczScript', fontSize: 16, color: Color(0xFF0E4A2E)),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => szperaczTryb.value = null,
            child: _maly('◀ WRÓĆ DO WYBORU'),
          ),
        ],
      ),
    );
  }
}

