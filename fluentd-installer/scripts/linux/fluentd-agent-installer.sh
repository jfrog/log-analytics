#!/bin/bash

# branch
GITHUB_BRANCH="karolh2000/plugin-installers"
DOCKERFILE_PATH="./Dockerfile"
DOCKER_IMAGE_TAG="jfrog/fluentd"
# load conf file
declare SCRIPT_PROPERTIES_FILE_PATH="./properties.conf"
# load common functions
source ./utils/common.sh # TODO Update the path (git raw)

intro() {
  declare logo=`cat ./other/jfrog_ascii_logo.txt`
  help_link=https://github.com/jfrog/log-analytics
  echo
  print_green "$logo"
  echo
  print_green "================================================================================================================="
  echo
  print_green 'JFrog fluentd installation script (Splunk, Datadog).'
  echo
  print_green 'The script installs fluentd and performs the following tasks:'
  print_green '- Checks if the Fluentd requirements are met and updates the OS if needed [optional].'
  print_green '- Installs/Updates Fluentd as a service or in the user space depending on Linux distro.[optional]'
  print_green '- Creates (builds) Fluentd docker image. [optional]'
  print_green '- Updates the log files/folders permissions [optional].'
  print_green '- Installs Fluentd plugins (Splunk, Datadog) [optional].'
  print_green '- Starts and enables the Fluentd service [optional].'
  print_green '- Provides additional info related to the installed plugins.'
  echo
  print_green "More information: $help_link"
  print_green "================================================================================================================="
  print_green *EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*EXPERIMENTAL*
  print_green "================================================================================================================="
  echo

  # Experimental warning
  declare experiments_warning=$(question "The installer is still in the EXPERIMENTAL phase (might be unstable). Would you like to continue? [y/n]: ")
  if [ "$experiments_warning" == false ]; then
    echo Have a nice day! Good Bye!
    exit 0
  fi
}

# Modify conf file
modify_conf_file() {
  declare now_date=$(date +"%m_%d_%Y_%H_%M_%S")
  declare backup_postfix="_la_backup_$now_date"
  # backup modifying file first
  declare file_path=$1
  declare file_path_backup="${file_path}${backup_postfix}"
  declare conf_content=$2
  declare run_as_sudo=$3
  run_command "$run_as_sudo" "cp ${file_path} ${file_path_backup}" || terminate "Error while creating backup copy, original file: ${file_path}, backup file: ${file_path_backup}."
  echo "Modifying ${file_path}..."
  echo "$conf_content" | run_command "$run_as_sudo" "tee -a ${file_path}"
  echo "File ${file_path} modified and the original content backed up to ${file_path_backup}"
}

load_remote_script() {
  script_url=$1
  # check url
  curl -L -f "$script_url" || error_script=true
  if [ $error_script == true ]; then
    echo "ERROR: Error while downloading ${script_url}. Exiting..."
    exit 1
  fi
  # run script
  curl -L -f "$script_url" | sh
}

