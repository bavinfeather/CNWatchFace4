import Toybox.Application;
import Toybox.System;

class FourthOptions {
    var values;
    function initialize() { reload(); }
    function reload() {
        values=FourthSettingsData.defaults();
        var keys=values.keys();
        for(var k=0;k<keys.size();k+=1) {
            var key=keys[k];
            var saved=Application.Properties.getValue(key);
            var options=FourthSettingsData.choices(key);
            if(options!=null) {
                for(var i=0;i<options.size();i+=1) {
                    if(saved==options[i][0]) { values[key]=saved; break; }
                }
            } else if(saved instanceof String) { values[key]=saved; }
        }
    }
    function enabled(key) { return values[key]==true; }
    function chinese() {
        if(values["Language"]!=0) { return values["Language"]==1; }
        var lang=System.getDeviceSettings().systemLanguage;
        return lang==System.LANGUAGE_CHS || lang==System.LANGUAGE_CHT;
    }
    function text(zh,en) { return chinese()?zh:en; }
    function color(key,fallback) { return values[key]==-1?fallback:values[key]; }
    function is24Hour() {
        return values["TimeFormat"]==0?System.getDeviceSettings().is24Hour:values["TimeFormat"]==2;
    }
    function hourText(hour) {
        if(!is24Hour()) { hour=hour%12; if(hour==0) { hour=12; } }
        return hour.format(enabled("LeadingZero")?"%02d":"%d");
    }
    function timeText(clock) { return hourText(clock.hour)+":"+clock.min.format("%02d"); }
    function dateText(date) {
        var day=date.day.format("%02d");
        var style=values["DateStyle"];
        if(style>0) { day=date.month.format("%02d")+"/"+day; }
        if(style==1) { return day; }
        var weekdays=chinese()?["周日","周一","周二","周三","周四","周五","周六"]:
            ["SUN","MON","TUE","WED","THU","FRI","SAT"];
        return weekdays[date.day_of_week-1]+" "+day;
    }
    function amPm(clock) { return !is24Hour() && enabled("ShowAmPm")?(clock.hour<12?"AM":"PM"):""; }
    function feet() {
        return values["ElevationUnit"]==0?System.getDeviceSettings().elevationUnits==System.UNIT_STATUTE:values["ElevationUnit"]==2;
    }
    function fahrenheit() {
        return values["TemperatureUnit"]==0?System.getDeviceSettings().temperatureUnits==System.UNIT_STATUTE:values["TemperatureUnit"]==2;
    }
}
