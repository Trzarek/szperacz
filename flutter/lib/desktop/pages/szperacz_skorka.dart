// Szperacz (389.x): skórki programu — RDZA, KARBON, GRAFIT (domyślna), POPIEL.
//
// Cały wygląd Szperacza był projektowany w kolorach RDZY. Skórka nie zmienia kształtów,
// tylko przelicza każdy kolor RDZY na kolor danej skórki według „rodziny” koloru
// (tło butelki, złoto ramy, napisy, pola, klawisze…). Dzięki temu każde okno,
// klawisz 3D i pole zmienia się razem, bez osobnego rysowania dla każdej skórki.
// Klawisze zostają 3D w każdej skórce (zasada na stałe, 27.10.2026).

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';

/// Rodziny kolorów RDZY.
enum _Rodzina { butelka, zloto, napis, pole, tusz, zielony, czerwony, ciemny }

const _rodziny = <int, _Rodzina>{
  // zielona butelka (tło)
  0xFF04190F: _Rodzina.butelka, 0xFF0B3A24: _Rodzina.butelka,
  0xFF17603C: _Rodzina.butelka, 0xFF2E8A5C: _Rodzina.butelka,
  // złoto ram, wstęg, napisów 3D
  0xFFFBE8A0: _Rodzina.zloto, 0xFFF2D77A: _Rodzina.zloto,
  0xFFE0BC45: _Rodzina.zloto, 0xFFC9A227: _Rodzina.zloto,
  0xFFA58219: _Rodzina.zloto, 0xFF8C6D12: _Rodzina.zloto,
  0xFF7C5F10: _Rodzina.zloto, 0xFF5E4709: _Rodzina.zloto,
  0xFF4F3B08: _Rodzina.zloto, 0xFF3A2A06: _Rodzina.zloto,
  0xFF6B4E0D: _Rodzina.zloto, 0xFFD9BC5C: _Rodzina.zloto,
  0xFFE8D39A: _Rodzina.zloto, 0xFFFFF3B8: _Rodzina.zloto,
  0xFF3E2A05: _Rodzina.zloto, 0xFF241802: _Rodzina.zloto,
  0xFFFFF0B0: _Rodzina.zloto,
  // napisy na oknie
  0xFFF3E7C9: _Rodzina.napis, 0xFFFFF3D6: _Rodzina.napis,
  0xFFF0D9A8: _Rodzina.napis, 0xFFEAD7B0: _Rodzina.napis,
  0xFFF6E9C8: _Rodzina.napis,
  // wnętrza pól i kuponów
  0xFFFFFBEE: _Rodzina.pole, 0xFFF7EDD3: _Rodzina.pole,
  0xFFD9C79F: _Rodzina.pole, 0xFFFFFDF5: _Rodzina.pole,
  0xFFF6EBD0: _Rodzina.pole, 0xFFCDB383: _Rodzina.pole,
  0xFFF4E8C8: _Rodzina.pole,
  // ciemny tusz (tekst w polach, napisy na złotych klawiszach)
  0xFF2A170C: _Rodzina.tusz, 0xFF2E1B0D: _Rodzina.tusz,
  // zielone klawisze
  0xFF5CC08A: _Rodzina.zielony, 0xFF1F8A50: _Rodzina.zielony,
  0xFF0B5A33: _Rodzina.zielony, 0xFF053A1D: _Rodzina.zielony,
  0xFF02200F: _Rodzina.zielony, 0xFF011208: _Rodzina.zielony,
  // czerwone klawisze i komunikaty
  0xFFF07070: _Rodzina.czerwony, 0xFFC02C2C: _Rodzina.czerwony,
  0xFF9E1B1B: _Rodzina.czerwony, 0xFF5E0B0B: _Rodzina.czerwony,
  0xFF4A0A0A: _Rodzina.czerwony, 0xFF2A0505: _Rodzina.czerwony,
  0xFFB32424: _Rodzina.czerwony, 0xFF7A1414: _Rodzina.czerwony,
  // ciemne klawisze, zakładki, sekcje
  0xFF3A2716: _Rodzina.ciemny, 0xFF1F140A: _Rodzina.ciemny,
  0xFF140C06: _Rodzina.ciemny, 0xFF080402: _Rodzina.ciemny,
  0xFF050301: _Rodzina.ciemny, 0xFF0E0804: _Rodzina.ciemny,
  0xFF130C07: _Rodzina.ciemny,
};

/// Zakres przeliczenia: odcień, nasycenie i przedział jasności, w który trafia
/// jasność koloru RDZY (0..1). `odwroc` zamienia jasne na ciemne (napisy na jasnym oknie).
class _Zakres {
  final double odcien, nasycenie, od, doJ;
  final bool odwroc;
  const _Zakres(this.odcien, this.nasycenie, this.od, this.doJ,
      {this.odwroc = false});

  Color przelicz(Color c) {
    final h = HSLColor.fromColor(c);
    var l = h.lightness;
    if (odwroc) l = 1 - l;
    return HSLColor.fromAHSL(
            h.alpha, odcien, nasycenie, (od + l * (doJ - od)).clamp(0.0, 1.0))
        .toColor();
  }
}

class Skorka {
  final String id;
  final String nazwa;

  /// null = kolory RDZY bez zmian.
  final Map<_Rodzina, _Zakres>? zakresy;

  /// Tekstura okna (asset) albo jednolity kolor okna.
  final String? tekstura;
  final Color kolorOkna;

  /// Rozmyty stempel pocztowy w rogu okien (tylko RDZA).
  final bool stempel;

