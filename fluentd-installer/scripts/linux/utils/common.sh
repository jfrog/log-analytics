#!/bin/bash

# Common functions

# Terminate installation message
terminate() {
  termination_reason=$1
  echo
  echo 'Installation was unsuccessful!'
  echo "Reason(s): $termination_reason"
  echo
  echo 'Installation aborted!'
  echo
  exit 1
}

# Check if fluentd installed
fluentd_check() {
  fluentd_as_service=$1
  user_install_fluentd_file_path=$2
  no_service_detected_message="No fluentd detected. Please install fluentd before continue (more info: https://github.com/jfrog/log-analytics)"

   # td-agent check
  if [ fluentd_as_service == true  ]; then
    echo no td-agent check
    TD_AGENT_SERVICE_NAME="td-agent.service"
    td_agent_present=$(systemctl list-units --full -all | grep "$TD_AGENT_SERVICE_NAME")
    if [ -z "$td_agent_present" -a "$td_agent_present" != " " ]; then
      echo 'Error! No td-agent found!'
      terminate "$no_service_detected_message"
    fi
  # user installed fluentd check - check if fluentd file is in the bin folder
  elif [ ! -f "$user_install_fluentd_file_path" ]; then
    echo $user_install_fluentd_file_path
    terminate "$no_service_detected_message"
  fi
}
