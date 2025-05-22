shader_type spatial;
render_mode specular_disabled, ambient_light_disabled;

uniform sampler2D DEPTH_TEXTURE : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;
uniform sampler2D NORMAL_TEXTURE : hint_normal_roughness_texture, filter_nearest;

uniform float lightIntensity = 1.25;
uniform float lineAlpha = 0.7;
uniform bool useLighting = true;
uniform float lineHighlight = 0.2;
uniform float lineShadow = 0.55;

varying vec2 screenUV;
varying float lineMask;


float GetLinearDepth(vec2 sUV, sampler2D depthTexture, mat4 invProjectionMat, float mask){
	// Raw depth to linear depth code from:
	// https://docs.godotengine.org/en/latest/tutorials/shaders/advanced_postprocessing.html
	float depth = texture(depthTexture, sUV).x * mask;
	vec3 ndc = vec3(sUV * 2.0 - 1.0, depth);
    vec4 view = invProjectionMat * vec4(ndc, 1.0);
	view.xyz /= view.w;
	return -view.z;
}

vec3 GetNormal(vec2 uv, sampler2D normalTexture, float mask){
	vec3 normal = texture(normalTexture, uv).rgb;
	normal = normal * 2.0 - 1.0 * mask;
	return normal;
}

float NormalEdgeIndicator(vec3 normalEdgeBias, vec3 normal, vec3 neighborNormal, float depthDifference){
	//From Kody King: https://threejs.org/examples/webgl_postprocessing_pixel.html
	float normalDifference = dot(normal - neighborNormal, normalEdgeBias);
	float normalIndicator = clamp(smoothstep(-.01, .01, normalDifference), 0.0, 1.0);
	float depthIndicator = clamp(sign(depthDifference * .25 + .0025), 0.0, 1.0);
	return (1.0 - dot(normal, neighborNormal)) * depthIndicator * normalIndicator;
}

void vertex(){
  POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	vec2 texelSize = 1.0 / VIEWPORT_SIZE.xy;
	screenUV = SCREEN_UV;

	// UV offsets
	vec2 UVOffsets[4];
	UVOffsets[0] = SCREEN_UV + vec2(0.0, -1.0) * texelSize;
	UVOffsets[1] = SCREEN_UV + vec2(0.0, 1.0) * texelSize;
	UVOffsets[2] = SCREEN_UV + vec2(1.0, 0.0) * texelSize;
	UVOffsets[3] = SCREEN_UV + vec2(-1.0, 0.0) * texelSize;

	// Using alpha channel (screen roughness) to mask objects to not receive outlines
	float outlineMask = texture(NORMAL_TEXTURE, SCREEN_UV).a;
	outlineMask = ceil(outlineMask); // Objects with Roughness = 0 will not have and outline

	// Edge detection with Depth
	float depthDifference = 0.0;
	float invDepthDifference = 0.5;
	float depth = GetLinearDepth(SCREEN_UV, DEPTH_TEXTURE, INV_PROJECTION_MATRIX, outlineMask);

	for (int i = 0; i < UVOffsets.length(); i++){
		float dOff = GetLinearDepth(UVOffsets[i],DEPTH_TEXTURE, INV_PROJECTION_MATRIX, outlineMask);
		depthDifference += clamp(dOff - depth, 0.0, 1.0);
		invDepthDifference += depth - dOff;
	}
	invDepthDifference = clamp(invDepthDifference, 0.0, 1.0);
	invDepthDifference = clamp(smoothstep(0.9, 0.9, invDepthDifference) * 10.0 , 0.0, 1.0);
	depthDifference = smoothstep(0.25, 0.3, depthDifference);

	// Edge detection with Normals
	float normalDifference = 0.;
	vec3 normalEdgeBias = vec3(1.0, 1.0, 1.0);
	vec3 normal = GetNormal(SCREEN_UV, NORMAL_TEXTURE, outlineMask);

	for (int i = 0; i < UVOffsets.length(); i++){
		vec3 nOff = GetNormal(UVOffsets[i],NORMAL_TEXTURE, outlineMask);
		normalDifference += NormalEdgeIndicator(normalEdgeBias, normal, nOff, depthDifference);
	}
	normalDifference = smoothstep(0.2, 0.2, normalDifference);
	normalDifference = clamp(normalDifference - invDepthDifference, 0.0, 1.0);


	ALBEDO = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	lineMask = clamp(0.1, lineAlpha, (depthDifference + normalDifference * 5.0));


	if (!useLighting){
		ALBEDO += clamp((normalDifference - depthDifference), 0.0, 1.0) * lineHighlight;
		ALBEDO -= ALBEDO * depthDifference * lineShadow;
	}
}

void light (){
	if (useLighting){
		vec4 normal = texture(NORMAL_TEXTURE, screenUV);
		normal = normal * 2.0 - 1.0;

		// Calculate light direction
		float dotNL = dot(normal.rgb, LIGHT);
		dotNL = pow(dotNL, 2.5);
		dotNL = clamp(dotNL, 0.0, 1.0);

		if(LIGHT_IS_DIRECTIONAL)
			DIFFUSE_LIGHT += mix(vec3(1.0), dotNL * LIGHT_COLOR * lightIntensity, lineMask);
	}
	else
		DIFFUSE_LIGHT = vec3(1.0);
}
