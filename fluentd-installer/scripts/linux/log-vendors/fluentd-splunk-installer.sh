#!/bin/bash

# const
declare FLUENTD_SPLUNK_CONF_BASE_URL='https://raw.githubusercontent.com/jfrog/log-analytics-splunk/master'
declare TEMP_FOLDER='/tmp'

# load common functions
source ./utils/common.sh # TODO Update the path (git raw)

init() {
  ## Splunk - Fluentd Install Script
  help_link=https://github.com/jfrog/log-analytics-splunk
  echo
  print_green "============================================================================================================"
  print_green 'Installing and configuring Splunk plugin for fluentd.'
  print_green 'The installation script performs the following tasks:'
  print_green '- Configure Splunk for JFrog artifactory, xray, etc'
  echo
  print_green "More information: $help_link"
  echo
  print_green "ALERT! Before continuing please complete the following manual steps:
-------------------------------------------------------------------
Splunkbase App (more info: https://github.com/jfrog/log-analytics-splunk#splunkbase-app)
  - Install the JFrog Log Analytics Platform app from Splunkbase - https://splunkbase.splunk.com/app/5023.
  - Restart Splunk post installation of App.
  - Login to Splunk after the restart completes.
  - Confirm the version is the latest version available in Splunkbase.

Configure Splunk (more info: https://github.com/jfrog/log-analytics-splunk#configure-splunk)
  - Create new index 'jfrog_splunk'.
  - Configure new HEC token to receive Logs (use 'jfrog_splunk' index to store the JFrog platform log data into)."
  print_green "============================================================================================================"

  init_steps=$(question "Are you ready to continue? [y/n]: ")
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
  if [ $fluentd_as_service = true ]; then
    copy_fluentd_conf '/etc/td-agent' "$fluentd_splunk_conf_name" true "$TEMP_FOLDER"
    configuration_file="/etc/td-agent/$fluentd_splunk_conf_name"
  else
    copy_fluentd_conf "$user_install_fluentd_install_path" "$fluentd_splunk_conf_name" true "$TEMP_FOLDER"
    configuration_file="$user_install_fluentd_install_path/$fluentd_splunk_conf_name"
  fi
  echo
  echo "WARNING: To enable SSL please update 'use_ssl' and 'ca_file' in the splunk fluentd configuration file: $configuration_file. More information: https://github.com/jfrog/log-analytics-splunk#fluentd-configuration-for-splunk"
  echo
}

install_plugin() {
  declare fluentd_as_service=$1
  declare user_install_fluentd_install_path=$2
  declare gem_command=$3

  #init script
  init

  # install splunk fluentd plugin
  declare install_splunk_command="$gem_command install fluent-plugin-splunk-enterprise"

  run_command $fluentd_as_service "$install_splunk_command" || terminate "Error while installing Splunk plugin."

  declare help_link=https://github.com/jfrog/log-analytics-splunk

  # init check
  fluentd_check $fluentd_as_service $user_install_fluentd_install_path

  # configure fluentd
  configure_fluentd "$fluentd_as_service" "$user_install_fluentd_install_path" "$gem_command"

  echo
  print_green '=============================================================================='
  if [ $fluentd_as_service = true ]; then
    print_green "Location of the fluentd conf file for Splunk conf file: $fluentd_conf_file_path"
  else
    print_green "To manually start fluentd with the Splunk conf run the following command: $user_install_fluentd_install_path/fluentd $fluentd_conf_file_path"
    print_green "Please make sure fluentd has read/write access to the log folder: '$user_product_path/log'. In some cases it's necessary to reload the environment or logout $USER user before starting fluentd."
    print_green "Location of the fluentd conf file for Splunk conf file: $fluentd_conf_file_path"
  fi
  print_green "JFrog Splunk log analytics help: $help_link"
  print_green 'WARNING: To enable SSL please update 'use_ssl' and 'ca_file' in the splunk fluentd configuration file: /etc/td-agent/fluent.conf.xray. More information: https://github.com/jfrog/log-analytics-splunk#fluentd-configuration-for-splunk'
  print_green '=============================================================================='
}
