%% bfa_to_batches.m
% Extract the Beamforming Feedback Information
% Copyright (C) 2025 Khandaker Foysal Haque
% Contact: haque.k@northeastern.edu
% This program is free software under the GNU GPL v3 license.


clc; clear; close all;

activity = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T"];

env = 'Classroom';
station = '89';
window_size = 10;
interval = 0.1;

% Load MAT files
for m = 1:length(activity)
    folder_name = sprintf('../Data/BFI/Processed/%s/%s/beamf_angles/%s/', env, station, activity(m));
    folder_save = sprintf('../Data/BFI/Processed/%s/%s/beamf_angles/%s_batch/', env, station, activity(m));
    csv_dir = sprintf('../Data/BFI/Processed/%s/%s/FeedBack_Pcap/', env, station);

    files = dir(fullfile(folder_name, '*.mat'));

    for file_idx = 1:numel(files)
        FILE = strcat(folder_name, files(file_idx).name); % Capture file
        person_name = files(file_idx).name(end-26:end-22);
        disp(person_name);

        csv_name = strcat(csv_dir, files(file_idx).name(end-26:end-4), '_', station, '.csv');
        load(FILE);

        % Initialize padding and read CSV
        dim = size(cell2mat(beamf_angles(1)), 1);
        ch = size(cell2mat(beamf_angles(1)), 2);
        zero_pkt = zeros(1, dim, ch); % Padding

        sheet = readtable(csv_name); % Sheet: num - time
        
        count = 1; % Number of time intervals
        i = 1;

        while count * interval <= 300
            bf_matrix = [];
            try
                while sheet.Time(i) - interval * (count - 1) < interval
                    bf_matrix = [bf_matrix; reshape(cell2mat(beamf_angles(i)), 1, dim, ch)];
                    disp(i);
                    i = i + 1;
                end
            catch
                bf_matrix = [];
            end

            bf_size = size(bf_matrix);
            if bf_size(1) < window_size
                for j = 1:(window_size - bf_size(1))
                    bf_matrix = [bf_matrix; zero_pkt];
                end
            else
                bf_matrix = bf_matrix(1:window_size, :, :);
            end

            mat_name = strcat(folder_save, person_name, 'batch', '_', string(count), '.mat');
            save(mat_name, 'bf_matrix');
            count = count + 1;
        end
    end
end