install_fluentd() {
  declare install_as_service=$1
  # supported linux distros
  declare supported_distros=("centos" "amazon")

  # Check distro
  detected_distro=$(cat /etc/*-release | tr [:upper:] [:lower:] | grep -Poi '(centos|ubuntu|red hat|amazon|debian)' | uniq)
  supported_distros=("centos" "amazon")
  is_supported_distro=false
  for supported_distro in "${supported_distros[@]}"; do
    if [[ $detected_distro == $supported_distro ]]; then
      is_supported_distro=true
      break
    fi
  done

  if [ "$is_supported_distro" == false ]; then
    echo "Linux distro '${detected_distro}' is not supported. Fluentd was NOT installed. Exiting..."
    exit 0
  fi

  # Check the Fluentd requirements (file descriptors, etc)
  declare ulimit_output=$(ulimit -n)
  if [ $ulimit_output -lt 65536 ]; then
    # Update the file descriptors limit per process and 'high load environments' if needed
    echo
    declare update_limit=$(question "Fluentd requires higher limit of the file descriptors per process and the network kernel parameters adjustment (more info: https://docs.fluentd.org/installation/before-install). Would you like to update the mentioned configuration (optional and sudo rights required)? [y/n]: ")
    if [ "$update_limit" == true ]; then
      limit_conf_file_path=/etc/security/limits.conf
      limit_config="
  # Added by JFrog log-analytics install script
  root soft nofile 65536
  root hard nofile 65536
  * soft nofile 65536
  * hard nofile 65536"
      modify_conf_file $limit_conf_file_path "$limit_config" true
      nkp_path_file=/etc/sysctl.conf
      nkp_config="
  # Added by JFrog log-analytics install script
  net.core.somaxconn = 1024
  net.core.netdev_max_backlog = 5000
  net.core.rmem_max = 16777216
  net.core.wmem_max = 16777216
  net.ipv4.tcp_wmem = 4096 12582912 16777216
  net.ipv4.tcp_rmem = 4096 12582912 16777216
  net.ipv4.tcp_max_syn_backlog = 8096
  net.ipv4.tcp_slow_start_after_idle = 0
  net.ipv4.tcp_tw_reuse = 1
  net.ipv4.ip_local_port_range = 10240 65535"
      modify_conf_file $nkp_path_file "$nkp_config" true
    fi
  fi

  # We support two ways of installing td-agent4 and user/zip.
  # Install as service or in the user space
  if [ "$install_as_service" == true ]; then
    # Fetches and installs td-agent4 (for now only Centos and Amazon distros supported)
    if [ "$detected_distro" == "centos" ]; then
      error_message="ERROR: td-agent 4 installation failed. Fluentd was NOT installed. Exiting..."
      echo "Centos detected. Installing td-agent 4..."
      {
        load_remote_script "https://toolbelt.treasuredata.com/sh/install-redhat-td-agent4.sh"
      } || {
        terminate "$error_message"
      }
    elif [ "$detected_distro" == "amazon" ]; then
      echo "Amazon Linux detected. Installing td-agent 4..."
      {
        load_remote_script "https://toolbelt.treasuredata.com/sh/install-amazon2-td-agent4.sh"
      } || {
        terminate "$error_message"
      }
    else
      terminate "Unsupported linux distro: $detected_distro"
    fi
  else
    current_path=$(pwd)
    declare fluentd_file_name="fluentd-1.11.0-linux-x86_64.tar.gz"
    declare fluentd_zip_install_default_path="$HOME/fluentd"
    echo
    read -p "Please provide a path where Fluentd will be installed, (default: $fluentd_zip_install_default_path): " user_fluentd_install_path

    # check if the path is empty, if empty then use fluentd_zip_install_default_path
    if [ -z "$user_fluentd_install_path" ]; then
      user_fluentd_install_path="$fluentd_zip_install_default_path"
    fi
    # create folder if not present
    echo Create $user_fluentd_install_path
    mkdir -p "$user_fluentd_install_path"
    # check if user has write permissions in the specified path
    if ! [ -w "$user_fluentd_install_path" ]; then
      terminate "ERROR: Write permission denied in ${user_fluentd_install_path}. Please make sure that you have read/write permissions in ${user_fluentd_install_path}. Fluentd was NOT installed. Exiting..."
    fi
    # cd to the specified folder
    # cd "$user_fluentd_install_path"
    # download and extract
    declare zip_file="$user_fluentd_install_path/$fluentd_file_name"
    wget -O "$zip_file" https://github.com/jfrog/log-analytics/raw/${GITHUB_BRANCH}/fluentd-installer/${fluentd_file_name}
    echo "Please wait, extracting $fluentd_file_name to $user_fluentd_install_path"
    tar -xf "$zip_file" -C "$user_fluentd_install_path" --strip-components 1
    # clean up
    rm "$zip_file"
    # cd $current_path
    echo "Fluentd files extracted to: $user_fluentd_install_path"
    echo
  fi
}

install_log_vendor() {
  declare install_as_service=$1
  # Install log vendors (splunk, datadog etc)
  declare config_link=$help_link
  declare install_log_vendors=$(question "Would you like to install Fluentd log vendors (optional)? [y/n]: ")

  # check if gem/td-agent-gem is installed
  if [ "$install_as_docker" == false ]; then
    if [ -x "$(command -v td-agent-gem)" ] && [ $install_as_service == true ]; then
      gem_command="sudo td-agent-gem"
    elif [ -x "$(command -v ${user_fluentd_install_path}/lib/ruby/bin/gem -v)" ]; then
      gem_command="$user_fluentd_install_path/lib/ruby/bin/gem"
    else
      terminate "WARNING: Ruby 'gem' or 'td-agent-gem' is required and was not found, please make sure that at least one of the mentioned frameworks is installed. Fluentd log vendors installation aborted."
    fi
  fi

  if [ "$install_log_vendors" == true ]; then
    while true; do
      echo
      read -p "What log vendor would you like to install [Splunk or Datadog]: " log_vendor_name
      log_vendor_name=${log_vendor_name,,}

      case $log_vendor_name in
      [splunk]*)
        log_vendor_name=splunk
        source ./log-vendors/fluentd-splunk-installer.sh # TODO Update the path (git raw)
        install_plugin $install_as_service $install_as_docker "$user_fluentd_install_path" "$gem_command" || terminate "Error while installing Splunk plugin."
        break
        ;;
      [datadog]*)
        log_vendor_name=datadog
        source ./log-vendors/fluentd-datadog-installer.sh # TODO Update the path (git raw)
        install_plugin $install_as_service $install_as_docker "$user_fluentd_install_path" "$gem_command" || terminate "Error while installing Datadog plugin."
        break
        ;;
      #[elastic]*)
      #  log_vendor_name=elastic
      #  echo Installing fluent-plugin-elasticsearch...
      #  $gem_command install fluent-plugin-elasticsearch
      #  help_link=https://github.com/jfrog/log-analytics-elastic
      #  break
      #  ;;
      #[prometheus]*)
      #  log_vendor_name=prometheus
      #  echo Installing fluent-plugin-prometheus...
      #  $gem_command install fluent-plugin-prometheus
      #  help_link=https://github.com/jfrog/log-analytics-prometheus
      #  break
      #  ;;
      *)
      echo "Please answer: Splunk or Datadog" ;
      esac
    done
  else
    echo "Skipping the log vendor installation."
  fi
}

start_enable_fluentd() {
  declare install_as_service=$1

  # Start/enable/status td-agent service
  if [ "$install_as_service" == true ]; then
    # enable and start fluentd service, this part is only available if Fluentd was installed as service in the previous steps
    echo
    declare start_enable_service=$(question "Would you like to start and enable Fluentd service (td-agent4, optional)? [y/n]: ")
    declare fluentd_service_name="td-agent"
    if [ "$start_enable_service" == true ]; then
      echo Starting and enabling td-agent service...
      if [[ $(systemctl) =~ -\.mount ]]; then
        sudo systemctl daemon-reload
        sudo systemctl enable ${fluentd_service_name}.service
        sudo systemctl restart ${fluentd_service_name}.service
        sudo systemctl status ${fluentd_service_name}.service
      else
        sudo chkconfig ${fluentd_service_name} on
        sudo /etc/init.d/${fluentd_service_name} restart
        sudo /etc/init.d/${fluentd_service_name} status
      fi
    fi
  else
    echo
    if [ "$start_enable_service" == true ]; then
      declare start_enable_tar_install=$(question "Would you like to start and enable Fluentd as service (systemctl required, optional)? [y/n]: ")
    fi
    if ! [[ $(systemctl) =~ -\.mount ]]; then
      echo "WARNING: The 'systemctl' command not found, the files needed to start Fluentd as service won't be created."
    elif [ "$start_enable_tar_install" == true ]; then
      echo Creating files needed for the Fluentd service...
      mkdir -p "$HOME"/.config/systemd/user/
      fluentd_service_name='jfrogfluentd'
      declare user_install_fluentd_service_conf_file="$HOME"/.config/systemd/user/${fluentd_service_name}.service
      touch "$user_install_fluentd_service_conf_file"
      echo "# Added by JFrog log-analytics install script
  [Unit]
  Description=JFrog_Fluentd

  [Service]
  ExecStart=${user_install_fluentd_path}/fluentd ${user_install_fluentd_path}/test.conf
  Restart=always

  [Install]
  WantedBy=graphical.target" >"$user_install_fluentd_service_conf_file"
      echo Starting and enabling td-agent service...
      {
      systemctl --user enable ${user_install_fluentd_service_conf_file}
      systemctl --user restart ${fluentd_service_name}
      } || {
        echo
        print_error "ALERT: Enabling the fluentd service wasn't successful, for additional info please check the errors above."
        print_error "You can still start Fluentd manually with the following command: '$user_fluentd_install_path/fluentd $fluentd_conf_file_path'"
      }
    fi
  fi

  if [[ -z $(ps aux | grep fluentd | grep -v "grep") ]]; then
    fluentd_service_msg="ALERT: Service ${fluentd_service_name} not found. Fluentd is not available as service."
  else
    if [ "$install_as_service" == true ]; then
      service_based_message="/etc/td-agent/td-agent.conf.
To manage the Fluentd as service (td-agent) please use 'service' or 'systemctl' command."
    else
      service_based_message="$fluentd_conf_file_path.
To manually start Fluentd use the following command: '$user_fluentd_install_path/fluentd $fluentd_conf_file_path'."
    fi
    fluentd_service_msg="To change the Fluentd configuration please update: '$service_based_message'"
  fi
}

build_docker_image() {
  echo
  declare docker_default_image_tag=$DOCKER_IMAGE_TAG/$log_vendor_name
  read -p "Please provide docker image tag (default: $docker_default_image_tag): " docker_image_tag
  if [ -z "$docker_image_tag" ]; then
    docker_image_tag=$docker_default_image_tag
  fi
  echo
  echo "Building docker image based on the provided information..."
  echo
  docker build -t $docker_image_tag ./ || terminate "Docker image creation failed."
  echo
  echo "Docker image created, tag: '$docker_image_tag' "
  echo
  echo "Docker image info:"
  docker image ls | grep $docker_image_tag
  echo
  fluentd_service_msg="Docker image info:
$(docker image ls | grep $docker_image_tag)
"
}

run_docker_image() {
  jf_log_mounting_path=$1
  echo
  while true; do
    read -p 'Please provide docker container name: ' docker_container_name
    echo "Provided name: $docker_container_name"
      if [ -z "$docker_container_name" ]; then
        echo "Incorrect docker container name, please try it again."
      else
        break
      fi
  done
  declare docker_start_command="docker run -d -it --name $docker_container_name --mount type=bind,source=$jf_log_mounting_path,target=$jf_log_mounting_path $docker_image_tag:latest"
  echo
  echo "Starting docker container..."
  {
    eval "$docker_start_command"
    docker ps -all | grep $docker_container_name
  } || print_error "Starting docker image '$DOCKER_IMAGE_TAG' failed, please resolve the problem and run it manually using the following command: '$docker_start_command'"
  fluentd_service_msg="$fluentd_service_msg
Docker container info:
$(docker ps -all | grep $docker_container_name)

Docker run command:
$docker_start_command"
}


## Fluentd Install Script
# Init
intro

while true; do
  echo
  read -p "Would you like to install Fluentd as SERVICE, in the USER space or build DOCKER image? [service/user/docker]
          [service] - Fluentd will be installed as service on this machine (sudo rights required).
          [user]    - Fluentd will be installed in a folder specified in the next step.
          [docker]  - Custom Docker image will built based on the latest fluentd image and user input.
[service/user/docker]: " install_type
  install_type=${install_type,,}

  case $install_type in
    [service]*)
      declare install_as_service=true
      declare install_as_docker=false
      echo "Installation type: SERVICE, Fluentd will be installed as service."
      break
      ;;
    [user]*)
      declare install_as_service=false
      declare install_as_docker=false
      echo "Installation type: USER, Fluentd will be installed in a folder specified in the next step."
      break
      ;;
    [docker]*)
      declare install_as_service=false
      declare install_as_docker=true
      echo "Installation type: DOCKER, Custom Docker image will be built based on the latest fluentd image and user input"
      break
      ;;
  *)
  echo "Please answer: service, user or docker."
  esac
done
echo

if [ "$install_as_docker" == false ]; then
  # install fluentd
  install_fluentd $install_as_service
else
  # check if docker is running/present
  {
    echo "Checking if docker is installed..."
    echo
    docker ps -q
  } || {
    terminate "Docker is not running or not installed, please fix the problem before running the script again."
  }
  echo
  echo "Docker is present and running!"
  echo
fi

install_log_vendor $install_as_service

# Enable/start Fluentd, only for non docker options.
if [ "$install_as_docker" == false ]; then
  start_enable_fluentd $install_as_service
else
  # build docker image
  build_docker_image
  declare run_docker_image=$(question "Would you like to create and run container for $docker_image_tag:latest? [y/n]: ")
  if [ "$run_docker_image" == true ]; then
    run_docker_image $user_product_path
  fi
fi

echo
print_green ==============================================================================================
print_green 'Fluentd installation completed!'
echo
print_green "$fluentd_service_msg"
echo
print_green "Additional information related to the JFrog log analytics: https://github.com/jfrog/log-analytics"
print_green ==============================================================================================
# Fin!
