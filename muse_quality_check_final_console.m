%% ============================================================
%             MUSE EEG QUALITY CONTROL PIPELINE v3
% =============================================================
%
% Purpose:
%   Quality control of Muse/SkyBrain 4-channel EEG recordings
%
% Channels:
%   TP9, AF7, AF8, TP10
%
% Sampling frequency:
%   256 Hz
%
% Handles CSV files WITH or WITHOUT segment_label.
%
% =============================================================

clear;
clc;
close all;

fprintf('\n');
fprintf('============================================================\n');
fprintf('             MUSE EEG QC PIPELINE v3\n');
fprintf('============================================================\n\n');


%% ============================================================
% 1. SETTINGS
% =============================================================

% -------- CSV FILE --------

filePath = ...
'"C:\Users\Debarati\Documents\SkyBrain\recordings\ya\csv\ya_Session_152603_20260929_152607.csv"';

% -------- SAMPLING RATE --------

Fs = 256;

% -------- EEG CHANNELS --------

channelNames = {'TP9','AF7','AF8','TP10'};

% -------- FILTER RANGE --------

lowCut = 1;
highCut = 40;

% -------- OUTPUT FILE --------

outputFile = ...
'C:\Users\Debarati\Documents\SkyBrain\recordings\me\csv\Muse_QC_Results.csv';


%% ============================================================
% 2. LOAD CSV
% =============================================================

fprintf('Loading file...\n');

T = readtable("C:\Users\Debarati\Documents\SkyBrain\recordings\random_m\csv\random_m_Session_121410_20260922_121413.csv");

fprintf('File loaded successfully.\n\n');

fprintf('CSV size:\n');
fprintf('Rows    : %d\n', height(T));
fprintf('Columns : %d\n\n', width(T));


%% ============================================================
% 3. DISPLAY AVAILABLE COLUMNS
% =============================================================

fprintf('Columns found in CSV:\n');

disp(T.Properties.VariableNames);


%% ============================================================
% 4. CHECK REQUIRED EEG COLUMNS
% =============================================================

requiredColumns = ...
    {'timestamp_unix','TP9','AF7','AF8','TP10'};

for i = 1:length(requiredColumns)

    if ~ismember(requiredColumns{i}, T.Properties.VariableNames)

        error(['Missing required EEG column: ' ...
            requiredColumns{i}]);

    end

end

fprintf('Required EEG columns found.\n');


%% ============================================================
% 5. OPTIONAL SEGMENT LABEL
% =============================================================

hasSegmentLabel = ...
    ismember('segment_label', T.Properties.VariableNames);

if hasSegmentLabel

    fprintf('segment_label found.\n');
    fprintf('Segment-wise analysis ENABLED.\n\n');

else

    fprintf('WARNING: segment_label not found.\n');
    fprintf('Continuing without segment-wise analysis.\n\n');

end


%% ============================================================
% 6. EXTRACT EEG DATA
% =============================================================

TP9  = double(T.TP9);
AF7  = double(T.AF7);
AF8  = double(T.AF8);
TP10 = double(T.TP10);

EEG = [TP9 AF7 AF8 TP10];

channelNames = ...
    {'TP9','AF7','AF8','TP10'};


%% ============================================================
% 7. BASIC INFORMATION
% =============================================================

N = size(EEG,1);

durationSeconds = N / Fs;

fprintf('EEG samples     : %d\n', N);
fprintf('Sampling rate   : %d Hz\n', Fs);
fprintf('Duration        : %.2f seconds\n', durationSeconds);
fprintf('Duration        : %.2f minutes\n\n', ...
    durationSeconds/60);


%% ============================================================
% 8. BASIC SIGNAL STATISTICS
% =============================================================

fprintf('============================================================\n');
fprintf('BASIC SIGNAL STATISTICS\n');
fprintf('============================================================\n');

meanVal = mean(EEG,1,'omitnan');
stdVal  = std(EEG,0,1,'omitnan');
minVal  = min(EEG,[],1);
maxVal  = max(EEG,[],1);

for ch = 1:4

    fprintf('\n%s\n',channelNames{ch});

    fprintf('Mean : %.4f\n',meanVal(ch));
    fprintf('STD  : %.4f\n',stdVal(ch));
    fprintf('Min  : %.4f\n',minVal(ch));
    fprintf('Max  : %.4f\n',maxVal(ch));

end


%% ============================================================
% 9. RAW EEG PLOT
% =============================================================

time = (0:N-1)/Fs;

figure('Name','Raw EEG','Color','w');

tiledlayout(4,1);

