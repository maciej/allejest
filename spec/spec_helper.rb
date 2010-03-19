$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'allejest'
require 'spec'
require 'spec/autorun'
require 'matchers'

Spec::Runner.configure do |config|
  config.include(Matchers)
end
