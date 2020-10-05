require "helper"
require "fluent/plugin/in_jfrog_siem.rb"

class JfrogSiemInputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  test "failure" do
    #flunk
  end

  # Default configuration for tests
  CONFIG = %[
    tag "test_tag"
    jpd_url <jpd_url>>
    access_token <access_token>
    pos_file "test_pos.txt"
  ]

  private

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::JfrogSiemInput).configure(conf)
  end

  sub_test_case 'Testing' do
    test 'Testing plugin in_jfrog_siem' do
      d = create_driver(CONFIG)
      d.run
    end
  end
end
