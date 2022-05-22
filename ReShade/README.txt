About Bandither 1.4
----------------------------------------------
Bandither is a non-linear color banding and dithering shader. It quantizes each color channel similar to 3D graphics hardware of the 1990's (Sega Saturn, Playstation 1, Nintendo 64, Voodoo 1/2) and can be skewed for darker games.


Installation and Use
----------------------------------------------
To use the shader first install ReShade onto your game/software of choice. Then in the "\reshade-shaders\Shaders\" directory of the program, add the "Bandither.fx" file. When you load your program, ReShade should also load which will give you instructions on how to set it up. Bandither.fx will now be one of the options. When selected you will find the following options:

"Color Levels" is the amount of colors per channel (red,green,blue). The lower the number, the more more bands and less colors used. 
"Banding Curve" is the amount to non-linearly skew banding. Higher numbers have smoother darks and band brights more, which is good for dark games.
"First Dither" has eight styles of dithering: Bayer 2x2, Bayer 8x8, static noise, motion noise, scanline, checker, magic square, and grid dithering.
"Second Dither" also has eight styles of dithering: Bayer 2x2, Bayer 8x8, static noise, motion noise, scanline, checker, magic square, and grid dithering.
"Dither Blend" is how much to blend first and second dithers from completely first (0) to completely second (1) and inbetween.
"Dither Amount" is the amount of dithering to use. A value of 0 produces sharp color bands, while 1 is completely dithered.
"Pixel Scale" is the pixel scale for dithering. Normally it should be 1, but if you are playing at a lower resolution, this may need to be increased to match pixel size.


Credits and Links
----------------------------------------------
Color banding learned from code by SolarLune on this topic: https://blenderartists.org/t/reducing-the-number-of-colors-color-depth/571154
Bayer dithering learned from code by hughsk: https://github.com/hughsk/glsl-dither
Noise dithering learned from this code: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
GZDoom implementation based on code from Molecicco, FTEQW implementation based on code from JaycieErysdren, and KEX engine implementation based on code from Kaiser.

Twitter: https://twitter.com/immorpher64
YouTube: https://www.youtube.com/c/Immorpher