clear
clc

%% Prepare paths and regexp

maindir = '/network/lustre/iss01/cenir/analyse/irm/users/benoit.beranger/TFM';

par.redo= 0;
par.run = 1;
par.pct = 0;
par.sge = 0;
par.mem = '8G';


%% Get files paths

e = exam(maindir,'nifti','TFM');

% T1
e.addSerie('3DT1_0_8iso_p2$','anat_T1' ,1)
e.getSerie('anat').addVolume('^s.*nii','s',1)

e.addSerie('fMRI_INDIVIEW_run01$'         , 'run_INDIVIEW_01_nm', 1)
e.addSerie('fMRI_INDIVIEW_run01_refBLIP$' , 'run_INDIVIEW_01_bp', 1)
e.addSerie('fMRI_INDIVIEW_run02$'         , 'run_INDIVIEW_02_nm', 1)
e.addSerie('fMRI_INDIVIEW_run02_refBLIP$' , 'run_INDIVIEW_02_bp', 1)
e.addSerie('fMRI_INDIVIEW_run03$'         , 'run_INDIVIEW_03_nm', 1)
e.addSerie('fMRI_INDIVIEW_run03_refBLIP$' , 'run_INDIVIEW_03_bp', 1)
e.addSerie('fMRI_INDIVIEW_run04$'         , 'run_INDIVIEW_04_nm', 1)
e.addSerie('fMRI_INDIVIEW_run04_refBLIP$' , 'run_INDIVIEW_04_bp', 1)
e.addSerie('fMRI_INDIVIEW_run05$'         , 'run_INDIVIEW_05_nm', 1)
e.addSerie('fMRI_INDIVIEW_run05_refBLIP$' , 'run_INDIVIEW_05_bp', 1)

e.addSerie('fMRI_LOCA$'         , 'run_LOCA_nm', 1)
e.addSerie('fMRI_LOCA_refBLIP$' , 'run_LOCA_bp', 1)

e.getSerie('run').addVolume('^f.*nii','f',1)
e.getSerie().addJson('^dic','j')

e.reorderSeries('name'); % mostly useful for topup, that requires pairs of (AP,PA)/(PA,AP) scans

% e.explore


%% Unzip if necessary

e.unzipVolume(par);


%% Segment anat with cat12

par.subfolder = 0;         % 0 means "do not write in subfolder"
par.biasstr   = 0.5;
par.accstr    = 0.5;
%par.GM        = [1 0 1 0]; %                          (wp1*)     /                        (mwp1*)     /              (p1*)     /                            (rp1*)
par.WM        = [1 0 1 0]; %                          (wp2*)     /                        (mwp2*)     /              (p2*)     /                            (rp2*)
par.CSF       = [1 0 1 0]; %                          (wp3*)     /                        (mwp3*)     /              (p3*)     /                            (rp3*)
par.TPMC      = [1 0 1 0]; %                          (wp[456]*) /                        (mwp[456]*) /              (p[456]*) /                            (rp[456]*)
par.label     = [1 0 0] ;  % native (p0*)  / normalize (wp0*)  / dartel (rp0*)       This will create a label map : p0 = (1 x p1) + (3 x p2) + (1 x p3)
par.bias      = [1 1 0] ;  % native (ms*)  / normalize (wms*)  / dartel (rms*)       This will save the bias field corrected  + SANLM (global) T1
par.las       = [0 0 0] ;  % native (mis*) / normalize (wmis*) / dartel (rmis*)      This will save the bias field corrected  + SANLM (local) T1
par.warp      = [1 1];     % Warp fields  : native->template (y_*) / native<-template (iy_*)
par.doSurface = 0;
par.doROI     = 0;         % Will compute the volume in each atlas region
par.jacobian  = 0;         % Write jacobian determinant in normalize space

anat = e.gser('anat_T1').gvol('^s');

par.workflow_qsub = 0;
job_do_segmentCAT12(anat,par);
par.workflow_qsub = 1;


%% Preprocess fMRI runs

%realign and reslice
par.type = 'estimate_and_reslice';
ffunc_nm = e.getSerie('run_.*_nm').getVolume('^f');
j_realign_reslice_nm = job_realign(ffunc_nm,par);

%realign and reslice opposite phase
par.type = 'estimate_and_reslice';
ffunc_bp = e.getSerie('run_.*_bp').getVolume('^f');
j_realign_reslice_op = job_realign(ffunc_bp,par);

%topup and unwarp
ffunc_all = e.getSerie('run').getVolume('^rf');
do_topup_unwarp_4D(ffunc_all,par);

%coregister mean fonc on brain_anat
fanat = e.getSerie('anat_T1').getVolume('^p0');
fmean = e.getSerie('run_.*_nm').getVolume('^utmeanf'); fmean = fmean(:,1); % use the mean of the run1 to estimate the coreg
fo    = e.getSerie('run_.*_nm').getVolume('^utrf');
par.type = 'estimate';
j_coregister=job_coregister(fmean,fanat,fo,par);

%apply normalize
par.vox      = [2 2 2];
fin = fo.removeEmpty + fmean.removeEmpty;
tmp_exam = [fin.exam];
fy = tmp_exam.getSerie('anat_T1').getVolume('^y');
j_apply_normalize=job_apply_normalize(fy,fin,par);

%smooth the data
ffonc = e.getSerie('run_.*_nm').getVolume('wutrf').removeEmpty;
par.smooth = [4 4 4];
j_smooth=job_smooth(ffonc,par);

% coregister WM & CSF on functionnal (using the warped mean)
if isfield(par,'prefix'), par = rmfield(par,'prefix'); end
ref = e.getSerie('run_.*_nm');
ref = ref(:,1).getVolume('^wutmeanf'); % first acquired run (time)
src = e.getSerie('anat_T1').getVolume('^wp2');
oth = e.getSerie('anat_T1').getVolume('^wp3');
par.type = 'estimate_and_write';
par.jobname  = 'spm_coreg_WM_CSF';
job_coregister(src,ref,oth,par);

save('e','e')

