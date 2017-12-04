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

%T__k_1__0 = vect2Htrans([1.3563 0.6305 1.6380 -1.5523   -1.5092    0.8382]');
%Tmat = zeros(3,797);

%% Initialization
%load ../../data/flow.mat
%load ../../data/data.mat
vT__k__k_1 = zeros(6,1) + 1e-15;
tmat = zeros(6,797);
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
    grayCurr = [];% data{1}(:,:,i);
    depCurr = data{1}(:,:,i);
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
    %{
    T__k__k_1 = vect2Htrans(vT__k__k_1);
    T__0__k = T__k_1__0^(-1) * T__k__k_1^(-1);
    vT__0__k = Htrans2Vect(T__0__k);
    Tmat(:,i) = vT__0__k(1:3);
    %}
    %t = theta2rot(vT__k__k_1(4:6))*xPrev' + vT__k__k_1(1:3);
    %t = t';
    tmat(:,i) = vT__k__k_1;
    
    % find reproject error
    t = theta2rot(vT__k__k_1(4:6))*xPrev' + vT__k__k_1(1:3);
    xPixel = K*t;
    temp = xPixel(1,:);
    xPixel(1,:) = xPixel(2,:);
    xPixel(2,:) = temp;
    xPixel =  ( xPixel(1:2,:)./xPixel(3,:) )';
    error = xPixel - featureCurrent(:,1:2);
    reproError = [reproError, sum(sqrt(sum(error.^2,2)))/size(featureCurrent,1)];
    
    fprintf('Error: %f\n',resnorm);
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
deltaPosGT = [tx,ty,tz,qw,qx,qy,qz];
poseGT = cameraPosQuat([0,0,0],deltaPosGT);
% plot groundtruth
plot3(poseGT(:,1),poseGT(:,2),poseGT(:,3),'g.');
%}	
% deal with estimated result
formResult();
posET = cameraPos([0,0,0],deltaPosT);
plot3(posET(:,1),posET(:,2),posET(:,3));