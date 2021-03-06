 %% Main code structure for 16720 project, Fall 2017
%{
TODO LIST: 
	debug Frame to frame motion estimation
	Implement BA
	Save/Compare results from FTF, BA, groudtruth
%}
%% global parameters
maxFeatNum = 100; % The maximum number of features to keep in one frame
minFeatNum = 50; % The minimum number of features to keep in one frame
distribute = [32,32]; % How should the uniform grid form for feature extraction
global features;
global C_nodepth;
global C_depth_x;
global C_depth_y;

C_nodepth = 0.001;%0.5;%0.7;%0.1;
C_depth_x = 1.2;%2.2;%3;%1.2;%0.3;
C_depth_y = 1.2;
%
fx = 525.0;  % focal length x
fy = 525.0;  % focal length y
cx = 319.5;  % optical center x
cy = 239.5;  % optical center y
K = [fx,0,cx;0,fy,cy;0,0,1];
%}
%{
fx = 481.20;  % focal length x
fy = -480.00;  % focal length y
cx = 319.5;  % optical center x
cy = 239.5;  % optical center y
K = [fx,0,cx;0,fy,cy;0,0,1];
%}
%T__k_1__0 = vect2Htrans([1.3563 0.6305 1.6380 -1.5523   -1.5092    0.8382]');
%Tmat = zeros(3,797);

%% Initialization
load ../../data/flow.mat
load ../../data/data.mat
%data = loadData('../../data/subset','../../data/subset');
%flow = loadFlow('../../data/subset');
vT__k__k_1 = zeros(6,1) + 1e-15;
tmat = zeros(6,798);
totalStamp = size(data{1},3);
[featurePrev, k] = featureExtraction(data{1}(:,:,1), data{2}(:,:,1), maxFeatNum, distribute);

%% Frame to Frame
% main loop
deltaPosT = [];
reproError = [];
for i = 2:totalStamp
    % add in data
    grayPrev = [];% data{1}(:,:,i-1);
    depPrev = [];% data{2}(:,:,i-1);
    grayCurr = [];% data{1}(:,:,i)
    depCurr = data{2}(:,:,i);
    flowmap = flow{i-1};
    % optical Flow to track the feature to current frame
    [featurePrev, featureCurrent, k] = featurePrep(featurePrev, k, flowmap, ...
        grayPrev, depPrev, grayCurr, depCurr);
    % transfer to 3D world coordinates
    [xPrev, xCurrent] = transferToWorldCoord(featurePrev, featureCurrent);
    xbk_1 = xPrev(:,1:2)./xPrev(:,3);
    temp1 = ones(size(xPrev,1),1);
    temp0 = zeros(size(xPrev,1),1);
    temp0(1:k,1) = 1;
    features = [temp1, xbk_1, temp0, xPrev, xCurrent(:,1:2)];
    % motion estimation 
    reprojectFn = @(x) reprojectionFn(x);
    options = optimset('Jacobian','on');
    options.Algorithm = 'levenberg-marquardt';
    [vT__k__k_1, resnorm,residual,exitflag,output,lambda,jacobian] = lsqnonlin('reprojectionFn',vT__k__k_1, [], [], options);
    tmat(:,i) = vT__k__k_1;    
    fprintf('Error: %f\n',resnorm);
    % find reproject error
    t = theta2rot(vT__k__k_1(4:6))*xPrev' + vT__k__k_1(1:3);
    xPixel = K*t;
    temp = xPixel(1,:);
    xPixel(1,:) = xPixel(2,:);
    xPixel(2,:) = temp;
    xPixel =  ( xPixel(1:2,:)./xPixel(3,:) )';
    error = xPixel - featureCurrent(:,1:2);
    reproError = [reproError, sum(sqrt(sum(error.^2,2)))/size(featureCurrent,1)];
    % update previous feature vector
    if size(featureCurrent,1) <= minFeatNum
        % or directly re-extract all features, which should be better
        [featureCurrent, k] = featureExtraction(data{1}(:,:,i), ...
            data{2}(:,:,i), maxFeatNum, distribute);
    end
    featurePrev = featureCurrent;
    depPrev = depCurr;
end
   
%% Save and visualization
%loadGT();
load('ground_truth.mat');
gt = [tx,ty,tz,qw,qx,qy,qz]';
[poses,posesGT] = findWorldPoseVect(tmat, gt);
% plot groundtruth
figure
hold on
plot3(posesGT(1,:),posesGT(2,:),posesGT(3,:),'g');
plot3(poses(1,:),poses(2,:),poses(3,:),'r');
%}	
% deal with estimated result
resu = formResult(tmat);
generate_txt(resu(2:end,1:3),resu(2:end,4:7));
%}