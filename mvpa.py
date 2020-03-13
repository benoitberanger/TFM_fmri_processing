#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os

import nilearn
from nilearn import plotting                        # dont know why but need to load this submodule separetly
import pandas as pd                                 # to read TSV files
import glob                                         # to fetch files using REGEX
from sklearn.svm import SVC                         # Support Vector Classifier
from nilearn.input_data import NiftiMasker          # tool to transform 4D to 2D
import numpy as np                                  # numpy for basic math operations
from sklearn.model_selection import cross_val_score, LeaveOneGroupOut

datadir = '/network/lustre/iss01/cenir/analyse/irm/users/benoit.beranger/TFM/mvpa/'
outdir  = '/network/lustre/iss01/cenir/analyse/irm/users/benoit.beranger/TFM/nilearn/'

subj = '2020_02_27_DEV_349_TFM_Pilote01/'

### Load T1 template
template = nilearn.image.load_img(os.path.join(datadir,'Template_T1_IXI555_MNI152_GS.nii'))
T1       = nilearn.image.load_img(os.path.join(datadir,subj,'wms*.nii'))

### Load subj 1 betas
subj1_path = os.path.join(datadir,subj)
mydata = nilearn.image.load_img(subj1_path + '*trial*nii')

### Get regression paramter : the angle
datlist = glob.glob(subj1_path + '*dat')
ANG   = list()
AMBIG = list()
GROUP = list()
c = 0
for file in datlist:
    c += 1
    dat = pd.read_csv(file, sep='\t', header=0)
    ok  = dat['OK']==1         # list of good trials
    dat = dat[ok]              # keep good trials
    ANG.extend(dat['ANG'])     # store parameter to classify
    AMBIG.extend(dat['AMBIG']) # store parameter to classify
    for i in range(1,len(dat)+1): GROUP.append(c)

condition = [ "pos" if val==1 else "neg" for val in AMBIG]

### Initialise the "masker" that transform 4D to 2D, ready to ingest in the SVC
# MTG_path = os.path.join(datadir,'MTG3_yeo.nii')
# OCC_path = os.path.join(datadir,'occipital_AAL.nii')
# MTG_img  = nilearn.image.load_img(MTG_path)
# OCC_img  = nilearn.image.load_img(OCC_path)
# MTG_img.set_sform( OCC_img.affine )
# mask_img = nilearn.image.math_img("np.array(a+b,dtype=bool)",a=MTG_img, b=OCC_img)
# mask_path = os.path.join(datadir,subj,'mask.nii')
mask_path = os.path.join(datadir,'mask_MTG3_OCC.nii')
mask_img  = nilearn.image.load_img(mask_path)
masker    = NiftiMasker(mask_img=mask_img, standardize=True)

### Final preparation
beta_masked = masker.fit_transform(mydata)

### SVC
svc_linear = SVC(kernel='linear')
svc_linear.fit(beta_masked, AMBIG)
prediction = svc_linear.predict(beta_masked)

### Unmasking & visualization
coef_img  = masker.inverse_transform(svc_linear.coef_)
threshold = 1e-3
plotting.plot_stat_map(coef_img, bg_img=T1, threshold=threshold, display_mode='z')
# Orth view
view      = plotting.view_img(coef_img,bg_img=T1, threshold=threshold )
view.open_in_browser()
# Surf view
view      = plotting.view_img_on_surf(coef_img, threshold=threshold )
view.open_in_browser()

### Cross validation
svc_crossval = SVC(kernel='linear')
cv           = LeaveOneGroupOut()
cv_scores    = cross_val_score(svc_crossval, beta_masked, AMBIG, cv=cv, groups=GROUP, n_jobs=-1, verbose=10)
print(cv_scores)
classification_accuracy = np.mean(cv_scores)
print(classification_accuracy)
