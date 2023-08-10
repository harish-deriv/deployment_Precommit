#!/bin/bash

# /---------------------------CONSTANTS-----------------------------------/

BASE_PATH="/Users"
ROOT_PATH="/var/root"
LOGPATH="/tmp/pre-commit-deployment.log"
PRECOMMIT_HOOK_PATH="/tmp/pre-commit"
TEST_LOGFILE="/tmp/precommit_test.log"

USERS=$(ls /Users/ | grep -viE "shared|.localized")

# /---------------------------Functions-----------------------------------/

# Temporarily generate pre-commit hook       file
function generate_precommit_file () {
    echo "[2] Generating Pre-Commit File..." >> $LOGPATH
    echo '#!/bin/bash

    function get_precommit_hook(){
        pre_commit_hook=$(curl -fsSL "$1" 2>&1)
        if [ $? -ne 0 ]; then
            echo "Please check your internet and then run again. add --no-verify flag to git commit if this error persists"
            exit 1
        else
            echo "$pre_commit_hook" | /bin/bash
        fi
    }

    get_precommit_hook https://gist.githubusercontent.com/security-binary/29086ac0a834564da2e0da64dd05c728/raw/07344d69825609ad678613d90e6d0ac1a40595eb/pre-commit.sh' > $PRECOMMIT_HOOK_PATH
    echo "[2.1] Pre-Commit File generated under $PRECOMMIT_HOOK_PATH" >> $LOGPATH
}

function precommit_configuration () {
    # Loop through all user directories and create a symbolic link to the global hooks - tested
    # If it doens't work, we'll just place the precommit in all user home dir
    #hookspath=
    echo "[2] Configuring pre-commit configuration for all users" >> $LOGPATH
    for user in $USERS; do

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
        sudo -u $user -i bash -c "cat $PRECOMMIT_HOOK_PATH >> $global_hooksPath/pre-commit"
        sudo -u $user -i bash -c "chmod +x $global_hooksPath/pre-commit"

        echo "/-------Configuration Completed for $homedir-------/" >> $LOGPATH
    done
    echo "[2.1] pre-commit configuration completed for all users" >> $LOGPATH
}


function precommit_configuration_root () {
    echo "[5] Configuring pre-commit configuration for Root user" >> $LOGPATH
    # Root user if in case they use root for commits
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
    sudo -u root -i bash -c "cat $PRECOMMIT_HOOK_PATH >> $global_hooksPath/pre-commit"
    sudo -u root -i bash -c "chmod +x $global_hooksPath/pre-commit"

    echo "/-------Configuration Completed for $ROOT_PATH-------/" >> $LOGPATH
    echo "[5.1] pre-commit configuration completed for Root user" >> $LOGPATH
}

function install_git_truffle(){
    for user in $USERS; do
        # this command would fail, as `git` binary - tested
        if ! command -v git &> /dev/null; then
            echo "[3] Git not found, Installing Git." >> $LOGPATH
            sudo -u $user -i bash -c "brew install git"
            echo "[3.1] Git installation completed." >> $LOGPATH
        fi

        # Download Trufflehog if it's not already installed - tested
        if [[ -x /usr/local/bin/trufflehog ]] || [[ -x /opt/homebrew/bin/trufflehog ]]; then
            echo "[4] Trufflehog already installed" >> $LOGPATH
        else
            echo "[4] Downloading Trufflehog..." >> $LOGPATH
            sudo -u $user -i bash -c "brew install trufflesecurity/trufflehog/trufflehog"
            echo "[4.1] Trufflehog Downloaded" >> $LOGPATH
            if [[ -x /usr/local/bin/trufflehog ]] || [[ -x /opt/homebrew/bin/trufflehog ]]; then
                echo "Trufflehog  properly configured for $user" >> $LOGPATH
            else
                echo "Trufflehog not properly configured for $user. Please check manually" >> $LOGPATH
            fi
        fi
    done
}

curl_command='bash -c "$(curl -fsSL https://raw.githubusercontent.com/security-binary/deployment_Precommit/main/testing_script.sh)"'
#logic to perform automated test for the users
function automated_test(){
    for user in $USERS; do
        sudo -u "$user" -i bash -c "$curl_command"
        echo "$user user testing results: "
        sudo -u "$user" -i bash -c "cat $TEST_LOGFILE"
        sudo -u "$user" -i bash -c "rm $TEST_LOGFILE"
    done
}

# /----------------------------MAIN----------------------------------/
# Setting up Pre-commit

rm $LOGPATH
generate_precommit_file
precommit_configuration
precommit_configuration_root
install_git_truffle

## Requires more testing - DO NOT USE IN DEPLOYMENT
automated_test
cat $LOGPATH