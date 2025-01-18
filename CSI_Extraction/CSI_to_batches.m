%% CSI_to_batches.m
% Extract the Beamforming Feedback Information
% Copyright (C) 2025 Khandaker Foysal Haque
% Contact: haque.k@northeastern.edu
% This program is free software under the GNU GPL v3 license.

clc; clear; close all;

activity = ['A' ; 'B' ; 'C' ; 'D' ; 'E' ; 'F'; 'G'; 'H'; 'I'; 'J'; 'K'; 'L'; 'M' ; 'N' ; 'O' ; 'P'; 'Q' ;'R'; 'S'; 'T'; 'U'];

env_list = {'Classroom', 'Kitchen', 'Livingroom'};
monitor_list = {'m1', 'm2', 'm3'};
BW = '80MHz';
window_size = 60;

for e = 1:length(env_list)
    env = env_list{e};
    for mon = 1:length(monitor_list)
        monitor = monitor_list{mon};

        for m = 1:length(activity)
            folder_name = sprintf('../Data/CSI/Processed/%s/%s/%s/', env, monitor, activity(m));
            folder_save = sprintf('../Data/CSI/Processed/%s/%s/%s_batch/', env, monitor, activity(m));
            
            if ~exist(folder_save, 'dir')
                mkdir(folder_save);
            end
            
            files = dir(fullfile(folder_name, '*.mat'));

            for file_idx = 1:numel(files)
                FILE = strcat(folder_name, files(file_idx).name); % capture file
                person_name = files(file_idx).name(3:6);
                disp(person_name);

                load(FILE);

                discard = 5;
                disp(activity(m));

                num_p = size(csi, 1);
                window = window_size;
                num_image = floor(num_p / window);
                
                % Process data window by window
                for i = discard:num_image-discard
                    csi_mon = [];
                    csi_mon = [csi_mon; csi((i-1)*window+1:i*window, :)];
                    mat_name = strcat(folder_save, person_name, 'batch_', string(i-discard), '.mat');
                    save(mat_name, 'csi_mon');
                end
            end
        end
    end
end
