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
require "fluent/plugin/xray"
require "fluent/plugin/position_file"

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
      config_param :pos_file_path, :string, default: ""

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
          puts "From date not specified, so getting violations from current date if pos_file doesn't exist"
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
        # call_home(@jpd_url)

        last_created_date = get_last_item_create_date()

        if (@from_date != "")
          last_created_date = DateTime.parse(@from_date).strftime("%Y-%m-%dT%H:%M:%SZ")
        end
        date_since = last_created_date
        puts "Getting queries from #{date_since}"
        xray = Xray.new(@jpd_url, @username, @apikey, @wait_interval, @batch_size, @pos_file_path, router)
        violations_channel = xray.violations(date_since)
        xray.violation_details(violations_channel)
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
        pos_file = @pos_file_path + "*.siem.pos"
        return Dir.glob(pos_file).sort.last
      end

    end
  end
end

