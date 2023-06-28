#!/bin/bash

echo "Enter your AD Server IP address: "

read adip

echo "Enter Your AD Server name: "

read server

echo "Enter your domain name: "

read domain

echo "-----"

echo "$adip"
echo "$server"
echo "$domain"

echo "-----"

echo "${server^^}"
echo "${domain^^}"

echo "-----"

full="$server"."$domain"

echo "$full"

echo "${full^^}"

#Edit /etc/hosts file
sed -i "4i $adip	$server $full" /etc/hosts

#Update and install packages
sudo apt update
sudo apt upgrade
sudo apt install sssd heimdal-clients msktutil

#Move Kerberos config file
sudo mv /etc/krb5.conf /etc/krb5.conf.default

#Create new Kerberos config file
