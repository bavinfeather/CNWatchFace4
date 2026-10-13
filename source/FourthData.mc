import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Complications;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Weather;

class FourthData {
    var options;
    var steps;
    var body;
    var altitude;
    var stress;
    var recoveryMinutes;
    var temperature;
    var condition;
    var weatherTime = 0;
    var temperatureTime = 0;
    var nextWeather = 0;
    var nextSun = 0;
    var sunDay = -1;
    var sunrise = 360;
    var sunset = 1080;
    var hasSunTimes = false;
    var location;
    var activityLocation;
    var weatherLocation;
    var weatherLocationTime = 0;
    var sunCoordinates;
    var sunZone;
    var nextMetrics = 0;
    var lastUpdate = 0;
    var metricsDay = -1;
    var bodyTime = 0;
    var altitudeTime = 0;
    var stressTime = 0;
    var recoveryTime = 0;
    var recoveryUntil = 0;
    var bodyCacheLoaded = false;
    var bodySavedValue;
    var bodySavedTime = 0;

    function complication(type) {
        try { return Complications.getComplication(new Complications.Id(type)).value; }
        catch(e) { return null; }
    }
    function numeric(v) { return v instanceof Number || v instanceof Float; }
    function fresh(stamp, age, now) { return stamp>0 && stamp<=now+300 && now-stamp<=age; }
    function validBody(v) { return numeric(v) && v>=0 && v<=100; }
    function readSteps() { return ActivityMonitor.getInfo().steps; }
    function readBodyHistory() {
        if(SensorHistory has :getBodyBatteryHistory) {
            return SensorHistory.getBodyBatteryHistory({:period=>1,:order=>SensorHistory.ORDER_NEWEST_FIRST}).next();
        }
        return null;
    }
    function readBodyCache() { return Application.Storage.getValue("FourthBodyBattery"); }
    function writeBodyCache(value, stamp) { Application.Storage.setValue("FourthBodyBattery",[value,stamp]); }
    function loadBodyCache(now) {
        if(bodyCacheLoaded) { return; }
        bodyCacheLoaded=true;
        try {
            var saved=readBodyCache();
            if(saved instanceof Array && saved.size()==2 && validBody(saved[0]) &&
                saved[1] instanceof Number && fresh(saved[1],14400,now)) {
                body=saved[0]; bodyTime=saved[1]; bodySavedValue=body; bodySavedTime=bodyTime;
            }
        } catch(e) {}
    }
    function cacheBody(value, stamp) {
        if(stamp<bodyTime) { return; }
        body=value; bodyTime=stamp;
        if(bodySavedValue==value && stamp-bodySavedTime<900) { return; }
        try { writeBodyCache(value,stamp); bodySavedValue=value; bodySavedTime=stamp; } catch(e) {}
    }
    function updateBody(now) {
        loadBodyCache(now);
        var current=complication(Complications.COMPLICATION_TYPE_BODY_BATTERY);
        if(validBody(current)) { cacheBody(current,now); return; }
        try {
            var sample=readBodyHistory();
            if(sample!=null && validBody(sample.data) && sample.when!=null &&
                fresh(sample.when.value(),14400,now)) { cacheBody(sample.data,sample.when.value()); }
        } catch(e) {}
    }
    function expireMetrics(now) {
        if(!fresh(bodyTime,14400,now)) { body=null; }
        if(!fresh(altitudeTime,900,now)) { altitude=null; }
        if(!fresh(stressTime,900,now)) { stress=null; }
        if(!fresh(recoveryTime,900,now)) { recoveryMinutes=null; }
        else { recoveryMinutes=Toybox.Math.ceil((recoveryUntil>now?recoveryUntil-now:0)/60.0); }
    }
    // Merge independently: an incomplete weather response must not erase valid data.
    function mergeWeather(temp, sky, observed, now) {
        if (observed == null || observed > now + 300 || now - observed > 14400) { return false; }
        var useful=false;
        if (numeric(temp) && observed >= temperatureTime) {
            temperature = temp; temperatureTime = observed; useful=true;
        }
        if (sky != null && observed >= weatherTime) { condition = sky; weatherTime = observed; useful=true; }
        return useful;
    }
    function expireWeather(now) {
        if (now - temperatureTime > 14400) { temperature = null; }
        if (now - weatherTime > 14400) { condition = null; }
    }
    function readActivity() { return Activity.getActivityInfo(); }
    function nowSeconds() { return Time.now().value(); }
    function readWeather() { return Weather.getCurrentConditions(); }
    function readSun(rising, place, moment) {
        return rising ? Weather.getSunrise(place,moment) : Weather.getSunset(place,moment);
    }
    function mergeLocation(place, observed, now) {
        if(place!=null && observed!=null && observed>=weatherLocationTime &&
            observed<=now+300 && now-observed<=14400) {
            weatherLocation=place; weatherLocationTime=observed;
        }
    }
    function updateSolar(date, now, zone) {
        location=weatherLocation!=null && now-weatherLocationTime<=14400 ? weatherLocation : activityLocation;
        var coordinates=location==null?null:location.toDegrees();
        var moved=coordinates!=null && (sunCoordinates==null ||
            (coordinates[0]-sunCoordinates[0]).abs()>=0.1 || (coordinates[1]-sunCoordinates[1]).abs()>=0.1);
        var lost=coordinates==null && sunCoordinates!=null;
        var day=date.year*10000+date.month*100+date.day;
        if(day!=sunDay || zone!=sunZone || moved || lost) {
            sunDay=day; sunZone=zone; sunCoordinates=coordinates;
            nextSun=0; hasSunTimes=false; sunrise=360; sunset=1080;
        }
        if(!hasSunTimes && location!=null && now>=nextSun) {
            nextSun=now+60;
            try {
                var moment=new Time.Moment(now);
                var rise=readSun(true,location,moment); var set=readSun(false,location,moment);
                if(rise!=null && set!=null) {
                    var r=Gregorian.info(rise,Time.FORMAT_SHORT); var s=Gregorian.info(set,Time.FORMAT_SHORT);
                    var a=r.hour*60+r.min; var b=s.hour*60+s.min;
                    if(b>a) { sunrise=a; sunset=b; hasSunTimes=true; }
                }
            } catch(e) {}
        }
    }
    // Reuse a recent same-day snapshot for one wake frame only.
    // Polling deadlines stay due for the next normal frame.
    function canReuseWake(date) {
        var now=nowSeconds();
        return lastUpdate>0 && now>=lastUpdate && now-lastUpdate<300 &&
            metricsDay==date.year*10000+date.month*100+date.day &&
            sunZone==System.getClockTime().timeZoneOffset;
    }
    function update(date) {
        var now = nowSeconds();
        if(now<lastUpdate) {
            nextWeather=0; nextMetrics=0; nextSun=0; hasSunTimes=false;
            temperature=null; condition=null; temperatureTime=0; weatherTime=0;
            weatherLocation=null; weatherLocationTime=0;
            body=null; altitude=null; stress=null; recoveryMinutes=null;
            bodyTime=0; altitudeTime=0; stressTime=0; recoveryTime=0; recoveryUntil=0;
            bodyCacheLoaded=false; bodySavedValue=null; bodySavedTime=0; metricsDay=-1;
        }
        lastUpdate=now;
        var day=date.year*10000+date.month*100+date.day;
        if(day!=metricsDay) { metricsDay=day; steps=null; nextMetrics=0; }
        if(now>=nextMetrics) {
            nextMetrics=now+10;
            try { var daily=readSteps(); if(numeric(daily) && daily>=0) { steps=daily; } } catch(e) {}
            updateBody(now);
            var height=complication(Complications.COMPLICATION_TYPE_ALTITUDE);
            var strain=complication(Complications.COMPLICATION_TYPE_STRESS);
            var recovery=complication(Complications.COMPLICATION_TYPE_RECOVERY_TIME);
            if(numeric(height)) { altitude=height; altitudeTime=now; }
            if(numeric(strain) && strain>=0 && strain<=100) { stress=strain; stressTime=now; }
            if(numeric(recovery) && recovery>=0) {
                recoveryTime=now; recoveryUntil=now+recovery*60;
            }
            try {
                var activity = readActivity();
                if (activity!=null) {
                    if(!numeric(height) && numeric(activity.altitude)) { altitude=activity.altitude; altitudeTime=now; }
                    if(activity.currentLocation!=null) { activityLocation=activity.currentLocation; }
                }
            } catch(e) {}
        }
        if (now >= nextWeather) {
            nextWeather = now + 60;
            try {
                var weather = readWeather();
                if (weather != null) {
                    var observed=weather.observationTime==null?null:weather.observationTime.value();
                    var useful=mergeWeather(weather.temperature, weather.condition,observed,now);
                    mergeLocation(weather.observationLocationPosition,observed,now);
                    if(useful) { nextWeather = now + 300; }
                }
            } catch(e) {}
        }
        expireWeather(now);
        expireMetrics(now);
        updateSolar(date,now,System.getClockTime().timeZoneOffset);
    }
    function temperatureText() {
        var fahrenheit=options==null?System.getDeviceSettings().temperatureUnits==System.UNIT_STATUTE:options.fahrenheit();
        var suffix=options==null || !options.enabled("ShowTemperatureUnit")?"°":(fahrenheit?"°F":"°C");
        if (temperature == null) { return "--"+suffix; }
        var value = temperature;
        if (fahrenheit) { value = value * 1.8 + 32; }
        return value.format("%.0f") + suffix;
    }
    function shortFieldValue(id,battery) {
        if(id==1 && steps!=null && steps>=10000) { return (steps/1000.0).format("%.0f")+"k"; }
        if(id==3 && altitude!=null) {
            var feet=options==null?System.getDeviceSettings().elevationUnits==System.UNIT_STATUTE:options.feet();
            var value=feet?altitude*3.28084:altitude;
            if(value.abs()>=1000) {
                var format=value<0 || value>=10000?"%.0f":"%.1f";
                return (value/1000.0).format(format)+(feet?"kft":"km");
            }
            return value.format("%.0f")+(feet?"ft":"m");
        }
        return fieldValue(id,battery);
    }
    function fieldValue(id, battery) {
        if(id==0) { return ""; }
        if (id == 5) { return stress == null ? "--" : stress.format("%.0f"); }
        if (id == 6) {
            if (recoveryMinutes == null) { return "--"; }
            // Garmin's recovery complication is minutes; round remaining hours up.
            if (recoveryMinutes < 60) { return recoveryMinutes.format("%.0f") + "m"; }
            return Toybox.Math.ceil(recoveryMinutes / 60.0).format("%.0f") + "h";
        }
        if (id == 1) {
            if (steps == null) { return "--"; }
            return steps >= 1000 ? (steps / 1000.0).format("%.1f") + "k" : steps.format("%d");
        }
        if (id == 2) { return body == null ? "--" : body.format("%.0f"); }
        if (id == 3) {
            if (altitude == null) { return "--"; }
            var feet = options==null?System.getDeviceSettings().elevationUnits==System.UNIT_STATUTE:options.feet();
            return (feet ? altitude * 3.28084 : altitude).format("%.0f") + (feet ? "ft" : "m");
        }
        return battery == null ? "--" : battery.format("%.0f") + "%";
    }
}
