require 'rubygems'
require 'mocha'
require 'spec'

require File.join(File.dirname(__FILE__), %w[.. lib values_for])

Spec::Runner.configure do |config|
  config.mock_with(:mocha)
end
