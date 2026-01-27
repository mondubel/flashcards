class AddReviewedToGenerations < ActiveRecord::Migration[8.1]
  def change
    add_column :generations, :reviewed, :boolean, default: false, null: false
  end
end
