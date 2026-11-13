import Toybox.Test;
import Toybox.Weather;
import Toybox.Graphics;
import Toybox.Math;

(:test) function sunLightingTransitions(logger) {
    var s = new Landscape();
    Test.assert(s.light(0,420,1020)[2] == 0);
    Test.assert(s.light(720,420,1020)[2] == 1);
    Test.assert(s.light(420,420,1020)[3] == 1);
    Test.assert(s.light(1020,420,1020)[3] == 1);
    Test.assert(s.light(1439,420,1020)[0] == s.light(0,420,1020)[0]);
    Test.assert(s.light(345,420,1020)[0] == s.light(344,420,1020)[0]);
    Test.assert(s.light(1095,420,1020)[0] == s.light(1096,420,1020)[0]);
    // Today's event times, rather than a hard-coded 06:00/18:00 palette.
    Test.assert(s.light(420,420,1020)[3] != s.light(420,360,1080)[3]);
    return true;
}
(:test) function partialAndStaleWeather(logger) {
    var d = new FourthData();
    d.mergeWeather(0,Weather.CONDITION_RAIN,100000,100000);
    d.mergeWeather(null,Weather.CONDITION_SNOW,100060,100060);
    Test.assert(d.temperature == 0 && d.condition == Weather.CONDITION_SNOW);
    d.mergeWeather(-3,null,100120,100120);
    Test.assert(d.temperature == -3 && d.condition == Weather.CONDITION_SNOW);
    d.mergeWeather(27,Weather.CONDITION_CLEAR,99000,100120);
    Test.assert(d.temperature == -3 && d.condition == Weather.CONDITION_SNOW);
    d.mergeWeather(44,Weather.CONDITION_CLEAR,null,100120);
    Test.assert(d.temperature == -3);
    d.expireWeather(114600);
    Test.assert(d.temperature == null && d.condition == null);
    return true;
}
(:test) function weatherCategories(logger) {
    var s = new Landscape();
    Test.assert(s.weatherKind(null) == 7);
    Test.assert(s.weatherKind(Weather.CONDITION_CLEAR) == 0);
    Test.assert(s.weatherKind(Weather.CONDITION_PARTLY_CLOUDY) == 1);
    Test.assert(s.weatherKind(Weather.CONDITION_CLOUDY) == 2);
    Test.assert(s.weatherKind(Weather.CONDITION_SHOWERS) == 3);
    Test.assert(s.weatherKind(Weather.CONDITION_SNOW) == 4);
    Test.assert(s.weatherKind(Weather.CONDITION_THUNDERSTORMS) == 5);
    Test.assert(s.weatherKind(Weather.CONDITION_FOG) == 6);
    Test.assert(s.weatherKind(Weather.CONDITION_RAIN_SNOW) == 8);
    Test.assert(s.weatherKind(Weather.CONDITION_HAIL) == 9);
    Test.assert(s.weatherKind(Weather.CONDITION_DUST) == 10);
    Test.assert(s.weatherKind(Weather.CONDITION_WINDY) == 13);
    Test.assert(s.cloudCover(s.weatherKind(Weather.CONDITION_WINDY)) == 0);
    Test.assert(s.weatherKind(Weather.CONDITION_ICE) == 12);
    Test.assert(s.weatherKind(Weather.CONDITION_UNKNOWN) == 7);
    Test.assert(s.weatherKind(999) == 7);
    // Every documented condition other than UNKNOWN has an explicit category.
    for(var condition=0;condition<53;condition+=1) { Test.assert(s.weatherKind(condition)!=7); }
    return true;
}
(:test) function moonDatesAndFrames(logger) {
    var s=new Landscape();
    var anchor=s.moonPhase(947182440);
    Test.assert(anchor<0.0178 || anchor>0.9822);
    // Independent astronomical events: Apr 8 2024 solar eclipse, Mar 14 2025 lunar eclipse.
    var eclipse=s.moonPhase(1712600460);
    Test.assert(eclipse<0.04 || eclipse>0.96);
    Test.assert((s.moonPhase(1741935540)-0.5).abs()<0.04);
    Test.assert(s.moonFrame(0)==0 && s.moonFrame(0.999)==0);
    Test.assert(s.moonFrame(0.25)==7);
    Test.assert(s.moonFrame(0.5)==14);
    Test.assert(s.moonFrame(0.75)==21);
    return true;
}
(:test) function precipitationAndUnknownScene(logger) {
    var s=new Landscape();
    var mixed=new RecordingDc(); s.draw(mixed,466,720,360,1080,Weather.CONDITION_RAIN_SNOW);
    Test.assert(mixed.lines>0 && mixed.circles>0);
    var hail=new RecordingDc(); s.draw(hail,466,720,360,1080,Weather.CONDITION_HAIL);
    Test.assert(hail.circles==0 && hail.lines==0);
    var ice=new RecordingDc(); s.draw(ice,466,720,360,1080,Weather.CONDITION_ICE);
    Test.assert(ice.circles==0 && ice.lines==0);
    var chance=new RecordingDc(); s.draw(chance,466,720,360,1080,Weather.CONDITION_CHANCE_OF_SHOWERS);
    Test.assert(chance.circles==0 && chance.lines==0);
    var unknown=new RecordingDc(); s.draw(unknown,466,1320,360,1080,null);
    Test.assert(unknown.circles==0 && unknown.lines==0);
    return true;
}
(:test) function solarEventGeometry(logger) {
    var s = new Landscape();
    // The sun must move below the valley horizon outside actual solar events.
    Test.assert(s.sunPosition(345,360,1080)[1]>214);
    Test.assert(s.sunPosition(375,360,1080)[1]<214);
    Test.assert(s.sunPosition(720,360,1080)[1]<60);
    Test.assert(s.sunPosition(1065,360,1080)[1]<214);
    Test.assert(s.sunPosition(1095,360,1080)[1]>214);
    // The same clock minute changes position when the real sunset changes.
    Test.assert(s.sunPosition(1065,360,1080)[1]!=s.sunPosition(1065,360,1200)[1]);
    Test.assert(s.light(375,360,1080)[0]!=s.light(1065,360,1080)[0]);
    return true;
}
(:test) function sunClearsStackedTime(logger) {
    var s=new Landscape();
    var events=[[360,1080],[420,1020],[720,780]];
    for(var i=0;i<events.size();i+=1) {
        for(var minute=events[i][0];minute<=events[i][1];minute+=1) {
            var sun=s.sunPosition(minute,events[i][0],events[i][1]);
            // Time07's widest digits occupy x=59..149, y=56..112 and 115..171.
            // Require room for the 11-unit sun plus a 3-unit visual gap.
            if(sun[1]+14>=56 && sun[1]-14<=171) {
                Test.assert(sun[0]-14>=149);
            }
        }
    }
    Test.assert(s.sunPosition(360,360,1080)[0]==118);
    Test.assert(s.sunPosition(1080,360,1080)[0]<118.01);
    Test.assert(s.sunPosition(720,360,1080)[0]==164);
    return true;
}
(:test) function shortDayLightingContinuity(logger) {
    var s = new Landscape();
    // A short winter day must not jump from morning to evening tint at noon.
    var before=s.light(749,720,780)[0];
    var after=s.light(751,720,780)[0];
    for(var channel=0;channel<3;channel+=1) {
        var shift=16-channel*8;
        Test.assert((((before>>shift)&255)-((after>>shift)&255)).abs()<8);
    }
    return true;
}
(:test) function zeroAndMissingFields(logger) {
    var d = new FourthData();
    Test.assert(d.fieldValue(1,null).equals("--"));
    d.steps=8200; d.body=0; d.altitude=0;
    Test.assert(d.fieldValue(1,null).equals("8.2k"));
    Test.assert(d.fieldValue(2,null).equals("0"));
    Test.assert(!d.fieldValue(3,null).equals("--"));
    Test.assert(d.fieldValue(4,0).equals("0%"));
    d.altitude=-40;
    Test.assert(d.fieldValue(3,null).substring(0,1).equals("-"));
    return true;
}

