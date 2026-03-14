class CreatePostStats < ActiveRecord::Migration[7.0]
  def change
    create_table :post_stats do |t|
      t.references :post, foreign_key: true, type: :bigint
      t.integer :drafts_saved
      t.string :keywords
      t.boolean :shared, default: false

      t.timestamps
    end
  end
end
