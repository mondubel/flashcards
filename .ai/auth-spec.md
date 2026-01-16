# Specyfikacja techniczna modułu autentykacji

## 1. Architektura interfejsu użytkownika

### 1.1 Dedykowany layout dla stron autentykacji

Strony autentykacji (logowanie, rejestracja) korzystają z osobnego layoutu `layouts/devise.html.erb`, który zapewnia:

- Wycentrowany kontener
- Logo aplikacji "Flashcards" z podtytułem
- Stopkę z informacją o prawach autorskich

### 1.2 Formularz rejestracji

**Lokalizacja widoku:** `app/views/devise/registrations/new.html.erb`

**Elementy formularza:**

| Pole | Typ | Wymagane | Walidacja |
|------|-----|----------|-----------|
| Email | `email_field` | Tak | Format email, unikalność |
| Hasło | `password_field` | Tak | Minimum 6 znaków |
| Potwierdzenie hasła | `password_field` | Tak | Zgodność z hasłem |

**Elementy interfejsu:**
- Nagłówek: "Create your account"
- Podtytuł: "Start your learning journey today"
- Informacja o minimalnej długości hasła (dynamicznie z konfiguracji)
- Przycisk submit: "Create account"
- Linki nawigacyjne do logowania

### 1.3 Formularz logowania

**Lokalizacja widoku:** `app/views/devise/sessions/new.html.erb`

**Elementy formularza:**

| Pole | Typ | Wymagane |
|------|-----|----------|
| Email | `email_field` | Tak |
| Hasło | `password_field` | Tak |
| Zapamiętaj mnie | `check_box` | Nie |

**Elementy interfejsu:**
- Nagłówek: "Welcome back"
- Podtytuł: "Sign in to continue learning"
- Checkbox "Remember me" (opcjonalny)
- Przycisk submit: "Sign in"
- Linki nawigacyjne do rejestracji

### 1.4 Formularz edycji profilu

**Lokalizacja widoku:** `app/views/devise/registrations/edit.html.erb`

**Elementy formularza:**

| Pole | Typ | Wymagane | Opis |
|------|-----|----------|------|
| Email | `email_field` | Tak | Aktualny email użytkownika |
| Nowe hasło | `password_field` | Nie | Puste = bez zmiany |
| Potwierdzenie nowego hasła | `password_field` | Nie | Wymagane jeśli zmiana hasła |
| Aktualne hasło | `password_field` | Tak | Weryfikacja tożsamości |

**Elementy interfejsu:**
- Nagłówek: "Edit Profile"
- Podtytuł: "Update your account settings"
- Informacja o minimalnej długości hasła
- Przycisk submit: "Update profile"
- Sekcja usuwania konta z ostrzeżeniem i przyciskiem "Delete my account"
- Link powrotny "Back"

### 1.5 Komponent komunikatów błędów

**Lokalizacja:** `app/views/devise/shared/_error_messages.html.erb`

**Komunikaty wyświetlane dla:**
- Niepoprawny format email
- Hasło zbyt krótkie
- Hasła nie są zgodne
- Email już zajęty
- Niepoprawne dane logowania

### 1.6 Komponent linków nawigacyjnych

**Lokalizacja:** `app/views/devise/shared/_links.html.erb`

**Linki warunkowe:**
- "Log in" - widoczny wszędzie oprócz strony logowania
- "Sign up" - widoczny wszędzie oprócz strony rejestracji

---

## 2. Logika backendowa

### 2.1 Model User

**Lokalizacja:** `app/models/user.rb`

```ruby
class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :rememberable, :validatable
end
```

**Moduły Devise:**

| Moduł | Funkcjonalność |
|-------|----------------|
| `database_authenticatable` | Autentykacja przez email i hasło (bcrypt) |
| `registerable` | Rejestracja, edycja i usuwanie konta |
| `rememberable` | Zapamiętywanie sesji przez cookie |
| `validatable` | Walidacja email i hasła |

### 2.2 Schemat bazy danych

**Tabela `users`:**

| Kolumna | Typ | Ograniczenia | Opis |
|---------|-----|--------------|------|
| `id` | bigint | PK, auto | Identyfikator |
| `email` | string | NOT NULL, UNIQUE | Adres email |
| `encrypted_password` | string | NOT NULL | Zahaszowane hasło (bcrypt) |
| `remember_created_at` | datetime | NULL | Timestamp "zapamiętaj mnie" |
| `created_at` | datetime | NOT NULL | Data utworzenia |
| `updated_at` | datetime | NOT NULL | Data aktualizacji |

**Indeksy:**
- `index_users_on_email` (UNIQUE) - szybkie wyszukiwanie i unikalność

### 2.3 Struktura endpointów (routing)

**Konfiguracja:** `config/routes.rb`

```ruby
devise_for :users
```

**Wygenerowane ścieżki:**

| Metoda | Ścieżka | Kontroler#Akcja | Nazwa pomocnicza |
|--------|---------|-----------------|------------------|
| GET | `/users/sign_in` | `devise/sessions#new` | `new_user_session_path` |
| POST | `/users/sign_in` | `devise/sessions#create` | `user_session_path` |
| DELETE | `/users/sign_out` | `devise/sessions#destroy` | `destroy_user_session_path` |
| GET | `/users/sign_up` | `devise/registrations#new` | `new_user_registration_path` |
| POST | `/users` | `devise/registrations#create` | `user_registration_path` |
| GET | `/users/edit` | `devise/registrations#edit` | `edit_user_registration_path` |
| PUT | `/users` | `devise/registrations#update` | `user_registration_path` |
| DELETE | `/users` | `devise/registrations#destroy` | `user_registration_path` |

