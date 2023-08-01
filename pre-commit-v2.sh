#!/bin/bash
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
fi
