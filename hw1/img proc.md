## BIM472 Image Processing Homework 1

### Part I: Using Matlab

**1. Describe the result of each of the following Matlab commands:**

**a.** 
">> x = randperm(50);"
* **Description:** Generates a 1x50 row vector x that contains a random permutation of the integers from 1 to 50. All numbers are different from eachother.

**b.** 
">> a = [1:2:10; 11:2:20]';"
">> b = a(2,:);"
* **Description:** The first one creates a 2x5 matrix. The first row is the numbers from 1 to 9 ([1, 3, 5, 7, 9]) and the second row being the numbers from 11 to 19 ([11, 13, 15, 17, 19]). The (') sign transposes the matrix. That operaiton turns it into a 5x2 matrix named "a". The second command extracts all elements of the second row of this transposed matrix "a" and assigns them to the variable "b". The resulting vector "b" will be [3, 13].

**c.** 
">> f = randn(10,2);"
">> g = f(find(f<1));"
* **Description:** The first one creates a 10x2 matrix named "f" filled with normally distributed random numbers. The second one finds the linear indices of all elements in "f" that are less than 1 using the "find" function. After that it extracts these elements and stores them in a new vector named "g".

**d.** 
">> x = 0.5 .* ones(1,10);"
">> y = 0.5 + zeros(1, length(x));"
">> z = x + y"
* **Description:** The first one creates a 1x10 vector "x" where every element is 0.5. The second command creates another 1x10 vector "y" by taking an array of zeros (the same length as "x" and that is 10) and adding 0.5 to each element. This operation creates an array identical to "x". The final command adds vectors "x" and "y" element-by-element. Because there is no semicolon at the end, it will print the result(1x10 vector named "z") to the Matlab command window.

**e.** 
">> a = [1: 100];"
">> b = a([end:- 1:1]);"
* **Description:** The first one creates a 1x100 vector named "a" that contains integers from 1 to 100 increments by one. The second one creates a new vector named "b" by indexing the elements of vector "a" starting from the last element ("end") to the first element ("1") with a step size of -1. Basically, vector "b" is the reversed version of the vector "a".

**2. Matrix Operations without Loops**

Assuming we are given a 100x100 matrix "A" representing a grayscale image.The following Matlab codes perform the requested operations without using loops.

**a. Plot all the intensities in A, sorted in decreasing value.**

plot(sort(A(: ), 'descend'));

**b. Create and display a new color image the same size as A, but with 3 channels to represent  R  G  and  B  values.  Set  the  values  to  be  bright  red  (i.e.,  R  =  255) wherever  the  intensity  in  A  is  greater  than  a  threshold  t,  and  black  everywhere else.**

color_img = zeros(100, 100, 3, 'uint8'); % Create a black RGB image of size 100x100x3.

color_img(:,:,1) = uint8(A > t) * 255;

imshow(color_img);

**c. Create a new image X that consists of the top left quadrant of A.**

X = A(1:50, 1:50); % Since A is 100x100 top left quadrant row and columns are 1x50

**d. Generate a new image, which is the same as A, but with A’s mean intensity value subtracted from each pixel**

new_A = double(A) - mean(A(: ));

**e. Let y be the vector: y = [1: 12]. Use the reshape command to form a new matrix z  whose  first  column  is  [1,  2,  3,  4]',  whose  second  column  is  [5,  6,  7,  8]'  and whose third column is [9, 10, 11, 12]'.**

y =;

z = reshape(y, 4, 3); % Reshaping this vector into 4 rows and 3 cloumns gives the requested matrix

**Let v be the vector: v = [1 8 8 2 1 3 9 8]. Set a new variable x to be the number of 8’s in the vector v.**

v = [1 8 8 2 1 3 9 8];

x = sum(v == 8);