### 2.4 Walidacja danych wejściowych

**Walidacja email (moduł validatable):**
- Obecność (nie może być puste)
- Format: regex `/\A[^@\s]+@[^@\s]+\z/`
- Unikalność (case-insensitive)
- Automatyczne usuwanie białych znaków (strip)
- Automatyczna konwersja do małych liter

**Walidacja hasła (moduł validatable):**
- Obecność (nie może być puste)
- Długość: 6-128 znaków (konfigurowalne)
- Potwierdzenie hasła (przy rejestracji i zmianie)

### 2.5 Ochrona zasobów

**Metody pomocnicze Devise dostępne w kontrolerach:**
- `authenticate_user!` - wymusza logowanie (przekierowanie do `/users/sign_in`)
- `current_user` - aktualnie zalogowany użytkownik
- `user_signed_in?` - sprawdza czy użytkownik jest zalogowany

### 2.6 Obsługa wyjątków i błędów

**Błędy autentykacji:**
- Niepoprawne dane logowania → render formularza z błędem (status 422)
- Brak dostępu → przekierowanie do logowania (status 303)

**Błędy walidacji:**
- Devise automatycznie renderuje formularz z błędami
- Status HTTP: 422 Unprocessable Entity
- Błędy dostępne przez `resource.errors`

---

## 3. System autentykacji

### 3.1 Konfiguracja Devise

**Lokalizacja:** `config/initializers/devise.rb`

**Kluczowe ustawienia:**

| Opcja | Wartość | Opis |
|-------|---------|------|
| `mailer_sender` | email | Adres nadawcy maili |
| `case_insensitive_keys` | `[:email]` | Email case-insensitive |
| `strip_whitespace_keys` | `[:email]` | Usuwanie białych znaków |
| `skip_session_storage` | `[:http_auth]` | Pominięcie sesji dla HTTP Auth |
| `stretches` | 12 (1 w testach) | Koszt hashowania bcrypt |
| `password_length` | 6..128 | Dozwolona długość hasła |
| `email_regexp` | `/\A[^@\s]+@[^@\s]+\z/` | Regex walidacji email |
| `expire_all_remember_me_on_sign_out` | true | Unieważnienie tokenów przy wylogowaniu |
| `sign_out_via` | `:delete` | Metoda HTTP dla wylogowania |

### 3.2 Przepływ rejestracji

1. Użytkownik otwiera `/users/sign_up`
2. Wypełnia formularz (email, hasło, potwierdzenie hasła)
3. Wysyła formularz (POST `/users`)
4. Devise waliduje dane:
   - Email: format, unikalność
   - Hasło: długość, zgodność z potwierdzeniem
5. Jeśli walidacja przejdzie:
   - Hasło hashowane przez bcrypt (12 rund)
   - Rekord zapisany w bazie
   - Użytkownik automatycznie zalogowany
   - Przekierowanie do strony głównej z komunikatem sukcesu
6. Jeśli walidacja nie przejdzie:
   - Formularz renderowany ponownie z błędami
   - Status HTTP 422

### 3.3 Przepływ logowania

1. Użytkownik otwiera `/users/sign_in`
2. Wypełnia formularz (email, hasło, opcjonalnie "Remember me")
3. Wysyła formularz (POST `/users/sign_in`)
4. Devise weryfikuje dane:
   - Wyszukuje użytkownika po email (case-insensitive)
   - Porównuje hasło z zahashowanym (bcrypt)
5. Jeśli dane poprawne:
   - Sesja tworzona w cookie
   - Jeśli "Remember me" zaznaczone → dodatkowy token w cookie
   - Przekierowanie do strony głównej
6. Jeśli dane niepoprawne:
   - Formularz renderowany z błędem "Invalid Email or password."
   - Status HTTP 422

### 3.4 Przepływ wylogowania

1. Użytkownik klika ikonę wylogowania
2. Wysyłane żądanie DELETE `/users/sign_out`
3. Devise:
   - Usuwa sesję
   - Unieważnia token "Remember me" (jeśli istnieje)
4. Przekierowanie do strony logowania z komunikatem

### 3.5 Mechanizm "Remember Me"

**Działanie:**
- Checkbox w formularzu logowania
- Po zaznaczeniu: token zapisany w cookie
- Czas ważności: 2 tygodnie (domyślnie)
- Przy wylogowaniu: wszystkie tokeny unieważniane

**Konfiguracja:**
```ruby
config.expire_all_remember_me_on_sign_out = true
```

### 3.6 Bezpieczeństwo sesji

**Ochrona CSRF:**
- Token CSRF w meta tagach (`csrf_meta_tags`)
- Automatyczna walidacja przez Rails
- Turbo wysyła token automatycznie

**Hashowanie haseł:**
- Algorytm: bcrypt
- Koszt: 12 rund (produkcja), 1 runda (testy)
- Salt generowany automatycznie

**Izolacja danych:**
- Każdy kontroler używa `current_user.flashcards` (scope)
- Brak możliwości dostępu do danych innych użytkowników
- `before_action :authenticate_user!` na chronionych kontrolerach

### 3.7 Edycja i usuwanie konta

**Edycja profilu:**
- Zmiana email wymaga podania aktualnego hasła
- Zmiana hasła wymaga podania aktualnego hasła
- Puste pole hasła = brak zmiany

**Usuwanie konta:**
- Przycisk "Delete my account" z potwierdzeniem (`data-turbo-confirm`)
- Kaskadowe usunięcie wszystkich powiązanych rekordów:
  - Generacje (`generations`)
  - Fiszki (`flashcards`)
- Wylogowanie i przekierowanie do strony logowania
