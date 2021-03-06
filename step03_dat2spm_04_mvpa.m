clear
clc

load e

subj_path = e.getPath;
onsets_path = fullfile(subj_path,'onsets');

onsets_datfile = gfile(onsets_path,'_indiview_run\d.dat$');

ntrials = 80;
name_other = {'jitter_1', 'static', 'jitter_2', 'response'};

n_names = ntrials + length(name_other);

jitter_1 = ntrials+1;
static   = ntrials+2;
jitter_2 = ntrials+3;
response = ntrials+4;

for iSubj = 1 : length(onsets_datfile)
    
    for iRun = 1 : size(onsets_datfile{iSubj},1)
        counter = 0;

        dat = importfile_dat_INDIVIEW( deblank(onsets_datfile{iSubj}(iRun,:)) );
        
        if any(dat.OK==0)
            dat = dat(dat.OK==1,:); % reject bad trials
        end
        
        [ names, onsets , durations ] = deal( cell(n_names,1) );
        
        pmod = struct;
        
        for evt = 1 : size(dat,1)
            
            % onsets ------------------------------------------------------
            
            onsets{jitter_1}(end+1) = dat.MRI_T(evt);
            onsets{static  }(end+1) = dat.MRI_T(evt) + dat.INIT_PAUSE(evt);
            if     dat.AMBIG(evt)==1
                counter = counter + 1;
                names {counter} = sprintf('mvt_pamb_%.2d',counter);
                onsets{counter}(end+1) = dat.MRI_T(evt) + dat.INIT_PAUSE(evt) + 0.5;
            elseif dat.AMBIG(evt)==0
                counter = counter + 1;
                names {counter} = sprintf('mvt_namb_%.2d',counter);
                onsets{counter}(end+1) = dat.MRI_T(evt) + dat.INIT_PAUSE(evt) + 0.5;
            else
                error('amb ?')
            end
            onsets{jitter_2}(end+1) = dat.MRI_T(evt) + dat.INIT_PAUSE(evt) + 0.5 + 1.0;
            onsets{response}(end+1) = dat.MRI_T(evt) + dat.INIT_PAUSE(evt) + 0.5 + 1.0 + dat.FINAL_PAUSE(evt);
            
            
            % durations ---------------------------------------------------
            durations{jitter_1}(end+1) = dat.INIT_PAUSE(evt);
            durations{static  }(end+1) = 0.5;
            if     dat.AMBIG(evt)==1
                durations{counter}(end+1) = 1.0;
            elseif dat.AMBIG(evt)==0
                durations{counter}(end+1) = 1.0;
            else
                error('amb ?')
            end
            durations{jitter_2}(end+1) = dat.FINAL_PAUSE(evt);
            durations{response}(end+1) = dat.RT(evt);
            
            
            %             % pmod --------------------------------------------------------
            %
            %             flag_AMBIG   = logical( dat.AMBIG==1 );
            %             flag_NOAMBIG = logical( dat.AMBIG==0 );
            %
            %             pmod(mvt_amb  ).name {1}  = 'cos';
            %             pmod(mvt_amb  ).param{1}  = cos( dat.ANG(flag_AMBIG)*pi/180 );
            %             pmod(mvt_amb  ).poly {1}  = 1;
            %             pmod(mvt_amb  ).name {2}  = 'sin';
            %             pmod(mvt_amb  ).param{2}  = sin( dat.ANG(flag_AMBIG)*pi/180 );
            %             pmod(mvt_amb  ).poly {2}  = 1;
            %             pmod(mvt_amb  ).name {3}  = 'ambig';
            %             pmod(mvt_amb  ).param{3}  = dat.diff_ang(flag_AMBIG);
            %             pmod(mvt_amb  ).poly {3}  = 1;
            %
            %             pmod(mvt_noamb).name {1}  = 'cos';
            %             pmod(mvt_noamb).param{1}  = cos( dat.ANG(flag_NOAMBIG)*pi/180 );
            %             pmod(mvt_noamb).poly {1}  = 1;
            %             pmod(mvt_noamb).name {2}  = 'sin';
            %             pmod(mvt_noamb).param{2}  = sin( dat.ANG(flag_NOAMBIG)*pi/180 );
            %             pmod(mvt_noamb).poly {2}  = 1;
            %             % no ambig for mvt_noamb
            
        end
        names(ntrials+1:end) = name_other;
        
        
        [pathstr, name, ext] = fileparts(   deblank(onsets_datfile{iSubj}(iRun,:)) );
        %         save( fullfile(pathstr,[name '_mvpa']) , 'names', 'onsets', 'durations', 'pmod' )
        save( fullfile(pathstr,[name '_mvpa']) , 'names', 'onsets', 'durations' )
        
        % plotSPMnod(names,onsets,durations);
        
    end % iRun
    
end % iSubj
