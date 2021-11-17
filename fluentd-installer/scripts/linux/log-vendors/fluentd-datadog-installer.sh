#!/bin/bash

# const
declare FLUENTD_DATADOG_CONF_BASE_URL='https://raw.githubusercontent.com/jfrog/log-analytics-datadog/master'
declare TEMP_FOLDER='/tmp'

# load common functions
source ./utils/common.sh # TODO Update the path (git raw)

intro() {
  ## Datadog - Fluentd Install Script
  declare logo=`cat ./other/dd_ascii_logo.txt`
  echo
  print_green "$logo"
  echo
  print_green "================================================================================================================="
  print_green 'Installing and configuring Datadog plugin for fluentd.'
  print_green 'The installation script performs the following tasks:'
  print_green '- Configure Datadog for JFrog artifactory, xray, etc'
  print_green 'More info: https://github.com/jfrog/log-analytics-datadog'
  print_green "================================================================================================================="
  echo
}

configure_fluentd() {
  declare fluentd_as_service=$1
  declare user_install_fluentd_install_path=$2
  declare gem_command=$3

  # Downloading the fluentd config for Datadog based on the user input
  config_download_path_base="https://raw.githubusercontent.com/jfrog/log-analytics-datadog/master/"
  while true; do
    echo
    read -p 'Type of Datadog configuration: [Artifactory, Xray, Missioncontrol, Distribution or Pipelines]: ' product_name
    case $product_name in
    [artifactory]*)
      jfrog_env_variables '/var/opt/jfrog/artifactory/' 'artifactory' $fluentd_as_service 'artifactory'
      declare fluentd_datadog_conf_name='fluent.conf.rt'
      download_fluentd_conf_file  $FLUENTD_DATADOG_CONF_BASE_URL $fluentd_datadog_conf_name $TEMP_FOLDER
      break
      ;;
    [xray]*)
      jfrog_env_variables '/var/opt/jfrog/xray/' 'xray' $fluentd_as_service 'xray'
      declare fluentd_datadog_conf_name='fluent.conf.xray'
      download_fluentd_conf_file $FLUENTD_DATADOG_CONF_BASE_URL $fluentd_datadog_conf_name $TEMP_FOLDER
      # Xray related config questions
      xray_shared_questions "$TEMP_FOLDER" "$fluentd_datadog_conf_name" "$gem_command" "$fluentd_as_service"
      break
      ;;
    #[nginx]*)
    #  jfrog_env_variables '/var/opt/jfrog/artifactory/' 'artifactory'
    #  declare fluentd_datadog_conf_name='fluent.conf.nginx'
    #  download_fluentd_conf_file $fluentd_datadog_conf_name
    #  break
    #  ;;
    [missioncontrol]*)
      jfrog_env_variables '/var/opt/jfrog/xray/' 'mission Control' $fluentd_as_service
      declare fluentd_datadog_conf_name='fluent.conf.missioncontrol'
      download_fluentd_conf_file $FLUENTD_DATADOG_CONF_BASE_URL $fluentd_datadog_conf_name $TEMP_FOLDER
      break
      ;;
    [distribution]*)
      jfrog_env_variables '/var/opt/jfrog/distribution/' 'distribution' $fluentd_as_service
      declare fluentd_datadog_conf_name='fluent.conf.distribution'
      download_fluentd_conf_file $FLUENTD_DATADOG_CONF_BASE_URL $fluentd_datadog_conf_name $TEMP_FOLDER
      break
      ;;
   [pipelines]*)
     jfrog_env_variables '/opt/jfrog/pipelines/var/' 'pipelines' $fluentd_as_service
      declare fluentd_datadog_conf_name='fluent.conf.pipelines'
      download_fluentd_conf_file $FLUENTD_DATADOG_CONF_BASE_URL $fluentd_datadog_conf_name $TEMP_FOLDER
      break
      ;;
    *) echo 'Incorrect value, please try again. ' ;
    esac
  done

  # Update API key datadog
  update_fluentd_config_file "$TEMP_FOLDER/$fluentd_datadog_conf_name" 'Please provide Datadog API KEY (more info: https://docs.datadoghq.com/account_management/api-app-keys): ' 'API_KEY' true $fluentd_as_service

  # finalizing configuration
  if [ $fluentd_as_service = true ]; then
    copy_fluentd_conf '/etc/td-agent' "$fluentd_datadog_conf_name" true "$TEMP_FOLDER"
  else
    copy_fluentd_conf "$user_install_fluentd_install_path" "$fluentd_datadog_conf_name" true "$TEMP_FOLDER"
  fi
}

install_plugin() {
  declare fluentd_as_service=$1
  declare user_install_fluentd_install_path=$2
  declare gem_command=$3

  #init script
  intro

  # install datadog fluentd plugin
  declare install_datadog_command="$gem_command install fluent-plugin-datadog"

  run_command $fluentd_as_service "$install_datadog_command" || terminate "Error while installing Datadog plugin."

  declare help_link=https://github.com/jfrog/log-analytics-datadog

  # init check
  fluentd_check $fluentd_as_service $user_install_fluentd_install_path

  # configure fluentd
  configure_fluentd "$fluentd_as_service" "$user_install_fluentd_install_path" "$gem_command"

  echo
  print_green '=============================================================================='
  print_green "Fluentd Datadog plugin configured."
  echo
  print_green "Location of the fluentd conf file for Splunk conf file: $fluentd_conf_file_path"
  echo
  if [ $fluentd_as_service = false ]; then
    print_green "To manually start fluentd with the Datadog conf run the following command:
$user_install_fluentd_install_path/fluentd $fluentd_conf_file_path"
  echo
    print_green "Please make sure fluentd has read/write access to the log folder: '$user_product_path/log'.
In some cases it's necessary to reload the environment or logout $USER user before starting fluentd."
    echo
    print_green "Location of the fluentd conf file for Datadog conf file: $fluentd_conf_file_path"
  fi
  echo
  print_green "More information: https://github.com/jfrog/log-analytics-datadog"
  print_green '=============================================================================='
}
