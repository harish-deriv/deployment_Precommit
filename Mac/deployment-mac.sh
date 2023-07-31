#!/bin/bash

# echo '[1] Creating /etc/skel/.git/hooks'
# mkdir -p /etc/skel/.git/hooks
# echo '[A] /etc/skel/.git/hooks Created'

# Check if brew is installed - tested
if [[ -x /usr/local/bin/brew ]] || [[ -x /opt/homebrew/bin/brew ]] || [[ -x /usr/local/Homebrew/bin/brew ]]; then
    echo "[1] Brew is already installed - Installing Now..." >> /tmp/pre-commit-deployment.log
else
    echo "[1] Brew is not installed - Installing Now..." >> /tmp/pre-commit-deployment.log
    # Installing Brew
    curl https://raw.githubusercontent.com/kandji-inc/support/main/Scripts/InstallHomebrew.zsh > /tmp/kandji-brew-installation.sh
    interpreter='#!/bin/bash'
    sed -i "1s+.*+$interpreter+" kandji-brew-installation.sh
    /bin/bash /tmp/kandji-brew-installation.sh
    echo "[1.1] Brew installation Completed..." >> /tmp/pre-commit-deployment.log
fi


# Add Trufflehog pre-commit hook - tested
echo "[2] Generating Pre-Commit File..." >> /tmp/pre-commit-deployment.log
echo '#!/bin/bash
# Look for a local pre-commit hook in the repository
if [ -x .git/hooks/pre-commit ]; then
    .git/hooks/pre-commit || exit $?
fi

# Look for a local husky pre-commit hook in the repository
if [ -x .husky/pre-commit ]; then
    .git/hooks/pre-commit || exit $?
fi

# Use `filesysytem` if the git repo does not have any commits
if git log -1; then
    trufflehog git file://. --no-update --since-commit HEAD > trufflehog_output
else
    trufflehog filesystem . --no-update > trufflehog_output
fi

if [ -s trufflehog_output ]
then
    cat trufflehog_output
    rm trufflehog_output
    echo "TruffleHog found secrets. Aborting commit."
    exit 1
fi
rm trufflehog_output' > /tmp/pre-commit
echo '[2.1] Pre-Commit File generated under /tmp/pre-commit' >> /tmp/pre-commit-deployment.log


# Loop through all user directories and create a symbolic link to the global hooks - tested
# If it doens't work, we'll just place the precommit in all user home dir
#hookspath=
echo "[3] Configuring pre-commit configuration for all users" >> /tmp/pre-commit-deployment.log
basepath="/Users"
users=$(ls /Users/ | grep -viE "shared|.localized")
for user in $users; do

    # this command would fail, as `git` binary - tested
    if ! command -v git &> /dev/null; then
        echo "[4] Git not found, Installing Git." >> /tmp/pre-commit-deployment.log
        sudo -u 'securitytest' -i bash -c "brew install git"
        echo "[4.1] Git installation completed." >> /tmp/pre-commit-deployment.log
    fi

    # Download Trufflehog if it's not already installed - tested
    if [[ -x /usr/local/bin/trufflehog ]] || [[ -x /opt/homebrew/bin/trufflehog ]]; then
        echo "[5] Trufflehog already installed" >> /tmp/pre-commit-deployment.log
    else
        echo "[5] Downloading Trufflehog..." >> /tmp/pre-commit-deployment.log
        sudo -u $user -i bash -c "brew install trufflesecurity/trufflehog/trufflehog"
        echo "[5.1] Trufflehog Downloaded" >> /tmp/pre-commit-deployment.log
    fi

    homedir=$basepath/$user
    echo "/-------Configuring for $homedir-------/" >> /tmp/pre-commit-deployment.log
    
    global_hooksPath=$(sudo -u $user -i bash -c "git config --global --get core.hooksPath")
    echo "$user hooksPath (Before): $global_hooksPath" >> /tmp/pre-commit-deployment.log
    if [ -z $global_hooksPath ]; then
        global_hooksPath=$homedir/.git/hooks/
    fi
    echo "$user hookspath (After): $global_hooksPath" >> /tmp/pre-commit-deployment.log
        
    sudo -u $user -i bash -c "git config --global core.hooksPath $global_hooksPath"
    sudo -u $user -i bash -c "mkdir -p $global_hooksPath"
    sudo -u $user -i bash -c "echo -e '\n' >> $global_hooksPath/pre-commit" 
    sudo -u $user -i bash -c "cat /tmp/pre-commit >> $global_hooksPath/pre-commit"
    sudo -u $user -i bash -c "chmod +x $global_hooksPath/pre-commit"

    echo "/-------Configuration Completed for $homedir-------/" >> /tmp/pre-commit-deployment.log
done
echo "[3.1] pre-commit configuration completed for all users" >> /tmp/pre-commit-deployment.log



