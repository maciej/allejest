require 'rubygems'

require 'active_support'
require 'open-uri'
require 'feed_me'
require 'cgi'
require 'yaml'
require 'simply_useful'
require 'erb'
require 'pathname'
require 'net/smtp'
require 'time'
require 'pony'

# Text query feed: http://allegro.pl/rss.php?category=0&from_showcat=1&string=canon+10-22&feed=search
# Category query feed: http://allegro.pl/rss.php?feed=cat&id=70563
# Text and category query feed: http://allegro.pl/rss.php?category=106&sg=0&string=garfield&feed=search

# Self note:
# I always find it hard to design code that is somewhere between a single script
# and a full-fledged application (software libraries not included).
# So let's keep it as much as possible close to the MVC pattern, as I think it's the most sane one
# to go with here.

# Parameters
# string -- for T queries
# cateogry -- for T and TC queries
# feed -- for C queries
# from_showcat -- for C and TC queries
# sg -- ??

module AlleJest
  class Item
    include HasAttributes

    attr_accessor :feed_entry, :id

    alias_method :old_initialize, :initialize

    def initialize(args = {})
      old_initialize(args)

      self.id = feed_entry.item_id
    end

  end

  class SearchResult
    include HasAttributes

    attr_accessor :feed, :query, :title, :items

    alias_method :old_initialize, :initialize

    def initialize(args = {})
      self.items = []
      old_initialize(args)
      
      self.title = feed.title.sub("Allegro.pl: ", "")
    end

    # TODO support non-text queries as well. Write a better matcher after all...
    def matches_query?
      self.title == query[:text]
    end
  end

  class Reader

    END_POINT = "http://allegro.pl/rss.php?"
    
    attr_accessor :config

    def initialize(config)
      self.config = config
    end

    def self.build_url(query = {})
      return if query.blank?

      q = END_POINT.dup # dup, because q is appended to

      params = {}
      if query.has_key?(:text)
        params[:string] = query[:text]
        params[:feed] = "search"
        if !query.has_key?(:category)
          params[:category] = 0
        end
      end
      if query.has_key?(:category)
        if query.has_key?(:text)
          params[:category] = query[:category]
        else # Category only queries
          params[:feed] = "cat"
          params[:id] = query[:category]
        end
      end

      # Using CGI instead of URI, as CGI produced + for space instead of %20 (that's what we need!)
      # See http://www.listable.org/show/difference-between-cgiescape-and-uriescape-in-ruby
      params.each do |k,v|
        q << "#{k.to_s}=#{CGI.escape(v.to_s)}&"
      end

      return q[0, q.length - 1] if q[q.length - 1] == ?& # remove trailing '&' if exists
      q
    end # build_url

    def get_feed(query)
      url = AlleJest::Reader.build_url(query)
      content = ""
      open(url) {|s| content = s.read }
      FeedMe.parse(content)
    end

    def map_feeds_to_queries
      return nil if config.nil? || config[:queries].nil?

      config[:queries].map do |query|
        [query, get_feed(query)]
      end
    end

  end

  class Filter
    include HasAttributes

    # Pruning strategy
    # prune db every 2 weeks
    # removing elements that are older than 2 months



    attr_accessor :filter_db_path, :filter_db

    alias_method :old_initialize, :initialize

    def initialize(args = {})
      old_initialize(args)
      read_db
    end
    
    def filter results
      now = Time.now.to_i

      results.dup.each do |result|
        result.items.reject! do |item|
          id = item.id
          unless id.blank?
            r = filter_db[:reported].has_key? id
            filter_db[:reported][id] = {:first_seen => now} unless r
            r
          else
            true
          end
        end
      end
    end

    def close
      prune
      save_db
    end

    private
    def read_db
      self.filter_db = {}
      if File.exist?(filter_db_path)
        f = File.read(filter_db_path)
        self.filter_db = YAML.load(f) unless f.blank?
      end
      self.filter_db.reverse_merge!({:reported => {}, :last_prune => Time.now.to_i})
    end

    def save_db
      File.open( filter_db_path, 'w' ) do |out|
        YAML.dump(filter_db, out)
      end
    end

    def prune
      return if filter_db[:last_prune] + 2.weeks > Time.now.to_i # Return if pruned in the last two weeks

      filter_db[:reported].reject! do |item|
        item[:first_seen] + 2.months < Time.now.to_i
      end

      filter_db[:last_prune] = Time.now.to_i
    end
  end

  class Emailer
    include HasAttributes

    attr_accessor :firstname, :lastname, :email, :results, :from_email, :from_address, :smtp

    def send_mail
      raw_erb = File.read(find_erb_path)
      erb = ERB.new(raw_erb)

      email_body = erb.result(binding) #.gsub(/^\s*/, '')

      pony_opts = {:to => "#{firstname} #{lastname} <#{email}>", :from => from_address,
        :body => email_body, :subject => "AlleJest report for #{Time.new.rfc2822}" }
      #puts pony_opts.inspect

      Pony.mail(pony_opts)
    end

    private
    def find_erb_path
      erb_path = nil
      $:.detect do |base_path|
        erb_path = if Pathname.new(base_path).absolute?
          base_path
        else
          File.expand_path File.join(Pathname.pwd, base_path)
        end
        erb_path = File.join(erb_path, 'alle_jest', 'mail.erb')
        File.exist?(erb_path)
      end
      erb_path
    end

  end

  # That's awfully, procedurally designed, but I don't care. It should just do it's job.
  class Runner
    include AlleJest

    attr_accessor :config

    def initialize(options = {})
      read_config(options[:config_path]) if options.has_key? :config_path
    end

    def read_config(path)
      return nil if path.blank?

      content = File.read(path)
      self.config = YAML.load(content)
      config.deep_symbolize_keys! if config.is_a? Hash
    end

    def run
      reader = Reader.new(config[:reader])

      # TODO move to Reader
      feeds = reader.map_feeds_to_queries

      results = feeds.map do |query, feed|
        result = SearchResult.new(:query => query, :feed => feed)
        result.items = feed.entries.map do |entry|
          Item.new(:feed_entry => entry)
        end
        result
      end

      # Filter results not matching the query
      results.each { |r| r.items = [] if !r.matches_query? }

      # EOT (end of TODO)

      if config[:general].try(:[], :filter) == true # (expr == 0) in Ruby evaluates to true!
        filter = Filter.new(:filter_db_path => File.join(File.expand_path("~"), ".allejest", 'filter_db.yml'))
        results = filter.filter(results)
        filter.close
      end

      # A singleton method :-) I always wanted to write one
      def results.blank?
        return true if self.length == 0
        self.all? do |r|
          r.items.blank?
        end
      end

      # E-mail only if there are results
      unless results.blank?
        emailer_config = config[:emailer].slice(:from_address, :smtp)
        send_to = config[:emailer][:send_to][0].slice(:email, :firstname, :lastname)
        emailer = Emailer.new(emailer_config.merge!(send_to).merge!({:results => results}))
        emailer.send_mail
      end
      
    end

    def self.main
      AlleJest::Runner.new(:config_path => File.join(File.expand_path("~"), '.allejest', 'config.yml')).run
    end
  
  end
end