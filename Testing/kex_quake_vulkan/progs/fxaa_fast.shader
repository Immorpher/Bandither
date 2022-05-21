// ---------------------------------------------------------------------
// About Bandither 1.4

// This is a testing shader for the KEX engine to test in Vulkan mode. It currently does not work.
// Bandither is a non-linear color banding and dithering shader. It quantizes each color channel similar to 3D graphics hardware of the 1990's (Sega Saturn, Playstation 1, Nintendo 64, Voodoo 1/2) and can be skewed for darker games.
// See user defined values section to customize this shader and learn more about its capabilities. The effects are enhanced if you pair this with increased pixel sizes.

// Color banding learned from code by SolarLune on this topic: https://blenderartists.org/t/reducing-the-number-of-colors-color-depth/571154
// Bayer dithering learned from code by hughsk: https://github.com/hughsk/glsl-dither
// Noise dithering learned from this code: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
// GZDoom implementation based on code from Molecicco, FTEQW implementation based on code from JaycieErysdren, and KEX engine implementation based on code from Kaiser.
// Twitter: https://twitter.com/immorpher64
// YouTube: https://www.youtube.com/c/Immorpher

#include "progs/common.inc"

// ---------------------------------------------------------------------
// User defined values

float coloramt = 7; // Color levels per channel (red,green,blue) plus 1 (black). The lower the number, the more more bands and less colors used. 
float bandcurve = 5; // Amount to non-linearly skew banding. Higher numbers have smoother darks and band brights more, which is good for dark games.
int dithertype1 = 1; // First dither: 0 for Bayer 2x2, 1 for Bayer 8x8, 2 for static noise, 3 for motion noise, 4 for scanline, 5 for checker, 6 for magic square, and 7 for grid dithering.
int dithertype2 = 3; // Second dither: 0 for Bayer 2x2, 1 for Bayer 8x8, 2 for static noise, 3 for motion noise, 4 for scanline, 5 for checker, 6 for magic square, and 7 for grid dithering.
float ditherblend = 0.2; // How much to blend first and second dithers from first (0) to second (1).
float ditheramt = 0.5; // Amount of dithering from 0 to 1, and inbetween. A value of 0 produces sharp color bands, while 1 is completely dithered.
int pixelscale = 2; // Pixel size on screen to lower resolution. Ideally this is best done with an engine setting if the engine offers it.


// ---------------------------------------------------------------------
// Header stuffs from Kaiser

#ifdef SHADER_VERTEX

	//----------------------------------------------------
	// input
	begin_input(inVertex)
		var_attrib(ATTRIB_POSITION, vec3);
		var_attrib(ATTRIB_TEXCOORD, vec2);
		var_attrib(ATTRIB_COLOR, vec4);
	end_input

	//----------------------------------------------------
	// output
	begin_output(outVertex)
		def_var_outPosition(position)
		def_var_out(vec2, out_texcoord, TEXCOORD0)
		def_var_out(vec4, out_color,    COLOR0)
	end_output

	//----------------------------------------------------
	shader_main(outVertex, inVertex, input)
	{
		declareOutVar(outVertex, output)
		
		vec4 vertex                         = vec4(inVarAttrib(ATTRIB_POSITION, input), 1.0);
		outVarPosition(output, position)    = mul(uProjectionMatrix, mul(uModelViewMatrix, vertex));
		outVar(output, out_texcoord)        = inVarAttrib(ATTRIB_TEXCOORD, input);
		outVar(output, out_color)           = inVarAttrib(ATTRIB_COLOR, input);
		
		outReturn(output)
	}

#endif

