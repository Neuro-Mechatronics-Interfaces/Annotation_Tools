function fig = annotateSlices(folderPath, options)
%ANNOTATESLICES Allows user to manually add annotations about "channel" locations by adding points to image slices.
%
% This function provides an interactive interface for annotating transverse MRI sections of the forearm.
% Users can navigate between slices, specify the channel being annotated, and save the annotations as a CSV file.
%
% Syntax: 
%   annotateSlices(folderPath);
%   fig = annotateSlices(folderPath,'Name',value,...);
%
% Inputs:
%   folderPath: (string, optional) Path to the folder containing image slices. If not provided, a directory
%               selection dialog will be shown. Default is an empty string.
%   options: (struct, optional) A structure containing the following fields:
%       - CData: (numeric matrix, optional) Custom color data for channels, with each row representing
%                RGB values. Default is generated using the 'winter' colormap.
%       - DefaultSliceSearchPath: (string, optional) Default path for the directory selection dialog. 
%                                 Default is 'C:/Data/Anatomy'.
%       - ImageFilePrefix: (string, optional) Prefix of the image file names to search for in the folder.
%                          Default is 'R_Forearm_Section_'.
%       - ImageFileType: (string, optional) Type of image files (e.g., '.png', '.jpg'). Default is '.png'.
%       - MarkerSize: (double, optional) Size of the markers used for annotations. Default is 16.
%       - NumChannels: (integer, optional) Number of channels to annotate. Default is 128.
%
% Outputs:
%   fig - MATLAB uifigure handle to this interface.
%
% See also: Contents

arguments
    folderPath = "";
    options.CData = [];
    options.ChannelMap = [];
    % options.ChannelMap = [17 16	15	14	13	9	5	1	22	21	20	19	18	10	6	2	27	26	25	24	23	11	7	3	32	31	30	29	28	12	8	4	33	34	35	36	37	53	57	61	38	39	40	41	42	54	58	62	43	44	45	46	47	55	59	63	48	49	50	51	52	56	60	64];
    options.ConfigOut = 'annotations.csv';
    options.DefaultSliceSearchPath {mustBeTextScalar} = 'C:/Data/Anatomy';
    options.ImageFilePrefix {mustBeTextScalar} = 'R_Forearm_Section_';
    options.ImageFileType {mustBeTextScalar} = '.png';
    options.MarkerSize (1,1) double = 8;
    options.NumChannels (1,1) {mustBeInteger} = 64;
    options.NumChannelsPerArc (1,1) {mustBeInteger} = 8;
    options.SliceOffset = [];
end

if strlength(folderPath) == 0
    folderPath = uigetdir(options.DefaultSliceSearchPath, ...
        'Select folder containing image sections');
    if folderPath == 0
        disp("No folder selected. Exited.");
        return;
    end
end

if isempty(options.CData)
    cdata = winter(options.NumChannels);
else
    cdata = options.CData;
    if size(cdata,1) < options.NumChannels
        error('MATLAB:badsubscript', ...
            "Must have at least as many rows in CData as requested Channels (%d).", ...
            options.NumChannels);
    end
end

if isempty(options.ChannelMap)
    chMap = 1:options.NumChannels;
else
    if numel(options.ChannelMap) ~= options.NumChannels
        error('MATLAB:badsubscript', ...
            "Must have exactly as many elements in ChannelMap as requested Channels (%d).", ...
            options.NumChannels);
    end
    chMap = options.ChannelMap;
end

% Get list of image files
imageFiles = dir(fullfile(folderPath, sprintf('%s*%s',options.ImageFilePrefix,options.ImageFileType)));
if isempty(imageFiles)
    error('MATLAB:load:couldNotReadFile', ...
        'No images found in the specified folder.');
end

if isempty(options.SliceOffset)
    sliceIndexingOffset = inf;
    for ii = 1:numel(imageFiles)
        f = strrep(strrep(imageFiles(ii).name,options.ImageFilePrefix,''),options.ImageFileType,'');
        sliceIndexingOffset = min(sliceIndexingOffset, str2double(f)-1);
    end
    fprintf(1,'Detected sliceIndexingOffset as %d. If that is incorrect, set it manually using the `SliceOffset` option.\n', sliceIndexingOffset);
