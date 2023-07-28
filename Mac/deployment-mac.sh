#!/bin/bash

echo '[1] Creating /etc/skel/.git/hooks'
mkdir -p /etc/skel/.git/hooks
echo '[A] /etc/skel/.git/hooks Created'

# Check if brew is installed 
if [[ -x /usr/local/bin/brew ]] || [[ -x /opt/homebrew/bin/brew ]] || [[ -x /usr/local/Homebrew/bin/brew ]]; then
    echo "[2] Brew is already installed - Installing Now..."
else
    echo "[2] Brew is not installed - Installing Now..."
    # Installing Brew
    curl https://raw.githubusercontent.com/kandji-inc/support/main/Scripts/InstallHomebrew.zsh > /tmp/kandji-brew-installation.sh
    interpreter='#!/bin/bash'
    sed -i "1s+.*+$interpreter+" kandji-brew-installation.sh
    /bin/bash /tmp/kandji-brew-installation.sh
    echo "[B] Brew installation Completed..."
fi


# Add Trufflehog pre-commit hook
echo "[6] Generating Pre-Commit File..."

echo '#!/bin/sh
# Look for a local pre-commit hook in the repository
if [ -x .git/hooks/pre-commit ]; then
    .git/hooks/pre-commit || exit $?
fi

# Look for a local husky pre-commit hook in the repository
if [ -x .husky/pre-commit ]; then
    .git/hooks/pre-commit || exit $?
fi

trufflehog git file://. --since-commit HEAD > trufflehog_output.json
if [ -s trufflehog_output.json ]
then
    cat trufflehog_output.json
    rm trufflehog_output.json
    echo "TruffleHog found secrets. Aborting commit."
    exit 1
fi
rm trufflehog_output.json' > /tmp/pre-commit
echo '[E] Pre-Commit File generated under /etc/skel/.git/hooks/pre-commit'


# Loop through all user directories and create a symbolic link to the global hooks
# If it doens't work, we'll just place the precommit in all user home dir
#hookspath=
echo "[7] Configuring pre-commit configuration for all users"
basepath="/Users"
users=$(ls /Users/ | grep -viE "shared|.localized")
for user in $users; do

    # this command would fail, as `git` binary 
    if ! command -v git &> /dev/null; then
        echo "[3] Git not found, Installing Git."
        sudo -u 'securitytest' -i bash -c "brew install git"
        echo "[C] Git installation completed."
    fi

    # Download Trufflehog if it's not already installed
    if [[ -x /usr/local/bin/trufflehog ]] || [[ -x /opt/homebrew/bin/trufflehog ]]; then
        echo "[5] Trufflehog already installed"
    else
        echo "[5] Downloading Trufflehog..."
        sudo -u $user -i bash -c "/usr/local/bin/brew install trufflesecurity/trufflehog/trufflehog"
        echo "[D] Trufflehog Downloaded"
    fi

    homedir=$basepath/$user
    echo "/-------Configuring for $homedir-------/"
    
    global_hooksPath=$(sudo -u $user -i bash -c "git config --global --get core.hooksPath")
    echo Test $global_hooksPath
    if [ -z $global_hooksPath ]; then
        global_hooksPath=$homedir/.git/hooks/
        echo Inside if $global_hooksPath
    fi
    echo User is $user with hookspath $global_hooksPath;
        
    sudo -u $user -i bash -c "git config --global core.hooksPath $global_hooksPath"
    sudo -u $user -i bash -c "mkdir -p $global_hooksPath"
    sudo -u $user -i bash -c "echo -e '\n' >> $global_hooksPath/pre-commit" 
    sudo -u $user -i bash -c "cat /tmp/pre-commit >> $global_hooksPath/pre-commit"
    sudo -u $user -i bash -c "chmod +x $global_hooksPath/pre-commit"
    sudo -u $user -i bash -c "rm /tmp/pre-commit"

    echo "/-------Configuration Completed for $homedir-------/"
done
echo "[F] pre-commit configuration completed for all users"



echo "[8] Configuring pre-commit configuration for Root user"
# Root user if in case they use root for commits
hookspath=$(sudo git config --get core.hooksPath)
if [ -d "${hookspath}" ]; then
    if [ -f "${hookspath}/pre-commit"]; then
      echo "\n" >> "${hookspath}/pre-commit" 
      cat /etc/skel/.git/hooks/pre-commit >> "${hookspath}/pre-commit"
    else
        touch "${hookspath}/pre-commit"
        ln -sf /etc/skel/.git/hooks/pre-commit "/var/root/.git/hooks/pre-commit"
    fi
else
    git config --global core.hooksPath /var/root/.git/hooks/
    mkdir -p /var/root/.git/hooks
fi
echo "[G] pre-commit configuration completed for Root user"


echo "/---------------------Running test on $TEST_REPO_URL...---------------------/"
# Test the pre-commit and pre-push hooks if secret not detected it sends a POST request to server indicating the user 
#### REPLACE REPO WITH ORG REPO WHERE USER CAN PUSH CODE TO
TEST_REPO_URL="https://github.com/harish-deriv/fake_repo_TEST9"
SERIAL_NUMBER=$(ioreg -d2 -c IOPlatformExpertDevice | awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')
for user in $users; do
    homedir=$basepath/$user
    if [ -d "$homedir" ]; then
        # Run the commands as the specific user
        if sudo -u "$user" bash -c "git clone '$TEST_REPO_URL' /tmp/fake_repo_TEST9;cd /tmp/fake_repo_TEST9 && touch \'$(openssl rand -hex 16).txt\' && git add . && git commit -m 'test'"; then
            echo "Pre-commit hook works for user $user"
            rm -rf /tmp/fake_repo_TEST9
        else
            rm -rf /tmp/fake_repo_TEST9
            echo "Pre-commit hook does not work for user $user"
            sudo -i "$user" bash -c 'cd /tmp/fake_repo_TEST9; git commit -m "TEST"'
        #    username_encoded=$(echo -n "$user" | base64)
            echo "Sending data to server: serial number=$SERIAL_NUMBER, username=$user"
            #curl -X POST -d "serial_number=$SERIAL_NUMBER&username=$user" https://localhost:8443/endpoint -k -H "Authorization: Bearer token"
        fi
    fi
done

#ROOT USER CHECK
if sudo bash -c "git clone '$TEST_REPO_URL' /tmp/fake_repo_TEST9;cd /tmp/fake_repo_TEST9 && touch \'$(openssl rand -hex 16).txt\' && git add . && git commit -m 'test'"; then
    echo "Pre-commit hook works for user root"
    rm -rf /tmp/fake_repo_TEST9
else
    rm -rf /tmp/fake_repo_TEST9
    echo "Pre-commit hook does not work for user root"
    sudo bash -c 'cd /tmp/fake_repo_TEST9; git commit -m "TEST"'
  #  username_encoded=$(echo -n "$user" | base64)
    echo "Sending data to server: serial number=$SERIAL_NUMBER, username=root"
    #curl -X POST -d "serial_number=$SERIAL_NUMBER&username=root" https://localhost:8443/endpoint -k -H "Authorization: Bearer token"
fi
