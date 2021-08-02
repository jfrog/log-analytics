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
     tag "jfrog.xray.siem.vulnerabilities"
     jpd_url "JPDURL"
     username "admin"
     apikey "APIKEY"
     pos_file_path "#{ENV['JF_PRODUCT_DATA_INTERNAL']}/log/"
     wait_interval 10
     from_date "2016-01-01"
     batch_size 25
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