else
    sliceIndexingOffset = options.SliceOffset;
    fprintf(1,'Using manual slice indexing offset value of %d.\n', sliceIndexingOffset);
end

% Initialize the figure and UI elements
fig = uifigure( ...
    'Name', 'Annotate Forearm Slices', ...
    'NumberTitle', 'off', ...
    'Units', 'inches', ...
    'Color', 'w', ...
    'Position', [3.5 2.75 8 5], ...
    'KeyPressFcn', @handleWindowKeyPress, ...
    'KeyReleaseFcn', @handleWindowKeyRelease);

% Set up the grid layout
grid = uigridlayout(fig, [6, 5], 'BackgroundColor', 'w');
grid.RowHeight = {'1x', 50};
grid.ColumnWidth = {'1x', 150};

% Create axes in the top-left corner of the grid layout
ax = uiaxes(grid, ...
    'NextPlot', 'add', ...
    'XColor','none',...
    'YColor','none');
ax.Layout.Row = [2 6];
ax.Layout.Column = [1 4];

% Display the first image using an image handle
sliceIndex = 1;
currentImageData = imread(fullfile(imageFiles(sliceIndex).folder, imageFiles(sliceIndex).name));
imageHandle = image(ax, 'CData', currentImageData);
axis(ax, 'image');
title(ax, sprintf('Slice %d', sliceIndex + 104));


% Prepare scatter points and text handles
scatterPoints = gobjects(options.NumChannels, 1);
textHandles = gobjects(options.NumChannels, 1);

for iCh = 1:options.NumChannels
    scatterPoints(iCh) = line(ax, nan, nan, ...
        'Marker', 'o', ...
        'MarkerFaceColor', cdata(iCh,:),  ...
        'MarkerEdgeColor', 'none', ...
        'MarkerSize', options.MarkerSize, ...
        'MarkerIndices', 1, ...
        'HitTest','off',...
        'UserData', iCh, ...
        'PickableParts','none');
    textHandles(iCh) = text(ax, nan, nan, sprintf("CH-%d | UNI-%d", iCh, chMap(iCh)), ...
        'FontName', 'Consolas', ...
        'FontSize', 10, ...
        'FontWeight', 'bold', ...
        'HorizontalAlignment', 'left', ...
        'Color', cdata(iCh,:), ...
        'HitTest','off', ...
        'PickableParts','none');
end

progAx = uiaxes(grid, ...
    'NextPlot', 'add', ...
    'XLim',[0 options.NumChannels], ...
    'YLim',[0 1], ...
    'XColor','none',...
    'YColor','none',...
    'YDir', 'normal', ...
    'CLim', [0 options.NumChannels], ...
    'Colormap', [0 0 0; cdata]);
progAx.Layout.Row = 1;
progAx.Layout.Column = [1 5];
progBar = imagesc(progAx, ...
    [0 options.NumChannels],[0 1],zeros(1,options.NumChannels), ...
    'ButtonDownFcn', @onProgBarClick);
for iCh = 1:options.NumChannels
    text(progAx,iCh - 1, 0.5,num2str(iCh),...
        'FontSize',6,'FontWeight','bold','FontName','Consolas','Color','k', ...
        'HorizontalAlignment','left','HitTest','off', ...
        'PickableParts','none');
end

% Create a table to store the annotations
annotationTable = table(...
    'Size', [options.NumChannels, 5], ...
    'VariableTypes', {'double', 'double', 'double', 'double', 'double'}, ...
    'VariableNames', {'Original', 'Mapped', 'Slice', 'X', 'Y'});

% Channel Spinner UI control in the top-right corner of the grid layout
lblChannel = uilabel(grid, 'Text', 'Channel', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'bottom', ...
    'FontWeight', 'bold', ...
    'FontName', 'Tahoma', ...
    'FontSize', 16, ...
    'FontColor', 'k');
lblChannel.Layout.Row = 2;
lblChannel.Layout.Column = 5;

