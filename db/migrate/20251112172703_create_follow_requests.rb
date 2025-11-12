class CreateFollowRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :follow_requests do |t|
      t.references :follower, null: false, foreign_key: true
      t.references :followed, null: false, foreign_key: true
      t.string :status

      t.timestamps
    end
  end
end
