function repo = baFun(x)
% x [6 N] vector form
global fID;
global BAframeNum;

% form H
Hs = cell(1,size(fID,2)-1);
for i = 1:size(Hs,2)
   fNum =  BAframeNum(i+1);
   Hs{i} = vect2Htrans( x(:,1) );
   for j = 2:fNum-1
       Hs{i} = vect2Htrans(x(:,j)) * Hs{i};
   end
end

infnD = [0.001,0   ,0;
            0,0.001,0;
            0,   0,0];
        
nkf = size(fID,2);
nfp = size(fID{1},1);

%repo = [];
repo = 0;
% sum for all key frame
for j = 2:nkf
    H = Hs{j-1};
    % sum for all feature point
    info = infnD;
    for i = 1:nfp
        if fID{j}(i,2) == 1
            info = [0.05,0   ,0;
                    0,0.05,0;
                    0,   0,1/(fID{j}(i,5))^2];
        end
        X_l_telda = [fID{1}(i,3:5)'./fID{1}(i,5);1];
        X_j_telda = [fID{j}(i,3:5)'./fID{j}(i,5);1];
        temp = H*X_l_telda - X_j_telda;
        temp = temp(1:3); % 3x1
        temp = temp' * info * temp;
        %repo = [repo; temp];
        repo = repo + temp;
    end
end

end