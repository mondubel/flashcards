class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :rememberable, :validatable

  has_many :generations, dependent: :destroy
  has_many :flashcards, dependent: :destroy

  # Calculate AI acceptance rate for this user
  # (accepted_unedited_count + accepted_edited_count) / generated_count * 100
  def ai_acceptance_rate
    total_generated = generations.sum(:generated_count)
    return 0 if total_generated.zero?

    total_accepted = generations.sum(:accepted_unedited_count).to_i +
                    generations.sum(:accepted_edited_count).to_i

    (total_accepted.to_f / total_generated * 100).round(1)
  end

  # Calculate percentage of flashcards that are AI-generated for this user
  # COUNT(flashcards WHERE source IN ('ai_full', 'ai_edited')) / COUNT(flashcards) * 100
  def ai_flashcards_percentage
    total_flashcards = flashcards.count
    return 0 if total_flashcards.zero?

    ai_flashcards = flashcards.where(source: [ :ai_full, :ai_edited ]).count
    (ai_flashcards.to_f / total_flashcards * 100).round(1)
  end

  # System-wide statistics (class methods)
  def self.system_ai_acceptance_rate
    total_generated = Generation.sum(:generated_count)
    return 0 if total_generated.zero?

    total_accepted = Generation.sum(:accepted_unedited_count).to_i +
                    Generation.sum(:accepted_edited_count).to_i

    (total_accepted.to_f / total_generated * 100).round(1)
  end

  def self.system_ai_flashcards_percentage
    total_flashcards = Flashcard.count
    return 0 if total_flashcards.zero?

    ai_flashcards = Flashcard.where(source: [ :ai_full, :ai_edited ]).count
    (ai_flashcards.to_f / total_flashcards * 100).round(1)
  end

  def self.system_total_flashcards
    Flashcard.count
  end

  def self.system_total_users
    User.count
  end
end
