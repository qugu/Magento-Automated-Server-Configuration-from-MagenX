#!/bin/bash
#====================================================================#
#        Automated Server Configuration for Magento 1+2              #
#        Copyright (C) 2017 admin@magenx.com                         #
#        All rights reserved.                                        #
#====================================================================#
SELF=$(basename $0)
MASCM_VER="20.5"
MASCM_BASE="https://masc.magenx.com"

### DEFINE LINKS AND PACKAGES STARTS ###

# Software versions
# Magento 1
MAGE_TMP_FILE="https://www.dropbox.com/s/5julyfcw36v4ie0/magento-1.9.3.2-2017-02-07-01-55-11.tar.gz"
MAGE_FILE_MD5="43136f05674c8114e9ac3183c1b75556"
MAGE_VER_1="1.9.3.2"

# Magento 2
MAGE_VER_2=$(curl -s https://api.github.com/repos/magento/magento2/tags 2>&1 | head -3 | grep -oP '(?<=")\d.*(?=")')
REPO_MAGE="composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition"

REPO_MASCM_TMP="https://raw.githubusercontent.com/magenx/Magento-Automated-Server-Configuration-from-MagenX/master/tmp/"

# Webmin Control Panel plugins:
WEBMIN_NGINX="https://github.com/magenx/webmin-nginx/archive/nginx-0.08.wbm__0.tar.gz"
WEBMIN_FAIL2BAN="http://download.webmin.com/download/modules/fail2ban.wbm.gz"

# Repositories
REPO_PERCONA="https://www.percona.com/redir/downloads/percona-release/ubuntu/latest/percona-release_0.1-4.xenial_all.deb"

# WebStack Packages
EXTRA_PACKAGES="build-essential make autoconf autopoint fonts-dejavu libtidy-0.99-0 libncap44 libgettextpo-dev libcppunit* recode libboost-all-dev libtbb* ed liblz4* libyaml-cpp-dev libdwarf-dev dnsutils e2fsprogs subversion gcc iptraf inotify-tools smartmontools net-tools mcrypt mlocate unzip vim wget curl sudo bc mailutils clamav clamav-base clamav-daemon proftpd-basic proftpd-mod-vroot proftpd-mod-geoip logrotate git patch ipset strace rsyslog gifsicle ncurses-dev libncursesw5-dev geoip-bin geoip-database libgeoip-dev openssl libssl-dev imagemagick libjpeg-turbo* pngcrush lsof snmp xinetd python-pip ncftp sysstat attr iotop expect certbot postgresql unixodbc"
PHP_PACKAGES=(cli common fpm opcache gd curl mbstring bcmath soap mcrypt mysql common xml xmlrpc intl gmp recode tidy zip ) # udan11-sql-parser, snappy
PHP_PECL_PACKAGES=(php-redis php-lzf php-geoip php-zip php-pclzip php-memcache php-gettext php-tcpdf php-phpseclib horde-lz4 symfony-class-loader symfony-common)
PERCONA_PACKAGES=(client-5.6 server-5.6)
PERL_MODULES=(libwww-perl libcpan-meta-perl libtemplate-plugin* libmoosex-role-timer-perl libextutils* libterm-readkey-perl libdbi-perl libdbd-mysql-perl libdigest* libtest-simple-perl libmoose-perl libnet-ssleay-perl libdevel*)
SPHINX="http://sphinxsearch.com/files/sphinxsearch_2.2.11-release-1~xenial_amd64.deb"

# Nginx extra configuration
NGINX_BASE="https://raw.githubusercontent.com/magenx/Magento-nginx-config/master/"
NGINX_EXTRA_CONF="assets.conf error_page.conf extra_protect.conf export.conf status.conf setup.conf php_backend.conf maps.conf phpmyadmin.conf maintenance.conf"

# Debug Tools
MYSQL_TUNER="https://raw.githubusercontent.com/major/MySQLTuner-perl/master/mysqltuner.pl"
MYSQL_TOP="https://launchpad.net/ubuntu/+archive/primary/+files/mytop_1.9.1.orig.tar.gz"

### DEFINE LINKS AND PACKAGES ENDS ###

# Simple colors
RED="\e[31;40m"
GREEN="\e[32;40m"
YELLOW="\e[33;40m"
WHITE="\e[37;40m"
BLUE="\e[0;34m"

# Background
DGREYBG="\t\t\e[100m"
BLUEBG="\e[44m"
REDBG="\t\t\e[41m"

# Styles
BOLD="\e[1m"

# Reset
RESET="\e[0m"

# quick-n-dirty settings
function WHITETXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${WHITE}${MESSAGE}${RESET}"
}
function BLUETXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${BLUE}${MESSAGE}${RESET}"
}
function REDTXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${RED}${MESSAGE}${RESET}"
}
function GREENTXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${GREEN}${MESSAGE}${RESET}"
}
function YELLOWTXT() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "\t\t${YELLOW}${MESSAGE}${RESET}"
}
function BLUEBG() {
        MESSAGE=${@:-"${RESET}Error: No message passed"}
        echo -e "${BLUEBG}${MESSAGE}${RESET}"
}

function pause() {
   read -p "$*"
}

function start_progress {
  while true
  do
    echo -ne "#"
    sleep 1
  done
}

function quick_progress {
  while true
  do
    echo -ne "#"
    sleep 0.05
  done
}

function long_progress {
  while true
  do
    echo -ne "#"
    sleep 3
  done
}

function stop_progress {
kill $1
wait $1 2>/dev/null
echo -en "\n"
}

updown_menu () {
i=1;for items in $(echo $1); do item[$i]="${items}"; let i=$i+1; done
i=1
echo
echo -e "\n---> Use up/down arrow keys then press Enter to select $2"
while [ 0 ]; do
  if [ "$i" -eq 0 ]; then i=1; fi
  if [ ! "${item[$i]}" ]; then let i=i-1; fi
  echo -en "\r                                 "
  echo -en "\r${item[$i]}"
  read -sn 1 selector
  case "${selector}" in
    "B") let i=i+1;;
    "A") let i=i-1;;
    "") echo; read -sn 1 -p "To confirm [ ${item[$i]} ] press y or n for new selection" confirm
      if [[ "${confirm}" =~ ^[Yy]$  ]]; then
        printf -v "$2" '%s' "${item[$i]}"
        break
      else
        echo
        echo -e "\n---> Use up/down arrow keys then press Enter to select $2"
      fi
      ;;
  esac
done }


clear
###################################################################################
#                                     START CHECKS                                #
###################################################################################
echo
echo
# root?
if [[ ${EUID} -ne 0 ]]; then
  echo
  REDTXT "ERROR: THIS SCRIPT MUST BE RUN AS ROOT!"
  YELLOWTXT "------> USE SUPER-USER PRIVILEGES."
  exit 1
  else
  GREENTXT "PASS: ROOT!"
fi

# network is up?
host1=209.85.202.91
host2=151.101.193.69
RESULT=$(((ping -w3 -c2 ${host1} || ping -w3 -c2 ${host2}) > /dev/null 2>&1) && echo "up" || (echo "down" && exit 1))
if [[ ${RESULT} == up ]]; then
  GREENTXT "PASS: NETWORK IS UP. GREAT, LETS START!"
  else
  echo
  REDTXT "ERROR: NETWORK IS DOWN?"
  YELLOWTXT "------> PLEASE CHECK YOUR NETWORK SETTINGS."
  echo
  echo
  exit 1
fi

# do we have Ubuntu 16.04?
if grep "16.04" /etc/os-release  > /dev/null 2>&1; then
  GREENTXT "PASS: UBUNTU 16.04"
  else
  echo
  REDTXT "ERROR: UNABLE TO DETERMINE DISTRIBUTION TYPE."
  YELLOWTXT "------> THIS CONFIGURATION FOR UBUNTU 16.04"
  YELLOWTXT "------> DONT RUN ON NEWER OR OLDER VERSIONS, PACKAGES MAY BE DIFFERENT"
  echo
  exit 1
fi

# check if x64. if not, beat it...
ARCH=$(uname -m)
if [ "${ARCH}" = "x86_64" ]; then
  GREENTXT "PASS: 64-BIT"
  else
  echo
  REDTXT "ERROR: 32-BIT SYSTEM?"
  YELLOWTXT "------> CONFIGURATION FOR 64-BIT ONLY."
  echo
  exit 1
fi

# check if memory is enough
TOTALMEM=$(awk '/MemTotal/ { print $2 }' /proc/meminfo)
if [ "${TOTALMEM}" -gt "3000000" ]; then
  GREENTXT "PASS: YOU HAVE ${TOTALMEM} Kb OF RAM"
  else
  echo
  REDTXT "WARNING: YOU HAVE LESS THAN 3Gb OF RAM"
  REDTXT "TO PROPERLY RUN COMPLETE STACK YOU NEED 4Gb+"
  echo
fi

# some selinux, sir?
if [ -f "/etc/selinux/config" ]; then
SELINUX=$(sestatus | awk '{print $3}')
if [ "${SELINUX}" != "disabled" ]; then
  echo
  REDTXT "ERROR: SELINUX IS NOT DISABLED"
  YELLOWTXT "------> PLEASE CHECK YOUR SELINUX SETTINGS"
  echo
  exit 1
  else
  GREENTXT "PASS: SELINUX IS DISABLED"
fi
fi
echo
if grep -q "yes" /root/mascm/.systest >/dev/null 2>&1 ; then
  BLUETXT "the systems test has been made already"
  else
echo "-------------------------------------------------------------------------------------"
BLUEBG "| QUICK SYSTEM TEST |"
echo "-------------------------------------------------------------------------------------"
echo
#    yum -y install epel-release > /dev/null 2>&1
#    yum -y install time bzip2 tar > /dev/null 2>&1

    test_file=vpsbench__$$
    tar_file=tarfile
    now=$(date +"%m/%d/%Y")

    cname=$( awk -F: '/model name/ {name=$2} END {print name}' /proc/cpuinfo )
    cores=$( awk -F: '/model name/ {core++} END {print core}' /proc/cpuinfo )
    freq=$( awk -F: ' /cpu MHz/ {freq=$2} END {print freq}' /proc/cpuinfo )
    tram=$( free -m | awk 'NR==2 {print $2}' )

    echo

    echo -n "     PROCESSING I/O PERFORMANCE "
    start_progress &
    pid="$!"
    io=$( ( dd if=/dev/zero of=$test_file bs=64k count=16k conv=fdatasync && rm -f $test_file ) 2>&1 | awk -F, '{io=$NF} END { print io}' )
    stop_progress "$pid"

    echo -n "     PROCESSING CPU PERFORMANCE "
    dd if=/dev/urandom of=$tar_file bs=1024 count=25000 >>/dev/null 2>&1
    start_progress &
    pid="$!"
    tf=$( (/usr/bin/time -f "%es" tar cfj $tar_file.bz2 $tar_file) 2>&1 )
    stop_progress "$pid"
    rm -f tarfile*
    echo
    echo

    if [ ${io% *} -ge 250 ] ; then
        IO_COLOR="${GREEN}$io - excellent result"
    elif [ ${io% *} -ge 200 ] ; then
        IO_COLOR="${YELLOW}$io - average result"
    else
        IO_COLOR="${RED}$io - very bad result"
    fi

    if [ ${tf%.*} -ge 10 ] ; then
        CPU_COLOR="${RED}$tf - very bad result"
    elif [ ${tf%.*} -ge 5 ] ; then
        CPU_COLOR="${YELLOW}$tf - average result"
    else
        CPU_COLOR="${GREEN}$tf - excellent result"
    fi

  WHITETXT "${BOLD}SYSTEM DETAILS"
  WHITETXT "CPU model: $cname"
  WHITETXT "Number of cores: $cores"
  WHITETXT "CPU frequency: $freq MHz"
  WHITETXT "Total amount of RAM: $tram MB"
  echo
  WHITETXT "${BOLD}BENCHMARK RESULTS"
  WHITETXT "I/O speed: ${IO_COLOR}"
  WHITETXT "CPU Time: ${CPU_COLOR}"

