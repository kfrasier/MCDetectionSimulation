function y=Piston(x)
%function y=Piston(x)
y=ones(size(x));
ix=x~=0;
y(ix)=2*real(besselj(1,x(ix),1))./x(ix);
return
