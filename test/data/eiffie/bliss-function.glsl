//Bliss Function by eiffie
#define time iTime
#define rez iResolution

vec3 mcol=vec3(0.0);
float t=0.;
float DE(vec3 p0){
  vec3 pc=sin(p0.yzx*vec3(1,1.3,1.7)+vec3(time));
  if(mcol.x>0.0)mcol+=vec3(0.5)+0.5*pc;
  vec4 p=vec4(mod(p0+pc*.2,2.)-1.,1.5-t/20.);
  vec3 c=vec3(.97,.65,1)*-4.0;
  for(int n=0;n<3;n++){
    p.xyz=abs(p.xyz+1.0)-1.0;
    p*=2.0/clamp(dot(p.xyz,p.xyz),0.,1.);
    if(p.x>p.y)p.xy=p.yx;
    p.xyz+=c;
  }
  p=abs(p);
  return (max(p.x-.2,p.y-1.))/p.w;
}
vec3 normal(vec3 p, float d){//from dr2
  vec2 e=vec2(d,-d);vec4 v=vec4(DE(p+e.xxx),DE(p+e.xyy),DE(p+e.yxy),DE(p+e.yyx));
  return normalize(2.*v.yzw+vec3(v.x-v.y-v.z-v.w));
}
vec3 sky(vec3 rd, vec3 L){
  float d=0.5*dot(rd,L)+0.5;
  vec3 bg=mix(vec3(.4,.5,.7),vec3(.7,.5,.1),d);
  bg=mix(bg,vec3(1.,.9,0.),pow(d,40.));
  vec3 c=sin(rd*7.+2.*sin(rd.yzx*7.+2.*sin(7.*rd.zxy)));
  d=(c.x+c.y+c.z)*.15;
  bg=mix(bg,vec3(max(.75,(c.x+c.y+c.z)*.27)),d);
  return bg;
}
float rnd;
void randomize(in vec2 p){rnd=fract(float(time)+sin(dot(p,vec2(13.3145,117.7391)))*42317.7654321);}

float ShadAO(in vec3 ro, in vec3 rd){
 float t=0.01*rnd,s=1.0,d,mn=0.01;
 for(int i=0;i<12;i++){
  d=max(DE(ro+rd*t)*1.5,mn);
  s=min(s,d/t+t*0.5);
  t+=d;
 }
 return s;
}
vec3 scene(vec3 ro, vec3 rd){
  t=DE(ro)*rnd;
  float d,px=1.0/rez.x,stop=10.+sin((rd.x+rd.y+rd.z)*3.)*2.;
  for(int i=0;i<99;i++){
    t+=d=DE(ro+rd*t);
    if(t>stop || d<px*t)break;
  }
  vec3 L=normalize(vec3(0.4,0.025,0.5));
  vec3 col=sky(rd,L);
  if(d<px*t*5.0){
    mcol=vec3(0.001);
    vec3 so=ro+rd*t;
    vec3 N=normal(so,d);
    vec3 scol=mcol*0.25;
    float dif=0.5+0.5*dot(N,L);
    float vis=clamp(dot(N,-rd),0.05,1.0);
    float fr=pow(1.-vis,5.0);
    float shad=ShadAO(so,L);
    col=(scol*dif+fr*sky(reflect(rd,N),L))*shad;
  }
  return col;
}
mat3 lookat(vec3 fw){
   fw=normalize(fw);vec3 rt=normalize(cross(fw,normalize(vec3(.2,.8,.2))));
   return mat3(rt,cross(rt,fw),fw);
}
vec3 path(float tim){return vec3(sin(tim),sin(tim*.3),cos(tim))*10.;}
void mainImage(out vec4 O, in vec2 U){
  vec2 uv=vec2(U-0.5*rez.xy)/rez.x;
  randomize(U);
  float tim=time*.15;
  vec3 ro=path(tim);
  vec3 rd=lookat(path(tim+1.)-ro)*normalize(vec3(uv.xy,1.0));
  O=vec4(scene(ro,rd),1.0);
}
