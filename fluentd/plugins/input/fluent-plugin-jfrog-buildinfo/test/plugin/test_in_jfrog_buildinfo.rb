require "helper"
require "fluent/plugin/in_jfrog_buildinfo.rb"

class JfrogBuildinfoInputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test "failure" do
    #flunk
  end

  # Default configuration for tests
  CONFIG = %[
    tag "test_tag"
    jpd_url <jpd_url>
    access_token <access_token>
  ]

  private

  def create_driver(conf)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::JfrogBuildinfoInput).configure(conf)
  end

  sub_test_case 'Testing' do
    test 'Testing plugin in_jfrog_buildinfo' do
      d = create_driver(CONFIG)
      d.run
    end
  end
end
