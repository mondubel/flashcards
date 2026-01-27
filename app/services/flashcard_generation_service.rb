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
    - Questions should be self-contained (include necessary context)
    - Answers should be specific and accurate
  PROMPT

  RESPONSE_FORMAT = {
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
                question: {
                  type: "string",
                  description: "The question on the front of the flashcard"
                },
                answer: {
                  type: "string",
                  description: "The answer on the back of the flashcard"
                }
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
  }.freeze

  # Modele które wspierają structured output
  DEFAULT_MODEL = "openai/gpt-4o-mini"
  FALLBACK_MODEL = "openai/gpt-4o"

  def initialize(model: DEFAULT_MODEL, temperature: 0.7)
    @model = model
    @temperature = temperature
  end

  def generate(source_text)
    raise ArgumentError, "Source text cannot be blank" if source_text.blank?

    start_time = Time.current
    user_message = build_user_message(source_text)

    response = openrouter_service.complete(
      system_message: SYSTEM_PROMPT,
      user_message: user_message,
      response_format: RESPONSE_FORMAT
    )

    flashcards = validate_and_extract_flashcards(response)
    end_time = Time.current
    duration_ms = ((end_time - start_time) * 1000).to_i

    {
      flashcards: flashcards,
      metadata: {
        model: @model,
        generation_duration: duration_ms,
        generated_count: flashcards.count
      }
    }
  end

  private

  def openrouter_service
    @openrouter_service ||= OpenRouterService.new(
      model: @model,
      temperature: @temperature,
      max_tokens: 3000,
      skip_ssl_verify: Rails.env.development? # Tylko dla developmentu, false w produkcji
    )
  end

  def build_user_message(source_text)
    <<~MESSAGE
      Generate educational flashcards from the following text:

      #{source_text}

      Create flashcards that will help a student learn and retain the key information from this text.
      Focus on the most important concepts and facts.
    MESSAGE
  end

  def validate_and_extract_flashcards(response)
    flashcards = response["flashcards"]

    if flashcards.blank? || !flashcards.is_a?(Array)
      raise OpenRouterService::ResponseParseError, "Invalid flashcards format in response"
    end

    if flashcards.empty?
      raise OpenRouterService::ResponseParseError, "No flashcards generated"
    end

    flashcards.map do |card|
      validate_flashcard!(card)

      {
        front: card["question"].strip,
        back: card["answer"].strip
      }
    end
  end

  def validate_flashcard!(card)
    if card["question"].blank?
      raise OpenRouterService::ResponseParseError, "Flashcard question cannot be blank"
    end

    if card["answer"].blank?
      raise OpenRouterService::ResponseParseError, "Flashcard answer cannot be blank"
    end

    if card["question"].length > 200
      raise OpenRouterService::ResponseParseError, "Flashcard question too long (max 200 characters)"
    end

    if card["answer"].length > 500
      raise OpenRouterService::ResponseParseError, "Flashcard answer too long (max 500 characters)"
    end
  end
end
