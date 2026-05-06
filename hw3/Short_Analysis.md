# Short Analyses

## Part 1: Morphological Closing — Mathematical Explanation

Purpose: Fill small holes (pepper noise) and connect nearby objects.

- **Dilation:** Replace each pixel with the maximum value in its 3×3 neighborhood. This expands foreground (white) regions, filling small black holes and bridging nearby objects.
- **Erosion:** After dilation, replace each pixel with the minimum value in its 3×3 neighborhood. This restores object size by shrinking regions, while preserving bridges created during dilation.
- **Why the order matters:** If erosion is applied first, small objects or thin structures can be removed. Dilation first creates connections across small gaps; erosion then returns objects close to their original sizes while keeping those connections, effectively removing small holes without losing connectivity.
- **Mathematical view:** Dilation is a local maximum operator and erosion is a local minimum operator. Closing (dilation followed by erosion) eliminates small background gaps and preserves object connectivity.

## Part 2: Nearest-Neighbor vs. Bilinear — Mathematical Distinction and Effect

- **Nearest-Neighbor (NN):** Assigns the value of the nearest input pixel to each output pixel. It is computationally cheap and preserves original pixel values, but it produces blocky artifacts and aliasing (staircase effects) in downsampled images.

- **Bilinear:** Computes a weighted average of the four nearest input pixels:

  $$I(r,c) = (1-\Delta r)(1-\Delta c)Q_{11} + \Delta r(1-\Delta c)Q_{21} + (1-\Delta r)\Delta c\,Q_{12} + \Delta r\Delta c\,Q_{22},$$

  where $\Delta r,\Delta c$ are the fractional distances from the top-left neighbor. Bilinear interpolation produces a continuous, linearly varying estimate between samples.

- **Why bilinear acts as a low-pass filter:** Bilinear replaces each output pixel with a local weighted average of neighbors, which attenuates high-frequency components (rapid intensity changes). In the frequency domain, this averaging corresponds to suppression of high frequencies—i.e., a low-pass effect—reducing aliasing but softening sharp edges.

- **Visual trade-off:** Bilinear reduces aliasing and yields smoother, more natural-looking images at lower resolution, but edges become slightly blurred. NN preserves sharper edges but introduces blockiness and aliasing; hence bilinear is preferred for photographic content, while NN may be suitable for pixel-art or sharp graphics.