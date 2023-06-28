float random (in vec2 _st) {
    return fract(sin(dot(_st.xy, vec2(0.890,-0.900))) * 757.153);
}

// Based on Morgan McGuire @morgan3d
// https://www.shadertoy.com/view/4dS3Wd
float noise (in vec2 _st) {
    vec2 i = floor(_st);
    vec2 f = fract(_st);

    // Four corners in 2D of a tile
    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    vec2 u = f * f * (3. - 2. * f);

    return mix(a, b, u.x) + (c - a)* u.y * (1. - u.x) + (d - b) * u.x * u.y;
}

float fbm ( in vec2 _st) {
    float v = sin(iTime)*0.15;
    float a = 0.9;
    vec2 shift = vec2(100.);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(1.0), -sin(0.5), acos(0.5));
    for (int i = 0; i < 5; ++i) {
        v += a * noise(_st);
        _st = rot * _st * 2. + shift;
        a *= 0.5;
    }
    return v;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 st = (2.*fragCoord-iResolution.xy) / min(iResolution.x, iResolution.y)*0.7;

    vec2 co = st;
    float len;
    for (int i = 0; i < 3; i++) {
        len = length(co);
        co.x +=  sin(co.y + iTime * 0.620)*0.3;
        co.y +=  cos(co.x + iTime * 0.164 + cos(len * 1.))*0.3;
    }
    len *= cos(len * 0.01);
    len -= 3.;

    vec3 color = vec3(0.);

    vec2 q = vec2(0.);
    q.x = fbm( st );
    q.y = fbm( st + vec2(-0.450,0.650));

    vec2 r = vec2(0.);
    r.x = fbm( st + 1.0*q + vec2(0.570,0.520)+ 0.5*iTime );
    r.y = fbm( st + 1.0*q + vec2(0.340,-0.570)+ 0.4*iTime);

    //Diagonal line
    for (float i = 0.; i < 3.; i++) {
        r += 1. / abs(mod(st.y + st.x, 0.6 * i) * 50.) * 2.;
        r += 1. / abs(mod(st.y - st.x, 0.6 * i) * 50.) * 1.;
    }

    color = mix(color, cos(len + vec3(0.620, 0.0, -0.564)), 1.0);

    float f = fbm(st+r);

    color = mix(vec3(0.667,0.340,0.404), vec3(0.101,0.551,0.667), color);

    fragColor = vec4(2.0*(f*f*f+.6*f*f+.5*f)*color,1.);
}
