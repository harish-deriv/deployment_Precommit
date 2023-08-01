#!/bin/bash

echo '[1] Creating /opt/skel/.git/hooks'
mkdir -p /opt/skel/.git/hooks
echo '[A] /opt/skel/.git/hooks Created'

# /---------------------------CONSTANTS-----------------------------------/
TEST_REPO_URL="https://github.com/harish-deriv/fake_repo_TEST9"
TEST_REPO_PATH="/tmp/fake_repo_TEST9"

BASE_PATH="/Users"
ROOT_PATH="/var/root"
PRECOMMIT_HOOK_PATH="/opt/skel/.git/hooks/pre-commit"
TRUFFLEHOG_EXIT_CODE_PATH="/tmp/trufflehog_exit_code"

LOGPATH="/tmp/pre-commit-deployment.log"

SERIAL_NUMBER=$(ioreg -d2 -c IOPlatformExpertDevice | awk -F\" '/IOPlatformSerialNumber/{print $(NF-1)}')

USERS=$(ls /Users/ | grep -viE "shared|.localized|PKXWMW1445|temp")

# /---------------------------Functions-----------------------------------/

# Check if brew is installed - tested
function brew_installation () {
    if [[ -x /usr/local/bin/brew ]] || [[ -x /opt/homebrew/bin/brew ]] || [[ -x /usr/local/Homebrew/bin/brew ]]; then
        echo "[1] Brew is already installed - Installing Now..." >> $LOGPATH
    else
        echo "[1] Brew is not installed - Installing Now..." >> $LOGPATH
        # Installing Brew
        curl https://raw.githubusercontent.com/kandji-inc/support/main/Scripts/InstallHomebrew.zsh > /tmp/kandji-brew-installation.sh
        interpreter='#!/bin/bash'
        sed -i "1s+.*+$interpreter+" kandji-brew-installation.sh
        /bin/bash /tmp/kandji-brew-installation.sh
        echo "[1.1] Brew installation Completed..." >> $LOGPATH
    fi
}


# Add Trufflehog pre-commit hook - tested
function generate_precommit_file () {
    echo "[2] Generating Pre-Commit File..." >> $LOGPATH
    echo '#!/bin/bash
# Look for a local pre-commit hook in the repository
if [ -x .git/hooks/pre-commit ]; then
    .git/hooks/pre-commit || exit $?
fi

# Look for a local husky pre-commit hook in the repository
if [ -x .husky/pre-commit ]; then
    .husky/pre-commit || exit $?
fi

# Use `filesysytem` if the git repo does not have any commits i.e its a new git repo.
if git log -1; then
    echo "global gittt"
    trufflehog git file://. --no-update --since-commit HEAD --fail > /tmp/trufflehog_output_$(whoami) 2>&1
    trufflehog_exit_code=$?
    echo $trufflehog_exit_code > /tmp/trufflehog_exit_code
else
    echo "global fileystemmm"
    trufflehog filesystem . --no-update --fail > /tmp/trufflehog_output_$(whoami) 2>&1
    trufflehog_exit_code=$?
    echo $trufflehog_exit_code > /tmp/trufflehog_exit_code
fi
if [ $trufflehog_exit_code -eq 183 ]; then
    cat /tmp/trufflehog_output_$(whoami)
    exit $trufflehog_exit_code
fi' > $PRECOMMIT_HOOK_PATH
    echo "[2.1] Pre-Commit File generated under $PRECOMMIT_HOOK_PATH" >> $LOGPATH
}


function precommit_configuration () {
    # Loop through all user directories and create a symbolic link to the global hooks - tested
    # If it doens't work, we'll just place the precommit in all user home dir
    #hookspath=
    echo "[3] Configuring pre-commit configuration for all users" >> $LOGPATH
    for user in $USERS; do

        # this command would fail, as `git` binary - tested
        if ! command -v git &> /dev/null; then
            echo "[4] Git not found, Installing Git." >> $LOGPATH
            sudo -u 'securitytest' -i bash -c "brew install git"
            echo "[4.1] Git installation completed." >> $LOGPATH
        fi

        # Download Trufflehog if it's not already installed - tested
        if [[ -x /usr/local/bin/trufflehog ]] || [[ -x /opt/homebrew/bin/trufflehog ]]; then
            echo "[5] Trufflehog already installed" >> $LOGPATH
        else
            echo "[5] Downloading Trufflehog..." >> $LOGPATH
            sudo -u $user -i bash -c "brew install trufflesecurity/trufflehog/trufflehog"
            echo "[5.1] Trufflehog Downloaded" >> $LOGPATH
        fi

        homedir=$BASE_PATH/$user
        echo "/-------Configuring for $homedir-------/" >> $LOGPATH
        
        global_hooksPath=$(sudo -u $user -i bash -c "git config --global --get core.hooksPath")
        echo "$user hooksPath (Before): $global_hooksPath" >> $LOGPATH
        if [ -z $global_hooksPath ]; then
            global_hooksPath=$homedir/.git/hooks/
        fi
        echo "$user hookspath (After): $global_hooksPath" >> $LOGPATH
            
        sudo -u $user -i bash -c "git config --global core.hooksPath $global_hooksPath"
        sudo -u $user -i bash -c "mkdir -p $global_hooksPath"
        sudo -u $user -i bash -c "echo -e '\n' >> $global_hooksPath/pre-commit" 
        sudo -u $user -i bash -c "echo -e '#!/bin/bash\n/bin/bash $PRECOMMIT_HOOK_PATH' >> $global_hooksPath/pre-commit"
        sudo -u $user -i bash -c "chmod +x $global_hooksPath/pre-commit"

        echo "/-------Configuration Completed for $homedir-------/" >> $LOGPATH
    done
    echo "[3.1] pre-commit configuration completed for all users" >> $LOGPATH
}


function precommit_configuration_root () {
    echo "[6] Configuring pre-commit configuration for Root user" >> $LOGPATH
    # Root user if in case they use root for commits
    hookspath=$(sudo -u root -i bash -c "git config --get core.hooksPath")
    echo "/-------Configuring for root-------/" >> $LOGPATH

    global_hooksPath=$(sudo -u root -i bash -c "git config --global --get core.hooksPath")
    echo "Root hooksPath (Before): $global_hooksPath" >> $LOGPATH
    if [ -z $global_hooksPath ]; then
        global_hooksPath=$ROOT_PATH/.git/hooks/
    fi
    echo "Root hooksPath (After): $global_hooksPath" >> $LOGPATH
        
    sudo -u root -i bash -c "git config --global core.hooksPath $global_hooksPath"
    sudo -u root -i bash -c "mkdir -p $global_hooksPath"
    sudo -u root -i bash -c "echo -e '\n' >> $global_hooksPath/pre-commit" 
    sudo -u root -i bash -c "echo -e '#!/bin/bash\n/bin/bash $PRECOMMIT_HOOK_PATH' >> $global_hooksPath/pre-commit"
    sudo -u root -i bash -c "chmod +x $global_hooksPath/pre-commit"

    echo "/-------Configuration Completed for $ROOT_PATH-------/" >> $LOGPATH
    echo "[6.1] pre-commit configuration completed for Root user" >> $LOGPATH
}


# Takes in two arguments: username, commit message
function commit_repo () {
    ### Note ###
    # 1. If there are nothing to commit, git would return exit code 1
    
    # Run the commands as the specific user

    sudo -u "$1" bash -c "git clone '$TEST_REPO_URL' $TEST_REPO_PATH"
    sudo -u "$1" bash -c "touch $TEST_REPO_PATH/test-1" # This is to make sure that the repo returns exit codo 0 if something when wrong with the trufflehog scan 
    sudo -u "$1" bash -c "cp $TEST_REPO_PATH/creds $TEST_REPO_PATH/newcreds"
    sudo -u "$1" bash -c "git --git-dir="$TEST_REPO_PATH/.git" --work-tree="$TEST_REPO_PATH" add ."
    sudo -u "$1" bash -c "git --git-dir="$TEST_REPO_PATH/.git" --work-tree="$TEST_REPO_PATH" commit -m '$2'"
    precommit_exit_code=$(cat $TRUFFLEHOG_EXIT_CODE_PATH) # return 1 if precommit detects secrets, return 0 if precommit does not detects secrets
    rm -rf $TEST_REPO_PATH 
}


# Test the pre-commit and pre-push hooks if secret not detected it sends a POST request to server indicating the user 
#### REPLACE REPO WITH ORG REPO WHERE USER CAN PUSH CODE TO
function test_precommit () {
    echo -e "\n\n/---------------------Running test on $TEST_REPO_URL...---------------------/" >> $LOGPATH
    for user in $USERS; do
        homedir=$BASE_PATH/$user

        commit_repo "$user" "Testing Pre-Commit for $user"
        if [[ $precommit_exit_code -eq 0 ]]
        then
            message="Trufflehog found no secrets with no errors"
            echo "Trufflehog found no secrets with no errors for the user $user - pre-commit returning exit code: $precommit_exit_code" >> $LOGPATH
            echo "Sending data to server: serial number=$SERIAL_NUMBER, username=$user, pre-commit exit code=$precommit_exit_code" >> $LOGPATH
            curl -X POST -d "serial_number=$SERIAL_NUMBER&username=$user&exit_code=$precommit_exit_code&message=$message" https://REPLACE_WITH_ELB:8443/endpoint -k -H "Authorization: token"
        elif [[ $precommit_exit_code -eq 183 ]]
        then
            message="Trufflehog found secrets with no errors"
            echo "Trufflehog found secrets with no errors for the $user - pre-commit returning exit code: $precommit_exit_code" >> $LOGPATH
            echo "Sending data to server: serial number=$SERIAL_NUMBER, username=$user, pre-commit exit code=$precommit_exit_code" >> $LOGPATH
            curl -X POST -d "serial_number=$SERIAL_NUMBER&username=$user&exit_code=$precommit_exit_code&message=$message" https://REPLACE_WITH_ELB:8443/endpoint -k -H "Authorization: token"
        else
            message="Trufflehog had some error"
            echo "Trufflehog had some error for the user $user - pre-commit returning exit code: $precommit_exit_code" >> $LOGPATH
            echo "Sending data to server: serial number=$SERIAL_NUMBER, username=$user, pre-commit exit code=$precommit_exit_code" >> $LOGPATH
            curl -X POST -d "serial_number=$SERIAL_NUMBER&username=$user&exit_code=$precommit_exit_code&message=$message" https://REPLACE_WITH_ELB:8443/endpoint -k -H "Authorization: token"
        fi
    done
}


#ROOT USER CHECK
function test_precommit_root () {

    user="root"

    commit_repo "$user" "Testing Pre-Commit for $user"
    if [[ $precommit_exit_code -eq 0 ]]
    then
        message="Trufflehog found no secrets with no errors"
        echo "Trufflehog found no secrets with no errors for the user $user - pre-commit returning exit code: $precommit_exit_code" >> $LOGPATH
        echo "Sending data to server: serial number=$SERIAL_NUMBER, username=$user, pre-commit exit code=$precommit_exit_code" >> $LOGPATH
        curl -X POST -d "serial_number=$SERIAL_NUMBER&username=$user&exit_code=$precommit_exit_code&message=$message" https://REPLACE_WITH_ELB:8443/endpoint -k -H "Authorization: token"
    elif [[ $precommit_exit_code -eq 183 ]]
    then
        message="Trufflehog found secrets with no errors"
        echo "Trufflehog found secrets with no errors for the $user - pre-commit returning exit code: $precommit_exit_code" >> $LOGPATH
        echo "Sending data to server: serial number=$SERIAL_NUMBER, username=$user, pre-commit exit code=$precommit_exit_code" >> $LOGPATH
        curl -X POST -d "serial_number=$SERIAL_NUMBER&username=$user&exit_code=$precommit_exit_code&message=$message" https://REPLACE_WITH_ELB:8443/endpoint -k -H "Authorization: token"
    else
        message="Trufflehog had some error"
        echo "Trufflehog had some error for the user $user - pre-commit returning exit code: $precommit_exit_code" >> $LOGPATH
        echo "Sending data to server: serial number=$SERIAL_NUMBER, username=$user, pre-commit exit code=$precommit_exit_code" >> $LOGPATH
        curl -X POST -d "serial_number=$SERIAL_NUMBER&username=$user&exit_code=$precommit_exit_code&message=$message" https://REPLACE_WITH_ELB:8443/endpoint -k -H "Authorization: token"
    fi
}

# /----------------------------MAIN----------------------------------/
# Setting up Pre-commit
#brew_installation
generate_precommit_file 
#precommit_configuration
#precommit_configuration_root

## Require more testing
test_precommit
# test_precommit_root
