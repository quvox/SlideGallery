class AddIndexSlidesUser < ActiveRecord::Migration
  def change
    add_index :slides, 'user'
  end
end
