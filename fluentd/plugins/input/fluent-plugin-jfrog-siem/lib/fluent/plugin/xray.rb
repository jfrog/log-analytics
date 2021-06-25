require 'concurrent'
require 'concurrent-edge'
require 'json'
require "rest-client"


class Xray
  def initialize(jpd_url, username, api_key, wait_interval, batch_size, pos_file)
    @jpd_url = jpd_url
    @username = username
    @api_key = api_key
    @wait_interval = wait_interval
    @batch_size = batch_size
    @pos_file = pos_file
  end

  def violations_count(for_date)
    xray_json = {"filters": { "created_from": for_date }, "pagination": {"order_by": "created","limit": @batch_size ,"offset": 1 } }
    JSON.parse(get_xray_violations(xray_json))['total_violations']
  end

  def page_count(total_violations)
    pages = total_violations / @batch_size
    another_page = total_violations % @batch_size
    return pages + 1 if another_page > 0
    return pages
  end

  def violations_by_page(for_date, page_number)
    violations = Concurrent::Array.new(@batch_size)
    xray_json = {"filters": { "created_from": for_date }, "pagination": {"order_by": "created","limit": @batch_size ,"offset": page_number } }
    resp = JSON.parse(get_xray_violations(xray_json))
    resp['violations'].each do |v|
      violations << v
    end
    violations
  end

  def violation_details(violations)
    violations.each do |v|
      Concurrent::Promises.future(v) do |v|
        open(@pos_file, 'a') do |f|
          created_date = DateTime.parse(v['created']).strftime("%Y-%m-%dT%H:%M:%SZ")
          f.puts [created_date, v['watch_name'], v['issue_id']].join(',')
        end

        pull_violation_details(v['violation_details_url'])
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