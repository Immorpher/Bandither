# Bandither
Bandither is a non-linear "software-like" color banding and dithering shader for GZDoom and FTEQW. This does not use the specific palette, rather it non-linearly quantizes each color channel which works well as an all-around shader for darker games.

# GZDoom Instructions (https://zdoom.org/downloads)
To use the shader you can load it like any other WAD into GZDoom, where you can drag and drop it onto the program, or use a launcher like ZDL.  
  
If you click on "Full options menu" in the GZDoom options menu, you will find these specific "Bandither" options  
"Color Levels" is the amount of colors per channel (red,green,blue). The lower the number, the more more bands and less colors used.  
"Banding Curve" is the amount to non-linearly skew banding. Higher numbers have smoother darks and band brights more, which is good for dark games.  
"Dither Style" has five styles of dithering which are: Bayer 2x2, Bayer 8x8, static noise, motion noise, and scanline dithering.  
"Dither Level" is the amount of dithering to use. A value of 0 produces sharp color bands, while 1 is completely dithered.  
"Dither Scale" is the pixel scale for dithering. Normally it should be 1, but if you are playing at a lower resolution, this may need to be increased to match pixel size.  

# FTEQW Instructions (https://fte.triptohell.info/)
To install this shader, move the "glsl" and "scripts" folder into the "id1" directory within the FTEQW directory. To use this shader, either add "r_postprocshader bandither" text to your fte.cfg or autoexec.cfg file, or when the game is loaded open the console with the "'" key and type the command in. This only works with OpenGL rendering with FTEQW.  
  
Within the "glsl" folder there is a "bandither.glsl" file which has options you can use to cusomize the shader:  
"coloramt" is the amount of colors per channel (red,green,blue). The lower the number, the more more bands and less colors used.  
"bandcurve" is the amount to non-linearly skew banding. Higher numbers have smoother darks and band brights more, which is good for dark games.  
"ditheramt" is the amount of dithering from 0 to 1, and inbetween. A value of 0 produces sharp color bands, while 1 is completely dithered.  
"ditherscale" is the pixel scale for dithering. Normally it should be 1, but if you are playing at a lower resolution, this may need to be increased to match pixel size.  
"dithertype" has five styles of dithering which include: Bayer 2x2, Bayer 8x8, static noise, motion noise, and scanline dithering.  

# Credits and Links  
Color banding learned from code by SolarLune on this topic: https://blenderartists.org/t/reducing-the-number-of-colors-color-depth/571154  
Bayer dithering learned from code by hughsk: https://github.com/hughsk/glsl-dither  
Noise dithering learned from this code: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner  
GZDoom implementation based on code from Molecicco and FTEQW implementation based on code from JaycieErysdren  
  
Twitter: https://twitter.com/immorpher64  
YouTube: https://www.youtube.com/c/Immorpher  
