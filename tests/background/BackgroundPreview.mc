import Toybox.Application;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Weather;
import Toybox.System;

// Preview fixtures only. Every tile calls the production Landscape renderer.
class BackgroundLightApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() { return [new BackgroundPreview(0)]; }
}
class BackgroundWeatherApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() { return [new BackgroundPreview(1)]; }
}
class BackgroundNightWeatherApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() { return [new BackgroundPreview(2)]; }
}
class BackgroundClassificationApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() { return [new BackgroundPreview(3)]; }
}
class BackgroundMoonApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() { return [new BackgroundPreview(4)]; }
}
// A normal onUpdate, unlike unit-test VM execution, enforces the frame watchdog.
class BackgroundStressApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() { return [new BackgroundStressView()]; }
}
class BackgroundStressView extends WatchUi.View {
    var nextFrame=0;
    function initialize() { View.initialize(); }
    function onUpdate(dc) {
        var minutes=[330,360,375,720,1065,1080,1125,1155,1320];
        var conditions=[Weather.CONDITION_PARTLY_CLOUDY,Weather.CONDITION_CLOUDY,
            Weather.CONDITION_HEAVY_RAIN,Weather.CONDITION_HEAVY_SNOW,
            Weather.CONDITION_THUNDERSTORMS,Weather.CONDITION_FOG,
            Weather.CONDITION_HEAVY_RAIN_SNOW,Weather.CONDITION_HAIL,
            Weather.CONDITION_DUST,Weather.CONDITION_HURRICANE,
            Weather.CONDITION_WINDY,Weather.CONDITION_ICE,null];
        var weatherTotal=minutes.size()+conditions.size()*2;
        var total=weatherTotal+28;
        if(nextFrame>=total) { return; }
        var minute=720; var condition=Weather.CONDITION_CLEAR;
        if(nextFrame<minutes.size()) { minute=minutes[nextFrame]; }
        else if(nextFrame<weatherTotal) {
            var index=nextFrame-minutes.size();
            condition=conditions[index%conditions.size()];
            if(index>=conditions.size()) { minute=1320; }
        }
        var start=System.getTimer();
        var landscape=new Landscape();
        if(nextFrame>=weatherTotal) {
            minute=1320;
            landscape=new MoonFixtureLandscape((nextFrame-weatherTotal)/28.0);
        }
        landscape.draw(dc,dc.getWidth(),minute,360,1080,condition);
        System.println("BACKGROUND_FRAME "+nextFrame+" OK ms="+(System.getTimer()-start));
        nextFrame+=1;
        if(nextFrame<total) { WatchUi.requestUpdate(); }
        else { System.println("BACKGROUND_STRESS PASSED frames="+total); }
    }
}
class MoonFixtureLandscape extends Landscape {
    var fixturePhase;
    function initialize(phase) { fixturePhase=phase; }
    function currentMoonPhase() { return fixturePhase; }
}
class BackgroundSingleApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() { return [new BackgroundSingleView()]; }
}
class BackgroundSingleView extends WatchUi.View {
    function initialize() { View.initialize(); }
    function onUpdate(dc) {
        new Landscape().draw(dc,dc.getWidth(),1065,360,1080,Weather.CONDITION_CLEAR);
    }
}
class BackgroundPreview extends WatchUi.View {
    var page;
    var nextTile=0;
    function initialize(value) { View.initialize(); page=value; }
    function onUpdate(dc) {
        var scenes = page==0 ?
            [[375,Weather.CONDITION_CLEAR,"06:15 DAWN"],
             [720,Weather.CONDITION_CLEAR,"12:00 DAY"],
             [1065,Weather.CONDITION_CLEAR,"17:45 DUSK"],
             [1320,Weather.CONDITION_CLEAR,"22:00 NIGHT"]] :
            [[720,Weather.CONDITION_CLOUDY,"CLOUDY"],
             [720,Weather.CONDITION_RAIN,"RAIN"],
             [720,Weather.CONDITION_SNOW,"SNOW"],
             [720,Weather.CONDITION_FOG,"FOG"]];
        var size=(dc.getWidth()/2).toNumber();
        if (page==2) {
            for(var scene=0;scene<4;scene+=1){scenes[scene][0]=1320;}
        }
        if(page==3) {
            scenes=[[720,Weather.CONDITION_RAIN_SNOW,"RAIN + SNOW"],
                [720,Weather.CONDITION_HAIL,"HAIL"],
                [720,Weather.CONDITION_DUST,"DUST"],
                [1320,null,"UNKNOWN"]];
        }
        if(page==4) {
            scenes=[[1320,Weather.CONDITION_CLEAR,"NEW"],
                [1320,Weather.CONDITION_CLEAR,"FIRST QUARTER"],
                [1320,Weather.CONDITION_CLEAR,"FULL"],
                [1320,Weather.CONDITION_CLEAR,"LAST QUARTER"]];
        }
        if (nextTile==0) { dc.setColor(0,0); dc.clear(); }
        if (nextTile>=4) { return; }
        var landscape=new Landscape();
        if(page==4) { landscape=new MoonFixtureLandscape(nextTile/4.0); }
        // Spread this preview's four scenes across updates to respect the VM budget.
        var i=nextTile;
            var x=(i%2)*size; var y=(i/2).toNumber()*size;
            dc.setClip(x,y,size,size);
            landscape.draw(new BackgroundTileDc(dc,x,y,size),size,scenes[i][0],360,1080,scenes[i][1]);
            dc.setColor(0xE8EEF2,Graphics.COLOR_TRANSPARENT);
            dc.drawText(x+size/2,y+size-dc.getFontHeight(Graphics.FONT_XTINY)-2,Graphics.FONT_XTINY,scenes[i][2],Graphics.TEXT_JUSTIFY_CENTER);
        dc.clearClip();
        nextTile+=1;
        if(nextTile<4){WatchUi.requestUpdate();}
    }
}
// Translate only drawing coordinates, without allocating four framebuffers.
class BackgroundTileDc {
    var dc; var ox; var oy; var size;
    function initialize(target,x,y,width) { dc=target;ox=x;oy=y;size=width; }
    function setColor(a,b) { dc.setColor(a,b); }
    function clear() { dc.fillRectangle(ox,oy,size,size); }
    function fillRectangle(x,y,w,h) { dc.fillRectangle(ox+x,oy+y,w,h); }
    function fillCircle(x,y,r) { dc.fillCircle(ox+x,oy+y,r); }
    function drawBitmap(x,y,bitmap) { dc.drawBitmap(ox+x,oy+y,bitmap); }
    function drawBitmap2(x,y,bitmap,options) { dc.drawBitmap2(ox+x,oy+y,bitmap,options); }
    function drawLine(x,y,a,b) { dc.drawLine(ox+x,oy+y,ox+a,oy+b); }
    function setPenWidth(w) { dc.setPenWidth(w); }
    function fillPolygon(points) {
        var shifted=[];
        for(var i=0;i<points.size();i+=1){shifted.add([ox+points[i][0],oy+points[i][1]]);}
        dc.fillPolygon(shifted);
    }
}
