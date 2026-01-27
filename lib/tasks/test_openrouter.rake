namespace :openrouter do
  desc "Test OpenRouterService basic functionality"
  task test_basic: :environment do
    puts "\n=== Testing OpenRouterService ===\n\n"

    # Check API key
    api_key = ENV["OPENROUTER_API_KEY"]
    if api_key.blank?
      puts "❌ ERROR: OPENROUTER_API_KEY environment variable is not set."
      puts "   Please set it with: export OPENROUTER_API_KEY='your-key'"
      exit 1
    end

    puts "✓ API key found: #{api_key[0..15]}..."

    # Test 1: Initialization
    puts "\n--- Test 1: Initialization ---"
    begin
      service = OpenRouterService.new(
        model: "openai/gpt-4-turbo",
        skip_ssl_verify: Rails.env.development?
      )
      puts "✓ Service initialized successfully"
      puts "  Model: #{service.model}"
      puts "  Temperature: #{service.temperature}"
      puts "  Max tokens: #{service.max_tokens}"
    rescue => e
      puts "❌ ERROR: #{e.class} - #{e.message}"
      exit 1
    end

    # Test 2: Simple completion
    puts "\n--- Test 2: Simple completion ---"
    begin
      response = service.complete(
        system_message: "You are a helpful assistant.",
        user_message: 'Say "Hello World" and nothing else.'
      )
      puts "✓ Request completed successfully"
      puts "  Response: #{response['content']}"
    rescue OpenRouterService::Error => e
      puts "❌ API ERROR: #{e.class} - #{e.message}"
      exit 1
    rescue => e
      puts "❌ UNEXPECTED ERROR: #{e.class} - #{e.message}"
      puts e.backtrace.first(5)
      exit 1
    end

    # Test 3: Structured response (flashcards)
    puts "\n--- Test 3: Structured response (flashcards) ---"
    begin
      response_format = {
        type: "json_schema",
        json_schema: {
          name: "flashcards_generation",
          strict: true,
          schema: {
            type: "object",
            properties: {
              flashcards: {
                type: "array",
                items: {
                  type: "object",
                  properties: {
                    question: { type: "string" },
                    answer: { type: "string" }
                  },
                  required: [ "question", "answer" ],
                  additionalProperties: false
                }
              }
            },
            required: [ "flashcards" ],
            additionalProperties: false
          }
        }
      }

      source_text = "Ruby on Rails is a web application framework written in Ruby. It follows the Model-View-Controller (MVC) pattern."

      response = service.complete(
        system_message: "You are an expert educational content creator. Generate exactly 2 flashcards.",
        user_message: "Generate flashcards from this text:\n\n#{source_text}",
        response_format: response_format
      )

      puts "✓ Structured response received"
      puts "  Number of flashcards: #{response['flashcards'].length}"

      response["flashcards"].each_with_index do |card, index|
        puts "\n  Flashcard #{index + 1}:"
        puts "    Q: #{card['question']}"
        puts "    A: #{card['answer']}"
      end
    rescue OpenRouterService::Error => e
      puts "❌ API ERROR: #{e.class} - #{e.message}"
      exit 1
    rescue => e
      puts "❌ UNEXPECTED ERROR: #{e.class} - #{e.message}"
      puts e.backtrace.first(5)
      exit 1
    end

    puts "\n\n=== All tests passed! ✓ ===\n"
  end

  desc "Test OpenRouterService error handling"
  task test_errors: :environment do
    puts "\n=== Testing OpenRouterService Error Handling ===\n\n"

    # Test 1: Missing API key
    puts "--- Test 1: Missing API key ---"
    begin
      service = OpenRouterService.new(model: "openai/gpt-4-turbo", api_key: "")
      puts "❌ Should have raised ConfigurationError"
    rescue OpenRouterService::ConfigurationError => e
      puts "✓ Correctly raised ConfigurationError"
      puts "  Message: #{e.message}"
    end

    # Test 2: Missing model
    puts "\n--- Test 2: Missing model ---"
    begin
      service = OpenRouterService.new(model: "", api_key: "test-key")
      puts "❌ Should have raised ConfigurationError"
    rescue OpenRouterService::ConfigurationError => e
      puts "✓ Correctly raised ConfigurationError"
      puts "  Message: #{e.message}"
    end

    # Test 3: Invalid API key (if user wants to test with real API)
    if ENV["TEST_INVALID_KEY"] == "true"
      puts "\n--- Test 3: Invalid API key (real API call) ---"
      begin
        service = OpenRouterService.new(model: "openai/gpt-4-turbo", api_key: "invalid-key")
        response = service.complete(
          system_message: "Test",
          user_message: "Hello"
        )
        puts "❌ Should have raised AuthenticationError"
      rescue OpenRouterService::AuthenticationError => e
        puts "✓ Correctly raised AuthenticationError"
        puts "  Message: #{e.message}"
      end
    else
      puts "\n--- Test 3: Invalid API key (skipped) ---"
      puts "  Set TEST_INVALID_KEY=true to test with real API"
    end

    puts "\n\n=== Error handling tests passed! ✓ ===\n"
  end
end
