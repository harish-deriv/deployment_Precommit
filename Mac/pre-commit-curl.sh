#!/bin/bash

function get_precommit_hook(){
	pre_commit_hook=$(curl -fsSL "$1" 2>&1)
   	if [ $? -ne 0 ]; then
    		echo "Please check your internet and then run again. add --no-verify flag to git commit if this error persists"
		exit 1
	else
		echo "$pre_commit_hook" | /bin/bash
    fi
}

get_precommit_hook https://raw.githubusercontent.com/WengOnn-Deriv/deployment_Precommit/main/pre-commit.sh
