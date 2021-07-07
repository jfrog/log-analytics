[
  File.join(File.dirname(__FILE__), '..'),
  File.join(File.dirname(__FILE__), '..', 'lib/fluent/plugin'),
  File.join(File.dirname(__FILE__), '..', 'spec'),
].each do |dir|
  $LOAD_PATH.unshift(dir) unless $LOAD_PATH.include?(dir)
end

require 'xray'
require 'date'
require 'rspec'


RSpec.describe Xray do
  describe "#violation_details" do
    it "creates a future for every item in the channel" do
      xray = Xray.new(@jpd_url, @username, @apikey, @wait_interval, @batch_size, @pos_file)
      violations = Concurrent::Array.new
      
      (1..5).each do |i|
        violations << i
      end
      
      promises = class_double("Concurrent::Promises").as_stubbed_const(:transfer_nested_constants => true)
      expect(promises).to receive(:future).exactly(5).times

      xray.violation_details(violations)
    end
  end

  describe "#violations_by_page" do
    it "gets violations for for_date" do
      xray = Xray.new("@jpd_url", @username, @apikey, @wait_interval, 5, @pos_file)

      rest_client = double("A Rest Client")
      expect(RestClient::Request).to receive(:new).and_return rest_client
      expect(rest_client).to receive(:execute).and_return('{"violations": [1, 2, 3, 4, 5]}')

      expect(JSON).to receive(:parse).and_return({'violations': [1, 2, 3, 4, 5]})

      violations = xray.violations_by_page(Date.today, 1)
      expect(violations).to eq ([1, 2, 3, 4, 5])
    end
  end

  describe "#page_count" do
    it "calculates page_count based on batch_size to account for last page smaller than batch_size" do
      xray = Xray.new(@jpd_url, @username, @apikey, @wait_interval, 5, @pos_file)

      expect(xray.page_count(24)).to be(5)
    end

    it "calculates page_count based on batch_size to account for last page same as batch_size" do
      xray = Xray.new(@jpd_url, @username, @apikey, @wait_interval, 5, @pos_file)

      expect(xray.page_count(20)).to be(4)
    end

    it "returns elegantly when violations_count is 0" do
      xray = Xray.new(@jpd_url, @username, @apikey, @wait_interval, 5, @pos_file)

      expect(xray.page_count(0)).to be(0)
    end

  end

end