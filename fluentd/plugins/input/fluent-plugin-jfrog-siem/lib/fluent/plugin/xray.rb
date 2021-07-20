require 'concurrent'
require 'concurrent-edge'
require 'json'
require "fluent/plugin/position_file.rb"

class Xray
  def initialize(jpd_url, username, api_key, wait_interval, batch_size, pos_file_path)
    @jpd_url = jpd_url
    @username = username
    @api_key = api_key
    @wait_interval = wait_interval
    @batch_size = batch_size
    @pos_file_path = pos_file_path
  end

  def violations(date_since)
    violations_channel = Concurrent::Channel.new(capacity: @batch_size)
    page_number = 1
    timer_task = Concurrent::TimerTask.new(execution_interval: @wait_interval, timeout_interval: 30) do
      xray_json = {"filters": { "created_from": date_since }, "pagination": {"order_by": "created","limit": @batch_size ,"offset": page_number } }
      resp = JSON.parse(get_xray_violations(xray_json))
      total_violation_count = resp['total_violations']
      page_violation_count = resp['violations'].length
      puts "Total violations count is #{total_violation_count}"
      if total_violation_count > 0
        puts "Number of Violations in page #{page_number} are #{page_violation_count}"
        resp['violations'].each do |violation|
          pos_file_date = DateTime.parse(violation['created']).strftime("%Y-%m-%d")
          pos_file = @pos_file_path + "jfrog_siem_log_#{pos_file_date}.siem.pos"
          if File.exist?(pos_file)
            violations_channel = push_unique_violations_to_violations_channel(violations_channel, violation)
          else
            violations_channel = push_to_violations_channel(violations_channel, violation)
          end
        end
        if page_violation_count == @batch_size
          page_number += 1
        end
      end
    end
    timer_task.execute
    violations_channel
  end

  def push_to_violations_channel(violations_channel, violation)
    violations_channel << violation
    violations_channel
  end

  def push_unique_violations_to_violations_channel(violations_channel, violation)
    unless PositionFile.new(@pos_file_path).processed?(violation)
      violations_channel << violation
    end
    violations_channel
  end

  private
  def get_xray_violations(xray_json)
    response = RestClient::Request.new(
        :method => :post,
        :url => @jpd_url + "/xray/api/v1/violations",
        :payload => xray_json.to_json,
        :user => @username,
        :password => @api_key,
        :headers => { :accept => :json, :content_type => :json }
    ).execute do |response, request, result|
      case response.code
      when 200
        return response.to_str
      else
        puts "error: #{response.to_json}"
        raise Fluent::ConfigError, "Cannot reach Artifactory URL to pull Xray SIEM violations. #{response.to_json}"
      end
    end
  end
end

