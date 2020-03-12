clear
clc

load e.mat

%%

dirFunc     = e.getSerie('run_.*_nm$').toJob
dirNoiseROI = e.getSerie('anat_T1').toJob(0)


%%

par.file_reg = '^f.*nii'; % to fetch volume info (nrVolumes, nrSlices, TR, ...)
par.noiseROI_files_regex  = '^wutrf.*nii';  % usually use normalied files, NOT the smoothed data
par.noiseROI_mask_regex   = '^rwp[23].*nii'; % 2 = WM, 3 = CSF
par.noiseROI_thresholds   = [0.95 0.90];     % keep voxels with tissu probabilty >= 95%
par.noiseROI_n_voxel_crop = [2 1];           % crop n voxels in each direction, to avoid partial volume
par.noiseROI_n_components = 10;              % keep n PCA componenets

par.rp_threshold = 1.0;

par.run           = 1;
par.display       = 0;
par.print_figures = 0;

par.redo      = 0;
par.usePhysio = 0;
par.noiseROI  = 1;

par.print_figures = 0;
par.pct = 0;

par

job_physio_tapas( dirFunc, [], dirNoiseROI, par);
