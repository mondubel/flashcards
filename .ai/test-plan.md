# Plan Testów - Flashcards

## 1. Wprowadzenie i zakres

### 1.1 Opis projektu
Flashcards to aplikacja webowa do nauki z wykorzystaniem metody spaced repetition. Główną funkcjonalnością jest automatyczne generowanie fiszek edukacyjnych przez AI na podstawie tekstu wklejanego przez użytkownika. Aplikacja umożliwia również manualne tworzenie fiszek oraz zarządzanie kolekcją.

### 1.2 Zakres testowania
Plan testów obejmuje:
- **Testy jednostkowe** modeli: `User`, `Flashcard`, `Generation`
- **Testy jednostkowe** serwisów: `AiGenerationService`
- **Testy request** kontrolerów: `FlashcardsController`, `GenerationsController`
- **Testy integracyjne** z zewnętrznym API Openrouter.ai
- **Testy systemowe** (E2E) głównych ścieżek użytkownika
- **Testy bezpieczeństwa** autentykacji i autoryzacji
- **Testy wydajnościowe** krytycznych endpointów

### 1.3 Elementy wyłączone z zakresu
- Testy wizualne (visual regression) stylów Tailwind CSS
- Testy mobilne (aplikacja jest wyłącznie webowa)
- Testy obciążeniowe produkcyjne
- Testy integracji z Anki (poza zakresem MVP)

---

## 2. Cele testowania

### 2.1 Cele główne
1. **Zapewnienie poprawności logiki biznesowej** - weryfikacja, że fiszki są poprawnie tworzone, edytowane i usuwane zgodnie z wymaganiami PRD
2. **Weryfikacja bezpieczeństwa** - potwierdzenie, że użytkownicy mają dostęp wyłącznie do własnych danych
3. **Walidacja integracji AI** - sprawdzenie poprawnej komunikacji z Openrouter.ai i obsługi błędów
4. **Zapewnienie jakości UX** - weryfikacja płynności interakcji z wykorzystaniem Turbo/Hotwire

### 2.2 Cele szczegółowe
- Osiągnięcie minimum 90% pokrycia kodu testami jednostkowymi dla modeli
- Przetestowanie wszystkich endpointów API zdefiniowanych w `api-plan.md`
- Pokrycie testami wszystkich historyjek użytkownika (US-001 do US-009)
- Weryfikacja obsługi błędów dla wszystkich przypadków brzegowych

### 2.3 Metryki sukcesu testów
- Wszystkie testy przechodzą w pipeline CI/CD (GitHub Actions)
- Brak krytycznych błędów bezpieczeństwa wykrytych przez Brakeman
- Brak podatności w zależnościach wykrytych przez bundler-audit

---

## 3. Podejście do testowania

### 3.1 Strategia testowania
Stosujemy podejście **piramidy testów** z naciskiem na testy jednostkowe i integracyjne:

```
        /\
       /  \     Testy E2E (System) - 10%
      /----\    Capybara + Selenium
     /      \   
    /--------\  Testy Request/Integracyjne - 30%
   /          \ RSpec request specs
  /------------\
 /              \ Testy Jednostkowe - 60%
/________________\ RSpec model specs
```

### 3.2 Metodologia
- **Test-Driven Development (TDD)** dla nowych funkcjonalności
- **Behavior-Driven Development (BDD)** dla testów systemowych
- **Testy regresyjne** uruchamiane automatycznie w CI/CD

### 3.3 Zasady tworzenia testów (zgodnie z `.cursor/rules/backend.mdc`)
- **Nie używamy** `let`, `before` ani `subject` w RSpec
- Każdy test jest samodzielny i czytelny
- Testujemy logikę biznesową na poziomie modeli i serwisów
- Testy kontrolerów skupiają się na: zachowaniu HTTP, autoryzacji, formacie odpowiedzi
- Używamy FactoryBot i Faker do generowania danych testowych

---

## 4. Typy testów

### 4.1 Testy jednostkowe modeli

#### 4.1.1 Model `User` (`spec/models/user_spec.rb`)

