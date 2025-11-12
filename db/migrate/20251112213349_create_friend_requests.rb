class CreateFriendRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :friend_requests do |t|
      t.references :sender, null: false, foreign_key: true
      t.references :receiver, null: false, foreign_key: true
      t.string :status

      t.timestamps
    end
  end
end
