#!/bin/bash

#script to perform manual cleanup of the pre-commit deployment

USERS=$(ls /Users/ | grep -viE "shared|.localized")

for user in $USERS
do
        sudo rm -rfv /Users/$user/.git*
        sudo -u $user -i bash -c "brew uninstall git"
        sudo -u $user -i bash -c "brew uninstall trufflehog"                                        
done 
      
sudo rm -rfv /var/root/.git* /tmp/pre-commit* /tmp/precommit* /tmp/trufflehog*