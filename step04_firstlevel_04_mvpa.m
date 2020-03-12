clear
clc

load e.mat

model_name = 'tapas_mvpa';


%% Prepare paths and regexp

par.display = 0;
par.run     = 1;
par.pct     = 0;
par.verbose = 2;


%% dirs & files

dirStats = e.mkdir('model',model_name);

dirFonc = e.getSerie('run_INDIVIEW_\d{2}_nm').toJob;
e.getSerie('run_INDIVIEW_01_nm').addStim('onsets','run1_mvpa.mat','INDIVIEW_1_mvpa',1)
e.getSerie('run_INDIVIEW_02_nm').addStim('onsets','run2_mvpa.mat','INDIVIEW_2_mvpa',1)
e.getSerie('run_INDIVIEW_03_nm').addStim('onsets','run3_mvpa.mat','INDIVIEW_3_mvpa',1)
e.getSerie('run_INDIVIEW_04_nm').addStim('onsets','run4_mvpa.mat','INDIVIEW_4_mvpa',1)
e.getSerie('run_INDIVIEW_05_nm').addStim('onsets','run5_mvpa.mat','INDIVIEW_5_mvpa',1)
onsetFile = e.getSerie('run_INDIVIEW_\d{2}_nm').getStim('INDIVIEW_\d_mvpa').toJob;

par.rp       = 1;
par.file_reg = '^sw.*nii';


%% Specify boxcar

par.redo    = 0;
par.sge     = 0;
par.run     = 1;
par.display = 0;
par.jobname = 'spm_glm_def';

% Boxcar + TAPAS
par.rp_regex = 'multiple_regressors.txt';
job_first_level_specify(dirFonc,dirStats,onsetFile,par);


%% Estimate

e.addModel('model',model_name,model_name);

save('e','e')

fspm = e.getModel(model_name).removeEmpty.toJob;

clear par
par.sge     = 0;
par.run     = 1;
par.redo    = 0;
par.display = 0;
job_first_level_estimate(fspm,par);
