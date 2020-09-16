create or replace package dd_plsql2gitlab is

  /*
  // +----------------------------------------------------------------------+
  // | dd_plsql2gitlab - PLSQL to GITLAB procedure                          |
  // +----------------------------------------------------------------------+
  // | Copyright (C) 2020       http://rasd.sourceforge.net                 |
  // +----------------------------------------------------------------------+
  // | This program is free software; you can redistribute it and/or modify |
  // | it under the terms of the GNU General Public License as published by |
  // | the Free Software Foundation; either version 2 of the License, or    |
  // | (at your option) any later version.                                  |
  // |                                                                      |
  // | This program is distributed in the hope that it will be useful       |
  // | but WITHOUT ANY WARRANTY; without even the implied warranty of       |
  // | MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the         |
  // | GNU General Public License for more details.                         |
  // +----------------------------------------------------------------------+
  // | Author: Domen Dolar       <domendolar@users.sourceforge.net>         |
  // |Created : 16.9.2020 10:13:45                                          |
  // |Purpose : Sending PL/SQL packages from database to GitLab             |
  // +----------------------------------------------------------------------+
  */

function codeGitToken(p_code varchar2) return varchar2;
  
function sendPackage2Git(
  p_project varchar2,
  p_owner varchar2,
  p_authormail varchar2,
  p_author varchar2,
  p_commitMessage varchar2,
  p_gittoken_coded varchar2
  ) return varchar2;  
  
    
/*
Sample:

:v_put2git := zpizlib.dd_plsql2gitlab.sendPackage2Git(
  'PACKAGE', -- package in DB
  'USER',   -- schema where package is
  'my@mail', -- your mail in git
  'd D',      -- your name in git 
  'commit message ,...', --commit message
  'token generated on gitlab' -- token generated in git GITLAB -> Settings -> Access Tokens -> Personal Access Tokens = check API and create token. Then code this token with function codeGitToken.
  );
*/

