addpath('C:\Users\Zachary_Pranske\Documents\GitHub\Trackmate_Analysis');
file_path = 'D:\LIVE IMAGES\2023-01-12 analysis GAD65\ALIGNED IMAGES\ROIs_ALIGNED_MAX_ZP_XXXX_Fc_2nM_GAD65-GFP_63x_stack_1h_15s_2_combined.xml';

[spot_table, spot_ID_map] = trackmateSpots(file_path);

%DISPLAY SPOT CLOUD IN MATLAB
%Use to make sure it matches with Fiji and has spots in ROIs only
x = spot_table.POSITION_X;
y = spot_table.POSITION_Y;
figure
plot(x, y, 'k.')
axis equal
units = 'um'; %char(spot_table.Properties.VariableUnits(22));
xlabel(['X (' units ')'])
ylabel(['Y (' units ')'])

%Import edge track table
edge_map = trackmateEdges(file_path);
%Sample code for how to pull all the spots that comprise a track and see info
%about them
edge1spots = edge_map('Track_1').SPOT_SOURCE_ID
edge1rows = ismember(spot_table.ID, edge1spots);
spot_table(edge1rows,:);

%Edge analysis
%TURN THIS INTO A LOOP FOR ALL EDGES
edges1 = edge_map('Track_1');
startx = edges1.EDGE_X_LOCATION(1);
endx = edges1.EDGE_X_LOCATION(end);
starty = edges1.EDGE_Y_LOCATION(1);
endy = edges1.EDGE_Y_LOCATION(end);
total_disp = sqrt((endx-startx)^2 + (endy-starty)^2);
total_distance = sum(edges1.DISPLACEMENT);
%NOTE this is not "displacement" as calculated above: since it corresponds
%to displacement of a single point-to-point link, its sum is actuall total distance traveled 
%Another possibility: mean(edges1.SPEED)*height(edges1) -- Seems to yield
%same result

%Graph connectivity of edges (should reveal info about splits and merges)
G = trackmateGraph(file_path, [], [], true);

figure
hp = plot(G, 'layout', 'layered');
set(hp, 'YData', G.Nodes.FRAME);
set(gca, 'YDir', 'reverse', 'XColor', 'none')
ylabel('Time point')
box off

%Get number of splitting events
n_splits = sum(outdegree(G)>1);
n_merges = sum(indegree(G)>1);


