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
  # CONFIG = %[
  #   tag "partnership.test_tag"
  #   jpd_url "https://partnership.jfrog.io/"
  #   username "sudhindrar"
  #   apikey "AKCp8ihpNg2JE5PV3nRXZQsmMGmzX9VTX6wN51hQBFRC1CXQWzGrKQvFL1tsw7aochjoQXAZq"
  #   pos_file "test_pos.txt"
  #   wait_interval 30
  # ]

  CONFIG = %[
    tag "sudhindra-xray-rt.test_tag"
    jpd_url "https://sudhindra-xray-rt.jfrog.tech/"
    username "admin"
    apikey "AKCp8jQd1zP4oKv43SNgewrNwikd1iAQznfhSfx3T249eVMkGnJnSjCpNsuv8vtHWChKLfJ1w"
    pos_file "test_pos.txt"
    wait_interval 10
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