for ch = 1:4

    nexttile;

    plot(time,EEG(:,ch));

    xlabel('Time (s)');
    ylabel(channelNames{ch});

    title(['Raw EEG - ' channelNames{ch}]);

    grid on;

end


%% ============================================================
% 10. DESIGN 1-40 Hz BANDPASS FILTER
% =============================================================

fprintf('\nCreating 1-40 Hz bandpass filtered EEG...\n');

[b,a] = butter(4,[lowCut highCut]/(Fs/2),'bandpass');

EEG_filtered = zeros(size(EEG));

for ch = 1:4

    EEG_filtered(:,ch) = ...
        filtfilt(b,a,EEG(:,ch));

end

fprintf('Filtering complete.\n');


%% ============================================================
% 11. FILTERED EEG PLOT
% =============================================================

figure('Name','Filtered EEG 1-40 Hz','Color','w');

tiledlayout(4,1);

for ch = 1:4

    nexttile;

    plot(time,EEG_filtered(:,ch));

    xlabel('Time (s)');
    ylabel(channelNames{ch});

    title(['Filtered EEG 1-40 Hz - ' channelNames{ch}]);

    grid on;

end


%% ============================================================
% 12. WELCH PSD
% =============================================================

fprintf('\nCalculating power spectral density...\n');

figure('Name','Welch PSD','Color','w');

tiledlayout(2,2);

PSD_data = cell(1,4);
F_data   = cell(1,4);

for ch = 1:4

    [Pxx,F] = pwelch( ...
        EEG_filtered(:,ch), ...
        [],[],[],Fs);

    PSD_data{ch} = Pxx;
    F_data{ch}   = F;

    nexttile;

    plot(F,Pxx);

    xlim([1 40]);

    xlabel('Frequency (Hz)');
    ylabel('Power');

    title(['PSD - ' channelNames{ch}]);

    grid on;

end


%% ============================================================
% 13. SPECTRAL SLOPE
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('SPECTRAL SLOPE\n');
fprintf('============================================================\n');

spectralSlope = zeros(1,4);

for ch = 1:4

    F = F_data{ch};
    P = PSD_data{ch};

    idx = F >= 2 & F <= 40 & P > 0;

    x = log10(F(idx));
    y = log10(P(idx));

    coeff = polyfit(x,y,1);

    spectralSlope(ch) = coeff(1);

    fprintf('%s : %.4f\n', ...
        channelNames{ch}, ...
        spectralSlope(ch));

end


%% ============================================================
% 14. BAND POWER
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('BAND POWER\n');
fprintf('============================================================\n');

bands = {
    'Delta',1,4;
    'Theta',4,8;
    'Alpha',8,13;
    'Beta',13,30;
    'Gamma',30,40
    };

bandPowerResults = zeros(4,5);

for ch = 1:4

    F = F_data{ch};
    P = PSD_data{ch};

    for bnd = 1:size(bands,1)

        fLow  = bands{bnd,2};
        fHigh = bands{bnd,3};

        idx = F >= fLow & F <= fHigh;

        bandPowerResults(ch,bnd) = ...
            trapz(F(idx),P(idx));

    end

end

for ch = 1:4

    fprintf('\n%s\n',channelNames{ch});

    for bnd = 1:5

        fprintf('%s : %.6f\n', ...
            bands{bnd,1}, ...
            bandPowerResults(ch,bnd));

    end

end


%% ============================================================
% 15. ALPHA / BETA RATIO
% =============================================================

alphaPower = bandPowerResults(:,3);
betaPower  = bandPowerResults(:,4);

alphaBetaRatio = alphaPower ./ betaPower;

fprintf('\n');
fprintf('============================================================\n');
fprintf('ALPHA / BETA RATIO\n');
fprintf('============================================================\n');

for ch = 1:4

    fprintf('%s : %.4f\n', ...
        channelNames{ch}, ...
        alphaBetaRatio(ch));

end


%% ============================================================
% 16. HIGH / LOW FREQUENCY RATIO
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('HIGH / LOW FREQUENCY RATIO\n');
fprintf('============================================================\n');

highLowRatio = zeros(1,4);

for ch = 1:4

    F = F_data{ch};
    P = PSD_data{ch};

    highIdx = F >= 20 & F <= 40;
    lowIdx  = F >= 1 & F < 20;

    highPower = trapz(F(highIdx),P(highIdx));
    lowPower  = trapz(F(lowIdx),P(lowIdx));

    highLowRatio(ch) = highPower / lowPower;

    fprintf('%s : %.4f\n', ...
        channelNames{ch}, ...
        highLowRatio(ch));

