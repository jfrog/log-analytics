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
require "thread/pool"
require "json"
require "date"
require "uri"

module Fluent
  module Plugin
    class JfrogSiemInput < Fluent::Plugin::Input
      Fluent::Plugin.register_input("jfrog_siem", self)


      # `config_param` defines a parameter.
      # You can refer to a parameter like an instance variable e.g. @port.
      # `:default` means that the parameter is optional.
      config_param :tag, :string, default: ""
      config_param :jpd_url, :string, default: ""
      config_param :access_token, :string, default: ""
      config_param :pos_file, :string, default: ""
      config_param :batch_size, :integer, default: 25
      config_param :thread_count, :integer, default: 5
      config_param :wait_interval, :integer, default: 60


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

        if @access_token == ""
          raise Fluent::ConfigError, "Must define the access token to use for authentication."
        end

        if @pos_file == ""
          raise Fluent::ConfigError, "Must define a position file to record last SIEM violation pulled."
        end

        if @thread_count < 1
          raise Fluent::ConfigError, "Must define at least one thread to process violation details."
        end

        if @thread_count > @batch_size
          raise Fluent::ConfigError, "Violation detail url thread count exceeds batch size."
        end

        if @wait_interval < 1
          raise Fluent::ConfigError, "Wait interval must be greater than 1 to wait between pulling new events."
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
        call_home(@jpd_url, @access_token)
        # runs the violation pull
        last_created_date_string = get_last_item_create_date()
        begin
          last_created_date = DateTime.parse(last_created_date_string).strftime("%Y-%m-%dT%H:%M:%SZ")
        rescue
          last_created_date = DateTime.parse("1970-01-01T00:00:00Z").strftime("%Y-%m-%dT%H:%M:%SZ")
        end
        offset_count=1
        left_violations=0
        waiting_for_violations = false
        xray_json={"filters": { "created_from": last_created_date }, "pagination": {"order_by": "created","limit": @batch_size ,"offset": offset_count } }

        while true
          # Grab the batch of records
          resp=get_xray_violations(xray_json, @jpd_url, @access_token)
          number_of_violations = JSON.parse(resp)['total_violations']
          if left_violations <= 0
            left_violations = number_of_violations
          end

          xray_violation_urls_list = []
          for index in 0..JSON.parse(resp)['violations'].length-1 do
            # Get the violation
            item = JSON.parse(resp)['violations'][index]

            # Get the created date and check if we should skip (already processed) or process this record.
            created_date_string = item['created']
            created_date = DateTime.parse(created_date_string).strftime("%Y-%m-%dT%H:%M:%SZ")

            # Determine if we need to persist this record or not
            persistItem = true
            if waiting_for_violations
              if created_date <= last_created_date
                # "not persisting it - waiting for violations"
                persistItem = false
              end
            else
              if created_date < last_created_date
                # "persisting everything"
                persistItem = true
              end
            end

            # Publish the record to fluentd
            if persistItem

              now = Fluent::Engine.now
              router.emit(@tag, now, item)

              # write to the pos_file created_date_string
              open(@pos_file, 'a') do |f|
                f << "#{created_date_string}\n"
              end

              # Mark this as the last record successfully processed
              last_created_date_string = created_date_string
              last_created_date = created_date

              # Grab violation detail url and add to url list to process w/ thread pool
              xray_violation_details_url=item['violation_details_url']
              xray_violation_urls_list.append(xray_violation_details_url)
            end
          end

          # iterate over url array adding to thread pool each url.
          # limit max workers to thread count to prevent overloading xray.
          thread_pool = Thread.pool(thread_count)
          thread_pool.process {
            for xray_violation_url in xray_violation_urls_list do
              pull_violation_details(xray_violation_url, @access_token)
            end
          }
          thread_pool.shutdown

          # reduce left violations by jump size (not all batches have full item count??)
          left_violations = left_violations - @batch_size
          if left_violations <= 0
            waiting_for_violations = true
            sleep(@wait_interval)
          else
            # Grab the next record to process for the violation details url
            waiting_for_violations = false
            offset_count = offset_count + 1
            xray_json={"filters": { "created_from": last_created_date_string }, "pagination": {"order_by": "created","limit": @batch_size , "offset": offset_count } }
          end
        end
      end


      # pull the last item create date from the pos_file return created_date_string
      def get_last_item_create_date()
        if(!(File.exist?(@pos_file)))
          @pos_file = File.new(@pos_file, "w")
        end
        return IO.readlines(@pos_file).last
      end

      #call home functionality
      def call_home(jpd_url, access_token)
        call_home_json = { "productId": "jfrogLogAnalytics/v0.5.1", "features": [ { "featureId": "Platform/Xray" }, { "featureId": "Channel/xrayeventsiem" } ] }
        response = RestClient::Request.new(
            :method => :post,
            :url => jpd_url + "/artifactory/api/system/usage",
            :payload => call_home_json.to_json,
            :headers => { :accept => :json, :content_type => :json, Authorization:'Bearer ' + access_token }
        ).execute do |response, request, result|
            puts "Posting call home information"
        end
      end

      # queries the xray API for violations based upon the input json
      def get_xray_violations_detail(xray_violation_detail_url, access_token)
        response = RestClient::Request.new(
            :method => :get,
            :url => xray_violation_detail_url,
            headers: {Authorization:'Bearer ' + access_token}
        ).execute do |response, request, result|
          case response.code
          when 200
            return response.to_str
          else
            raise Fluent::StandardError, "Cannot reach Artifactory URL to pull Xray SIEM violations."
          end
        end
      end


      # queries the xray API for violations based upon the input json
      def get_xray_violations(xray_json, jpd_url, access_token)
        response = RestClient::Request.new(
            :method => :post,
            :url => jpd_url + "/xray/api/v1/violations",
            :payload => xray_json.to_json,
            :headers => { :accept => :json, :content_type => :json, Authorization:'Bearer ' + access_token }
        ).execute do |response, request, result|
          case response.code
          when 200
            return response.to_str
          else
            raise Fluent::StandardError, "Cannot reach Artifactory URL to pull Xray SIEM violations."
          end
        end
      end

      # normalizes Xray data according to common information models for all log-vendors
      def data_normalization(detailResp)
        detailResp_json = JSON.parse(detailResp)
        cve = []
        cvss_v2_list = []
        cvss_v3_list = []
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

        impacted_artifacts = detailResp_json['impacted_artifacts']
        for impacted_artifact in impacted_artifacts do
          matchdata = impacted_artifact.match /default\/(?<repo_name>[^\/]*)\/(?<path>.*)/
          impacted_artifact_url = matchdata['repo_name'] + ":" + matchdata['path'] + " "
          impacted_artifact_url_list.append(impacted_artifact_url)
        end
        detailResp_json['impacted_artifacts_url'] = impacted_artifact_url_list
        return detailResp_json
      end

      def pull_violation_details(xray_violation_detail_url, access_token)
        begin
          detailResp=get_xray_violations_detail(xray_violation_detail_url, access_token)
          time = Fluent::Engine.now
          detailResp_json = data_normalization(detailResp)
          router.emit(@tag, time, detailResp_json)
        rescue
          raise Fluent::StandardError, "Error pulling violation details url #{xray_violation_detail_url}"
        end
      end

    end
  end
end
