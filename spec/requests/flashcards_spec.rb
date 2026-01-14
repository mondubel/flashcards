require 'rails_helper'

RSpec.describe "Flashcards", type: :request do
  describe "GET /flashcards" do
    context "when user is not authenticated" do
      it "redirects to sign in page" do
        get flashcards_path
        
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      it "returns successful response" do
        user = create(:user)
        sign_in user
        
        get flashcards_path
        
        expect(response).to have_http_status(:success)
      end

      it "displays only current user's flashcards" do
        user = create(:user)
        other_user = create(:user)
        user_flashcard = create(:flashcard, user: user, front: "User's card")
        other_flashcard = create(:flashcard, user: other_user, front: "Other's card")
        sign_in user
        
        get flashcards_path
        
        expect(response.body).to include("User&#39;s card")
        expect(response.body).not_to include("Other&#39;s card")
      end

      it "assigns current user's flashcards to @flashcards" do
        user = create(:user)
        flashcard1 = create(:flashcard, user: user)
        flashcard2 = create(:flashcard, user: user)
        sign_in user
        
        get flashcards_path
        
        expect(assigns(:flashcards)).to match_array([flashcard1, flashcard2])
      end
    end
  end

  describe "GET /flashcards/:id" do
    context "when user is not authenticated" do
      it "redirects to sign in page" do
        user = create(:user)
        flashcard = create(:flashcard, user: user)
        
        get flashcard_path(flashcard)
        
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      it "returns successful response for own flashcard" do
        user = create(:user)
        flashcard = create(:flashcard, user: user)
        sign_in user
        
        get flashcard_path(flashcard)
        
        expect(response).to have_http_status(:success)
      end

      it "assigns the flashcard to @flashcard" do
        user = create(:user)
        flashcard = create(:flashcard, user: user)
        sign_in user
        
        get flashcard_path(flashcard)
        
        expect(assigns(:flashcard)).to eq(flashcard)
      end

      it "renders 404 page when trying to access another user's flashcard" do
        user = create(:user)
        other_user = create(:user)
        flashcard = create(:flashcard, user: other_user)
        sign_in user
        
        get flashcard_path(flashcard)
        
        expect(response).to have_http_status(:not_found)
        expect(response).to render_template("errors/not_found")
      end

      it "renders 404 page when flashcard does not exist" do
        user = create(:user)
        sign_in user
        
        get flashcard_path(id: 999999)
        
        expect(response).to have_http_status(:not_found)
        expect(response).to render_template("errors/not_found")
      end
    end
  end

  describe "GET /flashcards/new" do
    context "when user is not authenticated" do
      it "redirects to sign in page" do
        get new_flashcard_path
        
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      it "returns successful response" do
        user = create(:user)
        sign_in user
        
        get new_flashcard_path
        
        expect(response).to have_http_status(:success)
      end

      it "assigns a new flashcard to @flashcard" do
        user = create(:user)
        sign_in user
        
        get new_flashcard_path
        
        expect(assigns(:flashcard)).to be_a_new(Flashcard)
        expect(assigns(:flashcard).user).to eq(user)
      end
    end
  end

  describe "POST /flashcards" do
    context "when user is not authenticated" do
      it "redirects to sign in page" do
        post flashcards_path, params: { flashcard: { front: "Question", back: "Answer" } }
        
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      context "with valid parameters" do
        it "creates a new flashcard" do
          user = create(:user)
          sign_in user
          
          expect {
            post flashcards_path, params: { flashcard: { front: "Question", back: "Answer" } }
          }.to change(Flashcard, :count).by(1)
        end

        it "sets the source to manual" do
          user = create(:user)
          sign_in user
          
          post flashcards_path, params: { flashcard: { front: "Question", back: "Answer" } }
          
          expect(Flashcard.last.source).to eq("manual")
        end

        it "associates flashcard with current user" do
          user = create(:user)
          sign_in user
          
          post flashcards_path, params: { flashcard: { front: "Question", back: "Answer" } }
          
          expect(Flashcard.last.user).to eq(user)
        end

        it "redirects to flashcards index" do
          user = create(:user)
          sign_in user
          
          post flashcards_path, params: { flashcard: { front: "Question", back: "Answer" } }
          
          expect(response).to redirect_to(flashcards_path)
        end

        it "sets a success notice" do
          user = create(:user)
          sign_in user
          
          post flashcards_path, params: { flashcard: { front: "Question", back: "Answer" } }
          
          expect(flash[:notice]).to eq("Flashcard created successfully.")
        end
      end

      context "with invalid parameters" do
        it "does not create a flashcard when front is missing" do
          user = create(:user)
          sign_in user
          
          expect {
            post flashcards_path, params: { flashcard: { front: "", back: "Answer" } }
          }.not_to change(Flashcard, :count)
        end

        it "does not create a flashcard when back is missing" do
          user = create(:user)
          sign_in user
          
          expect {
            post flashcards_path, params: { flashcard: { front: "Question", back: "" } }
          }.not_to change(Flashcard, :count)
        end

        it "does not create a flashcard when front is too long" do
          user = create(:user)
          sign_in user
          
          expect {
            post flashcards_path, params: { flashcard: { front: "a" * 201, back: "Answer" } }
          }.not_to change(Flashcard, :count)
        end

        it "does not create a flashcard when back is too long" do
          user = create(:user)
          sign_in user
          
          expect {
            post flashcards_path, params: { flashcard: { front: "Question", back: "a" * 501 } }
          }.not_to change(Flashcard, :count)
        end

        it "renders new template with unprocessable entity status" do
          user = create(:user)
          sign_in user
          
          post flashcards_path, params: { flashcard: { front: "", back: "Answer" } }
          
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:new)
        end

        it "assigns the invalid flashcard to @flashcard" do
          user = create(:user)
          sign_in user
          
          post flashcards_path, params: { flashcard: { front: "", back: "Answer" } }
          
          expect(assigns(:flashcard)).to be_a(Flashcard)
          expect(assigns(:flashcard).errors).not_to be_empty
        end
      end

      context "with missing parameters" do
        it "returns bad request when flashcard params are missing" do
          user = create(:user)
          sign_in user
          
          post flashcards_path, params: {}
          
          expect(response).to have_http_status(:bad_request)
        end
      end
    end
  end

  describe "GET /flashcards/:id/edit" do
    context "when user is not authenticated" do
      it "redirects to sign in page" do
        user = create(:user)
        flashcard = create(:flashcard, user: user)
        
        get edit_flashcard_path(flashcard)
        
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      it "returns successful response for own flashcard" do
        user = create(:user)
        flashcard = create(:flashcard, user: user)
        sign_in user
        
        get edit_flashcard_path(flashcard)
        
        expect(response).to have_http_status(:success)
      end

      it "assigns the flashcard to @flashcard" do
        user = create(:user)
        flashcard = create(:flashcard, user: user)
        sign_in user
        
        get edit_flashcard_path(flashcard)
        
        expect(assigns(:flashcard)).to eq(flashcard)
      end

      it "renders 404 page when trying to edit another user's flashcard" do
        user = create(:user)
        other_user = create(:user)
        flashcard = create(:flashcard, user: other_user)
        sign_in user
        
        get edit_flashcard_path(flashcard)
        
        expect(response).to have_http_status(:not_found)
        expect(response).to render_template("errors/not_found")
      end
    end
  end

  describe "PATCH /flashcards/:id" do
    context "when user is not authenticated" do
      it "redirects to sign in page" do
        user = create(:user)
        flashcard = create(:flashcard, user: user)
        
        patch flashcard_path(flashcard), params: { flashcard: { front: "Updated" } }
        
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      context "with valid parameters" do
        it "updates the flashcard" do
          user = create(:user)
          flashcard = create(:flashcard, user: user, front: "Old Front", back: "Old Back")
          sign_in user
          
          patch flashcard_path(flashcard), params: { 
            flashcard: { front: "New Front", back: "New Back" } 
          }
          
          flashcard.reload
          expect(flashcard.front).to eq("New Front")
          expect(flashcard.back).to eq("New Back")
        end

        it "redirects to flashcards index" do
          user = create(:user)
          flashcard = create(:flashcard, user: user)
          sign_in user
          
          patch flashcard_path(flashcard), params: { flashcard: { front: "Updated" } }
          
          expect(response).to redirect_to(flashcards_path)
        end

        it "sets a success notice" do
          user = create(:user)
          flashcard = create(:flashcard, user: user)
          sign_in user
          
          patch flashcard_path(flashcard), params: { flashcard: { front: "Updated" } }
          
          expect(flash[:notice]).to eq("Flashcard updated successfully.")
        end
      end

      context "with invalid parameters" do
        it "does not update when front is empty" do
          user = create(:user)
          flashcard = create(:flashcard, user: user, front: "Original")
          sign_in user
          
          patch flashcard_path(flashcard), params: { flashcard: { front: "" } }
          
          flashcard.reload
          expect(flashcard.front).to eq("Original")
        end

        it "does not update when back is empty" do
          user = create(:user)
          flashcard = create(:flashcard, user: user, back: "Original")
          sign_in user
          
          patch flashcard_path(flashcard), params: { flashcard: { back: "" } }
          
          flashcard.reload
          expect(flashcard.back).to eq("Original")
        end

        it "does not update when front is too long" do
          user = create(:user)
          flashcard = create(:flashcard, user: user, front: "Original")
          sign_in user
          
          patch flashcard_path(flashcard), params: { flashcard: { front: "a" * 201 } }
          
          flashcard.reload
          expect(flashcard.front).to eq("Original")
        end

        it "does not update when back is too long" do
          user = create(:user)
          flashcard = create(:flashcard, user: user, back: "Original")
          sign_in user
          
          patch flashcard_path(flashcard), params: { flashcard: { back: "a" * 501 } }
          
          flashcard.reload
          expect(flashcard.back).to eq("Original")
        end

        it "renders edit template with unprocessable entity status" do
          user = create(:user)
          flashcard = create(:flashcard, user: user)
          sign_in user
          
          patch flashcard_path(flashcard), params: { flashcard: { front: "" } }
          
          expect(response).to have_http_status(:unprocessable_entity)
          expect(response).to render_template(:edit)
        end

        it "assigns the invalid flashcard to @flashcard" do
          user = create(:user)
          flashcard = create(:flashcard, user: user)
          sign_in user
          
          patch flashcard_path(flashcard), params: { flashcard: { front: "" } }
          
          expect(assigns(:flashcard)).to eq(flashcard)
          expect(assigns(:flashcard).errors).not_to be_empty
        end
      end

      context "when trying to update another user's flashcard" do
        it "renders 404 page" do
          user = create(:user)
          other_user = create(:user)
          flashcard = create(:flashcard, user: other_user)
          sign_in user
          
          patch flashcard_path(flashcard), params: { flashcard: { front: "Hacked" } }
          
          expect(response).to have_http_status(:not_found)
          expect(response).to render_template("errors/not_found")
        end

        it "does not update the flashcard" do
          user = create(:user)
          other_user = create(:user)
          flashcard = create(:flashcard, user: other_user, front: "Original")
          sign_in user
          
          patch flashcard_path(flashcard), params: { flashcard: { front: "Hacked" } }
          
          flashcard.reload
          expect(flashcard.front).to eq("Original")
        end
      end
    end
  end

  describe "DELETE /flashcards/:id" do
    context "when user is not authenticated" do
      it "redirects to sign in page" do
        user = create(:user)
        flashcard = create(:flashcard, user: user)
        
        delete flashcard_path(flashcard)
        
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      it "deletes the flashcard" do
        user = create(:user)
        flashcard = create(:flashcard, user: user)
        sign_in user
        
        expect {
          delete flashcard_path(flashcard)
        }.to change(Flashcard, :count).by(-1)
      end

      it "redirects to flashcards index" do
        user = create(:user)
        flashcard = create(:flashcard, user: user)
        sign_in user
        
        delete flashcard_path(flashcard)
        
        expect(response).to redirect_to(flashcards_path)
      end

      it "sets a success notice" do
        user = create(:user)
        flashcard = create(:flashcard, user: user)
        sign_in user
        
        delete flashcard_path(flashcard)
        
        expect(flash[:notice]).to eq("Flashcard deleted successfully.")
      end

      it "renders 404 page when trying to delete another user's flashcard" do
        user = create(:user)
        other_user = create(:user)
        flashcard = create(:flashcard, user: other_user)
        sign_in user
        
        delete flashcard_path(flashcard)
        
        expect(response).to have_http_status(:not_found)
        expect(response).to render_template("errors/not_found")
      end

      it "does not delete another user's flashcard" do
        user = create(:user)
        other_user = create(:user)
        flashcard = create(:flashcard, user: other_user)
        sign_in user
        
        expect {
          delete flashcard_path(flashcard)
        }.not_to change(Flashcard, :count)
      end

      it "renders 404 page when flashcard does not exist" do
        user = create(:user)
        sign_in user
        
        delete flashcard_path(id: 999999)
        
        expect(response).to have_http_status(:not_found)
        expect(response).to render_template("errors/not_found")
      end
    end
  end
end
