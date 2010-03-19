# http://www.robertsosinski.com/2008/12/10/up-and-running-with-custom-rspec-matchers/

require 'uri'

module Matchers
  class MatchUri
    def initialize(expected)
      @expected_str = expected
      @expected_uri = URI.parse(@expected_str) unless expected.blank?
    end

    def matches?(actual)
      @actual_str = actual
      return false if @expected_uri.nil?

      # Check if no exceptions are thrown
      @actual_uri = URI.parse(@actual_str) unless actual.blank?
      return false if @actual_uri.blank?

      # aliases
      a = @actual_uri
      e = @expected_uri

      [:scheme, :userinfo, :host, :port, :path, :fragment].each do |c|
        return false unless a.send(c) == e.send(c)
      end

      qs = [a.query, e.query].collect do |q|
        q.split(/(&amp;|&)/).sort.reject{|t| ["&", "&amp;"].include? t }
      end

      return false unless qs[0] == qs[1]

      return true
    end

    def failure_message
      initial_fail_msg = initial_failure
      return initial_fail_msg unless initial_fail_msg.blank?

      "expected '#{@expected_str}' but got '#{@actual_str}'"
    end

    def negative_failure_message
      initial_fail_msg = initial_failure
      return initial_fail_msg unless initial_fail_msg.blank?

      "expected something else then '#{@expected_str_}' but got '#{@actual_str}'"
    end

    private
    def initial_failure
      return "could not parse expected URI" if @expected_uri.nil?
      return "could not parse actual URI" if @actual_uri.nil?
    end

  end

  def match_uri(expected)
    MatchUri.new(expected)
  end
end