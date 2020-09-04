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
    if ENV["ARTIFACTORY_LOG_DIR"] == nil
      puts("Skipping JFrog Artifactory 6.x Log Analytic Tests missing ARTIFACTORY_LOG_DIR environment variable.")
      flunk
    end
  end


  #######################
  ## ARTIFACTORY LOG TEST
  #######################
  test "artifactorylogtest" do
    puts("JFrog Log Analytics - Artifactory Log Test")
    artifactory_regexp = '^(?<timestamp>[^.*]*) \[(?<service_type>[^\]]*)\] \[(?<log_level>[^\]]*)\] (?<class_line_number>.*) -(?<message>.*)$'
    line_num=0
    text=File.open(ENV["ARTIFACTORY_LOG_DIR"] + '/artifactory.log').read
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
              'expression' => artifactory_regexp,
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
        rescue *Jfrogplatformtest::HANDLE_ERRORS => e
          flunk
        end
      end
    end
    puts("Number of lines checked: " + line_num.to_s)
  end

  #######################
  ## REQUEST LOG TEST
  #######################
  test "requestlogtest" do
    puts("JFrog Log Analytics - Request Log Test")
    request_regexp = '^(?<timestamp>[^ ]*)\|(?<trace_id>[^\|]*)\|(?<type>[^\|]*)\|(?<remote_address>[^\|]*)\|(?<username>[^\|]*)\|(?<request_method>[^\|]*)\|(?<request_url>[^\|]*)\|(?<request_user_agent>[^\|]*)\|(?<return_status>[^\|]*)\|(?<request_duration>.+)$'
    line_num=0
    text=File.open(ENV["ARTIFACTORY_LOG_DIR"] + '/request.log').read
    text.gsub!(/\r\n?/, "\n")
    text.each_line do |line|
      line_num += 1
      if line =~ /^\d+/
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
        rescue *Jfrogplatformtest::HANDLE_ERRORS => e
          flunk
        end
      end
    end
    puts("Number of lines checked: " + line_num.to_s)
  end

  #######################
  ## ACCESS LOG TEST
  #######################
  test "accesslogtest" do
    puts("JFrog Log Analytics - Access Log Test")
    access_regexp = '^(?<timestamp>[^.*]*) \[(?<action_response>[^\]]*)\] (?<repo_path>.*) for client : (?<username>.+) / (?<ip>.+)$'
    line_num=0
    text=File.open(ENV["ARTIFACTORY_LOG_DIR"] + '/access.log').read
    text.gsub!(/\r\n?/, "\n")
    text.each_line do |line|
      line_num += 1
      if line =~ /^\d+/
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
