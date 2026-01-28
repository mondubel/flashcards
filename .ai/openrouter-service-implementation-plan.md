# OpenRouter Service Implementation Plan

## 1. Opis usługi

`OpenRouterService` to usługa Ruby odpowiedzialna za komunikację z API OpenRouter.ai w celu realizacji zapytań do modeli językowych (LLM). Usługa ta enkapsuluje całą logikę związaną z formatowaniem żądań, obsługą odpowiedzi, oraz zarządzaniem błędami związanymi z komunikacją z zewnętrznym API.

### Główne cele usługi:
- Abstrakcja szczegółów implementacji API OpenRouter
- Zapewnienie typobezpiecznego interfejsu do komunikacji z LLM
- Obsługa strukturyzowanych odpowiedzi poprzez JSON Schema
- Centralizacja obsługi błędów i logowania
- Umożliwienie łatwej konfiguracji parametrów modelu

## 2. Opis konstruktora

```ruby
def initialize(model:, temperature: 0.7, max_tokens: 2000, api_key: nil)
```

### Parametry konstruktora:

1. **`model`** (String, wymagany)
   - Nazwa modelu z katalogu OpenRouter (np. `"openai/gpt-4-turbo"`, `"anthropic/claude-3-opus"`)
   - Pełna lista dostępnych modeli: https://openrouter.ai/models

2. **`temperature`** (Float, opcjonalny, domyślnie: 0.7)
   - Kontroluje losowość odpowiedzi (0.0 - 2.0)
   - Niższe wartości = bardziej deterministyczne odpowiedzi
   - Wyższe wartości = bardziej kreatywne odpowiedzi

3. **`max_tokens`** (Integer, opcjonalny, domyślnie: 2000)
   - Maksymalna liczba tokenów w odpowiedzi
   - Zapobiega nadmiernym kosztom i zbyt długim odpowiedziom

4. **`api_key`** (String, opcjonalny)
   - Klucz API do OpenRouter
   - Jeśli nie podano, używa `ENV['OPENROUTER_API_KEY']`

### Przykład użycia:

```ruby
# Podstawowe użycie z domyślnymi parametrami
service = OpenRouterService.new(model: "openai/gpt-4-turbo")

# Pełna konfiguracja
service = OpenRouterService.new(
  model: "anthropic/claude-3-opus",
  temperature: 0.3,
  max_tokens: 4000,
  api_key: "sk-or-v1-..."
)
```

## 3. Publiczne metody i pola

### 3.1. Metoda `complete`

Główna metoda do wykonywania zapytań do modelu z możliwością strukturyzowania odpowiedzi.

```ruby
def complete(system_message:, user_message:, response_format: nil)
```

#### Parametry:

1. **`system_message`** (String, wymagany)
   - Instrukcje systemowe definiujące zachowanie modelu
   - Określa rolę, kontekst i ograniczenia
   - Przykład:
   ```ruby
   system_message = <<~PROMPT
     You are an expert educational content creator specializing in flashcard generation.
     Create high-quality flashcards from the provided text that:
     - Focus on key concepts and facts
     - Use clear, concise language
     - Include context when necessary
     - Avoid ambiguity
   PROMPT
   ```

2. **`user_message`** (String, wymagany)
   - Treść zapytania użytkownika
   - Zawiera dane do przetworzenia przez model
   - Przykład:
   ```ruby
   user_message = "Generate flashcards from the following text: #{source_text}"
   ```

3. **`response_format`** (Hash, opcjonalny)
   - Definiuje strukturę oczekiwanej odpowiedzi w formacie JSON Schema
   - Zapewnia typobezpieczność i walidację odpowiedzi
   - Format zgodny z OpenRouter API:
   ```ruby
   {
     type: 'json_schema',
     json_schema: {
       name: 'flashcards_generation',
       strict: true,
       schema: {
         type: 'object',
         properties: {
           flashcards: {
             type: 'array',
             items: {
               type: 'object',
               properties: {
                 question: { type: 'string' },
                 answer: { type: 'string' }
               },
               required: ['question', 'answer'],
               additionalProperties: false
             }
           }
         },
         required: ['flashcards'],
         additionalProperties: false
       }
     }
   }
   ```

#### Zwracana wartość:

- **Sukces**: Hash z parsowanymi danymi JSON
- **Błąd**: Zgłasza wyjątek `OpenRouterService::Error` lub jego podklasy

