#!/bin/bash

# const
declare FLUENTD_DATADOG_CONF_BASE_URL='https://raw.githubusercontent.com/jfrog/log-analytics-datadog/master'
declare TEMP_FOLDER='/tmp'

# load common functions
source ./utils/common.sh # TODO Update the path (git raw)

init() {
  ## Datadog - Fluentd Install Script
  help_link=https://github.com/jfrog/log-analytics-datadog
  echo
  print_green "============================================================================================================"
  print_green 'Installing and configuring Datadog plugin for fluentd.'
  print_green 'The installation script performs the following tasks:'
  print_green '- Configure Datadog for JFrog artifactory, xray, etc'
  echo
  print_green "More information: $help_link"
  print_green "============================================================================================================"
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
      # required: JPD_URL is the Artifactory JPD URL of the format http://<ip_address> with is used to pull Xray Violations
      update_fluentd_config_file "$TEMP_FOLDER/$fluentd_datadog_conf_name" "Provide JFrog URL (more info: https://www.jfrog.com/confluence/display/JFROG/General+System+Settings): " 'JPD_URL' false $fluentd_as_service
      # required: USER is the Artifactory username for authentication
      update_fluentd_config_file "$TEMP_FOLDER/$fluentd_datadog_conf_name" 'Provide the Artifactory username for authentication (more info: https://www.jfrog.com/confluence/display/JFROG/Users+and+Groups): ' 'USER' false $fluentd_as_service
      # required: JFROG_API_KEY is the Artifactory API Key for authentication
      update_fluentd_config_file "$TEMP_FOLDER/$fluentd_datadog_conf_name" 'Provide the Artifactory API Key for authentication (more info: https://www.jfrog.com/confluence/display/JFROG/User+Profile#UserProfile-APIKey): ' 'JFROG_API_KEY' true $fluentd_as_service
      # install SIEM plugin
      echo
      install_custom_plugin 'SIEM' "$gem_command" "$fluentd_as_service"
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
  init

  # install datadog fluentd plugin
  declare install_datadog_command="$gem_command install fluent-plugin-datadog"

    echo ">>>>>> install_datadog_command=$install_datadog_command"
    echo ">>>>>> gem_command=$gem_command"
    echo ">>>>>> fluentd_as_service=$fluentd_as_service"

  run_command $fluentd_as_service "$install_datadog_command" || terminate "Error while installing Datadog plugin."

  declare help_link=https://github.com/jfrog/log-analytics-datadog

  # init check
  fluentd_check $fluentd_as_service $user_install_fluentd_install_path

  # configure fluentd
  configure_fluentd "$fluentd_as_service" "$user_install_fluentd_install_path" "$gem_command"

  echo
  print_green '=============================================================================='
  if [ $fluentd_as_service = true ]; then
    print_green "Location of fluentd Datadog conf file $fluentd_conf_file_path"
  else
    print_green "To manually start fluentd with the Datadog conf run the following command: $user_install_fluentd_install_path/fluentd $fluentd_conf_file_path"
    print_green "Datadog installation completed. Please make sure fluentd has read/write access to the log folder: '$user_product_path/log'. In some cases it's necessary to reload the environment or logout $USER user before starting fluentd."
    print_green "More info: $help_link"
  fi
  print_green '=============================================================================='
}
