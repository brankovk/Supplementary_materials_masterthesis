%% setup
setenv('WB_COMMAND', 'C:\Program Files\workbench\bin_windows64\wb_command.exe');

%% prep
id_file = "C:\Users\brank\Desktop\Masterarbeit_offiziell\Data\Task Data\WM brain states\Vorbereitung_extraction\HCP_1200_ids.txt";
atlas_base = "C:\Users\brank\Desktop\Masterarbeit_offiziell\Data\Task Data\WM brain states\results";
cope_base = "C:\Users\brank\Desktop\Masterarbeit_offiziell\Data\Task Data\WM brain states\States_Extracted";
output_base = "C:\Users\brank\Desktop\Masterarbeit_offiziell\Matlab\States prepared";

sub_string = fileread(id_file);
HCP1200ids = cellstr(split(strtrim(sub_string)));

%% extract mean value per ROI on Lausanne250

for subj=1:length(HCP1200ids)
    subj_id = strtrim(HCP1200ids{subj});

    fprintf('Processing subject %s\n', subj_id);

    atlas_path = fullfile(atlas_base, subj_id,'MNINonLinear', 'fsaverage_LR32k',[subj_id '.Laus250.32k_fs_LR.dlabel.nii']);
    atlas = ciftiopen(atlas_path);
    
    for c = 9:10
        cope_path = fullfile(cope_base, subj_id,['cope' num2str(c) '.feat'],'cope1.dtseries.nii');
        try
            disp(atlas_path)
            if ~isfile(atlas_path)
    error("Atlas file not found: %s", atlas_path);
end
            cii = ciftiopen(cope_path);
            cii = cii.cdata; %extract dense timeseries
            for k=1:max(atlas.cdata) % loop across ROIs
                sysmat{k,1}=mean(cii(atlas.cdata==k,:), 'all'); %xtract mean activation
                sysmat{k,2}=k;
                sysmat{k,3} = atlas.diminfo{1,2}.maps.table(k+1).name;
            end
            varname = ['HCP_' subj_id  '_cope' num2str(c) '_mean_firstlevel'];
            eval([varname '= sysmat;']); % assign mat
            clear sysmat % not needed  any more
            clear cii % not needed  any more
        catch
            disp(['HCP ' subj_id ' failed' ])
        end
        savefile = fullfile(output_base, subj_id, 'MNINonLinear', 'Results', 'tfMRI_WM', [subj_id '_cope' num2str(c) '_mean_firstlevel.mat']);
        try
            mkdir(fileparts(savefile))
            save(savefile,varname);
        catch
            disp(['HCP ' subj_id ' failed to save file'])
        end
    end
end