channelSpinner = uispinner(grid, ...
    'Limits', [1 options.NumChannels], ...
    'Value', 1, ...
    'FontName', 'Tahoma', ...
    'FontSize', 14, ...
    'HorizontalAlignment', 'center');
channelSpinner.Layout.Row = 3;
channelSpinner.Layout.Column = 5;
lastModified = [];
lastX = [];
lastY = [];
lastSlice = [];

% Save Button in the bottom-right corner of the grid layout
btnSave = uibutton(grid, 'Text', ...
    'Save', ...
    'FontName', 'Consolas', ...
    'FontWeight', 'bold', ...
    'FontColor', 'k', ...
    'BackgroundColor', [0.65 0.65 0.65], ...
    'ButtonPushedFcn', @saveAnnotations);
btnSave.Layout.Row = 6;
btnSave.Layout.Column = 5;

% Variable to keep track of the arc drawing state
arcState = struct('active', false, 'clickCount', 0, 'points', zeros(2, 3), 'h', gobjects(3,1));
for ii = 1:3
    arcState.h(ii) = line(ax,nan,nan,'Color','m','Marker','+','MarkerSize',16,'LineWidth',1,'MarkerIndices',1);
end

% Set up a callback for mouse clicks on the image
set(imageHandle, 'ButtonDownFcn', @onImageClick);
    
    function onProgBarClick(~,event)
        channel = ceil(event.IntersectionPoint(1));
        channelSpinner.Value = channel;
    end

    function onImageClick(~, event)
        % Get the current channel
        channel = channelSpinner.Value;

        if strcmp(get(fig, 'CurrentModifier'), 'shift')
            if ~arcState.active
                % Start arc drawing
                arcState.active = true;
                arcState.clickCount = 1;
                arcState.points(:, 1) = event.IntersectionPoint(1:2)';
                set(arcState.h(1),'XData',event.IntersectionPoint(1),'YData',event.IntersectionPoint(2));
                disp('Click to set the arc endpoint.');
                fig.Pointer = "crosshair";
            elseif arcState.clickCount == 1
                % Set arc endpoint
                arcState.clickCount = 2;
                arcState.points(:, 2) = event.IntersectionPoint(1:2)';
                set(arcState.h(2),'XData',event.IntersectionPoint(1),'YData',event.IntersectionPoint(2));
                disp('Click to set the control point.');
            elseif arcState.clickCount == 2
                % Set control point and finalize arc
                arcState.points(:, 3) = event.IntersectionPoint(1:2)';
                set(arcState.h(3),'XData',event.IntersectionPoint(1),'YData',event.IntersectionPoint(2));
                drawnow();
                drawArc(channel);
                arcState.active = false;
                arcState.clickCount = 0;
                fig.Pointer = "arrow";
                for iPt = 1:numel(arcState.h)
                    set(arcState.h(iPt),'XData',nan,'YData',nan);
                end
            end
        else
            arcState.clickCount = 0;
            arcState.active = false;
            for iPt = 1:numel(arcState.h)
                set(arcState.h(iPt),'XData',nan,'YData',nan);
            end
            fig.Pointer = "arrow";
            % Get the click position
            clickPos = round(event.IntersectionPoint(1:2));
    
            % Add the annotation to the table
            newRow = {channel, chMap(channel), sliceIndex + sliceIndexingOffset, clickPos(1), clickPos(2)};
            lastSlice = annotationTable.Slice(channel);
            lastX = annotationTable.X(channel);
            lastY = annotationTable.Y(channel);
            annotationTable(channel,:) = newRow;
    
            % Update the display
            scatterPoints(channel).XData = clickPos(1);
            scatterPoints(channel).YData = clickPos(2);
            textHandles(channel).Position = [clickPos(1)+20, clickPos(2)];
    
            progBar.CData(1,channel) = channel;
            lastModified = channel;
            channelSpinner.Value = mod(channelSpinner.Value, options.NumChannels) + 1;
        end
    end

    function handleWindowKeyRelease(~, event)
        switch event.Key
            case 'shift'
                fig.Pointer = 'arrow';
        end
    end

    function handleWindowKeyPress(~, event)
        % Update the slice index based on the arrow key pressed
        % disp(event);
        switch event.Key
            case 'shift'
                fig.Pointer = 'crosshair';
                return;
            case {'uparrow','w'}
                sliceIndex = min(sliceIndex + 1, numel(imageFiles));
            case {'downarrow','s'}
                sliceIndex = max(sliceIndex - 1, 1);
            case {'rightarrow', 'd'}
                channelSpinner.Value = mod(channelSpinner.Value,options.NumChannels)+1;
            case {'leftarrow','a'}
                channelSpinner.Value = mod(channelSpinner.Value-2,options.NumChannels)+1;
            case 'z'
                if ismember('control',event.Modifier) && (~isempty(lastModified)) % UNDO
                    for iUndo = 1:numel(lastModified)
                        channel = lastModified(iUndo);
                        newRow = {channel, chMap(channel), lastSlice(iUndo), lastX(iUndo), lastY(iUndo)};
                        if lastSlice(iUndo) == 0
                            progBar.CData(channel) = 0;
                        end
                        annotationTable(channel,:) = newRow;
                    end
                    lastModified = [];
                    lastX = [];
                    lastY = [];
                    lastSlice = [];
                    % disp('Undo');
                end
            otherwise
                return;
        end

        refreshMainDisplay();
    end

    function drawArc(startChannel)
        % Calculate the arc points
        t = linspace(0, 1, options.NumChannelsPerArc);
        arcX = (1-t).^2 * arcState.points(1,1) + 2*(1-t).*t * arcState.points(1,3) + t.^2 * arcState.points(1,2);
        arcY = (1-t).^2 * arcState.points(2,1) + 2*(1-t).*t * arcState.points(2,3) + t.^2 * arcState.points(2,2);
        
        lastSlice = nan(1,options.NumChannelsPerArc);
        lastX = nan(1,options.NumChannelsPerArc);
        lastY = nan(1,options.NumChannelsPerArc);

        % Annotate each channel along the arc
        for i = 1:options.NumChannelsPerArc
            channel = startChannel + i - 1;
            if channel > options.NumChannels
                break;
            end
            newRow = {channel, chMap(channel), sliceIndex + sliceIndexingOffset, round(arcX(i)), round(arcY(i))};
            lastSlice(i) = annotationTable.Slice(channel);
            lastX(i) = annotationTable.X(channel);
            lastY(i) = annotationTable.Y(channel);
            annotationTable(channel,:) = newRow;

            % Update the display
            scatterPoints(channel).XData = round(arcX(i));
            scatterPoints(channel).YData = round(arcY(i));
            textHandles(channel).Position = [round(arcX(i)), round(arcY(i))];
            progBar.CData(channel) = channel;
        end
        lastModified = startChannel:(startChannel+options.NumChannelsPerArc-1);
    end

    function refreshMainDisplay()
        % Update the displayed image data without reloading the image
        currentImageData = imread(fullfile(imageFiles(sliceIndex).folder, imageFiles(sliceIndex).name));
        imageHandle.CData = currentImageData;
        title(ax, sprintf('Slice %d', sliceIndex + sliceIndexingOffset));

        % Update scatter points and text handles
        for i = 1:height(annotationTable)
            if annotationTable.Original(i) > 0
                if annotationTable.Slice(i) == sliceIndex + sliceIndexingOffset
                    scatterPoints(annotationTable.Original(i)).XData = annotationTable.X(i);
                    scatterPoints(annotationTable.Original(i)).YData = annotationTable.Y(i);
                    textHandles(annotationTable.Original(i)).Position = [annotationTable.X(i), annotationTable.Y(i)];
                else
                    % disp(annotationTable(i,:));
                    scatterPoints(annotationTable.Original(i)).XData = nan;
                    scatterPoints(annotationTable.Original(i)).YData = nan;
                    textHandles(annotationTable.Original(i)).Position = [nan, nan];
                end
            end
        end
    end

    function saveAnnotations(~, ~)
        [file, path] = uiputfile(fullfile(folderPath,options.ConfigOut), ...
            'Save Annotations As');
        if file
            writetable(annotationTable, fullfile(path, file));
        end
    end

end
