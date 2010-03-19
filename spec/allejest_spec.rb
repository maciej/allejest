# Note: File.expand_path converts a pathname to an absolute pathname. (still learning)
require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

# Note: for stubbing and mocking see:
# http://rspec.info/documentation/mocks/stubs.html

require 'uri'

describe AlleJest::Runner do

  before :each do
    @alle_jest = AlleJest::Runner.new
  end

  describe ".read_config" do
    before :all do
      @config_path = File.join(File.dirname(__FILE__), 'fixtures', 'allejest.yml')
    end

    it "should read 3 queries" do
      c = @alle_jest.read_config(@config_path)
      c[:queries].size.should == 3

    end
  end
  
end

describe AlleJest::Reader do

  describe ".build_url" do

    before :each do
      @q = {:id => "foo"}
    end

    it "should render simple Text queries like allegro" do
      @q.merge!(:text => "simple")
      AlleJest::Reader.build_url(@q).should match_uri("http://allegro.pl/rss.php?category=0&string=simple&feed=search")
    end

    it "should render Text using URL encoding like allegro" do
      @q.merge!(:text => "not so simple")
      AlleJest::Reader.build_url(@q).should match_uri("http://allegro.pl/rss.php?category=0&string=not+so+simple&feed=search")
    end

    it "should not return an URL with a trailing &" do
      @q.merge!(:text => "not so simple")
      u = AlleJest::Reader.build_url(@q)
      u[u.length-1].chr.should_not == "&"
    end
  end
end