**Walidacje:**
- Walidacja obecności email
- Walidacja unikalności email
- Walidacja formatu email
- Walidacja obecności hasła
- Walidacja minimalnej długości hasła (6 znaków)

**Asocjacje:**
- has_many :flashcards z dependent: :destroy
- has_many :generations z dependent: :destroy

**Zachowania:**
- Usunięcie użytkownika usuwa wszystkie jego fiszki
- Usunięcie użytkownika usuwa wszystkie jego generacje

#### 4.1.2 Model `Flashcard` (`spec/models/flashcard_spec.rb`)

**Walidacje:**
- Walidacja obecności pola `front`
- Walidacja maksymalnej długości `front` (200 znaków)
- Walidacja obecności pola `back`
- Walidacja maksymalnej długości `back` (500 znaków)
- Walidacja obecności pola `source`
- Walidacja wartości enum `source` (manual, ai_full, ai_edited)
- Walidacja obecności `user_id`

**Asocjacje:**
- belongs_to :user (wymagane)
- belongs_to :generation (opcjonalne)

**Logika biznesowa:**
- Zmiana `source` z `ai_full` na `ai_edited` przy aktualizacji fiszki
- Scope'y enum: `Flashcard.manual`, `Flashcard.ai_full`, `Flashcard.ai_edited`
- Metody predykatowe: `manual?`, `ai_full?`, `ai_edited?`

#### 4.1.3 Model `Generation` (`spec/models/generation_spec.rb`)

**Walidacje:**
- Walidacja obecności `source_text`
- Walidacja minimalnej długości `source_text` (1000 znaków)
- Walidacja maksymalnej długości `source_text` (10000 znaków)
- Walidacja obecności `user_id`
- Walidacja `generated_count` (0-20)

**Asocjacje:**
- belongs_to :user (wymagane)
- has_many :flashcards z dependent: :nullify

**Zachowania:**
- Usunięcie generacji ustawia `generation_id` na NULL w powiązanych fiszkach

**Metryki:**
- Śledzenie `generated_count`
- Śledzenie `accepted_unedited_count`
- Śledzenie `accepted_edited_count`
- Obliczanie acceptance rate

### 4.2 Testy jednostkowe serwisów

#### 4.2.1 Serwis `AiGenerationService` (`spec/services/ai_generation_service_spec.rb`)

**Scenariusze sukcesu:**
- Generowanie propozycji fiszek z poprawnego tekstu źródłowego
- Generowanie maksymalnie 20 fiszek na żądanie
- Walidacja długości wygenerowanych fiszek (front ≤200, back ≤500)
- Zapisanie czasu generowania (`generation_duration`)
- Zapisanie użytego modelu AI (`model`)

**Scenariusze błędów:**
- Obsługa timeout (30 sekund)
- Retry przy błędach transient (2 próby z exponential backoff)
- Rzucenie `ServiceUnavailableError` przy trwałej awarii API
- Obsługa nieprawidłowego formatu odpowiedzi z API
- Obsługa limitów rate limiting API

**Mockowanie:**
- Mockowanie wywołań HTTP do Openrouter.ai
- Nagrywanie odpowiedzi z VCR (opcjonalnie)

### 4.3 Testy request (integracyjne kontrolerów)

#### 4.3.1 `FlashcardsController` (`spec/requests/flashcards_spec.rb`)

**GET /flashcards (index):**
- Przekierowanie niezalogowanego użytkownika na stronę logowania
- Zwrócenie listy fiszek zalogowanego użytkownika
- Wyświetlanie tylko fiszek należących do current_user
- Niewyświetlanie fiszek innych użytkowników

**GET /flashcards/:id (show):**
- Przekierowanie niezalogowanego użytkownika
- Wyświetlenie szczegółów własnej fiszki
- Zwrócenie 404 dla fiszki innego użytkownika
- Zwrócenie 404 dla nieistniejącej fiszki

**GET /flashcards/new (new):**
- Przekierowanie niezalogowanego użytkownika
- Wyświetlenie formularza nowej fiszki

