// License CC0: Fortress Harkonnen
// Inspired by: http://www.fractalforums.com/new-theories-and-research/very-simple-formula-for-fractal-patterns/

// SABS from ollj
#define LESS(a,b,c) mix(a,b,step(0.,c))
#define SABS(x,k)   LESS((.5/k)*x*x+k*.5,abs(x),abs(x)-k)

#define PI      3.141592654
#define TAU     (2.0*3.141592654)
#define TIME    iTime
#define PERIOD  55.0
#define PERIODS 5.0

void rot(inout vec2 p, float a) {
  float c = cos(a);
  float s = sin(a);
  p = vec2(c*p.x + s*p.y, -s*p.x + c*p.y);
}

float plane(vec2 p, vec2 n, float m) {
  return dot(p, n) + m;
}

float circle(vec2 p, float r) {
  return length(p) - r;
}

float holey(float d, float k) {
  return abs(d) - k;
}

float tanh2(float x) {
  // Hack around precision problem
  if (abs(x) > 50.0) {
    return sign(x);
  } else {
    return tanh(x);
  }
}

float nfield(vec2 p, vec2 c) {
  vec2 u = p;

  float a = 0.0;
  float s = 1.0;


  for (int i = 0; i < 25; ++i) {
    float m = dot(u,u);
    u = SABS(u, 0.0125)/m + c;
    u *= pow(s, 0.65);
    a += pow(s, 1.0)*m;
    s *= 0.75;
  }

  return -tanh2(0.125*a);
}

vec3 normal(vec2 p, vec2 c) {
  vec2 v;
  vec2 w;
  vec2 e = vec2(2.0/iResolution.y, 0);

  vec3 n;
  n.x = nfield(p + e.xy, c) - nfield(p - e.xy, c);
  n.y = 2.0*e.x;
  n.z = nfield(p + e.yx, c) - nfield(p - e.yx, c);

  return normalize(n);
}

vec3 field(vec2 p, vec2 c) {
  vec2 u = p;

  float a = 0.0;
  float s = 1.0;

  vec2 tc = vec2(0.5, 0.3);
  rot(tc, TAU*TIME/PERIOD);
  vec2 tpn = normalize(vec2(1.0));
  float tpm = 0.0 + 1.4*tanh(length(p));

  float tcd = 1E10;
  float tcp = 1E10;

  for (int i = 0; i < 18; ++i) {
    float m = dot(u,u);
    u = SABS(u, 0.0125)/m + c;
    tcd = min(tcd, holey(circle(u-tc, 0.05), -0.1));
    tcp = min(tcp, holey(plane(u, tpn, tpm), -0.1));
    u *= pow(s, 0.5);
    a += pow(s, 1.0)*m;
    s *= 0.75;
  }

  return vec3(tanh(0.125*a), tanh(tcd), tanh(tcp));

}

vec3 postProcess(vec3 col, vec2 q) {
  col=pow(clamp(col,0.0,1.0),vec3(.75));
  col=col*0.6+0.4*col*col*(3.0-2.0*col);  // contrast
  col=mix(col, vec3(dot(col, vec3(0.33))), -0.4);  // satuation
  col*=0.5+0.5*pow(19.0*q.x*q.y*(1.0-q.x)*(1.0-q.y),0.7);  // vigneting
  return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
  vec2 q = fragCoord/iResolution.xy;
  vec2 p = -1. + 2. * q;
  p.x *= iResolution.x/iResolution.y;

  float currentPeriod = mod(floor(TIME/PERIOD), PERIODS);
  float timeInPeriod = mod(TIME, PERIOD);

  p *= 0.25 + (0.005*timeInPeriod) + pow(1.35, currentPeriod);
  vec2 c = vec2(-0.5, -0.35);

  vec3 gp = vec3(p.x, 1.0*tanh(1.0 - (length(p))), p.y);
  vec3 lp1 = vec3(-1.0, 1.5, 1.0);
  vec3 ld1 = normalize(lp1 - gp);
  vec3 lp2 = vec3(1.0, 1.5, 1.0);
  vec3 ld2 = normalize(lp2 - gp);
  vec3 f = field(p, c);

  vec3 n = normal(p, c);

  float diff1 = max(dot(ld1, n), 0.0);
  float diff2 = max(dot(ld2, n), 0.0);

  vec3 col = vec3(0.0);

  const vec3 dcol1 = vec3(0.3, 0.5, 0.7).xyz;
  const vec3 dcol2 = 0.5*vec3(0.7, 0.5, 0.3).xyz;
  const vec3 scol1 = 0.5*vec3(1.0);
  const vec3 scol2 = 0.5*0.5*vec3(1.0);

  col += diff1*dcol1;
  col += diff2*dcol2;
  col += scol1*pow(diff1, 10.0);
  col += scol2*pow(diff2, 3.0);
  col -= vec3(tanh(f.y-0.1));
  col += 0.5*(diff1+diff2)*(1.25*pow(vec3(f.z), 5.0*vec3(1.0, 4.0, 5.0)));

  col = postProcess(col, q);

  const float fade = 2.0;
  float fadeIn  = smoothstep(0.0, fade, timeInPeriod);
  float fadeOut = 1.0-smoothstep(PERIOD - fade, PERIOD, timeInPeriod);
  col *= fadeIn*fadeOut;

  fragColor = vec4(col, 1.0);
}
