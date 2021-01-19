#!/bin/bash

sudo yum -y install redhat-lsb

if [ "`lsb_release -is`" == "Debian" ] || [ "`lsb_release -is`" == "Ubuntu" ]
then
    # Install & setup php
    sudo apt install software-properties-common dirmngr -y;
    if [ "`lsb_release -is`" == "Debian" ]
    then
        sudo wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg;
        echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php7.list;
    else
        ufw disable
        sudo add-apt-repository ppa:ondrej/php -y
    fi
    sudo apt-get update && apt-get install php7.2-fpm php7.2-cli php7.2-zip php7.2-opcache php7.2-mysql php7.2-mbstring php7.2-json php7.2-intl php7.2-gd php7.2-curl php7.2-bz2 php7.2-xml php7.2-tidy php7.2-soap php7.2-bcmath -y;
    sudo rm /etc/php/7.2/fpm/php.ini && sudo rm /etc/php/7.2/fpm/pool.d/www.conf;
    sudo wget https://gist.githubusercontent.com/jams008/4501b92f7f87e317213f16cdaf167e68/raw/59851e982bf11a8d08ba655383ac733cc2652851/pool-www.conf -O /etc/php/7.2/fpm/pool.d/www.conf;
    sudo wget https://gist.githubusercontent.com/jams008/c8cf5a5ce5bbfcecc341a093e474e7c7/raw/18a98b2b8eededf609ca9258bca21c90450337cd/ee-php.ini -O /etc/php/7.2/fpm/php.ini;
    sudo /etc/init.d/php7.2-fpm restart;

    # Install & setup mysql-server
    echo "mariadb-server mariadb-server/root_password password root" | sudo debconf-set-selections;
    echo "mariadb-server mariadb-server/root_password_again password root" | sudo debconf-set-selections;
    sudo apt-get -y install mariadb-server mariadb-client;
    sudo /etc/init.d/mysql restart;

    # Install & Setup Nginx
    sudo apt-get -y install nginx;
    sudo rm /etc/nginx/sites-enabled/default;
    sudo wget https://gist.githubusercontent.com/jams008/d08ea221cf87a0493aacb6e13cd9d58e/raw/a1629b2135e6d12635cd11e7e044fd6c4b6227eb/nginx-default-conf -O /etc/nginx/sites-enabled/default;
    sudo /etc/init.d/nginx restart;

    # Setup phpinfo
    sudo printf "<?php\nphpinfo();\n?>" > /var/www/html/info.php;
    sudo chown -R www-data: /var/www/ && sudo chmod 755 -R /var/www/;

elif [ "`lsb_release -is`" == "CentOS" ]
then
    # Install & Setup php
    sudo yum -y install epel-release wget curl;
    if [ "`lsb_release -a | grep Release: | awk '{ print $2 }' | cut -c 1`" == "8" ]
    then
        sudo yum -y install http://rpms.remirepo.net/enterprise/remi-release-8.rpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm yum-utils;
    else
        sudo yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm yum-utils;
    fi
    sudo yum-config-manager --enable remi-php72;
    sudo yum -y update && sudo yum -y install php72-php-fpm php72-php-gd php72-php-cli php72-php-zip php72-php-mysql php72-php-intl php72-php-curl php72-php-bz2 php72-php-tidy php72-php-soap php72-php-bcmath php72-php-json php72-php-mbstring php72-php-mysqlnd php72-php-xml php72-php-xmlrpc php72-php-opcache;
    sudo rm /etc/opt/remi/php72/php.ini && sudo rm /etc/opt/remi/php72/php-fpm.d/www.conf;
    sudo wget https://gist.githubusercontent.com/jams008/24b9d0dc907196aa2bd991e5fab809d1/raw/4b9b1573d075d97734a3508471d87f1643a716a2/www-centos-php72.conf -O /etc/opt/remi/php72/php-fpm.d/www.conf;
    sudo wget https://gist.githubusercontent.com/jams008/c8cf5a5ce5bbfcecc341a093e474e7c7/raw/18a98b2b8eededf609ca9258bca21c90450337cd/ee-php.ini -O /etc/opt/remi/php72/php.ini;
    sudo systemctl enable php72-php-fpm.service && sudo systemctl restart php72-php-fpm.service;

    # Install & Setup mysql-server
    sudo yum -y install mariadb-server mariadb-client;
    sudo systemctl enable mariadb && sudo systemctl start mariadb;
    sudo mysql_secure_installation;
    sudo systemctl restart mariadb;

    # Install & Setup Nginx
    sudo yum -y install nginx;
    sudo wget https://gist.githubusercontent.com/jams008/7d6cb06cf5616cdb795c661b7fcc46ef/raw/621429c3c3816d5954b8646fe33d914979c64f46/nginx-default-centos.conf -O /etc/nginx/nginx.conf;
    sudo systemctl enable nginx && sudo systemctl restart nginx;

    # Setup phpinfo
    sudo printf "<?php\nphpinfo();\n?>" > /usr/share/nginx/html/info.php;
    sudo chown -R nginx: /usr/share/nginx/html && chmod -R 775 /usr/share/nginx/html;
    sudo systemctl restart php72-php-fpm.service;

    # Disable SElinux
    setenforce 0
    sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
    sudo iptables -F
    sudo reboot

else
    echo "Unsupported Operating System";
fi