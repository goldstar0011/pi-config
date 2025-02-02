#!/bin/bash

#          Raspberry Pi setup, 'pi-heating-remote' configuration script.
# Author : Jeffrey.Powell ( jffrypwll <at> googlemail <dot> com )
# Date   : Nov 2016

# Die on any errors

#set -e 
clear

if [[ `whoami` != "root" ]]
then
  printf "\n\n Script must be run as root. \n\n"
  exit 1
fi

ENABLE_W1=$( cat /boot/config.txt | grep '^dtoverlay=w1-gpio$' )
if [[ $ENABLE_W1 == "" ]]
then
  echo "dtoverlay=w1-gpio" >> /boot/config.txt
  
  ENABLE_W1=$( cat /boot/config.txt | grep '^dtoverlay=w1-gpio$' )
  if [[ $ENABLE_W1 == "" ]]
  then  
    printf "\n\n EXITING : Unable to write to boot config. \n\n"
    exit 1
  fi
  apt-get update -y
  printf "\n\n REBOOT : Reeboot required to enable one wire module.\n\n"
  shutdown -r +1
else
  printf "\n One wire module enabled. \n"
  
  modprobe w1-gpio
  modprobe w1-therm
  
  printf "\n w1_gpio and w1_therm modules enabled. \n"
fi

APACHE_INSTALLED=$(which apache2)
if [[ "$APACHE_INSTALLED" == "" ]]
then
  printf "\n\n Installing Apache ...\n"
  # Install Apache
  apt-get install apache2 -y
  update-rc.d apache2 enable
  a2dissite 000-default.conf
  service apache2 restart
  
  APACHE_INSTALLED=$(which apache2)
    if [[ "$APACHE_INSTALLED" == "" ]]
    then
      printf "\n\n EXITING : Apache installation FAILED\n"
      exit 1
    fi
else
  printf "\n\n Apache is already installed. \n"
fi

PHP_INSTALLED=$(which php)
if [[ "$PHP_INSTALLED" == "" ]]
then
  printf "\n\n Installing PHP ...\n"
  # Install Apache
  apt-get install php -y
  
  PHP_INSTALLED=$(which php)
    if [[ "$PHP_INSTALLED" == "" ]]
    then
      printf "\n\n EXITING : PHP installation FAILED\n"
      exit 1
    fi
else
  printf "\n\n PHP is already installed. \n"
fi


# Install 'pi-heating-remote' app

PI_HEATING_V='1.0.0'
if [ ! -f "/home/pi/pi-heating-remote/README.md" ]
then
  printf "\n\n Installing pi-heating-remote v$PI_HEATING_V ...\n"
  # Install Apache
  cd /home/pi
  if [ -d "/home/pi/pi-heating-remote" ]
  then
    rm -rf "/home/pi/pi-heating-remote"
  fi
  
  if [ -d "/var/www/pi-heating-remote" ]
  then
    rm -rf "/var/www/pi-heating-remote"
  fi
  
  wget "https://github.com/goldstar0011/pi-heating-remote/archive/$PI_HEATING_V.tar.gz" -O "/home/pi/pi-heating-remote.tar.gz"
  tar -xvzf "/home/pi/pi-heating-remote.tar.gz"
  rm "/home/pi/pi-heating-remote.tar.gz"
  mv "/home/pi/pi-heating-remote-$PI_HEATING_V" "/home/pi/pi-heating-remote"
  mv "/home/pi/pi-heating-remote/www" "/var/www/pi-heating-remote"
  chown -R pi:pi "/home/pi/pi-heating-remote"
  chmod -R 755 "/home/pi/pi-heating-remote"
  chown -R pi:pi "/home/pi/pi-heating-remote/configs"
  chmod -R 755 "/home/pi/pi-heating-remote/configs"
  chown -R pi:pi "/var/www/pi-heating-remote"
  chmod -R 755 "/var/www/pi-heating-remote"
  
  if [ ! -f "/home/pi/pi-heating-remote/README.md" ]
    then
      printf "\n\n EXITING : pi-heating-remote v$PI_HEATING_V installation FAILED\n"
      exit 1
    fi
    
else
  printf "\n\n pi-heating-remote v$PI_HEATING_V is already installed. \n"
fi



# configure app

# configure apache vh on port 8080

printf "\n\n Configuring Apache ...\n"

  cat > /etc/apache2/ports.conf <<PORTS
Listen 8080
PORTS

  cat > /etc/apache2/sites-available/pi-heating.conf <<VHOST
<VirtualHost *:8080>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/pi-heating-remote/

    <Directory /var/www/pi-heating-remote/>
        Options -Indexes
        AllowOverride all
        Order allow,deny
        allow from all
    </Directory>
    
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
VHOST

a2ensite pi-heating.conf
service apache2 restart

printf "\n\n Installation Complete. Some changes might require a reboot. \n\n"
exit 1