echo
mkdir -p /root/mascm/ && echo "yes" > /root/mascm/.systest
echo
pause "---> Press [Enter] key to proceed"
echo
fi
echo
if grep -q "yes" /root/mascm/.sshport >/dev/null 2>&1 ; then
BLUETXT "ssh port has been changed already"
else
if grep -q "Port 22" /etc/ssh/sshd_config >/dev/null 2>&1 ; then
REDTXT "DEFAULT SSH PORT :22 DETECTED"
echo
echo -n "---> Lets change the default ssh port now? [y/n][n]:"
read new_ssh_set
if [ "${new_ssh_set}" == "y" ];then
   echo
      cp /etc/ssh/sshd_config /etc/ssh/sshd_config.BACK
      SSHPORT=$(shuf -i 9537-9554 -n 1)
      read -e -p "---> Enter a new ssh port : " -i "${SSHPORT}" NEW_SSH_PORT
      sed -i "s/.*Port 22/Port ${NEW_SSH_PORT}/g" /etc/ssh/sshd_config
      sed -i "s/.*LoginGraceTime.*/LoginGraceTime 30/" /etc/ssh/sshd_config
      sed -i "s/.*MaxAuthTries.*/MaxAuthTries 6/" /etc/ssh/sshd_config
      sed -i "s/.*X11Forwarding.*/X11Forwarding no/" /etc/ssh/sshd_config
      sed -i "s/.*PrintLastLog.*/PrintLastLog yes/" /etc/ssh/sshd_config
      sed -i "s/.*TCPKeepAlive.*/TCPKeepAlive yes/" /etc/ssh/sshd_config
      sed -i "s/.*ClientAliveInterval.*/ClientAliveInterval 600/" /etc/ssh/sshd_config
      sed -i "s/.*ClientAliveCountMax.*/ClientAliveCountMax 3/" /etc/ssh/sshd_config
      sed -i "s/.*UseDNS.*/UseDNS no/" /etc/ssh/sshd_config
     echo
        GREENTXT "SSH PORT AND SETTINGS HAS BEEN UPDATED  -  OK"
        systemctl restart sshd.service
        ss -tlp | grep sshd
     echo
echo
REDTXT "!IMPORTANT: NOW OPEN A NEW SSH SESSION WITH THE NEW PORT!"
REDTXT "!IMPORTANT: DO NOT CLOSE THE CURRENT SESSION!"
echo
echo -n "------> Have you logged in another session? [y/n][n]:"
read new_ssh_test
if [ "${new_ssh_test}" == "y" ];then
      echo
        GREENTXT "REMEMBER THE NEW SSH PORT NOW: ${NEW_SSH_PORT}"
        echo "yes" > /root/mascm/.sshport
        else
	echo
        mv /etc/ssh/sshd_config.BACK /etc/ssh/sshd_config
        REDTXT "RESTORING sshd_config FILE BACK TO DEFAULTS ${GREEN} [ok]"
        systemctl restart sshd.service
        echo
        GREENTXT "SSH PORT HAS BEEN RESTORED  -  OK"
        ss -tlp | grep sshd
fi
fi
fi
fi
echo
echo
###################################################################################
#                                     CHECKS END                                  #
###################################################################################
echo
if grep -q "yes" /root/mascm/.terms >/dev/null 2>&1 ; then
  echo ""
  else
  YELLOWTXT "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo
  YELLOWTXT "BY INSTALLING THIS SOFTWARE AND BY USING ANY AND ALL SOFTWARE"
  YELLOWTXT "YOU ACKNOWLEDGE AND AGREE:"
  echo
  YELLOWTXT "THIS SOFTWARE AND ALL SOFTWARE PROVIDED IS PROVIDED AS IS"
  YELLOWTXT "UNSUPPORTED AND WE ARE NOT RESPONSIBLE FOR ANY DAMAGE"
  echo
  YELLOWTXT "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo
   echo
    echo -n "---> Do you agree to these terms?  [y/n][y]:"
    read terms_agree
  if [ "${terms_agree}" == "y" ];then
    echo "yes" > /root/mascm/.terms
          else
        REDTXT "Going out. EXIT"
        echo
    exit 1
  fi
fi
###################################################################################
#                                  HEADER MENU START                              #
###################################################################################
showMenu () {
printf "\033c"
    echo
      echo
        echo -e "${DGREYBG}${BOLD}  MAGENTO SERVER CONFIGURATION v.${MASCM_VER}  ${RESET}"
        BLUETXT ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
        echo
        WHITETXT "-> Install repository and LEMP packages :  ${YELLOW}\tlemp"
        WHITETXT "-> Download Magento latest packages     :  ${YELLOW}\t\tmagento"
        WHITETXT "-> Setup Magento database               :  ${YELLOW}\t\t\tdatabase"
        WHITETXT "-> Install Magento no sample data       :  ${YELLOW}\t\tinstall"
        WHITETXT "-> Post-Install configuration           :  ${YELLOW}\t\tconfig"
        echo
        BLUETXT ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
        echo
        WHITETXT "-> Install CSF Firewall or Fail2Ban     :  ${YELLOW}\t\tfirewall"
        WHITETXT "-> Install Webmin control panel         :  ${YELLOW}\t\twebmin"
        WHITETXT "-> Install Ossec ELK stack              :  ${YELLOW}\t\t\tossec"
        echo
        BLUETXT ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
        echo
        WHITETXT "-> To quit and exit                     :  ${RED}\t\t\t\texit"
        echo
    echo
}
while [ 1 ]
do
        showMenu
        read CHOICE
        case "${CHOICE}" in
                "lemp")