end


%% ============================================================
% 17. 50 Hz LINE NOISE
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('50 Hz LINE NOISE CHECK\n');
fprintf('============================================================\n');

lineNoiseRatio = zeros(1,4);

for ch = 1:4

    % Use RAW signal for line-noise measurement

    [Praw,Fraw] = pwelch( ...
        EEG(:,ch), ...
        [],[],[],Fs);

    totalIdx = Fraw >= 1 & Fraw <= 40;

    lineIdx = Fraw >= 49 & Fraw <= 51;

    totalPower = trapz( ...
        Fraw(totalIdx), ...
        Praw(totalIdx));

    linePower = trapz( ...
        Fraw(lineIdx), ...
        Praw(lineIdx));

    lineNoiseRatio(ch) = ...
        linePower / totalPower;

    fprintf('%s : %.6f\n', ...
        channelNames{ch}, ...
        lineNoiseRatio(ch));

end


%% ============================================================
% 18. ROBUST ARTIFACT DETECTION
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('ROBUST ARTIFACT CHECK\n');
fprintf('============================================================\n');

artifactPercentage = zeros(1,4);

for ch = 1:4

    x = EEG_filtered(:,ch);

    medX = median(x,'omitnan');

    MAD = median(abs(x-medX),'omitnan');

    robustSD = 1.4826 * MAD;

    if robustSD == 0

        artifactPercentage(ch) = 0;

    else

        robustZ = abs((x-medX)/robustSD);

        artifactPercentage(ch) = ...
            100 * mean(robustZ > 6);

    end

    fprintf('%s : %.4f %%\n', ...
        channelNames{ch}, ...
        artifactPercentage(ch));

end


%% ============================================================
% 19. ROBUST AMPLITUDE
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('ROBUST AMPLITUDE\n');
fprintf('============================================================\n');

robustAmplitude = zeros(1,4);

for ch = 1:4

    x = EEG_filtered(:,ch);

    MAD = median( ...
        abs(x-median(x,'omitnan')), ...
        'omitnan');

    robustAmplitude(ch) = 1.4826 * MAD;

    fprintf('%s : %.4f\n', ...
        channelNames{ch}, ...
        robustAmplitude(ch));

end


%% ============================================================
% 20. FLATLINE CHECK
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('FLATLINE CHECK\n');
fprintf('============================================================\n');

flatlinePercentage = zeros(1,4);

for ch = 1:4

    x = EEG(:,ch);

    dx = diff(x);

    % Very conservative flatline criterion

    flatlinePercentage(ch) = ...
        100 * mean(dx == 0);

    fprintf('%s : %.4f %%\n', ...
        channelNames{ch}, ...
        flatlinePercentage(ch));

end


%% ============================================================
% 21. CHANNEL CORRELATION
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('CHANNEL CORRELATION\n');
fprintf('============================================================\n');

correlationMatrix = corrcoef(EEG_filtered, ...
    'Rows','pairwise');

disp(array2table( ...
    correlationMatrix, ...
    'VariableNames',channelNames, ...
    'RowNames',channelNames));


figure('Name','Channel Correlation','Color','w');

imagesc(correlationMatrix);

colorbar;

xticks(1:4);
yticks(1:4);

xticklabels(channelNames);
yticklabels(channelNames);

title('Channel Correlation');


%% ============================================================
% 22. ALPHA POWER PLOT
% =============================================================

figure('Name','Alpha Power','Color','w');

bar(alphaPower);

xticks(1:4);
xticklabels(channelNames);

ylabel('Alpha Power');

title('Alpha Power 8-13 Hz');

grid on;


%% ============================================================
% 23. ALPHA / BETA PLOT
% =============================================================

figure('Name','Alpha Beta Ratio','Color','w');

bar(alphaBetaRatio);

xticks(1:4);
xticklabels(channelNames);

ylabel('Alpha / Beta');

title('Alpha / Beta Ratio');

grid on;


%% ============================================================
% 24. HIGH / LOW FREQUENCY PLOT
% =============================================================

figure('Name','High Low Ratio','Color','w');

bar(highLowRatio);

xticks(1:4);
xticklabels(channelNames);

ylabel('20-40 Hz / 1-20 Hz');

title('High / Low Frequency Ratio');

grid on;


%% ============================================================
% 25. SPECTROGRAM
% =============================================================

fprintf('\nCreating spectrograms...\n');

figure('Name','EEG Spectrograms','Color','w');

tiledlayout(4,1);