#ifdef SHADER_PIXEL

	//----------------------------------------------------
	// input
	begin_input(outVertex)
		def_var_position(position)
		def_var_in(vec2, out_texcoord, TEXCOORD0)
		def_var_in(vec4, out_color,    COLOR0)
	end_input

	//----------------------------------------------------
	// output
	begin_output(outPixel)
		def_var_fragment(fragment)
	end_output
	

	// ---------------------------------------------------------------------
	// Dithering functions

	// Static noise based dither roughly learned from: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
	vec4 staticnoise(vec2 position){ 
		float limit = 0.0; // dither on or off
		vec2 wavenum = vec2(12.9898,78.233); // screen position noise
		
		// Get random number based on oscillating sine
		limit = fract(sin(dot(position,wavenum))*23758.5453);
		
		return vec4(limit,limit,limit,limit); // return as vec4
	}

	// Motion noise based dither roughly learned from: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
	vec4 motionnoise(vec2 position, vec4 brightness){ 
		vec4 limit = vec4(0,0,0,0); // dither on or off
		vec2 wavenum = vec2(12.9898,78.233); // screen position noise
		vec4 colornum = vec4(34.5345,67.5355,11.42455,83.7547); // color value noise
		
		// Get random number based on oscillating sine
		limit = fract((sin(dot(position,wavenum))+sin(brightness*colornum))*23758.5453);
		
		return limit; // return limit
	}

	// Scanline dithering inspired by bayer style
	vec4 scanline(vec2 position) {
		int y = int(mod(position.y, 2.0)); // restrict to 2 pixel increments vertically
		float limit = 0.0; // comparison place holder value

		// define scanline array of 2 values
		float scanline[2] = float[2](0.333,0.666);
		
		// Find and adjust the limit value to scale the dithering
		limit = scanline[y];
		
		return vec4(limit,limit,limit,limit); // return limits
	}

	// Checker 2x2 dither inspired by bayer 2x2
	vec4 checker(vec2 position) {
		int x = int(mod(position.x, 2.0)); // restrict to 2 pixel increments horizontally
		int y = int(mod(position.y, 2.0)); // restrict to 2 pixel increments vertically
		int index = x + y * 2; // determine position in Bayer array
		float limit = 0.0; // comparison place holder value

		// define checker 2x2 array of 4 values
		float check[4] = float[4](0.333,0.666,0.666,0.333);
		
		// Find and adjust the limit value to scale the dithering
		limit = check[index];
		
		return vec4(limit,limit,limit,limit); // return
	}

	// Grid 2x2 dither inspired by bayer 2x2
	vec4 grid2x2(vec2 position) {
		int x = int(mod(position.x, 2.0)); // restrict to 2 pixel increments horizontally
		int y = int(mod(position.y, 2.0)); // restrict to 2 pixel increments vertically
		int index = x + y * 2; // determine position in Bayer array
		float limit = 0.0; // comparison place holder value

		// define grid 2x2 array of 4 values
		float grid[4] = float[4](0.75,0.5,0.5,0.25);
		
		// Find and adjust the limit value to scale the dithering
		limit = grid[index];
		
		return vec4(limit,limit,limit,limit); // return
	}

	// Bayer 2x2 dither roughly adapted and corrected from: https://github.com/hughsk/glsl-dither
	vec4 dither2x2(vec2 position) {
		int x = int(mod(position.x, 2.0)); // restrict to 2 pixel increments horizontally
		int y = int(mod(position.y, 2.0)); // restrict to 2 pixel increments vertically
		int index = x + y * 2; // determine position in Bayer array
		float limit = 0.0; // comparison place holder value

		// define bayer 2x2 array of 4 values
		float bayer[4] = float[4](0.2,0.6,0.8,0.4);
		
		// Find and adjust the limit value to scale the dithering
		limit = bayer[index];
		
		return vec4(limit,limit,limit,limit); // return
	}

	// Magic Square 3x3 dither inspired by https://en.wikipedia.org/wiki/Magic_square
	vec4 magic3x3(vec2 position) {
		int x = int(mod(position.x, 3.0)); // restrict to 3 pixel increments horizontally
		int y = int(mod(position.y, 3.0)); // restrict to 3 pixel increments vertically
		int index = x + y * 3; // determine position in magic square array
		float limit = 0.0; // comparison place holder value
		
		// define magic square 3x3 array of 9 values
		float magic[9] = float[9](0.2,0.7,0.6,0.9,0.5,0.1,0.4,0.3,0.8);
			
		// Find and adjust the limit value to scale the dithering
		limit = magic[index];
		
		return vec4(limit,limit,limit,limit); // return
	}

	// Bayer 8x8 dither roughly adapted from: https://github.com/hughsk/glsl-dither
	vec4 dither8x8(vec2 position) {
		int x = int(mod(position.x, 8.0)); // restrict to 8 pixel increments horizontally
		int y = int(mod(position.y, 8.0)); // restrict to 8 pixel increments vertically
		int index = x + y * 8; // determine position in Bayer array
		float limit = 0.0; // comparison place holder value
		bvec4 compare = bvec4(0,0,0,0); // boolean vector for comparison of brightness vec4
		
		// define bayer 8x8 array of 64 values
		float bayer[64] = float[64](0.01538461538,0.5076923077,0.1384615385,0.6307692308,0.04615384615,0.5384615385,0.1692307692,0.6615384615,0.7538461538,0.2615384615,0.8769230769,0.3846153846,0.7846153846,0.2923076923,0.9076923077,0.4153846154,0.2,0.6923076923,0.07692307692,0.5692307692,0.2307692308,0.7230769231,0.1076923077,0.6,0.9384615385,0.4461538462,0.8153846154,0.3230769231,0.9692307692,0.4769230769,0.8461538462,0.3538461538,0.06153846154,0.5538461538,0.1846153846,0.6769230769,0.03076923077,0.5230769231,0.1538461538,0.6461538462,0.8,0.3076923077,0.9230769231,0.4307692308,0.7692307692,0.2769230769,0.8923076923,0.4,0.2461538462,0.7384615385,0.1230769231,0.6153846154,0.2153846154,0.7076923077,0.09230769231,0.5846153846,0.9846153846,0.4923076923,0.8615384615,0.3692307692,0.9538461538,0.4615384615,0.8307692308,0.3384615385);
		
		// Find and adjust the limit value to scale the dithering
		limit = bayer[index];
		
		return vec4(limit,limit,limit,limit); // return
	}


	// ---------------------------------------------------------------------
	// Color banding with addition of dither

	// Color quantization learned from: https://blenderartists.org/t/reducing-the-number-of-colors-color-depth/571154
	vec4 colround(vec2 position, vec4 color){ // Rounding function
		vec4 c = color;
		float colorbands = coloramt/atan(bandcurve); // normalize color level value by band curve adjustment
		vec4 ditherlimit = vec4(0,0,0,0); // dither probability vector
		bvec4 compare = bvec4(0,0,0,0); // boolean vector for comparison of dither limit vector
		
		// apply non-linear banding
		c *= bandcurve; // adjust for non-linear scaling
		c = atan(c); // non-linear scale the colors before banding	
		
		c *= colorbands; // Multiply the vector by the color level value for banding
		
		// round colors to bands
		vec4 cfloor = floor(c); // round down to lowest band
		vec4 cceil = ceil(c)-floor(c); // round up to higher band
		
		// determine first dither probability
		if (dithertype1 == 0) { // Bayer 2x2 dither
			ditherlimit = dither2x2(position);
		} else if (dithertype1 == 1) { // Bayer 8x8 dither
			ditherlimit = dither8x8(position);
		} else if (dithertype1 == 2) { // Static noise dither
			ditherlimit = staticnoise(position);
		} else if (dithertype1 == 3) { // Motion dither
			ditherlimit = motionnoise(position,c-cfloor);
		} else if (dithertype1 == 4) { // Scanline dither
			ditherlimit = scanline(position);
		} else if (dithertype1 == 5) { // Checker dither
			ditherlimit = checker(position);
		} else if (dithertype1 == 6) { // Magic square dither
			ditherlimit = magic3x3(position);
		} else { // Grid Dither
			ditherlimit = grid2x2(position);
		}
		
		ditherlimit = ditherlimit*(1-ditherblend); // adjust first dither
		
		// determine second dither probability
		if (dithertype2 == 0) { // Bayer 2x2 dither
			ditherlimit = ditherlimit + ditherblend*dither2x2(position);
		} else if (dithertype2 == 1) { // Bayer 8x8 dither
			ditherlimit = ditherlimit + ditherblend*dither8x8(position);
		} else if (dithertype2 == 2) { // Static noise dither
			ditherlimit = ditherlimit + ditherblend*staticnoise(position);
		} else if (dithertype2 == 3) { // Motion dither
			ditherlimit = ditherlimit + ditherblend*motionnoise(position,c-cfloor);
		} else if (dithertype2 == 4) { // Scanline dither
			ditherlimit = ditherlimit + ditherblend*scanline(position);
		} else if (dithertype2 == 5) { // Checker dither
			ditherlimit = ditherlimit + ditherblend*checker(position);
		} else if (dithertype2 == 6) { // Magic square dither
			ditherlimit = ditherlimit + ditherblend*magic3x3(position);
		} else { // Grid Dither
			ditherlimit = ditherlimit + ditherblend*grid2x2(position);
		}
		
		// Adjust dither amount based on 0.5 for rounding
		ditherlimit = ditheramt*ditherlimit + (1-ditheramt)*0.5; // 0.5 is for rounding up or down
		
		// determine which color values to quantize up for dithering
		compare = greaterThan(c-cfloor,ditherlimit);
		
		// add dither
		c = cfloor + cceil*vec4(float(compare.r),float(compare.g),float(compare.b),float(compare.a));
		
		// return back to normal color space
		c /= colorbands; // Re-normalize to normal color space
		c = tan(c)/bandcurve; // Go back to linear color space
		
		return c;
	}

	def_sampler(2D, tQuakeImage, 0);

	//----------------------------------------------------
	shader_main(outPixel, outVertex, input)
	{
		declareOutVar(outPixel, output)
		vec2 coordinates = floor(inVar(input, out_texcoord)*ScreenSize()/pixelscale); // reduced coordinates based on pixel scale
		
		vec4 frag = sampleLevelZero(tBase, (coordinates*pixelscale+floor(pixelscale*0.5))/ScreenSize()); // try to select middle pixel
		
		outVarFragment(output, fragment) = colround(coordinates, frag);
		outReturn(output)
	}

#endif