#### Przykład użycia:

```ruby
# Bez strukturyzowanej odpowiedzi
response = service.complete(
  system_message: "You are a helpful assistant.",
  user_message: "Explain photosynthesis in simple terms."
)
# => { "content" => "Photosynthesis is the process..." }

# Ze strukturyzowaną odpowiedzią
response_format = {
  type: 'json_schema',
  json_schema: {
    name: 'flashcards_list',
    strict: true,
    schema: {
      type: 'object',
      properties: {
        flashcards: {
          type: 'array',
          items: {
            type: 'object',
            properties: {
              question: { type: 'string' },
              answer: { type: 'string' }
            },
            required: ['question', 'answer'],
            additionalProperties: false
          }
        }
      },
      required: ['flashcards'],
      additionalProperties: false
    }
  }
}

response = service.complete(
  system_message: "Generate educational flashcards.",
  user_message: "Create 3 flashcards about photosynthesis.",
  response_format: response_format
)
# => { "flashcards" => [{"question" => "...", "answer" => "..."}, ...] }
```

### 3.2. Publiczne pola (getters)

```ruby
attr_reader :model, :temperature, :max_tokens
```

Umożliwiają odczyt konfiguracji usługi po inicjalizacji.

## 4. Prywatne metody i pola

### 4.1. Pole `@api_key`

```ruby
attr_reader :api_key
private :api_key
```

Przechowuje klucz API. Prywatne dla bezpieczeństwa.

### 4.2. Metoda `build_request_body`

```ruby
private

def build_request_body(system_message:, user_message:, response_format:)
```

Konstruuje ciało żądania HTTP do API OpenRouter.

#### Struktura zwracanego Hash:

```ruby
{
  model: @model,
  messages: [
    { role: "system", content: system_message },
    { role: "user", content: user_message }
  ],
  temperature: @temperature,
  max_tokens: @max_tokens
}
```

Jeśli podano `response_format`, dodaje klucz `response_format` do Hash.

### 4.3. Metoda `make_request`

```ruby
private

def make_request(body)
```

Wykonuje zapytanie HTTP POST do API OpenRouter.

#### Odpowiedzialności:
- Ustawia odpowiednie nagłówki HTTP
- Serializuje body do JSON
- Wykonuje zapytanie z timeoutami
- Obsługuje błędy sieciowe
- Parsuje odpowiedź JSON

#### Konfiguracja HTTP:
- Endpoint: `https://openrouter.ai/api/v1/chat/completions`
- Content-Type: `application/json`
- Authorization: `Bearer #{api_key}`
- HTTP-Referer: URL aplikacji (opcjonalny, dla statystyk)
- X-Title: Nazwa aplikacji (opcjonalny, dla statystyk)

#### Timeouty:
- Open timeout: 5 sekund
- Read timeout: 60 sekund (dla dłuższych generacji)

### 4.4. Metoda `parse_response`

```ruby
private

def parse_response(response)
```

Parsuje odpowiedź z API i ekstraktuje treść wiadomości.

#### Logika:
1. Sprawdza status code odpowiedzi
2. Parsuje JSON
3. Ekstraktuje treść z `response['choices'][0]['message']['content']`
4. Jeśli użyto `response_format`, parsuje treść jako JSON
5. Zwraca sparsowane dane

### 4.5. Metoda `handle_error_response`

```ruby
private

def handle_error_response(response)
```

Konwertuje kody błędów HTTP na odpowiednie wyjątki aplikacyjne.

#### Mapowanie błędów:
- 400 Bad Request → `InvalidRequestError`
- 401 Unauthorized → `AuthenticationError`
- 402 Payment Required → `InsufficientCreditsError`
- 429 Too Many Requests → `RateLimitError`
- 500+ Server Errors → `ServerError`
- Inne → `APIError`

## 5. Obsługa błędów

### 5.1. Hierarchia wyjątków

```ruby
class OpenRouterService
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class AuthenticationError < Error; end
  class InvalidRequestError < Error; end
  class RateLimitError < Error; end
  class InsufficientCreditsError < Error; end
  class ServerError < Error; end
  class APIError < Error; end
  class NetworkError < Error; end
  class ResponseParseError < Error; end
end
```

### 5.2. Scenariusze błędów i ich obsługa

