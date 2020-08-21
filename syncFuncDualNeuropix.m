function [syncFunc_1to2, syncFunc_2to1] = syncFuncDualNeuropix(dataFilename1, dataFilename2, chN1, chN2, sr, opt)
% [syncFunc_1to2, syncFunc_2to1] = syncFuncDualNeuropix(dataFilename1, dataFilename2, chN1, chN2, sr, opt)
%
% Function estimates synchronisation functions for dual Neuropixels probes.
% Input: dataFilename1 - full path to probe 1 recording binary file.
%        dataFilename2 - full path to probe 2 recording binary file. If
%                        this variable is supplied empty, the function will
%                        simply carry out frame time detection only. This
%                        mode can be used to carry out frame time detection
%                        and update the pupil/total movement data with this
%                        info.
%        cbN1 - number of channels in the probe 1 recording.
%        cbN2 - number of channels in the probe 2 recording.
%        sr - sampling rate.
%        opt - a structure variable with the following fields:
%          updatePupilData - determines whether and how to update the pupil
%            data file with frame time information. Default string value is
%            'no'. If chosen 'larger', will update with frame times
%            estimated on the basis of the probe recording file with a
%            larger sampling rate. If chosen 'smaller', will update with
%            frame times estimated on the basis of the probe recording file
%            with a smaller sampling rate.
%          pupilDataFile - full path to the pupil data file.
%          updateMovementData - equivalent to updatePupilData but for the
%            total movement data instead.
%          movementDataFile - full path to the total movement data file.
%          dataCrop - determine whether and how to crop pupil/total
%            movement data in the case where the pupil/total movement data
%            is longer than the detected frame time data based on probe
%            recordings. This happens when the pupil camera continues
%            recording after electrophysiology recording has been stopped
%            or if it starts recording prior to electrophysiology recording
%            being initiated. The default option string value is 'no'. If
%            chosen 'start', will crop the initial part of the data. If
%            chosen 'end', will crop the end part of the pupil/ total
%            movement data.
% Output: syncFunc_1to2 - a linear transformation function from detected
%           frame times based on dataFilename1 to detected frame times
%           based on dataFilename2. It takes the following form:
%             frame times 1 = a + b * frame times 2
%           In line with this expression, syncFunc_1to2 is a structure with
%           scalar fields a and b.
%         syncFunc_2to1 is equivalent to syncFunc_1to2 but in the opposite
%           direction.

%% Check input variables
if nargin < 6 || ~isfield(opt, 'updatePupilData')
  opt.updatePupilData = 'no';
elseif ~strcmp(opt.updatePupilData, 'larger') && ~strcmp(opt.updatePupilData, 'smaller') && ~strcmp(opt.updatePupilData, 'no')
  error('The opt.updatePupilData field value is not set correctly. Acceptable string values are the following: larger, smaller, or no.')
end

if ~isfield(opt, 'updateMovementData')
  opt.updateMovementData = 'no';
elseif ~strcmp(opt.updateMovementData, 'larger') && ~strcmp(opt.updateMovementData, 'smaller') && ~strcmp(opt.updateMovementData, 'no')
  error('The opt.updateMovementData field value is not set correctly. Acceptable string values are the following: larger, smaller, or no.')
end

if ~isfield(opt, 'dataCrop')
  opt.dataCrop = 'no';
elseif ~strcmp(opt.dataCrop, 'start') && ~strcmp(opt.dataCrop, 'end') && ~strcmp(opt.dataCrop, 'no')
  error('The opt.dataCrop field value is not set correctly. Acceptable string values are the following: start, end, or no.')
end


%% Detect frames
[frameTimes1, frameInd1] = detectFrames2(dataFilename1, chN1, sr);
if ~isempty(dataFilename2)
  [frameTimes2, frameInd2] = detectFrames2(dataFilename2, chN2, sr);
else
  frameTimes2 = frameTimes1;
  frameInd2 = frameInd1;
end
if strcmp(opt.dataCrop, 'end')
  if numel(frameTimes1) - numel(frameTimes2) == 1
    frameTimes1(end) = [];
    frameInd1(end) = [];
  elseif numel(frameTimes2) - numel(frameTimes1) == 1
    frameTimes2(end) = [];
    frameInd2(end) = [];
  end
