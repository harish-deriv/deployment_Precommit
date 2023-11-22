$TMP_DIR = "C:\Windows\Temp\pre-commit-data"

if (!(Test-Path -Path "$TMP_DIR" -PathType "Container")){
    mkdir "$TMP_DIR" 1>$null
    Write-Host "Tmp Directory Created"
}

# Check if the git repo has commits (not empty)
$lastCommit = git log -1 2>$null

if ($lastCommit) {
    # Git repo has commits
    trufflehog git file://. --no-update --since-commit HEAD --fail > "$TMP_DIR\trufflehog_output_$($env:USERNAME)" 2>$null
    $trufflehog_exit_code = $LASTEXITCODE
    $trufflehog_exit_code | Out-File -FilePath "$TMP_DIR\trufflehog_exit_code_$($env:USERNAME)"
}
else {
    # Git repo is empty
    trufflehog filesystem . --no-update --fail > "$TMP_DIR\trufflehog_output_$($env:USERNAME)" 2>$null
    $trufflehog_exit_code = $LASTEXITCODE
    $trufflehog_exit_code | Out-File -FilePath "$TMP_DIR\trufflehog_exit_code_$($env:USERNAME)"
}

# Only display results to stdout if trufflehog found something.
if ($trufflehog_exit_code -eq 183) {
    Get-Content "$TMP_DIR\trufflehog_output_$($env:USERNAME)"
    Write-Host "TruffleHog found secrets. Aborting commit. use --no-verify to bypass it"
    exit $trufflehog_exit_code
}