// Executes production draw paths in the VM. This checks calls and alignment,
// not native font rasterization or pixel-for-pixel visual acceptance.
(:test) class RecordingDc {
    var texts = [];
    var arcs = [];
    var circles=0;
    var lines=0;
    var rectangles=0;
    var polygons=0;
    var bitmaps=[];
    var color=0;
    function initialize() { texts=[]; arcs=[]; }
    function setColor(a,b) { Test.assert(a >= 0 && a <= 0xFFFFFF); color=a; }
    function getWidth() { return 466; }
    function getHeight() { return 466; }
    function getFontHeight(font) { return 24; }
    function clear() {}
    function fillRectangle(x,y,w,h) { Test.assert(w>0 && h>0); rectangles+=1; }
    function fillCircle(x,y,r) { Test.assert(r>=0); circles+=1; }
    function drawBitmap(x,y,bitmap) { Test.assert(bitmap!=null); }
    function drawBitmap2(x,y,bitmap,options) { Test.assert(bitmap!=null); bitmaps.add([x,y,options]); }
    function fillEllipse(x,y,w,h) { Test.assert(w>0 && h>0); }
    function fillPolygon(points) { Test.assert(points.size()>=3); polygons+=1; }
    function drawLine(x,y,a,b) { lines+=1; }
    function setPenWidth(w) { Test.assert(w>0); }
    function drawArc(x,y,r,d,a,b) { Test.assert(a != b); arcs.add([a,b]); }
    function getTextWidthInPixels(s,f) { return s.length()*12; }
    function drawText(x,y,f,s,flags) { texts.add([x,y,s,color,f]); }
}
(:test) function allSceneRenderPaths(logger) {
    var s = new Landscape();
    var conditions=[null,Weather.CONDITION_CLEAR,Weather.CONDITION_PARTLY_CLOUDY,
        Weather.CONDITION_CLOUDY,Weather.CONDITION_RAIN,Weather.CONDITION_SNOW,
        Weather.CONDITION_THUNDERSTORMS,Weather.CONDITION_FOG,Weather.CONDITION_RAIN_SNOW,
        Weather.CONDITION_HAIL,Weather.CONDITION_DUST,Weather.CONDITION_WINDY,Weather.CONDITION_ICE];
    var minutes=[0,315,360,720,1080,1125,1439];
    var sizes=[360,390,416,454,466];
    for(var i=0;i<conditions.size();i+=1) {
        for(var j=0;j<minutes.size();j+=1) {
            for(var k=0;k<sizes.size();k+=1) {
                s.draw(new RecordingDc(),sizes[k],minutes[j],360,1080,conditions[i]);
            }
        }
    }
    return true;
}
(:test) function verticalFieldsAndEmptyBattery(logger) {
    var v = new FourthView();
    v.width=466; v.scale=466/280.0; v.timeFont=1; v.fieldFont=2; v.labelFont=3;
    v.data.steps=8200; v.data.body=88; v.data.altitude=1286; v.data.temperature=18;
    var dc = new RecordingDc(); v.battery=0;
    v.drawActive(dc,new SceneClock(),new SceneDate());
    Test.assert(dc.arcs.size()==15); // Zero battery shows only separated empty segments.
    for(var a=0;a<dc.arcs.size();a+=1) { Test.assert(dc.arcs[a][1]-dc.arcs[a][0]<4); }
    var xs=[];
    var values=["8.2","88",v.valueParts(v.data.fieldValue(3,0))[0]];
    for(var i=0;i<dc.texts.size();i+=1) {
        var t=dc.texts[i];
        for(var field=0;field<3;field+=1) {
            if(t[2].equals(values[field])) { xs.add(t[0]); }
        }
    }
    Test.assert(xs.size()==3);
    for(var x=0;x<xs.size();x+=1) { Test.assert(xs[x]==v.p(185)); }
    return true;
}
(:test) class SceneClock { var hour=18; var min=8; var sec=32; }
(:test) class SceneDate { var day_of_week=5; var day=1; var month=10; }

