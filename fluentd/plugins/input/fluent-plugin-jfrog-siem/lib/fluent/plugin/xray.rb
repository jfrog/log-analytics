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
    violations = Concurrent::Array.new
    xray_json = {"filters": { "created_from": for_date }, "pagination": {"order_by": "created","limit": @batch_size ,"offset": page_number } }
    resp = JSON.parse(get_xray_violations(xray_json), {symbolize_names: true})
    resp[:violations].each do |v|
      violations << v
    end
    violations
  end

  def violation_details(violations)
    violations.each do |v|
      Concurrent::Promises.future(v) do |v|
        puts "In future: ", v
        File.open(@pos_file, 'a') do |f|
          timestamp = DateTime.parse(v[:created]).strftime("%Y-%m-%dT%H:%M:%SZ")
          f.puts [timestamp, v[:watch_name], v[:issue_id]].join(',')
        end

        pull_violation_details(v[:violation_details_url])
      end
    end
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
          return response
        else
          puts "error: #{response.to_json}"
          raise Fluent::ConfigError, "Cannot reach Artifactory URL to pull Xray SIEM violations. #{response.to_json}"
        end
      end
    end
    # queries the xray API for violations based upon the input json
    def get_xray_violations_detail(xray_violation_detail_url)
      response = RestClient::Request.new(
          :method => :get,
          :url => xray_violation_detail_url,
          :user => @username,
          :password => @apikey
      ).execute do |response, request, result|
        case response.code
        when 200
          return response.to_str
        else
          puts "error: #{response.to_json}"
          raise Fluent::ConfigError, "Cannot reach Artifactory URL to pull Xray SIEM violations."
        end
      end
    end

    # normalizes Xray data according to common information models for all log-vendors
    def data_normalization(detailResp)
      detailResp_json = JSON.parse(detailResp)
      cve = []
      cvss_v2_list = []
      cvss_v3_list = []
      policy_list = []
      rule_list = []
      impacted_artifact_url_list = []
      if detailResp_json.key?('properties')
        properties = detailResp_json['properties']
        for index in 0..properties.length-1 do
          if properties[index].key?('cve')
            cve.push(properties[index]['cve'])
          end
          if properties[index].key?('cvss_v2')
            cvss_v2_list.push(properties[index]['cvss_v2'])
          end
          if properties[index].key?('cvss_v3')
            cvss_v3_list.push(properties[index]['cvss_v3'])
          end
        end

        detailResp_json["cve"] = cve.sort.reverse[0]
        cvss_v2 = cvss_v2_list.sort.reverse[0]
        cvss_v3 = cvss_v3_list.sort.reverse[0]
        if !cvss_v3.nil?
          cvss = cvss_v3
        elsif !cvss_v2.nil?
          cvss = cvss_v2
        end
        cvss_score = cvss[0..2]
        cvss_version = cvss.split(':')[1][0..2]
        detailResp_json["cvss_score"] = cvss_score
        detailResp_json["cvss_version"] = cvss_version
      end

      if detailResp_json.key?('matched_policies')
        matched_policies = detailResp_json['matched_policies']
        for index in 0..matched_policies.length-1 do
          if matched_policies[index].key?('policy')
            policy_list.push(matched_policies[index]['policy'])
          end
          if matched_policies[index].key?('rule')
            rule_list.push(matched_policies[index]['rule'])
          end
        end
        detailResp_json['policies'] = policy_list
        detailResp_json['rules'] = rule_list
      end

      impacted_artifacts = detailResp_json['impacted_artifacts']
      for impacted_artifact in impacted_artifacts do
        matchdata = impacted_artifact.match /default\/(?<repo_name>[^\/]*)\/(?<path>.*)/
        impacted_artifact_url = matchdata['repo_name'] + ":" + matchdata['path'] + " "
        impacted_artifact_url_list.append(impacted_artifact_url)
      end
      detailResp_json['impacted_artifacts_url'] = impacted_artifact_url_list
      return detailResp_json
    end

    def pull_violation_details(xray_violation_detail_url)
      begin
        puts "Pulling violation details for #{xray_violation_detail_url}"
        detailResp=get_xray_violations_detail(xray_violation_detail_url)
        time = Fluent::Engine.now
        detailResp_json = data_normalization(detailResp)
        router.emit(@tag, time, detailResp_json)
      rescue => e
        puts "error: #{e}"
        raise Fluent::ConfigError, "Error pulling violation details url #{xray_violation_detail_url}: #{e}"
      end
    end
end