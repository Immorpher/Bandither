// ---------------------------------------------------------------------
// About Bandither 1.4

// Bandither is a non-linear color banding and dithering shader. It quantizes each color channel similar to 3D graphics hardware of the 1990's (Sega Saturn, Playstation 1, Nintendo 64, Voodoo 1/2) and can be skewed for darker games.
// See user defined values section to customize this shader and learn more about its capabilities. The effects are enhanced if you pair this with increased pixel sizes.

// Color banding learned from code by SolarLune on this topic: https://blenderartists.org/t/reducing-the-number-of-colors-color-depth/571154
// Bayer dithering learned from code by hughsk: https://github.com/hughsk/glsl-dither
// Noise dithering learned from this code: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
// GZDoom implementation based on code from Molecicco, FTEQW implementation based on code from JaycieErysdren, and KEX engine implementation based on code from Kaiser.
// Twitter: https://twitter.com/immorpher64
// YouTube: https://www.youtube.com/c/Immorpher


// --------------------------------------------------------------------
// Header data for reshade

// Get Reshade definitions
#include "ReShade.fxh"

// Sample the screen
sampler Linear
{
	Texture = ReShade::BackBufferTex;
	SRGBTexture = true;
};

// Grab time
uniform float Timer < source = "timer"; >;


// ---------------------------------------------------------------------
// User defined values for UI

uniform int coloramt < 
	ui_type = "slider";
	ui_min = 1; ui_max = 31;
	ui_label = "Color Levels";
	ui_tooltip = "Color levels per channel (red,green,blue) plus 1 (black). The lower the number, the more more bands and less colors used.";
> = 7;

uniform float bandcurve < 
	ui_type = "slider";
	ui_min = 0.001; ui_max = 10;
	ui_label = "Banding Curve";
	ui_tooltip = "Amount to non-linearly skew banding. Higher numbers have smoother darks and band brights more, which is good for dark games.";
> = 5;

uniform int dithertype1 <
	ui_type = "combo";
	ui_tooltip = "First dither type.";
	ui_label = "First Dither";
	ui_items = "Bayer 2x2\0"
	           "Bayer 8x8\0"
	           "Static Noise\0"
	           "Motion Noise\0"
	           "Scanline\0"
	           "Checker\0"
	           "Magic Square\0"
	           "Grid\0";
> = 1;

uniform int dithertype2 <
	ui_type = "combo";
	ui_tooltip = "Second dither type.";
	ui_label = "Second Dither";
	ui_items = "Bayer 2x2\0"
	           "Bayer 8x8\0"
	           "Static Noise\0"
	           "Motion Noise\0"
	           "Scanline\0"
	           "Checker\0"
	           "Magic Square\0"
	           "Grid\0";
> = 3;

uniform float ditherblend < 
	ui_type = "slider";
	ui_min = 0; ui_max = 1;
	ui_label = "Dither Blend";
	ui_tooltip = "How much to blend first and second dithers from first (0) to second (1).";
> = 0.2;

uniform float ditheramt < 
	ui_type = "slider";
	ui_min = 0; ui_max = 1;
	ui_label = "Dither Amount";
	ui_tooltip = "Amount of dithering from 0 to 1, and inbetween. A value of 0 produces sharp color bands, while 1 is completely dithered.";
> = 0.5;

uniform int pixelscale < 
	ui_type = "slider";
	ui_min = 1; ui_max = 10;
	ui_label = "Pixel Scale";
	ui_tooltip = "Pixel size on screen to lower resolution. Ideally this is best done with an engine setting if the engine offers it.";
> = 2;


// ---------------------------------------------------------------------
// Dithering functions

// definite modulo operator for hlsl, since online documentation aint great
float modulo(float x, float y) {
	return x - y * trunc(x/y);
}

// Static noise based dither roughly learned from: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
float4 staticnoise(float2 position){ 
	float limit = 0.0; // dither on or off
	float2 wavenum = float2(12.9898,78.233); // screen position noise
	
	// Get random number based on oscillating sine
    limit = frac(sin(dot(position,wavenum))*23758.5453);
	
	return float4(limit,limit,limit,limit); // return as float4
}

