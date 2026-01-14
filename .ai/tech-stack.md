# Tech stack

Frontend – Ruby on Rails (Views) + Turbo:
- Ruby on Rails odpowiada za renderowanie widoków HTML po stronie serwera
- Turbo (Hotwire) umożliwia dynamiczne aktualizacje interfejsu bez pełnych przeładowań strony
- Brak osobnego frontendu SPA
- Tailwind CSS do stylowania interfejsu użytkownika

Backend – Ruby on Rails jako monolit aplikacyjny:
- Ruby on Rails obsługuje logikę biznesową aplikacji
- ActiveRecord jako ORM
- PostgreSQL jako relacyjna baza danych
- Aplikacja backendowa i frontendowa w jednym repozytorium

Autentykacja:
- Devise do obsługi rejestracji i logowania użytkowników
- Autentykacja oparta o email i hasło

AI – Komunikacja z modelami przez usługę Openrouter.ai:
- Dostęp do wielu modeli językowych (OpenAI, Anthropic, Google i inne)
- Komunikacja z AI realizowana po stronie backendu
- Możliwość konfiguracji limitów i kluczy API

CI/CD i Hosting:
- GitHub Actions do tworzenia pipeline’ów CI/CD
- AWS do hostowania aplikacji

