float time() { return iTime; }
vec2 res() { return iResolution.xy; }

vec3 nor = vec3(0, 0, -1);

float formula(vec2 p) {
    p *= 0.6;
	p.x += time()*0.3;
	p.y += sin(time()*0.4);
	p.x = mod(p.x + 1.0, 2.0) - 1.0;
	float d = 100.0;

	for(int i = 0; i < 6; i++) {
		p = abs(p)/clamp(dot(p, p), 0.4, 1.0) - vec2(0.6);
		d = min(d, 0.5*abs(p.y));
	}

	return d;
}

vec3 bump(vec2 p) {
	vec2 h = vec2(0.008, 0.0);
	vec3 g = vec3(
		formula(p + h.xy) - formula(p - h.xy),
		formula(p + h.yx) - formula(p - h.yx),
		-0.3);
	return normalize(g);
}

vec3 render(vec2 p) {
	vec3 col = vec3(0);
	vec3 rd = normalize(vec3(p, 2.0));
	vec3 sn = normalize(bump(p));

	vec3 ref = reflect(rd, sn);

	col += pow(clamp(dot(-(normalize(rd + vec3(cos(time()), 0, 0))), ref), 0.0, 1.0), 10.0);
    return col;

    // Cool effect by Trisomie21, definitley gonna use this in the future.
	//return mix(col, vec3(2.0, 0.2, 0.2), clamp(formula(p)*2.,.2,1.2)-.2);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ) {
	vec2 p = (-res() + 2.0*fragCoord)/res().y;

	vec3 col = render(p);
	col = pow(col, vec3(1.0/2.2));
	fragColor = vec4(col, 1);
}
