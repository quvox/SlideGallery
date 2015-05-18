class CreateKeywords < ActiveRecord::Migration
  def change
    create_table :keywords do |t|
      t.integer :slideid
      t.text :word, :null => false

      t.timestamps null: false
    end
  end
end
