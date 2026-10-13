import Toybox.Graphics;
import Toybox.Math;
import Toybox.Time;
import Toybox.WatchUi;
import Toybox.Weather;

// Fixed 280-unit coordinates traced from approved sheet 07, AMOLED (bottom left).
// Lighting changes; the valley, river and right-hand cliff never move.
class Landscape {
    var scale = 1.0;
    var surfaceTint = 0;
    var surfaceBlend = 0.0;
    var skyRow;
    var skyRowWidth = 0;
    var moonAtlas;
    var moonLoadedFrame = -1;
    var lunar;
    var phaseHour = -1;
    var phaseValue = 0.0;
    var skyColors;
    var skyTop;
    var skyMiddle;
    var skyLow;
    var skyPalette = [0,0];
    function min(a,b) { return a < b ? a : b; }
    function max(a,b) { return a > b ? a : b; }
    function p(v) { return (v * scale).toNumber(); }
    function mix(a, b, t) {
        t = max(0.0, min(1.0, t));
        if (t == 0.0) { return a; }
        if (t == 1.0) { return b; }
        var r = (((a >> 16) & 255) * (1-t) + ((b >> 16) & 255) * t).toNumber();
        var g = (((a >> 8) & 255) * (1-t) + ((b >> 8) & 255) * t).toNumber();
        var c = ((a & 255) * (1-t) + (b & 255) * t).toNumber();
        return (r << 16) | (g << 8) | c;
    }
    function weatherKind(condition) {
        if (condition == null) { return 7; }
        if (condition == Weather.CONDITION_CLEAR || condition == Weather.CONDITION_FAIR) { return 0; }
        if (condition == Weather.CONDITION_HAIL) { return 9; }
        if (condition == Weather.CONDITION_ICE) { return 12; }
        if (condition == Weather.CONDITION_RAIN_SNOW || condition == Weather.CONDITION_LIGHT_RAIN_SNOW ||
            condition == Weather.CONDITION_HEAVY_RAIN_SNOW || condition == Weather.CONDITION_WINTRY_MIX ||
            condition == Weather.CONDITION_SLEET || condition == Weather.CONDITION_ICE_SNOW) { return 8; }
        if (condition == Weather.CONDITION_SNOW || condition == Weather.CONDITION_FLURRIES ||
            condition == Weather.CONDITION_LIGHT_SNOW || condition == Weather.CONDITION_HEAVY_SNOW) { return 4; }
        if (condition == Weather.CONDITION_THUNDERSTORMS ||
            condition == Weather.CONDITION_SCATTERED_THUNDERSTORMS) { return 5; }
        if (condition == Weather.CONDITION_RAIN || condition == Weather.CONDITION_SHOWERS ||
            condition == Weather.CONDITION_DRIZZLE || condition == Weather.CONDITION_LIGHT_RAIN ||
            condition == Weather.CONDITION_HEAVY_RAIN || condition == Weather.CONDITION_LIGHT_SHOWERS ||
            condition == Weather.CONDITION_HEAVY_SHOWERS || condition == Weather.CONDITION_SCATTERED_SHOWERS ||
            condition == Weather.CONDITION_FREEZING_RAIN) { return 3; }
        if (condition == Weather.CONDITION_WINDY) { return 13; }
        if (condition == Weather.CONDITION_TROPICAL_STORM || condition == Weather.CONDITION_HURRICANE ||
            condition == Weather.CONDITION_SQUALL || condition == Weather.CONDITION_TORNADO) { return 11; }
        if (condition == Weather.CONDITION_FOG || condition == Weather.CONDITION_MIST ||
            condition == Weather.CONDITION_HAZE || condition == Weather.CONDITION_HAZY) { return 6; }
        if (condition == Weather.CONDITION_SMOKE || condition == Weather.CONDITION_DUST ||
            condition == Weather.CONDITION_SAND || condition == Weather.CONDITION_SANDSTORM ||
            condition == Weather.CONDITION_VOLCANIC_ASH) { return 10; }
        if (condition == Weather.CONDITION_CLOUDY || condition == Weather.CONDITION_MOSTLY_CLOUDY ||
            condition == Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN || condition == Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW ||
            condition == Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW || condition == Weather.CONDITION_CHANCE_OF_SHOWERS ||
            condition == Weather.CONDITION_CHANCE_OF_SNOW || condition == Weather.CONDITION_CHANCE_OF_RAIN_SNOW ||
            condition == Weather.CONDITION_CHANCE_OF_THUNDERSTORMS || condition == Weather.CONDITION_UNKNOWN_PRECIPITATION) { return 2; }
        if (condition == Weather.CONDITION_PARTLY_CLOUDY || condition == Weather.CONDITION_THIN_CLOUDS ||
            condition == Weather.CONDITION_PARTLY_CLEAR || condition == Weather.CONDITION_MOSTLY_CLEAR) { return 1; }
        return 7; // Unknown and future conditions do not imply a clear sky.
    }
    function dawnFraction(minute, rise, set) {
        var dawn=max(0.0,1.0-(minute-rise).abs()/75.0);
        var dusk=max(0.0,1.0-(minute-set).abs()/75.0);
        return dawn+dusk>0.0?dawn/(dawn+dusk):0.0;
    }
    // Overlapping dawn and dusk in a short winter day blend continuously.
    function light(minute, rise, set) {
        if (minute < rise-75 || minute > set+75) { return [0x070F24,0x243968,0.0,0.0]; }
        var dawn = (minute-rise).abs();
        var dusk = (minute-set).abs();
        var glow = max(0.0,1.0-min(dawn,dusk)/75.0);
        var day = min(1.0,min((minute-(rise-75))/150.0,((set+75)-minute)/150.0));
        var top = mix(0x070F24,0x4A83A7,day);
        var low = mix(0x243968,0xDCE9CE,day);
        var tint=dawnFraction(minute,rise,set);
        top = mix(top,mix(0x081C35,0x20395A,tint),glow);
        low = mix(low,mix(0xFFD16A,0xFFE0B2,tint),glow);
        return [top,low,day,glow];
    }
    function polygon(dc, color, points) {
        // All callers pass fresh coordinate literals; scale these rather than
        // allocating a second polygon and another pair for every vertex.
        for (var i=0; i<points.size(); i+=1) { points[i][0]=p(points[i][0]); points[i][1]=p(points[i][1]); }
        dc.setColor(mix(color,surfaceTint,surfaceBlend),Graphics.COLOR_TRANSPARENT); dc.fillPolygon(points);
    }
    function cloudCover(kind) {
        if (kind == 1) { return 0.25; }
        if (kind == 2) { return 0.75; }
        if (kind == 3 || kind == 5 || kind == 9) { return 0.9; }
        if (kind == 4) { return 0.78; }
        if (kind == 6 || kind == 11) { return 0.95; }
        if (kind == 8 || kind == 10) { return 0.85; }
        if (kind == 7 || kind == 12) { return 0.45; }
        return 0.0;
    }
    // Original upstream glyphs; the phase now comes from the pinned SunCalc port.
    function moonPhase(seconds) {
        if(lunar==null) { lunar=new MoonPhase(); }
        return lunar.phase(seconds);
    }
    function currentMoonPhase() {
        var seconds=Time.now().value(); var hour=(seconds/3600).toNumber();
        if(hour!=phaseHour) { phaseValue=moonPhase(seconds); phaseHour=hour; }
        return phaseValue;
    }
    function releaseGraphics() { skyRow=null; moonAtlas=null; moonLoadedFrame=-1; }
    function loadMoonResource(id) { return WatchUi.loadResource(id); }
    function moonFrame(phase) { return Math.floor(phase*28+0.5).toNumber()%28; }
    function drawMoon(dc,color) {
        var frame=moonFrame(currentMoonPhase());
        if(frame==0) { return; }
        if(moonLoadedFrame!=frame) {
            var images=[Rez.Drawables.LandscapeMoon0,Rez.Drawables.LandscapeMoon1,
                Rez.Drawables.LandscapeMoon2,Rez.Drawables.LandscapeMoon3,
                Rez.Drawables.LandscapeMoon4,Rez.Drawables.LandscapeMoon5,
                Rez.Drawables.LandscapeMoon6,Rez.Drawables.LandscapeMoon7,
                Rez.Drawables.LandscapeMoon8,Rez.Drawables.LandscapeMoon9,
                Rez.Drawables.LandscapeMoon10,Rez.Drawables.LandscapeMoon11,
                Rez.Drawables.LandscapeMoon12,Rez.Drawables.LandscapeMoon13,
                Rez.Drawables.LandscapeMoon14,Rez.Drawables.LandscapeMoon15,
                Rez.Drawables.LandscapeMoon16,Rez.Drawables.LandscapeMoon17,
                Rez.Drawables.LandscapeMoon18,Rez.Drawables.LandscapeMoon19,
                Rez.Drawables.LandscapeMoon20,Rez.Drawables.LandscapeMoon21,
                Rez.Drawables.LandscapeMoon22,Rez.Drawables.LandscapeMoon23,
                Rez.Drawables.LandscapeMoon24,Rez.Drawables.LandscapeMoon25,
                Rez.Drawables.LandscapeMoon26,Rez.Drawables.LandscapeMoon27];
            try { moonAtlas=loadMoonResource(images[frame]); } catch(e) { moonAtlas=null; }
            if(moonAtlas==null) { return; }
            moonLoadedFrame=frame;
        }
        var transform=new Graphics.AffineTransform();
        var factor=p(20)/32.0;
        transform.scale(factor,factor);
        dc.drawBitmap2(p(143),p(30),moonAtlas,{:bitmapX=>0,:bitmapY=>0,
            :bitmapWidth=>32,:bitmapHeight=>32,:transform=>transform,
            :filterMode=>Graphics.FILTER_MODE_BILINEAR,:tintColor=>color});
    }
    function sunPosition(minute, rise, set) {
        var phase = (minute-rise)/max(1.0,(set-rise).toFloat());
        var arc=Math.sin(phase*Math.PI);
        // Keep sunrise/sunset in the valley; lift the disk into the narrow sky
        // right of Time07 (x<=149), with room before the cliff (x>=178).
        var lift=max(0.0,min(1.0,arc/0.18));
        lift=lift*lift*(3.0-2.0*lift);
        return [118+46*lift,214-arc*158];
    }
    function skyColor(top, middle, low, y) {
        // Keep the upper sky blue; concentrate twilight along the horizon.
        if (y < 130) { return mix(top,middle,y/130.0); }
        return mix(middle,low,min(1.0,(y-130)/72.0));
    }
    // RGB565 ordered dither. A two-row, two-color strip replaces a full
    // framebuffer; integer channel rounding keeps the cold frame within budget.
    function skyDither(color,threshold) {
        var bias=7-threshold;
        var r=((color>>16)&255)+bias;
        var g=((color>>8)&255)+(bias/2).toNumber();
        var b=(color&255)+bias;
        if(r>255) { r=255; }
        if(g>255) { g=255; }
        if(b>255) { b=255; }
        return ((r&0xF8)<<16)|((g&0xFC)<<8)|(b&0xF8);
    }
    function drawSky(dc,width,top,middle,low) {
        var fresh=false;
        var rows=((width+1)/2).toNumber();
        if(skyColors==null || skyColors.size()!=rows*2) {
            skyColors=[];
            for(var i=0;i<rows*2;i+=1) { skyColors.add(0); }
            skyTop=null;
        }
        if(top!=skyTop || middle!=skyMiddle || low!=skyLow) {
            for(var y=0;y<width;y+=2) {
                var color=skyColor(top,middle,low,(y+0.5)/scale);
                skyColors[y]=skyDither(color,2); skyColors[y+1]=skyDither(color,6);
            }
            skyTop=top; skyMiddle=middle; skyLow=low;
        }
        if(skyRow==null || skyRowWidth!=width) {
            try { skyRow=createSkyRow(width); } catch(e) { skyRow=null; }
            skyRowWidth=width;
            fresh=true;
        }
        var row=skyRow==null?null:skyRow.get();
        if(row==null) {
            // A missing graphics resource must still produce a complete sky.
            for(var y=0;y<width;y+=2) {
                dc.setColor(skyColors[y],Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(0,y,width,2);
            }
            return;
        }
        if(fresh || !row.isCached()) {
            row.setPalette([0,0xFFFFFF]);
            var stripDc=row.getDc();
            stripDc.setColor(0xFFFFFF,0); stripDc.clear();
            for(var x=0;x<width;x+=2) {
                stripDc.fillRectangle(x,1,1,1);
                if(x+1<width) { stripDc.fillRectangle(x+1,0,1,1); }
            }
        }
        for(var y=0;y<width;y+=2) {
            skyPalette[0]=skyColors[y]; skyPalette[1]=skyColors[y+1];
            row.setPalette(skyPalette);
            dc.drawBitmap(0,y,row);
        }
    }
    function createSkyRow(width) {
        return Graphics.createBufferedBitmap({:width=>width,:height=>2,:palette=>[0,0xFFFFFF]});
    }
    function sunGlow(dc,width,top,middle,low,sun,strength) {
        if(strength<=0.0) { return; }
        // Paint against each scanline's sky color, so no opaque halo disc appears.
        var radius=28.0;
        for(var y=max(0,p(sun[1]-radius));y<min(width,p(sun[1]+radius));y+=2) {
            var dy=y/scale-sun[1];
            var span=Math.sqrt(max(0.0,radius*radius-dy*dy));
            for(var band=0;band<3;band+=1) {
                var half=span*(1.0-band*0.28);
                var amount=strength*(0.025+band*0.05)*(1.0-dy*dy/(radius*radius));
                dc.setColor(mix(skyColor(top,middle,low,y/scale),0xFFE7B0,amount),Graphics.COLOR_TRANSPARENT);
                dc.fillRectangle(p(sun[0]-half),y,max(1,p(half*2)),2);
            }
        }
    }
    function draw(dc, width, minute, rise, set, condition) {
        scale = width / 280.0;
        surfaceBlend = 0.0;
        var colors = light(minute,rise,set);
        var day = colors[2]; var glow = colors[3]; var kind = weatherKind(condition);
        var dawnTint = dawnFraction(minute,rise,set);
        var cover = cloudCover(kind);
        glow = glow * (1.0-cover);
        var top = colors[0]; var low = colors[1];
        var wet=kind==3 || kind==5 || kind==8 || kind==9 || kind==11;
        var obscured=kind==6 || kind==10;
        var weatherTop=kind==4?0x7B96AE:(wet?0x40586D:(kind==10?0x887E71:0x748892));
        var weatherLow=kind==4?0xD7E3E3:(wet?0x96AFBA:(kind==10?0xC0B6A0:0xC8D4D5));
        top = mix(top,mix(0x081423,weatherTop,day),cover);
        low = mix(low,mix(0x1C2C41,weatherLow,day),cover);
        dc.setColor(top,top); dc.clear();
        var middle = mix(mix(top,low,0.42),mix(0xAD4F59,0xAF8297,dawnTint),glow);
        drawSky(dc,width,top,middle,low);
        if (minute >= rise-45 && minute <= set+45 && (kind < 2 || kind==13)) {
            var sun = sunPosition(minute,rise,set);
            sunGlow(dc,width,top,middle,low,sun,glow);
            dc.setColor(mix(0xFFE6AA,0xFFF4D1,day),Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(p(sun[0]),p(sun[1]),p(11));
        }
        // Distant atmospheric ridges stay connected to the valley silhouette.
        var haze = mix(mix(0x182942,0x9DBCC7,day),mix(0xE57A58,0xD6A3A0,dawnTint),glow*0.85);
        polygon(dc,haze,[[0,139],[20,137],[36,145],[52,137],[75,151],[48,154],[25,150],[0,159]]);
        polygon(dc,mix(haze,low,0.35),[[129,166],[145,151],[156,149],[163,137],[170,141],[183,126],[191,135],[192,167],[164,184],[138,178]]);
        polygon(dc,mix(haze,low,0.5),[[30,157],[59,162],[72,152],[96,170],[124,170],[145,159],[158,167],[129,183],[78,177]]);
        if (day < 0.3 && (kind < 2 || kind==13)) {
            dc.setColor(mix(top,0xB8CEE6,(1.0-day/0.3)*(1.0-cover)),Graphics.COLOR_TRANSPARENT);
            var stars = [[61,29],[145,21],[165,43],[37,72],[130,56],[182,28],[149,85]];
            for (var i=0;i<stars.size();i+=1) { dc.fillCircle(p(stars[i][0]),p(stars[i][1]),max(1,p(0.8))); }
            drawMoon(dc,mix(top,0xE8F0EE,1.0-day/0.3));
        }
        if (kind > 0 && !obscured && kind!=7 && kind!=12 && kind!=13) {
            var cloud = mix(0x17283F,kind==4?0xC0D0D5:(wet?0x879DAA:0xA5BAC6),day);
            polygon(dc,mix(cloud,top,0.62),[[0,49],[28,51],[43,46],[66,52],[89,50],[113,58],[142,59],[166,67],[108,65],[77,59],[37,62],[0,58]]);
            polygon(dc,mix(cloud,top,0.3),[[12,98],[33,90],[49,93],[68,87],[86,94],[106,94],[126,102],[91,103],[64,99],[39,102]]);
            polygon(dc,mix(cloud,top,0.4),[[120,65],[141,59],[156,61],[176,54],[194,62],[202,68],[179,72],[153,68]]);
            if (kind >= 2) {
                polygon(dc,mix(cloud,top,0.72),[[0,17],[37,26],[59,14],[90,28],[114,25],[138,39],[171,33],[211,54],[217,88],[189,80],[165,89],[128,70],[94,75],[65,62],[35,69],[0,59]]);
                polygon(dc,mix(cloud,low,wet?0.12:0.42),[[0,124],[27,120],[45,126],[70,121],[97,131],[121,129],[149,139],[174,132],[184,142],[148,143],[108,136],[61,134],[25,129],[0,131]]);
                if(wet) {
                    polygon(dc,mix(cloud,top,0.25),[[0,108],[24,111],[42,106],[66,114],[94,112],[118,122],[146,123],[168,130],[132,129],[102,124],[71,123],[40,116],[0,119]]);
                }
            }
        }
        // Wet surfaces lose saturation; fog reduces ridge contrast, not field contrast.
        surfaceTint = mix(0x132439,kind==10?0xB0A991:(kind==6?0xBACACD:(wet?0x435E71:0x9AB4C2)),day);
        surfaceBlend = obscured?0.7:(wet?0.4:cover*0.25);
        // Multiple ridges meet at a narrow valley; the tallest left peak is (30,143).
        polygon(dc,mix(mix(0x323D69,0x718EAB,day),0x8E526D,glow*0.5),[[0,158],[30,143],[56,182],[72,175],[93,199],[113,209],[131,203],[151,181],[161,186],[177,173],[190,139],[211,87],[280,150],[280,280],[0,280]]);
        polygon(dc,mix(mix(0x53638C,0xA9BDC6,day),0xC77C79,glow*0.6),[[30,143],[38,163],[56,182],[63,204],[50,192],[42,174]]);
        polygon(dc,mix(0x1F345B,0x527C98,day),[[0,158],[30,143],[42,174],[26,169],[14,187],[0,176]]);
        polygon(dc,mix(0x27385E,0x7390AF,day),[[42,174],[56,182],[72,175],[80,198],[93,199],[113,209],[81,212],[63,204]]);
        polygon(dc,mix(mix(0x485476,0x89A7B5,day),0xC37A6D,glow*0.35),[[72,175],[80,198],[93,199],[86,190]]);
        // Mist thins toward the nearer ridges; it never washes over the field wall.
        if(obscured) { surfaceBlend=0.44; }
        polygon(dc,mix(0x1A3357,0x437487,day),[[0,176],[14,187],[26,169],[42,174],[50,192],[63,204],[81,212],[113,216],[78,226],[0,231]]);
        polygon(dc,mix(0x0A203C,0x23546B,day),[[14,187],[26,169],[31,194],[43,207],[33,219],[17,209]]);
        polygon(dc,mix(0x152F50,0x346D81,day),[[42,174],[50,192],[63,204],[59,218],[43,207]]);
        polygon(dc,mix(0x314064,0x718FA4,day),[[151,181],[161,186],[155,204],[138,213],[113,216],[131,203]]);
        polygon(dc,mix(0x162F50,0x3F7085,day),[[161,186],[177,173],[190,139],[184,181],[168,204],[138,220],[138,213],[155,204]]);
        polygon(dc,mix(0x0C263F,0x295568,day),[[184,181],[168,204],[138,220],[117,225],[145,231],[177,220],[194,195]]);
        polygon(dc,mix(0x243A5A,0x578596,day),[[155,204],[168,204],[149,217],[131,220],[138,213]]);
        // Thin illuminated facets turn toward the valley's low sun.
        var ridgeLight = mix(mix(0x485675,0xA5B7BC,day),mix(0xF29962,0xE6BEA5,dawnTint),glow);
        polygon(dc,ridgeLight,[[30,143],[38,163],[56,182],[63,204],[59,191],[54,179],[39,159]]);
        polygon(dc,mix(ridgeLight,0x567A91,0.35),[[72,175],[80,198],[93,199],[88,196],[82,195],[76,179]]);
        polygon(dc,mix(ridgeLight,0x49697B,0.3),[[151,181],[161,186],[155,204],[138,213],[157,200],[164,184]]);
        // Steep cliff: illuminated broken rim, deep shadow behind all five fields.
        if (obscured) { surfaceBlend=0.12; }
        polygon(dc,mix(0x060F1A,0x102630,day),[[239,20],[229,41],[198,52],[189,81],[184,108],[178,147],[177,189],[166,222],[204,250],[280,280],[280,0]]);
        var rim = mix(mix(0x294362,0x587780,day),mix(0xF49A42,0xF0B575,dawnTint),glow*0.65);
        if (obscured) { rim=mix(rim,mix(0x14273A,0x36545F,day),0.5); }
        polygon(dc,rim,[[239,20],[229,41],[198,52],[189,81],[192,80],[200,57],[231,43],[243,24]]);
        polygon(dc,mix(rim,0xB17764,glow*0.32),[[239,20],[233,33],[231,43],[237,33],[243,24]]);
        polygon(dc,mix(rim,0xF6BF6B,glow*0.45),[[224,45],[198,52],[196,58],[202,56],[230,43]]);
        polygon(dc,mix(rim,0x803E43,glow*0.32),[[189,81],[184,108],[178,147],[181,139],[187,110],[192,88]]);
        polygon(dc,mix(rim,0xF0B575,glow*0.4),[[189,81],[186,98],[188,101],[192,88]]);
        polygon(dc,mix(rim,0xAD5345,glow*0.25),[[184,108],[183,132],[178,147],[183,170],[177,189],[184,180],[190,158]]);
        polygon(dc,mix(rim,0x163043,0.6),[[177,189],[166,222],[174,216],[182,201],[184,180]]);
        polygon(dc,mix(0x111827,0x1B343D,day),[[207,76],[219,68],[208,105],[195,117],[196,111]]);
        polygon(dc,mix(0x0D1725,0x18343F,day),[[195,117],[208,105],[218,121],[202,148],[190,158],[190,134]]);
        polygon(dc,mix(0x19202F,0x29414B,day),[[190,158],[202,148],[197,170],[184,180],[183,170]]);
        polygon(dc,mix(0x0F1C2C,0x1C3B46,day),[[184,180],[197,170],[202,202],[182,201],[174,216]]);
        polygon(dc,mix(0x070F1A,0x12313B,day),[[218,121],[230,92],[246,103],[237,148],[250,179],[224,216],[202,202],[197,170],[202,148]]);
        polygon(dc,mix(0x111B2B,0x23414B,day),[[174,216],[182,201],[202,202],[191,234],[204,250],[166,222]]);
        if(obscured) { surfaceBlend=0.05; }
        // Warm banks are wider than the thin, winding water reflection.
        var bank = mix(mix(0x34415E,0x84998E,day),mix(0xD87E48,0xDAB089,dawnTint),glow);
        polygon(dc,bank,[[72,215],[112,217],[139,218],[126,226],[149,235],[198,254],[206,267],[171,258],[120,235],[104,225],[88,224]]);
        var river = mix(mix(0x618BBD,0xADD9D1,day),0xFFE2A0,glow);
        polygon(dc,river,[[112,214],[138,215],[122,219],[116,222],[128,226],[125,230],[148,240],[145,242],[117,229],[113,224],[118,219],[104,217]]);
        polygon(dc,mix(river,0xB96642,glow*0.5),[[128,226],[145,231],[134,233],[149,239],[177,252],[164,248],[125,230]]);
        polygon(dc,mix(river,0xFFF3D0,glow*0.7),[[113,215],[133,215],[122,217],[112,217]]);
        polygon(dc,mix(river,0xEAF4E4,day*0.4),[[117,222],[125,225],[123,226],[116,224]]);
        // Foreground facets frame the fixed temperature, without a broad yellow fan.
        polygon(dc,mix(0x0A1B2A,0x16303A,day),[[0,225],[48,217],[73,225],[95,226],[113,243],[130,280],[0,280]]);
        polygon(dc,mix(mix(0x33415D,0x5C7B7F,day),0xAF6653,glow*0.6),[[48,217],[73,225],[64,236],[43,230]]);
        polygon(dc,mix(0x14283F,0x2B4C57,day),[[43,230],[64,236],[85,258],[65,266],[28,246]]);
        polygon(dc,mix(mix(0x2A3554,0x4B6C75,day),0x89544E,glow*0.45),[[73,225],[95,226],[113,243],[94,241],[85,258],[64,236]]);
        polygon(dc,mix(0x080F20,0x182F3D,day),[[85,258],[94,241],[113,243],[130,280],[108,280]]);
        polygon(dc,mix(0x102136,0x294450,day),[[113,243],[145,242],[171,258],[154,262],[181,280],[130,280]]);
        polygon(dc,mix(mix(0x374258,0x687F7C,day),0xA9604C,glow*0.5),[[145,242],[164,248],[177,252],[171,258],[154,262]]);
        polygon(dc,mix(0x070F1B,0x102B34,day),[[171,258],[206,267],[280,280],[181,280],[154,262]]);
        // Small angular conifers on the shaded left bank, as in the reference.
        for (var tree=0;tree<5;tree+=1) {
            var tx=16+tree*10; var ty=205+tree*4;
            polygon(dc,mix(0x061321,0x163D48,day),[[tx,ty-14],[tx-3,ty-6],[tx-1,ty-6],[tx-5,ty],[tx-2,ty],[tx-6,ty+6],[tx-1,ty+6],[tx-1,ty+11],[tx+1,ty+11],[tx+1,ty+6],[tx+6,ty+6],[tx+2,ty],[tx+5,ty],[tx+1,ty-6],[tx+3,ty-6]]);
        }
        // Weather is confined to the scenery; field surfaces and time stay legible.
        surfaceBlend = 0.0;
        var stormRain=kind==11 && (condition==Weather.CONDITION_TROPICAL_STORM || condition==Weather.CONDITION_HURRICANE);
        if (kind == 3 || kind == 5 || kind==8 || stormRain) {
            dc.setColor(mix(0x5A809E,0xA8C2CF,day),Graphics.COLOR_TRANSPARENT); dc.setPenWidth(1);
            var drops = condition==Weather.CONDITION_LIGHT_RAIN || condition==Weather.CONDITION_DRIZZLE || condition==Weather.CONDITION_LIGHT_SHOWERS ? 14 : 28;
            if (condition==Weather.CONDITION_HEAVY_RAIN || condition==Weather.CONDITION_HEAVY_SHOWERS || kind==5) { drops=38; }
            if(kind==8) { drops=condition==Weather.CONDITION_HEAVY_RAIN_SNOW?24:12; }
            if(stormRain) { drops=38; }
            for (var n=0;n<drops;n+=1) {
                var x=16+(n*31)%152; var yy=38+(n*47)%170;
                dc.drawLine(p(x),p(yy),p(x-(stormRain?6:3)),p(yy+7));
            }
            if (kind == 5) { polygon(dc,0xE7DAA6,[[169,68],[162,86],[168,85],[157,103],[179,79],[170,81]]); }
        }
        if (kind == 4 || kind==8 || kind==12) {
            polygon(dc,mix(0x9AAED0,0xE2EEF0,day),[[30,143],[38,163],[42,174],[33,160],[28,158],[24,160]]);
            polygon(dc,mix(0x9AAED0,0xE2EEF0,day),[[151,181],[161,186],[177,173],[167,189],[161,191],[156,188],[148,191]]);
            polygon(dc,mix(0x778FAA,0xCEE1E7,day),[[48,217],[73,225],[64,227],[52,222],[43,223]]);
            if(kind==4) {
                polygon(dc,mix(0x778FAA,0xE0ECEB,day),[[72,175],[76,179],[82,195],[78,192],[73,184]]);
                polygon(dc,mix(0x778FAA,0xD4E2E4,day),[[63,204],[81,212],[77,213],[70,210],[61,207]]);
            }
            dc.setColor(mix(0x9AAED0,0xE2EEF0,day),Graphics.COLOR_TRANSPARENT);
            var flakes = condition==Weather.CONDITION_HEAVY_SNOW ? 32 : 18;
            if(kind==8) { flakes=condition==Weather.CONDITION_HEAVY_RAIN_SNOW?18:9; }
            if(kind==12) { flakes=0; } // Ice is a surface condition, not falling snow.
            for (var j=0;j<flakes;j+=1) { dc.fillCircle(p(24+(j*43)%147),p(52+(j*29)%164),max(1,p(0.7))); }
        }
        if(kind==9) {
            for(var h=0;h<16;h+=1) {
                var hx=24+(h*43)%147; var hy=52+(h*29)%164;
                polygon(dc,mix(0x9AAED0,0xD8E8EB,day),[[hx,hy-1.5],[hx+1.5,hy],[hx,hy+1.5],[hx-1.5,hy]]);
            }
        }
        if(kind==11 || kind==13) {
            dc.setColor(mix(0x526A84,0x8EA6AF,day),Graphics.COLOR_TRANSPARENT);
            for(var w=0;w<7;w+=1) {
                var wx=20+(w*37)%120; var wy=62+w*19;
                dc.drawLine(p(wx),p(wy),p(wx+14),p(wy+2));
            }
        }
        dc.setPenWidth(1);
    }
}

