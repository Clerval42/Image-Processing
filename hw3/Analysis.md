# BIM472 Homework 3: Foundational Image Operations Analysis

## Part 1: Segmentation and Morphological Cleanup

### 1.1 Otsu's Thresholding Method

#### Mathematical Foundation

Otsu's method finds the optimal global threshold T by maximizing the inter-class variance:

$$\sigma_B^2(T) = \omega_0(T) \omega_1(T) [\mu_0(T) - \mu_1(T)]^2$$

Where:
- **$\omega_0(T)$** = Probability (proportion) of background pixels (intensities 0 to T-1)
- **$\omega_1(T)$** = Probability of foreground pixels (intensities T to 255)
- **$\mu_0(T)$** = Mean intensity of background pixels
- **$\mu_1(T)$** = Mean intensity of foreground pixels

#### Implementation Strategy

The algorithm iterates through all 255 possible threshold values and calculates the inter-class variance for each. The threshold that maximizes this variance creates the best separation between the two classes.

**Key Advantages:**
1. **Automatic threshold selection** - No manual parameter tuning required
2. **Robust to illumination changes** - Based on histogram distribution
3. **Computationally efficient** - O(L) complexity where L is the number of gray levels

**Computational Complexity:**
- Computing histogram: O(M×N)
- Iterating through 255 thresholds: O(255)
- Calculating variance for each threshold: O(255)
- **Total:** O(M×N + 255²) ≈ O(M×N)

### 1.2 Morphological Closing Operation

#### Definition and Components

Morphological Closing = Dilation ⊕ Erosion

Where ⊕ denotes sequential application (not logical OR).

#### Dilation

**Definition:** For each pixel, replace it with the maximum value in its neighborhood.

$$I_{\text{dilated}}(x,y) = \max_{(i,j) \in N(x,y)} I(i,j)$$

**Effects:**
- Expands white (foreground) regions
- Fills small black holes within objects
- Removes "pepper" (small black) noise
- Thickens thin structures

#### Erosion

**Definition:** For each pixel, replace it with the minimum value in its neighborhood.

$$I_{\text{eroded}}(x,y) = \min_{(i,j) \in N(x,y)} I(i,j)$$

**Effects:**
- Shrinks white (foreground) regions
- Removes small white objects
- Removes "salt" (small white) noise
- Thins structures

#### Why Closing Works (Dilation → Erosion)

**Step 1: Dilation**
- **Action:** Expands white regions, bridging small gaps between objects
- **Result:** Removes pepper noise (small black objects disappear)
- **Trade-off:** Objects grow larger, boundaries blur slightly

**Step 2: Erosion**
- **Action:** Shrinks all white regions uniformly
- **Result:** Returns object size to approximately original dimensions
- **Key benefit:** Gap-bridges remain intact because they've been dilated

**Net Effect:** Small holes are filled, nearby objects connected, while object boundaries are restored.

#### Mathematical Interpretation

For a 3×3 square structuring element:
- **Connectivity preservation:** Closing connects components separated by noise
- **Noise removal:** Pepper noise (isolated black pixels) is eliminated
- **Size consistency:** Overall object sizes remain approximately constant

#### Boundary Handling

In our implementation, we use **zero-padding** (replicate boundary mode):
- Pixels at image edges are assumed to have implicit zeros beyond the boundary
- This prevents edge artifacts and maintains consistent behavior

### 1.3 Comparison with Built-in Functions

**MATLAB Built-ins Used:**
- `graythresh()` - Calculates optimal threshold using Otsu's method
- `imbinarize()` - Applies threshold to create binary image
- `strel()` - Creates structuring element
- `imclose()` - Performs morphological closing

**Expected Results:**
- Custom and built-in thresholds should be identical or very similar
- Morphological closing results should show >98% similarity
- Differences arise only from boundary handling variations

---

## Part 2: Image Compression (Bilinear Downsampling)

### 2.1 Interpolation Fundamentals

#### Problem Statement

**Goal:** Reduce image spatial dimensions by 50% while maintaining visual quality.

