# Muse-signal-quality-check
Developed a MATLAB-based EEG quality-check pipeline for Muse recordings, featuring Butterworth bandpass filtering, 50 Hz notch filtering, Welch PSD, frequency-band power analysis, artifact detection, flatline checks, and line-noise assessment across TP9, AF7, AF8, and TP10.

# Muse EEG Signal Quality Assessment – MATLAB
This project implements a MATLAB-based quality-control (QC) pipeline for EEG recordings acquired using the **Muse EEG headset**. The objective is to evaluate signal integrity, identify potential artifacts, assess noise contamination, and visualize important signal characteristics before proceeding with further EEG analysis.

The pipeline processes CSV recordings containing four EEG channels: **TP9, AF7, AF8, and TP10**, sampled at 256 Hz. It begins with data integrity checks and visualization of raw EEG signals, followed by preprocessing using a Butterworth bandpass filter (1–40 Hz) and a 50 Hz notch filter to reduce unwanted frequency components while retaining relevant EEG activity.

Signal quality is evaluated using multiple time-domain and frequency-domain measures. These include amplitude statistics, variance, RMS amplitude, histograms, flatline detection, and artifact assessment. Frequency-domain analysis uses FFT and Welch's Power Spectral Density (PSD) estimation, complemented by spectrograms for examining changes in spectral content over time.

The pipeline also calculates power across standard EEG frequency bands, including delta, theta, alpha, beta, and gamma, along with the Alpha/Beta ratio. Additional quality indicators include 50 Hz line-noise assessment, high-frequency versus low-frequency power, and spectral characteristics. Channel correlation and channel-wise visualizations support the identification of unusual signal patterns and potential channel-quality issues.

The resulting analyses provide a structured overview of recording quality and help determine whether EEG data are suitable for subsequent preprocessing and feature extraction. The workflow is designed to support reproducible EEG inspection while retaining the original recordings for comparison and further analysis.

Key Features
- Four-channel Muse EEG data processing.
- Butterworth bandpass and 50 Hz notch filtering.
- FFT, Welch PSD, and spectrogram visualization.
- Frequency-band power and Alpha/Beta ratio analysis.
- Artifact, flatline, and line-noise assessment.
- Channel-wise statistics and signal-quality evaluation.

Technologies:MATLAB, Muse EEG, Digital Signal Processing (DSP), Power Spectral Density (PSD), and EEG Quality Control.