echo "[6] Configuring pre-commit configuration for Root user" >> /tmp/pre-commit-deployment.log
# Root user if in case they use root for commits
hookspath=$(sudo -u root -i bash -c "git config --get core.hooksPath")
echo "/-------Configuring for root-------/" >> /tmp/pre-commit-deployment.log

global_hooksPath=$(sudo -u root -i bash -c "git config --global --get core.hooksPath")
echo "Root hooksPath (Before): $global_hooksPath" >> /tmp/pre-commit-deployment.log
if [ -z $global_hooksPath ]; then
    global_hooksPath=/var/root/.git/hooks/
fi
echo "Root hooksPath (After): $global_hooksPath" >> /tmp/pre-commit-deployment.log
    
sudo -u root -i bash -c "git config --global core.hooksPath $global_hooksPath"
sudo -u root -i bash -c "mkdir -p $global_hooksPath"
sudo -u root -i bash -c "echo -e '\n' >> $global_hooksPath/pre-commit" 
sudo -u root -i bash -c "cat /tmp/pre-commit >> $global_hooksPath/pre-commit"
sudo -u root -i bash -c "chmod +x $global_hooksPath/pre-commit"

echo "/-------Configuration Completed for /var/root-------/" >> /tmp/pre-commit-deployment.log
echo "[6.1] pre-commit configuration completed for Root user" >> /tmp/pre-commit-deployment.log



# Test the pre-commit and pre-push hooks if secret not detected it sends a POST request to server indicating the user 
#### REPLACE REPO WITH ORG REPO WHERE USER CAN PUSH CODE TO
TEST_REPO_URL="https://github.com/harish-deriv/fake_repo_TEST9"
echo -e "\n\n/---------------------Running test on $TEST_REPO_URL...---------------------/" >> /tmp/pre-commit-deployment.log
SERIAL_NUMBER=$(ioreg -d2 -c IOPlatformExpertDevice | awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')
for user in $users; do
    homedir=$basepath/$user
    # Run the commands as the specific user
    if sudo -u "$user" -i bash -c "git clone '$TEST_REPO_URL' /tmp/fake_repo_TEST9;cd /tmp/fake_repo_TEST9 && cp creds newcreds && git --git-dir="/tmp/fake_repo_TEST9/.git" --work-tree="/tmp/fake_repo_TEST9" add . && git --git-dir="/tmp/fake_repo_TEST9/.git" --work-tree="/tmp/fake_repo_TEST9" commit -m 'test'"; then
        echo "Pre-commit hook doesn't work for the user $user - pre-commit returning exit code 0" >> /tmp/pre-commit-deployment.log
        rm -rf /tmp/fake_repo_TEST9
    else
        trufflehog_exit_code=$?
        rm -rf /tmp/fake_repo_TEST9
        if [[ $trufflehog_exit_code == 1 ]]; then
            echo "Pre-commit hook works for user $user" >> /tmp/pre-commit-deployment.log
        else
            echo "Pre-commit hook does not work for user $user" >> /tmp/pre-commit-deployment.log
            echo "Sending data to server: serial number=$SERIAL_NUMBER, username=$user" >> /tmp/pre-commit-deployment.log
            curl -X POST -d "serial_number=$SERIAL_NUMBER&username=$user" https://REPLACE_WITH_ELB:8443/endpoint -k -H "Authorization: token"
        fi
    fi
done

#ROOT USER CHECK
if sudo -u "root" -i bash -c "git clone '$TEST_REPO_URL' /tmp/fake_repo_TEST9;cd /tmp/fake_repo_TEST9 && cp creds newcreds && git --git-dir="/tmp/fake_repo_TEST9/.git" --work-tree="/tmp/fake_repo_TEST9" add . && git --git-dir="/tmp/fake_repo_TEST9/.git" --work-tree="/tmp/fake_repo_TEST9" commit -m 'test'"; then
    echo "Pre-commit hook does not work for user root - pre-commit returning exit code 0" >> /tmp/pre-commit-deployment.log
    curl -X POST -d "serial_number=$SERIAL_NUMBER&username=root" https://REPLACE_WITH_ELB:8443/endpoint -k -H "Authorization: TOKEN"
    rm -rf /tmp/fake_repo_TEST9
else
    trufflehog_exit_code=$?
    rm -rf /tmp/fake_repo_TEST9
    if [[ $trufflehog_exit_code == 1 ]]; then
        echo "Pre-commit hook works for user root" >> /tmp/pre-commit-deployment.log
    else
        echo "Pre-commit hook does not work for user root" >> /tmp/pre-commit-deployment.log
        echo "Sending data to server: serial number=$SERIAL_NUMBER, username=root" >> /tmp/pre-commit-deployment.log
        curl -X POST -d "serial_number=$SERIAL_NUMBER&username=root" https://REPLACE_WITH_ELB:8443/endpoint -k -H "Authorization: TOKEN"
    fi
fi