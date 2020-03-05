clear
clc

load e.mat

model_name = 'tapas_basic';


%% Prepare paths and regexp

par.display = 0;
par.run     = 1;
par.pct     = 0;
par.verbose = 2;


%% dirs & files

dirStats = e.mkdir('model',model_name);

dirFonc = e.getSerie('run_INDIVIEW_\d{2}_nm').toJob;
e.getSerie('run_INDIVIEW_01_nm').addStim('onsets','run1_basic.mat','INDIVIEW_1_basic',1)
e.getSerie('run_INDIVIEW_02_nm').addStim('onsets','run2_basic.mat','INDIVIEW_2_basic',1)
e.getSerie('run_INDIVIEW_03_nm').addStim('onsets','run3_basic.mat','INDIVIEW_3_basic',1)
e.getSerie('run_INDIVIEW_04_nm').addStim('onsets','run4_basic.mat','INDIVIEW_4_basic',1)
e.getSerie('run_INDIVIEW_05_nm').addStim('onsets','run5_basic.mat','INDIVIEW_5_basic',1)
onsetFile = e.getSerie('run_INDIVIEW_\d{2}_nm').getStim('INDIVIEW_\d_basic').toJob;

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


%% Contrast

jitter_1        = [1 0 0 0  0 0 0 0 ];
static          = [0 1 0 0  0 0 0 0 ];
mvt_amb         = [0 0 1 0  0 0 0 0 ];
mvt_amb_angle   = [0 0 0 1  0 0 0 0 ];
mvt_noamb       = [0 0 0 0  1 0 0 0 ];
mvt_noamb_angle = [0 0 0 0  0 1 0 0 ];
jitter_2        = [0 0 0 0  0 0 1 0 ];
response        = [0 0 0 0  0 0 0 1 ];

contrast_T.values = {
    
jitter_1
static
mvt_amb
mvt_amb_angle
mvt_noamb
mvt_noamb_angle
jitter_2
response

mvt_amb         - mvt_noamb
mvt_noamb       - mvt_amb
mvt_amb_angle   - mvt_noamb_angle
mvt_noamb_angle - mvt_amb_angle

}';

contrast_T.names = {
    
'jitter_1'
'static'
'mvt_amb'
'mvt_amb_angle'
'mvt_noamb'
'mvt_noamb_angle'
'jitter_2'
'response'

'mvt_amb         - mvt_noamb'
'mvt_noamb       - mvt_amb'
'mvt_amb_angle   - mvt_noamb_angle'
'mvt_noamb_angle - mvt_amb_angle'

}';

contrast_T.types = cat(1,repmat({'T'},[1 length(contrast_T.names)]));

contrast_F.names  = {'F-all'};
contrast_F.values = {eye(8)};
contrast_F.types  = cat(1,repmat({'F'},[1 length(contrast_F.names)]));

contrast.names  = [contrast_F.names  contrast_T.names ];
contrast.values = [contrast_F.values contrast_T.values];
contrast.types  = [contrast_F.types  contrast_T.types ];


%% Contrast : write

clear par
par.sge     = 0;
par.run     = 1;
par.display = 0;

par.sessrep = 'repl';

par.delete_previous = 1;
par.report=0;
job = job_first_level_contrast(fspm,contrast,par);
