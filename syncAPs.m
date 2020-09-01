function transformedRaster = syncAPs(raster, dt, tFunc)
% transformedRaster = syncAPs(raster, dt, tFunc)
%
% Function linearly transforms a raster vector so that
%
%   tranformed spike times = tFunc.a + tFunc.b * original spike times
%
% Input: raster - a spike count vector or a matrix. Matrix rows should
%          correspond to individual spike count vectors.
%        dt - sampling step size.
%        tFunc - a structure variable with linear function coefficients a
%          and b (y = a + b*x).
%
% Output: transformedRaster - a transformed spike count vector or matrix.

if isempty(raster) || (tFunc.a == 0 && tFunc.b == 1)
  transformedRaster = raster;
  return
end

originalInds = 1:size(raster,2);
originalTime = originalInds.*dt;

transformedTime = tFunc.a + tFunc.b*originalTime;
transformedInds = round(transformedTime./dt);

raster = raster(:,transformedInds > 0);
originalInds = originalInds(transformedInds > 0);
transformedInds = transformedInds(transformedInds > 0);
if transformedInds(1) > 1
  raster = [zeros(size(1:transformedInds(1)-1)) raster];
  originalInds = [1:transformedInds(1)-1 originalInds+transformedInds(1)-1];
  transformedInds = [1:transformedInds(1)-1 transformedInds];
end

if transformedInds(end) < originalInds(end) % Contract the vector
  uniqueLogical = zeros(size(originalInds));
  [~, uniqueInds] = unique(transformedInds);
  uniqueLogical(uniqueInds) = 1;
  if size(raster,1) > 1
    nonuniqueInds = originalInds(~logical(uniqueLogical));
  elseif size(raster,1) == 1
    nonuniqueInds = originalInds(~logical(uniqueLogical) & logical(raster));
  else
    nonuniqueInds = [];
  end
  
  transformedRaster = raster(:,logical(uniqueLogical));
  if ~isempty(nonuniqueInds)
    for i = 1:numel(nonuniqueInds)
      transformedRaster(:,transformedInds(nonuniqueInds(i))) = transformedRaster(:,transformedInds(nonuniqueInds(i))) + raster(:,nonuniqueInds(i));
    end
  end
elseif transformedInds(end) > originalInds(end) % Expand the vector
  transformedRaster = zeros(size(raster,1), size(transformedInds(1):transformedInds(end)));
  transformedRaster(:,transformedInds-transformedInds(1)+1) = raster;
else
  transformedRaster = raster;
end