class CreateFollowRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :follow_requests do |t|
      t.references :follower, null: false, foreign_key: { to_table: :users }
      t.references :followed, null: false, foreign_key: { to_table: :users }
      t.string :status, default: 'pending', null: false

      t.timestamps
    end

    add_index :follow_requests, [:follower_id, :followed_id], unique: true
  end
end
