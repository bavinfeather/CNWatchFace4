// Adapted from pinned mourner/suncalc; Copyright (c) 2026 Volodymyr Agafonkin.
// BSD-2-Clause: assets/suncalc/LICENSE. Coordinate/illumination subset only.
import Toybox.Math;
class MoonPhase {
    const PI=3.141592653589793d;
    const rad=0.017453292519943295d;
const moonLon = [
    0, 0, 1, 0, 6288774, -20905355,
    2, 0, -1, 0, 1274027, -3699111,
    2, 0, 0, 0, 658314, -2955968,
    0, 0, 2, 0, 213618, -569925,
    0, 1, 0, 0, -185116, 48888,
    0, 0, 0, 2, -114332, -3149,
    2, 0, -2, 0, 58793, 246158,
    2, -1, -1, 0, 57066, -152138,
    2, 0, 1, 0, 53322, -170733,
    2, -1, 0, 0, 45758, -204586,
    0, 1, -1, 0, -40923, -129620,
    1, 0, 0, 0, -34720, 108743,
    0, 1, 1, 0, -30383, 104755,
    2, 0, 0, -2, 15327, 10321,
    0, 0, 1, 2, -12528, 0,
    0, 0, 1, -2, 10980, 79661,
    4, 0, -1, 0, 10675, -34782,
    0, 0, 3, 0, 10034, -23210,
    4, 0, -2, 0, 8548, -21636,
    2, 1, -1, 0, -7888, 24208,
    2, 1, 0, 0, -6766, 30824,
    1, 0, -1, 0, -5163, -8379,
    1, 1, 0, 0, 4987, -16675,
    2, -1, 1, 0, 4036, -12831,
    2, 0, 2, 0, 3994, -10445,
    4, 0, 0, 0, 3861, -11650,
    2, 0, -3, 0, 3665, 14403,
    0, 1, -2, 0, -2689, -7003,
    2, 0, -1, 2, -2602, 0,
    2, -1, -2, 0, 2390, 10056,
    1, 0, 1, 0, -2348, 6322,
    2, -2, 0, 0, 2236, -9884,
    0, 1, 2, 0, -2120, 5751,
    0, 2, 0, 0, -2069, 0,
    2, -2, -1, 0, 2048, -4950,
    2, 0, 1, -2, -1773, 4130,
    2, 0, 0, 2, -1595, 0,
    4, -1, -1, 0, 1215, -3958,
    0, 0, 2, 2, -1110, 0,
    3, 0, -1, 0, -892, 3258,
    2, 1, 1, 0, -810, 2616,
    4, -1, -2, 0, 759, -1897,
    0, 2, -1, 0, -713, -2117,
    2, 2, -1, 0, -700, 2354,
    2, 1, -2, 0, 691, 0,
    2, -1, 0, -2, 596, 0,
    4, 0, 1, 0, 549, -1423,
    0, 0, 4, 0, 537, -1117,
    4, -1, 0, 0, 520, -1571,
    1, 0, -2, 0, -487, -1739,
    2, 1, 0, -2, -399, 0,
    0, 0, 2, -2, -381, -4421,
    1, 1, 1, 0, 351, 0,
    3, 0, -2, 0, -340, 0,
    4, 0, -3, 0, 330, 0,
    2, -1, 2, 0, 327, 0,
    0, 2, 1, 0, -323, 1165,
    1, 1, -1, 0, 299, 0,
    2, 0, 3, 0, 294, 0,
    2, 0, -1, -2, 0, 8752
];
const moonLat = [
    0, 0, 0, 1, 5128122,
    0, 0, 1, 1, 280602,
    0, 0, 1, -1, 277693,
    2, 0, 0, -1, 173237,
    2, 0, -1, 1, 55413,
    2, 0, -1, -1, 46271,
    2, 0, 0, 1, 32573,
    0, 0, 2, 1, 17198,
    2, 0, 1, -1, 9266,
    0, 0, 2, -1, 8822,
    2, -1, 0, -1, 8216,
    2, 0, -2, -1, 4324,
    2, 0, 1, 1, 4200,
    2, 1, 0, -1, -3359,
    2, -1, -1, 1, 2463,
    2, -1, 0, 1, 2211,
    2, -1, -1, -1, 2065,
    0, 1, -1, -1, -1870,
    4, 0, -1, -1, 1828,
    0, 1, 0, 1, -1794,
    0, 0, 0, 3, -1749,
    0, 1, -1, 1, -1565,
    1, 0, 0, 1, -1491,
    0, 1, 1, 1, -1475,
    0, 1, 1, -1, -1410,
    0, 1, 0, -1, -1344,
    1, 0, 0, -1, -1335,
    0, 0, 3, 1, 1107,
    4, 0, 0, -1, 1021,
    4, 0, -1, 1, 833,
    0, 0, 1, -3, 777,
    4, 0, -2, 1, 671,
    2, 0, 0, -3, 607,
    2, 0, 2, -1, 596,
    2, -1, 1, -1, 491,
    2, 0, -2, 1, -451,
    0, 0, 3, -1, 439,
    2, 0, 2, 1, 422,
    2, 0, -3, -1, 421,
    2, 1, -1, 1, -366,
    2, 1, 0, 1, -351,
    4, 0, 0, 1, 331,
    2, -1, 1, 1, 315,
    2, -2, 0, -1, 302,
    0, 0, 1, 3, -283,
    2, 1, 1, -1, -229,
    1, 1, 0, -1, 223,
    1, 1, 0, 1, 223,
    0, 1, -2, -1, -220,
    2, 1, -1, -1, -220,
    1, 0, 1, 1, -185,
    2, -1, -2, -1, 181,
    0, 1, 2, 1, -177,
    4, 0, -2, -1, 176,
    4, -1, -1, -1, 166,
    1, 0, 1, -1, -164,
    4, 0, 1, -1, 132,
    1, 0, -1, -1, -119,
    4, -1, 0, -1, 115,
    2, -2, 0, 1, 107
];
function deltaT(d) {
    var y = 2000 + d / 365.2425d;
    var t;
    if (y < 1920) { t = y - 1900; return -2.79d + t * (1.494119d + t * (-0.0598939d + t * (0.0061966d - t * 0.000197d))); }
    if (y < 1941) { t = y - 1920; return 21.20d + t * (0.84493d + t * (-0.076100d + t * 0.0020936d)); }
    if (y < 1961) { t = y - 1950; return 29.07d + t * (0.407d + t * (-1.0d / 233 + t / 2547)); }
    if (y < 1986) { t = y - 1975; return 45.45d + t * (1.067d + t * (-1.0d / 260 - t / 718)); }
    if (y < 2005) { t = y - 2000; return 63.86d + t * (0.3345d + t * (-0.060374d + t * (0.0017275d + t * (0.000651814d + t * 0.00002373599d)))); }
    if (y < 2050) { t = y - 2000; return 62.92d + t * (0.32217d + t * 0.005589d); }
    t = (y - 1820) / 100; return -20 + 32 * t * t - 0.5628d * (2150 - y);
}
function sunCoords(d) {
    var t = d / 36525;
    var L0 = rad * (280.46646d + t * (36000.76983d + t * 0.0003032d)); // 25.2d geometric mean longitude
    var M = rad * (357.52911d + t * (35999.05029d - t * 0.0001537d)); // 25.3d mean anomaly
    var sinM = Math.sin(M);
    var cosM = Math.cos(M);
    var C = rad * ((1.914602d - t * (0.004817d + t * 0.000014d)) * sinM + // equation of center
        (0.019993d - 0.000101d * t) * 2 * sinM * cosM + 0.000289d * sinM * (3 - 4 * sinM * sinM));
    var Om = rad * (125.04d - 1934.136d * t); // longitude of the ascending node
    var L = L0 + C - rad * (0.00569d + 0.00478d * Math.sin(Om)); // apparent longitude (nutation + aberration)
    // 22.2d mean obliquity + 25.8d correction for apparent position
    var e = rad * (23.439291d - t * (0.0130042d + t * (0.00000016d - t * 0.000000504d))) + rad * 0.00256d * Math.cos(Om);

    return [Math.atan2(Math.cos(e) * Math.sin(L), Math.cos(L)), Math.asin(Math.sin(e) * Math.sin(L))];
}
function nutationObliquity(t) {
    var om = rad * (125.04452d - 1934.136261d * t); // longitude of the Moon's ascending node
    var ls = rad * (280.4665d + 36000.7698d * t);   // mean longitude of the Sun
    var lm = rad * (218.3165d + 481267.8813d * t);  // mean longitude of the Moon
    var dpsi = (-17.20d * Math.sin(om) - 1.32d * Math.sin(2 * ls) - 0.23d * Math.sin(2 * lm) + 0.21d * Math.sin(2 * om)) / 3600;
    var deps = (9.20d * Math.cos(om) + 0.57d * Math.cos(2 * ls) + 0.10d * Math.cos(2 * lm) - 0.09d * Math.cos(2 * om)) / 3600;
    var eps0 = 23.439291d - t * (0.0130042d + t * (0.00000016d - t * 0.000000504d)); // 22.2d mean obliquity
    return [dpsi, rad * (eps0 + deps)];
}
function moonCoords(d) {
    var t = d / 36525;

    // fundamental arguments (degrees), 47.1d–47.6d
    var Lp = 218.3164477d + t * (481267.88123421d + t * (-0.0015786d + t * (1.0d / 538841 - t / 65194000)));
    var D = 297.8501921d + t * (445267.1114034d + t * (-0.0018819d + t * (1.0d / 545868 - t / 113065000)));
    var M = 357.5291092d + t * (35999.0502909d + t * (-0.0001536d + t / 24490000));
    var Mp = 134.9633964d + t * (477198.8675055d + t * (0.0087414d + t * (1.0d / 69699 - t / 14712000)));
    var F = 93.2720950d + t * (483202.0175233d + t * (-0.0036539d + t * (-1.0d / 3526000 + t / 863310000)));
    var A1 = 119.75d + 131.849d * t;
    var A2 = 53.09d + 479264.290d * t;
    var A3 = 313.45d + 481266.484d * t;
    var E = 1 - t * (0.002516d + t * 0.0000074d); // eccentricity factor for solar-anomaly terms

    var Dr=rad*D; var Mr=rad*M; var Mpr=rad*Mp; var Fr=rad*F;
    var sl=0.0d; var sr=0.0d; var sb=0.0d;
    for (var i = 0; i < moonLon.size(); i += 6) {
        var m = moonLon[i + 1];
        var arg = moonLon[i] * Dr + m * Mr + moonLon[i + 2] * Mpr + moonLon[i + 3] * Fr;
        var f = m == 1 || m == -1 ? E : m == 2 || m == -2 ? E * E : 1;
        sl += moonLon[i + 4] * f * Math.sin(arg);
        sr += moonLon[i + 5] * f * Math.cos(arg);
    }
    for (var i = 0; i < moonLat.size(); i += 5) {
        var m = moonLat[i + 1];
        var arg = moonLat[i] * Dr + m * Mr + moonLat[i + 2] * Mpr + moonLat[i + 3] * Fr;
        var f = m == 1 || m == -1 ? E : m == 2 || m == -2 ? E * E : 1;
        sb += moonLat[i + 4] * f * Math.sin(arg);
    }

    // additive terms (Venus, Jupiter and flattening of the Earth), 47 p.342
    var A1r=rad*A1; var Lpr=rad*Lp;
    sl += 3958 * Math.sin(A1r) + 1962 * Math.sin(Lpr - Fr) + 318 * Math.sin(rad * A2);
    sb += -2235 * Math.sin(Lpr) + 382 * Math.sin(rad * A3) + 175 * Math.sin(A1r - Fr) + 175 * Math.sin(A1r + Fr) +
        127 * Math.sin(Lpr - Mpr) - 115 * Math.sin(Lpr + Mpr);

    var nut = nutationObliquity(t); var dpsi = nut[0]; var eps = nut[1];
    var l = rad * (Lp + sl / 1e6 + dpsi); // apparent ecliptic longitude
    var b = rad * (sb / 1e6);             // ecliptic latitude

    return [Math.atan2(Math.sin(l) * Math.cos(eps) - Math.tan(b) * Math.sin(eps), Math.cos(l)), Math.asin(Math.sin(b) * Math.cos(eps) + Math.cos(b) * Math.sin(eps) * Math.sin(l)), 385000.56d + sr / 1000];
}
function phase(seconds) {
    // Subtract the J2000 Unix epoch before division, avoiding a large Float JD.
    var d=(seconds-946728000).toDouble()/86400.0d;
    d+=deltaT(d)/86400.0d;
    var s=sunCoords(d); var m=moonCoords(d);
    var dot=Math.sin(s[1])*Math.sin(m[1])+Math.cos(s[1])*Math.cos(m[1])*Math.cos(s[0]-m[0]);
    if(dot>1) { dot=1.0d; } if(dot< -1) { dot= -1.0d; }
    var phi=Math.acos(dot);
    var inc=Math.atan2(149598000.0d*Math.sin(phi),m[2]-149598000.0d*Math.cos(phi));
    var angle=Math.atan2(Math.cos(s[1])*Math.sin(s[0]-m[0]),
        Math.sin(s[1])*Math.cos(m[1])-Math.cos(s[1])*Math.sin(m[1])*Math.cos(s[0]-m[0]));
    return 0.5d+0.5d*inc*(angle<0?-1:1)/PI;
}
}
