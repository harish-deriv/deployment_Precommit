$TEST_LOGFILE = "C:\tmp\precommit_test.log"
$TEST_GIT_REPO = "https://github.com/harish-deriv/fake_repo_TEST9"

if (!(Test-Path -Path "C:\tmp" -PathType "Container")){
    mkdir "C:\tmp" 1>$null
    Write-Host "Tmp Directory Created"
}

function _log($message) {
    Write-Host "$message"
    Write-Output "$message" >> $TEST_LOGFILE
}

function Invoke-Test1 {
    New-Item -ItemType File -Name "newcreds" | Out-Null
    git add .
    git commit -m "test1"
    if ($? -eq $false) {
        _log "Test 1 Failed"
    } else {
        _log "Test 1 Succeeded"
    }
}

function Invoke-Test2 {
    Copy-Item "creds" -Destination "newcreds"
    git add .
    git commit -m "test2"
    if ($? -eq $false) {
        _log "Test 2 Succeeded"
    } else {
        _log "Test 2 Failed"
    }
}

function Invoke-Test3 {
    git commit -m "test3" --no-verify
    if ($? -eq $false) {
        _log "Test 3 Failed"
    } else {
        _log "Test 3 Succeeded"
    }
}

function Invoke-Test4 {
    Get-Content "newcreds" | Add-Content "creds"
    Remove-Item "newcreds"
    git add .
    git commit -m "Test4"
    if ($? -eq $false) {
        _log "Test 4 Succeeded"
    } else {
        _log "Test 4 Failed"
    }
}

function Invoke-Test5 {
    git commit -m "Test5" --no-verify
    if ($? -eq $false) {
        _log "Test 5 failed"
    } else {
        _log "Test 5 Succeeded"
    }
}

Set-Location "C:\tmp"
git clone $TEST_GIT_REPO
Set-Location "C:\tmp\fake_repo_TEST9"

Invoke-Test1
Invoke-Test2
Invoke-Test3
Invoke-Test4
Invoke-Test5
Set-Location "C:\"
Remove-Item -Recurse -Force "C:\tmp\fake_repo_TEST9" | Out-Null

Write-Host "___________________TESTING RESULTS___________________"
Get-Content $TEST_LOGFILE
Remove-Item $TEST_LOGFILE