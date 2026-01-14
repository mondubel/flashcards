require 'rails_helper'

RSpec.describe Flashcard, type: :model do
  describe 'associations' do
    it 'belongs to user' do
      user = create(:user)
      flashcard = create(:flashcard, user: user)

      expect(flashcard.user).to eq(user)
    end

    it 'belongs to generation optionally' do
      user = create(:user)
      generation = create(:generation, user: user)
      flashcard = create(:flashcard, :ai_full, user: user, generation: generation)

      expect(flashcard.generation).to eq(generation)
    end

    it 'is valid without generation for manual flashcards' do
      flashcard = build(:flashcard, :manual)

      expect(flashcard.valid?).to be true
      expect(flashcard.generation).to be_nil
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      flashcard = build(:flashcard)

      expect(flashcard.valid?).to be true
    end

    it 'is invalid without front' do
      flashcard = build(:flashcard, front: nil)

      expect(flashcard.valid?).to be false
      expect(flashcard.errors[:front]).to include("can't be blank")
    end

    it 'is invalid with empty front' do
      flashcard = build(:flashcard, front: '')

      expect(flashcard.valid?).to be false
      expect(flashcard.errors[:front]).to include("can't be blank")
    end

    it 'is invalid with front longer than 200 characters' do
      flashcard = build(:flashcard, front: 'a' * 201)

      expect(flashcard.valid?).to be false
      expect(flashcard.errors[:front]).to include('is too long (maximum is 200 characters)')
    end

    it 'is valid with front exactly 200 characters' do
      flashcard = build(:flashcard, front: 'a' * 200)

      expect(flashcard.valid?).to be true
    end

    it 'is invalid without back' do
      flashcard = build(:flashcard, back: nil)

      expect(flashcard.valid?).to be false
      expect(flashcard.errors[:back]).to include("can't be blank")
    end

    it 'is invalid with empty back' do
      flashcard = build(:flashcard, back: '')

      expect(flashcard.valid?).to be false
      expect(flashcard.errors[:back]).to include("can't be blank")
    end

    it 'is invalid with back longer than 500 characters' do
      flashcard = build(:flashcard, back: 'a' * 501)

      expect(flashcard.valid?).to be false
      expect(flashcard.errors[:back]).to include('is too long (maximum is 500 characters)')
    end

    it 'is valid with back exactly 500 characters' do
      flashcard = build(:flashcard, back: 'a' * 500)

      expect(flashcard.valid?).to be true
    end

    it 'is invalid without source' do
      flashcard = build(:flashcard, source: nil)

      expect(flashcard.valid?).to be false
      expect(flashcard.errors[:source]).to include("can't be blank")
    end

    it 'is invalid with invalid source value' do
      flashcard = build(:flashcard)

      expect { flashcard.source = 'invalid_source' }.to raise_error(ArgumentError)
    end

    it 'is valid with source manual' do
      flashcard = build(:flashcard, :manual)

      expect(flashcard.valid?).to be true
      expect(flashcard.source).to eq('manual')
    end

    it 'is valid with source ai_full' do
      flashcard = build(:flashcard, :ai_full)

      expect(flashcard.valid?).to be true
      expect(flashcard.source).to eq('ai_full')
    end

    it 'is valid with source ai_edited' do
      flashcard = build(:flashcard, :ai_edited)

      expect(flashcard.valid?).to be true
      expect(flashcard.source).to eq('ai_edited')
    end

    it 'is invalid without user' do
      flashcard = build(:flashcard, user: nil)

      expect(flashcard.valid?).to be false
      expect(flashcard.errors[:user]).to be_present
    end
  end

  describe 'enum source' do
    it 'defines manual, ai_full, and ai_edited sources' do
      expect(Flashcard.sources.keys).to contain_exactly('manual', 'ai_full', 'ai_edited')
    end

    it 'allows querying by source' do
      user = create(:user)
      manual_card = create(:flashcard, :manual, user: user)
      ai_card = create(:flashcard, :ai_full, user: user)

      expect(Flashcard.manual).to include(manual_card)
      expect(Flashcard.manual).not_to include(ai_card)
      expect(Flashcard.ai_full).to include(ai_card)
      expect(Flashcard.ai_full).not_to include(manual_card)
    end

    it 'allows checking source with predicate methods' do
      user = create(:user)
      manual_card = create(:flashcard, :manual, user: user)
      ai_full_card = create(:flashcard, :ai_full, user: user)
      ai_edited_card = create(:flashcard, :ai_edited, user: user)
      
      expect(manual_card.manual?).to be true
      expect(manual_card.ai_full?).to be false
      expect(ai_full_card.ai_full?).to be true
      expect(ai_edited_card.ai_edited?).to be true
    end
  end
end
