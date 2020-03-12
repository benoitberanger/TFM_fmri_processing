clear
clc

main_dir = '/network/lustre/iss01/cenir/analyse/irm/users/benoit.beranger/TFM/mvpa';

load e

models = e.getModel('mvpa');

for m = 1 : numel(models)
    
    out = r_mkdir(main_dir, models(m).exam.name);
    
    % Load
    
    SPM = models(m).load;
    SPM = SPM{1}.SPM;
    
    % Simplify beta names
    beta_name = SPM.xX.name';
    beta_name = regexprep(beta_name,'(','');
    beta_name = regexprep(beta_name,')','');
    beta_name = regexprep(beta_name,'*bf1','');
    beta_name( ~cellfun(@isempty,regexp(beta_name,' constant')) ) = [];
    
    % Run numer extraction
    res_run = regexp(beta_name,'Sn(\d)','tokens');
    run_idx = zeros(size(res_run));
    for i = 1 : length(run_idx)
        run_idx(i) = str2double(res_run{i}{1}{1});
    end
    
    % Trial extraction
    res_trial = regexp(beta_name,'mvt_\wamb_(\d+)','tokens');
    trial_idx = zeros(size(res_trial));
    for i = 1 : length(trial_idx)
        if isempty(res_trial{i}), continue, end
        trial_idx(i) = str2double(res_trial{i}{1}{1});
    end
    
    % pn extraction
    res_pn = regexp(beta_name,'mvt_(\w)amb','tokens');
    pn_val = cell(size(res_pn));
    for i = 1 : length(pn_val)
        if isempty(res_pn{i}), continue, end
        pn_val{i} = res_pn{i}{1}{1};
    end
    
    in_file  = cell(size(beta_name));
    out_file = cell(size(beta_name));
    
    for beta = 1 : length(beta_name)
        
        run   =   run_idx(beta);
        trial = trial_idx(beta);
        pn    =    pn_val{beta};
        
        if trial == 0, continue, end
        
        in_file {beta} = fullfile( SPM.swd, SPM.Vbeta(beta).fname );
        out_file{beta} = fullfile( char(out), sprintf('run%.2d_trial%.2d_%s.nii',run,trial,pn) );
        
    end
    
    % Clean lists
    is_trial = trial_idx > 0;
    in_file (~is_trial) = [];
    out_file(~is_trial) = [];
    
    r_movefile(in_file, out_file, 'copyn');
    
end % models


