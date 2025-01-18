%% pcap_to_bfa.m
% Extract the Beamforming Feedback Information
% Copyright (C) 2025 Khandaker Foysal Haque
% Contact: haque.k@northeastern.edu
% This program is free software under the GNU GPL v3 license.

clc; clear; close all;

%%Extraction Configuration 

env_list = {'Classroom', 'Kitchen', 'Livingroom'};
station_list = {'9C', '25', '89'};
n = 100000000;   %%max num of UDPs

activities =['A_01', 'A_02', 'A_03', 'A_04','A_05', 'A_06', 'A_07', 'A_08', 'A_09', 'A_10', 'A_11', 'A_12', 'A_13', 'A_14', 'A_15', 'A_16','A_17', 'A_18', 'A_19', 'A_20' ];


%% configuration
user_names = ['25', '9C', '89'];
name_suffix_offset = 10;


Nc_users = [1, 1, 1]; % number of spatial streams
phi_numbers = [2, 2, 2];
psi_numbers = [2, 2, 2];
skip_start_users = [255, 255, 255];
skip_start_sample_users = [33, 33, 33];
folder_proc = 'processed_dataset';

Nr = 3;  % number of Tx antennas
psi_bit = 7;
phi_bit = psi_bit + 2;
order_angles = ['phi_11', 'phi_21', 'psi_21', 'psi_31', 'phi_22', 'psi_32'];
order_bits = [phi_bit, phi_bit, psi_bit, psi_bit, phi_bit, psi_bit];

tot_angles_users = phi_numbers + psi_numbers;
tot_bits_users = phi_numbers*phi_bit + psi_numbers*psi_bit;
tot_bytes_users = ceil(tot_bits_users/8); 

BW = 80;                 
NSUBC = 256;
subcarrier_idxs = linspace(1, NSUBC, NSUBC) - NSUBC/2 - 1;
pilot_subcarriers = [25, 53, 89, 117, 139, 167, 203, 231];
num_pilots = numel(pilot_subcarriers);
subcarrier_idxs(252:end) = [];
subcarrier_idxs(231) = [];
subcarrier_idxs(203) = [];
subcarrier_idxs(167) = [];
subcarrier_idxs(139) = [];
subcarrier_idxs(128:130) = [];
subcarrier_idxs(117) = [];
subcarrier_idxs(89) = [];
subcarrier_idxs(53) = [];
subcarrier_idxs(25) = [];
subcarrier_idxs(1:6) = [];
NSUBC_VALID = numel(subcarrier_idxs);
length_angles_users = NSUBC_VALID*tot_bytes_users;
length_report_users = ((NSUBC_VALID + num_pilots)/2 + 1)/2*Nc_users;

