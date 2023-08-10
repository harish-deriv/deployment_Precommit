#!/bin/bash

#script to perform manual cleanup of the pre-commit deployment

USERS=$(ls /Users/ | grep -viE "shared|.localized")

for user in $USERS
do
        rm -rfv /Users/$user/.git*                                         
done       
rm -rfv /var/root/.git* /tmp/pre-commit* /tmp/precommit* /tmp/trufflehog*