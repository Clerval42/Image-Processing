# BIM472 Project 2: Final Results Summary

**Date**: April 2026  
**Dataset**: IDRiD Training Set (54 images)  
**Method**: Image Processing Pipeline (Preprocessing + Morphological Operations)

---

## Executive Summary

This project implemented an image processing pipeline for **Optic Disc (OD) center localization and segmentation** and **Fovea center localization** in fundus retinal images. The pipeline consists of four stages:

1. **Preprocessing**: Green channel extraction, CLAHE enhancement, median filtering
2. **OD Detection & Segmentation**: Morphological operations and connected component analysis
3. **Fovea Localization**: Anatomical constraint-based search
4. **Evaluation**: Euclidean distance error and segmentation metrics

---

## Dataset Information

| Property | Value |
|----------|-------|
| Total Images | 54 training images |
| Image Source | IDRiD Dataset (Kaggle) |
| Image Resolution | ~4000×3000 pixels (variable) |
| Ground Truth | CSV coordinates + TIF masks |
| OD Coordinates | 54 (Optic Disc Center Training Set_Markups.csv) |
| Fovea Coordinates | 54 (Fovea Center Training Set_Markups.csv) |
| OD Masks | 54 TIF binary masks (Optic Disc folder) |

---

## Results: Localization Performance

### Optic Disc (OD) Center Detection

| Metric | Value |
|--------|-------|
| Mean Error | **1012.40 pixels** |
| Std Deviation | 587.67 pixels |
| Median Error | 907.65 pixels |
| Min Error | 94.00 pixels (IDRiD_50) |
| Max Error | 2034.29 pixels (IDRiD_52) |
| Images Successfully Detected | 54/54 (100%) |

**Interpretation**: Mean error of ~1000 pixels on typical 4000×3000 images represents ~25% of image width. This is suboptimal and suggests the morphological approach has limitations with variable disc brightness/size.

### Fovea Center Detection

| Metric | Value |
|--------|-------|
| Mean Error | **2085.60 pixels** |
| Std Deviation | 659.40 pixels |
| Median Error | 2247.71 pixels |
| Min Error | 419.27 pixels (IDRiD_06) |
| Max Error | 3143.22 pixels (IDRiD_18) |
| Images Successfully Detected | 54/54 (100%) |

**Interpretation**: Fovea errors are 2× larger than OD errors. The simple darkest-pixel search within an anatomical ROI is insufficient. The fovea region is often subtle and may not be the darkest point in the search area, especially in images with pathology.

---

## Results: Segmentation Performance

### Optic Disc Segmentation (OD Mask Evaluation)

| Metric | Value |
|--------|-------|
| Mean Precision | **0.1908** (19.08%) |
| Mean Recall | **0.7131** (71.31%) |
| Mean F-Score | **0.2864** (28.64%) |
| Mean Dice Coefficient | 0.2864 |
| Mean IoU | 0.1809 |

**Interpretation**: 
- **High Recall (71%)**: Pipeline detects most OD pixels correctly
- **Low Precision (19%)**: Pipeline produces many false positive pixels
- **Low F-Score (0.29)**: Trade-off heavily favors detection over accuracy
- **Root Cause**: Simple thresholding at 90th percentile captures too much bright tissue (vessels, peripapillary atrophy)

### Per-Image Breakdown (F-Score Distribution)

| F-Score Range | Image Count | Examples |
|---|---|---|
| F > 0.7 | 1 | IDRiD_09 (F=0.831) |
| F: 0.5-0.7 | 7 | IDRiD_01, 02, 24, 40, 48, 50 |
| F: 0.3-0.5 | 17 | IDRiD_05, 14, 15, 20, 26, 31, 33, 43, 47, 52, 53 |
| F: 0.1-0.3 | 24 | Most remaining images |
| F: 0-0.1 | 5 | IDRiD_06, 10, 11, 12, 16, 25, 54 (F=0.0) |

