#!/bin/bash

# const
declare FLUENTD_SPLUNK_CONF_BASE_URL='https://raw.githubusercontent.com/jfrog/log-analytics-splunk/master'
declare TEMP_FOLDER='/tmp'

# load common functions
source ./utils/common.sh # TODO Update the path (git raw)

intro() {
  ## Splunk - Fluentd Install Script
  declare logo=`cat ./other/spl_ascii_logo.txt`
  echo
  print_green "$logo"
  echo
  print_green "================================================================================================================="
  print_green 'The installation script for the Splunk plugin performs the following tasks:'
  print_green '- Configure Splunk for JFrog artifactory, xray, etc'
  echo
  print_error "ALERT: Before continuing please complete the following manual steps:"
  print_green "1) Splunkbase App (more info: https://github.com/jfrog/log-analytics-splunk#splunkbase-app)
  - Install the JFrog Log Analytics Platform app from Splunkbase - https://splunkbase.splunk.com/app/5023.
  - Restart Splunk post installation of App.
  - Login to Splunk after the restart completes.
  - Confirm the version is the latest version available in Splunkbase.

2) Configure Splunk (more info: https://github.com/jfrog/log-analytics-splunk#configure-splunk)
  - Create new index 'jfrog_splunk'.
  - Configure new HEC token to receive Logs (use 'jfrog_splunk' index to store the JFrog platform log data into)."
  echo
  print_green 'More info: https://github.com/jfrog/log-analytics-splunk'
  print_green "================================================================================================================="

  declare continue_with_steps=$(question "Are you ready to continue? [y/n]: ")
  if [ "$continue_with_steps" == false ]; then
    echo 'Please complete the Splunk pre installation steps before continue.'
    echo 'Have a nice day! Good Bye!'
    exit 1
  fi
  echo
}

shared_config_questions() {
  declare fluentd_splunk_conf_name=$1
  declare $fluentd_as_service=$2

  download_fluentd_conf_file  $FLUENTD_SPLUNK_CONF_BASE_URL $fluentd_splunk_conf_name $TEMP_FOLDER
  # configure HEC url
  update_fluentd_config_file "$TEMP_FOLDER/$fluentd_splunk_conf_name" 'Provide IP or URL of Splunk HEC: ' 'HEC_HOST' false $fluentd_as_service
  # configure HEC port
  update_fluentd_config_file "$TEMP_FOLDER/$fluentd_splunk_conf_name" 'Provide Splunk HEC port: ' 'HEC_PORT' false $fluentd_as_service
  # configure HEC token
  update_fluentd_config_file "$TEMP_FOLDER/$fluentd_splunk_conf_name" 'Provide Splunk HEC token: ' 'HEC_TOKEN' true $fluentd_as_service
}

configure_fluentd() {
  declare fluentd_as_service=$1
  declare user_install_fluentd_install_path=$2
  declare gem_command=$3

  # Downloading the fluentd config for Splunk based on the user input
  config_download_path_base="https://raw.githubusercontent.com/jfrog/log-analytics-splunk/master/"
  while true; do
    echo
    read -p 'Type of Splunk configuration: [Artifactory, Xray, Missioncontrol, Distribution or Pipelines]: ' product_name
    case $product_name in
    [artifactory]*)
      jfrog_env_variables '/var/opt/jfrog/artifactory/' 'artifactory' $fluentd_as_service 'artifactory'
      declare fluentd_splunk_conf_name='fluent.conf.rt'
      # shared splunk configuration questions
      shared_config_questions $fluentd_splunk_conf_name $fluentd_as_service
      break
      ;;
    [xray]*)
      jfrog_env_variables '/var/opt/jfrog/xray/' 'xray' $fluentd_as_service 'xray'
      declare fluentd_splunk_conf_name='fluent.conf.xray'
      # shared splunk configuration questions
      shared_config_questions $fluentd_splunk_conf_name $fluentd_as_service
      # Xray related config questions
      xray_shared_questions "$TEMP_FOLDER" "$fluentd_splunk_conf_name" "$gem_command" "$fluentd_as_service"
      # install SIEM plugin
      echo
      install_custom_plugin 'SIEM' "$gem_command" "$fluentd_as_service"
      break
      ;;
    #[nginx]*)
    #  jfrog_env_variables '/var/opt/jfrog/artifactory/' 'artifactory'
    #  declare fluentd_splunk_conf_name='fluent.conf.nginx'
    #  download_fluentd_conf_file $fluentd_splunk_conf_name
    #  break
    #  ;;
    [missioncontrol]*)
      jfrog_env_variables '/var/opt/jfrog/xray/' 'mission Control' $fluentd_as_service
      declare fluentd_splunk_conf_name='fluent.conf.missioncontrol'
      # shared splunk configuration questions
      shared_config_questions $fluentd_splunk_conf_name $fluentd_as_service
      break
      ;;
    [distribution]*)
      jfrog_env_variables '/var/opt/jfrog/distribution/' 'distribution' $fluentd_as_service
      declare fluentd_splunk_conf_name='fluent.conf.distribution'
      # shared splunk configuration questions
      shared_config_questions $fluentd_splunk_conf_name $fluentd_as_service
      break
      ;;
   [pipelines]*)
     jfrog_env_variables '/opt/jfrog/pipelines/var/' 'pipelines' $fluentd_as_service
      declare fluentd_splunk_conf_name='fluent.conf.pipelines'
      # shared splunk configuration questions
      shared_config_questions $fluentd_splunk_conf_name $fluentd_as_service
      break
      ;;
    *) echo 'Incorrect value, please try again. ' ;
    esac
  done

  # finalizing configuration
  local configuration_file
  if [ $fluentd_as_service == true ]; then
    copy_fluentd_conf '/etc/td-agent' "$fluentd_splunk_conf_name" true "$TEMP_FOLDER"
    configuration_file="/etc/td-agent/$fluentd_splunk_conf_name"
  else
    copy_fluentd_conf "$user_install_fluentd_install_path" "$fluentd_splunk_conf_name" true "$TEMP_FOLDER"
    configuration_file="$user_install_fluentd_install_path/$fluentd_splunk_conf_name"
  fi
  echo
}

install_plugin() {
  declare fluentd_as_service=$1
  declare install_as_docker=$2
  declare user_install_fluentd_install_path=$3
  declare gem_command=$4

  #init script
  intro

  # install splunk fluentd plugin
  declare install_splunk_command="$gem_command install fluent-plugin-splunk-enterprise"

  run_command $fluentd_as_service "$install_splunk_command" || terminate "Error while installing Splunk plugin."

  # init check
  fluentd_check $fluentd_as_service $user_install_fluentd_install_path

  # configure fluentd
  configure_fluentd $fluentd_as_service $install_as_docker "$user_install_fluentd_install_path" "$gem_command"

  echo
  print_green '================================================================================================================='
  print_green "Fluentd Splunk plugin configured!"
  echo
  print_green "Location of the fluentd conf file for Splunk conf file: $fluentd_conf_file_path"
  echo
  print_green "ALERT: To enable SSL please update 'use_ssl' and 'ca_file' in the
Fluentd Splunk configuration file: /etc/td-agent/fluent.conf.xray.

More information: https://github.com/jfrog/log-analytics-splunk"
  print_green '================================================================================================================='
}