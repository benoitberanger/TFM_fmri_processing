clear
clc

load e

subj_path = e.getPath;
onsets_path = fullfile(subj_path,'onsets');

onsets_datfile = gfile(onsets_path,'_indiview_run\d.dat$');

names = {'jitter_1', 'static', 'mvt_amb', 'mvt_noamp', 'jitter_2', 'response'};
jitter_1 = 1;
static   = 2;
mvt_amb  = 3;
mvt_noamb= 4;
jitter_2 = 5;
response = 6;

for iSubj = 1 : length(onsets_datfile)
    
    for iRun = 1 : size(onsets_datfile{iSubj},1)
        
        dat = importfile_dat_INDIVIEW( deblank(onsets_datfile{iSubj}(iRun,:)) );
        
        if any(dat.OK==0)
            dat = dat(dat.OK==1,:); % reject bad trials
        end
        
        [ onsets , durations ] = deal( cell(size(names)) );
        
        pmod = struct;
        
        for evt = 1 : size(dat,1)
            
            % onsets ------------------------------------------------------
            
            onsets{jitter_1}(end+1) = dat.MRI_T(evt);
            onsets{static  }(end+1) = dat.MRI_T(evt) + dat.INIT_PAUSE(evt);
            if     dat.AMBIG(evt)==1
                onsets{mvt_amb  }(end+1) = dat.MRI_T(evt) + dat.INIT_PAUSE(evt) + 0.5;
            elseif dat.AMBIG(evt)==0
                onsets{mvt_noamb}(end+1) = dat.MRI_T(evt) + dat.INIT_PAUSE(evt) + 0.5;
            else
                error('amb ?')
            end
            onsets{jitter_2}(end+1) = dat.MRI_T(evt) + dat.INIT_PAUSE(evt) + 0.5 + 1.0;
            onsets{response}(end+1) = dat.MRI_T(evt) + dat.INIT_PAUSE(evt) + 0.5 + 1.0 + dat.FINAL_PAUSE(evt);
            
            
            % durations ---------------------------------------------------
            durations{jitter_1}(end+1) = dat.INIT_PAUSE(evt);
            durations{static  }(end+1) = 0.5;
            if     dat.AMBIG(evt)==1
                durations{mvt_amb  }(end+1) = 1.0;
            elseif dat.AMBIG(evt)==0
                durations{mvt_noamb}(end+1) = 1.0;
            else
                error('amb ?')
            end
            durations{jitter_2}(end+1) = dat.FINAL_PAUSE(evt);
            durations{response}(end+1) = dat.RT(evt);
            
            
            % pmod --------------------------------------------------------
            
            flag_AMBIG   = logical( dat.AMBIG==1 );
            flag_NOAMBIG = logical( dat.AMBIG==0 );
            
            pmod(mvt_amb  ).name {1}  = 'angle';
            pmod(mvt_amb  ).param{1}  = dat.ANG(flag_AMBIG);
            pmod(mvt_amb  ).poly {1}  = 1;
            
            pmod(mvt_noamb).name {1}  = 'angle';
            pmod(mvt_noamb).param{1}  = dat.ANG(flag_NOAMBIG);
            pmod(mvt_noamb).poly {1}  = 1;
            
        end
        
        [pathstr, name, ext] = fileparts(   deblank(onsets_datfile{iSubj}(iRun,:)) );
        save( fullfile(pathstr,[name '_basic']) , 'names', 'onsets', 'durations', 'pmod' )
        
        % plotSPMnod(names,onsets,durations);
        
    end % iRun
    
end % iSubj
