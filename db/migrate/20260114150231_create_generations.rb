class CreateGenerations < ActiveRecord::Migration[8.1]
  def change
    create_table :generations do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.text :source_text, null: false
      t.string :model
      t.integer :generation_duration
      t.integer :generated_count, null: false, default: 0
      t.integer :accepted_unedited_count
      t.integer :accepted_edited_count

      t.timestamps
    end
  end
end