elseif strcmp(opt.dataCrop, 'start')
  if numel(frameTimes1) - numel(frameTimes2) == 1
    frameTimes1(1) = [];
    frameInd1(1) = [];
  elseif numel(frameTimes2) - numel(frameTimes1) == 1
    frameTimes2(1) = [];
    frameInd2(1) = [];
  end
end
assert(numel(frameTimes1) == numel(frameTimes2));


%% Determine synchronisation functions
duration1 = frameTimes1(end) - frameTimes1(1);
duration2 = frameTimes2(end) - frameTimes2(1);
a_1to2 = frameTimes2(1) - frameTimes1(1);
a_2to1 = frameTimes1(1) - frameTimes2(1);
b_1to2 = duration2/duration1;
b_2to1 = duration1/duration2;
syncFunc_1to2.a = a_1to2;
syncFunc_1to2.b = b_1to2;
syncFunc_2to1.a = a_2to1;
syncFunc_2to1.b = b_2to1;


%% Update pupil data
if ~strcmp(opt.updatePupilData, 'no') && ~isempty(opt.pupilDataFile)
  load(opt.pupilDataFile); % load pupil data
  
  % Update pupil data with frame time info
  if strcmp(opt.updatePupilData, 'larger')
    if duration1 >= duration2
      results.frameTimes = frameTimes1';
      results.frameInd = frameInd1';
    elseif duration1 < duration2
      results.frameTimes = frameTimes2';
      results.frameInd = frameInd2';
    end
  elseif strcmp(opt.updatePupilData, 'smaller')
    if duration1 >= duration2
      results.frameTimes = frameTimes2';
      results.frameInd = frameInd2';
    elseif duration1 < duration2
      results.frameTimes = frameTimes1';
      results.frameInd = frameInd1';
    end
  end
  
  % Deal with unequal lengths
  if ~strcmp(opt.dataCrop, 'no')
    if strcmp(opt.dataCrop, 'end')
      inds = 1:numel(results.frameTimes);
    elseif strcmp(opt.dataCrop, 'start')
      inds = numel(results.area)-numel(results.frameTimes)+1:numel(results.area);
    end
    results.x = results.x(inds);
    results.y = results.y(inds);
    results.aAxis = results.aAxis(inds);
    results.bAxis = results.bAxis(inds);
    results.abAxis = results.abAxis(inds);
    results.area = abs(results.area(inds));
    results.goodFit = results.goodFit(inds);
    results.blink = results.blink(inds);
    results.saturation = results.saturation(inds);
    results.threshold = results.threshold(inds);
    results.roi = results.roi(inds,:);
    results.equation = results.equation(inds);
    results.xxContour = results.xxContour(inds);
    results.yyContour = results.yyContour(inds);
    results.blink = results.blink(inds);
    results.blinkRho = results.blinkRho(inds);
  end
  
  % Save the updated file
  save(opt.pupilDataFile, 'results','state'); %#ok<*USENS>
end


%% Update movement data
if ~strcmp(opt.updateMovementData, 'no') && ~isempty(opt.movementDataFile)
  load(opt.movementDataFile); % load movement data
  
  % Update movement data with frame time info
  if strcmp(opt.updateMovementData, 'larger')
    if duration1 >= duration2
      frameTimes = frameTimes1;
      frameInd = frameInd1;
    elseif duration1 < duration2
      frameTimes = frameTimes2;
      frameInd = frameInd2;
    end
  elseif strcmp(opt.updateMovementData, 'smaller')
    if duration1 >= duration2
      frameTimes = frameTimes2;
      frameInd = frameInd2;
    elseif duration1 < duration2
      frameTimes = frameTimes1;
      frameInd = frameInd1;
    end
  end
  
  % Deal with unequal lengths
  if ~strcmp(opt.dataCrop, 'no')
    if strcmp(opt.dataCrop, 'end')
      inds = 1:numel(frameTimes);
    elseif strcmp(opt.dataCrop, 'start')
      inds = numel(s)-numel(frameTimes)+1:numel(s);
    end
    s = s(inds);
    sa = sa(inds); %#ok<*NODEF>
  end
  
  % Save the updated file
  save(opt.movementDataFile, 's','sa','frameTimes','frameInd');
end