(:test) function compactFieldUnitsAndMissingValues(logger) {
    var d=new FourthData();
    Test.assert(d.fieldValue(5,null).equals("--") && d.fieldValue(6,null).equals("--"));
    d.stress=0; d.recoveryMinutes=0;
    Test.assert(d.fieldValue(5,null).equals("0") && d.fieldValue(6,null).equals("0m"));
    d.recoveryMinutes=59; Test.assert(d.fieldValue(6,null).equals("59m"));
    d.recoveryMinutes=60; Test.assert(d.fieldValue(6,null).equals("1h"));
    d.recoveryMinutes=61; Test.assert(d.fieldValue(6,null).equals("2h"));
    d.recoveryMinutes=720; Test.assert(d.fieldValue(6,null).equals("12h"));
    d.altitude=1500;
    Test.assert(!d.shortFieldValue(3,null).equals(d.fieldValue(3,null)));
    return true;
}
(:test) function fiveFieldHierarchyAndSleepRelease(logger) {
    var v=new FourthView();
    v.options.values["Language"]=2;
    v.width=466; v.scale=466/280.0; v.timeFont=1; v.fieldFont=2; v.labelFont=3; v.smallFont=3;
    v.fields=[1,2,3]; v.shortFields=[5,6];
    v.data.steps=8200; v.data.body=88; v.data.altitude=1286; v.data.stress=28; v.data.recoveryMinutes=720;
    var dc=new RecordingDc(); v.drawActive(dc,new SceneClock(),new SceneDate());
    var names=["STEPS","BB","ALT"];
    var values=["8.2","88",v.valueParts(v.data.fieldValue(3,null))[0]];
    for(var i=0;i<3;i+=1) {
        var label=null; var number=null;
        for(var j=0;j<dc.texts.size();j+=1) {
            if(dc.texts[j][2].equals(names[i])) { label=dc.texts[j]; }
            if(dc.texts[j][2].equals(values[i])) { number=dc.texts[j]; }
        }
        Test.assert(label!=null && number!=null && label[0]==v.p(185) && number[0]==label[0]);
        var unit=v.valueParts(v.data.fieldValue(v.fields[i],null))[1];
        if(!unit.equals("")) {
            var unitX=number[0]+dc.getTextWidthInPixels(number[2],number[4])+v.p(2);
            var unitY=v.p(86+i*50+23);
            var foundUnit=false;
            for(var k=0;k<dc.texts.size();k+=1) {
                var t=dc.texts[k];
                if(t[2].equals(unit) && t[0]==unitX && t[1]==unitY) { foundUnit=true; }
            }
            Test.assert(foundUnit);
        }
        Test.assert(number[1]-label[1]==v.p(86+i*50+20)-v.p(86+i*50));
    }
    Test.assert(v.shortIcons[0]!=null && v.shortIcons[1]!=null);
    // Both new groups have an icon left of the value and center on the main column.
    var icons=[];
    for(var b=0;b<dc.bitmaps.size();b+=1) {
        if(dc.bitmaps[b][2][:bitmapWidth]==v.p(13)) { icons.add(dc.bitmaps[b]); }
    }
    Test.assert(icons.size()==2);
    for(var slot=0;slot<2;slot+=1) {
        var icon=icons[slot]; var text=null;
        for(var t=0;t<dc.texts.size();t+=1) {
            if(dc.texts[t][2].equals(slot==0?"28":"12")) { text=dc.texts[t]; }
        }
        Test.assert(text!=null);
        Test.assert(icon[0]+v.p(13)<text[0]);
        var unitWidth=slot==0?0:v.p(1)+dc.getTextWidthInPixels("h",v.unitFont);
        Test.assert((icon[0]+(v.p(13)+v.p(4)+dc.getTextWidthInPixels(text[2],3)+unitWidth)/2-v.p(213)).abs()<=1);
    }
    var savedIcons=[v.shortIcons[0],v.shortIcons[1]];
    v.onEnterSleep(); Test.assert(v.shortIcons[0]==savedIcons[0] && v.shortIcons[1]==savedIcons[1]);
    v.shortFields=[0,0]; dc=new RecordingDc(); v.drawActive(dc,new SceneClock(),new SceneDate());
    Test.assert(v.shortIcons[0]==null && v.shortIcons[1]==null);
    for(var remaining=0;remaining<dc.texts.size();remaining+=1) {
        Test.assert(!dc.texts[remaining][2].equals("28") && !dc.texts[remaining][2].equals("12"));
    }
    return true;
}

