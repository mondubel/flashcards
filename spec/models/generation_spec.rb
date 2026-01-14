require 'rails_helper'

RSpec.describe Generation, type: :model do
  describe 'associations' do
    it 'belongs to user' do
      user = create(:user)
      generation = create(:generation, user: user)

      expect(generation.user).to eq(user)
    end

    it 'has many flashcards' do
      user = create(:user)
      generation = create(:generation, user: user)
      flashcard1 = create(:flashcard, :ai_full, user: user, generation: generation)
      flashcard2 = create(:flashcard, :ai_full, user: user, generation: generation)

      expect(generation.flashcards).to contain_exactly(flashcard1, flashcard2)
    end

    it 'nullifies flashcards generation_id when generation is destroyed' do
      user = create(:user)
      generation = create(:generation, user: user)
      flashcard = create(:flashcard, :ai_full, user: user, generation: generation)

      generation.destroy

      flashcard.reload
      expect(flashcard.generation_id).to be_nil
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      generation = build(:generation)

      expect(generation.valid?).to be true
    end

    it 'is invalid without source_text' do
      generation = build(:generation, source_text: nil)

      expect(generation.valid?).to be false
      expect(generation.errors[:source_text]).to include("can't be blank")
    end

    it 'is invalid with source_text shorter than 1000 characters' do
      generation = build(:generation, source_text: 'a' * 999)

      expect(generation.valid?).to be false
      expect(generation.errors[:source_text]).to include('is too short (minimum is 1000 characters)')
    end

    it 'is valid with source_text exactly 1000 characters' do
      generation = build(:generation, source_text: 'a' * 1000)

      expect(generation.valid?).to be true
    end

    it 'is invalid with source_text longer than 10000 characters' do
      generation = build(:generation, source_text: 'a' * 10_001)

      expect(generation.valid?).to be false
      expect(generation.errors[:source_text]).to include('is too long (maximum is 10000 characters)')
    end

    it 'is valid with source_text exactly 10000 characters' do
      generation = build(:generation, source_text: 'a' * 10_000)

      expect(generation.valid?).to be true
    end

    it 'is invalid without user' do
      generation = build(:generation, user: nil)

      expect(generation.valid?).to be false
      expect(generation.errors[:user]).to be_present
    end
  end
end
