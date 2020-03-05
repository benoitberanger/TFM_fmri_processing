%% Load

clear
clc
global prevrend

load e

allView = {
    'Go to Y-Z view (right)'  [  90   0] 'right'
    'Go to Y-Z view (left)'   [ -90   0] 'left'
    'Go to X-Y view (top)'    [   0  90] 'top'
    'Go to X-Y view (bottom)' [-180 -90] 'bottom'
    'Go to X-Z view (front)'  [-180   0] 'front'
    'Go to X-Z view (back)'   [   0   0] 'back'
    };

outdir = '/network/lustre/iss01/cenir/analyse/irm/users/benoit.beranger/TFM/png';


%% Which one ?

models = e.getModel('ambig');
views = allView;

contrasts = {
    'mvt_noamb_cos'
    'mvt_noamb_sin'
    'mvt_amb_ambig'
    'mvt_amb-mvt_noamb'
    };



%% Go

for m  = 1 : length(models)
    
    % Open SPM GUI
    matlabbatch{1}.spm.stats.results.spmmat = {models(m).path};
    matlabbatch{1}.spm.stats.results.conspec.titlestr = '';
    matlabbatch{1}.spm.stats.results.conspec.contrasts = 1;
    matlabbatch{1}.spm.stats.results.conspec.threshdesc = 'none';
    matlabbatch{1}.spm.stats.results.conspec.thresh = 0.001;
    matlabbatch{1}.spm.stats.results.conspec.extent = 20;
    matlabbatch{1}.spm.stats.results.conspec.conjunction = 1;
    matlabbatch{1}.spm.stats.results.conspec.mask.none = 1;
    matlabbatch{1}.spm.stats.results.units = 1;
    matlabbatch{1}.spm.stats.results.print = false;
    matlabbatch{1}.spm.stats.results.write.none = 1;
    spm('defaults','fmri')
    spm_jobman('run',matlabbatch)
    
    contrast_name = strrep({SPM.xCon.name}',' ','');
    contrast_name = strrep(contrast_name,'-AllSessions','');
    
    for c = 1 : length(contrasts)
        
        con = strcmp(contrast_name,contrasts{c});
        con = find(con);
        if numel(con)~=1
            keyboard
        end
        
        % Change contrast
        xSPM2.swd   = xSPM.swd;
        try, xSPM2.units = xSPM.units; end
        %         xSPM2.Ic    = getfield(get(obj,'UserData'),'Ic');
        xSPM2.Ic    = con
        if isempty(xSPM2.Ic) || all(xSPM2.Ic == 0), xSPM2 = rmfield(xSPM2,'Ic'); end
        xSPM2.Im    = xSPM.Im;
        xSPM2.pm    = xSPM.pm;
        xSPM2.Ex    = xSPM.Ex;
        xSPM2.title = '';
        if ~isempty(xSPM.thresDesc)
            if strcmp(xSPM.STAT,'P')
                % These are soon overwritten by spm_getSPM
                xSPM2.thresDesc = xSPM.thresDesc;
                xSPM2.u = xSPM.u;
                xSPM2.k = xSPM.k;
                % xSPM.STATstr contains Gamma
            else
                td = regexp(xSPM.thresDesc,'p\D?(?<u>[\.\d]+) \((?<thresDesc>\S+)\)','names');
                if isempty(td)
                    td = regexp(xSPM.thresDesc,'\w=(?<u>[\.\d]+)','names');
                    td.thresDesc = 'none';
                end
                if strcmp(td.thresDesc,'unc.'), td.thresDesc = 'none'; end
                xSPM2.thresDesc = td.thresDesc;
                xSPM2.u     = str2double(td.u);
                xSPM2.k     = xSPM.k;
            end
        end
        hReg = spm_XYZreg('FindReg',spm_figure('GetWin','Interactive'));
        xyz  = spm_XYZreg('GetCoords',hReg);
        [hReg,xSPM,SPM] = spm_results_ui('setup',xSPM2);
        TabDat = spm_list('List',xSPM,hReg);
        spm_XYZreg('SetCoords',xyz,hReg);
        assignin('base','hReg',hReg);
        assignin('base','xSPM',xSPM);
        assignin('base','SPM',SPM);
        assignin('base','TabDat',TabDat);
        figure(spm_figure('GetWin','Interactive'));
        
        % 3D Render
        rendfile = fullfile(spm('dir'),'canonical','cortex_20484.surf.gii');
        prevrend = struct('rendfile',rendfile,'brt',[],'col',[]);
        spm_render(struct( 'XYZ',xSPM.XYZ,'t',xSPM.Z','mat',xSPM.M,'dim',xSPM.DIM),prevrend.brt,prevrend.rendfile)
        
        % Get graphic objects ad variables related to the render
        patch = findobj('tag','SPMMeshRender');
        H = getappdata(patch.Parent,'handles');
        
        % Inflate
        spm_mesh_inflate(H.patch,Inf,1);
        axis(H.axis,'image');
        
        % View
        for v = 1 : size(views,1)
            view(H.axis,views{v,2});
            axis(H.axis,'image');
            camlight(H.light);
            
            % Save PNG
            F = spm_figure('GetWin','Graphics');
            fname = fullfile(outdir,[models(m).exam.name '---' contrasts{c} '---' views{v,3}]);
            saveas(F,fname,'png')
            
        end
        
    end
    
end


