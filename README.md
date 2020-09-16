# dd_plsql2gitlab

Package is prepared to transfer PACKAGE CODE to the GITLAB with PL/SQL. You can change code and push any code to the GITLAB using pure PL/SQL.</br></br>

Description of function sendPackage2Git(</br>
     p_project => :p_project,                - the name of the PACKAGE object in database</br>
     p_owner => :p_owner,                    - owner or. schema where PECKAGE is</br>
     p_authormail => :p_authormail,          - your email addres that is pushed to GITLAB</br>
     p_author => :p_author,                  - your namr that is pushed to GITLAB</br>
     p_commitmessage => :p_commitmessage,    - commit message for GITLAB</br>
     p_gittoken_coded => :p_gittoken_coded   - token from GITLAB. The token is coded with function codeGitToken. You get token on GITLAB -> Settings -> Access Tokens -> Personal Access Tokens = check API and create token.</br>
     );</br>
</br>
 The code of PACKAGE is pushed to src/main/ with sufix .sql.  You can set URL, PATH in variables in package in public variables. </br>  
 </br>
   -- git settings</br>
  p_gitlab_url varchar2(100) := 'http://gitlab.com'; </br>
  p_gitlab_api varchar2(10) := '/api/v4'; -- version of your gitlab api</br>
  -- git custom location settings</br>
  p_path      varchar2(100) := 'src/main/';</br>
  p_extension varchar2(100) := '.sql';</br>
     
</br>
 The function returns response from GITLAB repository. </br>



