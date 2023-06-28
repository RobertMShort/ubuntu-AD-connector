
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

full="$server"."$domain"

echo "$full"

#Edit /etc/hosts file
sed -i "3i $adip	$server $full" /etc/hosts

#Update and install packages
sudo apt update
sudo apt upgrade
sudo apt install sssd heimdal-clients msktutil

#Move Kerberos config file
sudo mv /etc/krb5.conf /etc/krb5.conf.default

#Create new Kerberos config file
echo '[libdefaults]' > /etc/krb5.conf
echo "default_realm = ${domain^^}" >> /etc/krb5.conf
echo 'rdns = no' >> /etc/krb5.conf
echo 'dns_lookup_kdc = true' >> /etc/krb5.conf
echo 'dns_lookup_realm = true' >> /etc/krb5.conf
echo ' ' >> /etc/krb5.conf
echo '[realms]' >> /etc/krb5.conf
echo "${domain^^} = {" >> /etc/krb5.conf
echo "kdc = $full" >> /etc/krb5.conf
echo "admin_server = $full" >> /etc/krb5.conf
echo '}' >> /etc/krb5.conf

#Initialize Kerberos and create kaytab file
kinit administrator
klist

host=$(hostname -f)
msktutil -N -c -b 'CN=COMPUTERS' -s "${host^^}"/"$host"."$domain" -k my-keytab.keytab --computer-name "${host^^}" --upn "${host^^}$" --server "$full" --user-creds-only
msktutil -N -c -b 'CN=COMPUTERS' -s "${host^^}"/"$host" -k my-keytab.keytab --computer-name "${host^^}"  --upn "${host^^}$" --server "$full" --user-creds-only
kdestroy

#Configure sssd
sudo mv my-keytab.keytab /etc/sssd/my-keytab.keytab

echo '[sssd]' > /etc/sssd/sssd.conf
echo 'services = nss,pam' >> /etc/sssd/sssd.conf
echo 'config_file_version = 2' >> /etc/sssd/sssd.conf
echo "domains = $domain" >> /etc/sssd/sssd.conf
echo '' >> /etc/sssd/sssd.conf
echo '[nss]' >> /etc/sssd/sssd.conf
echo 'entry_negative_timeout = 0' >> /etc/sssd/sssd.conf
echo '' >> /etc/sssd/sssd.conf
echo '[pam]' >> /etc/sssd/sssd.conf
echo '' >> /etc/sssd/sssd.conf
echo "[domain/$domain]" >> /etc/sssd/sssd.conf
echo 'enumerate = false' >> /etc/sssd/sssd.conf
echo 'id_provider = ad' >> /etc/sssd/sssd.conf
echo 'auth_provider = ad' >> /etc/sssd/sssd.conf
echo 'chpass_provider = ad' >> /etc/sssd/sssd.conf
echo 'access_provider = ad' >> /etc/sssd/sssd.conf
echo 'dyndns_update = false' >> /etc/sssd/sssd.conf
echo "ad_hostname = $host.$domain" >> /etc/sssd/sssd.conf
echo "ad_server = $full" >> /etc/sssd/sssd.conf
echo "ad_domain = $domain" >> /etc/sssd/sssd.conf
echo 'ldap_schema = ad' >> /etc/sssd/sssd.conf
echo 'ldap_id_mapping = true' >> /etc/sssd/sssd.conf
echo 'fallback_homedir = /home/%u' >> /etc/sssd/sssd.conf
echo 'default_shell = /bin/bash' >> /etc/sssd/sssd.conf
echo 'ldap_sasl_mech = gssapi' >> /etc/sssd/sssd.conf
echo "ldap_sasl_authid = ${host^^}$" >> /etc/sssd/sssd.conf
echo 'krb5_keytab = /etc/sssd/my-keytab.keytab' >> /etc/sssd/sssd.conf
echo 'ldap_krb5_init_creds = true' >> /etc/sssd/sssd.conf

#change permissions 
sudo chmod 0600 /etc/sssd/sssd.conf

#configure pam file

echo 'session required pam_mkhomedir.so skel=/etc/skel umask=0077' >> /etc/pam.d/common-session

#restart sssd
sudo systemctl restart sssd

#add admin user to group
sudo adduser administrator sudo

#test login
#su -l adminstrator

echo "NOW RESTART AND LOGIN WITH THE USERNAME OF A DOMAIN USER. 
