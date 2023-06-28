// Cristian A. aka @xor_swap on Instagram
// I make cool stuff, leave a like if you enjoy it ;)

// ==== PRIMITIVES ================================================================

float sphere(vec3 p, vec3 o, float r) {
	return length(p - o) - r;
}

float capsule(vec3 p, vec3 a, vec3 b, float r) {
	vec3 ab = b - a;
	vec3 ap = p - a;
	float t = dot(ab, ap) / dot(ab, ab);
	t = clamp(t, 0.0, 1.0);
	vec3 c = a + t * ab;
	return length(p - c) - r;
}

float cylinder(vec3 p, vec3 a, vec3 b, float r) {
	vec3 ab = b - a;
	vec3 ap = p - a;
	float t = dot(ab, ap) / dot(ab, ab);
	vec3 c = a + t * ab;
	float x = length(p - c) - r;
	float y = (abs(t - 0.5) - 0.5) * length(ab);
	float e = length(max(vec2(x, y), 0.0)); // exterior distance
	float i = min(max(x, y), 0.0); // interior distance
	return e + i;
}

float cylinder(vec3 p, vec3 b, float h, float r) {
	return cylinder(p, b, vec3(b.x, b.y + h, b.z), r);
}

// ==== SCENE =====================================================================

mat2 rotation(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c, -s, s, c);
}

float pawn(vec3 p, vec3 b) {
    float y = b.y + 1.5 - p.y;
    float base = cylinder(p, vec3(b.x, b.y, b.z), 0.05, 0.365) / 2.2;
    float belly = cylinder(p, vec3(b.x, b.y + 0.3, b.z), - 0.3,
        0.35 * (sin(y * 6.0 - 0.1) + 0.03)
    );
    float neck = cylinder(p, vec3(b.x, b.y + 0.775, b.z), - 0.04, 0.26 * y);
    float separator = cylinder(p, vec3(b.x, b.y + 0.33, b.z), vec3(b.x, b.y + 0.29, b.z), 0.275);
    float body = capsule(p, vec3(b.x, b.y + 1.0, b.z), vec3(b.x, b.y + 0.3, b.z),
        (p.y < b.y || p.y > b.y + 1.5) ? 0.0 : clamp(0.25 * pow(y * 0.8, 2.4), 0.0, 1.5)
	);
    float head = sphere(p, vec3(b.x, b.y + 1.0, b.z), 0.22);
    return min(base, min(head, min(neck, min(separator, min(body, belly)))));
}

float scene(vec3 p) {
    vec3 q = p;
    q.y -= 0.5;
    q.xz *= rotation(sin(iTime * 0.8) * 2.0);
    q.yz *= rotation(cos(iTime * 0.8) * 2.0 + 0.5);
    q.y -= 0.5;
    //q.z += cos(iTime);
    return pawn(q, vec3(0, -1.0, 0));
}

const int   MAX_STEPS = 100;
const float MAX_DIST  = 100.0;
const float SURF_DIST = 0.01;

const float INSIDE = -1.0, OUTSIDE = 1.0;
float march(in vec3 ro, in vec3 rd, float side) {
	float d0 = 0.0, ds = 0.0;
	for (int i = 0; i < MAX_STEPS; i++) {
		vec3 p = ro + rd * d0;
		ds = scene(p) * side; // outside or inside (1, -1)
		d0 += ds;
		if (d0 >= MAX_DIST || abs(ds) <= SURF_DIST) break;
	}
	return d0;
}

vec3 normal(vec3 p) {
	float d = scene(p);
	vec2 e = vec2(0.01, 0.0);
	vec3 n = d - vec3(
		scene(p - e.xyy),
		scene(p - e.yxy),
		scene(p - e.yyx)
	); // n is a point close to p;
	return normalize(n);
}

/// adds source lights to the scene
float light(vec3 n) {
    float t = 1.0;// (sin(iTime) * 0.5) + 0.5; // light movement
    vec3 l1 = vec3(clamp(n.z, -0.5, 0.5), t, clamp(n.x, -0.5, 0.5));
    vec3 l2 = vec3(clamp(n.y, -0.5, 0.5), clamp(n.x, -0.5, 0.5), t);
    vec3 l3 = vec3(t, clamp(n.z, -0.5, 0.5), clamp(n.y, -0.5, 0.5));
    float brightness = 0.0;
    brightness += max(0.0, dot(n, normalize(l1))) * 0.3;
    brightness += max(0.0, dot(n, normalize(l2))) * 0.3;
    brightness += max(0.0, dot(n, normalize(l3))) * 0.3;
    return clamp(brightness, 0.0, 1.0);
}

