About Bandither 1.4
----------------------------------------------
Bandither is a non-linear color banding and dithering shader. It quantizes each color channel similar to 3D graphics hardware of the 1990's (Sega Saturn, Playstation 1, Nintendo 64, Voodoo 1/2) and can be skewed for darker games.


Installation and Use
----------------------------------------------
It is simpler to use Bandither on the Doom 64 Remaster with a program like ReShade, however the specific implementation here can be considered a proof of concept. To install this shader, if not using ReShade, edit the existing "Doom64.kpf" file in the Doom 64 Remaster folder. This can be done with any program which can edit ZIP files, such as SLADE. Replace the files in the "localization" and "progs" folders with the ones provided.

To change the Bandither settings, within the "progs" folder, edit the text of the "fxaa_fast.shader". You will find the following options:
"coloramt" is the amount of colors per channel (red,green,blue). The lower the number, the more more bands and less colors used. 
"bandcurve" is the amount to non-linearly skew banding. Higher numbers have smoother darks and band brights more, which is good for dark games.
"dithertype1" has eight styles of dithering: Bayer 2x2, Bayer 8x8, static noise, motion noise, scanline, checker, magic square, and grid dithering.
"dithertype2" also has eight styles of dithering: Bayer 2x2, Bayer 8x8, static noise, motion noise, scanline, checker, magic square, and grid dithering.
"ditherblend" is how much to blend first and second dithers from completely first (0) to completely second (1) and inbetween.
"ditheramt" is the amount of dithering from 0 to 1, and inbetween. A value of 0 produces sharp color bands, while 1 is completely dithered.
"pixelscale" is the pixel size on screen to lower resolution. Ideally this is best done with an engine setting if the engine offers it.

To apply these options, the shader must be recompiled. To do this you must edit the "kexengine.cfg" file, which is in the "\Saved Games\Nightdive Studios\DOOM 64\" directory of the windows user folder. Here change 'seta developer "0"' to 'seta developer "1"' and 'vk_compileShaders "0"' to 'vk_compileShaders "1"'. Next time you start Doom 64, it will compile the shader with your settings. I find it will compile it to run in the OpenGL video mode but not Vulkan video mode. If you get it to compile in Vulkan or Direct X, let me know!

Finally, your anti-aliasing menu will now be a "Shader" menu which you can now select Bandither as one of the options.


Credits and Links
----------------------------------------------
Color banding learned from code by SolarLune on this topic: https://blenderartists.org/t/reducing-the-number-of-colors-color-depth/571154
Bayer dithering learned from code by hughsk: https://github.com/hughsk/glsl-dither
Noise dithering learned from this code: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
GZDoom implementation based on code from Molecicco, FTEQW implementation based on code from JaycieErysdren, and KEX engine implementation based on code from Kaiser.

Twitter: https://twitter.com/immorpher64
YouTube: https://www.youtube.com/c/Immorpher