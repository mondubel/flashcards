require "net/http"
require "json"

class OpenRouterService
  API_ENDPOINT = "https://openrouter.ai/api/v1/chat/completions"
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

  def initialize(model:, temperature: DEFAULT_TEMPERATURE, max_tokens: DEFAULT_MAX_TOKENS, api_key: nil, skip_ssl_verify: true)
    @model = model
    @temperature = temperature
    @max_tokens = max_tokens
    @api_key = api_key || fetch_api_key
    @skip_ssl_verify = skip_ssl_verify

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
      ENV["OPENROUTER_API_KEY"]
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
    uri = URI(API_ENDPOINT)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = DEFAULT_TIMEOUT

    # UWAGA: skip_ssl_verify powinno być używane TYLKO w developmencie
    # W produkcji ZAWSZE używaj weryfikacji SSL
    if @skip_ssl_verify
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      Rails.logger.warn("⚠️  SSL verification is disabled for OpenRouterService. This should ONLY be used in development!")
    end

    request = Net::HTTP::Post.new(uri.path)
    request["Content-Type"] = "application/json"
    request["Authorization"] = "Bearer #{api_key}"
    request["HTTP-Referer"] = Rails.application.routes.url_helpers.root_url rescue "https://flashcards.app"
    request["X-Title"] = "Flashcards App"
    request.body = body.to_json

    if Rails.env.development?
      Rails.logger.debug("OpenRouter Request:")
      Rails.logger.debug("  Model: #{body[:model]}")
      Rails.logger.debug("  Temperature: #{body[:temperature]}")
      Rails.logger.debug("  Max tokens: #{body[:max_tokens]}")
      Rails.logger.debug("  System message: #{body[:messages][0][:content][0..100]}...")
      Rails.logger.debug("  User message: #{body[:messages][1][:content][0..100]}...")
    end

    response = http.request(request)

    if Rails.env.development?
      Rails.logger.debug("OpenRouter Response:")
      Rails.logger.debug("  Status: #{response.code}")
      Rails.logger.debug("  Body: #{response.body[0..500]}...")
    end

    return response if response.is_a?(Net::HTTPSuccess)

    handle_error_response(response.code.to_i, response.body)
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    raise NetworkError, "Network timeout: #{e.message}"
  rescue OpenRouterService::Error
    raise  # Re-raise our own errors
  rescue StandardError => e
    Rails.logger.error("OpenRouter Unexpected Error: #{e.class} - #{e.message}")
    Rails.logger.error(e.backtrace.first(5).join("\n"))
    raise APIError, "Unexpected error: #{e.message}"
  end

  def parse_response(response, structured:)
    body = JSON.parse(response.body)

    # Sprawdź czy jest błąd w body (nawet przy HTTP 200)
    if body["error"].present?
      error_message = body.dig("error", "message") || "Unknown error from provider"
      error_code = body.dig("error", "code") || "unknown"

      Rails.logger.error("OpenRouter Provider Error: #{error_code} - #{error_message}")
      Rails.logger.error("Full error body: #{body['error'].inspect}")

      # Próbuj zmapować błąd providera na nasze wyjątki
      case error_code
      when 400, "invalid_request_error"
        raise InvalidRequestError, error_message
      when 401, "authentication_error"
        raise AuthenticationError, error_message
      when 429, "rate_limit_error"
        raise RateLimitError, error_message
      when 502, 503
        raise ServerError, "Provider error: #{error_message}"
      else
        raise APIError, "API error (#{error_code}): #{error_message}"
      end
    end

    content = body.dig("choices", 0, "message", "content")

    if content.blank?
      Rails.logger.error("No content in response. Full body: #{body.inspect}")
      raise ResponseParseError, "No content in API response. Response: #{body.inspect}"
    end

    # Jeśli użyto strukturyzowanej odpowiedzi, parsuj jako JSON
    if structured
      JSON.parse(content)
    else
      { "content" => content }
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
    parsed.dig("error", "message") || "Unknown error"
  rescue JSON::ParserError
    body.to_s
  end
end
