require 'rubygems'

require 'active_support'
require 'rss/1.0'
require 'rss/2.0'
require 'open-uri'
require 'feed_me'

# Sample feed: http://allegro.pl/rss.php?category=0&from_showcat=1&string=canon+10-22&feed=search
class Item

end

class SearchResult
  
end


class AlleJest

  def build_url

  end

  def self.run
    alle_jest = AlleJest.new
    

    #source = "http://allegro.pl/rss.php?category=0&from_showcat=1&string=canon+10-22&feed=search"
    
    content = ""
    #open(source) {|s| content = s.read }
    content = File.read(File.join(File.dirname(__FILE__), '..', 'spec', 'fixtures', 'allegro_canon1022_results.rss'))

    feed = FeedMe.parse(content)

    feed.entries.each do |entry|
      puts entry.item_id
    end
  end
  
end

