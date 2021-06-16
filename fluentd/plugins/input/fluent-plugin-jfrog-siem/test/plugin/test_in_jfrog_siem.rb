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
    jpd_url JPD_URL
    username USER
    apikey API_KEY
    pos_file "test_pos.txt"
  ]

  private

  def create_driver(conf = CONFIG)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::JfrogSiemInput).configure(conf)
  end

  sub_test_case 'Testing' do
    test 'Testing plugin in_jfrog_siem' do
      d = create_driver(CONFIG)
      begin
        d.run
      rescue => e
        raise "Test failed due to #{e}"
      end
    end
  end
end
