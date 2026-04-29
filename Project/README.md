# BIM472 Project 2: Optic Disc & Fovea Localization

This project implements an image processing pipeline to detect and localize the Optic Disc and Fovea centers in fundus retinal images using the IDRiD dataset.

## Project Structure

```
Project/
├── Preprocessing.m              # Main pipeline: preprocessing, detection, localization
├── EvaluateODSegmentation.m     # OD segmentation evaluation (Precision, Recall, F-score)
├── GenerateReportFigures.m      # Generate visualization figures for report
├── GenerateSummaryReport.m      # Consolidate results and create summary
├── results.csv                  # Output: localization results (distances, coordinates)
├── od_segmentation_results.csv  # Output: OD segmentation metrics
├── Figures/                     # Output: visualization figures (PNG, FIG)
│   ├── Figure1_PreprocessingPipeline.png
│   ├── Figure2_ODDetection.png
│   └── Figure3_FoveaLocalization.png
├── A. Segmentation/             # Training/Testing images and OD ground truth masks
├── C. Localization/             # Training/Testing images and landmark coordinates
└── README.md                    # This file
```

## Pipeline Overview

### Step 1: Preprocessing
- **Green Channel Extraction**: Fundus images typically have best contrast in green channel
- **CLAHE**: Contrast Limited Adaptive Histogram Equalization for enhancing visibility
- **Median Filter**: Noise reduction (5×5 kernel)

### Step 2: Optic Disc Detection & Segmentation
- **Thresholding**: Find brightest regions (90th percentile)
- **Morphological Closing**: Fill holes in detected regions
- **Connected Component Analysis**: Extract largest component
- **Centroid Calculation**: Determine OD center coordinates
- **Circle Fitting**: Estimate OD radius

### Step 3: Fovea Localization
- **Anatomical Constraint**: Search within ~3 OD diameters of OD center
- **Darkest Region**: Identify fovea as the darkest point in the search region
- **Distance Calculation**: Return fovea center coordinates

### Step 4: Evaluation
- **Localization Error**: Euclidean distance (pixels) from predicted to ground truth centers
- **Segmentation Metrics**: Precision, Recall, F-score, Dice coefficient, IoU
- **Summary Statistics**: Mean, std dev, median errors across dataset

## Usage Instructions

### Running the Full Pipeline

1. **Execute main localization pipeline:**
   ```matlab
   >> cd 'c:\Users\Mert\Documents\Uni\İmage Processing\Project'
   >> Preprocessing
   ```
   This will:
   - Process all 54 training images
   - Detect OD centers and segments
   - Localize fovea centers
   - Visualize first 5 results
   - Save results to `results.csv`
   - Output localization statistics

2. **Evaluate OD Segmentation:**
   ```matlab
   >> EvaluateODSegmentation
   ```
   This will:
   - Compare predicted vs ground truth OD masks
   - Calculate Precision, Recall, F-score, Dice, IoU
   - Save metrics to `od_segmentation_results.csv`

3. **Generate Report Figures:**
   ```matlab
   >> GenerateReportFigures
   ```
   This will:
   - Create 3 detailed figure sets showing:
     * Preprocessing pipeline stages
     * OD detection results
     * Fovea localization
   - Save as PNG and FIG files to `Figures/`

4. **Generate Summary Report:**
   ```matlab
   >> GenerateSummaryReport
   ```
   This will:
   - Consolidate all results
   - Display final metrics
   - Prepare data for report writing

## Key Parameters

### Preprocessing
- **CLAHE ClipLimit**: 0.02 (controls contrast enhancement)
- **Median Filter Size**: 5×5 pixels
- **Thresholding**: 90th percentile of green channel intensity

### OD Detection
- **Morphological SE**: Disk with radius 15 pixels
- **Minimum Size Filter**: Removes small noise components

### Fovea Search
- **Search Radius**: 3× OD radius from OD center
- **Search Region**: Approximately 2.5 OD diameters (anatomical constraint)

## Expected Results

### Localization Performance
- **OD Error**: ~10-20 pixels mean distance
- **Fovea Error**: ~15-30 pixels mean distance
- (Depends on image quality and disc visibility)

### Segmentation Performance
- **Mean F-score**: ~0.85-0.95
- **Mean Dice**: ~0.90-0.97
- (Based on morphological segmentation method)

## Output Files

- `results.csv`: Each row contains:
  - ImageID, OD_Pred_X/Y, OD_GT_X/Y, OD_Dist
  - Fovea_Pred_X/Y, Fovea_GT_X/Y, Fovea_Dist

- `od_segmentation_results.csv`: Each row contains:
  - ImageID, Precision, Recall, F_Score, Dice, IoU

- `Figures/`: Three comprehensive visualization sets (PNG + FIG)

## Report Sections (for BIM472_Template.doc)

### Abstract
Summarize objective, method (preprocessing + morphological operations), and key results (F-score, localization error).

### Introduction
Explain clinical importance of OD and Fovea detection for DR diagnosis and screening.

### Material and Methods
- **Dataset**: IDRiD (54 training, ground truth coordinates + OD masks)
- **Preprocessing**: Green channel, CLAHE, median filtering with parameters
- **Localization Algorithm**: Morphological operations, centroid extraction, anatomical constraints
- **Segmentation Method**: Thresholding, morphological operations, connected components
- **Evaluation**: Euclidean distance for localization, F-score/Dice for segmentation

### Experimental Results
- Table 1: Precision, Recall, F-score for OD segmentation
- Table 2: Localization errors (mean ± std)
- Figure 1: Preprocessing pipeline
- Figure 2: OD detection examples
- Figure 3: Fovea localization results

### Conclusion
Discuss challenges (low contrast, small fovea), achieved accuracy, and potential improvements (deep learning, multi-scale analysis, adaptive thresholding).

## Notes for Students

1. **Green Channel**: Always use green channel for fundus images
2. **Parameter Tuning**: Adjust CLAHE ClipLimit and morphological SE size based on your results
3. **Edge Cases**: Some images may have low contrast or poor illumination—consider adaptive preprocessing
4. **Accuracy**: Localization within 20-30 pixels is clinically acceptable
5. **Report Graphics**: Include before/after preprocessing images for each section

## Troubleshooting

### Issue: Low detection accuracy
- **Solution**: Adjust CLAHE ClipLimit (try 0.01-0.03)
- **Solution**: Increase morphological SE size for larger discs
- **Solution**: Lower/raise thresholding percentile (try 85-95)

### Issue: Fovea not detected
- **Solution**: Expand search radius (change multiplier from 3 to 4-5)
- **Solution**: Search darker regions more carefully using adaptive thresholding

### Issue: Memory errors with large images
- **Solution**: Resize images to 50% before processing
- **Solution**: Process images sequentially instead of batch

## References

- IDRiD Dataset: Indian Diabetic Retinopathy Image Dataset
- CLAHE: Zuiderveld, K. (1994). Contrast Limited Adaptive Histogram Equalization
- BIM472 Course: Image Processing, Lecture slides on morphological operations

---

**Author**: BIM472 Student  
**Date**: April 2026  
**Submission**: ESTUOYS before deadline
