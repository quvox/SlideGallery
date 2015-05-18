class AddIndexTagsSlideid < ActiveRecord::Migration
  def change
    add_index :tags, 'slideid'
  end
end
