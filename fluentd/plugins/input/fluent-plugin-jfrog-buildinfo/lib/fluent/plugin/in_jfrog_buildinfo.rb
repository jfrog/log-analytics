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

require 'net/http'
require "fluent/plugin/input"
require "rest-client"
require "thread/pool"
require 'socket'
require 'securerandom'


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
      config_param :webhook_url, :string, default: "localhost"
      config_param :port_to_listen_to, :integer, default: 9001

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

        if @webhook_url == "localhost"
          endpoint_url = "http://localhost:" + @port_to_listen_to
        else
          endpoint_url = @webhook_url
        end
      end

      # `start` is called when starting and after `configure` is successfully completed.
      def start
        super
        @running = true
        @thread = Thread.new(&method(:run))

        puts "starting to listen to: #{@port_to_listen_to}"
        server = TCPServer.open('localhost', @port_to_listen_to)

        loop {
          client = server.accept
          method, path = client.gets.split
          headers = {}

          while line = client.gets.split(' ', 2)
            break if line[0] == ""
            headers[line[0].chop] = line[1].strip
          end

          data = client.read(headers["Content-Length"].to_i)
          puts data
          client.puts "HTTP/1.1 200 Success"
          client.puts ""
          client.puts "Success\n"
          client.close
        }
      end

      def shutdown
        @running = false
        @thread.join
        super
      end

      def run
        puts "================================="
        call_home(@jpd_url, @access_token)
        webhook_secret = generate_webhook_secret()
        create_webhook(@jpd_url, @access_token, @webhook_url, webhook_secret)

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

      def generate_webhook_secret()
        return "jfrog_webhook_" + SecureRandom.urlsafe_base64
      end

      #creates a webhook to call back to our service
      def create_webhook(jpd_url, access_token, webhook_url, webhook_secret)
        webhook_payload = {
            "key": "ObservabilityBuildInfoWebhook_3",
            "description": "Observability build info webhook for build upload or promoted",
            "enabled": true,
            "event_filter": {
              "domain": "build",
              "event_types": [
                "uploaded",
                "promoted"
              ],
            "criteria": {
              "anyBuild": true
            }
          },
          "handlers": [
              {
              "handler_type": "webhook",
              "url": webhook_url,
              "secret": webhook_secret
            }
          ]
        }

        response = RestClient::Request.new(
            :method => :post,
            :url => jpd_url + "/event/api/v1/subscriptions",
            :payload => webhook_payload.to_json,
            :headers => { :accept => :json, :content_type => :json, Authorization:'Bearer ' + access_token }
        ).execute do |response, request, result|
          case response.code
          when 201
            puts "Webhook created"
            return response.to_str
          else
            puts "Failed to create necessary webhook", response.code
          end
        end
      end


    end
  end
end


