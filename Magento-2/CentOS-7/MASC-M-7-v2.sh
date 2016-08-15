#!/bin/bash
#====================================================================#
#  MagenX - Automated Server Configuration for Magento v2            #
#    Copyright (C) 2016 admin@magenx.com                             #
#       All rights reserved.                                         #
#====================================================================#
SELF=$(basename $0)
MASCM_VER="14.1"
MASCM_BASE="https://masc.magenx.com"

### DEFINE LINKS AND PACKAGES STARTS ###

# Software versions
MAGENTO_VER="2.1.0"
#MAGENTO_VER=$(curl -s https://api.github.com/repos/magento/magento2/releases 2>&1 | head -12 | grep 'tag_name' | grep -oP '(?<=")\d.*(?=")')
REPO_MAGENTO="composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition"

REPO_MASCM_TMP="https://raw.githubusercontent.com/magenx/Magento-Automated-Server-Configuration-from-MagenX/master/tmp/"
STATUS_ALERT_SERVICE="https://raw.githubusercontent.com/magenx/Magento-Automated-Server-Configuration-from-MagenX/master/tmp/service-status-mail%40.service"
STATUS_ALERT_SCRIPT="https://raw.githubusercontent.com/magenx/Magento-Automated-Server-Configuration-from-MagenX/master/tmp/service-status-mail.sh"

# Webmin Control Panel Nginx plugin
WEBMIN_NGINX="https://github.com/magenx/webmin-nginx/archive/nginx-0.08.wbm__0.tar.gz"

# Repositories
REPO_PERCONA="http://www.percona.com/redir/downloads/percona-release/redhat/latest/percona-release-0.1-3.noarch.rpm"
REPO_REMI="http://rpms.famillecollet.com/enterprise/remi-release-7.rpm"
REPO_FAN="http://www.city-fan.org/ftp/contrib/yum-repo/city-fan.org-release-1-13.rhel7.noarch.rpm"

# WebStack Packages
EXTRA_PACKAGES="dejavu-fonts-common dejavu-sans-fonts libtidy recode boost tbb lz4 libyaml libdwarf bind-utils e2fsprogs svn gcc iptraf inotify-tools net-tools mcrypt mlocate goaccess unzip vim wget curl sudo bc mailx clamav-filesystem clamav-server clamav-update clamav-milter-systemd clamav-data clamav-server-systemd clamav-scanner-systemd clamav clamav-milter clamav-lib clamav-scanner proftpd logrotate git patch ipset strace rsyslog gifsicle ncurses-devel GeoIP GeoIP-devel GeoIP-update ImageMagick libjpeg-turbo-utils pngcrush lsof net-snmp net-snmp-utils xinetd python-pip ncftp postfix certbot yum-cron sysstat attr iotop"
PHP_PACKAGES=(cli common fpm opcache gd curl mbstring bcmath soap mcrypt mysqlnd pdo xml xmlrpc intl gmp php-gettext phpseclib recode symfony-class-loader symfony-common tcpdf tcpdf-dejavu-sans-fonts tidy udan11-sql-parser) 
PHP_PECL_PACKAGES=(pecl-redis pecl-lzf pecl-geoip pecl-zip pecl-memcache)
PERCONA_PACKAGES=(client-56 server-56)
PERL_MODULES=(libwww-perl Template-Toolkit Time-HiRes ExtUtils-CBuilder ExtUtils-MakeMaker TermReadKey DBI DBD-MySQL Digest-HMAC Digest-SHA1 Test-Simple Moose Net-SSLeay)

# Nginx extra configuration
NGINX_BASE="https://raw.githubusercontent.com/magenx/Magento-nginx-config/master/magento2/"
NGINX_EXTRA_CONF="assets.conf error_page.conf extra_protect.conf status.conf setup.conf hhvm.conf php_backend.conf phpmyadmin.conf maintenance.conf multishop.conf spider.conf"
NGINX_EXTRA_CONF_URL="https://raw.githubusercontent.com/magenx/Magento-nginx-config/master/magento2/conf_m2/"

# Debug Tools
MYSQL_TUNER="https://raw.githubusercontent.com/major/MySQLTuner-perl/master/mysqltuner.pl"
MYSQL_TOP="https://launchpad.net/ubuntu/+archive/primary/+files/mytop_1.9.1.orig.tar.gz"

# Malware detector
MALDET="http://www.rfxn.com/downloads/maldetect-current.tar.gz"

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
echo -e "\n---> Use up/down arrow keys then press enter to select $2"
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
        echo -e "\n---> Use up/down arrow keys then press enter to select $2"
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
host1=74.125.24.106
host2=208.80.154.225
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
        MD5_NEW=$(curl -sL ${MASCM_BASE} > MASCM_NEW && md5sum MASCM_NEW | awk '{print $1}')
        MD5_OLD=$(md5sum ${SELF} | awk '{print $1}')
            if [[ "${MD5_NEW}" == "${MD5_OLD}" ]]; then
            GREENTXT "PASS: INTEGRITY CHECK FOR '${SELF}' OK"
            rm MASCM_NEW
            elif [[ "${MD5_NEW}" != "${MD5_OLD}" ]]; then
            echo
            YELLOWTXT "INTEGRITY CHECK FOR '${SELF}'"
            YELLOWTXT "DETECTED DIFFERENT MD5 CHECKSUM"
            YELLOWTXT "REMOTE REPOSITORY FILE HAS SOME CHANGES"
            REDTXT "IF YOU HAVE LOCAL CHANGES - SKIP UPDATES"
            echo
                echo -n "---> Would you like to update the file now?  [y/n][y]:"
		read update_agree
		if [ "${update_agree}" == "y" ];then
		mv MASCM_NEW ${SELF}
		echo
                GREENTXT "THE FILE HAS BEEN UPGRADED, PLEASE RUN IT AGAIN"
		echo
                exit 1
            else
        echo
        YELLOWTXT "NEW FILE SAVED TO MASCM_NEW"
        echo
  fi
fi

# do we have CentOS 7?
if grep "CentOS.* 7\." /etc/centos-release  > /dev/null 2>&1; then
  GREENTXT "PASS: CENTOS RELEASE 7"
  else
  echo
  REDTXT "ERROR: UNABLE TO DETERMINE DISTRIBUTION TYPE."
  YELLOWTXT "------> THIS CONFIGURATION FOR CENTOS 7"
  echo
  exit 1
