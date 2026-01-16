# Schemat bazy danych PostgreSQL - Flashcards MVP

## 1. Tabele

### 1.1 Tabela `users`

Tabela użytkowników zarządzana przez Devise.

| Kolumna | Typ | Ograniczenia | Opis |
|---------|-----|--------------|------|
| `id` | `BIGSERIAL` | `PRIMARY KEY` | Unikalny identyfikator użytkownika |
| `email` | `VARCHAR(255)` | `NOT NULL, UNIQUE` | Adres email użytkownika |
| `encrypted_password` | `VARCHAR(255)` | `NOT NULL` | Zaszyfrowane hasło (Devise) |
| `reset_password_token` | `VARCHAR(255)` | `UNIQUE` | Token resetowania hasła |
| `reset_password_sent_at` | `TIMESTAMP` | - | Czas wysłania tokenu resetowania |
| `remember_created_at` | `TIMESTAMP` | - | Czas utworzenia sesji "zapamiętaj mnie" |
| `created_at` | `TIMESTAMP` | `NOT NULL` | Data utworzenia rekordu |
| `updated_at` | `TIMESTAMP` | `NOT NULL` | Data ostatniej modyfikacji |

### 1.2 Tabela `generations`

Przechowuje sesje generowania fiszek przez AI.

| Kolumna | Typ | Ograniczenia | Opis |
|---------|-----|--------------|------|
| `id` | `BIGSERIAL` | `PRIMARY KEY` | Unikalny identyfikator generacji |
| `user_id` | `BIGINT` | `NOT NULL, FOREIGN KEY` | Referencja do użytkownika |
| `source_text` | `TEXT` | `NOT NULL` | Tekst źródłowy do generowania fiszek |
| `model` | `VARCHAR(100)` | - | Nazwa modelu AI użytego do generacji |
| `generation_duration` | `INTEGER` | - | Czas generowania w milisekundach |
| `generated_count` | `INTEGER` | `NOT NULL DEFAULT 0` | Liczba wygenerowanych fiszek |
| `accepted_unedited_count` | `INTEGER` | `DEFAULT NULL` | Liczba zaakceptowanych fiszek bez edycji |
| `accepted_edited_count` | `INTEGER` | `DEFAULT NULL` | Liczba zaakceptowanych fiszek z edycją |
| `created_at` | `TIMESTAMP` | `NOT NULL` | Data utworzenia rekordu |
| `updated_at` | `TIMESTAMP` | `NOT NULL` | Data ostatniej modyfikacji |

### 1.3 Tabela `flashcards`

Przechowuje fiszki użytkowników (manualne i wygenerowane przez AI).

| Kolumna | Typ | Ograniczenia | Opis |
|---------|-----|--------------|------|
| `id` | `BIGSERIAL` | `PRIMARY KEY` | Unikalny identyfikator fiszki |
| `user_id` | `BIGINT` | `NOT NULL, FOREIGN KEY` | Referencja do użytkownika |
| `generation_id` | `BIGINT` | `FOREIGN KEY, NULLABLE` | Referencja do sesji generacji (NULL dla fiszek manualnych) |
| `front` | `TEXT` | `NOT NULL` | Przód fiszki (pytanie) |
| `back` | `TEXT` | `NOT NULL` | Tył fiszki (odpowiedź) |
| `source` | `VARCHAR(20)` | `NOT NULL` | Źródło fiszki: 'manual', 'ai-full', 'ai-edited' |
| `created_at` | `TIMESTAMP` | `NOT NULL` | Data utworzenia rekordu |
| `updated_at` | `TIMESTAMP` | `NOT NULL` | Data ostatniej modyfikacji |

## 2. Relacje między tabelami

