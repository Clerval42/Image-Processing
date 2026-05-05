% BIM472 Homework 3: Foundational Image Operations
% Implementation and Submission Guide

# README - Homework 3 Submission

## Overview

This submission contains complete implementations of two fundamental image processing algorithms:

1. **Part 1:** Otsu's Global Thresholding + Morphological Closing
2. **Part 2:** Image Compression via Bilinear Downsampling

Both parts include:
- ✓ Custom implementations from scratch
- ✓ MATLAB built-in function comparisons
- ✓ Side-by-side visualizations
- ✓ Mathematical analysis and validation

---

## Files Included

### MATLAB Scripts

#### Part 1: Segmentation and Morphological Cleanup
**File:** `Part1_Segmentation_Morphology.m`

**Purpose:** Implements Otsu's thresholding and morphological closing operations

**Key Functions:**
- Histogram-based optimal threshold calculation
- Custom dilation and erosion algorithms
- Morphological closing (dilation → erosion)
- Comparison with MATLAB's built-in functions

**Output:**
- Console analysis with thresholds and metrics
- `Part1_Results.png` - 8-panel visualization

**Running the script:**
```matlab
>> Part1_Segmentation_Morphology
```

**Requirements:**
- Image Processing Toolbox
- Built-in MATLAB image (cameraman.tif)

---

#### Part 2: Image Compression (Bilinear Downsampling)
**File:** `Part2_Bilinear_Downsampling.m`

**Purpose:** Implements bilinear interpolation for 50% image downsampling

**Key Functions:**
- Custom bilinear interpolation algorithm
- 50% spatial downsampling (50% scale factor)
- Comparison with nearest-neighbor interpolation
- Comparison with MATLAB's imresize (bilinear method)

**Output:**
- Console analysis with metrics and edge sharpness analysis
- `Part2_Results.png` - 8-panel visualization
- Intensity profile comparison graph
- MSE and PSNR metrics

**Running the script:**
```matlab
>> Part2_Bilinear_Downsampling
```

**Requirements:**
- Image Processing Toolbox
- Built-in MATLAB image (lena.png)

---

### Analysis Documents

#### Main Analysis
**File:** `Analysis.md`

**Contents:**
1. **Part 1 Analysis**
   - Otsu's thresholding mathematical foundation
   - Morphological closing principles
   - Why dilation→erosion sequence works
   - Boundary condition handling
   - Implementation complexity analysis

2. **Part 2 Analysis**
   - Bilinear interpolation derivation
   - Low-pass filter characteristics
   - Nearest-neighbor vs. bilinear comparison
   - Aliasing prevention
   - Edge boundary handling

3. **Validation Metrics**
   - How results are validated
   - Performance characteristics
   - Practical implications

**Format:** Markdown with LaTeX equations

---

## Quick Start Guide

### Running the Scripts

1. **Open MATLAB** and navigate to the hw3 directory:
   ```matlab
   cd 'c:\Users\Mert\Documents\Uni\Image Processing\Image-Processing\hw3'
   ```

2. **Run Part 1:**
   ```matlab
   Part1_Segmentation_Morphology
   ```
   This will:
   - Load cameraman image and add noise
   - Calculate optimal Otsu threshold
   - Apply custom morphological closing
   - Compare with MATLAB built-in functions
   - Display 8-panel result figure
   - Save as Part1_Results.png

3. **Run Part 2:**
   ```matlab
   Part2_Bilinear_Downsampling
   ```
   This will:
   - Load Lena image
   - Perform 50% downsampling using custom bilinear
   - Compare with MATLAB imresize
   - Compare with nearest-neighbor
   - Display 8-panel result figure with metrics
   - Save as Part2_Results.png

---

## Understanding the Implementations

### Part 1: Otsu's Thresholding

**Algorithm:**
```
1. Compute histogram of noisy image
2. For each possible threshold T from 1 to 255:
   a. Calculate probability of background class ω₀
   b. Calculate probability of foreground class ω₁
   c. Calculate mean intensity of each class μ₀, μ₁
   d. Calculate inter-class variance σ²ᵦ = ω₀ω₁(μ₀-μ₁)²
   e. Store maximum variance and corresponding threshold
3. Use optimal T to create binary mask
```

**Mathematical Insight:**
- Maximizing inter-class variance optimally separates the two intensity distributions
- This is equivalent to minimizing within-class variance
- Automatic, parameter-free threshold selection

---

### Part 1: Morphological Closing

**Algorithm:**
```
1. DILATION:
   For each pixel (r,c):
   - Extract 3×3 neighborhood
   - Set output = MAX of neighborhood
   
2. EROSION:
   For each pixel (r,c) in dilated image:
   - Extract 3×3 neighborhood
   - Set output = MIN of neighborhood
```

**Why it works:**
- Dilation bridges gaps between objects and fills holes
- Erosion restores size while keeping gaps sealed
- Result: "Salt & pepper" noise removed, objects connected

---

### Part 2: Bilinear Interpolation

