# Szperacz — pomoc zdalna MINITEL

Szperacz to zmodyfikowana wersja [RustDesk](https://github.com/rustdesk/rustdesk) 1.5.0
(licencja AGPL-3.0, plik `LICENCE`). Kod źródłowy zmian jest publiczny zgodnie z licencją.

## Zmiany względem RustDesk 1.5.0

1. Wbudowany serwer MINITEL: `hg409rdx620.sn.mynetname.net` i jego klucz publiczny
   (`libs/hbb_common/src/config.rs`, stałe `RENDEZVOUS_SERVERS` i `RS_PUB_KEY`).
2. Nazwa aplikacji „Szperacz” (`APP_NAME`), opis pliku i producent w `flutter/windows/runner/Runner.rc`.
3. Ikony: pieczątka MINITEL (`res/*.png`, `res/*.ico`, `flutter/windows/runner/resources/app_icon.ico`,
   `flutter/assets/icon.svg`).
4. Submoduł `libs/hbb_common` włączony bezpośrednio do repozytorium (commit `229b904`), żeby zmiany w nim
   były w jednym miejscu.
5. Workflow `.github/workflows/szperacz-windows.yml` buduje tylko Windows x64 i wystawia artefakt
   `Szperacz-windows-x64` z plikiem `Szperacz.exe`. Pozostałe workflow RustDesk usunięte (poza `bridge.yml`).

## Budowa

GitHub → Actions → „Szperacz - budowa Windows x64” → Run workflow (uruchamia się też po każdym push do `main`).
Pierwsza budowa trwa około godziny, kolejne są szybsze dzięki pamięci podręcznej.

## Historia wersji

Numer wersji: `szperaczWersja` w `flutter/lib/desktop/pages/szperacz.dart`. Numer budowy, datę i skrót commita
wpisuje workflow (krok „Wpisz numer budowy”); widać je w stopce okien programu i w nazwie wydania „najnowsza”.

### 0.10.0 (20.10.2026) — stali klienci

1. Hasło stałe ustawiane przez klienta w jego oknie Szperacza (min. 10 znaków, można usunąć).
2. Połączenie hasłem stałym bez kodu i bez klikania AKCEPTUJ — działa też, gdy nikogo nie ma przy komputerze;
   klient zawsze widzi okienko połączenia z przyciskiem ROZŁĄCZ.
3. Kod jednorazowy dalej wymaga kliknięcia AKCEPTUJ.
4. Przycisk „ZAINSTALUJ NA STAŁE” w oknie klienta (Szperacz startuje z Windows jako usługa).
5. Hasło stałe NIE jest zapisywane w liście komputerów serwisanta — wpisuje się je przy każdym połączeniu.

### 0.9.0 (20.10.2026) — pierwsza wersja testowa

1. Jeden program z wyborem trybu: „Ktoś łączy się ze mną” (klient) / „Łączę się z kimś” (serwisant).
2. Wygląd starej etykiety piwa we wszystkich oknach, w tym w okienku połączenia i okienku kodu.
3. Połączenie wymaga kodu jednorazowego od klienta i kliknięcia AKCEPTUJ (tryb zablokowany w ustawieniach).
4. Nowy kod po każdej sesji, numer ID na stałe.
5. Kod w okienku serwisanta zawsze odkryty, bez „Zapamiętaj hasło”.
6. W trybie „Tylko podgląd” klient widzi kursor serwisanta.
7. Przycisk „AKCEPTUJ JAKO ADMINISTRATOR” (dostęp do okien z uprawnieniami).
