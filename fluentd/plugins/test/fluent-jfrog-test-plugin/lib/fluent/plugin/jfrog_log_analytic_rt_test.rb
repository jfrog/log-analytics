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
  #*  ARTIFACTORY TESTS
  #*|*_*|*_*|*_*|*_*|*_*|*_*|*_*|*_*|*_*|

  ######################
  ## SERVICE LOG TESTS
  ######################
  test "accessservicelogtest" do
    puts("JFrog Log Analytics - Access Service Log Test")
    testServiceLog(ENV["JFROG_LOG_DIR"] + '/access-service.log')
  end

  test "artifactoryservicelogtest" do
    puts("JFrog Log Analytics - Artifactory Service Log Test")
    testServiceLog(ENV["JFROG_LOG_DIR"] + '/artifactory-service.log')
  end

  test "frontendservicelogtest" do
    puts("JFrog Log Analytics - Frontend Service Log Test")
    testServiceLog(ENV["JFROG_LOG_DIR"] + '/frontend-service.log')
  end

  test "metadataservicelogtest" do
    puts("JFrog Log Analytics - Metadata Service Log Test")
    testServiceLog(ENV["JFROG_LOG_DIR"] + '/metadata-service.log')
  end

  test "routerservicelogtest" do
    puts("JFrog Log Analytics - Router Service Log Test")
    testServiceLog(ENV["JFROG_LOG_DIR"] + '/router-service.log')
  end

  def testServiceLog(filename)
    service_regexp = '^(?<timestamp>[^ ]*) \[(?<service_type>[^\]]*)\] \[(?<log_level>[^\]]*)\] \[(?<trace_id>[^\]]*)\] \[(?<class_line_number>.*)\] \[(?<thread>.*)\] -(?<message>.*)$'.gsub(%r{^\/(.+)\/$}, '\1')
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
    traefik_regexp = '^(?<timestamp>[^ ]*) \[(?<service_type>[^\]]*)\] \[(?<log_level>[^\]]*)\] \[(?<trace_id>[^\]]*)\] \[(?<class_line_number>.*)\] \[(?<thread>.*)\] -(?<message>.*)$'
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

  test "accessrequestlogtest" do
    puts("JFrog Log Analytics - Access Request Log Test")
    testRequestLog(ENV["JFROG_LOG_DIR"] + '/access-request.log')
  end

  test "artifactoryrequestlogtest" do
    puts("JFrog Log Analytics - Artifactory Request Log Test")
    testRequestLog(ENV["JFROG_LOG_DIR"] + '/artifactory-request.log')
  end

  test "frontendrequestlogtest" do
    puts("JFrog Log Analytics - Frontend Request Log Test")
    testRequestLog(ENV["JFROG_LOG_DIR"] + '/frontend-request.log')
  end

  test "metadatarequestlogtest" do
    puts("JFrog Log Analytics - Metadata Request Log Test")
    testRequestLog(ENV["JFROG_LOG_DIR"] + '/frontend-request.log')
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

  ######################
  ## ACCESS LOG TESTS
  ######################
  test "artifactoryaccesslogtest" do
    puts("JFrog Log Analytics - Artifactory Access Log Test")
    access_regexp = '^(?<timestamp>[^ ]*) \[(?<trace_id>[^\]]*)\] \[(?<action_response>[^\]]*)\] (?<repo_path>.*) for client : (?<username>.+)/(?<ip>.+)$'
    line_num=0
    text=File.open(ENV["JFROG_LOG_DIR"] + '/artifactory-access.log').read
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
              'expression' => access_regexp,
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
          if @parsed['action_response'].nil? or @parsed['action_response'].empty?
            flunk
          end
          if @parsed['repo_path'].nil? or @parsed['repo_path'].empty?
            flunk
          end
        rescue *Jfrogplatformtest::HANDLE_ERRORS => e
          flunk
        end
      end
    end
    puts("Number of lines checked: " + line_num.to_s)
  end

  ##############################
  ## ACCESS SECURITY LOG TESTS
  ##############################
  test "accesssecuritylogtest" do
    puts("JFrog Log Analytics - Access Security Audit Log Test")
    access_regexp = '^(?<timestamp>[^ ]*)\|(?<token_id>[^ ]*)\|(?<user_ip>[^ ]*)\|(?<user>[^ ]*)\|(?<logged_principal>[^ ]*)\|(?<entity_name>[^ ]*)\|(?<event_type>[^ ]*)\|(?<event>[^ ]*)\|(?<data_changed>.*)'
    line_num=0
    text=File.open(ENV["JFROG_LOG_DIR"] + '/access-security-audit.log').read
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
              'expression' => access_regexp,
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
          if @parsed['token_id'].nil? or @parsed['token_id'].empty?
            flunk
          end
          if @parsed['user_ip'].nil? or @parsed['user_ip'].empty?
            flunk
          end
          if @parsed['user'].nil? or @parsed['user'].empty?
            flunk
          end
          if @parsed['logged_principal'].nil? or @parsed['logged_principal'].empty?
            flunk
          end
          if @parsed['entity_name'].nil? or @parsed['entity_name'].empty?
            flunk
          end
          if @parsed['event_type'].nil? or @parsed['event_type'].empty?
            flunk
          end
          if @parsed['data_changed'].nil? or @parsed['data_changed'].empty?
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
