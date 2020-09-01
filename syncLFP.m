function transformedLFP = syncLFP(lfp, dt, tFunc)
% transformedLFP = syncLFP(lfp, dt, tFunc)
%
% Function linearly transforms a local field potential (LFP) vector (or any
%   continuous signal vector) so that
%
%   tranformed LFP times = tFunc.a + tFunc.b * original LFP times
%
% Input: lfp - an LFP vector or a matrix. Matrix rows should correspond to
%          individual LFP vectors.
%        dt - sampling step size.
%        tFunc - a structure variable with linear function coefficients a
%          and b (y = a + b*x).
%
% Output: transformedLFP - a transformed LFP vector or matrix.

if isempty(lfp) || (tFunc.a == 0 && tFunc.b == 1)
  transformedLFP = lfp;
  return
end

originalInds = 1:size(lfp,2);
originalTime = originalInds.*dt;

transformedTime = tFunc.a + tFunc.b*originalTime;
transformedInds = round(transformedTime./dt);

lfp = lfp(:,transformedInds > 0);
originalInds = originalInds(transformedInds > 0);
transformedInds = transformedInds(transformedInds > 0);
if transformedInds(1) > 1
  inds2add = 1:transformedInds(1)-1;
  originalInds = [inds2add originalInds+transformedInds(1)-1];
  transformedInds = [inds2add transformedInds];
  lfp2add = repmat(mean(lfp,2),1,numel(inds2add));
  lfp = [lfp2add lfp];
end

if transformedInds(end) < originalInds(end) % Contract the vector
  uniqueLogical = zeros(size(originalInds));
  [~, uniqueInds] = unique(transformedInds);
  uniqueLogical(uniqueInds) = 1;
  transformedLFP = lfp(:,logical(uniqueLogical));
elseif transformedInds(end) > originalInds(end) % Expand the vector
  transformedLFP = zeros(size(lfp,1), size(transformedInds(1):transformedInds(end)));
  transformedLFP(:,transformedInds-transformedInds(1)+1) = lfp;
  transformedLFP = transformedLFP';
  missingInds = find(~logical(transformedLFP));
  if ~isempty(missingInds)
    for i = 1:numel(missingInds)
      transformedLFP(i) = (transformedLFP(i-1) + transformedLFP(i+1))/2;
    end
  end
  transformedLFP = transformedLFP';
else
  transformedLFP = lfp;
end