**POST /flashcards (create):**
- Przekierowanie niezalogowanego użytkownika
- Utworzenie fiszki z poprawnymi danymi
- Ustawienie `source` na `manual`
- Przypisanie fiszki do current_user
- Przekierowanie po sukcesie z komunikatem flash
- Zwrócenie 422 przy brakującym `front`
- Zwrócenie 422 przy brakującym `back`
- Zwrócenie 422 przy zbyt długim `front`
- Zwrócenie 422 przy zbyt długim `back`
- Renderowanie formularza z błędami przy niepowodzeniu

**GET /flashcards/:id/edit (edit):**
- Przekierowanie niezalogowanego użytkownika
- Wyświetlenie formularza edycji własnej fiszki
- Zwrócenie 404 dla fiszki innego użytkownika

**PATCH/PUT /flashcards/:id (update):**
- Przekierowanie niezalogowanego użytkownika
- Aktualizacja fiszki z poprawnymi danymi
- Przekierowanie po sukcesie z komunikatem flash
- Zwrócenie 422 przy nieprawidłowych danych
- Zwrócenie 404 przy próbie edycji cudzej fiszki
- Nieaktualizowanie cudzej fiszki

**DELETE /flashcards/:id (destroy):**
- Przekierowanie niezalogowanego użytkownika
- Usunięcie własnej fiszki
- Przekierowanie po sukcesie z komunikatem flash
- Zwrócenie 404 przy próbie usunięcia cudzej fiszki
- Nieusuwanie cudzej fiszki
- Zwrócenie 404 dla nieistniejącej fiszki

#### 4.3.2 `GenerationsController` (`spec/requests/generations_spec.rb`)

**GET /generations (index):**
- Przekierowanie niezalogowanego użytkownika
- Zwrócenie listy generacji zalogowanego użytkownika
- Wyświetlanie tylko generacji należących do current_user
- Obsługa paginacji (page, per_page)

**GET /generations/:id (show):**
- Przekierowanie niezalogowanego użytkownika
- Wyświetlenie szczegółów własnej generacji z listą fiszek
- Zwrócenie 404 dla generacji innego użytkownika
- Zwrócenie 404 dla nieistniejącej generacji

**GET /generations/new (new):**
- Przekierowanie niezalogowanego użytkownika
- Wyświetlenie formularza z textarea na tekst źródłowy

**POST /generations (create):**
- Przekierowanie niezalogowanego użytkownika
- Utworzenie generacji z poprawnym tekstem źródłowym
- Zwrócenie propozycji fiszek (flashcards_proposals)
- Zapisanie metadanych (model, generation_duration, generated_count)
- Zwrócenie 422 przy zbyt krótkim `source_text` (<1000)
- Zwrócenie 422 przy zbyt długim `source_text` (>10000)
- Zwrócenie 503 przy awarii serwisu AI
- Obsługa rate limiting (max 10 requestów/godzinę)

### 4.4 Testy bezpieczeństwa

#### 4.4.1 Autoryzacja (`spec/requests/authorization_spec.rb`)

**Izolacja zasobów:**
- Użytkownik nie może uzyskać dostępu do fiszki innego użytkownika przez bezpośredni URL
- Użytkownik nie może zaktualizować fiszki innego użytkownika
- Użytkownik nie może usunąć fiszki innego użytkownika
- Użytkownik nie może uzyskać dostępu do generacji innego użytkownika

**Ochrona CSRF:**
- Odrzucenie żądań POST bez tokenu CSRF
- Odrzucenie żądań PATCH bez tokenu CSRF
- Odrzucenie żądań DELETE bez tokenu CSRF

**Scope'y ActiveRecord:**
- Wszystkie zapytania o fiszki są scopowane do `current_user.flashcards`
- Wszystkie zapytania o generacje są scopowane do `current_user.generations`

#### 4.4.2 Skanowanie bezpieczeństwa

**Brakeman:**
- SQL Injection
- Cross-Site Scripting (XSS)
- Mass Assignment
- Command Injection
- File Access vulnerabilities
- CSRF vulnerabilities