for env_idx = 1:length(env_list)
    env = env_list{env_idx};
    for station_idx = 1:length(station_list)
        station = station_list{station_idx};
        folders_name = strcat('../Data/BFI/Processed/', env, '/', station, '/', 'FeedBack_Pcap/');

        for folder_idx = 1:size(folders_name, 1)

            folder_name = folders_name(folder_idx, :);
            files = dir(fullfile(folder_name, '*.pcapng'));

            for file_idx = 1:numel(files)
                FILE = strcat(folder_name, files(file_idx).name); % capture file
                user_name = files(file_idx).name(end-8:end-7);
                if user_name == user_names(1:2)
                    index_user = 1;
                elseif user_name == user_names(3:4)
                    index_user = 2;
                elseif user_name == user_names(5:6)
                    index_user = 3;
                end
                
                activity_num = files(file_idx).name(end-27:end-24);
                if activity_num == activities(1:4)
                    activity = 'A';
                    
                elseif activity_num == activities(5:8)
                    activity = 'B';
                    
                elseif activity_num == activities(9:12)
                    activity = 'C';
                    
                elseif activity_num == activities(13:16)
                    activity = 'D';
                    
                elseif activity_num == activities(17:20)
                    activity = 'E';
                    
                elseif activity_num == activities(21:24)
                    activity = 'F';

                elseif activity_num == activities(25:28)
                    activity = 'G';
                    
                elseif activity_num == activities(29:32)
                    activity = 'H';
                    
                elseif activity_num == activities(33:36)
                    activity = 'I';
                    
                elseif activity_num == activities(37:40)
                    activity = 'J';
                    
                elseif activity_num == activities(41:44)
                    activity = 'K';

                elseif activity_num == activities(45:48)
                    activity = 'L';
                    
                elseif activity_num == activities(49:52)
                    activity = 'M';
                    
                elseif activity_num == activities(53:56)
                    activity = 'N';
                    
                elseif activity_num == activities(57:60)
                    activity = 'O';
                    
                elseif activity_num == activities(61:64)
                    activity = 'P';

               elseif activity_num == activities(65:68)
                    activity = 'Q';
                    
                elseif activity_num == activities(69:72)
                    activity = 'R';
                    
                elseif activity_num == activities(73:76)
                    activity = 'S';
                    
                elseif activity_num == activities(77:80)
                    activity = 'T';
                    
                end
                
                Nc = Nc_users(index_user);
                tot_bytes = tot_bytes_users(index_user);
                tot_angles = tot_angles_users(index_user);
                length_angles = length_angles_users(index_user);
                length_report = length_report_users(index_user);
                skip_start  = skip_start_users(index_user);
                skip_start_sample = skip_start_sample_users(index_user);
                
                payload_length = Nc + length_angles + length_report;
                
                disp(FILE);
                file_name = files(file_idx).name(1:end-name_suffix_offset);
                folder_save = strcat('../Data/BFI/Processed/', env,'/',  station, '/');
                name_beamf_angles = strcat(folder_save, 'beamf_angles/', activity, '/', file_name,'.mat');
                name_exclusive_beamf_report = strcat(folder_save, 'exclusive_beamf_report/', file_name, '.mat');
                name_vtilde_matrices = strcat(folder_save, 'vtilde_matrices/', file_name, '.mat');
                name_time_vector = strcat(folder_save, 'time_vector/', file_name, '.mat');

                if isfile(name_time_vector)
                    continue
                end

                %% read angles
                p = readpcap_beamf();
                p.open(FILE, skip_start);
                k_start = 1;
                k = k_start;
                beamf_angles = {};
                excl_beamf_reports = {};
                vtilde_matrices = {};
                time_vector = {};
                while (k <= n)
                    f = p.next(payload_length, skip_start_sample);
                    if isempty(f.payload)
                        disp('no more frames');
                        break;
                    end
                    if size(f.payload, 1) < payload_length
                        disp('error payload_length');
                        break;
                    end
                    if f.header.source_mac(6, 1:2) ~= user_name
                        disp('error user_name');
                        break;
                    end
                        
                    timestamp_dec = flip(f.header.radiotap_header(9:16));
                    timestamp_bin = de2bi(timestamp_dec, 'left-msb', 8);
                    timestamp_bin = reshape(timestamp_bin.', 1, []);
                    timestamp = bi2de(timestamp_bin, 'left-msb');
                    time_vector{k-k_start+1} = timestamp;

                    snr = flip(f.payload(1:Nc));

                    start_angles = Nc+1;
                    end_angles = start_angles+length_angles-1;
                    angle_values = f.payload(start_angles:end_angles);
                    beamforming_angles = zeros(NSUBC_VALID, tot_angles);
                    for s_i = 1:NSUBC_VALID
                        start_idx = (s_i-1)*tot_bytes + 1;
                        end_idx = s_i*tot_bytes;%index_user
                        angles_subc_dec = (angle_values(start_idx:end_idx));
                        angles_subc = de2bi(angles_subc_dec, 'right-msb', 8);
                        angles_subc = reshape(angles_subc.', 1, []);
                        i_curs = 1;
                        for a_i = 1:tot_angles
                            num_b = order_bits(a_i);
                            angle_val = bi2de(angles_subc(i_curs:i_curs+num_b-1), 'right-msb');
                            beamforming_angles(s_i, a_i) = angle_val;
                            i_curs = i_curs + num_b;
                        end
                    end
                    beamf_angles{k-k_start+1} = beamforming_angles;

                    start_report = start_angles+length_angles;
                    end_report = start_report+length_report-1;
                    length_payload = numel(f.payload);
                    if end_report > length_payload
                        continue
                    end
                    exclusive_beamf_report = f.payload(start_report:end_report);
                    excl_beamf_reports{k-k_start+1} = exclusive_beamf_report;

                    %% compute vtilde_matrix
                    if Nc == 2
                        vtilde_matrix = Vtilde_NSS2(beamforming_angles, Nc, Nr, NSUBC_VALID, phi_bit, psi_bit);
                    elseif Nc == 1
                        vtilde_matrix = Vtilde_NSS1(beamforming_angles, Nc, Nr, NSUBC_VALID, phi_bit, psi_bit);
                    end
                    
                    vtilde_matrices{k-k_start+1} = vtilde_matrix;

                    k = k + 1;

                end

                save(name_time_vector, 'time_vector')
                save(name_beamf_angles, 'beamf_angles')
                save(name_exclusive_beamf_report, 'excl_beamf_reports')
                save(name_vtilde_matrices, 'vtilde_matrices')
              
            end
        end
    end
end
