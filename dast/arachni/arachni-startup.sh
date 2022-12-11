#!/bin/bash
# Arachni Web Bootstrap

genpass() {
    cat /dev/urandom | tr -cd 'A-Za-z0-9' | fold -w 20 | head -1
}

setpass() {
    echo ""
    echo "Changing the default password..."
    pass=$(genpass)
    arachni_web_change_password "admin@admin.admin" "$pass"
    echo "Your new credentials are as follows..."
    echo
    echo -e "\e[32m[*] Username: admin@admin.admin \e[0m"
    echo -e "\e[32m[*] Password: $pass \e[0m"

}

database() {
    arachni_web_task db:version 2>&1 | grep 'Did you run the migration'
    
    if [ $? -eq 0 ];
    then
        echo "Setting up database..."
        arachni_web_task db:setup

        setpass
    fi
}

startup() {
    echo
    echo "Booting web server...."
    echo
    arachni_web --host 0.0.0.0
}

database
credits
startup
