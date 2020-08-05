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

require 'rest-client'
require 'splunk-sdk-ruby'
require 'thread/pool'
require 'json'
require 'date'
require 'uri'
require 'logger'


xray_url, xray_user, xray_pass = "", "", ""
splunk_url, splunk_user, splunk_pass = "", 0, "", ""
splunk_indexname, splunk_detail_indexname, sourcetype = "", "", ""
jumps = 25
log_file='./logs/xray_splunk_integration.log'
logger = Logger.new(log_file)
logger.level = Logger::DEBUG

def input_arg_check
    if ARGV.length != 10
        errorMsg="Required args: <xray_url> <xray_user> <splunk_url> <splunk_user> <splunk_violation_index> <splunk_detail_index> <splunk_sourcetype> <thread_count> <xray_pass> <splunk_pass>"
        puts errorMsg
        logger.error(errorMsg)
        exit
    end
    if ARGV[0].length == 0
        errorMsg="Required args: <xray_url> <xray_user> <splunk_url> <splunk_user> <splunk_violation_index> <splunk_detail_index> <splunk_sourcetype> <thread_count> <xray_pass> <splunk_pass>"
        puts errorMsg
        logger.error(errorMsg)
        exit
    end
end


# queries the xray API for violations based upon the input json
def get_xray_violations_detail(xray_violation_url, xray_user, xray_pass)
    response = RestClient::Request.new(
        :method => :get,
        :url => xray_violation_url,
        :user => xray_user,
        :password => xray_pass
    ).execute do |response, request, result|
        case response.code
            when 200
                return response.to_str
            else
                errorMsg = "Error pulling Xray violations #{response.to_str}"
                fail errorMsg
                logger.error(errorMsg)
                exit
            end
        end
end


def check_if_splunk_item_exists(service, index_name, json)
    splunk_index = service.indexes[index_name]
    searchquery = "search \"" + json + "\" index=\"" + index_name + "\" | head 1"
    oneshotsearch_results = service.jobs.create_oneshot(searchquery)

    # Get the last splunk item or default to UNIX epoch
    reader = Splunk::ResultsReader.new(oneshotsearch_results)
    exists = false
    for item in reader
        exists = true
        break
    end
    return exists
end


# queries the xray API for violations based upon the input json
def get_xray_violations(xray_json, xray_url, xray_user, xray_pass)
    response = RestClient::Request.new(
        :method => :post,
        :url => xray_url + "/api/v1/violations",
        :user => xray_user,
        :password => xray_pass,
        :payload => xray_json.to_json,
        :headers => { :accept => :json, :content_type => :json }
    ).execute do |response, request, result|
        case response.code
            when 200
                return response.to_str
            else
                errorMsg = "Invalid response #{response.to_str} received."
                fail errorMsg
                logger.error(errorMsg)
                exit
            end
        end
end

def get_last_splunk_item_create_date(service, index_name)
    splunk_index = service.indexes[index_name]
    searchquery = "search * index=\"" + index_name + "\" | head 1"
    oneshotsearch_results = service.jobs.create_oneshot(searchquery)

    # Get the last splunk item or default to UNIX epoch
    created_date="1970-01-01T00:00:00Z"
    reader = Splunk::ResultsReader.new(oneshotsearch_results)

    for json_data in reader
        if json_data['_raw'].length > 0
            innerJson = json_data['_raw']
            # TODO: Json parsing for json_data
            # using regex matching because json_data cannot be converted to json directly
            matchData = innerJson.match(/.*created=(.*?),/)
            created_date = matchData[1]
        end
    end
    return created_date
end


def store_in_splunk(xray_violation_url, service, splunk_indexname, sourcetype, xray_user, xray_pass)
    splunk_index = service.indexes[splunk_indexname]
    begin
        detailResp=get_xray_violations_detail(xray_violation_url, xray_user, xray_pass)

        # Check to ensure this resp is not identical to the item itself
        persistItem = true

        # Determine if we need to persist this record or not
        if check_if_splunk_item_exists(service, splunk_indexname, detailResp)
            persistItem = false
        end

        # Save the record to the splunk index
        if persistItem
            splunk_index.submit(detailResp, :sourcetype => sourcetype)
        end
    rescue
        puts "Error pulling violation details url #{xray_violation_url}"
    end
