#version 460 core
precision mediump float;

uniform sampler2D iChannel0; //image
//uniform sampler2D iChannel1; //noise
uniform float[8] values;



out vec4 fragColor;

// Function to get the values from the array
float getValue(int index) {
    return values[index];
}

float radial(vec2 pos, float radius)
{
    float result = length(pos)-radius;
    result = fract(result*1.0);
    float result2 = 1.0 - result;
    float fresult = result * result2;
    fresult = pow((fresult*5.5),10.0);
    fresult = clamp(0.0,1.0,fresult);
    return fresult;
}



float invertLerp(float v, float a, float b) {
    return clamp((v - a) / (b - a), 0.0, 1.0);
}

float lerp(float a, float b, float t) {
    return a + t * (b - a);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 iResolution = vec2(getValue(2), getValue(3));
    vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 customPos = vec2(getValue(6), getValue(7));
    vec2 c_uv = (uv - customPos) * 2.0 - 1.0;

    float distortionPower = getValue(5);
    float p = getValue(4);
    float iTime = getValue(0);
    float noisePower = getValue(1);

    vec2 o_uv = uv * lerp(distortionPower, 1.0, p);
    float noise = texture(iChannel0, uv * 0.1 + iTime * 0.05).r;
    float gradient = radial(c_uv, iTime);
    
    o_uv *= lerp((1.0 + noisePower * noise), 1.0, p);
   
    vec2 fuv = mix(uv, o_uv, gradient);
    vec3 col = texture(iChannel0, fuv).xyz;   
    
    fragColor = vec4(col, 0);
}

void main() {
    vec2 pos = gl_FragCoord.xy;
//    vec2 uv = pos / vec2(width, height);
    mainImage(fragColor,pos);
}