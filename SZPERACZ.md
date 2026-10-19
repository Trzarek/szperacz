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
