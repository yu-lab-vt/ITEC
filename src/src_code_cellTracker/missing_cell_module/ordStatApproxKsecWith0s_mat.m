function [mu, sigma] = ordStatApproxKsecWith0s_mat(fg, bg, nanVec)
% approximate the ~normal distribution using the fg and bg vector
% assuming there is only K parts exist for [0 1]
% A quick version of ordStatApproxKsecWith0s (should be ~100 faster)
if isempty(fg) && isempty(bg)
    mu = nan;
    sigma = nan;
    return;
end
fg = fg(:);
bg = bg(:);
nanVec = nanVec(:);
M = length(fg);
N = length(bg);
nanLen = length(nanVec);
n = M+N+nanLen;

delta = 1/n;
all = cat(1, bg, fg, nanVec);
labels = cat(1, bg*0-1, fg*0+1, nanVec*0);
[~, od] = sort(single(all)); % ascending
labels = labels(od);
bkpts = find(labels(2:end)-labels(1:end-1));

ai = cat(1, labels(bkpts), labels(end));
if M>0
    ai(ai>0) = ai(ai>0)*n/M;
end
if N>0
    ai(ai<0) = ai(ai<0)*(n/N);
end

% bi is start, ti is end of the i-th section
bi = cat(1, 0, bkpts*delta);
ti = cat(1, bkpts*delta, 1);

valid_ai = find(ai~=inf);
ai = ai(valid_ai);

Finvbi = norminv(bi(valid_ai));
if valid_ai(1) == 1
    Finvbi(1) = -1e5;
end
Finvti = norminv(ti(valid_ai));
if valid_ai(end) == length(bi)
    Finvti(end) = 1e5;
end

mu = double(sum(ai.*(normpdf(Finvbi) - normpdf(Finvti))));

% mat implementaion
[f1Finvti, FinvtiNcdf, FinvtiNpdf] = f1(Finvti);
[f1Finvbi, FinvbiNcdf, FinvbiNpdf] = f1(Finvbi);
f1Finvti_f1Finvbi = f1Finvti-f1Finvbi;
aixFinvtj_Finvbj = ai.*(Finvti-Finvbi);
cumsum_aixFinvtj_Finvbj = cumsum(aixFinvtj_Finvbj);
cumsum_aixFinvtj_Finvbj = cumsum_aixFinvtj_Finvbj(end) - cumsum_aixFinvtj_Finvbj;
t1_all = ai.*cumsum_aixFinvtj_Finvbj.*f1Finvti_f1Finvbi;
t1 = sum(t1_all);



t2 = sum(ai.*ai.*Finvti.*f1Finvti_f1Finvbi);
t3 = sum(ai.*ai.*...
    (f2(Finvti, FinvtiNcdf, FinvtiNpdf)-f2(Finvbi, FinvbiNcdf, FinvbiNpdf)));

A = 2*(t1+t2-t3);
B = (sum(ai.*f1Finvti_f1Finvbi))^2;%

sigma = double(sqrt(A-B)/sqrt(n));

end

function [y, xnormcdf, xnormpdf] = f1(x)
    xnormcdf = normcdf(x);
    xnormpdf = normpdf(x);
    y = x.*xnormcdf+xnormpdf;
end

function y = f2(x, xnormcdf, xnormpdf)
    y=0.5*(xnormcdf.*x.^2 - xnormcdf + xnormpdf.*x);
end
