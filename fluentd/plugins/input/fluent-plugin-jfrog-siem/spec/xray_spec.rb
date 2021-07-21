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

    let(:violation1){ { "created": Date.parse(Date.today.to_s).strftime("%Y-%m-%dT%H:%M:%SZ"), "watch_name": "watch1", "issue_id": "55444"} }
    let(:violation2){ { "created": Date.parse(Date.today.to_s).strftime("%Y-%m-%dT%H:%M:%SZ"), "watch_name": "watch2", "issue_id": "55443"} }

    it "creates a future for every violation" do
      xray = Xray.new(@jpd_url, @username, @apikey, @wait_interval, @batch_size, @pos_file_path, @router)
      violations = Concurrent::Array.new
      
      (1..5).each do |i|
        violations << i
      end
      
      promises = class_double("Concurrent::Promises").as_stubbed_const(:transfer_nested_constants => true)
      expect(promises).to receive(:future).exactly(5).times

      xray.violation_details(violations)
    end

    xit "updates pos file for every violation" do
      pos_file = double('pos_file')

      xray = Xray.new(@jpd_url, @username, @apikey, @wait_interval, @batch_size, @router)
      violations = Concurrent::Array.new
      
      violations << violation1
      violations << violation2

      datetime = double (DateTime)
      expect(datetime).to receive(:parse)
      promises = class_double("Concurrent::Promises").as_stubbed_const(:transfer_nested_constants => true)
      allow(promises).to receive(:future) { |&block| block.call }

      fluent = class_double("Fluent::Engine").as_stubbed_const(:transfer_nested_constants => true)
      expect(fluent).to receive(:now).and_return(DateTime.now)
      pos_file = double (PositionFile)
      expect(pos_file).to receive(:write).exactly(2).times

      xray.violation_details(violations)
    end
  end


end