#!/bin/bash

# branch
GITHUB_BRANCH=master

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
  print_green 'JFrog fluentd installation script (Splunk, Datadog, Prometheus, Elastic).'
  echo
  print_green 'The script installs fluentd and performs the following tasks:'
  print_green '- Checks if the Fluentd requirements are met and updates the OS if needed [optional].'
  print_green '- Installs/Updates Fluentd as a service or in user space depending on Linux distro (Centos and Amazon is supported, more to come).'
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
  # in case that the properties script exists don't interact with the user, use the properties from the file
  interactive=true
  if test -f "$SCRIPT_PROPERTIES_FILE_PATH"; then
    if [ "$EUID" -ne 0 ]; then
      terminate "In the headless mode (non interactive) this script has to be executed as sudo."
    fi
    interactive=false
    echo "interactive=$interactive"
    source "$SCRIPT_PROPERTIES_FILE_PATH"
  else
    echo "The script properties file not found in $SCRIPT_PROPERTIES_FILE_PATH, the script will continue in the interactive mode (user input)."
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

## Fluentd Install Script

#Init info
intro

# const
supported_distros=("centos" "amazon")

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

# Experimental warning
if [ "$interactive" == true ]; then
  declare experiments_warning=$(question "The installer is still in the EXPERIMENTAL phase (might be unstable). Would you like to continue? [y/n]: ")
  if [ "$experiments_warning" == false ]; then
    echo Have a nice day! Good Bye!
    exit 0
  fi
fi

# Check the Fluentd requirements (file descriptors, etc)
ulimit_output=$(ulimit -n)
if [ $ulimit_output -lt 65536 ]; then
  # Update the file descriptors limit per process and 'high load environments' if needed
  echo
  if [ "$interactive" == true ];then
    declare update_limit=$(question "Fluentd requires higher limit of the file descriptors per process and the network kernel parameters adjustment (more info: https://docs.fluentd.org/installation/before-install). Would you like to update the mentioned configuration (optional and sudo rights required)? [y/n]: ")
  fi
  if [ "$update_limit" == true ] || [ "$UPDATE_LIMIT" == true ]; then
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
echo
if [ "$interactive" == true ]; then
  install_as_service=$(question "Would you like to install Fluentd as service? [y/n]
Yes - Fluentd will be installed as service (sudo rights required).
No  - Fluentd will be installed in a folder specified in the next step (read/write permissions required).
[y/n]: ")
else
  install_as_service="$INSTALL_AS_SERVICE"
fi

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
  fluentd_zip_install_default_path="$HOME/fluentd"
  if [ "$interactive" == true ]; then
    echo
    read -p "Please provide a path where Fluentd will be installed, (default: $fluentd_zip_install_default_path): " user_fluentd_install_path
  else
    user_fluentd_install_path="$USER_FLUENTD_INSTALL_PATH"
  fi
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

# Install log vendors (splunk, datadog etc)
config_link=$help_link
if [ "$interactive" == true ]; then
  declare install_log_vendors=$(question "Would you like to install Fluentd log vendors (optional)? [y/n]: ")
fi
# check if gem/td-agent-gem is installed
if [ -x "$(command -v td-agent-gem)" ] && [ $install_as_service == true ]; then
  gem_command="sudo td-agent-gem"
elif [ -x "$(command -v ${user_fluentd_install_path}/lib/ruby/bin/gem -v)" ]; then
  gem_command="$user_fluentd_install_path/lib/ruby/bin/gem"
else
  echo "WARNING: Ruby 'gem' or 'td-agent-gem' is required and was not found, please make sure that at least one of the mentioned frameworks is installed. Fluentd log vendors installation aborted."
  install_log_vendors=false
fi

if [ "$install_log_vendors" == true ] || [ ! -z "$LOG_VENDOR_NAME" ]; then
  while true; do
    echo
    if [ "$interactive" == true ]; then
      read -p "What log vendor would you like to install [Splunk, Datadog, Prometheus (plugin only) or Elastic (plugin only)]: " log_vendor_name
      log_vendor_name=${log_vendor_name,,}
    else
      log_vendor_name=${LOG_VENDOR_NAME,,}
    fi

    case $log_vendor_name in
    [splunk]*)2
      source ./log-vendors/fluentd-splunk-installer.sh # TODO Update the path (git raw)
      install_plugin $install_as_service "$user_fluentd_install_path" "$gem_command" || terminate "Error while installing Splunk plugin."
      break
      ;;
    [datadog]*)
      source ./log-vendors/fluentd-datadog-installer.sh # TODO Update the path (git raw)
      echo "$install_as_service $user_install_fluentd_path $gem_command"
      install_plugin $install_as_service "$user_fluentd_install_path" "$gem_command" || terminate "Error while installing Datadog plugin."
      break
      ;;
    [elastic]*)
      echo Installing fluent-plugin-elasticsearch...
      $gem_command install fluent-plugin-elasticsearch
      help_link=https://github.com/jfrog/log-analytics-elastic
      break
      ;;
    [prometheus]*)
      echo Installing fluent-plugin-prometheus...
      $gem_command install fluent-plugin-prometheus
      help_link=https://github.com/jfrog/log-analytics-prometheus
      break
      ;;
    *)
      if [ "$interactive" == true ]; then
        echo "Please answer: Splunk, Datadog, Prometheus, or Elastic." ;
      else
        terminate "The properties conf file $SCRIPT_PROPERTIES_FILE_PATH is missing property LOG_VENDOR_NAME"
      fi
    esac
  done
else
  echo "Skipping the log vendor installation."
fi

# Start/enable/status td-agent service
if [ "$install_as_service" == true ]; then
  # enable and start fluentd service, this part is only available if Fluentd was installed as service in the previous steps
  echo
  if [ "$interactive" == true ]; then
    declare start_enable_service=$(question "Would you like to start and enable Fluentd service (td-agent4, optional)? [y/n]: ")
  fi
  fluentd_service_name="td-agent"
  if [ "$start_enable_service" == true ] || [ "$START_ENABLE_SERVICE" == true ]; then
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
  if [ "$start_enable_service" == true ] || [ "$START_ENABLE_SERVICE" == true ]; then
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
      print_error "You can still start Fluentd manually with the following command: '$user_fluentd_install_path/fluentd $fluentd_conf_file_path'."
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
    service_based_message="$fluentd_conf_file_path. To manually start Fluentd use the following command: '$user_fluentd_install_path/fluentd $fluentd_conf_file_path'."
  fi
  fluentd_service_msg="To change the Fluentd configuration please update: $service_based_message"
fi

echo
print_green ==============================================================================================
print_green 'Fluentd installation completed!'
echo
print_green "$fluentd_service_msg"
echo
print_green "Additional information related to the JFrog analytics: https://github.com/jfrog/log-analytics"
print_green ==============================================================================================
# Fin!
