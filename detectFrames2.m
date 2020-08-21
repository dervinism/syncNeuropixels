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

fid = fopen(dataFilename, 'r');

d = dir(dataFilename);
nSampsTotal = d.bytes/nChans/2;
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
[peaks, frameInd] = findpeaks(single(eyeData), 'MinPeakWidth',5);
frameTimes = t(frameInd);

% Plot the data
figure; plot(t, eyeData,'r')
hold on
plot(frameTimes(1:end), peaks, '.g', 'MarkerSize',20)
hold off