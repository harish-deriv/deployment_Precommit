#!/bin/bash

TEST_LOGFILE="/tmp/precommit_test.log"
TEST_GIT_REPO="https://github.com/harish-deriv/fake_repo_TEST9"

#1. Create 1 new file and commit. - commit should succed due to zero secrets in commit
invoke_test_1(){
    touch newcreds
    git add .
    git commit -m "test"
    if [ $? -ne 0 ]; then
        echo "Test 1 failed" | tee -a $TEST_LOGFILE
    else
        echo "Test 1 succeded" | tee -a $TEST_LOGFILE
    fi
}

#2. cp creds to newfile and commit - commit should fail due to secrets in newcreds
invoke_test_2(){
    cp creds newcreds
    git add .
    git commit -m "test"
    if [ $? -ne 0 ]; then
        echo "Test 2 succeded" | tee -a $TEST_LOGFILE
    else
        echo "Test 2 failed" | tee -a $TEST_LOGFILE
    fi
}

#3. cp creds to newfile and commit with —no-verify flag - commit should succed as precommit hook is bypassed
invoke_test_3(){
    git commit -m "test" --no-verify
    if [ $? -ne 0 ]; then
        echo "Test 3 failed" | tee -a $TEST_LOGFILE
    else
        echo "Test 3 succeded" | tee -a $TEST_LOGFILE
    fi
}

#4. append newfile content to creds, delete newfile and commit - commit should fail due to secrets in newcreds
invoke_test_4(){
    cat newcreds >> creds
    rm newcreds
    git add .
    git commit -m "Test4"
     if [ $? -ne 0 ]; then
        echo "Test 4 succeded" | tee -a $TEST_LOGFILE
    else
        echo "Test 4 failed" | tee -a $TEST_LOGFILE
    fi
}

#5. append newfile content to creds, delete newfile and commit with —no-verify flag - success
invoke_test_5(){
    git commit -m "Test4" --no-verify
    if [ $? -ne 0 ]; then
        echo "Test 5 failed" | tee -a $TEST_LOGFILE
    else
        echo "Test 5 succeded" | tee -a $TEST_LOGFILE
    fi
}


cd /tmp
rm -rf /tmp/fake_repo_TEST9
rm $TEST_LOGFILE
git clone $TEST_GIT_REPO
cd fake_repo_TEST9/

invoke_test_1
invoke_test_2
invoke_test_3
invoke_test_4
invoke_test_5