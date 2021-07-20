#
# Copyright 2020 - JFrog
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
require "fluent/plugin/input"
require "rest-client"
require "date"
require "uri"
require "fluent/plugin/xray.rb"
require "fluent/plugin/position_file.rb"

module Fluent
  module Plugin
    class JfrogSiemInput < Fluent::Plugin::Input
      Fluent::Plugin.register_input("jfrog_siem", self)


      # `config_param` defines a parameter.
      # You can refer to a parameter like an instance variable e.g. @port.
      # `:default` means that the parameter is optional.
      config_param :tag, :string, default: ""
      config_param :jpd_url, :string, default: ""
      config_param :username, :string, default: ""
      config_param :apikey, :string, default: ""
      config_param :batch_size, :integer, default: 25
      config_param :wait_interval, :integer, default: 60
      config_param :from_date, :string, default: ""

      # `configure` is called before `start`.
      # 'conf' is a `Hash` that includes the configuration parameters.
      # If the configuration is invalid, raise `Fluent::ConfigError`.
      def configure(conf)
        super
        if @tag == ""
          raise Fluent::ConfigError, "Must define a tag for the SIEM data."
        end

        if @jpd_url == ""
          raise Fluent::ConfigError, "Must define the JPD URL to pull Xray SIEM violations."
        end

        if @username == ""
          raise Fluent::ConfigError, "Must define the username to use for authentication."
        end

        if @apikey == ""
          raise Fluent::ConfigError, "Must define the API Key to use for authentication."
        end

        if @wait_interval < 1
          raise Fluent::ConfigError, "Wait interval must be greater than 1 to wait between pulling new events."
        end

        if @from_date == ""
          puts "From date not specified, so getting violations from current date"
        end

      end


      # `start` is called when starting and after `configure` is successfully completed.
      def start
        super
        @running = true
        @thread = Thread.new(&method(:run))
      end


      def shutdown
        @running = false
        @thread.join
        super
      end


      def run
        call_home(@jpd_url)

        last_created_date = get_last_item_create_date()

        if (@from_date != "")
          last_created_date = DateTime.parse(@from_date).strftime("%Y-%m-%dT%H:%M:%SZ")
        end
        date_since = last_created_date
        xray = Xray.new(@jpd_url, @username, @apikey, @wait_interval, @batch_size)
        violations_channel = xray.violations(date_since)
        violation_details(violations_channel)
        sleep 100
      end

      #call home functionality
      def call_home(jpd_url)
        call_home_json = { "productId": "jfrogLogAnalytics/v0.5.1", "features": [ { "featureId": "Platform/Xray" }, { "featureId": "Channel/xrayeventsiem" } ] }
        response = RestClient::Request.new(
            :method => :post,
            :url => jpd_url + "/artifactory/api/system/usage",
            :payload => call_home_json.to_json,
            :user => @username,
            :password => @apikey,
            :headers => { :accept => :json, :content_type => :json}
        ).execute do |response, request, result|
          puts "Posting call home information"
        end
      end

      # pull the last item create date from the pos_file return created_date_string
      def get_last_item_create_date()
        recent_pos_file = get_recent_pos_file()
        if recent_pos_file != nil
          last_created_date_string = IO.readlines(recent_pos_file).last
          return DateTime.parse(last_created_date_string).strftime("%Y-%m-%dT%H:%M:%SZ")
        else
          return DateTime.now.strftime("%Y-%m-%dT%H:%M:%SZ")
        end
      end

      def get_recent_pos_file()
        return Dir.glob("*.pos").sort[-1]
      end

      def violation_details(violations_channel)
        violations_channel.each do |v|
          Concurrent::Promises.future(v) do |v7|
            pull_violation_details(v['violation_details_url'])
            PositionFile.new.write(v)
          end
        end
      end

      def pull_violation_details(xray_violation_detail_url)
        begin
          detailResp=get_xray_violations_detail(xray_violation_detail_url)
          time = Fluent::Engine.now
          detailResp_json = data_normalization(detailResp)
          router.emit(@tag, time, detailResp_json)
        rescue => e
          puts "error: #{e}"
          raise Fluent::ConfigError, "Error pulling violation details url #{xray_violation_detail_url}: #{e}"
        end
      end

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

    end
  end
end

