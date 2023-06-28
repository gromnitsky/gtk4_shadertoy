// License CC0: Metallic Voronot Roses
//  If you got a decent height function, apply FBM and see if it makes it more interesting
//  Based upon: https://www.shadertoy.com/view/4tXGW4

#define TIME        iTime
#define RESOLUTION  iResolution
#define PI          3.141592654
#define TAU         (2.0*PI)
#define L2(x)       dot(x, x)
#define ROT(a)      mat2(cos(a), sin(a), -sin(a), cos(a))

float tanh_approx(float x) {
//  return tanh(x);
  float x2 = x*x;
  return clamp(x*(27.0 + x2)/(27.0+9.0*x2), -1.0, 1.0);
}

float pmin(float a, float b, float k) {
  float h = clamp(0.5+0.5*(b-a)/k, 0.0, 1.0);
  return mix(b, a, h) - k*h*(1.0-h);
}

float pmax(float a, float b, float k) {
  return -pmin(-a, -b, k);
}

float pabs(float a, float k) {
  return pmax(a, -a, k);
}

vec2 hash(vec2 p) {
  p += 0.5;
  p = vec2(dot (p, vec2 (127.1, 311.7)), dot (p, vec2 (269.5, 183.3)));
  return -1. + 2.*fract (sin (p)*43758.5453123);
}
float height_(vec2 p, float tm) {
  p *= 0.125*1.5;
  vec2 n = floor(p + 0.5);
  vec2 r = hash(n);
  p = fract(p+0.5)-0.5;
  float d = length(p);
//  p.x = pabs(p.x, 0.025);
//  p.x = abs(p.x);
//  p *= ROT(-TIME*0.1-1.5*d-(-0.5*p.y+2*p.x)*1) ;
  float c = 1E6;
  float x = pow(d, 0.1);
  float y = atan(p.x, p.y) / TAU;

  for (float i = 0.; i < 3.; ++i) {
    float ltm = tm+10.0*(r.x+r.y);
    float v = length(fract(vec2(x - ltm*i*.005123, fract(y + i*.125)*.5)*20.)*2.-1.);
    c = pmin(c, v, 0.125);
  }

  return -0.125*pabs(1.0-tanh_approx(5.5*d-80.*c*c*d*d*(.55-d))-0.25*d, 0.25);
}


float height(vec2 p) {
  float tm = TIME*0.00075;
  p += 100.0*vec2(cos(tm), sin(tm));
  const float aa = -0.35;
  const mat2  pp = 0.9*(1.0/aa)*ROT(1.0);
  float h = 0.0;
  float a = 1.0;
  float d = 0.0;
  for (int i = 0; i < 6; ++i) {
    h += a*height_(p, 0.125*TIME+10.0*sqrt(float(i)));
    h = pmin(h, -h, 0.025);
    d += a;
    a *= aa;
    p *= pp;
  }
  return (h/d);
}

vec3 normal(vec2 p) {
  vec2 v;
  vec2 w;
  vec2 e = vec2(4.0/RESOLUTION.y, 0);

  vec3 n;
  n.x = height(p + e.xy) - height(p - e.xy);
  n.y = 2.0*e.x;
  n.z = height(p + e.yx) - height(p - e.yx);

  return normalize(n);
}

vec3 color(vec2 p) {
  const float s = 1.0;
  const vec3 lp1 = vec3(1.0, 1.25, 1.0)*vec3(s, 1.0, s);
  const vec3 lp2 = vec3(-1.0, 1.25, 1.0)*vec3(s, 1.0, s);

  float h = height(p);
  vec3  n = normal(p);

  vec3 ro = vec3(0.0, -10.0, 0.0);
  vec3 pp = vec3(p.x, 0.0, p.y);

  vec3 po = vec3(p.x, h, p.y);
  vec3 rd = normalize(ro - po);

  vec3 ld1 = normalize(lp1 - po);
  vec3 ld2 = normalize(lp2 - po);

  float diff1 = max(dot(n, ld1), 0.0);
  float diff2 = max(dot(n, ld2), 0.0);

  vec3  rn    = n;
  vec3  ref   = reflect(rd, rn);
  float ref1  = max(dot(ref, ld1), 0.0);
  float ref2  = max(dot(ref, ld2), 0.0);

  vec3 lcol1 = vec3(1.5, 1.5, 2.0).xzy;
  vec3 lcol2 = vec3(2.0, 1.5, 0.75).zyx;
  vec3 lpow1 = 0.15*lcol1/L2(ld1);
  vec3 lpow2 = 0.5*lcol2/L2(ld2);
  vec3 dm = vec3(1.0)*tanh(-h*10.0+0.125);
  vec3 col = vec3(0.0);
  col += dm*diff1*diff1*lpow1;
  col += dm*diff2*diff2*lpow2;
  vec3 rm = vec3(1.0)*mix(0.25, 1.0, tanh_approx(-h*1000.0));
  col += rm*pow(ref1, 10.0)*lcol1;
  col += rm*pow(ref2, 10.0)*lcol2;

  return col;
}

vec3 postProcess(vec3 col, vec2 q) {
  col = clamp(col, 0.0, 1.0);
  col = pow(col, 1.0/vec3(2.2));
  col = col*0.6+0.4*col*col*(3.0-2.0*col);
  col = mix(col, vec3(dot(col, vec3(0.33))), -0.4);
  col *=0.5+0.5*pow(19.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);
  return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 q = fragCoord/RESOLUTION.xy;
  vec2 p = -1. + 2. * q;
  p.x *= RESOLUTION.x/RESOLUTION.y;
  vec3 col = color(p);

  col = tanh(0.33*col);
  col = postProcess(col, q);

  fragColor = vec4(col, 1.0);
}