/// fetches the background
vec3 background(vec3 ray) {
    // return texture(iChannel0, ray).rgb; // IT ALSO WORKS WITH CUBEMAPS
    vec3 color = vec3((0.2 - ray.y) / 10.0);
    color.b += 0.2;
    color.r += length(ray.zy) * (sin(iTime) * 0.5 + 0.5) * 0.3;
    color.g += length(ray.xz) * 0.1;
    return max(color * 0.5, 0.0);
}

/// fetches the foreground
vec3 foreground(vec3 ray) {
    const float cs = 1.5; // chromatic shift
    const float gl = 1.0; // white glare
    vec3 q = sin(vec3(1) + ray * 0.01 / cs) * 0.5 - 0.5;
    vec3 color = vec3(gl / length(mod(q, cs)));
    color /= cs * 10.0;
    float l = light(normal(normalize(ray))) * cs;
    color /= sin(l) * 0.5;
    color = mix(color, background(ray), l);
    return color;
}

vec3 direction(vec2 uv, vec3 p, vec3 l, float z) {
    vec3 f = normalize(l - p),
         r = normalize(cross(vec3(0, 1, 0), f)),
         u = cross(f, r),
         c = f * z,
         i = c + uv.x * r + uv.y * u;
    return normalize(i);
}

vec3 reflection(vec3 rd, vec3 n, float d, vec3 color) {
    vec3 r = reflect(rd, n);
    vec3 t = foreground(r).rgb;
    return vec3(d) * t * color;
}

/// reflects a surface with chromatic aberration
vec3 reflection(vec3 rd, vec3 n, float d, vec3 color, float ca) {
    vec3 t;
    t.r = foreground(reflect(rd - ca, n)).r;
    t.g = foreground(reflect(rd, n)).g;
    t.b = foreground(reflect(rd + ca, n)).b;
    return vec3(d) * t * color;
}

vec3 glass(vec3 p, vec3 rd, vec3 n) {
    const float ior = 3.5;
    vec3 refo = foreground(reflect(rd, n)); // reflection outside
    vec3 ri = refract(rd, n, 1.0 / ior);    // inside refraction ray
    vec3 e = p - n * SURF_DIST * 3.0;       // enter point
    float i = march(e, ri, INSIDE);         // raymarch the inside
    e = e + ri * i;                         // exit point
    vec3 en = - normal(e);                  // exit normal

    vec3 ro, t = vec3(0);
    // total internal reflection with chromatic aberation
    const float ca = 0.17; // chromatic aberration

    t.r = foreground(reflect(ri, en - ca)).r;
    t.g = foreground(reflect(ri, en)).g;
    t.b = foreground(reflect(ri, en + ca)).b;

    t = pow(pow(t, vec3(3.0)) * (exp(length(t - 0.2)) * 0.5), vec3(0.9));

    // outside reflection
    float fresnel = pow(1.0 + dot(rd, n), 8.0);
    t = mix(t, refo, fresnel);

    return max(vec3(0.0), t);
}

// ==== CAMERA =====================================================================

vec3 fragment(in vec2 uv) {
    vec2 m = iMouse.xy / iResolution.xy;
    vec3 ro = vec3(0, 5, - 4);
    ro.yz *= rotation(- m.y * 3.14);
    ro.xz *= rotation(- m.x * 6.2831);// + (sin(iTime / 9.5) * 3.0);
    vec3 rd = direction(uv, ro, vec3(0, 0.5, 0), 3.0);
    float d = march(ro, rd, OUTSIDE);
    vec3 color = vec3((uv.y + 0.5) * 0.5) * background(rd);
    if (d < MAX_DIST) {
        vec3 p = ro + rd * d;
        color = glass(p, rd, normal(p));
        color = mix(color, background(p), 0.5);
    }
    color = pow(color, vec3(0.4545)); // gamma correction
	return color;
}

void mainImage(out vec4 color, in vec2 coord) {
	vec2 uv = (coord - 0.5 * iResolution.xy) / iResolution.y;
	color = vec4(fragment(uv), 1.0);
}
