function [zscore, z_debias, sigma] = ordStats(fg, fg_neighbors, nanVec, OrSt)

M = max(length(fg), 10);
N = max(length(fg_neighbors), 10);
if isfield(OrSt, 'fgTestWay')
    wayChoice = OrSt.fgTestWay;
else
    wayChoice = ' ';
end
zscore_get = false;
z_debias = 0;
curVar = var(fg_neighbors);      % 20250401
%% way 1: use t-test
if strcmp(wayChoice, 'ttest')
    [~, ~,~,t] = ttest2(fg_neighbors, fg);
    zscore = -t.tstat;
    zscore_get = true;
elseif strcmp(wayChoice, 'ttest_varKnown')
    sum_st = mean(fg) - mean(fg_neighbors);
    n = length(fg);
    m = length(fg_neighbors);
    sigma = sqrt(curVar*(n+m)/(n*m));
    zscore = sum_st / sigma;
    z_debias = sum_st;
    zscore_get = true;
elseif strcmp(wayChoice, 'sTruncNormal')
    %% way 2: use simple truncated Gaussian
    lower_fg = norminv(1-M/(M+N));
    [f_mu, f_sigma] = truncatedGauss(0, 1, lower_fg, inf);
    f_sigma = f_sigma/sqrt(M);
    
    upper_nei = lower_fg;
    [n_mu, n_sigma] = truncatedGauss(0, 1, -inf, upper_nei);
    n_sigma = n_sigma/sqrt(N);
    
    mu = f_mu - n_mu;
    sigma = sqrt(f_sigma^2 + n_sigma^2);
elseif strcmp(wayChoice, 'Integral')
    %% way 3: use integral
    [mu, sigma] = conventionalIntegralv1(fg_neighbors, fg);
elseif strcmp(wayChoice, 'ovTruncNormal')
    %% way 4: use truncated Gaussian with ratio
    all_v = cat(1, fg, fg_neighbors);
    labels = cat(1, ones(M, 1), 2*ones(N, 1));
    [~, od_v] = sort(all_v, 'descend');
    labels = labels(od_v);
    ratio_v = (1:length(labels))'./length(labels);
    fg_ratio = mean(ratio_v(labels==1));
    lower_fg = -norminv(2*fg_ratio);
    [f_mu, f_sigma] = truncatedGauss(0, 1, lower_fg, inf);
    f_sigma = f_sigma/sqrt(M);
    
    nei_ratio = 2*(1-mean(ratio_v(labels==2)));
    upper_nei = norminv(nei_ratio);
    [n_mu, n_sigma] = truncatedGauss(0, 1, -inf, upper_nei);
    n_sigma = n_sigma/sqrt(N);
    
    mu = f_mu - n_mu;
    sigma = sqrt(f_sigma^2 + n_sigma^2);
elseif strcmp(wayChoice, 'lookupTable')
    %% way 5: look up table
    [h1, h2] = size(OrSt.NoStbMu);
    if (M>=h1 || N>=h2)
        sigmaScl = sqrt((M+N)/500);
        M1 = floor(M/(M+N)*500);
        N1 = floor(N/(M+N)*500);
        mu = OrSt.NoStbMu(M1, N1);
        sigma = OrSt.NoStbSig(M1, N1);
        sigma = sigma/sigmaScl;
    else
        mu = OrSt.NoStbMu(M, N);
        sigma = OrSt.NoStbSig(M, N);
    end
elseif strcmp(wayChoice, '3SecApprox')
    [order_vec,a,b] = order_info(fg, fg_neighbors);
    [mu, sigma] = ordStatApprox3sec(fg,fg_neighbors,order_vec,a,b);
elseif strcmp(wayChoice, 'KSecApprox')
    %[mu, sigma] = ordStatApproxKsec(fg,fg_neighbors);
    %[mu, sigma] = ordStatApproxKsecWith0s(fg,fg_neighbors, nanVec);
    [mu, sigma] = ordStatApproxKsecWith0s_mat(fg,fg_neighbors, nanVec);
else
    %% if we want to compare all 5 methods
    sum_st = mean(fg) - mean(fg_neighbors);
    zscore = nan(1, 5);
    %% way 1: use t-test
    [~, ~,~,t] = ttest2(fg_neighbors, fg);
    zscore(1) = -t.tstat;
    %% way 2: use simple truncated Gaussian
    lower_fg = norminv(1-M/(M+N));
    [f_mu, f_sigma] = truncatedGauss(0, 1, lower_fg, inf);
    f_sigma = f_sigma/sqrt(M);
    
    upper_nei = lower_fg;
    [n_mu, n_sigma] = truncatedGauss(0, 1, -inf, upper_nei);
    n_sigma = n_sigma/sqrt(N);
    
    mu = f_mu - n_mu;
    sigma = sqrt(f_sigma^2 + n_sigma^2);
    zscore(2) = (sum_st - mu*sqrt(curVar))...
        / (sigma*sqrt(curVar));
    %% way 3: use integral
    tic;
    [mu1, sigma] = conventionalIntegralv1(fg_neighbors, fg);
    t1 = toc;
    zscore(3) = (sum_st - mu1*sqrt(curVar))...
        / (sigma*sqrt(curVar));
    %% way 4: use truncated Gaussian with ratio
    all_v = cat(1, fg, fg_neighbors);
    labels = cat(1, ones(M, 1), 2*ones(N, 1));
    [~, od_v] = sort(all_v, 'descend');
    labels = labels(od_v);
    ratio_v = (1:length(labels))'./length(labels);
    fg_ratio = mean(ratio_v(labels==1));
    lower_fg = -norminv(2*fg_ratio);
    [f_mu, f_sigma] = truncatedGauss(0, 1, lower_fg, inf);
    f_sigma = f_sigma/sqrt(M);
    
    nei_ratio = 2*(1-mean(ratio_v(labels==2)));
    upper_nei = norminv(nei_ratio);
    [n_mu, n_sigma] = truncatedGauss(0, 1, -inf, upper_nei);
    n_sigma = n_sigma/sqrt(N);
    
    mu = f_mu - n_mu;
    sigma = sqrt(f_sigma^2 + n_sigma^2);
    zscore(4) = (sum_st - mu*sqrt(curVar))...
        / (sigma*sqrt(curVar));
    %% way 5: look up table
    [h1, h2] = size(OrSt.NoStbMu);
    if (M>=h1 || N>=h2)
        sigmaScl = sqrt((M+N)/500);
        M1 = floor(M/(M+N)*500);
        N1 = floor(N/(M+N)*500);
        mu = OrSt.NoStbMu(M1, N1);
        sigma = OrSt.NoStbSig(M1, N1);
        sigma = sigma/sigmaScl;
    else
        mu = OrSt.NoStbMu(M, N);
        sigma = OrSt.NoStbSig(M, N);
    end
    zscore(5) = (sum_st - mu*sqrt(curVar))...
        / (sigma*sqrt(curVar));
    %% way 6: use simplified integral
    tic;
    [mu, sigma] = ordStatApproxKsec(fg,fg_neighbors);
    t2 = toc;
    disp(t1/t2);
    zscore(6) = (sum_st - mu1*sqrt(curVar))...
        / (sigma*sqrt(curVar));

    zscore_get = true;
end
if ~zscore_get
    %% start cal z-score
    sum_st = mean(fg) - mean(fg_neighbors);
    sigma = sigma*sqrt(curVar);
    z_debias = mu*sqrt(curVar);
    zscore = (sum_st - z_debias) / sigma;
end

