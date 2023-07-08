addpath('C:\Users\Zachary_Pranske\Documents\GitHub\Trackmate_Analysis');
path = uigetdir('C:\Users\Zachary_Pranske\Desktop\Datasets');

filePattern = fullfile(path, '*.xml'); % Change to whatever pattern you need.
filenames_list = dir(filePattern);

start_frame = 0;
end_frame = 720;
frame_range = start_frame:end_frame;

%Loop to go through all xml's in a folder
skip_flag = false; ask=1;
for k = 1 : length(filenames_list)
    filename = filenames_list(k).name;
    file_path = fullfile(filenames_list(k).folder, filename);
    disp(['Now processing file ' filename '...'])
    if ~exist([path '\Variables from ' filename '.mat'])
        [spot_table,spot_ID_map,edge_map,G] = processTMoutputs(filename,file_path);
    else
        if ~skip_flag
             ask = input(['Found data for this file. Load existing workspace variables or reprocess? 1=use existing, 2=reprocess \n' ...
                'WARNING: selecting reprocess will replace all workspace variables and results files ' ...
                'in the working folder. \nProcessing may take up to several minutes per file. ']);
            y = input(['Do this for the rest of the files? 1=yes 2=no ']);
            if y==1;
                skip_flag=true;
            end
        end
        if ask==1
            load([path '\Variables from ' filename '.mat']);
        else
            [spot_table,spot_ID_map,edge_map,G] = processTMoutputs(filename,file_path);
        end
    end  
    
    %Process edges
    edgeinfo = process_edges(spot_table,edge_map,frame_range,filename);
    writetable(edgeinfo, [path '\Edge Table from ' filename '.csv']);   
    
    % Graph connectivity of edges (should reveal info about splits and merges)
    f = figure;
    hp = plot(G,'layout','layered');
    set(hp, 'YData', G.Nodes.FRAME);
    set(gca, 'YDir', 'reverse', 'XColor', 'none')
    ylabel('Time point')
    box off
    savefig(f,[path '\Map of ' filename '.fig']);
    
    %Analyze splits and merges
    t_removed = analyze_split_merge(G,filename,path);
    writematrix(t_removed, [path '\Survival curve from ' filename '.csv']);
end

beep; disp(['All files successfully processed!'])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% FUNCTIONS NEEDED FOR THIS THING TO WORK PROPERLY %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function[spot_table,spot_ID_map,edge_map,G] = processTMoutputs(filename,file_path)
    disp(['Analyzing spots for ' filename '...'])
    [spot_table, spot_ID_map] = trackmateSpots(file_path);
    writetable(spot_table, [path 'Spot Table of ' filename '.csv']);
    disp(['Analyzing edges for ' filename '...'])
    edge_map = trackmateEdges(file_path);
    G = trackmateGraph(file_path, [], [], true);
    save([path 'Variables from ' filename '.mat']);
end

function [edgeinfo] = process_edges(spot_table,edge_map,frame_range,filename)
    track_names = edge_map.keys;
    edgeinfo = table();
    for i = 1:edge_map.Count
        edges_i = edge_map(track_names{i});
        spot_ids_i = edge_map(track_names{i}).SPOT_SOURCE_ID;
        spot_rows_i = ismember(spot_table.ID, spot_ids_i); %List the rows in the spot table to pull for this edge        
        edge_info_i = spot_table(spot_rows_i,:);

        edge_info_i = edge_info_i(ismember(edge_info_i.FRAME,frame_range),:);
        edges_i = edges_i(ismember(edge_info_i.FRAME,frame_range),:);

        if(height(edge_info_i)>0)
            start_frame = edge_info_i.FRAME(1);
            end_frame = edge_info_i.FRAME(end);
            n_spots = height(edge_info_i);        

            startx_i = edges_i.EDGE_X_LOCATION(1);
            endx_i = edges_i.EDGE_X_LOCATION(end);
            starty_i = edges_i.EDGE_Y_LOCATION(1);
            endy_i = edges_i.EDGE_Y_LOCATION(end);
            total_disp_i = sqrt((endx_i-startx_i)^2 + (endy_i-starty_i)^2);
            total_distance_i = sum(edges_i.DISPLACEMENT);

            %Now pull info about the spots that comprise this track. For instance, look at first and last spots in this edge to find when
            %it was detected (for time subanalysis, e.g. look at first 10 mins of
            %each image) or find how many spots are in this track

            edgeinfo(i,:) = table(string(filename),[double(i), n_spots, total_disp_i, total_distance_i, start_frame, end_frame]);
        end
    end
end

function [t_removed] = analyze_split_merge(G,filename,path)
    %Get list of nodes with indegree 0 and outdegree >0 (indicating it is a
    %parent node)
    parent_nodes = find(indegree(G)==0 & outdegree(G)>0);

    %Get number of parent nodes with a downstream split
    n_splits_bucket = 0;
    survival = [];
    for i=1:length(parent_nodes)
        children = nearest(G,parent_nodes(i),Inf);
        doesitsplit = max(outdegree(G,children))>1;
        if doesitsplit
            n_splits_bucket = n_splits_bucket + 1;
        end
        P = shortestpath(G,parent_nodes(i),children(end));
        survival(i)=length(P);
    end
    survival = sort(survival');
    gc = groupcounts(survival);
    survival = [unique(survival) gc];
    t_removed = [];
    n_frames=750;
    p = 0; %Number to remove from each timepoint
    for i=1:n_frames
        if isempty(find(survival(:,1)==i));
            %do nothing
        else
            idx = find(survival(:,1)==i);
            subtract = survival(idx,2);
            p=p+subtract;
        end
        t_removed(i) = length(parent_nodes)-p;
    end
    t_removed = t_removed';

    n_tracks_w_split = n_splits_bucket;
    n_tracks_total = length(parent_nodes);
    percent_split = n_tracks_w_split / n_tracks_total;

    %Get TOTAL number of splitting events
    n_splits = sum(outdegree(G)>1);
    n_merges = sum(indegree(G)>1);
    
    fileID = fopen([path '\Split info from ' filename '.txt'],'w');
        fprintf(fileID,['n_tracks_total' '\t' int2str(n_tracks_total) '\n']);
        fprintf(fileID,['n_tracks_w_split' '\t' int2str(n_tracks_w_split) '\n']);
        fprintf(fileID,['percent_split' '\t' num2str(percent_split) '\n']);
        fprintf(fileID,['n_splits' '\t' int2str(n_splits) '\n']);
        fprintf(fileID,['n_merges' '\t' int2str(n_merges) '\n']);
    fclose(fileID);
end

%% DISPLAY SPOT CLOUD IN MATLAB
%Use to make sure it matches with Fiji and has spots in ROIs only

%     x = spot_table.POSITION_X;
%     y = spot_table.POSITION_Y;
%     figure;
%     plot(x, y, 'k.');
%     axis equal;
%     units = 'um'; %char(spot_table.Properties.VariableUnits(22));
%     xlabel(['X (' units ')']);
%     ylabel(['Y (' units ')']);
%     hold on;

%% Import edge track table

%Sample code to highlight a specific track on the graph

% x = edge1.POSITION_X;
% y = edge1.POSITION_Y;
% plot(x, y, 'bx')
% units = 'um'; %char(spot_table.Properties.VariableUnits(22));
% xlabel(['X (' units ')'])
% ylabel(['Y (' units ')'])
% x1 = edge1.POSITION_X(1);
% y1 = edge1.POSITION_Y(1);
% plot(x1,y1,'go')
% x_end = edge1.POSITION_X(end);
% y_end = edge1.POSITION_Y(end);
% plot(x_end,y_end,'ro')
