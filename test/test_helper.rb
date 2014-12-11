=begin
require 'simplecov'
SimpleCov.start do
  add_filter '/test/'
  add_filter '/vendor/'
end
=end

require 'antfarm'

Antfarm::Initializer.run do |config|
  config.environment = 'test'
  config.log_level   = 'debug'
  config.outputter   = lambda { |msg| File.open('/tmp/antfarm.out', 'w+') { |f| f.puts msg } }
end

require 'minitest/autorun'
require 'fabrication'

class TestCase < Minitest::Test
  def self.test(name, &block)
    define_method("test_#{name.gsub(/\W/, '_')}", &block) if block
  end

  def setup
    ActiveRecord::Migration.suppress_messages do
      Antfarm.store(true)
      load 'antfarm/schema.rb'
      Dir["#{Antfarm.root}/lib/antfarm/plugins/*/**/schema.rb"].each { |file| load file }
    end
  end
end
