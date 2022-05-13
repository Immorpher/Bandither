//
// Copyright(C) 2016-2017 Samuel Villarreal
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//

#include "progs/common.inc"

float coloramt = 7; // Color levels per channel (red,green,blue) plus 1 (black). The lower the number, the more more bands and less colors used. 
float bandcurve = 5; // Amount to non-linearly skew banding. Higher numbers have smoother darks and band brights more, which is good for dark games.
int dithertype1 = 1; // First dither: 0 for Bayer 2x2, 1 for Bayer 8x8, 2 for static noise, 3 for motion noise, 4 for scanline, 5 for checker, 6 for magic square, and 7 for grid dithering.
int dithertype2 = 3; // Second dither: 0 for Bayer 2x2, 1 for Bayer 8x8, 2 for static noise, 3 for motion noise, 4 for scanline, 5 for checker, 6 for magic square, and 7 for grid dithering.
float ditherblend = 0.2; // How much to blend first and second dithers from first (0) to second (1).
float ditheramt = 0.5; // Amount of dithering from 0 to 1, and inbetween. A value of 0 produces sharp color bands, while 1 is completely dithered.
int pixelscale = 2; // Pixel scale for dithering. Normally it should be 1, but if you are playing at a lower resolution, this may need to be increased to match pixel size.

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

// KEX DirectX modulo function
float modulo(float x, float y) {
	float mod = x - y * floor(x/y);
	return mod;
}

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
	float timer = 1; // fixed timer for now
	
	// Alternate oscillations
	wavenum = wavenum + sin(timer*vec2(34.9898,50.233));
	colornum = colornum + sin(timer*vec4(44.9808,15.638,66.3456,10.3563));
	
	// Get random number based on oscillating sine
    limit = fract((sin(dot(position,wavenum)+timer)+sin(brightness*colornum*timer))*23758.5453);
	
	return limit; // return limit
}

// Scanline dithering inspired by bayer style
vec4 scanline(vec2 position) {
	int y = int(modulo(position.y, 2.0)); // restrict to 2 pixel increments vertically
	float limit = 0.0; // comparison place holder value

	// define scanline array of 2 values
	float scanline[2];
	scanline[0] = 0.333;
	scanline[1] = 0.666;
	
	// Find and adjust the limit value to scale the dithering
	limit = scanline[y];
	
	return vec4(limit,limit,limit,limit); // return limits
}

// Checker 2x2 dither inspired by bayer 2x2
vec4 checker(vec2 position) {
	int x = int(modulo(position.x, 2.0)); // restrict to 2 pixel increments horizontally
	int y = int(modulo(position.y, 2.0)); // restrict to 2 pixel increments vertically
	int index = x + y * 2; // determine position in Bayer array
	float limit = 0.0; // comparison place holder value

	// define checker 2x2 array of 4 values
	float check[4];
	check[0] = 0.333;
	check[1] = 0.666;
	check[2] = 0.666;
	check[3] = 0.333;
	
	// Find and adjust the limit value to scale the dithering
	limit = check[index];
	
	return vec4(limit,limit,limit,limit); // return
}

// Grid 2x2 dither inspired by bayer 2x2
vec4 grid2x2(vec2 position) {
	int x = int(modulo(position.x, 2.0)); // restrict to 2 pixel increments horizontally
	int y = int(modulo(position.y, 2.0)); // restrict to 2 pixel increments vertically
	int index = x + y * 2; // determine position in Bayer array
	float limit = 0.0; // comparison place holder value

	// define grid 2x2 array of 4 values
	float grid[4];
	grid[0] = 0.75;
	grid[1] = 0.5;
	grid[2] = 0.5;
	grid[3] = 0.25;
	
	// Find and adjust the limit value to scale the dithering
	limit = grid[index];
	
	return vec4(limit,limit,limit,limit); // return
}

// Bayer 2x2 dither roughly adapted and corrected from: https://github.com/hughsk/glsl-dither
vec4 dither2x2(vec2 position) {
	int x = int(modulo(position.x, 2.0)); // restrict to 2 pixel increments horizontally
	int y = int(modulo(position.y, 2.0)); // restrict to 2 pixel increments vertically
	int index = x + y * 2; // determine position in Bayer array
	float limit = 0.0; // comparison place holder value

	// define bayer 2x2 array of 4 values
	float bayer[4];
	bayer[0] = 0.2;
	bayer[1] = 0.6;
	bayer[2] = 0.8;
	bayer[3] = 0.4;
	
	// Find and adjust the limit value to scale the dithering
	limit = bayer[index];
	
	return vec4(limit,limit,limit,limit); // return
}

