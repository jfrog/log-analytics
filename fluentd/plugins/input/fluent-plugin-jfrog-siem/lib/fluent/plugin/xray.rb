require 'concurrent'
require 'concurrent-edge'
require 'json'

class Xray
  def initialize(jpd_url, username, api_key, wait_interval, batch_size, pos_file)
    @jpd_url = jpd_url
    @username = username
    @api_key = api_key
    @wait_interval = wait_interval
    @batch_size = batch_size
    @pos_file = pos_file
  end

  def violations(date_since)
    violations_channel = Concurrent::Channel.new(capacity: 100)
    request_json = Concurrent::Channel.new(capacity: 1)
    page_number = 1
    # timer_task = Concurrent::TimerTask.new(execution_interval: @wait_interval, timeout_interval: 30) do
      xray_json = {"filters": { "created_from": date_since }, "pagination": {"order_by": "created","limit": @batch_size ,"offset": page_number } }
      resp = JSON.parse(get_xray_violations(xray_json))
      puts "Violations count is #{resp['total_violations']}"
      resp['violations'].each do |v|
        violations_channel << v
      end
      page_number += 1
    # end
    # timer_task.execute
    violations_channel
  end

  def violation_details(violations_channel)
    puts "violations details"
    violations_channel.each do |v|
      puts v
      Concurrent::Promises.future(v) do |v|
        puts "do nothing"
        # open(@pos_file, 'a') do |f|
        #   created_date = DateTime.parse(v['created']).strftime("%Y-%m-%dT%H:%M:%SZ")
        #   f.puts [created_date, v['watch_name'], v['issue_id']].join(',')
        # end

        # pull_violation_details(v['violation_details_url'])
      end
    end
  end

  private
    def get_xray_violations(xray_json)
      puts "jpd_url for #{@jpd_url}"
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