// Motion noise based dither roughly learned from: https://stackoverflow.com/questions/12964279/whats-the-origin-of-this-glsl-rand-one-liner
float4 motionnoise(float2 position, float4 brightness){ 
	float4 limit = float4(0,0,0,0); // dither on or off
	float2 wavenum = float2(12.9898,78.233); // screen position noise
	float4 colornum = float4(34.5345,67.5355,11.42455,83.7547); // color value noise
	
	// Alternate oscillations
	wavenum = wavenum + sin(Timer*float2(34.9898,50.233));
	colornum = colornum + sin(Timer*float4(44.9808,15.638,66.3456,10.3563));
	
	// Get random number based on oscillating sine
    limit = frac((sin(dot(position,wavenum)+Timer)+sin(brightness*colornum*Timer))*23758.5453);
	
	return limit; // return limit
}

// Scanline dithering inspired by bayer style
float4 scanline(float2 position) {
	int y = int(modulo(position.y, 2.0)); // restrict to 2 pixel increments vertically
	float limit = 0.0; // comparison place holder value

	// define scanline array of 2 values
	float scanline[2];
	scanline[0] = 0.333;
	scanline[1] = 0.666;
	
	// Find and adjust the limit value to scale the dithering
	limit = scanline[y];
	
	return float4(limit,limit,limit,limit); // return limits
}

// Checker 2x2 dither inspired by bayer 2x2
float4 checker(float2 position) {
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
	
	return float4(limit,limit,limit,limit); // return
}

// Grid 2x2 dither inspired by bayer 2x2
float4 grid2x2(float2 position) {
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
	
	return float4(limit,limit,limit,limit); // return
}

// Bayer 2x2 dither roughly adapted and corrected from: https://github.com/hughsk/glsl-dither
float4 dither2x2(float2 position) {
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
	
	return float4(limit,limit,limit,limit); // return
}

// Magic Square 3x3 dither inspired by https://en.wikipedia.org/wiki/Magic_square
float4 magic3x3(float2 position) {
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
	
	return float4(limit,limit,limit,limit); // return
}

// Bayer 8x8 dither roughly adapted from: https://github.com/hughsk/glsl-dither
float4 dither8x8(float2 position) {
	int x = int(modulo(position.x, 8.0)); // restrict to 8 pixel increments horizontally
	int y = int(modulo(position.y, 8.0)); // restrict to 8 pixel increments vertically
	int index = x + y * 8; // determine position in Bayer array
	float limit = 0.0; // comparison place holder value
	bool4 compare = bool4(0,0,0,0); // boolean vector for comparison of brightness float4
	
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
	
	return float4(limit,limit,limit,limit); // return
}


// ---------------------------------------------------------------------
// Color banding with addition of dither

// Color quantization learned from: https://blenderartists.org/t/reducing-the-number-of-colors-color-depth/571154
float4 colround(float4 vpos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
{
	float2 position = floor(texcoord.xy*BUFFER_SCREEN_SIZE/pixelscale);
	float4 color = tex2D(ReShade::BackBuffer, (position*pixelscale+floor(pixelscale*0.5))/BUFFER_SCREEN_SIZE).rgba;
	float4 c = color;
	float colorbands = coloramt/atan(bandcurve); // normalize color level value by band curve adjustment
	float4 ditherlimit = float4(0,0,0,0); // dither probability vector
	bool4 compare = bool4(0,0,0,0); // boolean vector for comparison of dither limit vector
	
	// apply non-linear banding
	c *= bandcurve; // adjust for non-linear scaling
	c = atan(c); // non-linear scale the colors before banding	
	
	c *= colorbands; // Multiply the vector by the color level value for banding
	
	// round colors to bands
	float4 cfloor = floor(c); // round down to lowest band
	float4 cceil = ceil(c)-floor(c); // round up to higher band
	
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
	c = cfloor + cceil*float4(float(compare.r),float(compare.g),float(compare.b),float(compare.a));
	
	// return back to normal color space
	c /= colorbands; // Re-normalize to normal color space
	c = tan(c)/bandcurve; // Go back to linear color space
	
	return c;
}

// Main loop
technique Bandither
{
	pass
	{
		VertexShader = PostProcessVS;
		PixelShader = colround;
	}
}