#### Scenariusz 1: Brak klucza API
**Kiedy**: Brak zmiennej środowiskowej i parametru konstruktora
**Wyjątek**: `ConfigurationError`
**Komunikat**: `"OpenRouter API key is missing. Provide api_key parameter or set OPENROUTER_API_KEY environment variable."`

#### Scenariusz 2: Nieprawidłowy klucz API
**Kiedy**: HTTP 401
**Wyjątek**: `AuthenticationError`
**Komunikat**: `"Invalid API key. Please check your OpenRouter credentials."`

#### Scenariusz 3: Nieprawidłowy format żądania
**Kiedy**: HTTP 400
**Wyjątek**: `InvalidRequestError`
**Komunikat**: Szczegóły błędu z API

#### Scenariusz 4: Limit żądań przekroczony
**Kiedy**: HTTP 429
**Wyjątek**: `RateLimitError`
**Komunikat**: `"Rate limit exceeded. Please try again later."`
**Retry-After**: Header w odpowiedzi (jeśli dostępny)

#### Scenariusz 5: Brak środków na koncie
**Kiedy**: HTTP 402
**Wyjątek**: `InsufficientCreditsError`
**Komunikat**: `"Insufficient credits. Please add funds to your OpenRouter account."`

#### Scenariusz 6: Timeout sieci
**Kiedy**: Net::OpenTimeout, Net::ReadTimeout
**Wyjątek**: `NetworkError`
**Komunikat**: `"Network timeout. The request took too long to complete."`

#### Scenariusz 7: Błąd serwera OpenRouter
**Kiedy**: HTTP 500+
**Wyjątek**: `ServerError`
**Komunikat**: `"OpenRouter server error. Please try again later."`

#### Scenariusz 8: Nieprawidłowy format odpowiedzi
**Kiedy**: Błąd parsowania JSON
**Wyjątek**: `ResponseParseError`
**Komunikat**: `"Unable to parse API response."`

### 5.3. Strategia obsługi błędów w aplikacji

```ruby
# W kontrolerze
def create
  @generation = current_user.generations.build(generation_params)
  
  return render_validation_error unless @generation.valid?
  
  begin
    flashcards = generate_flashcards(@generation.source_text)
    save_generation_with_flashcards(@generation, flashcards)
    redirect_to generation_path(@generation), notice: "Flashcards generated successfully."
  rescue OpenRouterService::RateLimitError => e
    handle_rate_limit_error(e)
  rescue OpenRouterService::InsufficientCreditsError => e
    handle_insufficient_credits_error(e)
  rescue OpenRouterService::NetworkError => e
    handle_network_error(e)
  rescue OpenRouterService::Error => e
    handle_general_error(e)
  end
end

private

def handle_rate_limit_error(error)
  flash.now[:alert] = "Too many requests. Please try again in a few minutes."
  render :new, status: :too_many_requests
end

def handle_insufficient_credits_error(error)
  flash.now[:alert] = "Service temporarily unavailable. Please try again later."
  render :new, status: :service_unavailable
end

def handle_network_error(error)
  flash.now[:alert] = "Connection timeout. Please try again."
  render :new, status: :request_timeout
end

def handle_general_error(error)
  Rails.logger.error("OpenRouter error: #{error.class} - #{error.message}")
  flash.now[:alert] = "Failed to generate flashcards. Please try again."
  render :new, status: :unprocessable_entity
end
```

## 6. Kwestie bezpieczeństwa

### 6.1. Ochrona klucza API

#### Dobre praktyki:
1. **Nigdy** nie commituj kluczy API do repozytorium
2. Używaj zmiennych środowiskowych (`ENV['OPENROUTER_API_KEY']`)
3. W produkcji używaj systemu zarządzania sekretami (AWS Secrets Manager, Rails credentials)
4. Rotuj klucze regularnie

#### Konfiguracja w Rails:

```ruby
# config/credentials.yml.enc (produkcja)
openrouter:
  api_key: sk-or-v1-xxxxxxxxxxxxx

# Dostęp w kodzie
api_key = Rails.application.credentials.dig(:openrouter, :api_key)
```

#### Plik .env dla development (z gem dotenv-rails):

```bash
# .env (dodaj do .gitignore!)
OPENROUTER_API_KEY=sk-or-v1-xxxxxxxxxxxxx
```

### 6.2. Walidacja i sanityzacja danych wejściowych

