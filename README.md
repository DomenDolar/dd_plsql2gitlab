# dd_plsql2gitlab


:v_put2git := zpizlib.dd_plsql2gitlab.sendPackage2Git(
  'PACKAGE', -- package in DB
  'USER',   -- schema where package is
  'my@mail', -- your mail in git
  'd D',      -- your name in git 
  'commit message ,...', --commit message
  'token generated on gitlab' -- token generated in git GITLAB -> Settings -> Access Tokens -> Personal Access Tokens = check API and create token. Then code this token with function codeGitToken.
  )



