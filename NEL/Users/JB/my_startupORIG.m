function my_startup
% MY_STARTUP personlized startup file for nel users

% MH 12/14/01

global MH_root_dir

MH_root_dir = [fileparts(which('my_startup')) filesep];

addpath([MH_root_dir  'Templates']);

MH_Templates = struct(...
   'T2',                  'T2_template', ...
   'T1',                  'T1_template', ...
   'TB',                  'TB_template', ...
   'FN',                  'FN_template', ...
   'SP',                  'SP_template', ...
   'T05',                 'T05_template', ...
   'B2',                  'B2_template', ...
   'B1',                  'B1_template', ...
   'BD',                  'BD_template', ...
   'FW',                  'FW_template', ...
   'FWC',                 'FWCEFS_template', ...
   'TX',                  'TX_template' ...
   );

register_user_templates(MH_Templates);