```ruby
# W modelu
validates :source_text, presence: true, length: { minimum: 100, maximum: 10_000 }

# Przed wysłaniem do API
def sanitize_input(text)
  text.strip.gsub(/\s+/, ' ') # Usuń nadmiarowe białe znaki
end
```

### 6.3. Rate limiting po stronie aplikacji

```ruby
# Implementacja prostego rate limitingu w cache
def check_rate_limit(user_id)
  key = "openrouter:rate_limit:#{user_id}"
  count = Rails.cache.read(key) || 0
  
  if count >= 10 # 10 żądań na godzinę
    raise OpenRouterService::RateLimitError, "User rate limit exceeded"
  end
  
  Rails.cache.write(key, count + 1, expires_in: 1.hour)
end
```

### 6.4. Logowanie i monitoring

```ruby
# Loguj wszystkie żądania do API (bez wrażliwych danych)
def log_api_request(model:, tokens_estimate:)
  Rails.logger.info({
    service: 'OpenRouterService',
    action: 'complete',
    model: model,
    tokens_estimate: tokens_estimate,
    timestamp: Time.current
  }.to_json)
end

# Loguj błędy z kontekstem
def log_api_error(error, context = {})
  Rails.logger.error({
    service: 'OpenRouterService',
    error_class: error.class.name,
    error_message: error.message,
    context: context,
    backtrace: error.backtrace.first(5),
    timestamp: Time.current
  }.to_json)
end
```

### 6.5. Timeout i resource limits

```ruby
# Zapobiegaj zawieszeniu aplikacji
http.open_timeout = 5  # Maksymalnie 5s na połączenie
http.read_timeout = 60 # Maksymalnie 60s na odpowiedź

# Limit maksymalnej liczby tokenów
MAX_TOKENS_LIMIT = 4000
```

## 7. Plan wdrożenia krok po kroku

### Krok 1: Przygotowanie środowiska

#### 1.1. Dodanie zależności do Gemfile

```ruby
# Gemfile
gem 'httparty', '~> 0.21' # Do zapytań HTTP (alternatywa: 'faraday')
```

Zainstaluj:
```bash
bundle install
```

#### 1.2. Konfiguracja zmiennych środowiskowych

```bash
# .env (development)
OPENROUTER_API_KEY=sk-or-v1-xxxxxxxxxxxxx

# .env.example (commituj do repo)
OPENROUTER_API_KEY=
```

Dodaj `.env` do `.gitignore`.

#### 1.3. Konfiguracja Rails credentials (production)

```bash
EDITOR="vim" rails credentials:edit

# Dodaj:
# openrouter:
#   api_key: sk-or-v1-production-key
```

### Krok 2: Utworzenie struktury usługi

#### 2.1. Utwórz katalog dla usług

```bash
mkdir -p app/services
```

#### 2.2. Utwórz plik usługi

```bash
touch app/services/openrouter_service.rb
```

### Krok 3: Implementacja podstawowej struktury usługi

```ruby
# app/services/openrouter_service.rb

class OpenRouterService
  API_ENDPOINT = 'https://openrouter.ai/api/v1/chat/completions'
  DEFAULT_TEMPERATURE = 0.7
  DEFAULT_MAX_TOKENS = 2000
  DEFAULT_TIMEOUT = 60
  
  attr_reader :model, :temperature, :max_tokens
  
  # Hierarchia wyjątków
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class AuthenticationError < Error; end
  class InvalidRequestError < Error; end
  class RateLimitError < Error; end
  class InsufficientCreditsError < Error; end
  class ServerError < Error; end
  class APIError < Error; end
  class NetworkError < Error; end
  class ResponseParseError < Error; end
  
  def initialize(model:, temperature: DEFAULT_TEMPERATURE, max_tokens: DEFAULT_MAX_TOKENS, api_key: nil)
    @model = model
    @temperature = temperature
    @max_tokens = max_tokens
    @api_key = api_key || fetch_api_key
    
    validate_configuration!
  end
  
  def complete(system_message:, user_message:, response_format: nil)
    body = build_request_body(
      system_message: system_message,
      user_message: user_message,
      response_format: response_format
    )
    
    response = make_request(body)
    parse_response(response, structured: response_format.present?)
  end
  
  private
  
  attr_reader :api_key
  
  def fetch_api_key
    Rails.application.credentials.dig(:openrouter, :api_key) ||
      ENV['OPENROUTER_API_KEY']
  end
  
  def validate_configuration!
    if api_key.blank?
      raise ConfigurationError,
        "OpenRouter API key is missing. Provide api_key parameter or set OPENROUTER_API_KEY."
    end
    
    if model.blank?
      raise ConfigurationError, "Model name is required."
    end
  end
  
  def build_request_body(system_message:, user_message:, response_format:)
    body = {
      model: model,
      messages: [
        { role: "system", content: system_message },
        { role: "user", content: user_message }
      ],
      temperature: temperature,
      max_tokens: max_tokens
    }
    
    body[:response_format] = response_format if response_format.present?
    body
  end
  
  def make_request(body)
    # Implementacja w następnym kroku
  end
  
  def parse_response(response, structured:)
    # Implementacja w następnym kroku
  end
  
  def handle_error_response(status_code, body)
    # Implementacja w następnym kroku
  end
end
```