**bundler-audit:**
- Skanowanie znanych CVE w zależnościach
- Weryfikacja aktualności gemów

### 4.5 Testy systemowe (E2E)

#### 4.5.1 Autentykacja (`spec/system/authentication_spec.rb`)

**Rejestracja użytkownika (US-001):**
- Rejestracja z poprawnymi danymi
- Automatyczne zalogowanie po rejestracji
- Wyświetlenie błędów przy nieprawidłowym email
- Wyświetlenie błędów przy zbyt krótkim haśle
- Wyświetlenie błędów przy niezgodnych hasłach

**Logowanie użytkownika (US-002):**
- Logowanie z poprawnymi danymi
- Wyświetlenie błędu przy nieprawidłowych danych
- Przekierowanie na główną stronę po zalogowaniu

**Wylogowanie (US-009):**
- Wylogowanie zalogowanego użytkownika
- Przekierowanie na stronę logowania
- Brak dostępu do chronionych zasobów po wylogowaniu

#### 4.5.2 Workflow fiszek (`spec/system/flashcard_workflows_spec.rb`)

**Manualne dodanie fiszki (US-004):**
- Wypełnienie formularza i utworzenie fiszki
- Wyświetlenie nowej fiszki na liście
- Walidacja pól front i back
- Komunikat sukcesu po utworzeniu

**Edycja fiszki (US-007):**
- Edycja istniejącej fiszki
- Zapisanie zmian
- Wyświetlenie zaktualizowanej treści
- Walidacja przy edycji

**Usuwanie fiszki (US-008):**
- Usunięcie fiszki z listy
- Potwierdzenie usunięcia
- Komunikat sukcesu
- Fiszka nie pojawia się na liście

**Bezpieczny dostęp (US-003):**
- Niezalogowany użytkownik nie widzi fiszek
- Zalogowany użytkownik widzi tylko swoje fiszki

#### 4.5.3 Workflow generowania AI (`spec/system/ai_generation_workflows_spec.rb`)

**Generowanie fiszek przez AI (US-005):**
- Wklejenie tekstu źródłowego (1000-10000 znaków)
- Wywołanie generacji
- Wyświetlenie podglądu propozycji fiszek
- Walidacja długości tekstu źródłowego
- Obsługa błędu serwisu AI

**Podgląd i zapis fiszek AI (US-006):**
- Wyświetlenie listy propozycji
- Możliwość edycji propozycji przed zapisem
- Zaznaczenie wybranych fiszek do zapisu
- Zapisanie wybranych fiszek
- Oznaczenie zapisanych fiszek odpowiednim source
- Niezapisane fiszki nie trafiają do bazy

---

## 5. Środowiska testowe

### 5.1 Środowisko lokalne (development)
- **Baza danych:** PostgreSQL (lokalna instancja)
- **Uruchamianie:** `bundle exec rspec`
- **Konfiguracja:** `config/environments/test.rb`

### 5.2 Środowisko CI (GitHub Actions)
- **Runner:** Ubuntu latest
- **Baza danych:** PostgreSQL (service container)
- **Konfiguracja:** `.github/workflows/ci.yml`

**Pipeline CI obejmuje:**
1. Instalacja zależności (`bundle install`)
2. Konfiguracja bazy danych (`rails db:setup`)
3. Uruchomienie testów jednostkowych (`rspec spec/models`)
4. Uruchomienie testów request (`rspec spec/requests`)
5. Uruchomienie testów systemowych (`rspec spec/system`)
6. Skanowanie bezpieczeństwa (`brakeman`, `bundler-audit`)
7. Linting (`rubocop`)

### 5.3 Konfiguracja testów systemowych
- Capybara z driverem Selenium
- Chrome w trybie headless
- Konfiguracja timeout i wait helpers

---

## 6. Narzędzia testowe

### 6.1 Framework testowy
| Narzędzie | Zastosowanie |
|-----------|--------------|
| RSpec Rails | Framework testowy |
| FactoryBot Rails | Tworzenie danych testowych |
| Faker | Generowanie realistycznych danych |