```
┌─────────┐       ┌─────────────┐       ┌────────────┐
│  users  │       │ generations │       │ flashcards │
├─────────┤       ├─────────────┤       ├────────────┤
│ id (PK) │◄──┐   │ id (PK)     │◄──┐   │ id (PK)    │
│ email   │   │   │ user_id(FK) │───┘   │ user_id(FK)│───┐
│ ...     │   │   │ ...         │       │ gen_id(FK) │───┤
└─────────┘   │   └─────────────┘       │ ...        │   │
              │                         └────────────┘   │
              └─────────────────────────────────────────┘
```

### Kardynalność relacji

| Relacja | Typ | Opis |
|---------|-----|------|
| `users` → `generations` | Jeden-do-wielu (1:N) | Użytkownik może mieć wiele sesji generacji |
| `users` → `flashcards` | Jeden-do-wielu (1:N) | Użytkownik może mieć wiele fiszek |
| `generations` → `flashcards` | Jeden-do-wielu (1:N), opcjonalna | Sesja generacji może mieć wiele fiszek; fiszka manualna nie ma powiązania |


## 3. Indeksy

| Tabela | Indeks | Kolumny | Typ | Uzasadnienie |
|--------|--------|---------|-----|--------------|
| `users` | `index_users_on_email` | `email` | UNIQUE | Wyszukiwanie użytkownika po emailu (logowanie) |
| `users` | `index_users_on_reset_password_token` | `reset_password_token` | UNIQUE | Wyszukiwanie tokenu resetowania hasła |
| `generations` | `index_generations_on_user_id` | `user_id` | B-tree | Pobieranie historii generacji użytkownika |
| `flashcards` | `index_flashcards_on_user_id` | `user_id` | B-tree | Pobieranie wszystkich fiszek użytkownika |
| `flashcards` | `index_flashcards_on_generation_id` | `generation_id` | B-tree | Pobieranie fiszek z danej generacji; wydajność CASCADE przy usuwaniu |


## 4. Zasady PostgreSQL (RLS)

Zgodnie z decyzjami z sesji planowania, **Row Level Security (RLS) nie jest implementowane** na poziomie bazy danych. Kontrola dostępu do danych jest realizowana przez warstwę aplikacji Rails z wykorzystaniem:

- Scope'ów ActiveRecord (`current_user.flashcards`, `current_user.generations`)
- Autoryzacji w kontrolerach
- Autentykacji przez Devise

Ta decyzja upraszcza architekturę MVP i jest wystarczająca dla monolitycznej aplikacji Rails.

## 5. Dodatkowe uwagi i wyjaśnienia

1. **Klucze główne BIGSERIAL**
   - Standardowy typ w Rails, prostszy i wydajniejszy niż UUID dla aplikacji monolitycznej
   - Automatyczna inkrementacja przez PostgreSQL

2. **Pole `source` jako VARCHAR(20) zamiast ENUM PostgreSQL**
   - Łatwiejsze zarządzanie wartościami w Rails
   - Walidacja `inclusion` w modelu Rails
   - Dozwolone wartości: `'manual'`, `'ai-full'`, `'ai-edited'`

3. **Nullable `generation_id` w flashcards**
   - Fiszki manualne (`source: 'manual'`) nie mają powiązania z generacją
   - Fiszki AI (`source: 'ai-full'` lub `'ai-edited'`) mają obowiązkowe powiązanie
   - Spójność zapewniana przez walidację w Rails

4. **Pola TEXT bez limitów długości**
   - PostgreSQL efektywnie przechowuje TEXT niezależnie od długości
   - Limity zdefiniowane w PRD walidowane na poziomie Rails:
     - `front`: max 200 znaków
     - `back`: max 500 znaków
     - `source_text`: 1000-10000 znaków

5. **Strategia usuwania: Hard Delete**
   - Brak soft delete (kolumny `deleted_at`)
   - Prostsze zarządzanie danymi w MVP
   - `ON DELETE CASCADE` dla automatycznego usuwania powiązanych rekordów

6. **Liczniki w generations**
   - `generated_count`, `accepted_unedited_count`, `accepted_edited_count`
   - Aktualizowane przez serwisy/callbacks w Rails
   - Służą do obliczania metryk sukcesu (75% akceptacji fiszek AI)