### Krok 4: Implementacja zapytań HTTP

#### 4.1. Opcja A: Użycie Net::HTTP (bez dodatkowych gemów)

```ruby
require 'net/http'
require 'json'

private

def make_request(body)
  uri = URI(API_ENDPOINT)
  
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.open_timeout = 5
  http.read_timeout = DEFAULT_TIMEOUT
  
  request = Net::HTTP::Post.new(uri.path)
  request['Content-Type'] = 'application/json'
  request['Authorization'] = "Bearer #{api_key}"
  request['HTTP-Referer'] = Rails.application.routes.url_helpers.root_url
  request['X-Title'] = 'Flashcards App'
  request.body = body.to_json
  
  response = http.request(request)
  
  return response if response.is_a?(Net::HTTPSuccess)
  
  handle_error_response(response.code.to_i, response.body)
rescue Net::OpenTimeout, Net::ReadTimeout => e
  raise NetworkError, "Network timeout: #{e.message}"
rescue StandardError => e
  raise APIError, "Unexpected error: #{e.message}"
end
```

#### 4.2. Opcja B: Użycie HTTParty

```ruby
require 'httparty'

private

def make_request(body)
  response = HTTParty.post(
    API_ENDPOINT,
    headers: {
      'Content-Type' => 'application/json',
      'Authorization' => "Bearer #{api_key}",
      'HTTP-Referer' => Rails.application.routes.url_helpers.root_url,
      'X-Title' => 'Flashcards App'
    },
    body: body.to_json,
    timeout: DEFAULT_TIMEOUT
  )
  
  return response if response.success?
  
  handle_error_response(response.code, response.body)
rescue HTTParty::TimeoutError => e
  raise NetworkError, "Network timeout: #{e.message}"
rescue StandardError => e
  raise APIError, "Unexpected error: #{e.message}"
end
```

### Krok 5: Implementacja parsowania odpowiedzi

```ruby
private

def parse_response(response, structured:)
  body = response.is_a?(String) ? JSON.parse(response) : response.parsed_response
  
  content = body.dig('choices', 0, 'message', 'content')
  
  if content.blank?
    raise ResponseParseError, "No content in API response"
  end
  
  # Jeśli użyto strukturyzowanej odpowiedzi, parsuj jako JSON
  if structured
    JSON.parse(content)
  else
    { 'content' => content }
  end
rescue JSON::ParserError => e
  raise ResponseParseError, "Failed to parse response: #{e.message}"
end

def handle_error_response(status_code, body)
  error_message = extract_error_message(body)
  
  case status_code
  when 400
    raise InvalidRequestError, error_message
  when 401
    raise AuthenticationError, "Invalid API key. Please check your OpenRouter credentials."
  when 402
    raise InsufficientCreditsError, "Insufficient credits. Please add funds to your OpenRouter account."
  when 429
    raise RateLimitError, "Rate limit exceeded. Please try again later."
  when 500..599
    raise ServerError, "OpenRouter server error (#{status_code}). Please try again later."
  else
    raise APIError, "API error (#{status_code}): #{error_message}"
  end
end

def extract_error_message(body)
  parsed = JSON.parse(body)
  parsed.dig('error', 'message') || 'Unknown error'
rescue JSON::ParserError
  body.to_s
end
```

### Krok 6: Utworzenie obiektu service dla generacji fiszek

#### 6.1. Utwórz dedykowany service object

```bash
touch app/services/flashcard_generation_service.rb
```

#### 6.2. Implementacja FlashcardGenerationService