### 6.2 Testy integracyjne i E2E
| Narzędzie | Zastosowanie |
|-----------|--------------|
| Capybara | Symulacja przeglądarki |
| Selenium WebDriver | Driver dla Chrome headless |
| rails-controller-testing | Helpery dla kontrolerów |
| Devise Test Helpers | Autentykacja w testach |

### 6.3 Mockowanie i stubbing
| Narzędzie | Zastosowanie |
|-----------|--------------|
| RSpec Mocks | Mockowanie obiektów Ruby |
| WebMock | Mockowanie requestów HTTP |
| VCR | Nagrywanie/odtwarzanie requestów HTTP |

### 6.4 Bezpieczeństwo
| Narzędzie | Zastosowanie |
|-----------|--------------|
| Brakeman | Statyczna analiza bezpieczeństwa |
| bundler-audit | Skanowanie podatności w gemach |

### 6.5 Jakość kodu
| Narzędzie | Zastosowanie |
|-----------|--------------|
| RuboCop | Linting kodu Ruby |
| ERB Lint | Linting szablonów ERB |
| SimpleCov | Pokrycie kodu testami |

### 6.6 Zalecane dodatki do Gemfile
```ruby
# group :test
gem 'webmock'           # Mockowanie HTTP requests
gem 'vcr'               # Nagrywanie HTTP interactions
gem 'simplecov'         # Pokrycie kodu
```

---

## 7. Zasoby

### 7.1 Zasoby ludzkie
| Rola | Odpowiedzialności |
|------|-------------------|
| Developer | Implementacja testów jednostkowych i request |
| QA Engineer | Testy E2E, testy eksploracyjne |
| Security Engineer | Przegląd konfiguracji, pentesty |

### 7.2 Infrastruktura
- **Lokalne środowisko:** Docker z PostgreSQL lub lokalna instalacja
- **CI/CD:** GitHub Actions (darmowe dla open source)
- **Monitoring testów:** GitHub Actions dashboard

### 7.3 Narzędzia zewnętrzne
- **Openrouter.ai API:** Sandbox/test mode (do mockowania w testach)
- **Test email:** Mailhog lub letter_opener_web (development)

---

## 8. Harmonogram

### 8.1 Faza 1: Infrastruktura testowa
- Konfiguracja RSpec, FactoryBot, Faker
- Konfiguracja SimpleCov
- Konfiguracja Capybara + Selenium
- Dodanie WebMock/VCR do projektu

### 8.2 Faza 2: Testy jednostkowe modeli
- Testy modelu `User`
- Testy modelu `Flashcard`
- Testy modelu `Generation`
- Dodanie logiki zmiany source na edycję

### 8.3 Faza 3: Testy request kontrolerów
- Testy `FlashcardsController`
- Testy `GenerationsController`
- Testy autoryzacji międzyużytkownikowej

### 8.4 Faza 4: Serwisy i integracja AI
- Implementacja `AiGenerationService`
- Testy serwisu z mockowaniem API
- Testy obsługi błędów i retry logic

### 8.5 Faza 5: Testy systemowe E2E
- Testy autentykacji (US-001, US-002, US-009)
- Testy workflow fiszek (US-004, US-007, US-008)
- Testy generowania AI (US-005, US-006)

### 8.6 Faza 6: Bezpieczeństwo i optymalizacja
- Pełne skanowanie Brakeman
- Audit zależności
- Optymalizacja czasu wykonania testów
- Konfiguracja parallel tests (opcjonalnie)

---

## 9. Kryteria akceptacji

### 9.1 Kryteria przejścia testów
- Wszystkie testy jednostkowe przechodzą (exit code 0)
- Wszystkie testy request przechodzą (exit code 0)
- Wszystkie testy systemowe przechodzą (exit code 0)
- Brakeman nie wykrywa krytycznych podatności
- bundler-audit nie wykrywa znanych CVE

### 9.2 Kryteria pokrycia kodu
- **Modele:** minimum 90% pokrycia
- **Kontrolery:** minimum 85% pokrycia
- **Serwisy:** minimum 95% pokrycia
- **Ogółem:** minimum 80% pokrycia

