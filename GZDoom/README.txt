About Bandither 1.1
----------------------------------------------
Bandither is a non-linear "software-like" color banding and dithering shader by Immorpher. This does not use the specific palette, rather it quantizes each color channel which works well as an all-around shader.


Installation and Use
----------------------------------------------
To use the shader you can load it like any other WAD into GZDoom, where you can drag and drop it onto the program, or use a launcher like ZDL.

If you click on "Full options menu" in the GZDoom options menu, you will find these specific "Bandither" options
"Color Levels" is the amount of colors per channel (red,green,blue). The lower the number, the more more bands and less colors used. 
"Banding Curve" is the amount to non-linearly skew banding. Higher numbers have smoother darks and band brights more, which is good for dark games.
"Dither Style" has five styles of dithering which are: Bayer 2x2, Bayer 8x8, static noise, motion noise, and scanline dithering.
"Dither Level" is the amount of dithering to use. A value of 0 produces sharp color bands, while 1 is completely dithered.
"Dither Scale" is the pixel scale for dithering. Normally it should be 1, but if you are playing at a lower resolution, this may need to be increased to match pixel size.


Credits and Links
----------------------------------------------
Color banding learned from code by SolarLune on this topic: https://blenderartists.org/t/reducing-the-number-of-colors-color-depth/571154
Bayer dithering learned from code by hughsk: https://github.com/hughsk/glsl-dither
Noise dithering learned from this code: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
GZDoom implementation based on code from Molecicco and FTEQW implementation based on code from JaycieErysdren

Twitter: https://twitter.com/immorpher64
YouTube: https://www.youtube.com/c/Immorpher