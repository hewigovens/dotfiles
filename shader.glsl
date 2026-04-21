// Dual-mode starfield: bright sparkles on dark themes, dark ink specks on light themes.
// Auto-switches based on iBackgroundColor.

float luminance(vec3 color) {
    return dot(color, vec3(0.2126, 0.7152, 0.0722));
}

const float threshold = 0.15;
const float repeats = 30.;
const float layers = 21.;

const vec3 starBlue   = vec3(51.,  64.,  195.) / 255.;
const vec3 starCyan   = vec3(117., 250., 254.) / 255.;
const vec3 starWhite  = vec3(255., 255., 255.) / 255.;
const vec3 starYellow = vec3(251., 245., 44.)  / 255.;
const vec3 starRed    = vec3(247., 2.,   20.)  / 255.;

vec3 spectrum(vec2 pos) {
    pos.x *= 4.;
    vec3 outCol = vec3(0);
    if (pos.x > 0.) outCol = mix(starBlue,   starCyan,   fract(pos.x));
    if (pos.x > 1.) outCol = mix(starCyan,   starWhite,  fract(pos.x));
    if (pos.x > 2.) outCol = mix(starWhite,  starYellow, fract(pos.x));
    if (pos.x > 3.) outCol = mix(starYellow, starRed,    fract(pos.x));
    return 1. - (pos.y * (1. - outCol));
}

float N21(vec2 p) {
    p = fract(p * vec2(233.34, 851.73));
    p += dot(p, p + 23.45);
    return fract(p.x * p.y);
}

vec2 N22(vec2 p) {
    float n = N21(p);
    return vec2(n, N21(p + n));
}

mat2 scale2(vec2 s) {
    return mat2(s.x, 0.0, 0.0, s.y);
}

vec3 stars(vec2 uv, float offset) {
    float timeScale = -(iTime + offset) / layers;
    float trans = fract(timeScale);
    float newRnd = floor(timeScale);
    vec3 col = vec3(0.);

    uv -= vec2(0.5);
    uv = scale2(vec2(trans)) * uv;
    uv += vec2(0.5);
    uv.x *= iResolution.x / iResolution.y;
    uv *= repeats;

    vec2 ipos = floor(uv);
    uv = fract(uv);

    vec2 rndXY = N22(newRnd + ipos * (offset + 1.)) * 0.9 + 0.05;
    float rndSize = N21(ipos) * 100. + 200.;

    vec2 j = (rndXY - uv) * rndSize;
    float sparkle = 1. / dot(j, j);

    col += spectrum(fract(rndXY * newRnd * ipos)) * vec3(sparkle);
    col *= smoothstep(1., 0.8, trans);
    return col;
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    vec4 terminalColor = texture(iChannel0, uv);

    vec3 col = vec3(0.);
    for (float i = 0.; i < layers; i++) {
        col += stars(uv, i);
    }

    vec3 blendedColor;
    if (luminance(iBackgroundColor) < 0.5) {
        // Dark theme: colored sparkles where terminal is dark.
        float mask = 1.0 - step(threshold, luminance(terminalColor.rgb));
        blendedColor = mix(terminalColor.rgb, col, mask);
    } else {
        // Light theme: same star positions rendered as dark ink specks.
        // luminance(col) is huge at star centers — clamp to get a 0–1 intensity.
        float starAmt = clamp(luminance(col) * 1.5, 0.0, 1.0);
        vec3 ink = vec3(0.08, 0.09, 0.18);
        blendedColor = mix(terminalColor.rgb, ink, starAmt * 0.85);
    }

    fragColor = vec4(blendedColor, terminalColor.a);
}
