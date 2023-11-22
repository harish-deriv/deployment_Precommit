if (!(Test-Path -Path "C:\Windows\Temp\pre-commit-data" -PathType "Container")){
    mkdir "C:\Windows\Temp\pre-commit-data" 1>$null
    Write-Host "Tmp Directory Created"
}

# Check if the git repo has commits (not empty)
$lastCommit = git log -1 2>$null

if ($lastCommit) {
    # Git repo has commits
    trufflehog git file://. --no-update --since-commit HEAD --fail > "C:\Windows\Temp\pre-commit-data\trufflehog_output_$($env:USERNAME)" 2>$null
    $trufflehog_exit_code = $LASTEXITCODE
    $trufflehog_exit_code | Out-File -FilePath "C:\Windows\Temp\pre-commit-data\trufflehog_exit_code_$($env:USERNAME)"
}
else {
    # Git repo is empty
    trufflehog filesystem . --no-update --fail > "C:\Windows\Temp\pre-commit-data\trufflehog_output_$($env:USERNAME)" 2>$null
    $trufflehog_exit_code = $LASTEXITCODE
    $trufflehog_exit_code | Out-File -FilePath "C:\Windows\Temp\pre-commit-data\trufflehog_exit_code_$($env:USERNAME)"
}

# Only display results to stdout if trufflehog found something.
if ($trufflehog_exit_code -eq 183) {
    Get-Content "C:\Windows\Temp\pre-commit-data\trufflehog_output_$($env:USERNAME)"
    Write-Host "TruffleHog found secrets. Aborting commit. use --no-verify to bypass it"
    exit $trufflehog_exit_code
}