```ruby
# app/services/flashcard_generation_service.rb

class FlashcardGenerationService
  SYSTEM_PROMPT = <<~PROMPT
    You are an expert educational content creator specializing in flashcard generation.
    Your task is to create high-quality flashcards from the provided text.
    
    Guidelines:
    - Focus on key concepts, definitions, and important facts
    - Each question should be clear and unambiguous
    - Answers should be concise but complete
    - Include context in the question when necessary
    - Avoid yes/no questions; prefer questions that require understanding
    - Generate between 5 and 15 flashcards depending on content richness
    - Ensure questions test understanding, not just memorization
  PROMPT
  
  RESPONSE_FORMAT = {
    type: 'json_schema',
    json_schema: {
      name: 'flashcards_generation',
      strict: true,
      schema: {
        type: 'object',
        properties: {
          flashcards: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                question: {
                  type: 'string',
                  description: 'The question on the front of the flashcard'
                },
                answer: {
                  type: 'string',
                  description: 'The answer on the back of the flashcard'
                }
              },
              required: ['question', 'answer'],
              additionalProperties: false
            }
          }
        },
        required: ['flashcards'],
        additionalProperties: false
      }
    }
  }.freeze
  
  def initialize(model: 'openai/gpt-4-turbo', temperature: 0.7)
    @openrouter = OpenRouterService.new(
      model: model,
      temperature: temperature,
      max_tokens: 3000
    )
  end
  
  def generate(source_text)
    raise ArgumentError, "Source text cannot be blank" if source_text.blank?
    
    user_message = build_user_message(source_text)
    
    response = @openrouter.complete(
      system_message: SYSTEM_PROMPT,
      user_message: user_message,
      response_format: RESPONSE_FORMAT
    )
    
    validate_and_extract_flashcards(response)
  end
  
  private
  
  def build_user_message(source_text)
    <<~MESSAGE
      Generate educational flashcards from the following text:
      
      #{source_text}
      
      Create flashcards that will help a student learn and retain the key information from this text.
    MESSAGE
  end
  
  def validate_and_extract_flashcards(response)
    flashcards = response['flashcards']
    
    if flashcards.blank? || !flashcards.is_a?(Array)
      raise OpenRouterService::ResponseParseError, "Invalid flashcards format"
    end
    
    flashcards.map do |card|
      {
        question: card['question'].strip,
        answer: card['answer'].strip
      }
    end
  end
end
```

### Krok 7: Integracja z kontrolerem

#### 7.1. Aktualizacja GenerationsController

```ruby
# app/controllers/generations_controller.rb

class GenerationsController < ApplicationController
  before_action :authenticate_user!
  
  def create
    @generation = current_user.generations.build(generation_params)
    
    unless @generation.valid?
      flash.now[:alert] = "Please check the errors below."
      return render :new, status: :unprocessable_entity
    end
    
    begin
      flashcards_data = generate_flashcards(@generation.source_text)
      save_generation_with_flashcards(@generation, flashcards_data)
      
      redirect_to generation_path(@generation), 
                  notice: "Successfully generated #{flashcards_data.count} flashcards."
    rescue OpenRouterService::RateLimitError
      handle_rate_limit_error
    rescue OpenRouterService::InsufficientCreditsError
      handle_insufficient_credits_error
    rescue OpenRouterService::NetworkError
      handle_network_error
    rescue OpenRouterService::Error => e
      handle_api_error(e)
    end
  end
  
  private
  
  def generate_flashcards(source_text)
    service = FlashcardGenerationService.new
    service.generate(source_text)
  end
  
  def save_generation_with_flashcards(generation, flashcards_data)
    ActiveRecord::Base.transaction do
      generation.save!
      
      flashcards_data.each do |card_data|
        generation.flashcards.create!(
          user: current_user,
          question: card_data[:question],
          answer: card_data[:answer]
        )
      end
    end
  end
  
  def handle_rate_limit_error
    flash.now[:alert] = "Too many requests. Please try again in a few minutes."
    render :new, status: :too_many_requests
  end
  
  def handle_insufficient_credits_error
    flash.now[:alert] = "Service temporarily unavailable. Please contact support."
    render :new, status: :service_unavailable
  end
  
  def handle_network_error
    flash.now[:alert] = "Connection timeout. Please check your internet connection and try again."
    render :new, status: :request_timeout
  end
  
  def handle_api_error(error)
    Rails.logger.error("OpenRouter API error: #{error.class} - #{error.message}")
    Rails.logger.error(error.backtrace.join("\n"))
    
    flash.now[:alert] = "Failed to generate flashcards. Please try again or contact support if the problem persists."
    render :new, status: :unprocessable_entity
  end
  
  def generation_params
    params.require(:generation).permit(:source_text)
  end
end
```