end dd_plsql2gitlab;
/
create or replace package body rasddev.dd_plsql2gitlab is

  -- git settings
  p_gitlab_url varchar2(100) := 'http://gitlab.com';  -- http://gitlab.com
  p_gitlab_api varchar2(10)  := '/api/v4'; -- version of your gitlab api
  -- git custom location settings
  p_path  varchar2(100) := 'src/main/';
  p_extension varchar2(100) := '.sql';
  
  procedure dbms_output_put_line(p_text varchar2) is
  begin
    
 -- dbms_output_put_line(p_text);
    null;
  end;
  
  

    function to_base64(t in varchar2) return varchar2 is
     begin
       return utl_raw.cast_to_varchar2(utl_encode.base64_encode(utl_raw.cast_to_raw(t)));
     end to_base64;
  
    function from_base64(t in varchar2) return varchar2 is
     begin
       return utl_raw.cast_to_varchar2(utl_encode.base64_decode(utl_raw.cast_to_raw    (t)));
     end from_base64; 

  function codeGitToken(p_code varchar2) return varchar2 is  
  begin
     return to_base64(p_code);    
  end;

  function deCodeGitToken(p_code varchar2) return varchar2 is  
  begin
     return from_base64(p_code);    
  end;
     
   function escapeJson(p_content clob) return clob is
       v_return clob := p_content;
     begin 
         v_return := replace(v_return,'\','\\');      --Backslash is replaced with \\
         v_return := replace(v_return,'"','\"');      --Double quote is replaced with \"
         v_return := replace(v_return,chr(10),'\n');  --Newline is replaced with \n
         v_return := replace(v_return,chr(13),'\r');  --Carriage return is replaced with \r
         v_return := replace(v_return,chr(9),'\t');   --Tab is replaced with \t            
       return v_return;

     end;
     
    function preparePackageContent(p_owner varchar2, p_name varchar2) return clob is
        v_return clob;
      begin

v_return := 'create or replace ';       
      for r in (select text from all_source s
where s.name = p_name
and s.owner = p_owner
and s.type = 'PACKAGE'
order by type, line) loop     
           v_return := v_return || r.text;

        end loop;
      
           v_return := v_return || '/
create or replace ';        
      
      for r in (select text from all_source s
where s.name = p_name
and s.owner = p_owner
and s.type = 'PACKAGE BODY'
order by type, line) loop     
           v_return := v_return || r.text;

        end loop;
      
           v_return := v_return || '/
';      

if length(v_return) < 100 then 
  return null;
else  
  return v_return;
end if;  
      end;
     
     
    function readGIT( purl varchar2, pmethod varchar2, pgittoken varchar2) return clob is
  l_http_req UTL_HTTP.REQ;
  l_http_resp UTL_HTTP.RESP;      
  l_resp_lob clob;
  l_vc_html VARCHAR2(32767);  
    begin
   l_http_req := UTL_HTTP.BEGIN_REQUEST(purl,pmethod);

  dbms_output_put_line('Request URL: '||l_http_req.url);
  dbms_output_put_line('Request Method: '||l_http_req.method);
  dbms_output_put_line('Request Version: '||l_http_req.http_version);   
   UTL_HTTP.SET_HEADER(l_http_req, 'Header #1', 'Chrome V.52.X');
   UTL_HTTP.SET_HEADER(l_http_req, 'Authorization', 'Bearer '||deCodeGitToken(pgittoken) );
  -- UTL_HTTP.SET_HEADER(l_http_req, 'Authorization', 'Basic '||to_base64('your usernama:password') );
  
  l_http_resp := UTL_HTTP.GET_RESPONSE(l_http_req);

  dbms_output_put_line('Response Status Code: '||l_http_resp.status_code);
  dbms_output_put_line('Response Reason: '||l_http_resp.reason_phrase);
  dbms_output_put_line('Response Version: '||l_http_resp.http_version);
--  dbms_output_put_line('---Header Count Starts---');
--  FOR loop_hc IN 1..UTL_HTTP.GET_HEADER_COUNT(l_http_resp)
--  LOOP
--    UTL_HTTP.GET_HEADER(l_http_resp, loop_hc, l_vc_header_name, l_vc_header_value);
--    dbms_output_put_line(l_vc_header_name || ': ' || l_vc_header_value);
--  END LOOP loop_hc;
--  dbms_output_put_line('---Header Count Ends---');
  begin
  LOOP
    UTL_HTTP.read_text(l_http_resp, l_vc_html);
    l_resp_lob := l_resp_lob || l_vc_html;
   -- dbms_output_put_line(l_vc_html);
  END LOOP;
  UTL_HTTP.END_RESPONSE(l_http_resp);
  exception WHEN UTL_HTTP.END_OF_BODY THEN
  UTL_HTTP.END_RESPONSE(l_http_resp);   
  end;      
  dbms_output_put_line('Response length: '||length(l_resp_lob));
    
  return l_resp_lob;
  exception when others then
  UTL_HTTP.END_RESPONSE(l_http_resp);  
  raise;    
    end;      





  function write2GIT( purl varchar2, pfolder varchar2, pfile varchar2 ,  pmethod varchar2, pcontent clob, pauthormail varchar2, pauthor varchar2, pcommit varchar2 ,pgittoken varchar2) return clob is
  l_http_req UTL_HTTP.REQ;
  l_http_resp UTL_HTTP.RESP;      
  l_resp_lob clob;
  l_vc_html VARCHAR2(32767);  
  v_content clob;
    
    begin
   l_http_req := UTL_HTTP.BEGIN_REQUEST(purl||replace(pfolder,'/','%2F')||pfile,pmethod);
  v_content := pcontent;

  v_content := '{"branch": "master", "author_email": "'||pauthormail||'", "author_name": "'||pauthor||'", "content": "'||escapeJson(v_content)||'", "commit_message": "From rasd.dd_plsql2gitlab: '||escapeJson(pcommit)||'"}';

  dbms_output_put_line('Request URL: '||l_http_req.url);
  dbms_output_put_line('Request Method: '||l_http_req.method);
  dbms_output_put_line('Request Version: '||l_http_req.http_version);   
  dbms_output_put_line('Request Data length: '||length(v_content));   
   UTL_HTTP.SET_HEADER(l_http_req, 'Header #1', 'Chrome V.52.X');
   UTL_HTTP.SET_HEADER(l_http_req, 'Authorization', 'Bearer '||deCodeGitToken(pgittoken) );
   UTL_HTTP.SET_HEADER(l_http_req, 'Content-Type', 'application/json');
   UTL_HTTP.SET_HEADER(l_http_req, 'Content-Length', length(v_content));
 
   while length(v_content) > 1000 loop
      utl_http.write_text(l_http_req , substr(v_content,1, 1000 )); 
      v_content := substr(v_content, 1001);    
   end loop;
   utl_http.write_text(l_http_req , v_content );

  l_http_resp := UTL_HTTP.GET_RESPONSE(l_http_req);

  dbms_output_put_line('Response Status Code: '||l_http_resp.status_code);
  dbms_output_put_line('Response Reason: '||l_http_resp.reason_phrase);
  dbms_output_put_line('Response Version: '||l_http_resp.http_version);
  begin
  LOOP
    UTL_HTTP.read_text(l_http_resp, l_vc_html);
    l_resp_lob := l_resp_lob || l_vc_html;
  END LOOP;
  UTL_HTTP.END_RESPONSE(l_http_resp);
  exception WHEN UTL_HTTP.END_OF_BODY THEN
  UTL_HTTP.END_RESPONSE(l_http_resp);   
  end;      
  dbms_output_put_line('Response length: '||length(l_resp_lob));
    
  return l_resp_lob;
  exception when others then
  UTL_HTTP.END_RESPONSE(l_http_resp);  
  raise;  
    end;
       
 
function sendPackage2Git(
  p_project varchar2,
  p_owner varchar2,
  p_authormail varchar2,
  p_author varchar2,
  p_commitMessage varchar2,
  p_gittoken_coded varchar2
  ) return varchar2 is
  v_GITProject varchar2(100); 
  v_GITid number;
  v_GITFileName varchar2(100);
  v_GITFIlePath varchar2(100);
  v_resp_lob clob;
  v_content clob;
begin
 
  dbms_output_put_line('---1. We read all projects from SDM---');

  
  v_resp_lob := readGIT(p_gitlab_url||p_gitlab_api||'/projects/', 'GET' , p_gittoken_coded  );

  dbms_output_put_line('---2. We check if project already exists---'); 
declare
begin
select name, id into v_GITProject, v_GITid
from json_table(v_resp_lob,'$[*]'
             COLUMNS(
              id number PATH '$.id',             
              name varchar2(100) PATH '$.name',
              description varchar2(100) PATH '$.description'
             )) jt
where name = p_project;             
exception when others then
  null;  
end;  


if v_GITid is null then
  -- project does not exists
  dbms_output_put_line('---3.2 Project does not exists---'); 
  dbms_output_put_line('Createing project...'); 
  v_resp_lob := readGIT(p_gitlab_url||p_gitlab_api||'/projects?name='||p_project, 'POST' , p_gittoken_coded  );
  
select name, id into v_GITProject, v_GITid
from  json_table(v_resp_lob,'$[*]'
             COLUMNS(
              id varchar2(100) PATH '$.id',
              name varchar2(100) PATH '$.name'
             )) jt ;
               
  dbms_output_put_line('Project created: ID:'||v_GITid||' NAME:'||v_GITProject||''); 
  
else
  -- project exists
  dbms_output_put_line('---3.2 Project exists ID:'||v_GITid||' NAME:'||v_GITProject||'---'); 
  
end if;


  v_content := preparePackageContent(p_owner , p_project );

if v_GITid is not null and v_content is not null then
  
  dbms_output_put_line('---4. We read files in project---'); 

  v_resp_lob := readGIT(p_gitlab_url||p_gitlab_api||'/projects/'||v_GITid||'/repository/tree/?ref=master&recursive=true', 'GET' , p_gittoken_coded  );


  dbms_output_put_line('---5. Filter files---'); 
 
declare
begin
select name, path into v_GITFileName, v_GITFIlePath
from json_table(v_resp_lob,'$[*]'
             COLUMNS(
              name varchar2(100) PATH '$.name',
              path varchar2(100) PATH '$.path'
             )) jt
where name = p_project||p_extension;             

  dbms_output_put_line('---6.1 Update existing file---'); 
v_resp_lob := write2GIT( p_gitlab_url||p_gitlab_api||'/projects/'||v_GITid||'/repository/files/' , p_path, p_project||p_extension ,  'PUT',
                        v_content, p_authormail , p_author , p_commitMessage ,p_gittoken_coded);
  dbms_output_put_line('Response file update:'||v_resp_lob); 

exception when no_data_found  then
  dbms_output_put_line('---6.2 Create new file---'); 
 v_resp_lob := write2GIT( p_gitlab_url||p_gitlab_api||'/projects/'||v_GITid||'/repository/files/' , p_path, p_project||p_extension ,  'POST',
                        v_content, p_authormail , p_author , p_commitMessage ,p_gittoken_coded);
  dbms_output_put_line('Response file update:'||v_resp_lob); 
 
end; 

   return substr(v_resp_lob,1,32000);
   
  
end if; --v_GITid is not null
  
return substr(v_resp_lob,1,32000);

end;



end dd_plsql2gitlab;
/