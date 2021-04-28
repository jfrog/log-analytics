#
# Copyright 2021- MahithaB
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

module Fluent
  module Plugin
    class JfrogBuildinfoInput < Fluent::Plugin::Input
      Fluent::Plugin.register_input("jfrog_buildinfo", self)

      # `config_param` defines a parameter.
      # You can refer to a parameter like an instance variable e.g. @port.
      # `:default` means that the parameter is optional.
      config_param :tag, :string, default: ""
      config_param :jpd_url, :string, default: ""
      config_param :access_token, :string, default: ""

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
      end

      #call home functionality
      def call_home(jpd_url, access_token)
        call_home_json = { "productId": "jfrogLogAnalytics/v0.5.1", "features": [ { "featureId": "Platform/Artifactory" }, { "featureId": "Channel/buildinfo" } ] }
        response = RestClient::Request.new(
            :method => :post,
            :url => jpd_url + "/artifactory/api/system/usage",
            :payload => call_home_json.to_json,
            :headers => { :accept => :json, :content_type => :json, Authorization:'Bearer ' + access_token }
        ).execute do |response, request, result|
          puts "Posting call home information"
        end
      end

    end
  end
end


