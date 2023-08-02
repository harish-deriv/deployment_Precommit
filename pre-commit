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
if git log -1 > /dev/null 2>&1; then
    trufflehog git file://. --no-update --since-commit HEAD --fail > /tmp/trufflehog_output_$(whoami) 2>&1
    trufflehog_exit_code=$?
    echo $trufflehog_exit_code > /tmp/trufflehog_exit_code_$(whoami)
else
    trufflehog filesystem . --no-update --fail > /tmp/trufflehog_output_$(whoami) 2>&1
    trufflehog_exit_code=$?
    echo $trufflehog_exit_code > /tmp/trufflehog_exit_code_$(whoami)
fi

# Only display results to stdout if trufflehog found something.
if [ $trufflehog_exit_code -eq 183 ]; then
    cat /tmp/trufflehog_output_$(whoami)
    echo "TruffleHog found secrets. Aborting commit. use --no-verify to bypass it"
    exit $trufflehog_exit_code
fi
