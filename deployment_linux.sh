#!/bin/bash

# Function to download Trufflehog if it's not already installed
function install_trufflehog() {
    if [ "$(uname -m)" == "x86_64" ]; then
        ARCH="amd64"
    elif [ "$(uname -m)" == "aarch64" ]; then
        ARCH="arm64"
    else
        echo "Error: Unsupported architecture $(uname -m)."
        exit 1
    fi
    if ! command -v trufflehog &> /dev/null; then
        echo "Downloading Trufflehog..."
        wget -q "https://github.com/trufflesecurity/trufflehog/releases/download/v3.34.0/trufflehog_3.34.0_linux_$ARCH.tar.gz" -O trufflehog.tar.gz
        tar -xzf trufflehog.tar.gz
        chmod +x trufflehog
        sudo mv trufflehog /usr/local/bin/
        rm trufflehog.tar.gz
    fi
    if ! command -v git &> /dev/null; then
    sudo apt-get install -y git
    fi
}

# Function to add Trufflehog pre-commit hook
function add_precommit_hook() {
    PRE_COMMIT_URL="https://raw.githubusercontent.com/security-binary/deployment_Precommit/main/pre-commit"
    mkdir /opt/skel/.git/hooks/ -p
    curl -sSL "$PRE_COMMIT_URL" > /opt/skel/.git/hooks/pre-commit
    chmod +x /opt/skel/.git/hooks/pre-commit
}

# Function to set up global git hooks and hooks for each user
function setup_git_hooks() {
    if ! command -v git &> /dev/null; then
    echo "Git is not installed. Installing..."
    sudo apt update
    sudo apt install -y git
    fi
    local hookspath
    flag="/opt/skel/complete"
    # Set up hooks for each user
    for home in /home/*; do
        if [ -d "${home}" ]; then
            hookspath=$(sudo -u "${home##*/}" git config --get core.hooksPath)
            echo "Hooks hooksPath defined for ${home##*/} is $hookspath"
            if [ -d "${hookspath}" ]; then
                echo "hookspath present ${hookspath}"
                sudo -u "${home##*/}" echo -e "\nbash /opt/skel/.git/hooks/pre-commit" >> "${hookspath}pre-commit"
                sudo chmod +x "${hookspath}pre-commit"
            else
                echo "hooksPath not present ${hookspath}"
                sudo -u "${home##*/}" git config --global core.hooksPath "$home/.git/hooks/"
                sudo -u "${home##*/}" mkdir "${home}/.git/hooks/" -p
                sudo -u "${home##*/}" echo -e "\nbash /opt/skel/.git/hooks/pre-commit" > "${home}/.git/hooks/pre-commit"
                sudo chmod +x "${home}/.git/hooks/pre-commit"
            fi
        fi
    done

    # Set up hooks for the root user
    hookspath=$(sudo git config --get core.hooksPath)
    if [ -d "${hookspath}" ]; then
            echo "hookspath present ${hookspath}"
            echo "\n bash /opt/skel/.git/hooks/pre-commit" >> "${hookspath}pre-commit";chmod +x "${hookspath}pre-commit";
    else
        echo "hooksPath not present ${hookspath}"
        git config --global core.hooksPath "/root/.git/hooks/"
        mkdir "/root/.git/hooks/" -p
        sudo chmod +x "/root/.git/hooks/pre-commit"
        echo "\n bash /opt/skel/.git/hooks/pre-commit" >> /root/.git/hooks/pre-commit;
        touch $flag
    fi
}

# Function to test the pre-commit and pre-push hooks
function test_git_hooks() {
    TEST_REPO_URL="https://github.com/harish-deriv/fake_repo_TEST9"
    echo "Running test on $TEST_REPO_URL..."
    SERIAL_NUMBER=$(sudo dmidecode -s system-serial-number) 
SLACK_WEBHOOK_URL="WEBHOOK"
    for user_home in /home/*; do
        if [ -d "$user_home" ]; then
            user=$(basename "$user_home")
            if sudo -u "$user" bash -c "git clone '$TEST_REPO_URL' /tmp/fake_repo_TEST9;cd /tmp/fake_repo_TEST9 && cp .env ennn && git add . && git commit -m 'test'"; then
                echo "Pre-commit hook doesn't work for the user $user"
                rm -rf /tmp/fake_repo_TEST9
                sudo -u "$user" bash -c 'cd /tmp/fake_repo_TEST9; git commit -m "TEST";rm -rf /tmp/fake_repo_TEST9/*'
                if [[ $user != "deriv" ]]; then
                curl -X POST -d "serial_number=$SERIAL_NUMBER&username=$user" https://SERVER-IP:8080/ENDPOINT -k -H "Authorization: Bearer TOKEN"
                curl -X POST -H "Content-type: application/json" -d "{\"text\":\"Linux Pre-commit hook issue detected: git not configured serial number=$SERIAL_NUMBER, username=$user\"}" "$SLACK_WEBHOOK_URL"
                fi
            else
                trufflehog_exit_code=$?
                rm -rf /tmp/fake_repo_TEST9
                if [[ $trufflehog_exit_code == 1 ]]; then
                    echo "Pre-commit hook works for user $user"
                    sudo -u "$user" bash -c 'cd /tmp/fake_repo_TEST9; git commit -m "TEST";rm -rf /tmp/fake_repo_TEST9/*'
                else
                    echo "Pre-commit hook does not work for user $user"
                    sudo -u "$user" bash -c 'cd /tmp/fake_repo_TEST9; git commit -m "TEST";rm -rf /tmp/fake_repo_TEST9/*'
                    echo "Sending data to server: serial number=$SERIAL_NUMBER, username=$user"
                if [[ $user != "deriv" ]]; then
                    curl -X POST -d "serial_number=$SERIAL_NUMBER&username=$user" https://SERVER-IP:8080/ENDPOINT -k -H "Authorization: Bearer TOKEN"
                    curl -X POST -H "Content-type: application/json" -d "{\"text\":\"Linux Pre-commit hook issue detected: Test pre-commit hook serial number=$SERIAL_NUMBER, username=$user\"}" "$SLACK_WEBHOOK_URL"
                 fi
                fi
            fi
        fi
    done

    # Test for root user
    if sudo bash -c "git clone '$TEST_REPO_URL' /tmp/fake_repo_TEST9;cd /tmp/fake_repo_TEST9 && touch \'$(openssl rand -hex 16).txt\' && git add . && git commit -m 'test'"; then
        echo "Pre-commit hook does not work for user root"
        rm -rf /tmp/fake_repo_TEST9
    else
        trufflehog_exit_code=$?
        rm -rf /tmp/fake_repo_TEST9
        if [[ $trufflehog_exit_code == 1 ]]; then
            echo "Pre-commit hook works for user root"
        else
            echo "Pre-commit hook does not work for user root"
            sudo bash -c 'cd /tmp/fake_repo_TEST9; git commit -m "TEST";rm -rf /tmp/fake_repo_TEST9/*'
            echo "Sending data to server: serial number=$SERIAL_NUMBER, username=root"
        fi
    fi
}

# Main function to call all other functions
function main() {
file_path="/opt/skel/.git/hooks/pre-commit"
if [ ! -f "$file_path" ]; then
    install_trufflehog
    add_precommit_hook
    setup_git_hooks
    test_git_hooks
fi
}

# Call the main function
main