### Krok 8: Testy jednostkowe

#### 8.1. Testy dla OpenRouterService

```bash
touch spec/services/openrouter_service_spec.rb
```

```ruby
# spec/services/openrouter_service_spec.rb

require 'rails_helper'

RSpec.describe OpenRouterService do
  describe '#initialize' do
    it 'raises ConfigurationError when API key is missing' do
      allow(ENV).to receive(:[]).with('OPENROUTER_API_KEY').and_return(nil)
      allow(Rails.application.credentials).to receive(:dig).with(:openrouter, :api_key).and_return(nil)
      
      expect {
        described_class.new(model: 'openai/gpt-4')
      }.to raise_error(OpenRouterService::ConfigurationError, /API key is missing/)
    end
    
    it 'accepts API key from environment variable' do
      allow(ENV).to receive(:[]).with('OPENROUTER_API_KEY').and_return('test-key')
      
      service = described_class.new(model: 'openai/gpt-4')
      
      expect(service.model).to eq('openai/gpt-4')
    end
    
    it 'uses default parameters when not provided' do
      allow(ENV).to receive(:[]).with('OPENROUTER_API_KEY').and_return('test-key')
      
      service = described_class.new(model: 'openai/gpt-4')
      
      expect(service.temperature).to eq(0.7)
      expect(service.max_tokens).to eq(2000)
    end
  end
  
  describe '#complete' do
    let(:service) do
      described_class.new(
        model: 'openai/gpt-4',
        api_key: 'test-key'
      )
    end
    
    let(:system_message) { 'You are a helpful assistant.' }
    let(:user_message) { 'Hello, world!' }
    
    context 'when request is successful' do
      it 'returns parsed response' do
        stub_successful_response
        
        response = service.complete(
          system_message: system_message,
          user_message: user_message
        )
        
        expect(response).to eq({ 'content' => 'Hello! How can I help you?' })
      end
    end
    
    context 'when using structured output' do
      let(:response_format) do
        {
          type: 'json_schema',
          json_schema: {
            name: 'test_schema',
            strict: true,
            schema: {
              type: 'object',
              properties: {
                message: { type: 'string' }
              },
              required: ['message']
            }
          }
        }
      end
      
      it 'returns structured response' do
        stub_structured_response
        
        response = service.complete(
          system_message: system_message,
          user_message: user_message,
          response_format: response_format
        )
        
        expect(response).to eq({ 'message' => 'Hello! How can I help you?' })
      end
    end
    
    context 'when API returns error' do
      it 'raises AuthenticationError on 401' do
        stub_error_response(401, 'Invalid API key')
        
        expect {
          service.complete(system_message: system_message, user_message: user_message)
        }.to raise_error(OpenRouterService::AuthenticationError)
      end
      
      it 'raises RateLimitError on 429' do
        stub_error_response(429, 'Rate limit exceeded')
        
        expect {
          service.complete(system_message: system_message, user_message: user_message)
        }.to raise_error(OpenRouterService::RateLimitError)
      end
    end
  end
  
  private
  
  def stub_successful_response
    stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
      .to_return(
        status: 200,
        body: {
          choices: [
            { message: { content: 'Hello! How can I help you?' } }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
  
  def stub_structured_response
    stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
      .to_return(
        status: 200,
        body: {
          choices: [
            { message: { content: '{"message":"Hello! How can I help you?"}' } }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
  
  def stub_error_response(status, message)
    stub_request(:post, 'https://openrouter.ai/api/v1/chat/completions')
      .to_return(
        status: status,
        body: { error: { message: message } }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end
```

#### 8.2. Dodanie webmock do Gemfile

```ruby
# Gemfile
group :test do
  gem 'webmock'
end
```

```bash
bundle install
```

#### 8.3. Konfiguracja webmock

```ruby
# spec/rails_helper.rb
require 'webmock/rspec'

RSpec.configure do |config|
  config.before(:each) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end
end
```

### Krok 9: Monitoring i logowanie

#### 9.1. Dodanie logowania do usługi

