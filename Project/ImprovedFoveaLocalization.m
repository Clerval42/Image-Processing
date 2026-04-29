%% Improved Fovea Localization Algorithm
% Better anatomical constraint-based approach

function foveaCenter = localizeFovea_Improved(I_prep, odCenter, odRadius)
    % Improved fovea localization with better anatomical constraints
    
    [h, w] = size(I_prep);
    
    % Fovea location properties:
    % 1. Located roughly 2.5-3 OD diameters from OD center (usually temporal/nasal)
    % 2. On the main blood vessel-free zone
    % 3. Usually below (higher Y) the OD center
    
    % Create search region ROI:
    % Search within a limited annulus around the OD
    minSearchDist = odRadius * 1.5;  % At least 1.5 disc diameters away
    maxSearchDist = odRadius * 3.5;  % No more than 3.5 disc diameters away
    
    % Create mask for search region
    [X, Y] = meshgrid(1:w, 1:h);
    distFromOD = sqrt((X - odCenter(1)).^2 + (Y - odCenter(2)).^2);
    
    searchMask = (distFromOD >= minSearchDist) & (distFromOD <= maxSearchDist);
    
    % Apply search region
    searchRegion = I_prep;
    searchRegion(~searchMask) = max(I_prep(:));  % Mask out non-search regions (set to bright)
    
    % Find darkest point in search region
    [minVal, minIdx] = min(searchRegion(:));
    [py, px] = ind2sub(size(searchRegion), minIdx);
    
    foveaCenter = [px, py];
    
    % Validate: if fovea is too close to OD, expand search
    foveaDist = sqrt((foveaCenter(1) - odCenter(1))^2 + (foveaCenter(2) - odCenter(2))^2);
    if foveaDist < odRadius * 1.2
        % Too close, search again with different strategy
        % Look in bottom-right quadrant preferentially
        bottomRightMask = (X > odCenter(1)) & (Y > odCenter(2)) & searchMask;
        searchRegion2 = I_prep;
        searchRegion2(~bottomRightMask) = max(I_prep(:));
        [~, minIdx2] = min(searchRegion2(:));
        [py2, px2] = ind2sub(size(searchRegion2), minIdx2);
        foveaCenter = [px2, py2];
    end
end
