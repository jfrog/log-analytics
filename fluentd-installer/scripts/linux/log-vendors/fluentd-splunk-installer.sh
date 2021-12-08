#!/bin/bash

# const
declare FLUENTD_SPLUNK_CONF_BASE_URL='https://raw.githubusercontent.com/jfrog/log-analytics-splunk/master'
declare TEMP_FOLDER='/tmp'
declare ERROR_MESSAGE='Error while installing/configuring Splunk.'

# load common script
# source ./utils/common.sh
load_remote_script "$SCRIPTS_URL_PATH/utils/common.sh" "common.sh"

intro() {
  ## Splunk - Fluentd Install Script
  declare logo=`cat ./other/spl_ascii_logo.txt`
  echo
  print_green "$logo"
  echo
  print_green 'The installation script for the Splunk plugin performs the following tasks:'
  print_green '- Configure Splunk for JFrog artifactory, xray, etc'
  print_green 'More info: https://github.com/jfrog/log-analytics-splunk'
  echo
  print_error "ALERT: Before continuing please complete the following steps:"
  echo
  print_green "1) Splunkbase App
  - Install the JFrog Log Analytics Platform app from Splunkbase - https://splunkbase.splunk.com/app/5023.
  - Restart Splunk post installation of App.
  - Login to Splunk after the restart completes.
  - Confirm the version is the latest version available in Splunkbase.
    more info: https://github.com/jfrog/log-analytics-splunk/blob/master/README.md#splunkbase-app

2) Configure Splunk
  - Create new index 'jfrog_splunk'
    more info: https://github.com/jfrog/log-analytics-splunk/blob/master/README.md#create-index-jfrog_splunk
  - Configure new HEC (HTTP Event Collector) token to receive Logs (use 'jfrog_splunk' index to store the JFrog platform log data into).
    more info: https://github.com/jfrog/log-analytics-splunk/blob/master/README.md#configure-new-hec-token-to-receive-logs"
  echo
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
  update_fluentd_config_file "$TEMP_FOLDER/$fluentd_splunk_conf_name" 'Provide IP or DNS of Splunk HEC: ' 'HEC_HOST' false $fluentd_as_service
  # configure HEC port
  update_fluentd_config_file "$TEMP_FOLDER/$fluentd_splunk_conf_name" 'Provide Splunk HEC port: ' 'HEC_PORT' false $fluentd_as_service
  # configure HEC token
  update_fluentd_config_file "$TEMP_FOLDER/$fluentd_splunk_conf_name" 'Provide Splunk HEC token value: ' 'HEC_TOKEN' true $fluentd_as_service
}

configure_fluentd() {
  declare fluentd_as_service=$1
  declare install_as_docker=$2
  declare user_install_fluentd_install_path=$3
  declare gem_command=$4

  # Downloading the fluentd config for Splunk based on the user input
  config_download_path_base="https://raw.githubusercontent.com/jfrog/log-analytics-splunk/master/"
  while true; do
    echo
    read -p 'Type of Splunk configuration: [Artifactory or Xray]: ' product_name
    case $product_name in
    [artifactory]*)
      jfrog_env_variables '/var/opt/jfrog/artifactory/' 'artifactory' $fluentd_as_service 'artifactory' $install_as_docker
      declare fluentd_splunk_conf_name='fluent.conf.rt'
      # shared splunk configuration questions
      shared_config_questions $fluentd_splunk_conf_name $fluentd_as_service
      break
      ;;
    [xray]*)
      jfrog_env_variables '/var/opt/jfrog/xray/' 'xray' $fluentd_as_service 'xray' $install_as_docker
      declare fluentd_splunk_conf_name='fluent.conf.xray'
      # shared splunk configuration questions
      shared_config_questions $fluentd_splunk_conf_name $fluentd_as_service
      # Xray related config questions
      xray_shared_questions "$TEMP_FOLDER" "$fluentd_splunk_conf_name" "$gem_command" "$fluentd_as_service" $install_as_docker
      break
      ;;
#    [nginx]*)
#      jfrog_env_variables '/var/opt/jfrog/artifactory/' 'artifactory'
#      declare fluentd_splunk_conf_name='fluent.conf.nginx'
#      download_fluentd_conf_file $fluentd_splunk_conf_name
#      break
#      ;;
#    [missioncontrol]*)
#      jfrog_env_variables '/var/opt/jfrog/xray/' 'mission Control' $fluentd_as_service
#      declare fluentd_splunk_conf_name='fluent.conf.missioncontrol'
#      # shared splunk configuration questions
#      shared_config_questions $fluentd_splunk_conf_name $fluentd_as_service
#      break
#      ;;
#    [distribution]*)
#      jfrog_env_variables '/var/opt/jfrog/distribution/' 'distribution' $fluentd_as_service
#      declare fluentd_splunk_conf_name='fluent.conf.distribution'
#      # shared splunk configuration questions
#      shared_config_questions $fluentd_splunk_conf_name $fluentd_as_service
#      break
#      ;;
#   [pipelines]*)
#     jfrog_env_variables '/opt/jfrog/pipelines/var/' 'pipelines' $fluentd_as_service
#      declare fluentd_splunk_conf_name='fluent.conf.pipelines'
#      # shared splunk configuration questions
#      shared_config_questions $fluentd_splunk_conf_name $fluentd_as_service
#      break
#      ;;
    *) echo 'Incorrect value, please try again. ' ;
    esac
  done

  # update Dockerfile if needed - fluentd conf file name
  if [ "$install_as_docker" == true ]; then
    run_command false "sed -i -e "s,FLUENT_CONF_FILE_NAME,$fluentd_splunk_conf_name,g" $DOCKERFILE_PATH"
  fi

  # finalizing configuration
  finalizing_configuration $install_as_docker $fluentd_as_service $fluentd_splunk_conf_name "$user_install_fluentd_install_path" || terminate $ERROR_MESSAGE
}

install_plugin() {
  declare fluentd_as_service=$1
  declare install_as_docker=$2
  declare user_install_fluentd_install_path=$3
  declare gem_command=$4

  #init script
  intro

  # install splunk plugin (VM or docker)
  declare fluentd_plugin_name=fluent-plugin-splunk-enterprise
  install_fluentd_plugin $fluentd_as_service $install_as_docker $fluentd_plugin_name "$gem_command" || terminate $ERROR_MESSAGE

  # configure fluentd
  configure_fluentd $fluentd_as_service $install_as_docker "$user_install_fluentd_install_path" "$gem_command" $install_as_docker || terminate $ERROR_MESSAGE

  # final message
  echo
  print_green "Fluentd Splunk plugin configured!"
  echo
  print_error "ALERT: To enable SSL please update 'use_ssl' and 'ca_file' in the Fluentd Splunk configuration file: $fluentd_conf_file_path"
  print_green 'More information: https://github.com/jfrog/log-analytics-splunk'
  echo
}
