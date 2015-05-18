class AddIndexTagsTagname < ActiveRecord::Migration
  def change
    add_index :tags, 'tagname'
  end
end
