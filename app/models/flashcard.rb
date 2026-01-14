class Flashcard < ApplicationRecord
  belongs_to :user
  belongs_to :generation, optional: true

  validates :front, presence: true, length: { maximum: 200 }
  validates :back, presence: true, length: { maximum: 500 }
  validates :source, presence: true

  enum :source, { manual: 'manual', ai_full: 'ai_full', ai_edited: 'ai_edited' }
end