fi

# check if x64. if not, beat it...
ARCH=$(uname -m)
if [ "${ARCH}" = "x86_64" ]; then
  GREENTXT "PASS: YOUR ARCHITECTURE IS 64-BIT"
  else
  echo
  REDTXT "ERROR: YOUR ARCHITECTURE IS 32-BIT?"
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
    yum -y install epel-release > /dev/null 2>&1
    yum -y install time bzip2 tar > /dev/null 2>&1
    
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

    if [ ${io:0:3} -le 200 ] ; then
        IO_COLOR="${RED}$io - very bad result"
    elif [ ${io:0:3} -le 250 ] ; then
        IO_COLOR="${YELLOW}$io - average result"
    else
        IO_COLOR="${GREEN}$io - excellent result"
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
        /bin/systemctl restart sshd.service
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
        /bin/systemctl restart sshd.service
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
        echo -e "${DGREYBG}${BOLD}  MAGENTO ${MAGENTO_VER} SERVER CONFIGURATION v.${MASCM_VER}  ${RESET}"
        BLUETXT ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
        echo
        WHITETXT "-> Install repository and LEMP packages :  ${YELLOW}\tlemp"
        WHITETXT "-> Download Magento latest packages     :  ${YELLOW}\t\tmagento"
	WHITETXT "-> Setup Magento database               :  ${YELLOW}\t\t\tdatabase"
	WHITETXT "-> Install Magento with Composer        :  ${YELLOW}\t\tinstall"
	WHITETXT "-> Post-Install configuration           :  ${YELLOW}\t\tpostconfig"
        echo
        BLUETXT ":::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::"
        echo
        WHITETXT "-> Install Webmin control panel         :  ${YELLOW}\t\twebmin"
        WHITETXT "-> Install CSF Firewall                 :  ${YELLOW}\t\t\tfirewall"
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
GREENTXT "INSTALLING EXTRA PACKAGES. PLEASE WAIT"
yum -q -y install ${REPO_FAN} >/dev/null 2>&1
sed -i '0,/gpgkey/s//includepkgs=curl libmetalink libpsl libcurl libssh2\n&/' /etc/yum.repos.d/city-fan.org.repo
yum -q -y install ${EXTRA_PACKAGES} ${PERL_MODULES[@]/#/perl-} >/dev/null 2>&1
echo
GREENTXT "CHECKING UPDATES. PLEASE WAIT"
## checking updates
UPDATES=$(yum check-update | grep -c updates$)
KERNEL=$(yum check-update | grep -c ^kernel)
if [ "${UPDATES}" -gt 0 ] || [ "${KERNEL}" -gt 0 ]; then
echo
YELLOWTXT "---> NEW UPDATED PKGS: ${UPDATES}"
YELLOWTXT "---> NEW KERNEL PKGS: ${KERNEL}"
echo
GREENTXT "THE UPDATES ARE BEING INSTALLED"
            echo
            echo -n "     PROCESSING  "
            long_progress &
            pid="$!"
            yum -y -q update >/dev/null 2>&1
            stop_progress "$pid"
            echo
            GREENTXT "THE SYSTEM IS UP TO DATE  -  OK"
            echo "yes" > /root/mascm/.sysupdate
            echo
fi
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
            rpm --quiet -U ${REPO_PERCONA} >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q percona-release
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
              yum -y -q install ${PERCONA_PACKAGES[@]/#/Percona-Server-}  >/dev/null 2>&1
              stop_progress "$pid"
              rpm  --quiet -q ${PERCONA_PACKAGES[@]/#/Percona-Server-}
        if [ "$?" = 0 ] # if package installed then configure
          then
            echo
              GREENTXT "DATABASE HAS BEEN INSTALLED  -  OK"
              echo
              ## plug in service status alert
              cp /usr/lib/systemd/system/mysqld.service /etc/systemd/system/mysqld.service
              sed -i "/Restart=always/d" /etc/systemd/system/mysqld.service
              sed -i "/Restart=always/d" /etc/systemd/system/mysql.service
              sed -i "/^After=.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/mysqld.service
              sed -i "/^After=.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/mysql.service
              systemctl daemon-reload
              systemctl enable mysql >/dev/null 2>&1
              echo
              WHITETXT "Downloading my.cnf file from MagenX Github repository"
              wget -qO /etc/my.cnf https://raw.githubusercontent.com/magenx/magento-mysql/master/my.cnf/my.cnf
              echo
                echo
                 WHITETXT "We need to correct your innodb_buffer_pool_size"
                 rpm -qa | grep -qw bc || yum -q -y install bc >/dev/null 2>&1
                 IBPS=$(echo "0.5*$(awk '/MemTotal/ { print $2 / (1024*1024)}' /proc/meminfo | cut -d'.' -f1)" | bc | xargs printf "%1.0f")
                 sed -i "s/innodb_buffer_pool_size = 4G/innodb_buffer_pool_size = ${IBPS}G/" /etc/my.cnf
                 sed -i "s/innodb_buffer_pool_instances = 4/innodb_buffer_pool_instances = ${IBPS}/" /etc/my.cnf
                 echo
                 YELLOWTXT "Your innodb_buffer_pool_size = ${IBPS}G"
                 YELLOWTXT "Your innodb_buffer_pool_instances = ${IBPS}"
                echo
              echo
              ## get mysql tools
              wget -qO - ${MYSQL_TOP} | tar -xzp && cd mytop*
              perl Makefile.PL && make && make install  >/dev/null 2>&1
              yum -y -q install percona-toolkit >/dev/null 2>&1
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
            wget -qO /etc/pki/rpm-gpg/nginx_signing.key  http://nginx.org/packages/keys/nginx_signing.key
            echo
            WHITETXT "Creating Nginx (mainline) repository file"
            echo
cat >> /etc/yum.repos.d/nginx.repo <<END
[nginx]
name=nginx repo
baseurl=http://nginx.org/packages/mainline/centos/7/x86_64/
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/nginx_signing.key
gpgcheck=1
END
            echo
            GREENTXT "REPOSITORY HAS BEEN INSTALLED  -  OK"
            echo
            GREENTXT "Installation of NGINX package:"
            echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            yum -y -q install nginx nginx-module-geoip >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q nginx
      if [ "$?" = 0 ]
        then
          echo
            GREENTXT "NGINX HAS BEEN INSTALLED  -  OK"
            echo
            ## plug in service status alert
            cp /usr/lib/systemd/system/nginx.service /etc/systemd/system/nginx.service
            sed -i "/^After=.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/nginx.service
            sed -i "s,PIDFile=/run/nginx.pid,PIDFile=/var/run/nginx.pid," /etc/systemd/system/nginx.service
            sed -i "s/PrivateTmp=true/PrivateTmp=false/" /etc/systemd/system/nginx.service
            systemctl daemon-reload
            systemctl enable nginx >/dev/null 2>&1
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
echo -n "---> Start the Remi repository and PHP 7.0 installation? [y/n][n]:"
read repo_remi_install
if [ "${repo_remi_install}" == "y" ];then
          echo
            GREENTXT "Installation of Remi repository:"
            echo
            echo -n "     PROCESSING  "
            quick_progress &
            pid="$!"
            rpm --quiet -U ${REPO_REMI} >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q remi-release
      if [ "$?" = 0 ]
        then
          echo
            GREENTXT "REPOSITORY HAS BEEN INSTALLED  -  OK"
            echo
            GREENTXT "Installation of PHP 7.0:"
            echo
            echo -n "     PROCESSING  "
            long_progress &
            pid="$!"
            yum --enablerepo=remi,remi-php70 -y -q install php ${PHP_PACKAGES[@]/#/php-} ${PHP_PECL_PACKAGES[@]/#/php-} >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q php
       if [ "$?" = 0 ]
         then
           echo
             GREENTXT "PHP HAS BEEN INSTALLED  -  OK"
             ## plug in service status alert
             cp /usr/lib/systemd/system/php-fpm.service /etc/systemd/system/php-fpm.service
             sed -i "s/PrivateTmp=true/PrivateTmp=false/" /etc/systemd/system/php-fpm.service
             sed -i "/^After=.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/php-fpm.service
             systemctl daemon-reload
             systemctl enable php-fpm >/dev/null 2>&1
             systemctl disable httpd >/dev/null 2>&1
             yum list installed | awk '/php.*x86_64/ {print "      ",$1}'
                else
               echo
             REDTXT "PHP INSTALLATION ERROR"
         exit
       fi
         echo
           echo
            GREENTXT "Installation of Redis and Memcached packages:"
            echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            yum --enablerepo=remi -y -q install redis memcached >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q redis
       if [ "$?" = 0 ]
         then
           echo
             GREENTXT "REDIS HAS BEEN INSTALLED"
             systemctl disable redis >/dev/null 2>&1
             echo
for REDISPORT in 6379 6380
do
mkdir -p /var/lib/redis-${REDISPORT}
chmod 755 /var/lib/redis-${REDISPORT}
chown redis /var/lib/redis-${REDISPORT}
\cp -rf /etc/redis.conf /etc/redis-${REDISPORT}.conf
\cp -rf /usr/lib/systemd/system/redis.service /etc/systemd/system/redis-${REDISPORT}.service
sed -i "s/daemonize no/daemonize yes/"  /etc/redis-${REDISPORT}.conf
sed -i "s/^bind 127.0.0.1.*/bind 127.0.0.1/"  /etc/redis-${REDISPORT}.conf
sed -i "s/^dir.*/dir \/var\/lib\/redis-${REDISPORT}\//"  /etc/redis-${REDISPORT}.conf
sed -i "s/^logfile.*/logfile \/var\/log\/redis\/redis-${REDISPORT}.log/"  /etc/redis-${REDISPORT}.conf
sed -i "s/^pidfile.*/pidfile \/var\/run\/redis\/redis-${REDISPORT}.pid/"  /etc/redis-${REDISPORT}.conf
sed -i "s/^port.*/port ${REDISPORT}/" /etc/redis-${REDISPORT}.conf
sed -i "s/redis.conf/redis-${REDISPORT}.conf/" /etc/systemd/system/redis-${REDISPORT}.service
sed -i "/^After=.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/redis-${REDISPORT}.service
done
systemctl daemon-reload
systemctl enable redis-6379 >/dev/null 2>&1
systemctl enable redis-6380 >/dev/null 2>&1
echo
cat > /etc/sysconfig/memcached <<END
PORT="11211"
USER="memcached"
MAXCONN="5024"
CACHESIZE="128"
OPTIONS="-l 127.0.0.1"
END
## plug in service status alert
cp /usr/lib/systemd/system/memcached.service /etc/systemd/system/memcached.service
sed -i "/^After=.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/memcached.service
systemctl daemon-reload
systemctl enable memcached   >/dev/null 2>&1
                else
               echo
             REDTXT "REDIS INSTALLATION ERROR"
         exit
       fi
         else
           echo
             REDTXT "REPOSITORY INSTALLATION ERROR"
        exit
      fi
        else
          echo
            YELLOWTXT "The Remi repository installation was skipped by the user. Next step"
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
            rpm --quiet --nosignature -i https://repo.varnish-cache.org/redhat/varnish-4.1.el7.rpm >/dev/null 2>&1
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            yum -y -q install varnish >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q varnish
      if [ "$?" = 0 ]
        then
          echo
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
cat > /etc/yum.repos.d/gleez.repo <<END
[gleez]
name=Gleez repo
baseurl=https://yum.gleez.com/7/x86_64/
gpgcheck=0
enabled=1
END
echo
            GREENTXT "Installation of HHVM package:"
            echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            yum -y -q install hhvm >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q hhvm
      if [ "$?" = 0 ]
        then
          echo
            GREENTXT "HHVM HAS BEEN INSTALLED  -  OK"
            echo
            ## plug in service status alert
            cp /usr/lib/systemd/system/hhvm.service /etc/systemd/system/hhvm.service
            sed -i "/^Description=.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/hhvm.service
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
cat > /etc/php.d/10-opcache.ini <<END
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
opcache.save_comments = 0
opcache.load_comments = 0
opcache.fast_shutdown = 0
opcache.enable_file_override = 0
opcache.optimization_level = 0xffffffff
opcache.inherited_hack = 1
opcache.blacklist_filename=/etc/php.d/opcache-default.blacklist
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
cp /etc/php.ini /etc/php.ini.BACK
sed -i 's/^\(max_execution_time = \)[0-9]*/\17200/' /etc/php.ini
sed -i 's/^\(max_input_time = \)[0-9]*/\17200/' /etc/php.ini
sed -i 's/^\(memory_limit = \)[0-9]*M/\11024M/' /etc/php.ini
sed -i 's/^\(post_max_size = \)[0-9]*M/\164M/' /etc/php.ini
sed -i 's/^\(upload_max_filesize = \)[0-9]*M/\164M/' /etc/php.ini
sed -i 's/expose_php = On/expose_php = Off/' /etc/php.ini
sed -i 's/;realpath_cache_size = 16k/realpath_cache_size = 512k/' /etc/php.ini
sed -i 's/;realpath_cache_ttl = 120/realpath_cache_ttl = 86400/' /etc/php.ini
sed -i 's/short_open_tag = Off/short_open_tag = On/' /etc/php.ini
sed -i 's/; max_input_vars = 1000/max_input_vars = 50000/' /etc/php.ini
sed -i 's/session.gc_maxlifetime = 1440/session.gc_maxlifetime = 28800/' /etc/php.ini
sed -i 's/mysql.allow_persistent = On/mysql.allow_persistent = Off/' /etc/php.ini
sed -i 's/mysqli.allow_persistent = On/mysqli.allow_persistent = Off/' /etc/php.ini
sed -i 's/pm = dynamic/pm = ondemand/' /etc/php-fpm.d/www.conf
sed -i 's/;pm.max_requests = 500/pm.max_requests = 10000/' /etc/php-fpm.d/www.conf
sed -i 's/pm.max_children = 50/pm.max_children = 1000/' /etc/php-fpm.d/www.conf

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
BLUEBG "| DOWNLOADING MAGENTO ${MAGENTO_VER} |"
echo "-------------------------------------------------------------------------------------"
echo
echo
     read -e -p "---> Enter your domain name (without www.): " -i "myshop.com" MY_DOMAIN
     MY_SHOP_PATH="/home/${MY_DOMAIN%%.*}/public_html"
     echo
        echo "--->  Magento ${MAGENTO_VER} will be downloaded to:"
        echo "--->  ${MY_SHOP_PATH}"
        mkdir -p ${MY_SHOP_PATH} && cd $_
        useradd -d ${MY_SHOP_PATH%/*} -s /sbin/nologin ${MY_DOMAIN%%.*}  >/dev/null 2>&1
        LINUX_USER_PASS=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
        echo "${MY_DOMAIN%%.*}:${LINUX_USER_PASS}"  | chpasswd  >/dev/null 2>&1
        chown -R ${MY_DOMAIN%%.*}:${MY_DOMAIN%%.*} ${MY_SHOP_PATH%/*}
        chmod 2770 ${MY_SHOP_PATH}
        setfacl -Rdm u:${MY_DOMAIN%%.*}:rwx,g:${MY_DOMAIN%%.*}:rw,g::rw,o::- ${MY_SHOP_PATH}
        echo
        curl -sS https://getcomposer.org/installer | php >/dev/null 2>&1
        mv composer.phar /usr/local/bin/composer
        echo
        echo
        su ${MY_DOMAIN%%.*} -s /bin/bash -c "${REPO_MAGENTO} ."
        echo
     echo
WHITETXT "============================================================================="
GREENTXT "      == MAGENTO DOWNLOADED AND READY FOR INSTALLATION =="
WHITETXT "============================================================================="
mkdir -p /root/mascm/
cat >> /root/mascm/.mascm_index <<END
webshop ${MY_DOMAIN}    ${MY_SHOP_PATH}    ${MY_DOMAIN%%.*}   ${LINUX_USER_PASS}
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
GREENTXT "CREATING MAGENTO DATABASE AND DATABASE USER"
echo
/bin/systemctl start mysql.service
pause '------> Press [Enter] key to generate MySQL ROOT strong password'
   echo
       MYSQL_ROOT_PASS=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
       WHITETXT "MySQL ROOT password: ${REDBG}${MYSQL_ROOT_PASS}"
       GREENTXT "!REMEMBER IT AND KEEP IT SAFE!"
   echo
pause '------> Press [Enter] key to start MySQL Secure Installation'
mysql_secure_installation
echo
echo
pause '------> Press [Enter] key to generate MySQL USER strong password'
   MAGE_DB_PASS=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
   WHITETXT "MySQL USER password: ${REDBG}${MAGE_DB_PASS}"
   echo
echo
read -e -p "---> Enter Magento database host : " -i "localhost" MAGE_DB_HOST
read -e -p "---> Enter Magento database name : " -i "magento2_${MY_DOMAIN%%.*}" MAGE_DB_NAME
read -e -p "---> Enter Magento database user : " -i "${MY_DOMAIN%%.*}" MAGE_DB_USER_NAME
echo
echo
pause '------> Press [Enter] key to create MySQL database and user'
mysql -u root -p${MYSQL_ROOT_PASS} <<EOMYSQL
CREATE USER '${MAGE_DB_USER_NAME}'@'${MAGE_DB_HOST}' IDENTIFIED BY '${MAGE_DB_PASS}';
CREATE DATABASE ${MAGE_DB_NAME};
GRANT ALL PRIVILEGES ON ${MAGE_DB_NAME}.* TO '${MAGE_DB_USER_NAME}'@'${MAGE_DB_HOST}' WITH GRANT OPTION;
exit
EOMYSQL
echo
GREENTXT "MAGENTO DATABASE ${RED} ${MAGE_DB_NAME} ${GREEN}AND USER ${RED} ${MAGE_DB_USER_NAME} ${GREEN}CREATED, PASSWORD IS ${RED} ${MAGE_DB_PASS}"
GREENTXT "MySQL ROOT password: ${REDBG}${MYSQL_ROOT_PASS}"
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
database        ${MAGE_DB_HOST}   ${MAGE_DB_NAME}   ${MAGE_DB_USER_NAME}     ${MAGE_DB_PASS}    ${MYSQL_ROOT_PASS}
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
echo "-------------------------------------------------------------------------------------"
BLUEBG   "vvv   MAGENTO ${MAGENTO_VER} INSTALLATION WITH COMPOSER   vvv"
echo "-------------------------------------------------------------------------------------"
echo
MY_SHOP_PATH=$(awk '/webshop/ { print $3 }' /root/mascm/.mascm_index)
cd ${MY_SHOP_PATH}
chown -R ${MY_DOMAIN%%.*}:${MY_DOMAIN%%.*} ${MY_SHOP_PATH}
echo
echo "---> ENTER SETUP INFORMATION"
DB_HOST=$(awk '/database/ { print $2 }' /root/mascm/.mascm_index)
DB_NAME=$(awk '/database/ { print $3 }' /root/mascm/.mascm_index)
DB_USER_NAME=$(awk '/database/ { print $4 }' /root/mascm/.mascm_index)
DB_PASS=$(awk '/database/ { print $5 }' /root/mascm/.mascm_index)
MY_DOMAIN=$(awk '/webshop/ { print $2 }' /root/mascm/.mascm_index)
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
read -e -p "---> Enter your email: " -i "admin@${MY_DOMAIN}"  MAGE_ADMIN_EMAIL
read -e -p "---> Enter your admins login name: " -i "admin"  MAGE_ADMIN_LOGIN
MAGE_ADMIN_PASSGEN=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 9 | head -n 1)
read -e -p "---> Use generated admin password: " -i "${RANDOM}${MAGE_ADMIN_PASSGEN}"  MAGE_ADMIN_PASS
read -e -p "---> Enter your shop url: " -i "http://www.${MY_DOMAIN}/"  MAGE_SITE_URL
echo
WHITETXT "Language, Currency and Timezone settings"
chmod u+x bin/magento
updown_menu "$(bin/magento info:language:list | sed "s/[|+-]//g" | awk 'NR > 3 {print $NF}' | sort )" MAGE_LOCALE
updown_menu "$(bin/magento info:currency:list | sed "s/[|+-]//g" | awk 'NR > 3 {print $NF}' | sort )" MAGE_CURRENCY
updown_menu "$(bin/magento info:timezone:list | sed "s/[|+-]//g" | awk 'NR > 3 {print $NF}' | sort )" MAGE_TIMEZONE
echo
echo
cat >> /root/mascm/.mascm_index <<END
adminpass ${MAGE_ADMIN_PASS}
END
GREENTXT "INSTALL MAGENTO ${MAGENTO_VER} WITHOUT SAMPLE DATA"
echo
pause '---> Press [Enter] key to continue'
echo
su ${MY_DOMAIN%%.*} -s /bin/bash -c "bin/magento setup:install --base-url=${MAGE_SITE_URL} \
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
echo
echo
pause '------> Press [Enter] key to show menu'
printf "\033c"
;;
###################################################################################
#                                SYSTEM CONFIGURATION                             #
###################################################################################
"postconfig")
printf "\033c"
echo "-------------------------------------------------------------------------------------"
BLUEBG " POST-INSTALL CONFIGURATION "
echo "-------------------------------------------------------------------------------------"
echo
echo
## "NGINX CONFIGURATION"
echo
wget -qO /etc/nginx/fastcgi_params  ${NGINX_BASE}fastcgi_params
wget -qO /etc/nginx/nginx.conf  ${NGINX_BASE}nginx.conf

mkdir -p /etc/nginx/sites-enabled
mkdir -p /etc/nginx/sites-available && cd $_
wget -q ${NGINX_BASE}sites-available/default.conf
wget -q ${NGINX_BASE}sites-available/magento2.conf

sed -i "s/example.com/${MY_DOMAIN}/g" /etc/nginx/sites-available/magento2.conf
sed -i "s,/var/www/html,${MY_SHOP_PATH},g" /etc/nginx/sites-available/magento2.conf

ln -s /etc/nginx/sites-available/magento2.conf /etc/nginx/sites-enabled/magento2.conf
ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

mkdir -p /etc/nginx/conf_m2 && cd /etc/nginx/conf_m2/
for CONFIG in ${NGINX_EXTRA_CONF}
do
wget -q ${NGINX_EXTRA_CONF_URL}${CONFIG}
done
echo
usermod -G ${MY_DOMAIN%%.*} nginx
sed -i "s/user = apache/user = ${MY_DOMAIN%%.*}/" /etc/php-fpm.d/www.conf
sed -i "s/group = apache/group = ${MY_DOMAIN%%.*}/" /etc/php-fpm.d/www.conf
sed -i "s,.*php_value\[session.save_path\].*,php_value\[session.save_path\] = ${MY_SHOP_PATH}/var/session," /etc/php-fpm.d/www.conf
sed -i "s,.*php_value\[soap.wsdl_cache_dir\].*,php_value\[soap.wsdl_cache_dir\] = ${MY_SHOP_PATH}/tmp," /etc/php-fpm.d/www.conf
echo
GREENTXT "PROFTPD CONFIGURATION"
pause '------> Press [Enter] key to continue'
echo
     wget -qO /etc/proftpd.conf ${REPO_MASCM_TMP}proftpd.conf
     ## change proftpd config
     SERVER_IP_ADDR=$(ip route get 1 | awk '{print $NF;exit}')
     USER_IP=$(last -i | grep "root.*still logged in" | awk 'NR==1{print $3}')
     USER_GEOIP=$(geoiplookup ${USER_IP} | awk 'NR==1{print substr($4,1,2)}')
     FTP_PORT=$(shuf -i 5121-5132 -n 1)
     sed -i "s/server_sftp_port/${FTP_PORT}/" /etc/proftpd.conf
     sed -i "s/server_ip_address/${SERVER_IP_ADDR}/" /etc/proftpd.conf
     sed -i "s/client_ip_address/${USER_IP}/" /etc/proftpd.conf
     sed -i "s/geoip_country_code/${USER_GEOIP}/" /etc/proftpd.conf
     sed -i "s/sftp_domain/${MY_DOMAIN}/" /etc/proftpd.conf
     sed -i "s/FTP_USER/${MY_DOMAIN%%.*}/" /etc/proftpd.conf
     echo
     ## plug in service status alert
     cp /usr/lib/systemd/system/proftpd.service /etc/systemd/system/proftpd.service
     sed -i "/^After=.*/a OnFailure=service-status-mail@%n.service" /etc/systemd/system/proftpd.service
     systemctl daemon-reload
     systemctl enable proftpd.service >/dev/null 2>&1
     /bin/systemctl restart proftpd.service
     echo
     WHITETXT "We have created a user: ${REDBG}${MY_DOMAIN%%.*}"
     WHITETXT "With a password: ${REDBG}${LINUX_USER_PASS}"
     WHITETXT "FTP PORT: ${REDBG}${FTP_PORT}"
     WHITETXT "Your GeoIP location: ${REDBG}${USER_GEOIP}"
     WHITETXT "PROFTPD config file /etc/proftpd.conf"
echo
GREENTXT "INSTALLING PHPMYADMIN - ADVANCED MYSQL INTERFACE"
pause '------> Press [Enter] key to continue'
echo
     cd ${MY_SHOP_PATH}
     PMA_FOLDER=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 5 | head -n 1)
     BLOWFISHCODE=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 64 | head -n 1)
     yum -y -q --enablerepo=remi,remi-test,remi-php70 install phpMyAdmin
     sed -i "s/.*blowfish_secret.*/\$cfg['blowfish_secret'] = '${BLOWFISHCODE}';/" /etc/phpMyAdmin/config.inc.php
     sed -i "s/PHPMYADMIN_PLACEHOLDER/mysql_${PMA_FOLDER}/g" /etc/nginx/conf_m2/phpmyadmin.conf
     echo
     GREENTXT "phpMyAdmin was installed to http://www.${MY_DOMAIN}/mysql_${PMA_FOLDER}/"
echo
echo
echo
GREENTXT "INSTALLING OPCACHE GUI"
pause '------> Press [Enter] key to continue'
echo
    cd ${MY_SHOP_PATH}/pub/
    OPCACHE_FILE=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z' | fold -w 12 | head -n 1)
    wget -qO ${OPCACHE_FILE}_opcache_gui.php https://raw.githubusercontent.com/magenx/opcache-gui/master/index.php
    echo
    GREENTXT "Opcache interface was installed to http://www.${MY_DOMAIN}/${OPCACHE_FILE}_opcache_gui.php"
echo
echo
if yum list installed "varnish" >/dev/null 2>&1; then
GREENTXT "VARNISH DAEMON CONFIGURATION FILE"
echo
wget -qO /etc/systemd/system/varnish.service ${REPO_MASCM_TMP}varnish.service
sed -i "s,VCL_PATH,/etc/varnish/default.vcl,g" /etc/systemd/system/varnish.service
systemctl daemon-reload >/dev/null 2>&1
systemctl enable varnish >/dev/null 2>&1
echo
echo 'Varnish secret key -->'$(cat /etc/varnish/secret)'<-- copy it'
echo
fi
echo
GREENTXT "SYSTEM UPDATE CONFIGURATION YUM-CRON"
echo
sed -i '8s/.*/enabled=1/' /etc/yum.repos.d/remi-php70.repo
sed -i '9s/.*/enabled=1/' /etc/yum.repos.d/remi.repo
echo
sed -i 's/apply_updates = no/apply_updates = yes/' /etc/yum/yum-cron.conf
sed -i "s/email_from = root@localhost/email_from = yum-cron@${MY_DOMAIN}/" /etc/yum/yum-cron.conf
sed -i "s/email_to = root/email_to = admin@${MY_DOMAIN}/" /etc/yum/yum-cron.conf
echo
systemctl enable yum-cron
systemctl restart yum-cron
echo
GREENTXT "LETSENCRYPT SSL CERTIFICATE REQUEST"
echo
DNS_DOMAIN=$(getent hosts ${MY_DOMAIN} | awk '{ print $1 }')
SERVER_IP_ADDR=$(ip route get 1 | awk '{print $NF;exit}')
if [ "${DNS_DOMAIN}" != "${SERVER_IP_ADDR}" ] ; then
    echo
    REDTXT "DNS A record and your servers IP address do not match"
	YELLOWTXT "Your servers ip address ${SERVER_IP_ADDR}"
	YELLOWTXT "Domain ${MY_DOMAIN} resolves to ${DNS_DOMAIN}"
	YELLOWTXT "Please change your DNS A record to this servers IP address"
	YELLOWTXT "and run this command later: /usr/bin/certbot certonly --standalone --email admin@${MY_DOMAIN} -d ${MY_DOMAIN} -d www.${MY_DOMAIN}"
	echo
	GREENTXT "WE CAN GENERATE DHPARAM FILE NOW"
	echo
        openssl dhparam -dsaparam -out /etc/ssl/certs/dhparams.pem 4096
        echo
    else
    service nginx stop
    /usr/bin/certbot certonly --standalone --email admin@${MY_DOMAIN} -d ${MY_DOMAIN} -d www.${MY_DOMAIN}
    service nginx start
fi
echo
GREENTXT "CREATING SIMPLE LOGROTATE SCRIPT FOR MAGENTO LOGS"
cat > /etc/logrotate.d/magento <<END
${MY_SHOP_PATH}/var/log/*.log
{
weekly
rotate 4
notifempty
missingok
compress
}
END
echo
GREENTXT "SETUP SERVICE STATUS WITH E-MAIL ALERTS"
echo
wget -qO /etc/systemd/system/service-status-mail@.service ${STATUS_ALERT_SERVICE}
wget -qO /bin/service-status-mail.sh ${STATUS_ALERT_SCRIPT}
sed -i "s/MAGEADMINEMAIL/${MAGE_ADMIN_EMAIL}/" /bin/service-status-mail.sh
sed -i "s/DOMAINNAME/${MY_DOMAIN}/" /bin/service-status-mail.sh
chmod u+x /bin/service-status-mail.sh
systemctl daemon-reload
echo
GREENTXT "SETUP REALTIME MALWARE MONITOR WITH E-MAIL ALERTS"
YELLOWTXT "WARNING: INFECTED FILES WILL BE MOVED TO QUARANTINE"
echo
cd /usr/local/src
wget -q ${MALDET}
tar -zxf maldetect-current.tar.gz
cd maldetect-*
./install.sh
echo
sed -i 's/email_alert="0"/email_alert="1"/' /usr/local/maldetect/conf.maldet
sed -i "s/you@domain.com/${MAGE_ADMIN_EMAIL}/" /usr/local/maldetect/conf.maldet
sed -i 's/quarantine_hits="0"/quarantine_hits="1"/' /usr/local/maldetect/conf.maldet
sed -i 's,# default_monitor_mode="/usr/local/maldetect/monitor_paths",default_monitor_mode="/usr/local/maldetect/monitor_paths",' /usr/local/maldetect/conf.maldet
sed -i 's/inotify_base_watches="16384"/inotify_base_watches="35384"/' /usr/local/maldetect/conf.maldet
echo -e "${MY_SHOP_PATH}\n\n/var/tmp/\n\n/tmp/" > /usr/local/maldetect/monitor_paths
echo
sed -i "/^Example/d" /etc/clamd.d/scan.conf
sed -i "/^Example/d" /etc/freshclam.conf
sed -i "/^FRESHCLAM_DELAY/d" /etc/sysconfig/freshclam
echo "maldet --monitor /usr/local/maldetect/monitor_paths" >> /etc/rc.local
maldet --monitor /usr/local/maldetect/monitor_paths
echo
echo
GREENTXT "DOWNLOADING NETZ98 MAGERUN CLI TOOLS FOR MAGENTO 2"
echo
curl -o  /usr/local/bin/n98-magerun2.phar https://files.magerun.net/n98-magerun2.phar
chmod u+x /usr/local/bin/n98-magerun2.phar
echo
GREENTXT "IMAGES OPTIMIZATION SCRIPT"
wget -qO ${MY_SHOP_PATH}/imgopt.pl ${REPO_MASCM_TMP}wesley.pl
chmod u+x /etc/rc.local
echo
        crontab -l -u ${MY_DOMAIN%%.*} > magecron
        echo "MAILTO="${MAGE_ADMIN_EMAIL}"" >> magecron
        echo "* * * * * php -c /etc/php.ini ${MY_SHOP_PATH}/bin/magento cron:run" >> magecron
	    echo "* * * * * php -c /etc/php.ini ${MY_SHOP_PATH}/update/cron.php" >> magecron
	    echo "* * * * * php -c /etc/php.ini ${MY_SHOP_PATH}/bin/magento setup:cron:run" >> magecron
        echo "5 8 * * 7 perl ${MY_SHOP_PATH}/mysqltuner.pl --nocolor 2>&1 | mailx -E -s \"MYSQLTUNER WEEKLY REPORT at ${HOSTNAME}\" ${MAGE_ADMIN_EMAIL}" >> magecron
        crontab -u ${MY_DOMAIN%%.*} magecron
        rm magecron
echo
cd ${MY_SHOP_PATH}
su ${MY_DOMAIN%%.*} -s /bin/bash -c "bin/magento setup:static-content:deploy ${MAGE_LOCALE}"
echo
wget -qO ${MY_SHOP_PATH}/mysqltuner.pl ${MYSQL_TUNER}
echo
chown -R ${MY_DOMAIN%%.*}:${MY_DOMAIN%%.*} ${MY_SHOP_PATH}
chmod u+x ${MY_SHOP_PATH}/{imgopt.pl,mysqltuner.pl,bin/magento}
echo
GREENTXT "SERVER TIMEZONE SETUP"
sed -i "s,.*date.timezone.*,date.timezone = ${MAGE_TIMEZONE}," /etc/php.ini
timedatectl set-timezone ${MAGE_TIMEZONE}
echo
echo
    GREENTXT "NOW CHECK EVERYTHING AND LOGIN TO YOUR BACKEND"
    echo
  echo
echo "-------------------------------------------------------------------------------------"
BLUEBG " POST-INSTALL CONFIGURATION IS COMPLETED "
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
echo -n "---> Would you like to install CSF firewall? [y/n][n]:"
read csf_test
if [ "${csf_test}" == "y" ];then
           echo
               GREENTXT "DOWNLOADING CSF FIREWALL"
               echo
               cd /usr/local/src/
               echo -n "     PROCESSING  "
               quick_progress &
               pid="$!"
               wget -qO - http://www.configserver.com/free/csf.tgz | tar -xz
               stop_progress "$pid"
               echo
               cd csf
               GREENTXT "NEXT, TEST IF YOU HAVE THE REQUIRED IPTABLES MODULES"
               echo
        if perl csftest.pl | grep "FATAL" ; then
               perl csftest.pl
               echo
               pause '---> Press [Enter] key to show menu'
           exit
           else
               perl csftest.pl
               echo
               pause '---> Press [Enter] key to continue'
               echo
               GREENTXT "Running CSF installation"
               echo
               echo -n "     PROCESSING  "
               quick_progress &
               pid="$!"
               sh install.sh
               stop_progress "$pid"
               echo
               GREENTXT "CSF FIREWALL HAS BEEN INSTALLED OK"
               echo
    fi
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
cat > /etc/yum.repos.d/webmin.repo <<END
[Webmin]
name=Webmin Distribution
#baseurl=http://download.webmin.com/download/yum
mirrorlist=http://download.webmin.com/download/yum/mirrorlist
enabled=1
END
rpm --import http://www.webmin.com/jcameron-key.asc
            echo
            echo -n "     PROCESSING  "
            start_progress &
            pid="$!"
            yum -y -q install webmin >/dev/null 2>&1
            stop_progress "$pid"
            rpm  --quiet -q webmin
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
            wget -q ${WEBMIN_NGINX} -O webmin_nginx
            perl /usr/libexec/webmin/install-module.pl $_ >/dev/null 2>&1
            perl /usr/libexec/webmin/install-module.pl /usr/local/csf/csfwebmin.tgz >/dev/null 2>&1
            sed -i 's/root/webadmin/' /etc/webmin/miniserv.users
            sed -i 's/root:/webadmin:/' /etc/webmin/webmin.acl
            WEBADMIN_PASS=$(head -c 500 /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 15 | head -n 1)
            /usr/libexec/webmin/changepass.pl /etc/webmin/ webadmin ${WEBADMIN_PASS}
            chkconfig webmin on >/dev/null 2>&1
            service webmin restart  >/dev/null 2>&1
            YELLOWTXT "Access Webmin on port: ${WEBMIN_PORT}"
            YELLOWTXT "User: webadmin , Password: ${WEBADMIN_PASS}"
            REDTXT "Please enable Two-factor authentication"
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
GREENTXT "Installation of OSSEC ELK stack:"
cd /usr/local/src
mkdir ossec_tmp && cd $_
git clone -b stable https://github.com/wazuh/ossec-wazuh.git
echo
cd ossec-wazuh
echo
YELLOWTXT "Choose 'server' when being asked about the installation type and answer the rest of questions as desired."
echo
./install.sh
echo
echo
GREENTXT "Installation of Oracle Java 8 JDK RPM:"
cd /usr/local/src
wget --no-cookies --no-check-certificate --header "Cookie: gpw_e24=http%3A%2F%2Fwww.oracle.com%2F; oraclelicense=accept-securebackup-cookie" "http://download.oracle.com/otn-pub/java/jdk/8u102-b14/jdk-8u102-linux-x64.rpm"
yum -y -q localinstall jdk-8u102-linux-x64.rpm
export JAVA_HOME=/usr/java/jdk1.8.0_102/jre
echo "export JAVA_HOME=/usr/java/jdk1.8.0_102/jre" > /etc/profile
echo
echo
GREENTXT "Installation of Logstash:"
rpm --import https://packages.elastic.co/GPG-KEY-elasticsearch
cat > /etc/yum.repos.d/logstash.repo <<END
[logstash-2.3]
name=Logstash repository for 2.3.x packages
baseurl=https://packages.elastic.co/logstash/2.3/centos
gpgcheck=1
gpgkey=https://packages.elastic.co/GPG-KEY-elasticsearch
enabled=1
END
yum -y -q install logstash
echo
cp /usr/local/src/ossec_tmp/ossec-wazuh/extensions/logstash/01-ossec-singlehost.conf /etc/logstash/conf.d/
cp /usr/local/src/ossec_tmp/ossec-wazuh/extensions/elasticsearch/elastic-ossec-template.json  /etc/logstash/
curl -sO "http://geolite.maxmind.com/download/geoip/database/GeoLiteCity.dat.gz"
gzip -d GeoLiteCity.dat.gz && mv GeoLiteCity.dat /etc/logstash/
usermod -a -G ossec logstash
echo
echo
GREENTXT "Installation of Elastcsearch:"
echo
cat > /etc/yum.repos.d/elasticsearch.repo <<END
[elasticsearch-2.x]
name=Elasticsearch repository for 2.x packages
baseurl=https://packages.elastic.co/elasticsearch/2.x/centos
gpgcheck=1
gpgkey=https://packages.elastic.co/GPG-KEY-elasticsearch
enabled=1
END
echo
yum -y -q install elasticsearch
echo
systemctl daemon-reload
systemctl enable elasticsearch.service
echo
sed -i "s/.*cluster.name.*/cluster.name: ossec/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/.*node.name.*/node.name: ossec_node1/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/.*network.host.*/network.host: 127.0.0.1/" /etc/elasticsearch/elasticsearch.yml
sed -i "s/.*http.port.*/http.port: 9200/" /etc/elasticsearch/elasticsearch.yml
chown -R :elasticsearch /etc/elasticsearch/*
service elasticsearch restart
sleep 2
echo
cd /usr/local/src/ossec_tmp/ossec-wazuh/extensions/elasticsearch/ && curl -XPUT "http://localhost:9200/_template/ossec/" -d "@elastic-ossec-template.json"
echo
echo
GREENTXT "Lets install Kibana:"
cd /usr/local/src/ossec_tmp/
wget https://download.elastic.co/kibana/kibana/kibana-4.3.1-linux-x64.tar.gz
tar xf kibana-*.tar.gz && sudo mkdir -p /opt/kibana && sudo cp -R kibana-4*/* /opt/kibana/
cat > /etc/systemd/system/kibana4.service <<END
[Service]
ExecStart=/opt/kibana/bin/kibana
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=kibana4
User=root
Group=root
Environment=NODE_ENV=production
[Install]
WantedBy=multi-user.target
END
echo
systemctl daemon-reload
systemctl enable kibana4.service
systemctl restart kibana4.service
service logstash restart
echo
KIBANA_PORT=$(shuf -i 10322-10539 -n 1)
USER_IP=$(last -i | grep "root.*still logged in" | awk '{print $3}')
echo "Create password for Kibana interface http authentication:"
htpasswd -c /etc/nginx/.htpasswd ossec
cat > /etc/nginx/sites-available/kibana.conf <<END
server {
  listen ${KIBANA_PORT} ssl http2;
  server_name           ossec.${MY_DOMAIN};
  access_log            /var/log/nginx/access.log;
  
  ## SSL CONFIGURATION
	#ssl_certificate     /etc/letsencrypt/live/example.com/fullchain.pem; 
	#ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
	
    satisfy all;
    allow ${USER_IP};
    deny  all;
    auth_basic           "blackhole";
    auth_basic_user_file .htpasswd;
       
       location / {
               proxy_pass http://127.0.0.1:5601;
       }
}
END
echo
cd /etc/nginx/sites-enabled/
ln -s /etc/nginx/sites-available/kibana.conf kibana.conf
echo "Kibana web listening port: ${KIBANA_PORT}"
echo
echo " to Configure an index pattern, set it up following these steps:

- Check Index contains time-based events.
- Insert Index name or pattern: ossec-* .
- On Time-field name list select @timestamp option.
- Click on Create button.
- You should see the fields list with about ~72 fields.
- Go to Discover tap on top bar buttons."
echo
echo "
- Click at top bar on Settings.
- Click on Objects.
- Download the Dashboards JSON File: https://raw.githubusercontent.com/wazuh/ossec-wazuh/stable/extensions/kibana/kibana-ossecwazuh-dashboards.json .
- Then click the button Import."
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
