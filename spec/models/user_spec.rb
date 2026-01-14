require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it 'has many generations' do
      user = create(:user)
      generation1 = create(:generation, user: user)
      generation2 = create(:generation, user: user)

      expect(user.generations).to contain_exactly(generation1, generation2)
    end

    it 'has many flashcards' do
      user = create(:user)
      flashcard1 = create(:flashcard, user: user)
      flashcard2 = create(:flashcard, user: user)

      expect(user.flashcards).to contain_exactly(flashcard1, flashcard2)
    end

    it 'destroys associated generations when user is destroyed' do
      user = create(:user)
      generation = create(:generation, user: user)
      generation_id = generation.id

      user.destroy

      expect(Generation.find_by(id: generation_id)).to be_nil
    end

    it 'destroys associated flashcards when user is destroyed' do
      user = create(:user)
      flashcard = create(:flashcard, user: user)
      flashcard_id = flashcard.id

      user.destroy

      expect(Flashcard.find_by(id: flashcard_id)).to be_nil
    end
  end

  describe 'devise modules' do
    it 'is database authenticatable' do
      user = create(:user, password: 'password123')

      expect(user.valid_password?('password123')).to be true
      expect(user.valid_password?('wrongpassword')).to be false
    end

    it 'is registerable' do
      user = build(:user, email: 'newuser@example.com', password: 'password123')

      expect(user.save).to be true
      expect(User.find_by(email: 'newuser@example.com')).to eq(user)
    end

    it 'is validatable' do
      user = build(:user, email: 'invalid-email', password: 'short')

      expect(user.valid?).to be false
      expect(user.errors[:email]).to be_present
      expect(user.errors[:password]).to be_present
    end

    it 'requires unique email' do
      create(:user, email: 'test@example.com')
      duplicate_user = build(:user, email: 'test@example.com')

      expect(duplicate_user.valid?).to be false
      expect(duplicate_user.errors[:email]).to include('has already been taken')
    end
  end
end
