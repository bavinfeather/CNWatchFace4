import Toybox.Test;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Weather;

(:test) class LocationFixture {
    var coordinates;
    function initialize(lat,lon) { coordinates=[lat,lon]; }
    function toDegrees() { return coordinates; }
}
(:test) class SunDataFixture extends FourthData {
    var calls=0;
    var fail=false;
    var seconds=1791000000;
    var weatherCalls=0;
    var metricsCalls=0;
    function readSun(rising,place,moment) {
        calls+=1;
        if(fail) { return null; }
        var midnight=(moment.value()/86400).toNumber()*86400;
        return new Time.Moment(midnight+(rising?3600:43200));
    }
    function nowSeconds() { return seconds; }
    function readActivity() { metricsCalls+=1; return null; }
    function readWeather() { weatherCalls+=1; return new WeatherFixture(seconds); }
    function complication(type) { return null; }
    function readBodyHistory() { return null; }
    function readBodyCache() { return null; }
    function writeBodyCache(value,stamp) {}
}
(:test) class WeatherFixture {
    var temperature=10;
    var condition=Weather.CONDITION_CLEAR;
    var observationTime;
    var observationLocationPosition;
    function initialize(seconds) { observationTime=new Time.Moment(seconds); observationLocationPosition=new LocationFixture(31,121); }
}
(:test) class MissingGraphicsLandscape extends Landscape {
    function createSkyRow(width) { return null; }
    function currentMoonPhase() { return 0.5; }
    function loadMoonResource(id) { return null; }
}
(:test) function locationAndTimeZoneCache(logger) {
    var d=new SunDataFixture(); var now=d.seconds;
    var date=Gregorian.info(new Time.Moment(now),Time.FORMAT_SHORT);
    d.mergeLocation(new LocationFixture(31,121),now,now);
    d.updateSolar(date,now,28800); Test.assert(d.hasSunTimes && d.calls==2);
    d.mergeLocation(new LocationFixture(31.01,121.01),now+1,now+1);
    d.updateSolar(date,now+1,28800); Test.assert(d.calls==2);
    d.mergeLocation(new LocationFixture(39,116),now+2,now+2);
    d.updateSolar(date,now+2,28800); Test.assert(d.calls==4);
    d.updateSolar(date,now+3,32400); Test.assert(d.calls==6);
    d.updateSolar(Gregorian.info(new Time.Moment(now+86400),Time.FORMAT_SHORT),now+86400,32400);
    Test.assert(!d.hasSunTimes && d.location==null);
    return true;
}
(:test) function staleLocationAndSolarRetry(logger) {
    var d=new SunDataFixture(); var now=d.seconds;
    var date=Gregorian.info(new Time.Moment(now),Time.FORMAT_SHORT);
    d.mergeLocation(new LocationFixture(31,121),now-14401,now);
    d.updateSolar(date,now,28800); Test.assert(d.calls==0 && !d.hasSunTimes);
    d.mergeLocation(new LocationFixture(31,121),now,now); d.fail=true;
    d.updateSolar(date,now,28800); Test.assert(d.calls==2 && !d.hasSunTimes);
    d.fail=false; d.updateSolar(date,now+59,28800); Test.assert(d.calls==2);
    d.updateSolar(date,now+60,28800); Test.assert(d.calls==4 && d.hasSunTimes);
    d.mergeLocation(new LocationFixture(39,116),now-1,now+60);
    Test.assert(d.weatherLocation.toDegrees()[0]==31);
    return true;
}
(:test) function dataPollThrottling(logger) {
    var d=new SunDataFixture(); var start=d.seconds;
    var date=Gregorian.info(new Time.Moment(start),Time.FORMAT_SHORT);
    for(var i=0;i<61;i+=1) { d.seconds=start+i; d.update(date); }
    Test.assert(d.weatherCalls==1 && d.metricsCalls==7);
    d.seconds=start-10; d.update(date);
    Test.assert(d.weatherCalls==2 && d.metricsCalls==8);
    return true;
}
(:test) function aodMinuteShift(logger) {
    var v=new FourthView(); v.width=466; v.scale=466/280.0;
    v.aodFont=1; v.smallFont=2; v.battery=75;
    var first=new RecordingDc(); var second=new RecordingDc();
    var clock=new SceneClock(); var date=Gregorian.info(Time.now(),Time.FORMAT_SHORT);
    clock.min=8; v.drawAod(first,clock,date);
    clock.min=9; v.drawAod(second,clock,date);
    Test.assert(first.texts.size()==3 && second.texts.size()==3);
    // Current shared AOD moves its complete composition by one pixel.
    for(var i=0;i<3;i+=1) {
        Test.assert(second.texts[i][0]==first.texts[i][0]+1);
        Test.assert(second.texts[i][1]==first.texts[i][1]);
    }
    return true;
}
(:test) function missingGraphicsStillDrawsFrame(logger) {
    var s=new MissingGraphicsLandscape(); var dc=new RecordingDc();
    s.draw(dc,466,1320,360,1080,Weather.CONDITION_CLEAR);
    Test.assert(dc.rectangles>=233 && dc.polygons>20);
    s.releaseGraphics();
    s.draw(new RecordingDc(),360,720,360,1080,Weather.CONDITION_WINDY);
    var normal=new Landscape();
    normal.draw(new RecordingDc(),466,720,360,1080,Weather.CONDITION_CLEAR);
    normal.releaseGraphics();
    normal.draw(new RecordingDc(),466,720,360,1080,Weather.CONDITION_CLEAR);
    return true;
}
