class CreateFlashcards < ActiveRecord::Migration[8.1]
  def change
    create_table :flashcards do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.references :generation, null: true, foreign_key: { on_delete: :cascade }
      t.text :front, null: false
      t.text :back, null: false
      t.string :source, null: false

      t.timestamps
    end
  end
end