**Best Case**: IDRiD_09 (F=0.831, P=0.743, R=0.943)  
**Worst Cases**: IDRiD_06, 10, 11, 12, 16, 25, 54 (F=0.0, possible OD not detected or extremely poor match)

---

## Preprocessing Pipeline

### Steps Implemented

1. **Green Channel Extraction**
   - Reason: Fundus images have best contrast in green channel for vascular and disc features
   - Typical intensity range: [0, 255]

2. **CLAHE (Contrast Limited Adaptive Histogram Equalization)**
   - Parameters: ClipLimit=0.02, Distribution='rayleigh'
   - Effect: Enhances local contrast, improves fovea visibility as dark region

3. **Median Filter (Noise Reduction)**
   - Kernel size: 5×5 pixels
   - Effect: Removes sensor noise while preserving edges

### Preprocessing Impact

- **Before**: Raw fundus image with variable illumination
- **After**: Enhanced green channel with clearer disc boundaries and fovea depression

---

## Algorithm Details

### OD Detection & Segmentation

```
1. Extract green channel from RGB
2. Apply CLAHE enhancement
3. Apply 5×5 median filter
4. Threshold at 90th percentile (p90)
5. Morphological closing (disk SE, radius=15)
6. Fill holes
7. Connected component labeling
8. Extract largest component
9. Calculate centroid → OD center
10. Calculate equivalent diameter / 2 → OD radius
```

**Key Parameters**:
- Threshold percentile: 90 (captures brightest 10% of pixels)
- Morphological SE radius: 15 pixels
- Minimum component size: None (takes largest)

### Fovea Localization

```
1. Define search annulus around OD center
   - Min radius: 1.5 × OD_radius
   - Max radius: 3.5 × OD_radius
   (Anatomical constraint: fovea ~2.5 disc diameters away)
2. Search for darkest pixel in annulus
3. Return coordinates of minimum intensity point
```

**Anatomical Assumption**: Fovea is darkest point within 2.5-3.5 OD diameters of OD center (temporal side)

---

## Challenges & Limitations

### OD Localization Errors

1. **Variable disc brightness**: Some images have low-contrast discs
2. **Peripapillary atrophy**: Bright regions near disc confuse thresholding
3. **Hemorrhages & exudates**: Bright lesions outside disc trigger false positives
4. **Image quality**: Some training images have poor illumination

### OD Segmentation Errors

1. **Simple thresholding**: Captures too much surrounding tissue
2. **Fixed morphological SE**: Not optimal for variable disc sizes
3. **No adaptive preprocessing**: Single CLAHE parameters for all images
4. **No boundary refinement**: Disc boundary is rough estimate

### Fovea Localization Errors

1. **Anatomical variation**: Fovea location varies more than assumed
2. **Darkest pixel assumption fails**: Fovea may not be darkest region
   - Blood vessels crossing fovea are darker
   - Hard exudates may be darker than fovea
3. **Search radius too broad**: 2.5-3.5 OD diameters is approximate
4. **No sub-pixel refinement**: Only pixel-level accuracy

---

## Performance Analysis by Image Quality

### Good Cases (OD Error < 500 px, Fovea Error < 1000 px)
- Clear disc boundary
- Good illumination
- Few pathological lesions
- Examples: IDRiD_26 (F=0.478), IDRiD_50 (F=0.432)

### Moderate Cases (OD Error 500-1500 px, Fovea Error 1000-2500 px)
- Visible disc but some low contrast
- Moderate illumination variation
- Some lesions present
- Examples: IDRiD_01, 02, 24

### Poor Cases (OD Error > 1500 px, Fovea Error > 2500 px)
- Very low disc contrast
- Poor illumination
- Many pathological lesions
- Extreme disc size variation
- Examples: IDRiD_33, 35, 38, 41, 44, 45, 52

---

## Recommendations for Improvement

