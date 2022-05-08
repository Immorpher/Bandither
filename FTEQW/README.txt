About Bandither 1.3
----------------------------------------------
Bandither is a non-linear "software-like" color banding and dithering shader. This does not use the specific palette, rather it quantizes each color channel which works well as an all-around shader.


Installation and Use
----------------------------------------------
To install this shader, move the "glsl" and "scripts" folder into the "id1" directory within the FTEQW directory. To use this shader, either add "r_postprocshader bandither" text to your fte.cfg or autoexec.cfg file, or when the game is loaded open the console with the "'" key and type the command in. This only works with OpenGL rendering with FTEQW

Within the "glsl" folder there is a "bandither.glsl" file which has options you can use to cusomize the shader:
"coloramt" is the amount of colors per channel (red,green,blue). The lower the number, the more more bands and less colors used. 
"bandcurve" is the amount to non-linearly skew banding. Higher numbers have smoother darks and band brights more, which is good for dark games.
"dithertype1" has eight styles of dithering: Bayer 2x2, Bayer 8x8, static noise, motion noise, scanline, checker, magic square, and grid dithering.
"dithertype2" also has eight styles of dithering: Bayer 2x2, Bayer 8x8, static noise, motion noise, scanline, checker, magic square, and grid dithering.
"ditherblend" is how much to blend first and second dithers from completely first (0) to completely second (1) and inbetween.
"ditherscale" is the pixel scale for dithering. Normally it should be 1, but if you are playing at a lower resolution, this may need to be increased to match pixel size.
"ditheramt" is the amount of dithering from 0 to 1, and inbetween. A value of 0 produces sharp color bands, while 1 is completely dithered.


Credits and Links
----------------------------------------------
Color banding learned from code by SolarLune on this topic: https://blenderartists.org/t/reducing-the-number-of-colors-color-depth/571154
Bayer dithering learned from code by hughsk: https://github.com/hughsk/glsl-dither
Noise dithering learned from this code: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
GZDoom implementation based on code from Molecicco and FTEQW implementation based on code from JaycieErysdren

Twitter: https://twitter.com/immorpher64
YouTube: https://www.youtube.com/c/Immorpher