```ruby
# app/services/openrouter_service.rb

def complete(system_message:, user_message:, response_format: nil)
  log_request_start(user_message)
  
  body = build_request_body(
    system_message: system_message,
    user_message: user_message,
    response_format: response_format
  )
  
  response = make_request(body)
  result = parse_response(response, structured: response_format.present?)
  
  log_request_success
  result
rescue OpenRouterService::Error => e
  log_request_error(e)
  raise
end

private

def log_request_start(user_message)
  Rails.logger.info({
    service: 'OpenRouterService',
    action: 'complete',
    model: model,
    message_length: user_message.length,
    timestamp: Time.current
  }.to_json)
end

def log_request_success
  Rails.logger.info({
    service: 'OpenRouterService',
    action: 'complete',
    status: 'success',
    timestamp: Time.current
  }.to_json)
end

def log_request_error(error)
  Rails.logger.error({
    service: 'OpenRouterService',
    action: 'complete',
    status: 'error',
    error_class: error.class.name,
    error_message: error.message,
    timestamp: Time.current
  }.to_json)
end
```

### Krok 10: Dokumentacja użycia

#### 10.1. Utwórz dokumentację

```bash
touch docs/openrouter_service_usage.md
```

#### 10.2. Przykłady użycia

```markdown
# OpenRouter Service - Przewodnik użycia

## Podstawowe użycie

### Proste zapytanie

```ruby
service = OpenRouterService.new(model: 'openai/gpt-4-turbo')

response = service.complete(
  system_message: 'You are a helpful assistant.',
  user_message: 'Explain quantum computing in simple terms.'
)

puts response['content']
```

### Strukturyzowana odpowiedź

```ruby
response_format = {
  type: 'json_schema',
  json_schema: {
    name: 'explanation',
    strict: true,
    schema: {
      type: 'object',
      properties: {
        summary: { type: 'string' },
        key_points: {
          type: 'array',
          items: { type: 'string' }
        }
      },
      required: ['summary', 'key_points']
    }
  }
}

response = service.complete(
  system_message: 'Provide structured explanations.',
  user_message: 'Explain photosynthesis.',
  response_format: response_format
)

puts response['summary']
response['key_points'].each { |point| puts "- #{point}" }
```

## Obsługa błędów

```ruby
begin
  response = service.complete(
    system_message: system_msg,
    user_message: user_msg
  )
rescue OpenRouterService::RateLimitError
  # Poczekaj i spróbuj ponownie
  sleep 60
  retry
rescue OpenRouterService::InsufficientCreditsError
  # Powiadom administratora
  AdminMailer.insufficient_credits.deliver_now
rescue OpenRouterService::Error => e
  # Ogólna obsługa błędów
  Rails.logger.error(e.message)
  raise
end
```
```

### Krok 11: Checklist wdrożenia

- [ ] Dodano gem do obsługi HTTP (httparty lub użycie Net::HTTP)
- [ ] Skonfigurowano zmienne środowiskowe dla development
- [ ] Skonfigurowano Rails credentials dla production
- [ ] Utworzono katalog `app/services`
- [ ] Zaimplementowano `OpenRouterService` z wszystkimi metodami
- [ ] Zaimplementowano `FlashcardGenerationService`
- [ ] Zaktualizowano `GenerationsController`
- [ ] Dodano obsługę błędów w kontrolerze
- [ ] Napisano testy jednostkowe dla usług
- [ ] Dodano logowanie żądań i błędów
- [ ] Przetestowano ręcznie w środowisku development
- [ ] Utworzono dokumentację użycia
- [ ] Skonfigurowano monitoring (opcjonalnie)
- [ ] Przeprowadzono code review
- [ ] Wdrożono na production

## Podsumowanie

Ten plan wdrożenia zapewnia:
- ✅ Kompletną implementację komunikacji z OpenRouter API
- ✅ Typobezpieczne strukturyzowane odpowiedzi przez JSON Schema
- ✅ Kompleksową obsługę błędów z dedykowanymi wyjątkami
- ✅ Bezpieczeństwo poprzez zarządzanie sekretami
- ✅ Logowanie i monitoring dla celów debugowania
- ✅ Separation of concerns (usługa ogólna + usługa domenowa)
- ✅ Testy jednostkowe dla zapewnienia jakości
- ✅ Dokumentację dla przyszłych deweloperów

Implementacja ta jest zgodna z Rails best practices, zasadami SOLID oraz wytycznymi projektu dotyczącymi service objects i thin controllers.
