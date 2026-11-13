import Toybox.Test;
import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Complications;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Application;
import Toybox.Weather;

(:test) class MetricsFailureFixture extends SunDataFixture {
    var missing=false;
    function complication(type) {
        if(missing) { return null; }
        if(type==Complications.COMPLICATION_TYPE_BODY_BATTERY) { return 73; }
        if(type==Complications.COMPLICATION_TYPE_ALTITUDE) { return 123; }
        if(type==Complications.COMPLICATION_TYPE_STRESS) { return 28; }
        if(type==Complications.COMPLICATION_TYPE_RECOVERY_TIME) { return 60; }
        return null;
    }
}
(:test) class EmptyWeatherFixture extends SunDataFixture {
    function readWeather() {
        var weather=new WeatherFixture(seconds);
        weather.temperature=null; weather.condition=null;
        return weather;
    }
}
(:test) function transientMetricsDoNotEraseValidValues(logger) {
    var d=new MetricsFailureFixture();
    var date=Gregorian.info(new Time.Moment(d.seconds),Time.FORMAT_SHORT);
    d.update(date); d.missing=true; d.seconds+=10; d.update(date);
    Test.assert(d.body==73 && d.altitude==123 && d.stress==28 && d.recoveryMinutes==60);
    return true;
}
(:test) function emptyWeatherUsesRetryInterval(logger) {
    var d=new EmptyWeatherFixture();
    d.update(Gregorian.info(new Time.Moment(d.seconds),Time.FORMAT_SHORT));
    Test.assert(d.nextWeather==d.seconds+60);
    return true;
}
(:test) function missingVectorFontKeepsDegreeGlyph(logger) {
    var v=new FourthView(); v.scale=466/280.0;
    v.fieldFont=WatchUi.loadResource(Rez.Fonts.Small); v.smallFont=v.fieldFont;
    v.options.values["TemperatureUnit"]=1; v.data.options=v.options; v.data.temperature=-12;
    v.options.values["ShowWeatherText"]=false;
    var dc=new RecordingDc(); v.drawTemperatureWeather(dc);
    Test.assert(dc.texts[0][2].equals("-12°C"));
    Test.assert(dc.texts[0][4]==Graphics.FONT_SMALL || dc.texts[0][4]==Graphics.FONT_XTINY);
    v.scale=416/280.0; v.data.temperature=-999; dc=new RecordingDc(); v.drawTemperatureWeather(dc);
    Test.assert(dc.texts[0][2].equals("-999°C") && dc.texts[0][4]==Graphics.FONT_XTINY);
    return true;
}

(:test) function metricsExpiryAndRecoveryCountdown(logger) {
    var d=new MetricsFailureFixture(); var start=d.seconds;
    var date=Gregorian.info(new Time.Moment(start),Time.FORMAT_SHORT);
    d.update(date); d.missing=true;
    d.seconds=start+61; d.update(date);
    Test.assert(d.recoveryMinutes==59 && d.body==73);
    d.seconds=start+901; d.update(date);
    Test.assert(d.altitude==null && d.stress==null && d.recoveryMinutes==null && d.body==73);
    d.seconds=start+14401; d.update(Gregorian.info(new Time.Moment(d.seconds),Time.FORMAT_SHORT));
    Test.assert(d.body==null);
    return true;
}