  const Skorka(this.id, this.nazwa,
      {this.zakresy,
      this.tekstura,
      this.kolorOkna = const Color(0xFF130C07),
      this.stempel = false});

  Color kolor(int v) {
    final c = Color(v);
    final z = zakresy;
    if (z == null) return c;
    // Kolory z przezroczystością: rodzina po kolorze nieprzezroczystym.
    final r = _rodziny[v | 0xFF000000];
    if (r == null) return c;
    final zakres = z[r];
    if (zakres == null) return c;
    return zakres.przelicz(c);
  }
}

class Skorki {
  static const rdza = Skorka('rdza', 'RDZA',
      tekstura: 'assets/szperacz_rdza.png', stempel: true);

  static const grafit = Skorka('grafit', 'GRAFIT',
      kolorOkna: Color(0xFF2B2F34),
      zakresy: {
        _Rodzina.butelka: _Zakres(210, 0.08, 0.07, 0.20),
        _Rodzina.zloto: _Zakres(210, 0.06, 0.22, 0.78),
        _Rodzina.napis: _Zakres(210, 0.05, 0.62, 0.95),
        _Rodzina.pole: _Zakres(210, 0.05, 0.84, 0.98),
        _Rodzina.tusz: _Zakres(210, 0.12, 0.10, 0.16),
        _Rodzina.zielony: _Zakres(210, 0.10, 0.10, 0.62),
        _Rodzina.czerwony: _Zakres(0, 0.38, 0.12, 0.58),
        _Rodzina.ciemny: _Zakres(210, 0.08, 0.06, 0.22),
      });

  static const karbon = Skorka('karbon', 'KARBON',
      tekstura: 'assets/szperacz_karbon.png',
      kolorOkna: Color(0xFF1B1D20),
      zakresy: {
        _Rodzina.butelka: _Zakres(0, 0.0, 0.04, 0.14),
        _Rodzina.zloto: _Zakres(0, 0.72, 0.16, 0.66),
        _Rodzina.napis: _Zakres(0, 0.10, 0.70, 0.96),
        _Rodzina.pole: _Zakres(0, 0.0, 0.08, 0.14),
        _Rodzina.tusz: _Zakres(0, 0.85, 0.55, 0.62),
        _Rodzina.zielony: _Zakres(0, 0.68, 0.14, 0.62),
        _Rodzina.czerwony: _Zakres(0, 0.0, 0.10, 0.45),
        _Rodzina.ciemny: _Zakres(220, 0.06, 0.06, 0.24),
      });

  static const popiel = Skorka('popiel', 'POPIEL',
      kolorOkna: Color(0xFFECEEF0),
      zakresy: {
        _Rodzina.butelka: _Zakres(210, 0.06, 0.70, 0.86),
        _Rodzina.zloto: _Zakres(210, 0.06, 0.48, 0.86),
        _Rodzina.napis: _Zakres(210, 0.10, 0.14, 0.40, odwroc: true),
        _Rodzina.pole: _Zakres(210, 0.04, 0.90, 1.0),
        _Rodzina.tusz: _Zakres(210, 0.12, 0.12, 0.18),
        _Rodzina.zielony: _Zakres(210, 0.10, 0.40, 0.88),
        _Rodzina.czerwony: _Zakres(0, 0.40, 0.30, 0.70),
        _Rodzina.ciemny: _Zakres(210, 0.06, 0.70, 0.92, odwroc: true),
      });

  static const wszystkie = [grafit, popiel, karbon, rdza];

  static Skorka zId(String id) =>
      wszystkie.firstWhere((s) => s.id == id, orElse: () => grafit);
}

/// Aktualna skórka (389.6: domyślnie GRAFIT).
final szperaczSkorka = Rx<Skorka>(Skorki.grafit);

bool _wystartowala = false;
const _kluczSkorki = 'szperacz-skorka';

/// 389.3–389.5: przy pierwszym użyciu skórki w danym oknie bierzemy ostatnio
/// zapisaną, a potem co 5 minut pytamy serwer, którą wybrał administrator.
Skorka get _aktualna {
  if (!_wystartowala) {
    _wystartowala = true;
    try {
      final id = bind.mainGetLocalOption(key: _kluczSkorki);
      if (id.isNotEmpty) szperaczSkorka.value = Skorki.zId(id);
    } catch (_) {}
    Timer.run(_pobierzSkorke);
    Timer.periodic(const Duration(minutes: 5), (_) => _pobierzSkorke());
  }
  return szperaczSkorka.value;
}

Future<void> _pobierzSkorke() async {
  for (final adres in const [
    'https://szperacz.minitel24.pl/api/skorka',
    'http://192.168.66.10:8099/api/skorka', // sieć biura / VPN
  ]) {
    try {
      final r =
          await http.get(Uri.parse(adres)).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) continue;
      final id = (jsonDecode(r.body)['skorka'] ?? '').toString();
      if (id.isEmpty) return;
      final s = Skorki.zId(id);
      if (s.id != szperaczSkorka.value.id) szperaczSkorka.value = s;
      bind.mainSetLocalOption(key: _kluczSkorki, value: s.id);
      return;
    } catch (_) {}
  }
}

/// Kolor RDZY przeliczony na aktualną skórkę.
Color sk(int v) => _aktualna.kolor(v);

/// Tło okna: tekstura albo kolor skórki.
DecorationImage? szperaczTekstura() {
  final t = _aktualna.tekstura;
  return t == null
      ? null
      : DecorationImage(image: AssetImage(t), fit: BoxFit.cover);
}

Color szperaczKolorOkna() => _aktualna.kolorOkna;
