require 'rails_helper'

RSpec.describe "Authentication", type: :request do
  describe "POST /users (registration)" do
    context "with valid parameters" do
      it "creates a new user" do
        valid_params = {
          user: {
            email: 'newuser@example.com',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }

        expect {
          post user_registration_path, params: valid_params
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:redirect)
      end

      it "signs in the user automatically after registration" do
        valid_params = {
          user: {
            email: 'newuser@example.com',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }

        post user_registration_path, params: valid_params

        expect(controller.current_user).to be_present
        expect(controller.current_user.email).to eq('newuser@example.com')
      end

      it "redirects to root path after successful registration" do
        valid_params = {
          user: {
            email: 'newuser@example.com',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }

        post user_registration_path, params: valid_params

        expect(response).to redirect_to(root_path)
      end
    end

    context "with invalid email format" do
      it "does not create a user" do
        invalid_params = {
          user: {
            email: 'invalid-email',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }

        expect {
          post user_registration_path, params: invalid_params
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "displays validation errors" do
        invalid_params = {
          user: {
            email: 'invalid-email',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }

        post user_registration_path, params: invalid_params

        expect(response.body).to include('Email is invalid')
      end
    end

    context "with password too short" do
      it "does not create a user" do
        invalid_params = {
          user: {
            email: 'user@example.com',
            password: 'short',
            password_confirmation: 'short'
          }
        }

        expect {
          post user_registration_path, params: invalid_params
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "displays password length error" do
        invalid_params = {
          user: {
            email: 'user@example.com',
            password: 'short',
            password_confirmation: 'short'
          }
        }

        post user_registration_path, params: invalid_params

        expect(response.body).to include('Password is too short')
      end
    end

    context "with mismatched passwords" do
      it "does not create a user" do
        invalid_params = {
          user: {
            email: 'user@example.com',
            password: 'password123',
            password_confirmation: 'different123'
          }
        }

        expect {
          post user_registration_path, params: invalid_params
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "displays password confirmation error" do
        invalid_params = {
          user: {
            email: 'user@example.com',
            password: 'password123',
            password_confirmation: 'different123'
          }
        }

        post user_registration_path, params: invalid_params

        expect(response.body).to match(/Password confirmation.*match/i)
      end
    end

    context "with duplicate email" do
      it "does not create a user" do
        create(:user, email: 'existing@example.com')
        duplicate_params = {
          user: {
            email: 'existing@example.com',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }

        expect {
          post user_registration_path, params: duplicate_params
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "displays email taken error" do
        create(:user, email: 'existing@example.com')
        duplicate_params = {
          user: {
            email: 'existing@example.com',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }

        post user_registration_path, params: duplicate_params

        expect(response.body).to include('Email has already been taken')
      end
    end
  end

  describe "POST /users/sign_in (login)" do
    context "with valid credentials" do
      it "signs in the user" do
        user = create(:user, email: 'user@example.com', password: 'password123')
        valid_params = {
          user: {
            email: 'user@example.com',
            password: 'password123'
          }
        }

        post user_session_path, params: valid_params

        expect(controller.current_user).to eq(user)
      end

      it "redirects to root path after successful login" do
        user = create(:user, email: 'user@example.com', password: 'password123')
        valid_params = {
          user: {
            email: 'user@example.com',
            password: 'password123'
          }
        }

        post user_session_path, params: valid_params

        expect(response).to redirect_to(root_path)
      end

      it "returns redirect status" do
        user = create(:user, email: 'user@example.com', password: 'password123')
        valid_params = {
          user: {
            email: 'user@example.com',
            password: 'password123'
          }
        }

        post user_session_path, params: valid_params

        expect(response).to have_http_status(:redirect)
      end
    end

    context "with invalid email" do
      it "does not sign in the user" do
        create(:user, email: 'user@example.com', password: 'password123')
        invalid_params = {
          user: {
            email: 'wrong@example.com',
            password: 'password123'
          }
        }

        post user_session_path, params: invalid_params

        expect(controller.current_user).to be_nil
      end

      it "re-renders sign in form with error" do
        create(:user, email: 'user@example.com', password: 'password123')
        invalid_params = {
          user: {
            email: 'wrong@example.com',
            password: 'password123'
          }
        }

        post user_session_path, params: invalid_params

        expect(response.body).to include('Sign in')
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "re-renders login form" do
        create(:user, email: 'user@example.com', password: 'password123')
        invalid_params = {
          user: {
            email: 'wrong@example.com',
            password: 'password123'
          }
        }

        post user_session_path, params: invalid_params

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with invalid password" do
      it "does not sign in the user" do
        create(:user, email: 'user@example.com', password: 'password123')
        invalid_params = {
          user: {
            email: 'user@example.com',
            password: 'wrongpassword'
          }
        }

        post user_session_path, params: invalid_params

        expect(controller.current_user).to be_nil
      end

      it "re-renders sign in form with error" do
        create(:user, email: 'user@example.com', password: 'password123')
        invalid_params = {
          user: {
            email: 'user@example.com',
            password: 'wrongpassword'
          }
        }

        post user_session_path, params: invalid_params

        expect(response.body).to include('Sign in')
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with missing credentials" do
      it "does not sign in without email" do
        invalid_params = {
          user: {
            email: '',
            password: 'password123'
          }
        }

        post user_session_path, params: invalid_params

        expect(controller.current_user).to be_nil
      end

      it "does not sign in without password" do
        create(:user, email: 'user@example.com', password: 'password123')
        invalid_params = {
          user: {
            email: 'user@example.com',
            password: ''
          }
        }

        post user_session_path, params: invalid_params

        expect(controller.current_user).to be_nil
      end
    end
  end

  describe "DELETE /users/sign_out (logout)" do
    context "when user is signed in" do
      it "signs out the user" do
        user = create(:user)
        sign_in user

        delete destroy_user_session_path

        expect(controller.current_user).to be_nil
      end

      it "redirects to root path after logout" do
        user = create(:user)
        sign_in user

        delete destroy_user_session_path

        expect(response).to redirect_to(root_path)
      end

      it "returns redirect status" do
        user = create(:user)
        sign_in user

        delete destroy_user_session_path

        expect(response).to have_http_status(:redirect)
      end
    end

    context "when accessing protected resources after logout" do
      it "cannot access flashcards index" do
        user = create(:user)
        sign_in user
        delete destroy_user_session_path

        get flashcards_path

        expect(response).to redirect_to(new_user_session_path)
      end

      it "cannot create flashcards" do
        user = create(:user)
        sign_in user
        delete destroy_user_session_path

        post flashcards_path, params: { flashcard: { front: 'Test', back: 'Test' } }

        expect(response).to redirect_to(new_user_session_path)
      end

      it "cannot access generations" do
        user = create(:user)
        sign_in user
        delete destroy_user_session_path

        get generations_path

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe "GET /users/sign_in (sign in page)" do
    it "displays sign in form" do
      get new_user_session_path

      expect(response).to have_http_status(:success)
      expect(response.body).to match(/log in|sign in/i)
    end

    it "redirects to root if already signed in" do
      user = create(:user)
      sign_in user

      get new_user_session_path

      expect(response).to redirect_to(root_path)
    end
  end

  describe "GET /users/sign_up (sign up page)" do
    it "displays sign up form" do
      get new_user_registration_path

      expect(response).to have_http_status(:success)
      expect(response.body).to match(/Create.*account|Sign up/i)
    end

    it "redirects to root if already signed in" do
      user = create(:user)
      sign_in user

      get new_user_registration_path

      expect(response).to redirect_to(root_path)
    end
  end
end
