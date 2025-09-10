function phat = fitTruncGamma(data)

data(data==0) = [];
phatOri = gamfit(data);

phat0 = phatOri;
truncThr0 = max(data)*2;
truncThr = max(data);

tol = quantile(data,0.99)*0.01;

while (truncThr0 - truncThr) > tol
    truncThr0 = truncThr;
    
    truncThr = gaminv(1-0.05, phat0(1), phat0(2));
    truncedVec = data(data <= truncThr);   
    pdf_truncgamma = @(x,a,b) gampdf(x,a,b) ./ gamcdf(truncThr,a,b);
    phat = mleNewtonMethod(pdf_truncgamma, truncedVec, phat0);
    phat0 = phat;
end