for ch = 1:4

    nexttile;

    % Use a reasonable window

    windowLength = 4 * Fs;

    overlap = round(0.75 * windowLength);

    [S,F,Tspec] = spectrogram( ...
        EEG_filtered(:,ch), ...
        windowLength, ...
        overlap, ...
        [], ...
        Fs);

    P = abs(S).^2;

    imagesc(Tspec,F,10*log10(P + eps));

    axis xy;

    ylim([1 40]);

    xlabel('Time (s)');
    ylabel('Hz');

    title(['Spectrogram - ' channelNames{ch}]);

    colorbar;

end


%% ============================================================
% 26. OPTIONAL SEGMENT ANALYSIS
% =============================================================

if hasSegmentLabel

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('SEGMENT INFORMATION\n');
    fprintf('============================================================\n');

    segmentLabel = string(T.segment_label);

    segments = unique(segmentLabel);

    fprintf('Number of segments: %d\n\n', ...
        length(segments));

    for s = 1:length(segments)

        currentSegment = segments(s);

        idx = segmentLabel == currentSegment;

        fprintf('%s : %d samples (%.2f seconds)\n', ...
            currentSegment, ...
            sum(idx), ...
            sum(idx)/Fs);

    end

else

    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('SEGMENT ANALYSIS\n');
    fprintf('============================================================\n');

    fprintf('Skipped because segment_label is not present.\n');

end


%% ============================================================
% 27. CREATE QC RESULTS TABLE
% =============================================================

fprintf('\n');
fprintf('============================================================\n');
fprintf('CREATING QC RESULTS TABLE\n');
fprintf('============================================================\n');

