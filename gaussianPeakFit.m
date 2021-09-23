function [f,transientT,fitX, fitY] = gaussianPeakFit(x, y,Xpk, Wpk,baseline)
GaussianF = @(f) f(1)*exp( -(x-Xpk).^2/(2*(f(2)^2)) )+baseline - y;
f0 = [min(y)-max(y),Wpk/2/1.177];
[f,resnorm,residual]=lsqnonlin(GaussianF,f0, [1.05*(min(y)-baseline),0],...
[0.95*(min(y)-baseline),inf]);
% [f,resnorm,residual]=lsqnonlin(GaussianF,f0);
% FWHM=1.177*f(2)*2;
fitXmin = min(x);
fitXmax = max(x);
step = (fitXmax - fitXmin)/500;
x01 = sqrt(2*f(2)^2*log(10))+Xpk;
x09 = sqrt(2*f(2)^2*log(10/9))+Xpk;
transientT = x01 - x09;
fitX = min(x):step:max(x);
fitY = f(1)*exp(-(fitX-Xpk).^2/2/(f(2)^2))+baseline;