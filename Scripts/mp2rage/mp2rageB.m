%MP2RAGE stuff - reads in nifti's from r2agui (PAR/REC from packngo). 
%r2agui options: output NIFTI; 4D (makes no difference)
%outputs are ~000 (magnitude) and ~003 (phase). Rename to something
%sensible. (something like: MP2RAGE_INV1, MP2RAGE_INV1ph, MP2RAGE_INV2, MP2RAGE_INV2ph)
%Inputs are the base of the file you want to read in: 'xxx' in xxx_INV1.nii, 
%an expected threshold for the masking ~200 for 1mm, 80-100 for 0.6 mm 
%Check proper threshold: 
%dat = load_untouch_nii( 'MP2RAGE_INV2.nii' )
%imagesc( dat.img( :, : ,end/2 ),[60 61]) %or e.g. [80 81]
%and finally the movie flag. (1) = ON. 
%Make sure you have the niftitools included in your matlabpath
%Line 46 and following: fill out proper MP2RAGE values for your scanning
%sequence.

%%
function mp2rageB(name,thresh, movie)

inv1 = load_untouch_nii([name '_INV1.nii']);
inv1ph = load_untouch_nii([name '_INV1ph.nii']);
inv2 = load_untouch_nii([name '_INV2.nii']);
inv2ph = load_untouch_nii([name '_INV2ph.nii']);

%%
compINV1 = double(inv1.img).*exp((double(inv1ph.img)/4096*2*pi)*1i);
compINV2 = double(inv2.img).*exp((double(inv2ph.img)/4096*2*pi)*1i);

%%
%compINV1 = cos((double(inv1ph.img)/4096*2*pi)).*double(inv1.img) + 1i*sin((double(inv1ph.img)/4096*2*pi)).*double(inv1.img);
%compINV2 = cos((double(inv2ph.img)/4096*2*pi)).*double(inv2.img) + 1i*sin((double(inv2ph.img)/4096*2*pi)).*double(inv2.img);

%%
MP2RAGE = (real(compINV1.*compINV2./(compINV1.^2 + compINV2.^2)))*4095+2048;%(scaling 0-4095)
%subplot(221);imagesc(rot90(MP2RAGE(:,:,100)),[0,4000]);colorbar
MP2RAGE(find(MP2RAGE<0))=0;
%subplot(222);imagesc(rot90(MP2RAGE(:,:,100)),[0,4000]);colorbar
MP2RAGE(find(MP2RAGE>4000))=4000;
%subplot(223);imagesc(rot90(MP2RAGE(:,:,100)),[0,4000]);colorbar
mask = double(inv2.img(:,:,:,1)); mask(find(mask<thresh))=0; mask(find(mask>10))=1;
MP2RAGEM = MP2RAGE.*mask;
imagesc(rot90(MP2RAGEM(:,:,end/2)),[0,4000]);colorbar
axis image; axis off; colormap('gray');

%%
inv1.hdr.dime.dim(1) = 3;inv1.hdr.dime.dim(5)=1; 
inv1.hdr.dime.scl_slope = 1; inv1.hdr.dime.vox_offset = 0;
namen = [name 'M.nii'];
inv1.img = MP2RAGEM; save_untouch_nii(inv1,namen);
namen = [name '.nii'];
inv1.img = MP2RAGE; save_untouch_nii(inv1,namen);

%% T1maps 

%[T1map]=T1mappingMP2RAGE(MP2RAGEimg,2,MP2RAGE.TR,MP2RAGE.TIs,MP2RAGE.FlipDegrees,MP2RAGE.NExcitation_after_ivn,MP2RAGE.TRFLASH)
% 2blocks
% T1map = T1mappingMP2RAGE(inv1,2,8250,[1.200 3.800],[14,10],36,0.057);
% 4blocks
% T1map = T1mappingMP2RAGE(inv1,2,10,[1.000 3.200],[20,16],18,0.057);
% MP2RAGE
%  T1map = T1mappingMP2RAGE(inv1,2,8,[0.800 2.700],[7,5],160,0.0062); %note input is actually MP2RAGE saved in INV1

T1map = T1mappingMP2RAGE(inv1,2,6,[0.800 3.700],[7,5],159,0.0062); %note input is actually MP2RAGE saved in INV1

 
T1M = T1map;T1M.img = T1map.img.*mask;

namen = [name '_T1.nii'];
save_untouch_nii(T1map,namen);
namen = [name '_T1M.nii'];
save_untouch_nii(T1M,namen);

%%
if movie
    filename = [name '.gif'];
    colormap('gray');
    for n = 1:size(MP2RAGE,3)
        imagesc(rot90(MP2RAGEM(:,:,n)),[0,4000]);axis image;axis off
        drawnow
        frame = getframe(1);
        im = frame2im(frame);
        [A,map] = rgb2ind(im,256); 
       if n == 1;
		imwrite(A,map,filename,'gif','LoopCount',Inf,'DelayTime',0.1);
       else
		imwrite(A,map,filename,'gif','WriteMode','append','DelayTime',0.1)
       end
    end
end
end