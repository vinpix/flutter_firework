precision highp float;
uniform sampler2D iChannel0;
uniform float iTime;
uniform vec2 iResolution;

out vec4 fragColor;

float radial(vec2 pos, float radius)
{
    float result = length(pos)-radius;
    result = fract(result*1.0);
    float result2 = 1.0 - result;
    float fresult = result * result2;
    fresult = pow((fresult*5.5),10.0);
    //fresult = clamp(0.0,1.0,fresult);
    return fresult;
}




void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    
    vec2 c_uv = uv * 2.0 - 1;
    vec2 o_uv = uv * 0.80;
    float gradient = radial(c_uv, iTime*0.5);
    vec2 fuv = mix(uv,o_uv,gradient);
    vec3 col = texture(iChannel0,fuv).xyz;
	fragColor = vec4(col,0);
}

void main() {
    vec2 pos = gl_FragCoord.xy;
//    vec2 uv = pos / vec2(width, height);
    mainImage(fragColor,pos);
}