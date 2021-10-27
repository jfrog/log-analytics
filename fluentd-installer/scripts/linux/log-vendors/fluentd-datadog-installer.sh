#!/bin/bash

# Fluents datadog script for JFrog products

# vars
FLUENTD_DATADOG_CONF_BASE_URL='https://raw.githubusercontent.com/jfrog/log-analytics-datadog/master'
ERROR_MESSAGE='Error while installing/configuring Datadog.'

# load the common script
if [ "$LOCAL_MODE" == true ]; then
  source ./utils/common.sh
else
  load_remote_script "$SCRIPTS_URL_PATH/utils/common.sh" "common.sh"
fi

# intro message
intro() {
  ## Datadog - Fluentd Install Script
  declare logo=`cat ./other/dd_ascii_logo.txt`
  echo
  print_green "$logo"
  echo
  echo 'The installation script for the Datadog plugin performs the following tasks:'
  echo '- Configure Datadog for JFrog artifactory, xray, etc'
  echo 'More info: https://github.com/jfrog/log-analytics-datadog'
  echo
}

# Configure fluentd datadog plugin based on the JFrog product
configure_fluentd() {
  declare fluentd_as_service=$1
  declare install_as_docker=$2
  declare user_install_fluentd_install_path=$3
  declare gem_command=$4

  # Downloading the fluentd config for Datadog based on the user input
  config_download_path_base="https://raw.githubusercontent.com/jfrog/log-analytics-datadog/master/"
  while true; do
    echo
    read -p 'Type of Datadog configuration: [Artifactory or Xray]: ' product_name
    case $product_name in
    [artifactory]*)
      jfrog_env_variables '/var/opt/jfrog/artifactory/' 'artifactory' $fluentd_as_service 'artifactory' $install_as_docker
      declare fluentd_datadog_conf_name='fluent.conf.rt'
      download_fluentd_conf_file  $FLUENTD_DATADOG_CONF_BASE_URL $fluentd_datadog_conf_name $TEMP_FOLDER
      # Update API key datadog
      update_fluentd_config_file "$TEMP_FOLDER/$fluentd_datadog_conf_name" 'Please provide Datadog API KEY (more info: https://docs.datadoghq.com/account_management/api-app-keys): ' 'API_KEY' true $fluentd_as_service
      break
      ;;
    [xray]*)
      jfrog_env_variables '/var/opt/jfrog/xray/' 'xray' $fluentd_as_service 'xray' $install_as_docker
      declare fluentd_datadog_conf_name='fluent.conf.xray'
      download_fluentd_conf_file $FLUENTD_DATADOG_CONF_BASE_URL $fluentd_datadog_conf_name $TEMP_FOLDER
      # Xray related config questions
      xray_shared_questions "$TEMP_FOLDER" "$fluentd_datadog_conf_name" "$gem_command" $fluentd_as_service $install_as_docker
      # Update API key datadog
      update_fluentd_config_file "$TEMP_FOLDER/$fluentd_datadog_conf_name" 'Please provide Datadog API KEY (more info: https://docs.datadoghq.com/account_management/api-app-keys): ' 'DATADOG_API_KEY' true $fluentd_as_service
      break
      ;;
    #[nginx]*)
    #  jfrog_env_variables '/var/opt/jfrog/artifactory/' 'artifactory'
    #  declare fluentd_datadog_conf_name='fluent.conf.nginx'
    #  download_fluentd_conf_file $fluentd_datadog_conf_name
    #  break
    #  ;;
    #[missioncontrol]*)
    #  jfrog_env_variables '/var/opt/jfrog/xray/' 'mission Control' $fluentd_as_service $install_as_docker
    #  declare fluentd_datadog_conf_name='fluent.conf.missioncontrol'
    #  download_fluentd_conf_file $FLUENTD_DATADOG_CONF_BASE_URL $fluentd_datadog_conf_name $TEMP_FOLDER
    #  break
    #  ;;
    #[distribution]*)
    #  jfrog_env_variables '/var/opt/jfrog/distribution/' 'distribution' $fluentd_as_service $install_as_docker
    #  declare fluentd_datadog_conf_name='fluent.conf.distribution'
    #  download_fluentd_conf_file $FLUENTD_DATADOG_CONF_BASE_URL $fluentd_datadog_conf_name $TEMP_FOLDER
    #  break
    #  ;;
    #[pipelines]*)
    # jfrog_env_variables '/opt/jfrog/pipelines/var/' 'pipelines' $fluentd_as_service
    #  declare fluentd_datadog_conf_name='fluent.conf.pipelines'
    #  download_fluentd_conf_file $FLUENTD_DATADOG_CONF_BASE_URL $fluentd_datadog_conf_name $TEMP_FOLDER
    #  break
    #  ;;
    *) echo 'Incorrect value, please try again. ' ;
    esac
  done

  # update Dockerfile if needed - fluentd conf file name
  if [ "$install_as_docker" == true ]; then
    run_command false "sed -i -e "s,FLUENT_CONF_FILE_NAME,$fluentd_datadog_conf_name,g" $DOCKERFILE_PATH"
  fi

  # finalizing configuration
  finalizing_configuration $install_as_docker $fluentd_as_service $fluentd_datadog_conf_name "$user_install_fluentd_install_path"
}

# init method (run it first)
install_plugin() {
  declare fluentd_as_service=$1
  declare install_as_docker=$2
  declare user_install_fluentd_install_path=$3
  declare gem_command=$4

  #init script
  intro

  # install datadog plugin (VM or docker)
  declare fluentd_plugin_name=fluent-plugin-datadog
  install_fluentd_plugin $fluentd_as_service $install_as_docker $fluentd_plugin_name "$gem_command" || terminate $ERROR_MESSAGE

  # configure fluentd
  configure_fluentd $fluentd_as_service $install_as_docker "$user_install_fluentd_install_path" "$gem_command" || terminate $ERROR_MESSAGE

  # summary message
  echo
  echo 'Datadog plugin installation summary:'
  if [ "$install_as_docker" == true ]; then
    echo "- The fluentd configuration will be added to the docker image."
  fi
  print_error '- ALERT: To use predefined Datadog Jfrog dashboards please do the following:'
  print_error '     1) Install Datadog JFrog integration integration: https://app.datadoghq.com/account/settings#integrations/jfrog-platform'
  print_error '     2) To add Datadog JFrog dashboards (Datadog portal) go to Dashboard -> Dashboard List, find JFrog Artifactory Dashboard, Artifactory Metrics, Xray Metrics, Xray Logs, Xray Violations and explore it.'
  echo '- More information: https://github.com/jfrog/log-analytics-datadog'
  print_green "Fluentd Datadog plugin configured!"
}
