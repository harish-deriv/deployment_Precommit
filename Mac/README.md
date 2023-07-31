### Mac Deployment
1. User need to have administrator privilege
    - `Kandji` bug, if the Macbook `Kandji` agent is installed as `standard user` there is a high chance the elevating user to `administrator` privilege would not work. (Require reformatting)  
    - `SAP Profile` App is used to determine the user privilege
2. Install Brew - Done (Use script provided by `Kandji` - [Link](https://support.kandji.io/support/solutions/articles/72000560518-deploying-homebrew-as-a-custom-script))
3. Install Git - Done
4. Install Trufflehog - Done 
5. Configure Pre-Commit for normal users - Done
5. Configure Pre-Commit for root user - Pending
6. Testing Pre-Commit - Pending

--- 
### Kandji
1. Testing Blue Print: Standard: Testing Pre-Commit Deployment
2. Custom Deployment Script: Pre-Commit Deployment 
3. SAP Profile - Admin: Toggle this for sudo access 
4. SAP Profile - Standard User: Disable this for sudo access