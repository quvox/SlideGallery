class Keyword < ActiveRecord::Base
  def self.search(key)
    where("match(word) against (? in boolean mode)", "+#{key}")
  end
end