(:test) function nativeF9RenderAndFontBounds(logger) {
    var reference=Graphics.createBufferedBitmap({:width=>466,:height=>466});
    var bitmap=reference.get();
    var dc=bitmap.getDc();
    var v=new FourthView();
    v.onLayout(dc);
    v.data.steps=8200; v.data.body=88; v.data.altitude=1286; v.data.temperature=18;
    v.battery=75;
    logger.debug("Time font height="+dc.getFontHeight(v.timeFont)+", 88 width="+dc.getTextWidthInPixels("88",v.timeFont));
    logger.debug("Elevation width="+dc.getTextWidthInPixels(v.data.fieldValue(3,75),v.fieldFont));
    Test.assert(dc.getFontHeight(v.timeFont)>=v.p(54));
    for (var value=0;value<60;value+=1) {
        var digits=value.format("%02d");
        Test.assert(dc.getTextWidthInPixels(digits,v.timeFont)>=v.p(82));
        Test.assert(dc.getTextWidthInPixels(digits,v.timeFont)<=v.p(90));
    }
    v.drawActive(dc,new SceneClock(),new SceneDate());
    v.data.steps=12345; v.data.body=100; v.data.altitude=-999;
    v.data.stress=100; v.data.recoveryMinutes=5760;
    for(var id=1;id<=6;id+=1) {
        var value=v.data.shortFieldValue(id,100);
        var parts=v.valueParts(value);
        var font=v.compactFont!=null?v.compactFont:v.smallFont;
        var unitWidth=parts[1].equals("")?0:v.p(1)+dc.getTextWidthInPixels(parts[1],v.unitFont);
        var total=v.p(13)+v.p(4)+dc.getTextWidthInPixels(parts[0],font)+unitWidth;
        if(total>v.p(48)) { font=v.labelFont; total=v.p(13)+v.p(4)+dc.getTextWidthInPixels(parts[0],font)+unitWidth; }
        var right=v.p(213)+total/2.0;
        var bottom=v.p(230)+dc.getFontHeight(font)/2.0;
        var dx=right-233; var dy=bottom-233;
        logger.debug("Compact field "+id+" value="+value+" width="+total+" right="+right+" bottom="+bottom);
        Test.assert(dx*dx+dy*dy<231*231);
    }
    v.drawAod(dc,new SceneClock(),Toybox.Time.Gregorian.info(Toybox.Time.now(),Toybox.Time.FORMAT_SHORT));
    return true;
}

