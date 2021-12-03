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
  print_green "--------------------------------------------------------------------------------------------------------"
  print_green 'Installing and configuring Datadog plugin for fluentd.'
  print_green 'The installation script performs the following tasks:'
  print_green '- Configure Datadog for JFrog artifactory, xray, etc'
  print_green 'More info: https://github.com/jfrog/log-analytics-datadog'
  print_green "--------------------------------------------------------------------------------------------------------"
  echo
}

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
      break
      ;;
    [xray]*)
      jfrog_env_variables '/var/opt/jfrog/xray/' 'xray' $fluentd_as_service 'xray' $install_as_docker
      declare fluentd_datadog_conf_name='fluent.conf.xray'
      download_fluentd_conf_file $FLUENTD_DATADOG_CONF_BASE_URL $fluentd_datadog_conf_name $TEMP_FOLDER
      # Xray related config questions
      xray_shared_questions "$TEMP_FOLDER" "$fluentd_datadog_conf_name" "$gem_command" $fluentd_as_service $install_as_docker
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
  # update dockerfile - fluentd conf file name
  run_command false "sed -i -e "s,FLUENT_CONF_FILE_NAME,$fluentd_datadog_conf_name,g" $DOCKERFILE_PATH"

  # Update API key datadog
  update_fluentd_config_file "$TEMP_FOLDER/$fluentd_datadog_conf_name" 'Please provide Datadog API KEY (more info: https://docs.datadoghq.com/account_management/api-app-keys): ' 'API_KEY' true $fluentd_as_service

  # finalizing configuration
  if [ "$install_as_docker" == false ]; then
    if [ $fluentd_as_service == true ]; then
      copy_fluentd_conf '/etc/td-agent' "$fluentd_datadog_conf_name" $fluentd_as_service $install_as_docker "$TEMP_FOLDER"
    else
      copy_fluentd_conf "$user_install_fluentd_install_path" "$fluentd_datadog_conf_name" $fluentd_as_service $install_as_docker "$TEMP_FOLDER"
    fi
  else
    copy_fluentd_conf "$user_install_fluentd_install_path" "$fluentd_datadog_conf_name" $fluentd_as_service $install_as_docker "$TEMP_FOLDER"
  fi
}

install_plugin() {
  declare fluentd_as_service=$1
  declare install_as_docker=$2
  declare user_install_fluentd_install_path=$3
  declare gem_command=$4

  #init script
  intro

  # install datadog fluentd plugin or modify Dockerfile
  if [ "$install_as_docker" == false ]; then
    declare install_datadog_command="$gem_command install fluent-plugin-datadog"
    # fluentd check
    fluentd_check $fluentd_as_service $user_install_fluentd_install_path
    # install fluentd datadog plugin
    run_command $fluentd_as_service "$install_datadog_command" || terminate "Error while installing Datadog plugin."
  else
    # download dockerfile template
    download_dockerfile_template
    # add datadog plugin install command to the dockerfile
    echo "RUN fluent-gem install fluent-plugin-datadog" >> "$DOCKERFILE_PATH"
  fi

  declare help_link=https://github.com/jfrog/log-analytics-datadog

  # configure fluentd
  configure_fluentd $fluentd_as_service $install_as_docker "$user_install_fluentd_install_path" "$gem_command"

  echo
  print_green '--------------------------------------------------------------------------------------------------------'
  print_green "Fluentd Datadog plugin configured."
  if [ "$install_as_docker" == false ]; then
    echo
    print_green "Location of the fluentd conf file for conf file: '$fluentd_conf_file_path'"
    echo
    if [ $fluentd_as_service == false ]; then
      print_green "To manually start fluentd with the Datadog conf run the following command:
$user_install_fluentd_install_path/fluentd $fluentd_conf_file_path"
    echo
    print_green "Please make sure fluentd has read/write access to the log folder: '$user_product_path/log'.
In some cases it's necessary to reload the environment for '$USER' user before starting fluentd."
    fi
  else
    echo
    print_green "The fluentd configuration will be added to the docker image."
  fi
  echo
  print_error 'ALERT: To use predefined Datadog Jfrog dashboards please do the following:'
  print_green '1) Install Datadog JFrog integration integration: https://app.datadoghq.com/account/settings#integrations/jfrog-platform'
  print_green '2) To add Datadog JFrog dashboards (Datadog portal) go to Dashboard -> Dashboard List, find JFrog Artifactory Dashboard,
   Artifactory Metrics, Xray Metrics, Xray Logs, Xray Violations and explore it.'
  echo
  print_green 'More information: https://github.com/jfrog/log-analytics-datadog'
  print_green '--------------------------------------------------------------------------------------------------------'
}
