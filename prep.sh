function system_update() {
    echo "### Begin system_update"
    apt update
    apt -q -y install aptitude
    DEBIAN_FRONTEND=noninteractive aptitude -y safe-upgrade
    echo "### End system_update"
}
export -f system_update

function get_ubuntu_codename() {
    echo "$(lsb_release -c | cut -f2)"
}

export -f get_ubuntu_codename

function system_primary_ip() {
    echo $(ip addr show eth0 | fgrep " inet " | egrep -o "(?[[:digit:]]{1,3}\.){3}[[:digit:]]{1,3}" | head -1)
}
export -f system_primary_ip

function install_system_utils() {
    echo "### Begin install_system_utils"
    aptitude -y install build-essential tree htop apt-transport-https ca-certificates curl gnupg lsb-release jq
    echo "### End install_system_utils"
}
export -f install_system_utils

function restart_services() {
    echo "### Begin restart_services"
    for service in $(ls /tmp/restart-* | cut -d- -f2-10); do
        systemctl restart $service
        rm -f /tmp/restart-$service
    done
    echo "### End restart_services"
}
export -f restart_services


## INSTALL

function nginx_install() {
    echo "### Begin nginx_install"
    add-apt-repository -y ppa:nginx/stable
    apt update
    apt install -y nginx
    echo "### End nginx_install"
}
export -f nginx_install

