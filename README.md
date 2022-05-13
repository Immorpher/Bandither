# Bandither
Bandither is a non-linear color banding and dithering shader. It quantizes each color channel similar to 3D graphics hardware of the 1990's (Sega Saturn, Playstation 1, Nintendo 64, Voodoo 1/2) and can be skewed for darker games.

# GZDoom Instructions (https://zdoom.org/downloads)
To use the shader you can load it like any other WAD into GZDoom, where you can drag and drop it onto the program, or use a launcher like ZDL.  
  
If you click on "Full options menu" in the GZDoom options menu, you will find these specific "Bandither" options  
"Color Levels" is the amount of colors per channel (red,green,blue). The lower the number, the more more bands and less colors used.  
"Banding Curve" is the amount to non-linearly skew banding. Higher numbers have smoother darks and band brights more, which is good for dark games.  
"First Dither" has 8 styles of dithering which are: Bayer 2x2, Bayer 8x8, static noise, motion noise, scanline, checker, magic square, and grid dithering.  
"Second Dither" also has 8 styles of dithering which are: Bayer 2x2, Bayer 8x8, static noise, motion noise, scanline, checker, magic square, and grid dithering.  
"Dither Blend" is how much to blend first and second dithers from completely first (0) to completely second (1) and inbetween.  
"Dither Level" is the amount of dithering to use. A value of 0 produces sharp color bands, while 1 is completely dithered.  
"Dither Scale" is the pixel scale for dithering. Normally it should be 1, but it can produce interesting effects at large values.  

# FTEQW Instructions (https://fte.triptohell.info/)
To install this shader, move the "glsl" and "scripts" folder into the "id1" directory within the FTEQW directory. To use this shader, either add "r_postprocshader bandither" text to your fte.cfg, autoexec.cfg file, or when the game is loaded open the console with the "'" key and type the command in. This only works with OpenGL rendering with FTEQW  

Once the shader is loaded in FTEQW you can use these console variables to cusomize the shader:  
r_band_coloramt is the color levels per channel (red,green,blue) plus 1 (black). The lower the number, the more more bands and less colors used.  
r_band_bandcurve is the amount to non-linearly skew banding. Higher numbers have smoother darks and band brights more, which is good for dark games.  
r_band_dithertype1 is the first dither style: 0 for Bayer 2x2, 1 for Bayer 8x8, 2 for static noise, 3 for motion noise, 4 for scanline, 5 for checker, 6 for magic square, and 7 for grid dithering.  
r_band_dithertype2 is the second dither style: 0 for Bayer 2x2, 1 for Bayer 8x8, 2 for static noise, 3 for motion noise, 4 for scanline, 5 for checker, 6 for magic square, and 7 for grid dithering.  
r_band_ditherblend is how much to blend first and second dithers from first (0) to second (1).  
r_band_ditheramt is the amount of dithering from 0 to 1, and inbetween. A value of 0 produces sharp color bands, while 1 is completely dithered.  
r_band_pixelscale is the pixel scale of the dithering. Set r_renderscale -1/pixelscale in FTEQW console to match screen resolution.  

# Credits and Links  
Color banding learned from code by SolarLune on this topic: https://blenderartists.org/t/reducing-the-number-of-colors-color-depth/571154  
Bayer dithering learned from code by hughsk: https://github.com/hughsk/glsl-dither  
Noise dithering learned from this code: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner  
GZDoom implementation based on code from Molecicco, FTEQW implementation based on code from JaycieErysdren, and KEX engine implementation based on code from Kaiser.  
  
Twitter: https://twitter.com/immorpher64  
YouTube: https://www.youtube.com/c/Immorpher  
