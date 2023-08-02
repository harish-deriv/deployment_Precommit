## Pre-Commit Deployment

### Documentations
1. [Pre-commit & Pre-push installation](https://docs.google.com/document/d/1zqfZc-iyjnsIKHWbHv3mP5-RRH5zEhY5I0iWbdDGyVg/edit#heading=h.ufhpzm1dxy82)
2. [Pre-commit Deployment tracker](https://docs.google.com/spreadsheets/d/1BwA6rKtyj8861UMmSTwtN8iQtSq_36g__PP8gwFkFJY/edit#gid=0)
3. [Pre-commit Dev Form](https://docs.google.com/spreadsheets/d/1RR57JI4GMPoQ3uIw2CCDWsR6P2Mrl15J1R-H1oAjQ4E/edit#gid=0)

### Scripts
1. [Trufflehog Installation](https://gist.githubusercontent.com/harish-deriv/849f0075982b35668b0be4aa30a008fe/raw/c06cde4f5d02e120f62c82670ca5f1fbc4312dcd/install_secretscanner.sh)
2. [Trufflehog Installation - Github Gist](https://gist.github.com/harish-deriv/849f0075982b35668b0be4aa30a008fe#file-install_secretscanner-sh)
3. [Pre-commit hook](https://gist.github.com/harish-deriv/134064f95a2b2313a8991bc8d9f9560c)
4. [Deployment Script](https://gist.github.com/harish-deriv/86e81c0910f85b041430554d4a9de687)

### QA Box Inventory List
1. [Inventory List](https://github.com/regentmarkets/chef-qa-provisioning/blob/master/inventory.txt)

### Deployment Plan
#### Overview
1. Linux deployment - Jumpcloud
2. MacOS deployment - Kandji
3. Main slack channel - #temp_precommit_hooks_plan
4. Create Slack channel for respective team `temp_precommit_deployment_{TEAM_NAME}` in order to communicate with the team
5. A python server would be set up to receive deployment status through the deployment script
    - Fail condition:
        - Once deployed, there will be a pre-commit test run on `https://github.com/harish-deriv/fake_repo_TEST9"` that has secret in it 
        - If no secret is detect, send a post request to the python server. 
        - **Note:** Due to the default users (i.e. root and deriv) false positive would occur
6. The deployment would need to be modified depending on the dev's environment
7. Set up a AWS Instance for the python server
    - Used to receive logs from deployment script 


#### Configurations
1. The precommit bash script would be hosted on a public repository.
2. The main precommit file would execute the bash script through `curl` and piped the output to `/bin/bash`.
3. Reasons:
    - This would make maintaining the pre-commit much easier as future update can simply be performed update the repository.  

### QA Environment Deployment Plan
1. Dev's are developing and pushing code through QA Box instead of local machine 
2. Add pre-commit configuration to QA Box `chef` code  

---
### Edge Cases
1. If there are secrets in a brand new git repository (Does not have any commits before), trufflehog would not pick up the secrets.
    - One workaround would be to run `git log` on the repo if there is no commit it would return `exit code` of `128` instead of `0`
    - If it a new repo use `trufflehog filesystem .` instead of `trufflehog git file://.`    
    - This logic can be added to the pre-commit file 