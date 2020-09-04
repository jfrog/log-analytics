# frozen_string_literal: true
require 'fluent/env'
require 'fluent/version'
require 'fluent/engine'
require 'fluent/plugin/parser_regexp'
require "test-unit"
require "fluent/test"
require "fluent/test/driver/input"
require "fluent/test/helpers"



module Jfrogplatformtest
  VERSION = ::Fluent::VERSION

  HANDLE_ERRORS = [
      Fluent::Plugin::Parser::ParserError,
      Fluent::ConfigError,
      RegexpError
  ].freeze
end

class JfrogSiemInputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
    if ENV["JFROG_LOG_DIR"] == nil
      puts("Skipping JFrog Platform Log Analytic Tests missing JFROG_LOG_DIR environment variable.")
      flunk
    end
  end

  #*|*_*|*_*|*_*|*_*|*_*|*_*|*_*|*_*|*_*|
  #*  MISSION CONTROL TESTS
  #*|*_*|*_*|*_*|*_*|*_*|*_*|*_*|*_*|*_*|

  ######################
  ## SERVICE LOG TESTS
  ######################
  test "insightschedulerservicelogtest" do
    puts("JFrog Log Analytics - Mission Control Insight Scheduler Service Log Test")
    testServiceLog(ENV["JFROG_LOG_DIR"] + '/insight-scheduler-service.log')
  end

  test "insightserverservicelogtest" do
    puts("JFrog Log Analytics - Mission Control Insight Server Service Log Test")
    testServiceLog(ENV["JFROG_LOG_DIR"] + '/insight-server-service.log')
  end

  test "routerservicelogtest" do
    puts("JFrog Log Analytics - Router Service Log Test")
    testServiceLog(ENV["JFROG_LOG_DIR"] + '/router-service.log')
  end

  test "missioncontrolservicelogtest" do
    puts("JFrog Log Analytics - Mission Control Service Log Test")
    testServiceLog(ENV["JFROG_LOG_DIR"] + '/mc-service.log')
  end

  test "missioncontrolerrorlogtest" do
    puts("JFrog Log Analytics - Mission Control Error Log Test")
    testServiceLog(ENV["JFROG_LOG_DIR"] + '/mc-error.log')
  end

  def testServiceLog(filename)
    service_regexp = '^(?<timestamp>[^ ]*) \[(?<service_type>[^\]]*)\] \[(?<log_level>[^\]]*)\] \[(?<trace_id>[^\]]*)\] \[(?<class_line_number>.*)\] \[(?<thread>.*)\] -(?<message>.*)$'
    line_num=0
    text=File.open(filename).read
    text.gsub!(/\r\n?/, "\n")
    # remove color codes
    text.gsub!(/\e\[([;\d]+)?m/, '')
    text.each_line do |line|
      line_num += 1
      if line =~ /^\d+-\d+-\d/
        #puts(line)
        @time_format = ''
        @error       = nil
        begin
          parser = Fluent::Plugin::RegexpParser.new
          conf = {
              'expression' => service_regexp,
              'time_format' => @time_format
          }
          parser.configure(
              Fluent::Config::Element.new('', '', conf, [])
          )
          parser.parse(line) do |parsed_time, parsed|
            @parsed_time = parsed_time
            @parsed      = parsed
          end
          if @parsed.nil?
            flunk
          end
          if @parsed_time.nil?
            flunk
          end
          if @parsed['timestamp'].nil? or @parsed['timestamp'].empty?
            flunk
          end
          if @parsed['service_type'].nil? or @parsed['service_type'].empty?
            flunk
          end
          if @parsed['log_level'].nil? or @parsed['log_level'].empty?
            flunk
          end
          if @parsed['trace_id'].nil? or @parsed['trace_id'].empty?
            flunk
          end
          if @parsed['class_line_number'].nil? or @parsed['class_line_number'].empty?
            flunk
          end
          if @parsed['thread'].nil? or @parsed['thread'].empty?
            flunk
          end
          # ' ' single space is considered passing.
          if @parsed['message'].nil? or @parsed['message'].empty?
            flunk
          end
        rescue *Jfrogplatformtest::HANDLE_ERRORS => e
          flunk
        end
      end
    end
    puts("Number of lines checked: " + line_num.to_s)
  end

  ######################
  ## TRAEFIK LOG TEST
  ######################
  test "routertraefiklogtest" do
    puts("JFrog Log Analytics - Router Traefik Log Test")
    traefik_regexp = '^(?<timestamp>[^ ]*) \[(?<service_type>[^\]]*)\] \[(?<log_level>[^\]]*)\] \[(?<trace_id>[^\]]*)\] \[(?<class_line_number>.*)\] \[(?<thread>.*)\] -(?<message>.+)$'
    line_num=0
    text=File.open(ENV["JFROG_LOG_DIR"] + '/router-traefik.log').read
    text.gsub!(/\r\n?/, "\n")
    text.each_line do |line|
      line_num += 1
      if line =~ /^\d+-\d+-\d/
        #puts(line)
        @time_format = ''
        @error       = nil
        begin
          parser = Fluent::Plugin::RegexpParser.new
          conf = {
              'expression' => traefik_regexp,
              'time_format' => @time_format
          }
          parser.configure(
              Fluent::Config::Element.new('', '', conf, [])
          )
          parser.parse(line) do |parsed_time, parsed|
            @parsed_time = parsed_time
            @parsed      = parsed
          end
          if @parsed_time.nil?
            flunk
          end
          if @parsed['timestamp'].nil? or @parsed['timestamp'].empty?
            flunk
          end
          if @parsed['service_type'].nil? or @parsed['service_type'].empty?
            flunk
          end
          if @parsed['log_level'].nil? or @parsed['log_level'].empty?
            flunk
          end
          if @parsed['trace_id'].nil? or @parsed['trace_id'].empty?
            flunk
          end
          if @parsed['class_line_number'].nil? or @parsed['class_line_number'].empty?
            flunk
          end
          if @parsed['thread'].nil? or @parsed['thread'].empty?
            flunk
          end
          # ' ' single space is considered passing.
          if @parsed['message'].nil? or @parsed['message'].empty?
            flunk
          end
        rescue *Jfrogplatformtest::HANDLE_ERRORS => e
          flunk
        end
      end
    end
    puts("Number of lines checked: " + line_num.to_s)
  end


  ######################
  ## REQUEST LOG TESTS
  ######################

  test "missioncontrolrequestlogtest" do
    puts("JFrog Log Analytics - Misson Control Request Log Test")
    testRequestLog(ENV["JFROG_LOG_DIR"] + '/mc-request.log')
  end

  test "missioncontrolinsightserverrequestlogtest" do
    puts("JFrog Log Analytics - Misson Control Insight Server Request Log Test")
    testRequestLog(ENV["JFROG_LOG_DIR"] + '/insight-server-request.log')
  end

  test "missioncontrolinsightschedulerrequestlogtest" do
    puts("JFrog Log Analytics - Misson Control Insight Scheduler Request Log Test")
    testRequestLog(ENV["JFROG_LOG_DIR"] + '/insight-scheduler-request.log')
  end


  def testRequestLog(filename)
    request_regexp = '^(?<timestamp>[^ ]*)\|(?<trace_id>[^\|]*)\|(?<remote_address>[^\|]*)\|(?<username>[^\|]*)\|(?<request_method>[^\|]*)\|(?<request_url>[^\|]*)\|(?<return_status>[^\|]*)\|(?<response_content_length>[^\|]*)\|(?<request_content_length>[^\|]*)\|(?<request_duration>[^\|]*)\|(?<request_user_agent>.+)$'.gsub(%r{^\/(.+)\/$}, '\1')
    line_num=0
    text=File.open(filename).read
    text.gsub!(/\r\n?/, "\n")
    text.each_line do |line|
      line_num += 1
      if line =~ /^\d+-\d+-\d/
        #puts(line)
        @time_format = ''
        @error       = nil
        begin
          parser = Fluent::Plugin::RegexpParser.new
          conf = {
              'expression' => request_regexp,
              'time_format' => @time_format
          }
          parser.configure(
              Fluent::Config::Element.new('', '', conf, [])
          )
          parser.parse(line) do |parsed_time, parsed|
            @parsed_time = parsed_time
            @parsed      = parsed
          end
          if @parsed_time.nil?
            flunk
          end

          if @parsed['timestamp'].nil? or @parsed['timestamp'].empty?
            flunk
          end
          if @parsed['trace_id'].nil? or @parsed['trace_id'].empty?
            flunk
          end
          if @parsed['remote_address'].nil? or @parsed['remote_address'].empty?
            flunk
          end
          if @parsed['username'].nil? or @parsed['username'].empty?
            flunk
          end
          if @parsed['request_method'].nil? or @parsed['request_method'].empty?
            flunk
          end
          if @parsed['request_url'].nil? or @parsed['request_url'].empty?
            flunk
          end
          if @parsed['return_status'].nil? or @parsed['return_status'].empty?
            flunk
          end
          if @parsed['response_content_length'].nil? or @parsed['response_content_length'].empty?
            flunk
          end
          if @parsed['request_content_length'].nil? or @parsed['request_content_length'].empty?
            flunk
          end
          if @parsed['request_duration'].nil? or @parsed['request_duration'].empty?
            flunk
          end
          if @parsed['request_user_agent'].nil? or @parsed['request_user_agent'].empty?
            flunk
          end
        rescue *Jfrogplatformtest::HANDLE_ERRORS => e
          flunk
        end
      end
    end
    puts("Number of lines checked: " + line_num.to_s)
  end

  private

  def create_driver(conf)
    Fluent::Test::Driver::Input.new(Fluent::Plugin::JfrogSiemInput).configure(conf)
  end
end