// Magic Square 3x3 dither inspired by https://en.wikipedia.org/wiki/Magic_square
vec4 magic3x3(vec2 position) {
	int x = int(modulo(position.x, 3.0)); // restrict to 3 pixel increments horizontally
	int y = int(modulo(position.y, 3.0)); // restrict to 3 pixel increments vertically
	int index = x + y * 3; // determine position in magic square array
	float limit = 0.0; // comparison place holder value
	
	// define magic square 3x3 array of 9 values
	float magic[9];
	magic[0] = 0.2;
	magic[1] = 0.7;
	magic[2] = 0.6;
	magic[3] = 0.9;
	magic[4] = 0.5;
	magic[5] = 0.1;
	magic[6] = 0.4;
	magic[7] = 0.3;
	magic[8] = 0.8;
		
	// Find and adjust the limit value to scale the dithering
	limit = magic[index];
	
	return vec4(limit,limit,limit,limit); // return
}

// Bayer 8x8 dither roughly adapted from: https://github.com/hughsk/glsl-dither
vec4 dither8x8(vec2 position) {
	int x = int(modulo(position.x, 8.0)); // restrict to 8 pixel increments horizontally
	int y = int(modulo(position.y, 8.0)); // restrict to 8 pixel increments vertically
	int index = x + y * 8; // determine position in Bayer array
	float limit = 0.0; // comparison place holder value
	bvec4 compare = bvec4(0,0,0,0); // boolean vector for comparison of brightness vec4
	
	// define bayer 8x8 array of 64 values
	float bayer[64];
	bayer[0] = 0.0153846153846154;
	bayer[1] = 0.507692307692308;
	bayer[2] = 0.138461538461538;
	bayer[3] = 0.630769230769231;
	bayer[4] = 0.0461538461538462;
	bayer[5] = 0.538461538461538;
	bayer[6] = 0.169230769230769;
	bayer[7] = 0.661538461538462;
	bayer[8] = 0.753846153846154;
	bayer[9] = 0.261538461538462;
	bayer[10] = 0.876923076923077;
	bayer[11] = 0.384615384615385;
	bayer[12] = 0.784615384615385;
	bayer[13] = 0.292307692307692;
	bayer[14] = 0.907692307692308;
	bayer[15] = 0.415384615384615;
	bayer[16] = 0.2;
	bayer[17] = 0.692307692307692;
	bayer[18] = 0.0769230769230769;
	bayer[19] = 0.569230769230769;
	bayer[20] = 0.230769230769231;
	bayer[21] = 0.723076923076923;
	bayer[22] = 0.107692307692308;
	bayer[23] = 0.6;
	bayer[24] = 0.938461538461539;
	bayer[25] = 0.446153846153846;
	bayer[26] = 0.815384615384615;
	bayer[27] = 0.323076923076923;
	bayer[28] = 0.969230769230769;
	bayer[29] = 0.476923076923077;
	bayer[30] = 0.846153846153846;
	bayer[31] = 0.353846153846154;
	bayer[32] = 0.0615384615384615;
	bayer[33] = 0.553846153846154;
	bayer[34] = 0.184615384615385;
	bayer[35] = 0.676923076923077;
	bayer[36] = 0.0307692307692308;
	bayer[37] = 0.523076923076923;
	bayer[38] = 0.153846153846154;
	bayer[39] = 0.646153846153846;
	bayer[40] = 0.8;
	bayer[41] = 0.307692307692308;
	bayer[42] = 0.923076923076923;
	bayer[43] = 0.430769230769231;
	bayer[44] = 0.769230769230769;
	bayer[45] = 0.276923076923077;
	bayer[46] = 0.892307692307692;
	bayer[47] = 0.4;
	bayer[48] = 0.246153846153846;
	bayer[49] = 0.738461538461539;
	bayer[50] = 0.123076923076923;
	bayer[51] = 0.615384615384615;
	bayer[52] = 0.215384615384615;
	bayer[53] = 0.707692307692308;
	bayer[54] = 0.0923076923076923;
	bayer[55] = 0.584615384615385;
	bayer[56] = 0.984615384615385;
	bayer[57] = 0.492307692307692;
	bayer[58] = 0.861538461538462;
	bayer[59] = 0.369230769230769;
	bayer[60] = 0.953846153846154;
	bayer[61] = 0.461538461538462;
	bayer[62] = 0.830769230769231;
	bayer[63] = 0.338461538461539;

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
	// compare = greaterThan(c-cfloor,ditherlimit);
	compare.r = (c.r-cfloor.r) > ditherlimit.r;
	compare.g = (c.g-cfloor.g) > ditherlimit.g;
	compare.b = (c.b-cfloor.b) > ditherlimit.b;
	compare.a = (c.a-cfloor.a) > ditherlimit.a;
	
	// add dither
	c = cfloor + cceil*vec4(float(compare.r),float(compare.g),float(compare.b),float(compare.a));
	
	// return back to normal color space
	c /= colorbands; // Re-normalize to normal color space
	c = tan(c)/bandcurve; // Go back to linear color space
	
	return c;
}


def_sampler(2D, tBase, 0);

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
