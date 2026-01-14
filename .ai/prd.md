# Dokument wymagań produktu (PRD) - Flashcards

## 1. Przegląd produktu
Flashcards to webowa aplikacja edukacyjna wspierająca naukę z wykorzystaniem metody spaced repetition. Główną wartością produktu jest automatyczne generowanie wysokiej jakości fiszek edukacyjnych przy pomocy AI na podstawie wklejanego tekstu, co znacząco redukuje czas i wysiłek potrzebny na przygotowanie materiałów do nauki.

Produkt jest skierowany do osób uczących się samodzielnie (studenci, profesjonaliści, pasjonaci), które chcą efektywnie przyswajać wiedzę, ale są zniechęcone manualnym procesem tworzenia fiszek.

MVP obejmuje wyłącznie aplikację webową z podstawowym systemem kont użytkowników oraz integracją z gotowym algorytmem powtórek (Anki).

## 2. Problem użytkownika
Użytkownicy wiedzą, że nauka z wykorzystaniem fiszek i spaced repetition jest skuteczna, jednak:
- ręczne tworzenie fiszek jest czasochłonne,
- wymaga umiejętności syntezy i parafrazowania treści,
- często prowadzi do porzucenia tej metody nauki.

W efekcie użytkownicy:
- uczą się mniej efektywnie,
- odkładają naukę,
- nie wykorzystują potencjału spaced repetition.

Flashcards rozwiązuje ten problem poprzez szybkie generowanie fiszek przez AI oraz bezproblemową integrację z algorytmem powtórek.

## 3. Wymagania funkcjonalne

3.1 Zarządzanie użytkownikami
- Rejestracja konta użytkownika przy użyciu emaila i hasła.
- Logowanie i wylogowywanie użytkownika.
- Sesja użytkownika utrzymywana po zalogowaniu.

3.2 Manualne tworzenie fiszek
- Możliwość utworzenia fiszki z polami:
  - Front (maks. 200 znaków)
  - Back (maks. 500 znaków)
- Walidacja długości pól po stronie aplikacji.
- Zapis fiszki do bazy danych użytkownika.

3.3 Generowanie fiszek przez AI
- Textarea do wklejenia tekstu (limit 1 000–10 000 znaków).
- Jedno żądanie generuje maksymalnie 20 fiszek.
- Wszystkie wygenerowane fiszki mają format Front/Back.
- Po wygenerowaniu użytkownik widzi listę fiszek w widoku podglądu.
- Użytkownik może:
  - edytować fiszkę,
  - zapisać wybrane fiszki,
  - pominąć (nie zapisać) pozostałe.
- Zapisane fiszki są trwale oznaczone jako AI-generated.

3.4 Zarządzanie fiszkami
- Lista wszystkich zapisanych fiszek użytkownika.
- Możliwość edycji fiszki (manualnej i AI-generated).
- Możliwość usunięcia fiszki w dowolnym momencie.

3.5 Powtórki
- Integracja fiszek z gotowym algorytmem Anki po zapisaniu fiszki.
- Prosty widok: „Do powtórki dziś”.
- Usunięcie fiszki usuwa ją również z cyklu powtórek.

## 4. Granice produktu

Poza zakresem MVP:
- Własny algorytm spaced repetition.
- Import plików (PDF, DOCX, itp.).
- Współdzielenie fiszek między użytkownikami.
- Integracje z zewnętrznymi platformami edukacyjnymi.
- Aplikacje mobilne.
- Onboarding użytkownika.
- Rozbudowana analityka i raportowanie.

## 5. Historyjki użytkowników

US-001
Tytuł: Rejestracja nowego użytkownika
Opis: Jako nowy użytkownik chcę założyć konto przy użyciu emaila i hasła, aby móc zapisywać swoje fiszki.
Kryteria akceptacji:
- Formularz wymaga emaila i hasła.
- Email musi mieć poprawny format.
- Hasło jest wymagane.
- Po poprawnej rejestracji użytkownik może się zalogować.

US-002
Tytuł: Logowanie użytkownika
Opis: Jako użytkownik chcę się zalogować, aby uzyskać dostęp do swoich fiszek.
Kryteria akceptacji:
- Użytkownik podaje poprawne dane logowania.
- Po zalogowaniu widzi główny ekran aplikacji.
- Niepoprawne dane uniemożliwiają logowanie.

US-003
Tytuł: Bezpieczny dostęp do danych
Opis: Jako użytkownik chcę mieć pewność, że tylko ja mam dostęp do swoich fiszek.
Kryteria akceptacji:
- Niezalogowany użytkownik nie ma dostępu do fiszek.
- Użytkownik nie widzi fiszek innych użytkowników.

US-004
Tytuł: Manualne dodanie fiszki
Opis: Jako użytkownik chcę ręcznie dodać fiszkę, aby zapisać własną wiedzę.
Kryteria akceptacji:
- Front i Back są wymagane.
- Obowiązuje limit znaków.
- Fiszka zostaje zapisana i trafia do powtórek.

US-005
Tytuł: Generowanie fiszek przez AI
Opis: Jako użytkownik chcę wygenerować fiszki z wklejonego tekstu, aby oszczędzić czas.
Kryteria akceptacji:
- Textarea akceptuje 1 000–10 000 znaków.
- Generowanych jest maks. 20 fiszek.
- Po wygenerowaniu widoczny jest podgląd.

US-006
Tytuł: Podgląd i zapis fiszek AI
Opis: Jako użytkownik chcę zdecydować, które fiszki AI zapisać.
Kryteria akceptacji:
- Użytkownik może zapisać wybrane fiszki.
- Niezapisane fiszki nie trafiają do bazy.
- Zapisane fiszki są oznaczone jako AI-generated.

US-007
Tytuł: Edycja fiszki
Opis: Jako użytkownik chcę edytować fiszkę, aby poprawić jej treść.
Kryteria akceptacji:
- Możliwa edycja front/back.
- Obowiązuje walidacja długości pól.

US-008
Tytuł: Usuwanie fiszki
Opis: Jako użytkownik chcę usunąć fiszkę, aby nie pojawiała się w powtórkach.
Kryteria akceptacji:
- Fiszka zostaje usunięta z listy.
- Fiszka znika z cyklu powtórek.

US-009
Tytuł: Przegląd fiszek do powtórki
Opis: Jako użytkownik chcę zobaczyć fiszki do powtórki na dziś.
Kryteria akceptacji:
- Widok pokazuje tylko fiszki zaplanowane na dziś.
- Brak fiszek skutkuje pustym stanem.

US-010
Tytuł: Wylogowanie
Opis: Jako użytkownik chcę się wylogować, aby zakończyć sesję.
Kryteria akceptacji:
- Sesja użytkownika zostaje zakończona.
- Użytkownik wraca do ekranu logowania.

## 6. Metryki sukcesu
- 75% fiszek generowanych przez AI jest zapisywanych przez użytkowników.
- 75% wszystkich fiszek w systemie pochodzi z generowania AI.