### 9.3 Kryteria wydajności testów
- Testy jednostkowe: < 30 sekund
- Testy request: < 60 sekund
- Testy systemowe: < 3 minuty
- Pełny suite: < 5 minut

### 9.4 Kryteria akceptacji funkcjonalnej
Wszystkie historyjki użytkownika z PRD muszą być pokryte testami:

| User Story | Opis | Typ testu |
|------------|------|-----------|
| US-001 | Rejestracja nowego użytkownika | System |
| US-002 | Logowanie użytkownika | System |
| US-003 | Bezpieczny dostęp do danych | Request + System |
| US-004 | Manualne dodanie fiszki | Request + System |
| US-005 | Generowanie fiszek przez AI | Request + System |
| US-006 | Podgląd i zapis fiszek AI | System |
| US-007 | Edycja fiszki | Request + System |
| US-008 | Usuwanie fiszki | Request + System |
| US-009 | Wylogowanie | System |

---

## 10. Ryzyka i założenia

### 10.1 Ryzyka

| Ryzyko | Prawdopodobieństwo | Wpływ | Mitygacja |
|--------|-------------------|-------|-----------|
| Niestabilność API Openrouter.ai | Średnie | Wysoki | Mockowanie w testach, VCR recordings |
| Flaky testy systemowe | Wysokie | Średni | Retry logic, wait_for helpers |
| Wolne testy E2E | Wysokie | Niski | Parallel execution, selektywne uruchamianie |
| Brak środowiska testowego AI | Średnie | Wysoki | Pełne mockowanie API, sandbox mode |
| Zmiany w API Devise | Niskie | Średni | Pinowanie wersji, regularne aktualizacje |

### 10.2 Założenia

1. **Środowisko testowe:**
   - PostgreSQL jest dostępny lokalnie i w CI
   - Chrome jest zainstalowany w środowisku CI (GitHub Actions)
   - Dostęp do internetu nie jest wymagany dla testów (poza instalacją zależności)

2. **Dane testowe:**
   - FactoryBot i Faker generują wystarczająco realistyczne dane
   - Transakcyjne fixtures zapewniają izolację testów
   - Nie są potrzebne zewnętrzne seedowane dane

3. **Integracja AI:**
   - Openrouter.ai zapewnia stabilny format odpowiedzi JSON
   - Limity API są wystarczające dla testów development
   - Mockowanie API jest wystarczające dla walidacji logiki biznesowej

4. **CI/CD:**
   - GitHub Actions runners mają wystarczającą moc obliczeniową
   - Cache bundler działa poprawnie
   - Secrets są bezpiecznie przechowywane w GitHub Secrets

### 10.3 Zależności zewnętrzne

| Zależność | Ryzyko | Plan awaryjny |
|-----------|--------|---------------|
| Openrouter.ai API | Zmiana formatu odpowiedzi | Adapter pattern, schema validation |
| Devise gem | Breaking changes w major versions | Pinowanie wersji, regularne aktualizacje |
| PostgreSQL | Różnice między wersjami | Docker z określoną wersją |
| Chrome/Selenium | Aktualizacje przeglądarki | Headless mode, pinowanie wersji driver |

---

## 11. Przypadki testowe priorytetowe

### 11.1 Krytyczne (P0) - Bezpieczeństwo i autoryzacja

| ID | Przypadek testowy | Lokalizacja |
|----|-------------------|-------------|
| TC-001 | Niezalogowany użytkownik nie ma dostępu do fiszek | `spec/requests/flashcards_spec.rb` |
| TC-002 | Użytkownik nie widzi fiszek innych użytkowników | `spec/requests/flashcards_spec.rb` |
| TC-003 | Użytkownik nie może edytować cudzych fiszek | `spec/requests/flashcards_spec.rb` |
| TC-004 | Użytkownik nie może usunąć cudzych fiszek | `spec/requests/flashcards_spec.rb` |
| TC-005 | Użytkownik nie widzi generacji innych użytkowników | `spec/requests/generations_spec.rb` |
| TC-006 | CSRF token jest wymagany dla POST/PATCH/DELETE | `spec/requests/authorization_spec.rb` |

