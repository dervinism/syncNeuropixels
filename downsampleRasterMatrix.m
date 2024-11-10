function [downsampledMat, downsampledTime] = downsampleRasterMatrix(rasterMat, srOriginal, srNew)
% [downsampledMat, downsampledTime] = downsampleRasterMatrix(rasterMat, srOriginal, srNew)
%
% Function downsamples a raster matrix where rows correspond to neurons and
% columns to time.
% Input: rasterMat - the original raster matrix.
%        srOriginal - original sampling rate in Hz.
%        srNew - new sampling rate in Hz.
% Output: downsampledMat - a new downsampled raster matrix with rows
%         corresponding to neurons and columns to new downsampled time.
%         downsampledTime - the downsampled time.
%
% Example: [downsampledMat, downsampledTime] = downsampleRasterMatrix(rasterMat, 400, 0.2)
%          would take a raster matrix sampled at 400 Hz and return a new
%          raster matrix resampled at 0.2 Hz (once every 5 seconds).

try
  durationNew = ceil(size(rasterMat,2)/(srOriginal/srNew));
  rasterHist = reshape(rasterMat(:,round(1:durationNew*(srOriginal/srNew)))',round([(srOriginal/srNew) durationNew size(rasterMat,1)]));
catch
  durationNew = floor(size(rasterMat,2)/(srOriginal/srNew));
  rasterHist = reshape(rasterMat(:,round(1:durationNew*(srOriginal/srNew)))',round([(srOriginal/srNew) durationNew size(rasterMat,1)]));
end
downsampledMat = squeeze(sum(rasterHist,1))';
downsampledTime = (1:durationNew).*(1/srNew);