class AddIndexKeywordsWord < ActiveRecord::Migration
  def up
    execute "ALTER TABLE keywords engine=MyISAM;"
    execute "CREATE FULLTEXT INDEX keyword_fulltext_index on keywords(word);"
  end

  def down
    execute "DROP INDEX keyword_fulltext_index on keywords;"
  end
end
