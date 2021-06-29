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
require "date"
require "uri"
require 'xray'

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
      config_param :pos_file, :string, default: ""
      config_param :batch_size, :integer, default: 5
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

        if @username == ""
          raise Fluent::ConfigError, "Must define the username to use for authentication."
        end

        if @apikey == ""
          raise Fluent::ConfigError, "Must define the API Key to use for authentication."
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
        call_home(@jpd_url)

        last_created_date_string = get_last_item_create_date()
        begin
          last_created_date = DateTime.parse(last_created_date_string).strftime("%Y-%m-%dT%H:%M:%SZ")
        rescue
          last_created_date = DateTime.parse("1970-01-01T00:00:00Z").strftime("%Y-%m-%dT%H:%M:%SZ")
        end
        for_date = last_created_date
        
        xray = Xray.new(@jpd_url, @username, @apikey, @wait_interval, @batch_size, @pos_file)

        violations_count = xray.violations_count(for_date)
        puts violations_count
        puts xray.page_count(violations_count)
        page_count = xray.page_count(violations_count)
        (1..xray.page_count(violations_count)).each  do |page_number|
          violations = xray.violations_by_page(for_date, page_number)
          puts "getting details for #{page_number}"
          xray.violation_details(violations)
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

    end
  end
end
