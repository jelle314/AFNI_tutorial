function [T1map]=T1mappingMP2RAGE(MP2RAGEnii,nimage,MPRAGE_tr,invtimesAB,flipangleABdegree,nZslices,FLASH_tr,varargin)

if nargin==7
    [Intensity T1vector]=MP2RAGE_lookuptable(nimage,MPRAGE_tr,invtimesAB,(flipangleABdegree),nZslices,FLASH_tr,'normal');
else
    [Intensity T1vector]=MP2RAGE_lookuptable(nimage,MPRAGE_tr,invtimesAB,(flipangleABdegree),nZslices,FLASH_tr,'normal',varargin{1});
end
if max(abs(MP2RAGEnii.img(:)))>1
    T1=interp1(Intensity,T1vector,-0.5+1/4095*double(MP2RAGEnii.img(:)));
else
    T1=interp1(Intensity,T1vector,MP2RAGEnii.img(:));
end;
T1(isnan(T1))=0;
T1map=MP2RAGEnii;

T1map.img=reshape(T1*1000,size(MP2RAGEnii.img));

figure(525)
plot(Intensity,T1vector);
xlabel('MP2RAGE')

xlabel('T1')