(:test) function stackedTimeColorsAndUnits(logger) {
    var v=new FourthView();
    var examples=["8.2k","-1286ft","100%","12h","--","0m"];
    var numbers=["8.2","-1286","100","12","--","0"];
    var units=["k","ft","%","h","","m"];
    for(var i=0;i<examples.size();i+=1) {
        var parts=v.valueParts(examples[i]);
        Test.assert(parts[0].equals(numbers[i]) && parts[1].equals(units[i]));
    }
    v.timeFont=1; v.fieldFont=2; v.labelFont=3; v.smallFont=3; v.unitFont=4;
    v.shortFields=[0,0];
    var dc=new RecordingDc(); v.drawActive(dc,new SceneClock(),new SceneDate());
    var hour=dc.texts[1]; var minute=dc.texts[2];
    Test.assert(hour[0]==minute[0] && hour[1]<minute[1]);
    Test.assert(hour[3]!=minute[3] && hour[4]==minute[4]);
    var levels=[null,-1,0,100,101];
    for(var b=0;b<levels.size();b+=1) {
        v.battery=levels[b]; var batteryDc=new RecordingDc(); v.drawBattery(batteryDc,0xFFCAA1);
        Test.assert(batteryDc.arcs.size()==(b<3?15:30));
        for(var j=0;j<batteryDc.arcs.size();j+=1) {
            Test.assert(batteryDc.arcs[j][0]>=143 && batteryDc.arcs[j][1]<=218);
        }
    }
    return true;
}
