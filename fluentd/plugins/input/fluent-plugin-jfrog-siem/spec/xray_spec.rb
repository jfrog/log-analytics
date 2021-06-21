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
      violations_channel = Concurrent::Channel.new(capacity: 5)
      
      (1..5).each do |i|
        puts i
        violations_channel << i        
      end
      
      promises = class_double("Concurrent::Promises")
      expect(promises).to receive(:future).exactly(5).times

      xray.violation_details(violations_channel)
    end
  end

  describe "#violations" do
    it "gets violations from date_since" do
      xray = Xray.new(@jpd_url, @username, @apikey, @wait_interval, @batch_size, @pos_file)
      json = class_double(JSON)
      expect(json).to receive(:parse).and_return({'violations': [1, 2, 3, 4, 5]})

      violations_channel = xray.violations(Date.today)
      result = []
      violations_channel.each do |v|
        result << v
      end
      expect(result).to eq ([1, 2, 3, 4, 5])
    end
  end

end