echo
echo
if grep -q "yes" /root/mascm/.sysupdate >/dev/null 2>&1 ; then
echo
else
## install all extra packages
GREENTXT "SYSTEM PACKAGES INSTALLATION. PLEASE WAIT"
add-apt-repository -y ppa:certbot/certbot >/dev/null 2>&1
apt-get -q -y update >/dev/null 2>&1
apt-get -q -y upgrade >/dev/null 2>&1
echo proftpd-basic shared/proftpd/inetd_or_standalone select standalone | debconf-set-selections
echo postfix postfix/main_mailer_type select No configuration |  debconf-set-selections
apt-get -q -y install ${EXTRA_PACKAGES} >/dev/null 2>&1
apt-get -q -y install ${PERL_MODULES}  >/dev/null 2>&1
echo
echo "yes" > /root/mascm/.sysupdate
echo
fi
echo
echo
echo "-------------------------------------------------------------------------------------"
BLUEBG "| START THE INSTALLATION OF REPOSITORIES AND PACKAGES |"
echo "-------------------------------------------------------------------------------------"
echo
WHITETXT "============================================================================="
echo
echo -n "---> Start Percona repository and Percona database installation? [y/n][n]:"
read repo_percona_install
if [ "${repo_percona_install}" == "y" ];then
          echo
            GREENTXT "Installation of Percona repository:"
            echo
            echo -n "     PROCESSING  "
            quick_progress &
            pid="$!"
            wget -qO /tmp/percona_repo.deb ${REPO_PERCONA}
            dpkg --install /tmp/percona_repo.deb >/dev/null 2>&1
            stop_progress "$pid"
            dpkg-query -l percona-release >/dev/null 2>&1
      if [ "$?" = 0 ] # if repository installed then install package
        then
          echo
            GREENTXT "REPOSITORY HAS BEEN INSTALLED  -  OK"
              echo
              echo
              GREENTXT "Installation of Percona 5.6 database:"
              echo
              echo -n "     PROCESSING  "
              long_progress &
              pid="$!"
              apt-get update -y >/dev/null 2>&1
              export MYSQL_ROOT_PASS=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
              echo ${MYSQL_ROOT_PASS} > /root/mascm/.mysql_pass
              echo percona-server-server-5.6 percona-server-server/root_password password ${MYSQL_ROOT_PASS} | debconf-set-selections
              echo percona-server-server-5.6 percona-server-server/root_password_again password ${MYSQL_ROOT_PASS} | debconf-set-selections
              apt-get install -q -y ${PERCONA_PACKAGES[@]/#/percona-server-}  >/dev/null 2>&1
              stop_progress "$pid"
              dpkg-query -l ${PERCONA_PACKAGES[@]/#/percona-server-} >/dev/null 2>&1
        if [ "$?" = 0 ] # if package installed then configure
          then
            echo
              GREENTXT "DATABASE HAS BEEN INSTALLED  -  OK"
              echo
              echo
              WHITETXT "Downloading my.cnf file from MagenX Github repository"
              wget -qO /etc/mysql/my.cnf https://raw.githubusercontent.com/magenx/magento-mysql/master/my.cnf/my.cnf
              echo
                echo
                 WHITETXT "We need to correct your innodb_buffer_pool_size"
                 apt install -y bc >/dev/null 2>&1
                 IBPS=$(echo "0.5*$(awk '/MemTotal/ { print $2 / (1024*1024)}' /proc/meminfo | cut -d'.' -f1)" | bc | xargs printf "%1.0f")
                 sed -i "s/innodb_buffer_pool_size = 4G/innodb_buffer_pool_size = ${IBPS}G/" /etc/mysql/my.cnf
                 sed -i "s/innodb_buffer_pool_instances = 4/innodb_buffer_pool_instances = ${IBPS}/" /etc/mysql/my.cnf
                 echo
                 YELLOWTXT "innodb_buffer_pool_size = ${IBPS}G"
                 YELLOWTXT "innodb_buffer_pool_instances = ${IBPS}"
                echo
              echo
              ## get mysql tools
              cd /usr/local/src
              wget -qO - ${MYSQL_TOP} | tar -xzp && cd mytop*  >/dev/null 2>&1
              perl Makefile.PL >/dev/null 2>&1
              make >/dev/null 2>&1
              make install >/dev/null 2>&1
              apt install -y percona-toolkit >/dev/null 2>&1
              echo
              WHITETXT "Please use these tools to check and finetune your database:"
              echo
              WHITETXT "Percona Toolkit with pt- commands"
              WHITETXT "mytop"
              WHITETXT "perl mysqltuner.pl"
              echo
              else
              echo
              REDTXT "DATABASE INSTALLATION ERROR"
          exit # if package is not installed then exit
        fi
          else
            echo
              REDTXT "REPOSITORY INSTALLATION ERROR"
        exit # if repository is not installed then exit
      fi
        else
              echo
            YELLOWTXT "Percona repository installation was skipped by the user. Next step"
fi
echo
WHITETXT "============================================================================="
echo
echo -n "---> Start Nginx (mainline) Repository installation? [y/n][n]:"
read repo_nginx_install
if [ "${repo_nginx_install}" == "y" ];then
          echo
            GREENTXT "Installation of Nginx (mainline) repository:"
            echo
            WHITETXT "Downloading Nginx GPG key"
            wget -qO /tmp/nginx_signing.key https://nginx.ru/keys/nginx_signing.key  >/dev/null 2>&1
            echo
            WHITETXT "Adding Nginx GPG key"
            apt-key add /tmp/nginx_signing.key
            WHITETXT "Nginx (mainline) repository file"
            echo
cat >> /etc/apt/sources.list <<END
deb http://nginx.org/packages/mainline/ubuntu/ xenial nginx
deb-src http://nginx.org/packages/mainline/ubuntu/ xenial nginx
END
            echo
            GREENTXT "REPOSITORY HAS BEEN INSTALLED  -  OK"
            echo
            GREENTXT "Installation of NGINX package:"
            echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            apt update -y >/dev/null 2>&1
            apt install -y nginx nginx-module-geoip nginx-module-perl >/dev/null 2>&1
            stop_progress "$pid"
            dpkg-query -l nginx >/dev/null 2>&1
      if [ "$?" = 0 ]
        then
          echo
            GREENTXT "NGINX HAS BEEN INSTALLED  -  OK"
            echo
            else
             echo
            REDTXT "NGINX INSTALLATION ERROR"
        exit
      fi
        else
          echo
            YELLOWTXT "Nginx (mainline) repository installation was skipped by the user. Next step"
fi
echo
WHITETXT "============================================================================="
echo
echo -n "---> Start the PHP 7.0 installation? [y/n][n]:"
read repo_remi_install
if [ "${repo_remi_install}" == "y" ]; then
        GREENTXT "Installation of PHP 7.0:"
            echo
            echo -n "     PROCESSING  "
            long_progress &
            pid="$!"
            add-apt-repository -y ppa:ondrej/php >/dev/null 2>&1
            apt-get update -y  >/dev/null 2>&1
            apt-get install -y php7.0 ${PHP_PACKAGES[@]/#/php7.0-} ${PHP_PECL_PACKAGES} >/dev/null 2>&1
            stop_progress "$pid"
            dpkg-query -l php7.0 >/dev/null 2>&1
       if [ "$?" = 0 ]
         then
           echo
             GREENTXT "PHP HAS BEEN INSTALLED  -  OK"
              sed -i "s/PrivateTmp=true/PrivateTmp=false/" /lib/systemd/system/php7.0-fpm.service
              sed -i "/^After.*/a OnFailure=service-status-mail@%n.service" /lib/systemd/system/php7.0-fpm.service
              sed -i "/\[Install\]/i Restart=on-failure\nRestartSec=10\n" /lib/systemd/system/php7.0-fpm.service
              systemctl daemon-reload
              systemctl enable php7.0-fpm >/dev/null 2>&1
              dpkg-query -l php7.0* | awk '/php7.0.*/ {print "      ",$2}'
                else
               echo
             REDTXT "PHP INSTALLATION ERROR"
         exit
       fi
     else
       echo
         YELLOWTXT "The PHP installation was skipped by the user. Next step"
       fi

     WHITETXT "============================================================================="
      echo
      echo -n "---> Start the Redis and Memcached installation? [y/n][n]:"
      read repo_redis_install
      if [ "${repo_redis_install}" == "y" ]; then
           echo
            GREENTXT "Installation of Redis, Memcached and Sphinx packages:"
            echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            apt install -y redis-server memcached >/dev/null 2>&1
            wget -qO sphinx-latest.deb ${SPHINX}  >/dev/null 2>&1
            dpkg --install sphinx-latest.deb >/dev/null 2>&1
            apt-get install -f -y  >/dev/null 2>&1
            stop_progress "$pid"
            dpkg-query -l redis-server >/dev/null 2>&1
       if [ "$?" = 0 ]
         then
           echo
             GREENTXT "REDIS HAS BEEN INSTALLED"
             systemctl stop redis-server.service >/dev/null 2>&1
             systemctl disable redis-server.service >/dev/null 2>&1
             echo

for REDISPORT in 6379 6380
    do
        mkdir -p /var/lib/redis-${REDISPORT}
        chmod 755 /var/lib/redis-${REDISPORT}
        chown redis:redis /var/lib/redis-${REDISPORT}
        cp -rf /etc/redis/redis.conf /etc/redis/redis-${REDISPORT}.conf
        chmod 644 /etc/redis/redis-${REDISPORT}.conf
        cp -rf /lib/systemd/system/redis-server.service /lib/systemd/system/redis-${REDISPORT}.service
        sed -i "s/daemonize no/daemonize yes/"  /etc/redis/redis-${REDISPORT}.conf
        sed -i "s/pidfile \/var\/run\/redis\/redis-server.pid/pidfile \/var\/run\/redis\/redis-${REDISPORT}.pid/" /etc/redis/redis-${REDISPORT}.conf
        sed -i "s/^bind 127.0.0.1.*/bind 127.0.0.1/"  /etc/redis/redis-${REDISPORT}.conf
        sed -i "s/^dir.*/dir \/var\/lib\/redis-${REDISPORT}\//"  /etc/redis/redis-${REDISPORT}.conf
        sed -i "s/^logfile.*/logfile \/var\/log\/redis\/redis-${REDISPORT}.log/"  /etc/redis/redis-${REDISPORT}.conf
        sed -i "s/^port.*/port ${REDISPORT}/" /etc/redis/redis-${REDISPORT}.conf
        sed -i "s/redis.conf/redis-${REDISPORT}.conf/" /lib/systemd/system/redis-${REDISPORT}.service
        sed -i "/^After.*/a OnFailure=service-status-mail@%n.service" /lib/systemd/system/redis-${REDISPORT}.service
        # Hack of the original file coming from GIT.
        sed -i "/ExecStartPre/d" /lib/systemd/system/redis-${REDISPORT}.service
        sed -i "/ExecStartPost/d" /lib/systemd/system/redis-${REDISPORT}.service
        sed -i "/ExecStopPost/d" /lib/systemd/system/redis-${REDISPORT}.service
        sed -i "/PIDFile/d" /lib/systemd/system/redis-${REDISPORT}.service
        # --- End of Hack ---
        sed -i "s/^Alias=.*/Alias=redis-${REDISPORT}.service/" /lib/systemd/system/redis-${REDISPORT}.service
        sed -i "/\[Install\]/i Restart=on-failure\nRestartSec=10\n" /lib/systemd/system/redis-${REDISPORT}.service
        sed -i "s/ReadWriteDirectories=-\/var\/lib\/redis/ReadWriteDirectories=-\/var\/lib\/redis-${REDISPORT}/" /lib/systemd/system/redis-${REDISPORT}.service
    done
echo
        cat > /etc/memcached.conf <<END
-p 11211
-u memcache
-c 5024
-m 128
-l 127.0.0.1
END
        systemctl daemon-reload
        systemctl enable redis-6379 >/dev/null 2>&1
        systemctl enable redis-6380 >/dev/null 2>&1

                else
               echo
             REDTXT "REDIS PACKAGE INSTALLATION ERROR"
         exit
       fi
        else
          echo
            YELLOWTXT "The Redis installation was skipped by the user. Next step"
fi
echo
WHITETXT "============================================================================="
echo
echo -n "---> Start Varnish 4.x installation? [y/n][n]:"
read varnish_install
if [ "${varnish_install}" == "y" ];then
          echo
            GREENTXT "Installation of Varnish package:"
            echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            apt-get install -f -y  >/dev/null 2>&1
            apt-get install -y varnish >/dev/null 2>&1
            stop_progress "$pid"
            dpkg-query -l varnish >/dev/null 2>&1
      if [ "$?" = 0 ]
        then
          echo
	    wget -qO /lib/systemd/system/varnish.service ${REPO_MASCM_TMP}varnish.service  >/dev/null 2>&1
            wget -qO /etc/varnish/varnish.params ${REPO_MASCM_TMP}varnish.params  >/dev/null 2>&1
            systemctl daemon-reload >/dev/null 2>&1
            GREENTXT "VARNISH HAS BEEN INSTALLED  -  OK"
               else
              echo
            REDTXT "VARNISH INSTALLATION ERROR"
      fi
        else
          echo
            YELLOWTXT "Varnish installation was skipped by the user. Next step"
fi
echo
echo
WHITETXT "============================================================================="
echo
echo -n "---> Start HHVM installation? [y/n][n]:"
read hhvm_install
if [ "${hhvm_install}" == "y" ];then
echo
echo
            GREENTXT "Installation of HHVM package:"
            echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            apt install -y hhvm >/dev/null 2>&1
            stop_progress "$pid"
            dpkg-query -l hhvm >/dev/null 2>&1
      if [ "$?" = 0 ]
        then
          echo
            GREENTXT "HHVM HAS BEEN INSTALLED  -  OK"
            echo
            sed -i "/^Description=.*/a OnFailure=service-status-mail@%n.service" /lib/systemd/system/hhvm.service
            sed -i "/\[Install\]/i Restart=on-failure\nRestartSec=10\n" /lib/systemd/system/hhvm.service
            systemctl daemon-reload
            systemctl enable hhvm >/dev/null 2>&1
               else
              echo
            REDTXT "HHVM INSTALLATION ERROR"
      fi
        else
          echo
            YELLOWTXT "HHVM installation was skipped by the user. Next step"
fi
echo
echo "-------------------------------------------------------------------------------------"
BLUEBG "| THE INSTALLATION OF REPOSITORIES AND PACKAGES IS COMPLETE |"
echo "-------------------------------------------------------------------------------------"
echo
echo
GREENTXT "NOW WE ARE GOING TO CONFIGURE EVERYTHING"
echo
pause "---> Press [Enter] key to proceed"
echo
echo "Load optimized configs of php, opcache, fpm, fastcgi, sysctl, varnish"
WHITETXT "YOU HAVE TO CHECK THEM AFTER ANYWAY"
cat > /etc/sysctl.conf <<END
fs.file-max = 1000000
fs.inotify.max_user_watches = 1000000
vm.swappiness = 10
net.ipv4.ip_forward = 0
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.default.accept_source_route = 0
kernel.sysrq = 0
kernel.core_uses_pid = 1
kernel.msgmnb = 65535
kernel.msgmax = 65535
kernel.shmmax = 68719476736
kernel.shmall = 4294967296
net.ipv4.tcp_tw_recycle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 8388608 8388608 8388608
net.ipv4.tcp_rmem = 4096 87380 8388608
net.ipv4.tcp_wmem = 4096 65535 8388608
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_challenge_ack_limit = 1073741823
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_keepalive_time = 15
net.ipv4.tcp_max_orphans = 262144
net.ipv4.tcp_max_syn_backlog = 262144
net.ipv4.tcp_max_tw_buckets = 400000
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_sack = 1
net.ipv4.route.flush = 1
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 8388608
net.core.wmem_default = 8388608
net.core.netdev_max_backlog = 262144
net.core.somaxconn = 65535
END

sysctl -q -p
echo
WHITETXT "sysctl.conf loaded ${GREEN} [ok]"
cat > /etc/php/7.0/fpm/conf.d/10-opcache.ini <<END
zend_extension=opcache.so
opcache.enable = 1
opcache.enable_cli = 1
opcache.memory_consumption = 256
opcache.interned_strings_buffer = 4
opcache.max_accelerated_files = 50000
opcache.max_wasted_percentage = 5
opcache.use_cwd = 1
opcache.validate_timestamps = 0
;opcache.revalidate_freq = 2
opcache.file_update_protection = 2
opcache.revalidate_path = 0
opcache.save_comments = 1
opcache.load_comments = 1
opcache.fast_shutdown = 0
opcache.enable_file_override = 0
opcache.optimization_level = 0xffffffff
opcache.inherited_hack = 1
opcache.blacklist_filename=/etc/php/7.0/fpm/opcache-default.blacklist
opcache.max_file_size = 0
opcache.consistency_checks = 0
opcache.force_restart_timeout = 60
opcache.error_log = "/var/log/php-fpm/opcache.log"
opcache.log_verbosity_level = 1
opcache.preferred_memory_model = ""
opcache.protect_memory = 0
;opcache.mmap_base = ""
END

WHITETXT "opcache.ini loaded ${GREEN} [ok]"
#Tweak php.ini.
cp /etc/php/7.0/fpm/php.ini /etc/php/7.0/fpm/php.ini.BACK
sed -i 's/^\(max_execution_time = \)[0-9]*/\17200/' /etc/php/7.0/fpm/php.ini
sed -i 's/^\(max_input_time = \)[0-9]*/\17200/' /etc/php/7.0/fpm/php.ini
sed -i 's/^\(memory_limit = \)[0-9]*M/\11024M/' /etc/php/7.0/fpm/php.ini
sed -i 's/^\(post_max_size = \)[0-9]*M/\164M/' /etc/php/7.0/fpm/php.ini
sed -i 's/^\(upload_max_filesize = \)[0-9]*M/\164M/' /etc/php/7.0/fpm/php.ini
sed -i 's/expose_php = On/expose_php = Off/' /etc/php/7.0/fpm/php.ini
sed -i 's/;realpath_cache_size = 16k/realpath_cache_size = 512k/' /etc/php/7.0/fpm/php.ini
sed -i 's/;realpath_cache_ttl = 120/realpath_cache_ttl = 86400/' /etc/php/7.0/fpm/php.ini
sed -i 's/short_open_tag = Off/short_open_tag = On/' /etc/php/7.0/fpm/php.ini
sed -i 's/; max_input_vars = 1000/max_input_vars = 50000/' /etc/php/7.0/fpm/php.ini
sed -i 's/session.gc_maxlifetime = 1440/session.gc_maxlifetime = 28800/' /etc/php/7.0/fpm/php.ini
sed -i 's/mysql.allow_persistent = On/mysql.allow_persistent = Off/' /etc/php/7.0/fpm/php.ini
sed -i 's/mysqli.allow_persistent = On/mysqli.allow_persistent = Off/' /etc/php/7.0/fpm/php.ini
sed -i 's/pm = dynamic/pm = ondemand/' /etc/php/7.0/fpm/pool.d/www.conf
sed -i 's/;pm.max_requests = 500/pm.max_requests = 10000/' /etc/php/7.0/fpm/pool.d/www.conf
sed -i 's/pm.max_children = 50/pm.max_children = 1000/' /etc/php/7.0/fpm/pool.d/www.conf

WHITETXT "php.ini loaded ${GREEN} [ok]"
echo
echo "*         soft    nofile          700000" >> /etc/security/limits.conf
echo "*         hard    nofile          1000000" >> /etc/security/limits.conf
echo
echo
echo "-------------------------------------------------------------------------------------"
BLUEBG "| FINISHED PACKAGES INSTALLATION |"
echo "-------------------------------------------------------------------------------------"
echo
echo
pause '------> Press [Enter] key to show the menu'
printf "\033c"
;;
"magento")
###################################################################################
#                                MAGENTO                                          #
###################################################################################
echo
echo "-------------------------------------------------------------------------------------"
BLUEBG "|   SELECT TO DOWNLOAD MAGENTO 1 (${MAGE_VER_1}) OR 2 (${MAGE_VER_2})  |"
echo "-------------------------------------------------------------------------------------"
echo
echo
     read -e -p "---> SELECT MAGENTO TO DOWNLOAD 1 OR 2: " -i "2"  MAGE_SEL_VER
	 MAGE_VER=MAGE_VER_${MAGE_SEL_VER}
	 echo
     read -e -p "---> ENTER YOUR DOMAIN NAME: " -i "myshop.com" MAGE_DOMAIN
     MAGE_WEB_ROOT_PATH="/home/${MAGE_DOMAIN%%.*}/public_html"
     echo
	 echo "---> MAGENTO ${MAGE_SEL_VER} (${!MAGE_VER})"
	 echo "---> WILL BE DOWNLOADED TO ${MAGE_WEB_ROOT_PATH}"
     echo
        mkdir -p ${MAGE_WEB_ROOT_PATH} && cd $_
        useradd -d ${MAGE_WEB_ROOT_PATH%/*} -s /sbin/nologin ${MAGE_DOMAIN%%.*}  >/dev/null 2>&1
        MAGE_WEB_USER_PASS=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
        echo "${MAGE_DOMAIN%%.*}:${MAGE_WEB_USER_PASS}"  | chpasswd  >/dev/null 2>&1
        chmod 711 /home/${MAGE_DOMAIN%%.*}
        chown -R ${MAGE_DOMAIN%%.*}:${MAGE_DOMAIN%%.*} ${MAGE_WEB_ROOT_PATH%/*}
        chmod 2770 ${MAGE_WEB_ROOT_PATH}
        setfacl -Rdm u:${MAGE_DOMAIN%%.*}:rwx,g:${MAGE_DOMAIN%%.*}:rwx,g::rw-,o::- ${MAGE_WEB_ROOT_PATH}
        echo
		if [ "${MAGE_SEL_VER}" = "1" ]; then
			echo -n "      DOWNLOADING MAGENTO"
			long_progress &
			pid="$!"
			su ${MAGE_DOMAIN%%.*} -s /bin/bash -c "wget -qO - ${MAGE_TMP_FILE} | tar -xzp --strip-components 1"
			stop_progress "$pid"
        else
			curl -sS https://getcomposer.org/installer | php >/dev/null 2>&1
			mv composer.phar /usr/local/bin/composer
			[ -f "/usr/local/bin/composer" ] || { echo "---> COMPOSER INSTALLATION ERROR" ; exit 1 ;}
			su ${MAGE_DOMAIN%%.*} -s /bin/bash -c "${REPO_MAGE} ."
		fi
        echo
     echo
WHITETXT "============================================================================="
GREENTXT "      == MAGENTO DOWNLOADED AND READY FOR INSTALLATION =="
WHITETXT "============================================================================="
mkdir -p /root/mascm/
cat >> /root/mascm/.mascm_index <<END
webshop ${MAGE_DOMAIN}    ${MAGE_WEB_ROOT_PATH}    ${MAGE_DOMAIN%%.*}   ${MAGE_WEB_USER_PASS}  ${MAGE_SEL_VER}  ${!MAGE_VER}
END
echo
pause '------> Press [Enter] key to show menu'
printf "\033c"
;;
###################################################################################
#                                MAGENTO DATABASE SETUP                           #
###################################################################################
"database")
printf "\033c"
WHITETXT "============================================================================="
GREENTXT "MAGENTO DATABASE AND DATABASE USER"
echo
systemctl start mysql.service
MAGE_SEL_VER=$(awk '/webshop/ { print $6 }' /root/mascm/.mascm_index)
if [ -f "/root/mascm/.mysql_pass" ]; then
   MYSQL_ROOT_PASS=$(cat /root/mascm/.mysql_pass)
  else
  MYSQL_ROOT_PASS=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
  fi
MAGE_DB_PASS=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)

MYSQL_SECURE_INSTALLATION=$(expect -c "
set timeout 5
log_user 0
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"${MYSQL_ROOT_PASS}\r\"
expect \"Change the root password?\"
send \"n\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"n\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")


echo "${MYSQL_SECURE_INSTALLATION}"
echo
echo
read -e -p "---> Enter Magento database host : " -i "localhost" MAGE_DB_HOST
read -e -p "---> Enter Magento database name : " -i "m${MAGE_SEL_VER}d_$(openssl rand 2 -hex)_$(date +%y%m%d)" MAGE_DB_NAME
read -e -p "---> Enter Magento database user : " -i "m${MAGE_SEL_VER}u_$(openssl rand 2 -hex)_$(date +%y%m%d)" MAGE_DB_USER_NAME
echo
echo
pause '------> Press [Enter] key to create MySQL database and user'
mysql -u root -p${MYSQL_ROOT_PASS} -Bse "CREATE DATABASE \`${MAGE_DB_NAME}\`;
CREATE USER '${MAGE_DB_USER_NAME}'@'${MAGE_DB_HOST}' IDENTIFIED BY '${MAGE_DB_PASS}';
GRANT ALL PRIVILEGES ON ${MAGE_DB_NAME}.* TO '${MAGE_DB_USER_NAME}'@'${MAGE_DB_HOST}' WITH GRANT OPTION"
echo
cat > /root/.mytop <<END
user=root
pass=${MYSQL_ROOT_PASS}
db=mysql
END
cat > /root/.my.cnf <<END
[client]
user=root
password=${MYSQL_ROOT_PASS}
END
echo
mkdir -p /root/mascm/
cat >> /root/mascm/.mascm_index <<END
database   ${MAGE_DB_HOST}   ${MAGE_DB_NAME}   ${MAGE_DB_USER_NAME}     ${MAGE_DB_PASS}    ${MYSQL_ROOT_PASS}
END
echo
echo
pause '------> Press [Enter] key to show menu'
printf "\033c"
;;
###################################################################################
#                                MAGENTO INSTALLATION                             #
###################################################################################
"install")
printf "\033c"
MAGE_SEL_VER=$(awk '/webshop/ { print $6 }' /root/mascm/.mascm_index)
MAGE_VER=$(awk '/webshop/ { print $7 }' /root/mascm/.mascm_index)
echo "-------------------------------------------------------------------------------------"
BLUEBG   "|  MAGENTO ${MAGE_SEL_VER} (${MAGE_VER}) INSTALLATION  |"
echo "-------------------------------------------------------------------------------------"
echo
MAGE_WEB_ROOT_PATH=$(awk '/webshop/ { print $3 }' /root/mascm/.mascm_index)
MAGE_WEB_USER=$(awk '/webshop/ { print $4 }' /root/mascm/.mascm_index)
MAGE_DOMAIN=$(awk '/webshop/ { print $2 }' /root/mascm/.mascm_index)
DB_HOST=$(awk '/database/ { print $2 }' /root/mascm/.mascm_index)
DB_NAME=$(awk '/database/ { print $3 }' /root/mascm/.mascm_index)
DB_USER_NAME=$(awk '/database/ { print $4 }' /root/mascm/.mascm_index)
DB_PASS=$(awk '/database/ { print $5 }' /root/mascm/.mascm_index)

cd ${MAGE_WEB_ROOT_PATH}
chown -R ${MAGE_WEB_USER}:${MAGE_WEB_USER} ${MAGE_WEB_ROOT_PATH}
echo
echo "---> ENTER SETUP INFORMATION"
echo
WHITETXT "Database information"
read -e -p "---> Enter your database host: " -i "${DB_HOST}"  MAGE_DB_HOST
read -e -p "---> Enter your database name: " -i "${DB_NAME}"  MAGE_DB_NAME
read -e -p "---> Enter your database user: " -i "${DB_USER_NAME}"  MAGE_DB_USER_NAME
read -e -p "---> Enter your database password: " -i "${DB_PASS}"  MAGE_DB_PASS
echo
WHITETXT "Administrator and domain"
read -e -p "---> Enter your First Name: " -i "Name"  MAGE_ADMIN_FNAME
read -e -p "---> Enter your Last Name: " -i "Lastname"  MAGE_ADMIN_LNAME
read -e -p "---> Enter your email: " -i "admin@${MAGE_DOMAIN}"  MAGE_ADMIN_EMAIL
read -e -p "---> Enter your admins login name: " -i "admin"  MAGE_ADMIN_LOGIN
MAGE_ADMIN_PASSGEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 10 | head -n 1)
read -e -p "---> Use generated admin password: " -i "${MAGE_ADMIN_PASSGEN}${RANDOM}"  MAGE_ADMIN_PASS
read -e -p "---> Enter your shop url: " -i "http://${MAGE_DOMAIN}/"  MAGE_SITE_URL
echo
WHITETXT "Language, Currency and Timezone settings"
if [ "${MAGE_SEL_VER}" = "1" ]; then
MAGE_ADMIN_PATH_RANDOM=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z' | fold -w 6 | head -n 1)
updown_menu "$(curl -s ${REPO_MASCM_TMP}magento-locale | sort )" MAGE_LOCALE
updown_menu "$(curl -s ${REPO_MASCM_TMP}magento-currency | sort )" MAGE_CURRENCY
updown_menu "$(timedatectl list-timezones | sort )" MAGE_TIMEZONE
echo
echo
chmod u+x mage
su ${MAGE_WEB_USER} -s /bin/bash -c "./mage mage-setup ."
su ${MAGE_WEB_USER} -s /bin/bash -c "php -f install.php -- \
--license_agreement_accepted "yes" \
--locale "${MAGE_LOCALE}" \
--timezone "${MAGE_TIMEZONE}" \
--default_currency "${MAGE_CURRENCY}" \
--db_host "${MAGE_DB_HOST}" \
--db_name "${MAGE_DB_NAME}" \
--db_user "${MAGE_DB_USER_NAME}" \
--db_pass "${MAGE_DB_PASS}" \
--url "${MAGE_SITE_URL}" \
--use_rewrites "yes" \
--use_secure "no" \
--secure_base_url "" \
--skip_url_validation "yes" \
--use_secure_admin "no" \
--admin_frontname "admin_${MAGE_ADMIN_PATH_RANDOM}" \
--admin_firstname "${MAGE_ADMIN_FNAME}" \
--admin_lastname "${MAGE_ADMIN_LNAME}" \
--admin_email "${MAGE_ADMIN_EMAIL}" \
--admin_username "${MAGE_ADMIN_LOGIN}" \
--admin_password "${MAGE_ADMIN_PASS}""
    echo
    WHITETXT "============================================================================="
    echo
    GREENTXT "INSTALLED MAGENTO ${MAGE_SEL_VER} (${MAGE_VER}) WITHOUT SAMPLE DATA"
    echo
    WHITETXT "============================================================================="
    WHITETXT " MAGENTO ADMIN ACCOUNT"
    echo
    echo "---> Admin path: ${MAGE_SITE_URL}admin_${MAGE_ADMIN_PATH_RANDOM}"
    echo "---> Username: ${MAGE_ADMIN_LOGIN}"
    echo "---> Password: ${MAGE_ADMIN_PASS}"
    echo
    WHITETXT "============================================================================="
 echo
echo
	else
chmod u+x bin/magento
updown_menu "$(bin/magento info:language:list | sed "s/[|+-]//g" | awk 'NR > 3 {print $NF}' | sort )" MAGE_LOCALE
updown_menu "$(bin/magento info:currency:list | sed "s/[|+-]//g" | awk 'NR > 3 {print $NF}' | sort )" MAGE_CURRENCY
updown_menu "$(bin/magento info:timezone:list | sed "s/[|+-]//g" | awk 'NR > 3 {print $NF}' | sort )" MAGE_TIMEZONE
echo
echo
GREENTXT "SETUP MAGENTO ${MAGE_SEL_VER} (${MAGE_VER}) WITHOUT SAMPLE DATA"
echo
pause '---> Press [Enter] key to run setup'
echo
su ${MAGE_WEB_USER} -s /bin/bash -c "bin/magento setup:install --base-url=${MAGE_SITE_URL} \
--db-host=${MAGE_DB_HOST} \
--db-name=${MAGE_DB_NAME} \
--db-user=${MAGE_DB_USER_NAME} \
--db-password=${MAGE_DB_PASS} \
--admin-firstname=${MAGE_ADMIN_FNAME} \
--admin-lastname=${MAGE_ADMIN_LNAME} \
--admin-email=${MAGE_ADMIN_EMAIL} \
--admin-user=${MAGE_ADMIN_LOGIN} \
--admin-password=${MAGE_ADMIN_PASS} \
--language=${MAGE_LOCALE} \
--currency=${MAGE_CURRENCY} \
--timezone=${MAGE_TIMEZONE} \
--cleanup-database \
--session-save=files \
--use-rewrites=1"
fi

cat >> /root/mascm/.mascm_index <<END
mageadmin  ${MAGE_ADMIN_LOGIN}  ${MAGE_ADMIN_PASS}  ${MAGE_ADMIN_EMAIL}  ${MAGE_TIMEZONE}  ${MAGE_LOCALE} ${MAGE_ADMIN_PATH_RANDOM}
END

pause '------> Press [Enter] key to show menu'
printf "\033c"
;;
###################################################################################
#                                SYSTEM CONFIGURATION                             #
###################################################################################
"config")
printf "\033c"
MAGE_DOMAIN=$(awk '/webshop/ { print $2 }' /root/mascm/.mascm_index)
MAGE_WEB_ROOT_PATH=$(awk '/webshop/ { print $3 }' /root/mascm/.mascm_index)
MAGE_WEB_USER=$(awk '/webshop/ { print $4 }' /root/mascm/.mascm_index)
MAGE_WEB_USER_PASS=$(awk '/webshop/ { print $5 }' /root/mascm/.mascm_index)
MAGE_ADMIN_EMAIL=$(awk '/mageadmin/ { print $4 }' /root/mascm/.mascm_index)
MAGE_TIMEZONE=$(awk '/mageadmin/ { print $5 }' /root/mascm/.mascm_index)
MAGE_LOCALE=$(awk '/mageadmin/ { print $6 }' /root/mascm/.mascm_index)
MAGE_ADMIN_LOGIN=$(awk '/mageadmin/ { print $2 }' /root/mascm/.mascm_index)
MAGE_ADMIN_PASS=$(awk '/mageadmin/ { print $3 }' /root/mascm/.mascm_index)
MAGE_ADMIN_PATH_RANDOM=$(awk '/mageadmin/ { print $7 }' /root/mascm/.mascm_index)
MAGE_SEL_VER=$(awk '/webshop/ { print $6 }' /root/mascm/.mascm_index)
MAGE_VER=$(awk '/webshop/ { print $7 }' /root/mascm/.mascm_index)
MAGE_DB_HOST=$(awk '/database/ { print $2 }' /root/mascm/.mascm_index)
MAGE_DB_NAME=$(awk '/database/ { print $3 }' /root/mascm/.mascm_index)
MAGE_DB_USER_NAME=$(awk '/database/ { print $4 }' /root/mascm/.mascm_index)
MAGE_DB_PASS=$(awk '/database/ { print $5 }' /root/mascm/.mascm_index)
MYSQL_ROOT_PASS=$(awk '/database/ { print $6 }' /root/mascm/.mascm_index)
echo "-------------------------------------------------------------------------------------"
BLUEBG "| POST-INSTALLATION CONFIGURATION |"
echo "-------------------------------------------------------------------------------------"
echo
echo
GREENTXT "SERVER HOSTNAME SETTINGS"
hostnamectl set-hostname server.${MAGE_DOMAIN} --static
echo
GREENTXT "SERVER TIMEZONE SETTINGS"
timedatectl set-timezone ${MAGE_TIMEZONE}
echo
GREENTXT "HHVM AND PHP-FPM SETTINGS"
sed -i "s/\[www\]/\[${MAGE_WEB_USER}\]/" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s/user = www-data/user = ${MAGE_WEB_USER}/" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s/group = www-data/group = ${MAGE_WEB_USER}/" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s/listen.owner = www-data/listen.group = ${MAGE_WEB_USER}/" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s/listen.group = www-data/listen.group = ${MAGE_WEB_USER}/" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s/;listen.mode = 0660/listen.mode = 0660/" /etc/php/7.0/fpm/pool.d/www.conf
sed -i "s,session.save_handler = files,session.save_handler = redis," /etc/php/7.0/fpm/php.ini
sed -i 's,;session.save_path = "/var/lib/php/sessions",session.save_path = "tcp://127.0.0.1:6379",' /etc/php/7.0/fpm/php.ini
sed -i '/PHPSESSID/d' /etc/php/7.0/fpm/php.ini
sed -i "s,.*date.timezone.*,date.timezone = ${MAGE_TIMEZONE}," /etc/php/7.0/fpm/php.ini
sed -i '/sendmail_path/,$d' /etc/php/7.0/fpm/pool.d/www.conf

cat >> /etc/php/7.0/fpm/pool.d/www.conf <<END
;;
;; Custom pool settings
php_flag[display_errors] = off
php_admin_flag[log_errors] = on
php_admin_value[error_log] = ${MAGE_WEB_ROOT_PATH}/var/log/php-fpm-error.log
php_admin_value[memory_limit] = 1024M
php_admin_value[date.timezone] = ${MAGE_TIMEZONE}
END

sed -i "s/www-data/${MAGE_WEB_USER}/" /lib/systemd/system/hhvm.service
sed -i "s/daemon/server/" /lib/systemd/system/hhvm.service
sed -i "/.*hhvm.server.port.*/a hhvm.server.ip = 127.0.0.1" /etc/hhvm/server.ini
sed -i '/.*hhvm.jit_a_size.*/,$d' /etc/hhvm/server.ini
cat >> /etc/hhvm/server.ini <<END
session.save_handler = redis
session.save_path = "tcp://127.0.0.1:6379"
date.timezone = ${MAGE_TIMEZONE}
max_execution_time = 600
END
systemctl daemon-reload
systemctl restart hhvm >/dev/null 2>&1
echo
GREENTXT "NGINX SETTINGS"
wget -qO /etc/nginx/fastcgi_params  ${NGINX_BASE}magento${MAGE_SEL_VER}/fastcgi_params  >/dev/null 2>&1
wget -qO /etc/nginx/nginx.conf  ${NGINX_BASE}magento${MAGE_SEL_VER}/nginx.conf  >/dev/null 2>&1
mkdir -p /etc/nginx/sites-enabled
mkdir -p /etc/nginx/sites-available && cd $_
wget -q ${NGINX_BASE}magento${MAGE_SEL_VER}/sites-available/default.conf  >/dev/null 2>&1
wget -q ${NGINX_BASE}magento${MAGE_SEL_VER}/sites-available/magento${MAGE_SEL_VER}.conf  >/dev/null 2>&1
ln -s /etc/nginx/sites-available/magento${MAGE_SEL_VER}.conf /etc/nginx/sites-enabled/magento${MAGE_SEL_VER}.conf
ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf
mkdir -p /etc/nginx/conf_m${MAGE_SEL_VER} && cd /etc/nginx/conf_m${MAGE_SEL_VER}/
for CONFIG in ${NGINX_EXTRA_CONF}
do
wget -q ${NGINX_BASE}magento${MAGE_SEL_VER}/conf_m${MAGE_SEL_VER}/${CONFIG}  >/dev/null 2>&1
done
sed -i "s/user  nginx;/user  ${MAGE_WEB_USER};/" /etc/nginx/nginx.conf
sed -i "s/example.com/${MAGE_DOMAIN}/g" /etc/nginx/sites-available/magento${MAGE_SEL_VER}.conf
# Hack remove the www-redirect block:
sed -i -e '/\#\#.*www\sredirect.*/,+5d' /etc/nginx/sites-available/magento${MAGE_SEL_VER}.conf
# Hack. Remove the www-redirect coming from the orginal GIT
# sed -i '/return\s301.*/d' /etc/nginx/sites-available/magento${MAGE_SEL_VER}.conf
sed -i "s/example.com/${MAGE_DOMAIN}/g" /etc/nginx/nginx.conf
sed -i "s,/var/www/html,${MAGE_WEB_ROOT_PATH},g" /etc/nginx/sites-available/magento${MAGE_SEL_VER}.conf
# Hack: Deploy path fix in nginx's conf_m2/php_backend.conf:
sed -i "s/^fastcgi_pass.*$/fastcgi_pass   unix:\/run\/php\/php7.0-fpm.sock;/" /etc/nginx/conf_m${MAGE_SEL_VER}/php_backend.conf
    if [ "${MAGE_SEL_VER}" = "1" ]; then
    	MAGE_ADMIN_PATH=$(grep -Po '(?<=<frontName><!\[CDATA\[)\w*(?=\]\]>)' ${MAGE_WEB_ROOT_PATH}/app/etc/local.xml)
    	else
	MAGE_ADMIN_PATH=$(grep -Po "(?<='frontName' => ')\w*(?=')" ${MAGE_WEB_ROOT_PATH}/app/etc/env.php)
    fi
	sed -i "s/ADMIN_PLACEHOLDER/${MAGE_ADMIN_PATH}/" /etc/nginx/conf_m${MAGE_SEL_VER}/extra_protect.conf
echo
GREENTXT "PHPMYADMIN INSTALLATION AND CONFIGURATION"
     PMA_FOLDER=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)
     PMA_PASSWD=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)
     BLOWFISHCODE=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
     debconf-set-selections <<< "mysql-server mysql-server/root_password password $(cat /root/mascm/.mysql_pass)"
     debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $(cat /root/mascm/.mysql_pass)"
     debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
     debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-reinstall boolean true"
     debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-upgrade boolean true"
     debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-remove boolean true"
     debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password ${PMA_PASSWD}"
     debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password ${PMA_PASSWD}"
     debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password ${PMA_PASSWD}"
     debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none"
     apt-get install -y phpmyadmin  >/dev/null 2>&1
     USER_IP=$(echo $SSH_CLIENT | awk '{ print $1}')
     # USER_IP=$(ss -ant | grep -Po "(\d|\.)+:22\s+\K[^:]+")
     sed -i "s/.*blowfish_secret.*/\$cfg['blowfish_secret'] = '${BLOWFISHCODE}';/" /etc/phpmyadmin/config.inc.php
     sed -i "s/PHPMYADMIN_PLACEHOLDER/mysql_${PMA_FOLDER}/g" /etc/nginx/conf_m${MAGE_SEL_VER}/phpmyadmin.conf
     sed -i "5i satisfy any; \\
           allow ${USER_IP}/32; \\
           deny  all; \\
           auth_basic  \"please login\"; \\
           auth_basic_user_file .mysql;"  /etc/nginx/conf_m${MAGE_SEL_VER}/phpmyadmin.conf
# Hack. The config coming from authors GIT...
sed -i 's/phpMyAdmin/phpmyadmin/' /etc/nginx/conf_m2/phpmyadmin.conf
chown -R ${MAGE_WEB_USER}:${MAGE_WEB_USER} /usr/share/phpmyadmin
# ---- End of hack -------
     htpasswd -b -c /etc/nginx/.mysql mysql ${PMA_PASSWD}  >/dev/null 2>&1
     echo
cat >> /root/mascm/.mascm_index <<END
pma   mysql_${PMA_FOLDER}   mysql   ${PMA_PASSWD}
END
echo
GREENTXT "PROFTPD CONFIGURATION"
     wget -qO /etc/proftpd/proftpd.conf ${REPO_MASCM_TMP}proftpd.conf  >/dev/null 2>&1
     ## change proftpd config
     SERVER_IP_ADDR=$(ip route get 1 | awk '{print $NF;exit}')
     USER_IP=$(echo $SSH_CLIENT | awk '{ print $1}')
     #USER_IP=${SSH_CLIENT%% *}
     USER_GEOIP=$(geoiplookup ${USER_IP} | awk 'NR==1{print substr($4,1,2)}')
     FTP_PORT=$(shuf -i 5121-5132 -n 1)
     sed -i "s/server_sftp_port/${FTP_PORT}/" /etc/proftpd/proftpd.conf
     sed -i "s/server_ip_address/${SERVER_IP_ADDR}/" /etc/proftpd/proftpd.conf
     sed -i "s/client_ip_address/${USER_IP}/" /etc/proftpd/proftpd.conf
     sed -i "s/geoip_country_code/${USER_GEOIP}/" /etc/proftpd/proftpd.conf
     sed -i "s/sftp_domain/${MAGE_DOMAIN}/" /etc/proftpd/proftpd.conf
     sed -i "s/FTP_USER/${MAGE_WEB_USER}/" /etc/proftpd/proftpd.conf
     # A hack to fix the file coming from original GIT.
     sed -i '/^Group.*nobody.*/d' /etc/proftpd/proftpd.conf
     echo "127.0.0.1    $(hostname)" >> /etc/hosts
     echo
     systemctl daemon-reload
     /lib/systemd/systemd-sysv-install enable proftpd >/dev/null 2>&1
     /etc/init.d/proftpd restart
     echo
cat >> /root/mascm/.mascm_index <<END
proftpd   ${USER_GEOIP}   ${FTP_PORT}   ${MAGE_WEB_USER_PASS}
END
echo
if [ -f /lib/systemd/system/varnish.service ]; then
GREENTXT "VARNISH CACHE SETTINGS"
    sed -i "s/MAGE_WEB_USER/${MAGE_WEB_USER}/g"  /lib/systemd/system/varnish.service
	systemctl enable varnish.service >/dev/null 2>&1
    systemctl restart varnish.service
	YELLOWTXT "VARNISH CACHE PORT :8081"
fi
echo
GREENTXT "OPCACHE GUI, n98-MAGERUN, IMAGE OPTIMIZER, MYSQLTUNER, SSL DEBUG TOOLS"
     cd ${MAGE_WEB_ROOT_PATH}
     wget -qO tlstest_$(openssl rand 2 -hex).php ${REPO_MASCM_TMP}tlstest.php  >/dev/null 2>&1
     wget -qO wesley.pl ${REPO_MASCM_TMP}wesley.pl  >/dev/null 2>&1
     wget -qO mysqltuner.pl ${MYSQL_TUNER}  >/dev/null 2>&1
echo
echo
GREENTXT "LETSENCRYPT SSL CERTIFICATE REQUEST"
DNS_A_RECORD=$(getent hosts magento.cozy-apparel.online | awk '{ print $1 }')
SERVER_IP_ADDR=$(dig +short myip.opendns.com @resolver1.opendns.com)
if [ "${DNS_A_RECORD}" != "${SERVER_IP_ADDR}" ] ; then
    echo
    REDTXT "DNS A record and your servers IP address do not match"
	YELLOWTXT "Your servers ip address ${SERVER_IP_ADDR}"
	YELLOWTXT "Domain ${MAGE_DOMAIN} resolves to ${DNS_A_RECORD}"
	YELLOWTXT "Please change your DNS A record to this servers IP address, and run this command later: "
	if [ "${MAGE_SEL_VER}" = "1" ]; then
	WHITETXT "/usr/bin/certbot certonly --agree-tos --email ${MAGE_ADMIN_EMAIL} --webroot -w ${MAGE_WEB_ROOT_PATH} -d ${MAGE_DOMAIN}"
	else
	WHITETXT "/usr/bin/certbot certonly --agree-tos --email ${MAGE_ADMIN_EMAIL} --webroot -w ${MAGE_WEB_ROOT_PATH}/pub -d ${MAGE_DOMAIN}"
	fi
	echo
    else
    if [ "${MAGE_SEL_VER}" = "1" ]; then
    /usr/bin/certbot certonly --agree-tos --email ${MAGE_ADMIN_EMAIL} --webroot -w ${MAGE_WEB_ROOT_PATH} -d ${MAGE_DOMAIN}
    service nginx reload
    else
    /usr/bin/certbot certonly --agree-tos --email ${MAGE_ADMIN_EMAIL} --webroot -w ${MAGE_WEB_ROOT_PATH}/pub -d ${MAGE_DOMAIN}
    service nginx reload
    fi
 fi
echo '45 5 * * 1 root /usr/bin/certbot renew --quiet --post-hook "service nginx reload" >> /var/log/letsencrypt-renew.log' >> /etc/crontab
echo
GREENTXT "GENERATE DHPARAM FOR NGINX SSL"
openssl dhparam -dsaparam -out /etc/ssl/certs/dhparams.pem 4096 >/dev/null 2>&1
echo
GREENTXT "GENERATE DEFAULT NGINX SSL SERVER KEY/CERT"
openssl req -x509 -newkey rsa:4096 -sha256 -nodes -keyout /etc/ssl/certs/default_server.key -out /etc/ssl/certs/default_server.crt \
-subj "/CN=default_server" -days 3650 -subj "/C=US/ST=Oregon/L=Portland/O=default_server/OU=Org/CN=default_server" >/dev/null 2>&1
echo
GREENTXT "SIMPLE LOGROTATE SCRIPT FOR MAGENTO LOGS"
cat > /etc/logrotate.d/magento <<END
${MAGE_WEB_ROOT_PATH}/var/log/*.log
{
weekly
rotate 4
notifempty
missingok
compress
}
END
echo
GREENTXT "SERVICE STATUS WITH E-MAIL ALERTING"
wget -qO /lib/systemd/system/service-status-mail@.service ${REPO_MASCM_TMP}service-status-mail@.service  >/dev/null 2>&1
wget -qO /bin/service-status-mail.sh ${REPO_MASCM_TMP}service-status-mail.sh  >/dev/null 2>&1
sed -i "s/MAGEADMINEMAIL/${MAGE_ADMIN_EMAIL}/" /bin/service-status-mail.sh
sed -i "s/DOMAINNAME/${MAGE_DOMAIN}/" /bin/service-status-mail.sh
chmod u+x /bin/service-status-mail.sh
systemctl daemon-reload
echo
GREENTXT "REALTIME MALWARE MONITOR WITH E-MAIL ALERTING"
YELLOWTXT "warning: infected files will be moved to quarantine"
cd /usr/local/src
git clone https://github.com/rfxn/linux-malware-detect.git >/dev/null 2>&1
cd linux-malware-detect
./install.sh >/dev/null 2>&1

sed -i 's/email_alert="0"/email_alert="1"/' /usr/local/maldetect/conf.maldet
sed -i "s/you@domain.com/${MAGE_ADMIN_EMAIL}/" /usr/local/maldetect/conf.maldet
sed -i 's/quarantine_hits="0"/quarantine_hits="1"/' /usr/local/maldetect/conf.maldet
sed -i 's,# default_monitor_mode="/usr/local/maldetect/monitor_paths",default_monitor_mode="/usr/local/maldetect/monitor_paths",' /usr/local/maldetect/conf.maldet
sed -i 's/inotify_base_watches="16384"/inotify_base_watches="85384"/' /usr/local/maldetect/conf.maldet
echo -e "${MAGE_WEB_ROOT_PATH%/*}\n\n/var/tmp/\n\n/tmp/" > /usr/local/maldetect/monitor_paths

cp /usr/lib/systemd/system/maldet.service /lib/systemd/system/maldet.service
sed -i "/^After.*/a OnFailure=service-status-mail@%n.service" /lib/systemd/system/maldet.service
sed -i "/\[Install\]/i Restart=on-failure\nRestartSec=10\n" /lib/systemd/system/maldet.service
systemctl daemon-reload

echo "maldet --monitor /usr/local/maldetect/monitor_paths" >> /etc/rc.local
maldet --monitor /usr/local/maldetect/monitor_paths >/dev/null 2>&1
chmod u+x /etc/rc.local
echo
GREENTXT "GOACCESS REALTIME ACCESS LOG DASHBOARD"
cd /usr/local/src
git clone https://github.com/allinurl/goaccess.git >/dev/null 2>&1
cd goaccess
autoreconf -fi >/dev/null 2>&1
./configure --enable-utf8 --enable-geoip=legacy --with-openssl  >/dev/null 2>&1
make  >/dev/null 2>&1
make install  >/dev/null 2>&1
echo
GREENTXT "MAGENTO CRONJOBS"
if [ "${MAGE_SEL_VER}" = "1" ]; then
        echo "MAILTO=${MAGE_ADMIN_EMAIL}" >> magecron
        echo "* * * * * ! test -e ${MAGE_WEB_ROOT_PATH}/maintenance.flag && /bin/bash ${MAGE_WEB_ROOT_PATH}/cron.sh  > /dev/null" >> magecron
        echo "*/5 * * * * /bin/bash ${MAGE_WEB_ROOT_PATH}/cron_check.sh" >> magecron
        echo "5 8 * * 7 perl ${MAGE_WEB_ROOT_PATH}/mysqltuner.pl --nocolor 2>&1 | mailx -E -s \"MYSQLTUNER WEEKLY REPORT at ${HOSTNAME}\" ${MAGE_ADMIN_EMAIL}" >> magecron
	else
		echo "* * * * * php -c /etc/php/7.0/fpm/php.ini ${MAGE_WEB_ROOT_PATH}/bin/magento cron:run" >> magecron
		echo "* * * * * php -c /etc/php/7.0/fpm/php.ini ${MAGE_WEB_ROOT_PATH}/update/cron.php" >> magecron
		echo "* * * * * php -c /etc/php/7.0/fpm/php.ini ${MAGE_WEB_ROOT_PATH}/bin/magento setup:cron:run" >> magecron
		echo "*/5 * * * * /bin/bash ${MAGE_WEB_ROOT_PATH}/cron_check.sh" >> magecron
                echo "5 8 * * 7 perl ${MAGE_WEB_ROOT_PATH}/mysqltuner.pl --nocolor 2>&1 | mailx -E -s \"MYSQLTUNER WEEKLY REPORT at ${HOSTNAME}\" ${MAGE_ADMIN_EMAIL}" >> magecron
fi
crontab -u ${MAGE_WEB_USER} magecron
rm magecron
echo
GREENTXT "REDIS CACHE AND SESSION STORAGE"
if [ "${MAGE_SEL_VER}" = "1" ]; then
sed -i '/<session_save>/d' ${MAGE_WEB_ROOT_PATH}/app/etc/local.xml
sed -i '/<global>/ a\
 <session_save>db</session_save> \
	<redis_session> \
	<host>127.0.0.1</host> \
	<port>6379</port> \
	<password></password> \
	<timeout>10</timeout> \
	<persistent><![CDATA[db1]]></persistent> \
	<db>1</db> \
	<compression_threshold>2048</compression_threshold> \
	<compression_lib>lzf</compression_lib> \
	<log_level>1</log_level> \
	<max_concurrency>64</max_concurrency> \
	<break_after_frontend>5</break_after_frontend> \
	<break_after_adminhtml>30</break_after_adminhtml> \
	<first_lifetime>600</first_lifetime> \
	<bot_first_lifetime>60</bot_first_lifetime> \
	<bot_lifetime>7200</bot_lifetime> \
	<disable_locking>0</disable_locking> \
	<min_lifetime>86400</min_lifetime> \
	<max_lifetime>2592000</max_lifetime> \
    </redis_session> \
    <cache> \
        <backend>Cm_Cache_Backend_Redis</backend> \
        <backend_options> \
          <default_priority>10</default_priority> \
          <auto_refresh_fast_cache>1</auto_refresh_fast_cache> \
            <server>127.0.0.1</server> \
            <port>6380</port> \
            <persistent><![CDATA[db1]]></persistent> \
            <database>1</database> \
            <password></password> \
            <force_standalone>0</force_standalone> \
            <connect_retries>1</connect_retries> \
            <read_timeout>10</read_timeout> \
            <automatic_cleaning_factor>0</automatic_cleaning_factor> \
            <compress_data>1</compress_data> \
            <compress_tags>1</compress_tags> \
            <compress_threshold>204800</compress_threshold> \
            <compression_lib>lzf</compression_lib> \
        </backend_options> \
    </cache>' ${MAGE_WEB_ROOT_PATH}/app/etc/local.xml

    sed -i "s/false/true/" ${MAGE_WEB_ROOT_PATH}/app/etc/modules/Cm_RedisSession.xml
echo
GREENTXT "DISABLE MAGENTO DATABASE LOGGING"
echo
sed -i '/<\/admin>/ a\
<frontend> \
        <events> \
            <controller_action_predispatch> \
            <observers><log><type>disabled</type></log></observers> \
            </controller_action_predispatch> \
            <controller_action_postdispatch> \
            <observers><log><type>disabled</type></log></observers> \
            </controller_action_postdispatch> \
            <customer_login> \
            <observers><log><type>disabled</type></log></observers> \
            </customer_login> \
            <customer_logout> \
            <observers><log><type>disabled</type></log></observers> \
            </customer_logout> \
            <sales_quote_save_after> \
            <observers><log><type>disabled</type></log></observers> \
            </sales_quote_save_after> \
            <checkout_quote_destroy> \
            <observers><log><type>disabled</type></log></observers> \
            </checkout_quote_destroy> \
        </events> \
</frontend>' ${MAGE_WEB_ROOT_PATH}/app/etc/local.xml
echo
	else
sed -i -e '/session/{n;N;N;d}' ${MAGE_WEB_ROOT_PATH}/app/etc/env.php
sed -i "/.*session.*/a \\
   array ( \\
   'save' => 'redis', \\
   'redis' => \\
      array ( \\
        'host' => '127.0.0.1', \\
        'port' => '6379', \\
        'password' => '', \\
        'timeout' => '5', \\
        'persistent_identifier' => 'db1', \\
        'database' => '1', \\
        'compression_threshold' => '2048', \\
        'compression_library' => 'lzf', \\
        'log_level' => '1', \\
        'max_concurrency' => '6', \\
        'break_after_frontend' => '5', \\
        'break_after_adminhtml' => '30', \\
        'first_lifetime' => '600', \\
        'bot_first_lifetime' => '60', \\
        'bot_lifetime' => '7200', \\
        'disable_locking' => '0', \\
        'min_lifetime' => '60', \\
        'max_lifetime' => '2592000' \\
    ), \\
), \\
'cache' =>  \\
  array ( \\
    'frontend' =>  \\
    array ( \\
      'default' =>  \\
      array ( \\
        'backend' => 'Cm_Cache_Backend_Redis', \\
        'backend_options' =>  \\
        array ( \\
          'server' => '127.0.0.1', \\
          'port' => '6380', \\
          'persistent' => '', \\
          'database' => '1', \\
          'force_standalone' => '0', \\
          'connect_retries' => '2', \\
          'read_timeout' => '10', \\
          'automatic_cleaning_factor' => '0', \\
          'compress_data' => '0', \\
          'compress_tags' => '0', \\
          'compress_threshold' => '20480', \\
          'compression_lib' => 'lzf', \\
        ), \\
      ), \\
      'page_cache' =>  \\
      array ( \\
        'backend' => 'Cm_Cache_Backend_Redis', \\
        'backend_options' =>  \\
        array ( \\
          'server' => '127.0.0.1', \\
          'port' => '6380', \\
          'persistent' => '', \\
          'database' => '2', \\
          'force_standalone' => '0', \\
          'connect_retries' => '2', \\
          'read_timeout' => '10', \\
          'automatic_cleaning_factor' => '0', \\
          'compress_data' => '1', \\
          'compress_tags' => '1', \\
          'compress_threshold' => '20480', \\
          'compression_lib' => 'lzf', \\
        ), \\
      ), \\
    ), \\
  ), \\ " ${MAGE_WEB_ROOT_PATH}/app/etc/env.php
fi
echo
systemctl daemon-reload
systemctl restart nginx.service
systemctl restart php7.0-fpm.service
systemctl restart redis-6379.service
systemctl restart redis-6380.service

cd ${MAGE_WEB_ROOT_PATH}
chown -R ${MAGE_WEB_USER}:${MAGE_WEB_USER} ${MAGE_WEB_ROOT_PATH%/*}
GREENTXT "OPCACHE INVALIDATION MONITOR"
OPCACHE_FILE=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z' | fold -w 12 | head -n 1)
if [ "${MAGE_SEL_VER}" = "1" ]; then
wget -qO ${MAGE_WEB_ROOT_PATH}/${OPCACHE_FILE}_opcache_gui.php https://raw.githubusercontent.com/magenx/opcache-gui/master/index.php  >/dev/null 2>&1
else
wget -qO ${MAGE_WEB_ROOT_PATH}/pub/${OPCACHE_FILE}_opcache_gui.php https://raw.githubusercontent.com/magenx/opcache-gui/master/index.php  >/dev/null 2>&1
fi
cat > ${MAGE_WEB_ROOT_PATH}/zend_opcache.sh <<END
#!/bin/bash
## monitor magento folder and invalidate opcache
/usr/bin/inotifywait -e modify,move \\
    -mrq --timefmt %a-%b-%d-%T --format '%w%f %T' \\
    --excludei '/(cache|log|session|report|locks|media|skin|tmp)/|\.(xml|html?|css|js|gif|jpe?g|png|ico|te?mp|txt|csv|swp|sql|t?gz|zip|svn?g|git|log|ini|sh|pl)~?' \\
    ${MAGE_WEB_ROOT_PATH}/ | while read line; do
    echo "\$line " >> /var/log/zend_opcache_monitor.log
    FILE=\$(echo \${line} | cut -d' ' -f1 | sed -e 's/\/\./\//g' | cut -f1-2 -d'.')
    TARGETEXT="(php|phtml)"
    EXTENSION="\${FILE##*.}"
  if [[ "\$EXTENSION" =~ \$TARGETEXT ]];
    then
    su ${MAGE_WEB_USER} -s /bin/bash -c "curl --cookie 'varnish_bypass=1' --silent http://${MAGE_DOMAIN}/${OPCACHE_FILE}_opcache_gui.php?page=invalidate&file=\${FILE} >/dev/null 2>&1"
  fi
done
END
echo
if [ "${MAGE_SEL_VER}" = "1" ]; then
su ${MAGE_WEB_USER} -s /bin/bash -c "mkdir -p var/log"
curl -s -o n98-magerun.phar https://files.magerun.net/n98-magerun.phar
rm -rf index.php.sample LICENSE_AFL.txt LICENSE.html LICENSE.txt RELEASE_NOTES.txt php.ini.sample dev
GREENTXT "CLEANING UP INDEXES LOCKS AND RUNNING RE-INDEX ALL"
echo
rm -rf  ${MAGE_WEB_ROOT_PATH}/var/locks/*
su ${MAGE_WEB_USER} -s /bin/bash -c "php ${MAGE_WEB_ROOT_PATH}/shell/indexer.php --reindexall"
echo
	else
GREENTXT "DISABLE MAGENTO CACHE AND ENABLE DEVELOPER MODE"
rm -rf var/*
su ${MAGE_WEB_USER} -s /bin/bash -c "php bin/magento deploy:mode:set developer"
su ${MAGE_WEB_USER} -s /bin/bash -c "php bin/magento cache:flush"
su ${MAGE_WEB_USER} -s /bin/bash -c "php bin/magento cache:disable"
sed -i "s/report/report|${OPCACHE_FILE}_opcache_gui/" /etc/nginx/sites-available/magento2.conf
systemctl restart php7.0-fpm.service
echo
curl -s -o n98-magerun2.phar https://files.magerun.net/n98-magerun2.phar
chmod u+x bin/magento
GREENTXT "SAVING COMPOSER JSON AND LOCK"
cp composer.json ../composer.json.saved
cp composer.lock ../composer.lock.saved
fi
echo
GREENTXT "IMAGES OPTIMIZATION SCRIPT"
echo
cat >> ${MAGE_WEB_ROOT_PATH}/optimages.sh <<END
#!/bin/bash
## monitor media folder and optimize new images
/usr/bin/inotifywait -e create \\
    -mrq --timefmt %a-%b-%d-%T --format '%w%f %T' \\
    --excludei '\.(xml|php|phtml|html?|css|js|ico|te?mp|txt|csv|swp|sql|t?gz|zip|svn?g|git|log|ini|opt|prog|crush)~?' \\
    ${MAGE_WEB_ROOT_PATH}/pub/media | while read line; do
    echo "\${line} " >> ${MAGE_WEB_ROOT_PATH}/var/log/images_optimization.log
    FILE=\$(echo \${line} | cut -d' ' -f1)
    TARGETEXT="(jpg|jpeg|png|gif)"
    EXTENSION="\${FILE##*.}"
  if [[ "\${EXTENSION}" =~ \${TARGETEXT} ]];
    then
   su ${MAGE_WEB_USER} -s /bin/bash -c "${MAGE_WEB_ROOT_PATH}/wesley.pl \${FILE} >/dev/null 2>&1"
  fi
done
END
cat >> ${MAGE_WEB_ROOT_PATH}/cron_check.sh <<END
#!/bin/bash
pgrep optimages.sh > /dev/null || ${MAGE_WEB_ROOT_PATH}/optimages.sh &
pgrep zend_opcache.sh > /dev/null || ${MAGE_WEB_ROOT_PATH}/zend_opcache.sh &
END
echo
GREENTXT "FIXING PERMISSIONS"
chown -R ${MAGE_WEB_USER}:${MAGE_WEB_USER} ${MAGE_WEB_ROOT_PATH}
find . -type f -exec chmod 660 {} \;
find . -type d -exec chmod 2770 {} \;
chmod u+x wesley.pl mysqltuner.pl cron_check.sh zend_opcache.sh optimages.sh
echo
echo
echo "===========================  INSTALLATION LOG  ======================================"
echo
echo
WHITETXT "[shop domain]: ${MAGE_DOMAIN}"
WHITETXT "[webroot path]: ${MAGE_WEB_ROOT_PATH}"
WHITETXT "[admin path]: ${MAGE_DOMAIN}/${MAGE_ADMIN_PATH}"
WHITETXT "[admin name]: ${MAGE_ADMIN_LOGIN}"
WHITETXT "[admin pass]: ${MAGE_ADMIN_PASS}"
echo
WHITETXT "[phpmyadmin url]: ${MAGE_DOMAIN}/mysql_${PMA_FOLDER}"
WHITETXT "[phpmyadmin http auth name]: mysql"
WHITETXT "[phpmyadmin http auth pass]: ${PMA_PASSWD}"
echo
WHITETXT "[mysql host]: ${MAGE_DB_HOST}"
WHITETXT "[mysql user]: ${MAGE_DB_USER_NAME}"
WHITETXT "[mysql pass]: ${MAGE_DB_PASS}"
WHITETXT "[mysql database]: ${MAGE_DB_NAME}"
WHITETXT "[mysql root pass]: ${MYSQL_ROOT_PASS}"
echo
WHITETXT "[ftp port]: ${FTP_PORT}"
WHITETXT "[ftp user]: ${MAGE_WEB_USER}"
WHITETXT "[ftp password]: ${MAGE_WEB_USER_PASS}"
WHITETXT "[ftp geoip]: ${USER_GEOIP}"
WHITETXT "[ftp ip login]: ${USER_IP}"
echo
WHITETXT "[opcache gui]: ${OPCACHE_FILE}_opcache_gui.php"
echo
echo
echo "===========================  INSTALLATION LOG  ======================================"
echo
# usermod -G apache ${MAGE_WEB_USER}
echo "-------------------------------------------------------------------------------------"
BLUEBG "| POST-INSTALLATION CONFIGURATION IS COMPLETED |"
echo "-------------------------------------------------------------------------------------"
echo
pause '---> Press [Enter] key to show menu'
;;
###################################################################################
#                          INSTALLING CSF FIREWALL                                #
###################################################################################
"firewall")
WHITETXT "============================================================================="
echo
MAGE_DOMAIN=$(awk '/webshop/ { print $2 }' /root/mascm/.mascm_index)
MAGE_ADMIN_EMAIL=$(awk '/mageadmin/ { print $4 }' /root/mascm/.mascm_index)
YELLOWTXT "If you are going to use services like CloudFlare - install Fail2Ban"
echo
echo -n "---> Would you like to install CSF firewall(y) or Fail2Ban(n)? [y/n][n]:"
read csf_test
if [ "${csf_test}" == "y" ];then
           echo
               GREENTXT "DOWNLOADING CSF FIREWALL"
               echo
               cd /usr/local/src/
               echo -n "     PROCESSING  "
               quick_progress &
               pid="$!"
               wget -qO - https://download.configserver.com/csf.tgz | tar -xz  >/dev/null 2>&1
               stop_progress "$pid"
               echo
               cd csf
               GREENTXT "NEXT, TEST IF YOU HAVE THE REQUIRED IPTABLES MODULES"
               echo
           if perl csftest.pl | grep "FATAL" ; then
               perl csftest.pl
               echo
               REDTXT "CSF FILERWALL HAS FATAL ERRORS INSTALL FAIL2BAN INSTEAD"
               echo -n "     PROCESSING  "
               quick_progress &
               pid="$!"
               apt install -y fail2ban >/dev/null 2>&1
               stop_progress "$pid"
               echo
               GREENTXT "FAIL2BAN HAS BEEN INSTALLED OK"
               echo
               pause '---> Press [Enter] key to show menu'
           else
               echo
               GREENTXT "CSF FIREWALL INSTALLATION"
               echo
               echo -n "     PROCESSING  "
               quick_progress &
               pid="$!"
               sh install.sh
               stop_progress "$pid"
               echo
               GREENTXT "CSF FIREWALL HAS BEEN INSTALLED OK"
                   echo
                   YELLOWTXT "Add ip addresses to whitelist/ignore (paypal,api,erp,backup,github,etc)"
                   echo
                   read -e -p "---> Enter ip address/cidr each after space: " -i "173.0.80.0/20 64.4.244.0/21 " IP_ADDR_IGNORE
                   for ip_addr_ignore in ${IP_ADDR_IGNORE}; do csf -a ${ip_addr_ignore}; done
                   ### csf firewall optimization
                   sed -i 's/^TESTING = "1"/TESTING = "0"/' /etc/csf/csf.conf
                   sed -i 's/^CT_LIMIT =.*/CT_LIMIT = "300"/' /etc/csf/csf.conf
                   sed -i 's/^CT_INTERVAL =.*/CT_INTERVAL = "30"/' /etc/csf/csf.conf
                   sed -i 's/^PS_INTERVAL =.*/PS_INTERVAL = "120"/' /etc/csf/csf.conf
                   sed -i 's/^PS_LIMIT =.*/PS_LIMIT = "10"/' /etc/csf/csf.conf
                   sed -i 's/^LF_WEBMIN =.*/LF_WEBMIN = "5"/' /etc/csf/csf.conf
                   sed -i 's/^LF_WEBMIN_EMAIL_ALERT =.*/LF_WEBMIN_EMAIL_ALERT = "1"/' /etc/csf/csf.conf
                   sed -i "s/^LF_ALERT_TO =.*/LF_ALERT_TO = \"${MAGE_ADMIN_EMAIL}\"/" /etc/csf/csf.conf
                   sed -i "s/^LF_ALERT_FROM =.*/LF_ALERT_FROM = \"firewall@${MAGE_DOMAIN}\"/" /etc/csf/csf.conf
                   sed -i 's/^DENY_IP_LIMIT =.*/DENY_IP_LIMIT = "50000"/' /etc/csf/csf.conf
                   sed -i 's/^DENY_TEMP_IP_LIMIT =.*/DENY_TEMP_IP_LIMIT = "200"/' /etc/csf/csf.conf
                   sed -i 's/^LF_IPSET =.*/LF_IPSET = "1"/' /etc/csf/csf.conf
                   ### this line will block every blacklisted ip address
                   sed -i "/|0|/s/^#//g" /etc/csf/csf.blocklists
        csf -r
    fi
    else
    echo
    GREENTXT "FAIL2BAN INSTALLATION"
    echo
    echo -n "     PROCESSING  "
    quick_progress &
    pid="$!"
    apt-get install -y fail2ban >/dev/null 2>&1
    stop_progress "$pid"
    echo
    GREENTXT "FAIL2BAN HAS BEEN INSTALLED OK"
    echo
fi
echo
echo
pause '---> Press [Enter] key to show menu'
;;
###################################################################################
#                               WEBMIN HERE YOU GO                                #
###################################################################################
"webmin")
echo
echo -n "---> Start the Webmin Control Panel installation? [y/n][n]:"
read webmin_install
if [ "${webmin_install}" == "y" ];then
          echo
            GREENTXT "Installation of Webmin package:"
wget http://www.webmin.com/download/deb/webmin-current.deb  >/dev/null 2>&1
            echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            dpkg --install webmin-current.deb >/dev/null 2>&1
            # Add missing dependencies for webmin
            apt-get -f install -y  >/dev/null 2>&1
            stop_progress "$pid"
            dpkg-query -l webmin
      if [ "$?" = 0 ]
        then
          echo
            GREENTXT "WEBMIN HAS BEEN INSTALLED  -  OK"
            echo
            WEBMIN_PORT=$(shuf -i 17556-17728 -n 1)
            sed -i 's/theme=gray-theme/theme=authentic-theme/' /etc/webmin/config
            sed -i 's/preroot=gray-theme/preroot=authentic-theme/' /etc/webmin/miniserv.conf
            sed -i "s/port=10000/port=${WEBMIN_PORT}/" /etc/webmin/miniserv.conf
            sed -i "s/listen=10000/listen=${WEBMIN_PORT}/" /etc/webmin/miniserv.conf
            ## nginx module
            cd /usr/local/src/
            wget -q ${WEBMIN_NGINX} -O webmin_nginx  >/dev/null 2>&1
            perl /usr/libexec/webmin/install-module.pl $_ >/dev/null 2>&1
            if [ -f "/usr/local/csf/csfwebmin.tgz" ]
				then
				perl /usr/libexec/webmin/install-module.pl /usr/local/csf/csfwebmin.tgz >/dev/null 2>&1
				GREENTXT "INSTALLED CSF FIREWALL PLUGIN"
    		else
				cd /usr/local/src
				wget -q ${WEBMIN_FAIL2BAN} -O fail2ban.wbm.gz
				perl /usr/libexec/webmin/install-module.pl $_ >/dev/null 2>&1
				GREENTXT "INSTALLED FAIL2BAN PLUGIN"
            fi
            sed -i 's/root/webadmin/' /etc/webmin/miniserv.users
            sed -i 's/root:/webadmin:/' /etc/webmin/webmin.acl
            WEBADMIN_PASS=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
            /usr/libexec/webmin/changepass.pl /etc/webmin/ webadmin ${WEBADMIN_PASS} >/dev/null 2>&1
          #  chkconfig webmin on >/dev/null 2>&1
            service webmin restart  >/dev/null 2>&1
            YELLOWTXT "Access Webmin on port: ${WEBMIN_PORT}"
            YELLOWTXT "User: webadmin , Password: ${WEBADMIN_PASS}"
            REDTXT "PLEASE ENABLE TWO-FACTOR AUTHENTICATION!"
               else
              echo
            REDTXT "WEBMIN INSTALLATION ERROR"
      fi
        else
          echo
            YELLOWTXT "Webmin installation was skipped by the user. Next step"
fi
echo
echo
pause '---> Press [Enter] key to show menu'
;;
###################################################################################
#                          INSTALLING OSSEC ELK STACK                             #
###################################################################################
"ossec")
WHITETXT "============================================================================="
echo
GREENTXT "INSTALLATION OF WAZUH 2.0 (OSSEC) + ELK 5.3.0 STACK:"
echo
GREENTXT "INSTALLATION OF WAZUH MANAGER"
apt-get install -y curl apt-transport-https lsb-release  >/dev/null 2>&1
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | apt-key add -
CODENAME=$(lsb_release -cs)
echo "deb https://packages.wazuh.com/apt ${CODENAME} main" | tee /etc/apt/sources.list.d/wazuh.list
apt-get update -y  >/dev/null 2>&1
apt-get install -y wazuh-manager  >/dev/null 2>&1
echo
GREENTXT "INSTALLATION OF WAZUH API + NODEJS"
curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash - >/dev/null 2>&1
apt-get install -y nodejs  >/dev/null 2>&1
apt-get install -y wazuh-api  >/dev/null 2>&1
echo
GREENTXT "INSTALLATION OF JAVA 8 JDK:"
apt-get install -y python-software-properties  >/dev/null 2>&1
add-apt-repository -y ppa:webupd8team/java  >/dev/null 2>&1
apt-get update -y  >/dev/null 2>&1
apt-get install -y oracle-java8-installer
export JAVA_HOME=/usr/lib/jvm/java-8-oracle/jre
echo "export JAVA_HOME=/usr/lib/jvm/java-8-oracle/jre" > /etc/profile
echo
echo
GREENTXT "INSTALLATION OF ELASTCSEARCH:"
echo
curl -s https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add -
apt-get install apt-transport-https  >/dev/null 2>&1
echo "deb https://artifacts.elastic.co/packages/5.x/apt stable main" | tee /etc/apt/sources.list.d/elastic-5.x.list
apt-get update -y  >/dev/null 2>&1
apt-get install -y elasticsearch >/dev/null 2>&1
echo
sed -i "s/.*cluster.name.*/cluster.name: wazuh/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/.*node.name.*/node.name: wazuh-node1/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/.*network.host.*/network.host: 127.0.0.1/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/.*http.port.*/http.port: 9200/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/-Xms2g/-Xms512m/" /etc/elasticsearch/jvm.options
sed -i "s/-Xmx2g/-Xmx512m/" /etc/elasticsearch/jvm.options
chown -R :elasticsearch /etc/elasticsearch/*
systemctl daemon-reload
systemctl enable elasticsearch.service
systemctl start elasticsearch.service
echo
echo
sleep 15
GREENTXT "INSTALLATION OF PACKETBEAT:"
apt-get install -y packetbeat-5.3.0  >/dev/null 2>&1
/usr/share/packetbeat/scripts/import_dashboards
echo
echo
GREENTXT "INSTALLATION OF LOGSTASH:"
apt-get install -y logstash  >/dev/null 2>&1
curl -so /etc/logstash/conf.d/01-wazuh.conf https://raw.githubusercontent.com/wazuh/wazuh/master/extensions/logstash/01-wazuh.conf
curl -so /etc/logstash/wazuh-elastic5-template.json https://raw.githubusercontent.com/wazuh/wazuh/master/extensions/elasticsearch/wazuh-elastic5-template.json
usermod -a -G ossec logstash
sed -i "1,11d" /etc/logstash/conf.d/01-wazuh.conf
sed -i "/elastic2/d" /etc/logstash/conf.d/01-wazuh.conf
sed -i "s/^#//g" /etc/logstash/conf.d/01-wazuh.conf
systemctl daemon-reload
systemctl enable logstash.service
systemctl start logstash.service
echo
echo
GREENTXT "INSTALLATION OF KIBANA:"
apt-get install -y kibana  >/dev/null 2>&1
/usr/share/kibana/bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp.zip
echo
systemctl daemon-reload
systemctl enable kibana.service
systemctl restart kibana.service
echo
echo
apt-mark hold elasticsearch logstash kibana packetbeat wazuh-manager wazuh-api
GREENTXT "OSSEC WAZUH API SETTINGS"
sed -i 's/.*config.host.*/config.host = "127.0.0.1";/' /var/ossec/api/configuration/config.js
echo
MAGE_DOMAIN=$(awk '/webshop/ { print $2 }' /root/mascm/.mascm_index)
KIBANA_PORT=$(shuf -i 10322-10539 -n 1)
USER_IP=${SSH_CLIENT%% *}
KIBANA_PASSWD=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)
WAZUH_API_PASSWD=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 6 | head -n 1)
htpasswd -b -c /etc/nginx/.wazuh wazuh-web ${KIBANA_PASSWD}  >/dev/null 2>&1
cd /var/ossec/api/configuration/auth
htpasswd -b -c user wazuh-api ${WAZUH_API_PASSWD}  >/dev/null 2>&1
systemctl restart wazuh-api
touch /etc/nginx/sites-available/kibana.conf
cat > /etc/nginx/sites-available/kibana.conf <<END
server {
  listen ${KIBANA_PORT} ssl http2;
  server_name           ${MAGE_DOMAIN};
  access_log            /var/log/nginx/access.log;

  ## SSL CONFIGURATION
	#ssl_certificate     /etc/letsencrypt/live/${MAGE_DOMAIN}/fullchain.pem;
	#ssl_certificate_key /etc/letsencrypt/live/${MAGE_DOMAIN}/privkey.pem;

    satisfy all;
    allow "${USER_IP}""/32;
    deny  all;
    auth_basic  "blackhole";
    auth_basic_user_file .ossec;

       location / {
               proxy_pass http://127.0.0.1:5601;
       }
}
END
echo
cd /etc/nginx/sites-enabled/
ln -s /etc/nginx/sites-available/kibana.conf kibana.conf
service nginx reload
echo
YELLOWTXT "KIBANA WEB INTERFACE PORT: ${KIBANA_PORT}"
YELLOWTXT "KIBANA HTTP AUTH: wazuh-web ${KIBANA_PASSWD}"
echo
YELLOWTXT "WAZUH API AUTH: wazuh-api ${WAZUH_API_PASSWD}"
echo
pause '---> Press [Enter] key to show menu'
;;
"exit")
REDTXT "------> EXIT"
exit
;;
###################################################################################
#                               MENU DEFAULT CATCH ALL                            #
###################################################################################
*)
printf "\033c"
;;
esac
done
