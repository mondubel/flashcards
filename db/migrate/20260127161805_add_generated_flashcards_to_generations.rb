class AddGeneratedFlashcardsToGenerations < ActiveRecord::Migration[8.1]
  def change
    add_column :generations, :generated_flashcards, :jsonb
  end
end