(:test) class BodyHistorySample {
    var data; var when;
    function initialize(value,stamp) { data=value; when=new Time.Moment(stamp); }
}
(:test) class CacheDataFixture extends SunDataFixture {
    var currentBody; var history; var saved; var writes=0; var dailySteps=1200;
    function complication(type) { return type==Complications.COMPLICATION_TYPE_BODY_BATTERY?currentBody:null; }
    function readBodyHistory() { return history; }
    function readBodyCache() { return saved; }
    function writeBodyCache(value,stamp) { saved=[value,stamp]; writes+=1; }
    function readSteps() { return dailySteps; }
    function tick() { update(Gregorian.info(new Time.Moment(seconds),Time.FORMAT_SHORT)); }
}
(:test) function bodyFallbackAndStorageThrottle(logger) {
    var d=new CacheDataFixture(); var start=d.seconds;
    d.saved=[66,start-100]; d.history=new BodyHistorySample(70,start-20);
    d.tick(); Test.assert(d.body==70 && d.bodyTime==start-20 && d.writes==1);
    d.currentBody=0; d.seconds+=10; d.tick();
    Test.assert(d.body==0 && d.writes==2); // A valid zero wins over history.
    d.seconds+=10; d.tick(); Test.assert(d.writes==2);
    d.currentBody=101; d.history=new BodyHistorySample(99,start-30);
    d.seconds+=10; d.tick(); Test.assert(d.body==0 && d.writes==2);
    d.currentBody=0; d.seconds=start+910; d.tick(); Test.assert(d.writes==3);
    var restart=new CacheDataFixture(); restart.seconds=d.seconds; restart.saved=d.saved;
    restart.tick(); Test.assert(restart.body==0 && restart.writes==0);
    return true;
}
(:test) function invalidAndExpiredBodyCache(logger) {
    var d=new CacheDataFixture(); var now=d.seconds;
    var bad=["old",[],[0],[101,now],[50,"bad"],[50,now-14401],[50,now+301]];
    for(var i=0;i<bad.size();i+=1) {
        var item=new CacheDataFixture(); item.saved=bad[i]; item.tick();
        Test.assert(item.body==null && item.writes==0);
    }
    d.history=new BodyHistorySample(80,now-14401); d.tick(); Test.assert(d.body==null);
    d.history=new BodyHistorySample(-1,now); d.seconds+=10; d.tick(); Test.assert(d.body==null);
    d.history=new BodyHistorySample(0,now); d.seconds+=10; d.tick(); Test.assert(d.body==0);
    return true;
}
(:test) function dailyStepsAndClockRollback(logger) {
    var d=new CacheDataFixture(); d.currentBody=73; d.tick();
    var date=Gregorian.info(new Time.Moment(d.seconds),Time.FORMAT_SHORT);
    Test.assert(d.steps==1200 && d.writes==1);
    d.dailySteps=null; d.seconds+=10; d.tick(); Test.assert(d.steps==1200);
    // Force the next local day inside the poll interval: yesterday must disappear.
    date.day+=1; d.seconds+=1; d.update(date); Test.assert(d.steps==null);
    d.seconds-=1000; d.dailySteps=0; d.tick();
    Test.assert(d.steps==0 && d.body==73 && d.bodyTime==d.seconds && d.writes==2);
    return true;
}
(:test) class PartialWeatherFixture extends CacheDataFixture {
    var temp=0; var sky; var observedDelta=0; var missingTime=false; var throwWeather=false;
    function readWeather() {
        weatherCalls+=1;
        if(throwWeather) { throw new Toybox.Lang.Exception(); }
        var w=new WeatherFixture(seconds+observedDelta);
        w.temperature=temp; w.condition=sky;
        if(missingTime) { w.observationTime=null; }
        return w;
    }
}
(:test) function weatherRetryAndPartialZero(logger) {
    var d=new PartialWeatherFixture(); d.tick();
    Test.assert(d.temperature==0 && d.condition==null && d.nextWeather==d.seconds+300);
    d.seconds+=300; d.temp=null; d.sky=Weather.CONDITION_RAIN; d.tick();
    Test.assert(d.temperature==0 && d.condition==Weather.CONDITION_RAIN && d.nextWeather==d.seconds+300);
    d.seconds+=300; d.temp=99; d.missingTime=true; d.tick();
    Test.assert(d.temperature==0 && d.nextWeather==d.seconds+60);
    d.seconds+=60; d.missingTime=false; d.observedDelta=-14401; d.tick();
    Test.assert(d.temperature==0 && d.nextWeather==d.seconds+60);
    d.seconds+=60; d.observedDelta=301; d.tick();
    Test.assert(d.temperature==0 && d.nextWeather==d.seconds+60);
    d.seconds+=60; d.throwWeather=true; d.tick();
    Test.assert(d.temperature==0 && d.nextWeather==d.seconds+60);
    return true;
}
(:test) function repeatedUnitSwitchKeepsRawData(logger) {
    var d=new FourthData(); d.options=new FourthOptions(); d.temperature=18; d.altitude=-40;
    for(var i=0;i<3;i+=1) {
        d.options.values["TemperatureUnit"]=2; d.options.values["ElevationUnit"]=2;
        Test.assert(d.temperatureText().equals("64°F") && d.fieldValue(3,null).equals("-131ft"));
        d.options.values["TemperatureUnit"]=1; d.options.values["ElevationUnit"]=1;
        Test.assert(d.temperatureText().equals("18°C") && d.fieldValue(3,null).equals("-40m"));
        Test.assert(d.temperature==18 && d.altitude==-40);
    }
    return true;
}
(:test) function invalidSettingsAndIndependentColorPersistence(logger) {
    var defaults=FourthSettingsData.defaults(); var keys=defaults.keys(); var saved={};
    for(var i=0;i<keys.size();i+=1) { saved[keys[i]]=Application.Properties.getValue(keys[i]); }
    try {
        for(var k=0;k<keys.size();k+=1) { Application.Properties.setValue(keys[k],"bad"); }
        var invalid=new FourthOptions();
        for(var check=0;check<keys.size();check+=1) {
            if(!keys[check].equals("LicenseKey")) { Test.assert(invalid.values[keys[check]]==defaults[keys[check]]); }
        }
        Application.Properties.setValue("HourColor",0);
        Application.Properties.setValue("MinuteColor",0x80D6B4);
        Application.Properties.setValue("FieldLabelColor",0xA998E8);
        Application.Properties.setValue("FieldValueColor",0xFF7788);
        var view=new FourthView();
        Application.Properties.setValue("TemperatureUnit",2); view.reloadSettings();
        Test.assert(view.options.color("HourColor",1)==0 && view.options.fahrenheit());
        var restart=new FourthView();
        Test.assert(restart.options.values["MinuteColor"]==0x80D6B4 &&
            restart.options.values["FieldLabelColor"]==0xA998E8 && restart.options.values["FieldValueColor"]==0xFF7788);
    } catch(e) {
        for(var restore=0;restore<keys.size();restore+=1) { Application.Properties.setValue(keys[restore],saved[keys[restore]]); }
        throw e;
    }
    for(var end=0;end<keys.size();end+=1) { Application.Properties.setValue(keys[end],saved[keys[end]]); }
    return true;
}
(:test) class LifecycleViewFixture extends AwakeSettingsView {
    function initialize() { AwakeSettingsView.initialize(); data=new CacheDataFixture(); }
}
(:test) class FrameRecordingDc extends RecordingDc {
    var skyRows=0;
    function drawBitmap(x,y,bitmap) { Test.assert(bitmap!=null); skyRows+=1; }
}
(:test) function fullFramesAndAodPollingBoundary(logger) {
    var v=new LifecycleViewFixture(); var dc=new FrameRecordingDc(); v.onLayout(dc);
    v.options.values["ShowSecondsActive"]=true; v.options.values["Language"]=2;
    v.onUpdate(dc); var first=v.data.metricsCalls;
    Test.assert(dc.polygons>20 && first==1);
    // The OS may discard the old frame; the same minute still requires a complete redraw.
    var again=new FrameRecordingDc(); v.onUpdate(again);
    Test.assert(again.polygons>20 && (again.skyRows>=233 || again.rectangles>=233) && v.data.metricsCalls==first);
    v.onEnterSleep(); v.data.seconds+=60;
    var asleep=new RecordingDc(); v.onUpdate(asleep);
    Test.assert(v.data.metricsCalls==first && asleep.texts.size()==4 && asleep.polygons<20);
    for(var t=0;t<asleep.texts.size();t+=1) { Test.assert(!asleep.texts[t][2].equals(":"+v.readClock().sec.format("%02d"))); }
    v.onExitSleep(); var awake=new RecordingDc(); v.onUpdate(awake);
    Test.assert(awake.polygons>20 && v.data.metricsCalls==first);
    var next=new RecordingDc(); v.onUpdate(next);
    Test.assert(next.polygons>20 && v.data.metricsCalls==first+1);
    return true;
}
