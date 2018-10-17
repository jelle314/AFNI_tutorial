clearvars -except params
jStartup('+','afni_matlab')
Thr = 1.25;
% Thr = 0.01;
% ThrLabel = '001';
ThrLabel = '125';
Hemi = 2; %0 = lh, 1 = rh, 2 = both
lineW = 2;
results = struct;

%% Load data
[Stats, StatsHeader ] = BrikLoad('results/statsCoreg_box.nii.gz');
[Depth, DepthHeader ] = BrikLoad('results/depth_shft_box.nii.gz');
[T1, T1Header ] = BrikLoad('results/anatomy_res_clip_shft_box.nii.gz');

%% Load ROIs
[V1lh, V1lhHeader ] = BrikLoad('results/V1_lh_shft_box.nii.gz');
[V1rh, V1rhHeader ] = BrikLoad('results/V1_rh_shft_box.nii.gz');
[V2lh, V2lhHeader ] = BrikLoad('results/V2_lh_shft_box.nii.gz');
[V2rh, V2rhHeader ] = BrikLoad('results/V2_rh_shft_box.nii.gz');
[V3lh, V3lhHeader ] = BrikLoad('results/V3_lh_shft_box.nii.gz');
[V3rh, V3rhHeader ] = BrikLoad('results/V3_rh_shft_box.nii.gz');

%% Depreciated naming 19-07-17
% [V1lh, V1lhHeader ] = BrikLoad('results/V1_lh_DICOM.1D.roi_clust+orig');
% [V1rh, V1rhHeader ] = BrikLoad('results/V1_rh_DICOM.1D.roi_clust+orig');

for iROIs = 1:3 %For V1-V3
    if iROIs == 1
        ROIlh = V1lh;
        ROIrh = V1rh;
        ROI = 'V1';
    elseif iROIs == 2
        ROIlh = V2lh;
        ROIrh = V2rh;
        ROI = 'V2';
    elseif iROIs == 3
        ROIlh = V3lh;
        ROIrh = V3rh;
        ROI = 'V3';
    end
    
    %Thresholding is crucial! Best would be independent ROI-based analysis
    idx_lh = (Stats(:,:,:,end-7) >= Thr | Stats(:,:,:,end-4) >= Thr | Stats(:,:,:,end-1) >= Thr) & ROIlh == 1; %3,6,9 ; or 13,16,19 (polort 4) 
    idx_rh = (Stats(:,:,:,end-7) >= Thr | Stats(:,:,:,end-4) >= Thr | Stats(:,:,:,end-1) >= Thr) & ROIrh == 1;
    
    if Hemi == 0;
        idx2 = idx_lh;
        tt = 'lh';
    elseif Hemi == 1;
        idx2 = idx_rh;
        tt = 'rh';
    elseif Hemi == 2;
        idx2 = (idx_rh | idx_lh);
        tt = '';
    end
    
    T1_Val = T1(idx2);
    Depth_Val = Depth(idx2);
    %Check which volume we need in afni (Coef is %signal change in this format)
    %Coef is % signal change because we have an impicit baseline, and
    %predictors are automatically scaled to 1 by afni
    % SO WE WANT COEF :)
    quant = quantile( Depth_Val, [ 0:.2:1 ]);
    
    Five_pc = Stats(:,:,:,end-8);
    pcBOLD_005 = Five_pc(idx2);
    for i = 1:length(quant)-1
        idx = Depth_Val >= quant(i) & Depth_Val < quant(i+1);
        results.(ROI).storeBOLD005(i) = median( pcBOLD_005( idx));
        results.(ROI).storeDepth005(i) = median( Depth_Val( idx));
        results.(ROI).error005(i) = std(pcBOLD_005( idx))/sqrt( sum( idx == 1));
    end
    figure
    p(1) = errorbar( results.(ROI).storeDepth005, results.(ROI).storeBOLD005, results.(ROI).error005, 'Color', [1 0 0]);
    hold on
    
    Twenty_pc = Stats(:,:,:,end-5);
    pcBOLD_02 = Twenty_pc(idx2);
    for i = 1:length(quant)-1
        idx = Depth_Val >= quant(i) & Depth_Val < quant(i+1);
        results.(ROI).storeBOLD02(i) = median( pcBOLD_02( idx));
        results.(ROI).storeDepth02(i) = median( Depth_Val( idx));
        results.(ROI).error02(i) = std(pcBOLD_02( idx))/sqrt( sum( idx == 1));
    end
    p(2)=errorbar( results.(ROI).storeDepth02, results.(ROI).storeBOLD02, results.(ROI).error02, 'Color', [0 1 0]);
    
    
    Eighty_pc = Stats(:,:,:,end-2);
    pcBOLD_Eighty = Eighty_pc(idx2);
    for i = 1:length(quant)-1
        idx = Depth_Val >= quant(i) & Depth_Val < quant(i+1);
        results.(ROI).storeBOLD08(i) = median( pcBOLD_Eighty( idx));
        results.(ROI).storeDepth08(i) = median( Depth_Val( idx));
        results.(ROI).error08(i) = std(pcBOLD_Eighty( idx))/sqrt( sum( idx == 1));
    end
    p(3)= errorbar( results.(ROI).storeDepth08, results.(ROI).storeBOLD08, results.(ROI).error08, 'Color', [0 0 1]);
    
    xlabel('Cortical depth')
    ylabel('BOLD Amplitude [%]')
    title(['Laminar contrast response profiles' tt ' ' ROI])
    legend('5% contrast','20% contrast','80% contrast','Location','Best')
    set(gca,'fontsize',15,'FontWeight','bold')
    set(gca,'LineWidth',1)
    axis([0 1 0 5.5])
    set(gca,'YTick',[2 4])
    set(gca,'XTick',[0 0.5 1])
    axis square
    
    for i = 1:3
        p(i).LineWidth = lineW;
    endV3lh
    hold off
    
    [ ~, FileName] = fileparts( pwd);
    saveas(gcf, ['ctfvsdepth_' FileName tt '_' ROI '_Thr' ThrLabel], 'epsc');
    saveas(gcf, ['ctfvsdepth_' FileName tt '_' ROI '_Thr' ThrLabel], 'tif');
end
results.Threshold = Thr;
results.Hemisphere = Hemi;
results.LineWidth = lineW;
save(['results/' FileName '_ctfvsdepth'], 'results');