### Short-term (Better parameter tuning)
1. **Adaptive thresholding**: Use local adaptive threshold instead of global
2. **Morphological SE optimization**: Learn SE size from disc size
3. **Fovea search refinement**: 
   - Use intensity profile (dark valley) instead of just minimum
   - Incorporate blood vessel detection
   - Constrain search to temporal side of disc

### Medium-term (Algorithm enhancements)
1. **Hough Circles**: Fit circle to detected OD boundary (more robust than centroid)
2. **Active Contours (Snakes)**: Refine OD boundary iteratively
3. **Region Growing**: Start from OD center, grow while intensity in expected range
4. **Multi-scale analysis**: Process at multiple scales, combine results

### Long-term (Deep learning)
1. **CNN-based detection**: End-to-end learning of OD center and boundary
2. **U-Net segmentation**: Pixel-wise classification of OD region
3. **Data augmentation**: Synthetic variations to improve robustness
4. **Transfer learning**: Pre-trained models from similar medical imaging tasks

---

## Files Generated

### Source Code
- `Preprocessing.m`: Main pipeline (54 images processing)
- `EvaluateODSegmentation.m`: Segmentation metrics calculation
- `GenerateReportFigures.m`: Visualization generation
- `GenerateSummaryReport.m`: Results consolidation
- `ImprovedFoveaLocalization.m`: Alternative fovea algorithm
- `README.md`: Complete documentation

### Results Data
- `results.csv`: Localization results (Image ID, predicted/GT coords, distances)
- `od_segmentation_results.csv`: Segmentation metrics per image
- `Figures/`: Three comprehensive PNG visualizations

### Documentation
- `RESULTS_SUMMARY.md`: This file
- `BIM472_TEMPLATE.doc`: Report template (to be filled in)

---

## Conclusion

This project demonstrates a complete image processing pipeline from preprocessing through evaluation. While results show room for improvement (OD F-score 0.29, localization errors ~1000 px), the pipeline successfully:

✓ Processes all 54 images automatically  
✓ Detects 100% of discs (though with location error)  
✓ Localizes fovea centers (with location error)  
✓ Generates quantitative evaluation metrics  
✓ Provides visualization of all stages  

The low F-score and high localization errors highlight the importance of robust segmentation and detection algorithms in medical image analysis. Future work should focus on adaptive preprocessing and more sophisticated boundary detection methods.

---

**Student Notes for Report Writing:**

1. **Abstract**: State goal (localization + segmentation), mention F-score 0.29, OD error 1012±588 px
2. **Introduction**: Explain clinical importance of OD/fovea detection in DR screening
3. **Methods**: Detail preprocessing (green channel, CLAHE, median), morphological operations, parameters
4. **Results**: 
   - Include Table 1: Segmentation metrics (Precision, Recall, F-score, Dice, IoU)
   - Include Table 2: Localization errors (mean ± std, median, range)
   - Include Figure 1: Preprocessing pipeline stages
   - Include Figure 2: OD detection (overlay on original)
   - Include Figure 3: Fovea localization
5. **Discussion**: Explain low F-score (high false positives), high localization error (difficult anatomical landmarks), suggest improvements
6. **Conclusion**: Summarize achievements and future directions

---

**For PowerPoint Presentation:**

Slide 1: Title + Authors + Date  
Slide 2: Problem Statement (why detect OD/fovea?)  
Slide 3: Dataset Overview (IDRiD, 54 images, ground truth)  
Slide 4: Methodology (4-step pipeline)  
Slide 5: Preprocessing (before/after)  
Slide 6: OD Detection Algorithm  
Slide 7: Fovea Localization Algorithm  
Slide 8: Results - Localization (table with metrics)  
Slide 9: Results - Segmentation (table with F-score, Dice, IoU)  
Slide 10: Example Results (show 3-4 successful/failed cases)  
Slide 11: Challenges & Limitations  
Slide 12: Conclusions & Future Work  

---

Generated: April 2026  
Format: Markdown for easy conversion to report  
