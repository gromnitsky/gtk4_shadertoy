// Cole Peterson (Plento)

#define R iResolution.xy
#define m ((iMouse.xy - .5*R.xy) / R.y)
#define rot(a) mat2(cos(a), -sin(a), sin(a), cos(a))

float rbox( vec3 p, vec3 b, float r ){
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

// Dave Hoshkin
float hash13(vec3 p3){
	p3  = fract(p3 * .1031);
    p3 += dot(p3, p3.zyx + 31.32);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 hash33(vec3 p3){
	p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);

}


#define b vec3(2., 2., 2.)

vec3 getCell(vec3 p){
    return floor(p / b);
}

vec3 getCellCoord(vec3 p){
    return mod(p, b) - b*.5;
}

float map(vec3 p){
    vec3 id = getCell(p);
    p = getCellCoord(p);

    float rnd = 2.*hash13(id*663.) - 1.;

    p.xz *= rot(rnd*iTime*.3 + rnd);
    p.xy *= rot(rnd*iTime*.3 + rnd);
    p.yz *= rot(p.x*(5.+rnd*10.));

    return rbox(p, vec3(0.7, .16, .16), .1);
}

vec3 normal( in vec3 pos ){
    vec2 e = vec2(0.002, -0.002);
    return normalize(
        e.xyy * map(pos + e.xyy) +
        e.yyx * map(pos + e.yyx) +
        e.yxy * map(pos + e.yxy) +
        e.xxx * map(pos + e.xxx));
}

vec3 color(vec3 ro, vec3 rd, vec3 n, float t){
    vec3 p = ro + rd*t;
    vec3 lp = ro + vec3(.0, .0, 2.7);

    if(iMouse.z>0.) lp.z += m.y*14.;

    vec3 ld = normalize(lp-p);
    float dd = length(p - lp);
    float dif = max(dot(n, ld), .1);
    float fal = 1. / dd;
    float spec = pow(max(dot( reflect(-ld, n), -rd), 0.), 23.);

    vec3 id = getCell(p);
    vec3 objCol = hash33(id*555.);


    objCol *= (dif + .2);
    objCol += spec * 0.6;
    objCol *= fal;

    return objCol;
}


void mainImage( out vec4 f, in vec2 u ){
    vec2 uv = vec2(u.xy - 0.5*R.xy)/R.y;
    vec3 rd = normalize(vec3(uv, 0.8));
    vec3 ro = vec3(0., 7.0, 4.);
    rd.xy*=rot(-iTime*.1 + .5);
    ro.zy += iTime;
    ro.x += cos(iTime)*.25;

    int nHits = 0;
    float d = 0.0, t = 0.0, ns = 0.;
    vec3 p, n, col = vec3(0);

    for(int i = 0; i < 80; i++){
    	d = map(ro + rd*t);

        if(nHits >= 4 || t >= 12.) break;

        if(abs(d) < .001){
            p = ro + rd*t;
            n = normal(p);

            if(d > 0. && nHits == 0) rd = refract(rd, n, 1.03);

            col += color(ro, rd, n, t);

            nHits++;
            t += .1;
        }
        t += abs(d) * .6;

        if(nHits == 0) ns++;
    }

    col /= float(nHits)*.6;
    col *= smoothstep(.5, .3, ns * .01);

    col = 1.-exp(-col);
    f = vec4(col, 1.0);
}
