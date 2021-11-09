#!/bin/bash

#common vars
GREEN_COLOR='\033[0;32m'
NO_COLOR='\033[0m'
ERROR_COLOR='\033[0;31m'

# Common functions

# Terminate installation message
terminate() {
  termination_reason=$1
  echo
  print_error 'Installation was unsuccessful!'
  print_error "Reason(s): $termination_reason"
  echo
  print_error 'Installation aborted!'
  echo
  exit 1
}

# Check if fluentd installed
fluentd_check() {
  fluentd_as_service=$1
  user_install_fluentd_file_test_path=$2
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
  elif [ ! -f "$user_install_fluentd_file_test_path" ]; then
    echo $user_install_fluentd_file_test_path
    terminate "$no_service_detected_message"
  fi
}

run_command() {
  run_as_sudo=$1
  command_string=$2
  # check if run the command as sudo
  if [ $run_as_sudo = true ]; then
    sudo_cmd="sudo"
  fi
  # run the command
  {
    ${sudo_cmd} ${command_string}
  } || {
    print_error "Error, command:'$command_string'. Please check the logs for more information. "
  }
}

print_error() {
  error_message=$1
  echo ""
  echo -e "$ERROR_COLOR$error_message$NO_COLOR"
}
