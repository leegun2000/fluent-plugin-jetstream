require "helper"
require "fluent/plugin/in_jetstream.rb"

class JetstreamInputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test "failure" do
    flunk
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::JetstreamInput).configure(conf)
  end
end
