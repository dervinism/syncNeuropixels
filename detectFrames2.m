function [frameTimes, frameInd] = detectFrames2(dataFilename, nChans, sr)
% Function finds the times and indices of every consecutive peak in the
% voltage data recorded in an extra Open Ephys channel. These peaks
% correspond to the eye-tracker video frame refresh instances.
% Input: dataFilename - a string with the name of the data file (in dat or
%                       bin formats).
%        nChans - a total number of channels in the recording. The voltage
%                 channel is supposed to be the last one.
%        sr - a sampling rate.
% Output: frameTimes and frameInd.

chunkSize = 1000000;

try
  fid = fopen(dataFilename, 'r');
  d = dir(dataFilename);
  nSampsTotal = d.bytes/nChans/2;
catch
  fid = fopen([dataFilename(1:end-3) 'dat'], 'r');
  d = dir([dataFilename(1:end-3) 'dat']);
  nSampsTotal = d.bytes/nChans/2;
end

nChunksTotal = ceil(nSampsTotal/chunkSize);

% Load voltage data
chunkInd = 1;
eyeData = [];
while 1
  fprintf(1, 'chunk %d/%d\n', chunkInd, nChunksTotal);
  dat = fread(fid, [nChans chunkSize], '*int16');
  if ~isempty(dat)
    eyeData = [eyeData dat(end,:)]; %#ok<AGROW>
  else
    break
  end  
  chunkInd = chunkInd+1;
end

% Detect frame times
t = 1/sr:1/sr:numel(eyeData)/sr;
eyeDataLogical = eyeData;
eyeDataLogical(eyeDataLogical <= 10) = -1;
eyeDataLogical(eyeDataLogical > 0) = 1;
eyeDataLogical(eyeDataLogical < 0) = 0;
[~, frameIndInit] = findpeaks(single(eyeDataLogical));
eyeDataLogical(frameIndInit-1) = 0;
eyeDataLogical(frameIndInit) = 0;
eyeDataLogical(frameIndInit+1) = 0;
[~, frameInd] = findpeaks(single(eyeDataLogical));
frameInd = frameInd-2;
peaks = eyeData(frameInd);
frameTimes = t(frameInd);

% Test agreement with the old method
% [~, frameInd2] = findpeaks(single(eyeData), 'MinPeakWidth',5);
% assert(numel(frameInd) == numel(frameInd2))

% Plot the data
figure; plot(t, eyeData,'r')
hold on
plot(frameTimes(1:end), peaks, '.g', 'MarkerSize',20)
hold off