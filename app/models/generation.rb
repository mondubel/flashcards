class Generation < ApplicationRecord
  belongs_to :user
  has_many :flashcards, dependent: :nullify

  validates :source_text, presence: true, length: { minimum: 1000, maximum: 10_000 }
end