end


########################################################################
# MAIN
########################################################################

# setup logging

# verify and assign input args
input_arg_check
xray_url = ARGV[0]
xray_user = ARGV[1]
splunk_url = ARGV[2]
splunk_user = ARGV[3]
splunk_indexname = ARGV[4]
splunk_detail_indexname = ARGV[5]
sourcetype = ARGV[6]
thread_count = ARGV[7].to_i
xray_pass = ARGV[8]
splunk_pass = ARGV[9]

if thread_count > jumps
    puts "Xray Splunk Integration allows you to specify how many violation detail urls to pull concurrently."
    puts "Violation Detail Url thread count should be less than #{jumps}"
    puts "Please specify a lower thread count to run the integration."
    logger.error("Violation detail url thread count exceeds batch size #{jumps}")
    exit 1
end

# Connect to the splunk server
service = Splunk::connect(:username => splunk_user, :password => splunk_pass, :host => splunk_url)

splunk_index = service.indexes[splunk_indexname]

last_created_date_string = get_last_splunk_item_create_date(service, splunk_indexname)
last_created_date=DateTime.parse(last_created_date_string).strftime("%Y-%m-%dT%H:%M:%SZ")

# Grab the first batch of records
offset_count=1
xray_json={"filters": { "created_from": last_created_date }, "pagination": {"order_by": "created","limit": jumps ,"offset": offset_count } }
resp=get_xray_violations(xray_json, xray_url, xray_user, xray_pass)
number_of_violations = JSON.parse(resp)['total_violations']

if number_of_violations != jumps
    logger.info('Xray Splunk Integration total number of records to process: #{number_of_violations}')
    puts "Xray Splunk Integration total number of records to process: #{number_of_violations}"
end

left_violations = number_of_violations
# iterate through this batch of violations and insert them into splunk
while left_violations > 0
    xray_violation_urls_list = []
    for index in 0..JSON.parse(resp)['violations'].length-1 do
        # Get the violation
        item = JSON.parse(resp)['violations'][index]

        # Get the created date and check if we should skip (already processed) or process this record.
        created_date_string = item['created']
        created_date = DateTime.parse(created_date_string).strftime("%Y-%m-%dT%H:%M:%SZ")

        # Determine if we need to persist this record or not
        persistItem = true
        if created_date < last_created_date
            persistItem = false
        elsif check_if_splunk_item_exists(service, splunk_indexname, URI.encode_www_form(item))
            persistItem = false
        elsif number_of_violations == jumps
            # cover the case of when we keep getting last record batch w/ same create date looping forever
            if last_created_date_string == created_date_string
                persistItem = false
            end
        end

        # Save the record to the splunk index
        if persistItem
            splunk_item = item.map {|p| '%s=%s' % p }.join(', ')
            splunk_index.submit(URI.decode(splunk_item), :sourcetype => sourcetype)
            # Mark this as the last record successfully processed
            last_created_date_string = created_date_string
            last_created_date = created_date
            # Grab violation detail url and add to url list to process w/ thread pool
            xray_violation_details_url=item['violation_details_url']
            xray_violation_urls_list.append(URI.decode(xray_violation_details_url))
        end
    end

    # iterate over url array adding to thread pool each url.
    # limit max workers to thread count to prevent overloading xray.
    thread_pool = Thread.pool(thread_count)
    for xray_violation_url in xray_violation_urls_list do
      thread_pool.process {
        store_in_splunk(xray_violation_url, service, splunk_detail_indexname, sourcetype, xray_user, xray_pass)
      }
    end

    thread_pool.shutdown

    # reduce left violations by jump size (not all batches have full item count??)
    left_violations = left_violations - jumps
    if left_violations <= 0
        exit
    end

    # Grab the next record to process for the violation details url
    offset_count = offset_count + 1
    xray_json={"filters": { "created_from": last_created_date_string }, "pagination": {"order_by": "created","limit": jumps , "offset": offset_count } }
    resp=get_xray_violations(xray_json, xray_url, xray_user, xray_pass)
end

