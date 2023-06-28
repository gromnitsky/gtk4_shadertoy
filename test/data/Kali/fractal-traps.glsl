//orbit traps from julia version of fractal formula z=(z+1/z+c)*-scale;

#define zoom 5.
#define offset vec2(0.3,0.2)

#define iterations 27
#define scale -.4
#define julia vec2(2.2,0.75)

#define orbittraps vec3(.8,.5,-.01)
#define trapswidths vec3(.2,.2,.3)

#define trap1color vec3(1.00,0.30,0.10)
#define trap2color vec3(1.00,0.50,0.10)
#define trap3color vec3(0.10,0.20,1.00)

#define trapsbright vec3(1.,.8,.7)
#define trapscontrast vec3(5.,10.,5.)

#define trapsfreq vec3(5.,8.,20.)
#define trapsamp vec3(.03,.03,.01)
#define trapspeeds vec3(20.,20.,40.)

#define saturation .6
#define brightness .9
#define contrast 1.35
#define minbright .3

#define antialias 3.


vec2 rotate(vec2 p, float angle) {
return p*mat2(cos(angle),sin(angle),-sin(angle),cos(angle));
}

void mainImage(out vec4 fragColor, vec2 fragCoord)
{
    vec3 aacolor=vec3(0.);
    vec2 uv=fragCoord / iResolution.xy - 0.5;
    float aspect=iResolution.x/iResolution.y;
    vec2 pos=uv;
    pos.x*=aspect;
    float t=iTime*.07;
    float zoo=.005+pow(abs(sin(t*.5+1.4)),5.)*zoom;
    pos=rotate(pos,t*1.2365);
    pos+=offset;
    pos*=zoo;
    vec2 pixsize=1./iResolution.xy*zoo;
    pixsize.x*=aspect;
    float av=0.;
    vec3 its=vec3(0.);
    for (float aa=0.; aa<16.; aa++) {
        vec3 otrap=vec3(1000.);
        if (aa<antialias*antialias) {
            vec2 aacoord=floor(vec2(aa/antialias,mod(aa,antialias)));
            vec2 z=pos+aacoord*pixsize/antialias;
            for (int i=0; i<iterations; i++) {
                vec2 cz=vec2(z.x,-z.y);
                z=z+cz/dot(z,z)+julia;
                z=z*scale;
                float l=length(z);
                vec3 ot=abs(vec3(l)-orbittraps+
                    (sin(pos.x*trapsfreq/zoo+t*trapspeeds)+
                     sin(pos.y*trapsfreq/zoo+trapspeeds))*trapsamp);
                if (ot.x<otrap.x) {
                    otrap.x=ot.x;
                    its.x=float(iterations-i);
                }
                if (ot.y<otrap.y) {
                    otrap.y=ot.y;
                    its.y=float(iterations-i);
                }
                if (ot.z<otrap.z) {
                    otrap.z=ot.z;
                    its.z=float(iterations-i);
                }
            }
        }
        otrap=pow(max(vec3(0.),trapswidths-otrap)/trapswidths,trapscontrast);
        its=its/float(iterations);
        vec3 otcol1=otrap.x*pow(trap1color,3.5-vec3(its.x*3.))*max(minbright,its.x)*trapsbright.x;
        vec3 otcol2=otrap.y*pow(trap2color,3.5-vec3(its.y*3.))*max(minbright,its.y)*trapsbright.y;
        vec3 otcol3=otrap.z*pow(trap3color,3.5-vec3(its.z*3.))*max(minbright,its.z)*trapsbright.z;
        aacolor+=(otcol1+otcol2+otcol3);
    }
    aacolor=aacolor/(antialias*antialias)+.15;
    vec3 color=mix(vec3(length(aacolor)),aacolor,saturation)*brightness;
    color=pow(color,vec3(contrast));
    fragColor = vec4(color,1.0);
}
