require 'rails_helper'

RSpec.describe "Authentication", type: :system do
  describe "User Registration (US-001)" do
    it "successfully registers a new user with valid data" do
      visit new_user_registration_path

      fill_in 'Email', with: 'newuser@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'password123'

      click_button 'Create account'

      expect(page).to have_current_path(root_path)
      expect(page).to have_content('My Cards')
    end

    it "automatically logs in the user after successful registration" do
      visit new_user_registration_path

      fill_in 'Email', with: 'autouser@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'password123'

      click_button 'Create account'

      expect(page).to have_selector('form[action="/users/sign_out"]')
      expect(page).to have_content('My Cards')
    end

    it "displays error message when email format is invalid" do
      visit new_user_registration_path

      fill_in 'Email', with: 'invalid-email'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'password123'

      click_button 'Create account'

      expect(page).to have_content('Email is invalid')
      expect(page).to have_current_path(user_registration_path)
    end

    it "displays error message when password is too short" do
      visit new_user_registration_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'short'
      fill_in 'Password confirmation', with: 'short'

      click_button 'Create account'

      expect(page).to have_content('Password is too short')
      expect(page).to have_current_path(user_registration_path)
    end

    it "displays error message when passwords do not match" do
      visit new_user_registration_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'different123'

      click_button 'Create account'

      expect(page).to have_content("Password confirmation doesn't match")
      expect(page).to have_current_path(user_registration_path)
    end

    it "displays error message when email is already taken" do
      create(:user, email: 'existing@example.com')

      visit new_user_registration_path

      fill_in 'Email', with: 'existing@example.com'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'password123'

      click_button 'Create account'

      expect(page).to have_content('Email has already been taken')
      expect(page).to have_current_path(user_registration_path)
    end

    it "preserves entered email on validation error" do
      visit new_user_registration_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'short'
      fill_in 'Password confirmation', with: 'short'

      click_button 'Create account'

      expect(page).to have_field('Email', with: 'user@example.com')
    end

    it "does not create a user record when validation fails" do
      visit new_user_registration_path

      fill_in 'Email', with: 'invalid-email'
      fill_in 'Password', with: 'password123'
      fill_in 'Password confirmation', with: 'password123'

      expect {
        click_button 'Create account'
      }.not_to change(User, :count)
    end
  end

  describe "User Login (US-002)" do
    it "successfully logs in with valid credentials" do
      user = create(:user, email: 'user@example.com', password: 'password123')

      visit new_user_session_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'password123'

      click_button 'Sign in'

      expect(page).to have_current_path(root_path)
      expect(page).to have_content('My Cards')
    end

    it "redirects to main page after successful login" do
      user = create(:user, email: 'user@example.com', password: 'password123')

      visit new_user_session_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'password123'

      click_button 'Sign in'

      expect(page).to have_current_path(root_path)
    end

    it "displays error message with invalid email" do
      create(:user, email: 'user@example.com', password: 'password123')

      visit new_user_session_path

      fill_in 'Email', with: 'wrong@example.com'
      fill_in 'Password', with: 'password123'

      click_button 'Sign in'

      expect(page).to have_content('Sign in')
      expect(page).to have_current_path(user_session_path)
      expect(page).to have_content('Invalid Email or password')
      expect(page).to have_selector('[role="alert"]')
    end

    it "displays error message with invalid password" do
      create(:user, email: 'user@example.com', password: 'password123')

      visit new_user_session_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'wrongpassword'

      click_button 'Sign in'

      expect(page).to have_content('Sign in')
      expect(page).to have_current_path(user_session_path)
      expect(page).to have_content('Invalid Email or password')
    end

    it "preserves email field on failed login attempt" do
      create(:user, email: 'user@example.com', password: 'password123')

      visit new_user_session_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'wrongpassword'

      click_button 'Sign in'

      expect(page).to have_field('Email', with: 'user@example.com')
    end

    it "displays navigation after successful login" do
      user = create(:user, email: 'user@example.com', password: 'password123')

      visit new_user_session_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'password123'

      click_button 'Sign in'

      expect(page).to have_content('My Cards')
      expect(page).to have_content('History')
    end

    it "allows access to protected resources after login" do
      user = create(:user, email: 'user@example.com', password: 'password123')

      visit new_user_session_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'password123'

      click_button 'Sign in'

      visit flashcards_path

      expect(page).to have_current_path(flashcards_path)
      expect(page).to have_content('My Cards')
    end

    it "does not allow login with empty credentials" do
      visit new_user_session_path

      fill_in 'Email', with: ''
      fill_in 'Password', with: ''

      click_button 'Sign in'

      expect(page).to have_content('Sign in')
      expect(page).to have_current_path(user_session_path)
      expect(page).to have_content('Invalid Email or password')
    end
  end

  describe "User Logout (US-009)" do
    it "successfully logs out a signed in user" do
      user = create(:user, email: 'user@example.com', password: 'password123')

      visit new_user_session_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'password123'
      click_button 'Sign in'

      # Click the logout button (it's inside a form)
      find('form[action="/users/sign_out"]').find('button').click

      expect(page).to have_content('Sign in')
    end

    it "redirects to sign in page after logout" do
      user = create(:user, email: 'user@example.com', password: 'password123')

      visit new_user_session_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'password123'
      click_button 'Sign in'

      find('form[action="/users/sign_out"]').find('button').click

      expect(page).to have_current_path(new_user_session_path)
    end

    it "displays sign in page after logout" do
      user = create(:user, email: 'user@example.com', password: 'password123')

      visit new_user_session_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'password123'
      click_button 'Sign in'

      find('form[action="/users/sign_out"]').find('button').click

      expect(page).to have_content('Sign in')
      expect(page).to have_content('Welcome back')
    end

    it "prevents access to flashcards after logout" do
      user = create(:user, email: 'user@example.com', password: 'password123')

      visit new_user_session_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'password123'
      click_button 'Sign in'

      find('form[action="/users/sign_out"]').find('button').click

      visit flashcards_path

      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_content('Sign in')
      expect(page).to have_content('You need to sign in or sign up before continuing')
      expect(page).to have_selector('[role="alert"]')
    end

    it "prevents creating flashcards after logout" do
      user = create(:user, email: 'user@example.com', password: 'password123')

      visit new_user_session_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'password123'
      click_button 'Sign in'

      find('form[action="/users/sign_out"]').find('button').click

      visit new_flashcard_path

      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_content('Sign in')
      expect(page).to have_content('You need to sign in or sign up before continuing')
    end

    it "prevents access to generations after logout" do
      user = create(:user, email: 'user@example.com', password: 'password123')

      visit new_user_session_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'password123'
      click_button 'Sign in'

      find('form[action="/users/sign_out"]').find('button').click

      visit generations_path

      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_content('Sign in')
      expect(page).to have_content('You need to sign in or sign up before continuing')
    end
  end

  describe "Authentication redirects and access control" do
    it "redirects unauthenticated users from flashcards index to sign in" do
      visit flashcards_path

      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_content('Sign in')
      expect(page).to have_content('You need to sign in or sign up before continuing')
    end

    it "redirects unauthenticated users from new flashcard to sign in" do
      visit new_flashcard_path

      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_content('Sign in')
      expect(page).to have_content('You need to sign in or sign up before continuing')
    end

    it "redirects unauthenticated users from generations to sign in" do
      visit generations_path

      expect(page).to have_current_path(new_user_session_path)
      expect(page).to have_content('Sign in')
      expect(page).to have_content('You need to sign in or sign up before continuing')
    end

    it "redirects already signed in user from sign in page to root" do
      user = create(:user, email: 'user@example.com', password: 'password123')

      visit new_user_session_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'password123'
      click_button 'Sign in'

      visit new_user_session_path

      expect(page).to have_current_path(root_path)
    end

    it "redirects already signed in user from sign up page to root" do
      user = create(:user, email: 'user@example.com', password: 'password123')

      visit new_user_session_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'password123'
      click_button 'Sign in'

      visit new_user_registration_path

      expect(page).to have_current_path(root_path)
    end
  end

  describe "Session persistence" do
    it "maintains user session across page navigation" do
      user = create(:user, email: 'user@example.com', password: 'password123')

      visit new_user_session_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'password123'
      click_button 'Sign in'

      visit flashcards_path
      expect(page).to have_current_path(flashcards_path)

      visit root_path
      expect(page).to have_content('My Cards')

      visit flashcards_path
      expect(page).to have_current_path(flashcards_path)
    end

    it "allows user to perform multiple protected actions in one session" do
      user = create(:user, email: 'user@example.com', password: 'password123')

      visit new_user_session_path

      fill_in 'Email', with: 'user@example.com'
      fill_in 'Password', with: 'password123'
      click_button 'Sign in'

      visit flashcards_path
      expect(page).to have_current_path(flashcards_path)

      visit generations_path
      expect(page).to have_current_path(generations_path)

      visit new_flashcard_path
      expect(page).to have_current_path(new_flashcard_path)
    end
  end
end
