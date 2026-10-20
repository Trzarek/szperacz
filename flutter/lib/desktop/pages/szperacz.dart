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
            shadows: [
              Shadow(offset: Offset(1, 1), color: _Kolory.czerwienCiemna),
            ],
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
  const _Klawisz({
    required this.tekst,
    required this.ikona,
    required this.kolor,
    required this.cien,
    required this.onTap,
    this.wysokosc = 56,
  });

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
            boxShadow: [
              BoxShadow(color: widget.cien, offset: const Offset(0, 5)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.ikona, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              // Napis zawsze w jednej linii — w wąskim okienku zmniejsza się zamiast łamać (130.2).
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.tekst,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: const TextStyle(
                      fontFamily: 'SzperaczSlab',
                      fontSize: 15,
                      letterSpacing: 0.5,
                      color: Colors.white,
                      shadows: [
                        Shadow(offset: Offset(1, 2), color: Color(0x8C000000)),
                      ],
                    ),
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
Widget szperaczKlawisz({
  required String tekst,
  required bool zielony,
  required VoidCallback onTap,
  bool zloty = false,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(4, 4, 4, 9),
    child: _Klawisz(
      tekst: tekst,
      ikona: zloty
          ? Icons.security_rounded
          : (zielony ? Icons.check_rounded : Icons.close_rounded),
      kolor: zloty
          ? _Kolory.zlotoCiemne
          : (zielony ? _Kolory.zielen : _Kolory.czerwien),
      cien: zloty
          ? const Color(0xFF4A3A08)
          : (zielony ? _Kolory.zielenCiemna : _Kolory.czerwienCiemna),
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
              fontFamily: 'SzperaczScript',
              fontSize: 16,
              color: Color(0xFF0E4A2E),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mała etykieta: kremowa karta ze złotą ramką (okna 3 i 4 — „jak 1 i 2, ale mniejsze”, 119.x).
class SzperaczMalaKarta extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const SzperaczMalaKarta({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(10),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _Kolory.krem,
        border: Border.all(color: _Kolory.zloto, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          border: Border.all(color: _Kolory.zlotoCiemne, width: 1),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Theme(
          data: MyTheme.lightTheme,
          child: DefaultTextStyle.merge(
            style: const TextStyle(color: _Kolory.tusz),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Zielone tło jak butelka, bez centrowania — do okien wypełniających cały obszar.
class SzperaczTlo extends StatelessWidget {
  final Widget child;
  const SzperaczTlo({Key? key, required this.child}) : super(key: key);

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
      child: child,
    );
  }
}

/// Kolory nagłówka okienka połączenia (zamiast niebieskiego gradientu RustDesk).
const szperaczNaglowekKolory = [_Kolory.czerwien, Color(0xFF7A1414)];
const szperaczZloto = _Kolory.zloto;

/// Panel operatora: „Łączę się z kimś” — mniejsza etykieta (okno 4).
class SzperaczOperator extends StatefulWidget {
  final Widget listaKomputerow;
  const SzperaczOperator({Key? key, required this.listaKomputerow})
    : super(key: key);

  @override
  State<SzperaczOperator> createState() => _SzperaczOperatorState();
}

class _SzperaczOperatorState extends State<SzperaczOperator> {
  final _numer = TextEditingController();

  @override
  void dispose() {
    _numer.dispose();
    super.dispose();
  }

  void _polacz() {
    final id = _numer.text.replaceAll(' ', '').trim();
    if (id.isEmpty) {
      showToast('Wpisz numer klienta');
      return;
    }
    connect(context, id);
  }

  Widget _malyKupon(TextEditingController k) =>
      ValueListenableBuilder<TextEditingValue>(
        valueListenable: k,
        builder: (context, w, _) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          decoration: BoxDecoration(
            color: _Kolory.kupon,
            border: Border.all(color: _Kolory.czerwien, width: 1.5),
            borderRadius: BorderRadius.circular(5),
          ),
          child: SelectableText(
            w.text.isEmpty ? '...' : w.text,
            style: const TextStyle(
              fontFamily: 'SzperaczMono',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 2,
              color: _Kolory.tusz,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final model = gFFI.serverModel;
    return SzperaczTlo(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SzperaczMalaKarta(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                children: [
                  const Text(
                    'SZPERACZ',
                    style: TextStyle(
                      fontFamily: 'SzperaczSlab',
                      fontSize: 18,
                      letterSpacing: 2,
                      color: _Kolory.czerwien,
                    ),
                  ),
                  const SizedBox(width: 14),
                  _maly('MÓJ NUMER'),
                  const SizedBox(width: 6),
                  _malyKupon(model.serverId),
                  const SizedBox(width: 10),
                  _maly('HASŁO'),
                  const SizedBox(width: 6),
                  _malyKupon(model.serverPasswd),
                  const Spacer(),
                  TextButton(
                    onPressed: () => szperaczTryb.value = null,
                    child: _maly('◀ WYBÓR'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SzperaczMalaKarta(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  _maly('NUMER KLIENTA'),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _numer,
                      onSubmitted: (_) => _polacz(),
                      style: const TextStyle(
                        fontFamily: 'SzperaczMono',
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        letterSpacing: 3,
                        color: _Kolory.tusz,
                      ),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: _Kolory.kupon,
                        hintText: '123 456 789',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: _Kolory.czerwien,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: _Kolory.czerwien,
                            width: 2.5,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 150,
                    child: szperaczKlawisz(
                      tekst: 'POŁĄCZ',
                      zielony: true,
                      onTap: _polacz,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SzperaczMalaKarta(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                child: widget.listaKomputerow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kupon z wartością (ID albo hasło) czytaną na żywo z kontrolera RustDesk.
Widget _kupon(
  TextEditingController kontroler, {
  required double rozmiar,
  required bool przerywana,
  bool szeroki = true,
}) {
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
        padding: EdgeInsets.symmetric(
          vertical: 6,
          horizontal: szeroki ? 0 : 18,
        ),
        decoration: BoxDecoration(
          color: _Kolory.kupon,
          border: Border.all(
            color: _Kolory.czerwien,
            width: 2,
            style: BorderStyle.solid,
          ),
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
          _kupon(
            model.serverPasswd,
            rozmiar: 24,
            przerywana: false,
            szeroki: false,
          ),
          const SizedBox(height: 6),
          const Text(
            'Gdy serwisant się połączy, pojawi się okienko —\nkliknij w nim AKCEPTUJ.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'SzperaczSerif',
              fontSize: 14,
              color: _Kolory.tusz,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'jasna, pełna, szybka pomoc',
            style: TextStyle(
              fontFamily: 'SzperaczScript',
              fontSize: 16,
              color: Color(0xFF0E4A2E),
            ),
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
