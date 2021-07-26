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
require 'rest-client'


RSpec.describe Xray do
  describe "#violation_details" do

    let(:violation1){ { "created": Date.parse(Date.today.to_s).strftime("%Y-%m-%dT%H:%M:%SZ"),
                        "watch_name": "watch1",
                        "issue_id": "55444",
                        "violation_details_url": "http://www.com"}
                    }
    let(:violation2){ { "created": Date.parse(Date.today.to_s).strftime("%Y-%m-%dT%H:%M:%SZ"),
                        "watch_name": "watch2",
                        "issue_id": "55443",
                        "violation_details_url": "http://www.com"}
                    }

    let(:violations) { Concurrent::Array.new }

    it "creates a future for every violation" do
      xray = Xray.new(@jpd_url, @username, @apikey, @wait_interval, @batch_size, @pos_file_path, @router)

      (1..5).each do |i|
        violations << i
      end

      promises = class_double("Concurrent::Promises").as_stubbed_const(:transfer_nested_constants => true)
      expect(promises).to receive(:future).exactly(5).times

      xray.violation_details(violations)
    end

    it "updates pos file for every violation (cannot do exactly tests since stubs with Concurrent ruby are broken)" do
      router = double('router')
      pos_file_path = `pwd`
      xray = Xray.new(@jpd_url, @username, @apikey, @wait_interval, @batch_size, pos_file_path, router)

      violations << JSON.parse(violation1.to_json)
      violations << JSON.parse(violation2.to_json)

      promises = class_double("Concurrent::Promises").as_stubbed_const(:transfer_nested_constants => true)
      allow(promises).to receive(:future).and_yield(violation1).and_yield(violation2)

      rest_client = double("RestClient::Request")
      allow(RestClient::Request).to receive(:new).and_return rest_client
      allow(rest_client).to receive(:execute).and_return(JSON.parse({'impacted_artifacts': []}.to_json))

      pos_file = double(PositionFile)
      allow(PositionFile).to receive(:new).and_return pos_file
      allow(pos_file).to receive(:write)

      fluent = class_double("Fluent::Engine").as_stubbed_const(:transfer_nested_constants => true)
      allow(fluent).to receive(:now).and_return(DateTime.now)
      allow(router).to receive(:emit)

      xray.violation_details(JSON.parse(violations.to_json))
    end
  end

  describe "#violations" do

  end

  describe "#process" do
    let(:violation1){ { "created": Date.parse(Date.today.to_s).strftime("%Y-%m-%dT%H:%M:%SZ"),
                        "watch_name": "watch1",
                        "issue_id": "55444",
                        "violation_details_url": "http://www.com"}
                    }
    let(:violation2){ { "created": Date.parse(Date.today.to_s).strftime("%Y-%m-%dT%H:%M:%SZ"),
                        "watch_name": "watch2",
                        "issue_id": "55443",
                        "violation_details_url": "http://www.com"}
                    }

    let(:violations_channel) { Concurrent::Array.new }

    it "skips processed violation" do
      pos_file_path = `pwd`
      xray = Xray.new(@jpd_url, @username, @apikey, @wait_interval, @batch_size, @pos_file_path, @router)

      violations_channel << violation1

      pos_file = double(PositionFile)
      allow(PositionFile).to receive(:new).and_return pos_file
      allow(pos_file).to receive(:processed?).and_return true

      xray.process(violation1, violations_channel)

      expect(violations_channel.size).to eq 1
    end

    it "adds unprocessed violation to the channel" do
      pos_file_path = `pwd`
      xray = Xray.new(@jpd_url, @username, @apikey, @wait_interval, @batch_size, @pos_file_path, @router)

      violations_channel << violation1

      pos_file = double(PositionFile)
      allow(PositionFile).to receive(:new).and_return pos_file
      allow(pos_file).to receive(:processed?).and_return false

      xray.process(violation2, violations_channel)

      expect(violations_channel.size).to eq 2
    end
  end

end