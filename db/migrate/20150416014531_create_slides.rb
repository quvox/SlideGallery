class CreateSlides < ActiveRecord::Migration
  def change
    create_table :slides do |t|
      t.string :title
      t.string :filename
      t.string :path
      t.string :user
      t.string :pass

      t.timestamps null: false
    end
  end
end
