import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;
import Toybox.Weather;

class ReliabilityApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() { return [new ReliabilityView()]; }
}
class AodAuditApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() { return [new AodAuditView()]; }
}
class PowerBenchmarkApp extends Application.AppBase {
    function initialize() { AppBase.initialize(); }
    function getInitialView() { return [new PowerBenchmarkView()]; }
}
class AodAuditView extends FourthView {
    function initialize() { FourthView.initialize(); battery=100; }
    function onUpdate(dc) { drawAod(dc,System.getClockTime(),Gregorian.info(Time.now(),Time.FORMAT_SHORT)); }
}
class ReliabilityDate {
    var year=2026; var month=10; var day=3; var day_of_week=7;
}
class ReliabilityClock { var hour=22; var min=0; }
class ReliabilityLocation { function toDegrees() { return [31.0,121.0]; } }
class ReliabilityWeather {
    var temperature=18;
    var condition=Weather.CONDITION_CLEAR;
    var observationTime;
    var observationLocationPosition;
    function initialize(seconds) { observationTime=new Time.Moment(seconds); observationLocationPosition=new ReliabilityLocation(); }
}
class ReliabilityData extends FourthData {
    var seconds=1791000000;
    var sky=Weather.CONDITION_CLEAR;
    var polls=0;
    function nowSeconds() { return seconds; }
    function readActivity() { return null; }
    function readWeather() {
        polls+=1;
        var weather=new ReliabilityWeather(seconds); weather.condition=sky; return weather;
    }
    function readSteps() { return 12345; }
    function complication(type) {
        if(type==Toybox.Complications.COMPLICATION_TYPE_BODY_BATTERY) { return 100; }
        if(type==Toybox.Complications.COMPLICATION_TYPE_ALTITUDE) { return -999.0; }
        if(type==Toybox.Complications.COMPLICATION_TYPE_STRESS) { return 100; }
        if(type==Toybox.Complications.COMPLICATION_TYPE_RECOVERY_TIME) { return 5760; }
        return null;
    }
    function readBodyHistory() { return null; }
    function readBodyCache() { return null; }
    function writeBodyCache(value,stamp) {}
    function readSun(rising,place,moment) {
        var midnight=(moment.value()/86400).toNumber()*86400;
        return new Time.Moment(midnight+(rising?3600:43200));
    }
}
class ReliabilityLandscape extends Landscape {
    var fixturePhase=-1;
    function currentMoonPhase() { return fixturePhase<0?Landscape.currentMoonPhase():fixturePhase; }
}
// Calls the complete production onUpdate, with injected data and clock only.
// Every system callback is painted; one instance survives the full run.
class ReliabilityView extends FourthView {
    var frame=0;
    var clock;
    var date;
    var peak=0;
    var minimumFree=2147483647;
    var blockMin=2147483647;
    var warmMs=0; var warmCount=0;
    var coldMs=0; var coldCount=0;
    var cycles=0;
    var conditions=[Weather.CONDITION_CLEAR,Weather.CONDITION_WINDY,Weather.CONDITION_CLOUDY,
        Weather.CONDITION_HEAVY_RAIN,Weather.CONDITION_HEAVY_SNOW,Weather.CONDITION_FOG,
        Weather.CONDITION_HAIL,Weather.CONDITION_RAIN_SNOW,Weather.CONDITION_THUNDERSTORMS];
    var minutes=[1320,375,720,1065];
    function initialize() {
        FourthView.initialize(); data=new ReliabilityData(); landscape=new ReliabilityLandscape();
        clock=new ReliabilityClock(); date=new ReliabilityDate(); battery=75;
    }
    function readClock() { return clock; }
    function readDate() { return date; }
    function isLowPower() { return asleep; }
    function onUpdate(dc) {
        if(frame>=3000) { return; }
        // Bound each native callback to three complete frames, including cold resources.
        for(var batch=0;batch<3 && frame<3000;batch+=1) {
            var position=frame%100;
            if(position==80) { onEnterSleep(); }
            if(position==90) { onExitSleep(); cycles+=1; }
            var minute=minutes[(frame/60).toNumber()%minutes.size()];
            clock.hour=(minute/60).toNumber(); clock.min=minute%60;
            if(asleep) { clock.min=frame%60; }
            data.sky=conditions[(frame/60).toNumber()%conditions.size()];
            data.seconds+=1;
            if(frame%60==0) { data.nextWeather=0; }
            // Drive all moon assets and exercise the real astronomy on the first frame.
            landscape.fixturePhase=frame==0?-1:(frame%28)/28.0;
            var cold=frame%20==0;
            if(cold) { landscape.skyTop=null; }
            if(frame%250==0) { landscape.releaseGraphics(); }
            var start=System.getTimer();
            FourthView.onUpdate(dc);
            var elapsed=System.getTimer()-start;
            if(!asleep && isAmoled()) {
                if(cold) { coldMs+=elapsed; coldCount+=1; }
                else { warmMs+=elapsed; warmCount+=1; }
            }
            var stats=System.getSystemStats();
            if(stats.usedMemory>peak) { peak=stats.usedMemory; }
            if(stats.freeMemory<minimumFree) { minimumFree=stats.freeMemory; }
            if(stats.usedMemory<blockMin) { blockMin=stats.usedMemory; }
            frame+=1;
            if(frame%100==0) {
                System.println("RELIABILITY_BLOCK frame="+frame+" min="+blockMin+" peak="+peak+" free="+minimumFree);
                blockMin=2147483647;
            }
        }
        if(frame<3000) { WatchUi.requestUpdate(); }
        else {
            if(minimumFree<4096) { System.println("RELIABILITY FAILED memory headroom"); return; }
            System.println("RELIABILITY PASSED frames="+frame+" sleepWake="+cycles+" peak="+peak+" minFree="+minimumFree+" total="+System.getSystemStats().totalMemory);
            System.println("RELIABILITY_POWER warmMs="+warmMs+" warmFrames="+warmCount+" coldMs="+coldMs+" coldFrames="+coldCount+" weatherPolls="+data.polls);
        }
    }
}
// Paired CPU samples of identical complete frames; this is not battery telemetry.
class PowerBenchmarkView extends FourthView {
    var clock; var date; var samples=0; var primed=false;
    var coldMs=0; var warmMs=0;
    function initialize() {
        FourthView.initialize(); data=new ReliabilityData(); landscape=new ReliabilityLandscape();
        landscape.fixturePhase=0.5;
        clock=new ReliabilityClock(); clock.hour=12; date=new ReliabilityDate(); battery=75;
    }
    function readClock() { return clock; }
    function readDate() { return date; }
    function isLowPower() { return false; }
    function measure(dc,cold) {
        if(cold) { landscape.skyTop=null; }
        var start=System.getTimer(); FourthView.onUpdate(dc);
        var elapsed=System.getTimer()-start;
        if(cold) { coldMs+=elapsed; } else { warmMs+=elapsed; }
    }
    function onUpdate(dc) {
        if(samples>=200) { return; }
        if(!primed) {
            FourthView.onUpdate(dc); primed=true; WatchUi.requestUpdate(); return;
        }
        // One complete frame per native callback, with alternating pair order.
        var order=samples%4;
        measure(dc,order==0 || order==3);
        samples+=1;
        if(samples<200) { WatchUi.requestUpdate(); }
        else { System.println("POWER_PAIRED PASSED pairs=100 warmMs="+warmMs+" coldMs="+coldMs+" weatherPolls="+data.polls); }
    }
}