**Challenge:** New pixel coordinates don't align with original grid.
- New image position (1,1) → Original position (2,2)
- New image position (1,2) → Original position (2,4)
- New image position (2,1) → Original position (4,2)

**Mapping:** New coordinate (r', c') maps to original (r'×2, c'×2)

This typically yields non-integer coordinates requiring interpolation.

### 2.2 Bilinear Interpolation Formula

#### Derivation

For a non-integer coordinate (r, c) where:
- $r = \lfloor r \rfloor + \Delta r$ (integer + fractional part)
- $c = \lfloor c \rfloor + \Delta c$

The four surrounding pixels form a 2×2 neighborhood:
```
Q11 --- Q12
 |       |
Q21 --- Q22
```

**Bilinear Interpolation:**
$$I(r,c) = (1-\Delta r)(1-\Delta c)Q_{11} + \Delta r(1-\Delta c)Q_{21} + (1-\Delta r)\Delta c Q_{12} + \Delta r \Delta c Q_{22}$$

#### Mathematical Interpretation

This is a **weighted average** where:
- Weights sum to 1: $(1-\Delta r)(1-\Delta c) + \Delta r(1-\Delta c) + (1-\Delta r)\Delta c + \Delta r \Delta c = 1$ ✓
- Closer pixels get higher weight
- Weight decreases linearly with distance from interpolation point

#### Properties

1. **Continuity:** Output is continuous across pixel boundaries
2. **Symmetry:** Same weights for equivalent fractional distances
3. **Locality:** Uses only 4-neighborhood (computationally efficient)
4. **Linearity:** Preserves linear intensity gradients

### 2.3 Nearest-Neighbor vs. Bilinear Interpolation

#### Nearest-Neighbor

**Definition:** Assign the intensity of the closest pixel.

$$I_{\text{NN}}(r,c) = I(\text{round}(r), \text{round}(c))$$

**Advantages:**
- Computationally fastest
- Preserves exact original pixel values
- Retains edges and fine details

**Disadvantages:**
- Creates **aliasing artifacts** - jagged edges, stair-step patterns
- Produces blockiness in downsampled images
- Poor visual quality for smooth intensity transitions
- High-frequency content introduced by discontinuities

#### Bilinear Interpolation

**Definition:** Weighted average of 4 nearest neighbors.

**Advantages:**
- Smooth transitions between pixels
- Reduces aliasing artifacts
- Creates visually smoother results
- Acts as a **natural low-pass filter**

**Disadvantages:**
- Slightly blurrier results
- Loss of sharp edges
- Computationally more expensive (still O(1) but 4× the operations)
- May introduce ringing artifacts for very high-frequency content

### 2.4 Low-Pass Filter Characteristic of Bilinear Interpolation

#### Why Bilinear Acts as a Low-Pass Filter

**Frequency Domain Analysis:**

The bilinear kernel in the frequency domain has a sinc-like response:
- **Low frequencies (<0.25 fs):** Fully preserved
- **Mid frequencies (0.25-0.5 fs):** Gradually attenuated
- **High frequencies (>0.5 fs):** Significantly suppressed

Where fs is the sampling frequency.

**Physical Interpretation:**

Each output pixel is a weighted average of 4 input pixels:
$$I_{\text{out}} = c_1 I_1 + c_2 I_2 + c_3 I_3 + c_4 I_4$$

This convolution operation inherently smooths transitions between pixels, suppressing rapid intensity changes (high-frequency components).

#### Impact on Image Quality

**Aliasing Prevention:**
- Original sharp edges create high-frequency components
- Downsampling without filtering causes aliasing (false patterns)
- Bilinear's smoothing prevents aliasing by removing high-frequency content before downsampling

**Sharpness Trade-off:**
- **Before:** High-resolution crisp edges
- **After:** Slightly blurred edges, but smooth gradient transitions
- **Result:** Perceived softness without visible artifacts

### 2.5 Mathematical Comparison

#### Interpolation Error

**Nearest-Neighbor Error:**
$$E_{\text{NN}} = |I_{\text{true}}(r,c) - I_{\text{closest}}|$$
- Can be as large as the maximum gradient between adjacent pixels
- Discontinuous error function