QC_Table = table( ...
    string(channelNames'), ...
    meanVal', ...
    stdVal', ...
    minVal', ...
    maxVal', ...
    spectralSlope', ...
    bandPowerResults(:,1), ...
    bandPowerResults(:,2), ...
    bandPowerResults(:,3), ...
    bandPowerResults(:,4), ...
    bandPowerResults(:,5), ...
    alphaBetaRatio, ...
    highLowRatio', ...
    lineNoiseRatio', ...
    artifactPercentage', ...
    robustAmplitude', ...
    flatlinePercentage', ...
    'VariableNames', ...
    { ...
    'Channel', ...
    'Mean', ...
    'STD', ...
    'Min', ...
    'Max', ...
    'SpectralSlope', ...
    'DeltaPower', ...
    'ThetaPower', ...
    'AlphaPower', ...
    'BetaPower', ...
    'GammaPower', ...
    'AlphaBetaRatio', ...
    'HighLowRatio', ...
    'LineNoise50Hz', ...
    'ArtifactPercent', ...
    'RobustAmplitude', ...
    'FlatlinePercent' ...
    });


%% ============================================================
% 28. DISPLAY FINAL QC TABLE
% =============================================================

fprintf('\n');

disp(QC_Table);


%% ============================================================
% 29. SAVE QC TABLE
% =============================================================

writetable(QC_Table,outputFile);

fprintf('\nQC results saved to:\n');
fprintf('%s\n',outputFile);


%% ============================================================
% 30. AUTOMATIC OVERALL QUALITY CONCLUSION
% =============================================================
%
% Practical screening thresholds based on the QC metrics already
% calculated above. These are HEURISTIC thresholds, not clinical
% diagnostic cutoffs.
%
% Lower artifact, line-noise and flatline values = cleaner data.
% =============================================================

fprintf('\\n');
fprintf('============================================================\\n');
fprintf('             OVERALL EEG QUALITY CONCLUSION\\n');
fprintf('============================================================\\n');

channelScore = zeros(1,4);
channelQuality = strings(1,4);
channelNoise = strings(1,4);

for ch = 1:4

    score = 100;

    % -------- Artifact penalty --------
    if artifactPercentage(ch) <= 1
        artifactPenalty = 0;
    elseif artifactPercentage(ch) <= 5
        artifactPenalty = 15;
    elseif artifactPercentage(ch) <= 10
        artifactPenalty = 30;
    else
        artifactPenalty = 45;
    end

    % -------- 50 Hz line-noise penalty --------
    if lineNoiseRatio(ch) <= 0.01
        linePenalty = 0;
    elseif lineNoiseRatio(ch) <= 0.05
        linePenalty = 15;
    elseif lineNoiseRatio(ch) <= 0.10
        linePenalty = 30;
    else
        linePenalty = 45;
    end

    % -------- Flatline penalty --------
    if flatlinePercentage(ch) <= 0.1
        flatPenalty = 0;
    elseif flatlinePercentage(ch) <= 1
        flatPenalty = 10;
    elseif flatlinePercentage(ch) <= 5
        flatPenalty = 25;
    else
        flatPenalty = 40;
    end

    score = max(0, score - artifactPenalty - linePenalty - flatPenalty);
    channelScore(ch) = score;

    if score >= 85
        channelQuality(ch) = "VERY GOOD";
    elseif score >= 70
        channelQuality(ch) = "GOOD";
    elseif score >= 50
        channelQuality(ch) = "FAIR";
    else
        channelQuality(ch) = "BAD";
    end

    noiseBurden = artifactPenalty + linePenalty;

    if noiseBurden <= 10
        channelNoise(ch) = "LOW";
    elseif noiseBurden <= 30
        channelNoise(ch) = "MODERATE";
    else
        channelNoise(ch) = "HIGH";
    end

    fprintf('\\n%s\\n', channelNames{ch});
    fprintf('  QC Score          : %.1f / 100\\n', channelScore(ch));
    fprintf('  Quality           : %s\\n', channelQuality(ch));
    fprintf('  Noise / Artifact  : %s\\n', channelNoise(ch));
    fprintf('  Artifact          : %.3f %%\\n', artifactPercentage(ch));
    fprintf('  50 Hz Noise Ratio : %.6f\\n', lineNoiseRatio(ch));
    fprintf('  Flatline          : %.3f %%\\n', flatlinePercentage(ch));

end

overallScore = mean(channelScore);

if overallScore >= 85
    overallQuality = "VERY GOOD";
elseif overallScore >= 70
    overallQuality = "GOOD";
elseif overallScore >= 50
    overallQuality = "FAIR";
else
    overallQuality = "BAD";
end

highNoiseCount = sum(channelNoise == "HIGH");
moderateNoiseCount = sum(channelNoise == "MODERATE");

if highNoiseCount >= 2
    overallNoise = "HIGH";
elseif highNoiseCount == 1 || moderateNoiseCount >= 2
    overallNoise = "MODERATE";
else
    overallNoise = "LOW";
end

fprintf('\\n');
fprintf('------------------------------------------------------------\\n');
fprintf('\n');
fprintf('------------------------------------------------------------\n');
fprintf('FINAL RECORDING ASSESSMENT\n');
fprintf('------------------------------------------------------------\n');
fprintf('\n');

fprintf('Overall QC Score       : %.1f / 100\n', overallScore);
fprintf('Overall Quality        : %s\n', overallQuality);
fprintf('Overall Noise/Artifact : %s\n', overallNoise);
fprintf('\n');

fprintf('CONCLUSION\n');
fprintf('------------------------------------------------------------\n');

if overallQuality == "VERY GOOD"
    fprintf('Quality Level  : VERY GOOD\n');
    fprintf('Noise Level    : LOW\n');
    fprintf('Assessment     : Clean and stable EEG recording.\n');
    fprintf('Recommendation : Suitable for further EEG spectral analysis.\n');
elseif overallQuality == "GOOD"
    fprintf('Quality Level  : GOOD\n');
    fprintf('Noise Level    : %s\n', overallNoise);
    fprintf('Assessment     : Acceptable EEG recording with manageable noise/artifacts.\n');
    fprintf('Recommendation : Suitable for further EEG analysis with routine preprocessing.\n');
elseif overallQuality == "FAIR"
    fprintf('Quality Level  : FAIR\n');
    fprintf('Noise Level    : %s\n', overallNoise);
    fprintf('Assessment     : Moderate noise/artifacts are present.\n');
    fprintf('Recommendation : Use after careful preprocessing and artifact rejection.\n');
else
    fprintf('Quality Level  : BAD\n');
    fprintf('Noise Level    : HIGH\n');
    fprintf('Assessment     : Substantial noise/artifacts or signal-quality issues are present.\n');
    fprintf('Recommendation : Review carefully before using for further analysis.\n');
end

fprintf('\n');
fprintf('Automated QC Note : This is a screening conclusion based on heuristic thresholds.\n');
fprintf('                    It is not a clinical diagnosis.\n');
fprintf('------------------------------------------------------------\n');
fprintf('============================================================\n');
fprintf('             QC ANALYSIS COMPLETE\n');
fprintf('============================================================\n');

fprintf('\nRaw EEG preserved.\n');
fprintf('Filtered EEG created separately.\n');
fprintf('Segment analysis was automatically handled.\n');

fprintf('\nChannels analysed:\n');

for ch = 1:4
    fprintf('  %s\n',channelNames{ch});
end

fprintf('\nDone! 🧠\n');