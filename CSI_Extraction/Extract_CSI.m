%% Extract_CSI.m
% Extract the Beamforming Feedback Information
% Copyright (C) 2025 Khandaker Foysal Haque
% Contact: haque.k@northeastern.edu
% This program is free software under the GNU GPL v3 license.

clc; clear; close all;

%% Configuration Parameters
total_monitor = 3;
environments = {'Kitchen', 'Livingroom'}; % List of environments
% environments = {'Classroom'}; % List of environments
subjects = {'sub1', 'sub2', 'sub3'}; % List of subjects
CHIP = '4366c0'; % WiFi chip (options: 4339, 4358, 43455c0, 4366c0)
BW = 80; % Bandwidth in MHz
conf = '1x1'; % CSI configuration
save_in = '../Data/CSI';

% Subcarrier indices for non-zero values
if BW == 20
    non_zero = [5:32, 34:61];
else
    non_zero = [7:128, 132:251];
end

activities = 'A':'T';
core_labels = ['00'; '01'; '02'; '03'];

%% Main Processing Loop
for env_idx = 1:length(environments)
    save_env = environments{env_idx}; % Current environment
    for sub_idx = 1:length(subjects)
        sub = subjects{sub_idx}; % Current subject
        for num_mo = 1:3
            for c = 1:size(conf, 1)
                num_ant = str2double(conf(c, end));
                
                for a = 1:length(activities)
                    activity = activities(a);
                    seq_plane = cell(num_mo, 1);
                    core_plane = cell(num_mo, 1);
                    data_raw = cell(num_mo, 1);

                    % Generate the desired .pcap file name
                    sub_file = sprintf('%s_%dMHz_%s_M%d_%s.pcap', activity, BW, conf, num_mo, sub);
                    FILE = sprintf('%s/Raw/%s/m%d/%s', save_in, save_env, num_mo, sub_file);
                    fprintf('Now reading %s\n', FILE);

                    % Initialize pcap reader
                    p = readpcap();
                    p.open(FILE);
                    n = min(length(p.all()), 1000000); % Max number of packets
                    p.from_start();
                    
                    % Initialize buffers
                    csi_buff = complex(zeros(n, BW * 3.2), 0);
                    seq_num = [];
                    core_num = [];

                    % Read pcap frames
                    for k = 1:n
                        f = p.next();
                        if isempty(f)
                            fprintf('No more frames\n');
                            break;
                        end

                        if f.header.orig_len - (16 - 1) * 4 ~= BW * 3.2 * 4
                            fprintf('Skipped frame with incorrect size\n');
                            continue;
                        end

                        payload = f.payload;
                        P14 = dec2hex(payload(14), 8);
                        seq_num = [seq_num; P14(5:end)];
                        core_num = [core_num; P14(1:2)];

                        H = payload(16:16 + BW * 3.2 - 1);

                        switch CHIP
                            case {'4339', '43455c0'}
                                Hout = typecast(H, 'int16');
                            case '4358'
                                Hout = unpack_float(int32(0), int32(BW * 3.2), H);
                            case '4366c0'
                                Hout = unpack_float(int32(1), int32(BW * 3.2), H);
                            otherwise
                                error('Invalid CHIP');
                        end

                        Hout = reshape(Hout, 2, []).';
                        csi_buff(k, :) = double(Hout(:, 1)) + 1j * double(Hout(:, 2));
                    end

                    % Save processed data
                    seq_plane{num_mo} = seq_num;
                    core_plane{num_mo} = core_num;
                    data_raw{num_mo} = csi_buff;

                    % Filter data and save as .mat file
                    csi = csi_buff(:, non_zero);
                    mat_name = sprintf('%s/Processed/%s/m%d/%s/%s_%s.mat', save_in, save_env, num_mo, activity, activity, sub);
                    save(mat_name, 'csi');
                end
            end
        end
    end
end

fprintf('Processing complete.\n');