**Bilinear Interpolation Error:**
$$E_{\text{linear}} = |I_{\text{true}}(r,c) - I_{\text{bilinear}}(r,c)|$$
- Bounded by the second-order Taylor expansion terms
- Maximum error ≈ $\frac{1}{8} \max(|f''(x)|)$ for smooth functions
- Continuous error distribution

**Conclusion:** Bilinear provides superior approximation for smooth intensity variations.

### 2.6 Edge Boundary Conditions

In our implementation, we handle edges by:

1. **Clamping:** Ensure interpolation indices stay within [1, M] and [1, N]
2. **Replicate:** When accessing pixels beyond boundaries, use the edge pixel value

```matlab
r1 = max(1, min(r1, H_orig));  % Clamp to valid range
c1 = max(1, min(c1, W_orig));
```

**Alternative Approaches:**
- **Zero-padding:** Assume black (0) pixels beyond boundary
- **Periodic wrapping:** Treat image as periodic
- **Mirror reflection:** Reflect pixel values at boundary

Our approach is **conservative** - prevents edge artifacts by using boundary values.

---

## Part 3: Algorithm Validation

### Validation Metrics

#### 1. Otsu's Thresholding
- **Threshold value comparison:** Should match MATLAB's `graythresh()` (within ±1 due to rounding)
- **Binary mask similarity:** >99% pixel match
- **Histogram distribution:** Visual inspection of bimodality

#### 2. Morphological Closing
- **Noise reduction:** Pepper noise should be eliminated
- **Object connectivity:** Nearby objects should be connected
- **Boundary preservation:** Object boundaries should remain recognizable
- **Comparison metric:** Pixel-wise match with built-in function >98%

#### 3. Bilinear Downsampling
- **MSE vs. MATLAB:** Should be <1.0 (implementation variations)
- **Correlation coefficient:** >0.99 with MATLAB implementation
- **Visual inspection:** No visible artifacts or discontinuities
- **Dimension verification:** Exactly 50% of original dimensions

### Performance Considerations

| Operation | Time Complexity | Space Complexity |
|-----------|-----------------|------------------|
| Otsu Histogram | O(M×N) | O(256) |
| Otsu Variance Search | O(256) | O(1) |
| Dilation/Erosion (3×3) | O(M×N) | O(M×N) |
| Bilinear Downsampling | O((M/2)×(N/2)) | O((M/2)×(N/2)) |

---

## Conclusions

### Part 1: Morphological Image Processing
1. **Otsu's method** provides automatic, optimal threshold selection based on histogram statistics
2. **Morphological closing** effectively removes salt-and-pepper noise while preserving object structure
3. The **sequence matters**: Dilation before erosion creates the desired hole-filling effect
4. Custom implementations validate understanding of underlying mathematical principles

### Part 2: Image Compression
1. **Bilinear interpolation** provides superior visual quality compared to nearest-neighbor
2. The **low-pass filtering** effect is both a feature and limitation:
   - **Feature:** Eliminates aliasing artifacts
   - **Limitation:** Reduces sharpness of fine details
3. **50% downsampling** reduces data by 75% while maintaining acceptable visual quality
4. Choice of interpolation method depends on application priorities (sharpness vs. smoothness)

### Practical Implications

**For Image Segmentation:**
- Use Otsu's method when automated, global thresholding is appropriate
- Apply morphological operations to enhance segmentation quality
- Combine techniques for robust object detection

**For Image Compression:**
- Bilinear interpolation is superior for general-purpose downsampling
- Consider content: bilinear for natural images, nearest-neighbor for diagrams/text
- Integrate with anti-aliasing filters for high-quality downsampling

---

## References

1. Otsu, N. (1979). "A threshold selection method from gray-level histograms"
2. Gonzalez & Woods (2018). "Digital Image Processing" (4th ed.)
3. Jain, R., Kasturi, R., & Schunck, B. G. (1995). "Machine Vision"
4. Keys, R. G. (1981). "Cubic convolution interpolation"

---

*Document created for BIM472 Image Processing Course*
*Implementation: Custom MATLAB algorithms with built-in function comparison*
