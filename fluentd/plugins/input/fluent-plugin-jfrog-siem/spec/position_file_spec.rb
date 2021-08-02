[
  File.join(File.dirname(__FILE__), '..'),
  File.join(File.dirname(__FILE__), '..', 'lib/fluent/plugin'),
  File.join(File.dirname(__FILE__), '..', 'spec'),
].each do |dir|
  $LOAD_PATH.unshift(dir) unless $LOAD_PATH.include?(dir)
end

require 'position_file'
require 'date'
require 'rspec'


RSpec.describe PositionFile do
  describe "#processed?" do
    let(:violation){ { "created": Date.parse(Date.today.to_s).strftime("%Y-%m-%dT%H:%M:%SZ"), "watch_name": "watch1", "issue_id": "55444"} }

    pos_file_date = DateTime.parse(Date.today.to_s).strftime("%Y-%m-%d")
    temp_pos_file = "jfrog_siem_log_#{pos_file_date}.pos"

    it "returns false when a violation has not been processed" do
      pos_file = PositionFile.new(`pwd`)
      allow(File).to receive(:open).and_yield []

      expect(pos_file.processed?(JSON.parse(violation.to_json))).to be_falsey
    end

    it "returns true when a violation was found in the pos file" do
      pos_file = PositionFile.new(`pwd`)

      matching_violation = [violation[:created], violation[:watch_name], violation[:issue_id]].join(',')
      another_violation = [violation[:created], "watch2", "12345"].join(',')
      allow(File).to receive(:exist?).and_return true
      allow(File).to receive(:open).and_yield [matching_violation, another_violation]

      expect(pos_file.processed?(JSON.parse(violation.to_json))).to be_truthy
    end

  end

  describe "#write" do
    let(:violation){ { "created": Date.parse(Date.today.to_s).strftime("%Y-%m-%dT%H:%M:%SZ"), "watch_name": "watch1", "issue_id": "55444"} }

    it "returns false when a violation has not been processed" do
      pos_file = PositionFile.new(`pwd`)

      result = []
      allow(File).to receive(:open).and_yield result

      pos_file.write(JSON.parse(violation.to_json))

      matching_violation = [violation[:created], violation[:watch_name], violation[:issue_id]].join(',')
      expect(result.include? matching_violation).to be_truthy
    end
  end
end