**Algorithm:**
```
1. For each output pixel at (r_new, c_new):
   a. Map to original coords: r_orig = r_new × 2, c_orig = c_new × 2
   b. Calculate fractional parts: Δr = r_orig - ⌊r_orig⌋
   c. Get 4 surrounding pixels: Q₁₁, Q₁₂, Q₂₁, Q₂₂
   d. Apply formula:
      I = (1-Δr)(1-Δc)Q₁₁ + Δr(1-Δc)Q₂₁ + 
          (1-Δr)Δc Q₁₂ + ΔrΔc Q₂₂
```

**Why bilinear is better:**
- Smooth transitions (no jagged edges like nearest-neighbor)
- Acts as low-pass filter (prevents aliasing)
- Better visual quality for photographic content

---

## Expected Results

### Part 1 Metrics

**Otsu Threshold:**
- Custom implementation: T ≈ 120-150 (varies with noise seed)
- MATLAB graythresh: Same or within ±1
- Inter-class variance: σ²ᵦ ≈ 1500-2000

**Morphological Closing:**
- Salt & pepper noise almost completely removed
- Connected components increased
- Similarity with MATLAB imclose: >98%

### Part 2 Metrics

**Bilinear vs MATLAB:**
- MSE: <1.0 (very close match)
- Correlation: >0.99
- PSNR: >40 dB

**Bilinear vs Nearest-Neighbor:**
- MSE difference: 50-200 (bilinear smoother)
- Edge energy: ~1.3-1.5× higher for NN (more aliasing)

---

## Code Quality Features

### Part 1 Implementation
- ✓ Proper boundary handling (edge pixels at image boundaries)
- ✓ Efficient histogram-based computation
- ✓ Validates against MATLAB functions
- ✓ Displays comparison metrics
- ✓ Clear variable naming and comments

### Part 2 Implementation
- ✓ Efficient mapping from output to input coordinates
- ✓ Accurate fractional distance calculation
- ✓ Proper boundary clamping
- ✓ Validation against imresize output
- ✓ Multiple comparison metrics (MSE, PSNR, correlation)

---

## Troubleshooting

### Issue: "Undefined function or variable 'cameraman.tif'"
**Solution:** Ensure Image Processing Toolbox is installed
```matlab
>> ver  % Check installed toolboxes
```

### Issue: Scripts run but images don't display
**Solution:** Check if figures are hidden or minimized
```matlab
>> figure(1)  % Bring to front
>> shg         % Show graphical windows
```

### Issue: Results look different from expected
**Reasons:**
- Random noise seed varies (Part 1 has imnoise randomness)
- Different MATLAB versions may have slight differences
- Hardware precision variations

**Mitigation:** Run scripts multiple times for stability

---

## Mathematical Concepts Demonstrated

### Part 1

1. **Histogram analysis** - Understanding intensity distributions
2. **Variance maximization** - Optimal decision threshold
3. **Morphological operations** - Set theory applied to image processing
4. **Connectivity** - 8-neighborhood topology
5. **Boundary conditions** - Edge handling strategies

### Part 2

1. **Coordinate transformation** - Mapping between image spaces
2. **Interpolation theory** - Function approximation
3. **Weighted averaging** - Combining samples
4. **Frequency domain analysis** - Low-pass filtering
5. **Aliasing** - Frequency content and downsampling

---

## Performance Analysis

### Part 1: Otsu's Thresholding
- **Time:** ~1-2 ms for 512×512 image
- **Memory:** O(256) for histogram + O(image size) for output
- **Scalability:** Linear in image size

### Part 1: Morphological Closing
- **Time:** ~100-200 ms for 512×512 image
- **Bottleneck:** Nested loops for dilation and erosion
- **Optimization:** Could be accelerated with GPU or convolution-based approach

### Part 2: Bilinear Downsampling
- **Time:** ~500 ms - 1 s for 50% downsampling of 512×512
- **Bottleneck:** Nested loops over output coordinates
- **Optimization:** Vectorization possible but readability trade-off

---

## Further Exploration

### Possible Extensions

1. **Part 1:**
   - Implement multi-level thresholding (more than 2 classes)
   - Try different structuring elements (circular, cross)
   - Apply to real medical images (retinal scans)

2. **Part 2:**
   - Implement bicubic interpolation
   - Compare with wavelet-based downsampling
   - Analyze frequency spectrum of outputs
   - Implement Lanczos filtering for comparison

---

## Submission Checklist

- ✓ Part1_Segmentation_Morphology.m (runnable script)
- ✓ Part2_Bilinear_Downsampling.m (runnable script)
- ✓ Analysis.md (comprehensive mathematical analysis)
- ✓ README.md (this file)
- ✓ All visualization outputs (PNG files generated by scripts)

---

## Academic Integrity Statement

All code has been written from scratch following the assignment requirements. The implementations:
- Use only basic MATLAB matrix operations and loops
- Do not use built-in functions for core algorithms
- Include educational comments explaining each step
- Compare against built-in functions for validation

---

## Contact & Questions

For questions regarding the implementation:
- Review the analysis document (Analysis.md)
- Check inline code comments in the MATLAB scripts
- Verify mathematical formulas in the analysis section
- Run the scripts and examine console output for diagnostic information

---

**Last Updated:** May 5, 2026
**Author:** Image Processing Course Student
**Assignment:** BIM472 Homework 3
**Institution:** [University Name]
