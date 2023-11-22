# Pre-Commit Scripts for Windows Laptops

## Files
- `pre-commit`: A shell script needed to invoke ps1 scripts in windows. You need to provide appropriate path to the `pre-commit.ps1` in this script. 
- `pre-commit.ps1`: This script contains the main code for invoking trufflehog in each commit.
- `testing_script.ps1`: This script is to use for testing the pre-commit setup. Use the following command in any shell i.e Git Bash, Cmd, Powershell, etc. 
```
powershell.exe -command "(Invoke-WebRequest -Uri https://raw.githubusercontent.com/security-deriv/deployment_Precommit/main/Windows/testing_script.ps1).Content | powershell.exe -ExecutionPolicy RemoteSigned"
``` 