### 11.2 Wysokie (P1) - Główna funkcjonalność

| ID | Przypadek testowy | Lokalizacja |
|----|-------------------|-------------|
| TC-010 | Tworzenie manualnej fiszki z poprawnymi danymi | `spec/requests/flashcards_spec.rb` |
| TC-011 | Walidacja długości pola front (max 200 znaków) | `spec/models/flashcard_spec.rb` |
| TC-012 | Walidacja długości pola back (max 500 znaków) | `spec/models/flashcard_spec.rb` |
| TC-013 | Generowanie fiszek przez AI z poprawnym tekstem | `spec/requests/generations_spec.rb` |
| TC-014 | Walidacja długości source_text (1000-10000) | `spec/models/generation_spec.rb` |
| TC-015 | Zapisywanie wybranych fiszek z generacji | `spec/requests/generations_spec.rb` |
| TC-016 | Zmiana source na ai_edited przy edycji | `spec/models/flashcard_spec.rb` |
| TC-017 | Maksymalnie 20 fiszek na generację | `spec/services/ai_generation_service_spec.rb` |

### 11.3 Średnie (P2) - Obsługa błędów i edge cases

| ID | Przypadek testowy | Lokalizacja |
|----|-------------------|-------------|
| TC-020 | Obsługa timeout API Openrouter.ai | `spec/services/ai_generation_service_spec.rb` |
| TC-021 | Retry przy błędach transient API | `spec/services/ai_generation_service_spec.rb` |
| TC-022 | Zwrócenie 503 gdy AI niedostępne | `spec/requests/generations_spec.rb` |
| TC-023 | Walidacja formatu email przy rejestracji | `spec/models/user_spec.rb` |
| TC-024 | Unikalność adresu email | `spec/models/user_spec.rb` |
| TC-025 | Minimalna długość hasła (6 znaków) | `spec/models/user_spec.rb` |

### 11.4 Niskie (P3) - UX i metryki

| ID | Przypadek testowy | Lokalizacja |
|----|-------------------|-------------|
| TC-030 | Zliczanie generated_count w Generation | `spec/models/generation_spec.rb` |
| TC-031 | Zliczanie accepted_unedited_count | `spec/models/generation_spec.rb` |
| TC-032 | Zliczanie accepted_edited_count | `spec/models/generation_spec.rb` |
| TC-033 | Obliczanie acceptance rate | `spec/models/generation_spec.rb` |
| TC-034 | Flash messages po operacjach CRUD | `spec/requests/flashcards_spec.rb` |
| TC-035 | Turbo responses (format HTML) | `spec/requests/` |

---

## Załącznik A: Struktura katalogów testowych

```
spec/
├── factories/
│   ├── flashcards.rb
│   ├── generations.rb
│   └── users.rb
├── models/
│   ├── flashcard_spec.rb
│   ├── generation_spec.rb
│   └── user_spec.rb
├── requests/
│   ├── authorization_spec.rb
│   ├── flashcards_spec.rb
│   └── generations_spec.rb
├── services/
│   └── ai_generation_service_spec.rb
├── system/
│   ├── authentication_spec.rb
│   ├── flashcard_workflows_spec.rb
│   └── ai_generation_workflows_spec.rb
├── support/
│   ├── capybara.rb
│   └── factory_bot.rb
├── rails_helper.rb
└── spec_helper.rb
```

---

## Załącznik B: Komendy uruchamiania testów

```bash
# Wszystkie testy
bundle exec rspec

# Tylko testy modeli
bundle exec rspec spec/models

# Tylko testy request
bundle exec rspec spec/requests

# Tylko testy systemowe
bundle exec rspec spec/system

# Konkretny plik
bundle exec rspec spec/models/flashcard_spec.rb

# Z pokryciem kodu
COVERAGE=true bundle exec rspec

# Skanowanie bezpieczeństwa
bin/brakeman --no-pager
bin/bundler-audit check --update

# Linting
bin/rubocop
```
