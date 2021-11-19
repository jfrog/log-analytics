# build docker image, JDP image + fluentd
# const
GITHUB_BRANCH=karolh2000/plugin-installers

# flow

# load scripts
common_sh_path=https://raw.githubusercontent.com/jfrog/log-analytics/${GITHUB_BRANCH}/fluentd-installer/scripts/linux/utils/common.sh
echo $common_sh_path

# load_remote_script $common_sh_path

source <(curl -s "$common_sh_path")

# check if docker installed
if ! command -v docker &> /dev/null
then
  terminate "Docker not found, please install docker before continue."
  exit 1
fi

# download Dockerfile
wget -O Dockerfile https://github.com/jfrog/log-analytics/raw/${GITHUB_BRANCH}/fluentd-installer/scripts/linux/docker/Dockerfile

# download the script
wget -O fluentd-agent-installer.sh https://github.com/jfrog/log-analytics/raw/${GITHUB_BRANCH}/fluentd-installer/scripts/linux/fluentd-agent-installer.sh
