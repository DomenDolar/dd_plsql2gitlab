# dd_plsql2gitlab

Package is prepared to transfer PACAKAGE CODE to the GITLAB with PL/SQL. You can change code and push any code to the GITLAB using pure PL/SQL.

Description of function sendPackage2Git(
     p_project => :p_project,                - the name of the PACKAGE object in database
     p_owner => :p_owner,                    - owner or. schema where PECKAGE is
     p_authormail => :p_authormail,          - your email addres that is pushed to GITLAB
     p_author => :p_author,                  - your namr that is pushed to GITLAB
     p_commitmessage => :p_commitmessage,    - commit message for GITLAB
     p_gittoken_coded => :p_gittoken_coded   - token from GITLAB. The token is coded with function codeGitToken. You get token on GITLAB -> Settings -> Access Tokens -> Personal Access Tokens = check API and create token.
     );
     
 You can set URL, PATH in variables in package.    
     

 The function returs response from GITLAB repository. 



