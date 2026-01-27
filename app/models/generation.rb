class Generation < ApplicationRecord
  belongs_to :user
  has_many :flashcards, dependent: :nullify

  validates :source_text, presence: true, length: { minimum: 1000, maximum: 10_000 }

  # Ensure generated_flashcards is always an array
  def generated_flashcards
    value = super
    return [] if value.nil?
    return value if value.is_a?(Array)

    # If it's a string, try to parse it as JSON
    if value.is_a?(String)
      begin
        JSON.parse(value)
      rescue JSON::ParserError
        []
      end
    else
      []
    end
  end
end
