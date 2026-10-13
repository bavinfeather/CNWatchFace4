import Toybox.Application;
import Toybox.Test;
import Toybox.Weather;

(:test) function timeFormatBoundaries(logger) {
    var o=new FourthOptions(); o.values["TimeFormat"]=1;
    Test.assert(o.hourText(0).equals("12") && o.hourText(12).equals("12") && o.hourText(23).equals("11"));
    var clock=new SceneClock(); clock.hour=0; Test.assert(o.amPm(clock).equals("AM"));
    clock.hour=12; Test.assert(o.amPm(clock).equals("PM"));
    o.values["ShowAmPm"]=false; Test.assert(o.amPm(clock).equals(""));
    o.values["TimeFormat"]=2; Test.assert(o.hourText(0).equals("00") && o.hourText(23).equals("23"));
    o.values["LeadingZero"]=false; Test.assert(o.hourText(8).equals("8"));
    o.values["Language"]=1;
    Test.assert(o.dateText(new SceneDate()).equals("周四 01"));
    o.values["DateStyle"]=1; Test.assert(o.dateText(new SceneDate()).equals("10/01"));
    return true;
}
(:test) function selectedTemperatureAndElevationUnits(logger) {
    var d=new FourthData(); d.options=new FourthOptions();
    d.options.values["TemperatureUnit"]=1; d.temperature=0;
    Test.assert(d.temperatureText().equals("0°C"));
    d.options.values["TemperatureUnit"]=2;
    Test.assert(d.temperatureText().equals("32°F"));
    d.temperature=-40; Test.assert(d.temperatureText().equals("-40°F"));
    d.options.values["TemperatureUnit"]=1; Test.assert(d.temperatureText().equals("-40°C"));
    d.options.values["ShowTemperatureUnit"]=false; Test.assert(d.temperatureText().equals("-40°"));
    d.temperature=null; Test.assert(d.temperatureText().equals("--°"));
    d.options.values["ElevationUnit"]=1; d.altitude=100;
    Test.assert(d.fieldValue(3,null).equals("100m"));
    d.options.values["ElevationUnit"]=2; Test.assert(d.fieldValue(3,null).equals("328ft"));
    d.altitude=1500; Test.assert(d.shortFieldValue(3,null).equals("4.9kft"));
    return true;
}
(:test) function localizedWeatherLabels(logger) {
    var v=new FourthView();
    v.options.values["Language"]=1;
    v.data.condition=Weather.CONDITION_CLEAR; Test.assert(v.weatherText().equals("晴"));
    v.data.condition=Weather.CONDITION_RAIN_SNOW; Test.assert(v.weatherText().equals("雨雪"));
    v.data.condition=null; Test.assert(v.weatherText().equals("未知"));
    v.options.values["Language"]=2;
    v.data.condition=Weather.CONDITION_CLEAR; Test.assert(v.weatherText().equals("CLEAR"));
    v.data.condition=Weather.CONDITION_RAIN_SNOW; Test.assert(v.weatherText().equals("RAIN/SNOW"));
    v.data.condition=null; Test.assert(v.weatherText().equals("--"));
    return true;
}
(:test) class AwakeSettingsView extends FourthView {
    function initialize() { FourthView.initialize(); }
    function isLowPower() { return asleep; }
}
(:test) function independentColorsFieldsAndAwakeSeconds(logger) {
    var v=new AwakeSettingsView(); v.scale=466/280.0; v.width=466;
    v.timeFont=1; v.fieldFont=2; v.smallFont=3; v.unitFont=4;
    v.options.values["Language"]=2; v.options.values["TimeFormat"]=1;
    v.options.values["HourColor"]=0xFFE377; v.options.values["MinuteColor"]=0x80D6B4;
    v.options.values["FieldLabelColor"]=0xA998E8; v.options.values["FieldValueColor"]=0xFF7788;
    v.options.values["ShowSecondsActive"]=true;
    v.fields=[5,6,0]; v.shortFields=[0,0]; v.data.stress=28; v.data.recoveryMinutes=720;
    var dc=new RecordingDc(); v.drawActive(dc,new SceneClock(),new SceneDate());
    var seconds=false; var ampm=false; var value=false; var label=false;
    Test.assert(dc.texts[1][3]==0xFFE377 && dc.texts[2][3]==0x80D6B4);
    for(var i=0;i<dc.texts.size();i+=1) {
        var text=dc.texts[i];
        if(text[2].equals(":32")) { seconds=true; }
        if(text[2].equals("PM")) { ampm=true; }
        if(text[2].equals("28")) { value=text[3]==0xFF7788; }
        if(text[2].equals("STRESS")) { label=text[3]==0xA998E8; }
        Test.assert(!text[2].equals("ALT"));
    }
    Test.assert(seconds && ampm && value && label);
    v.asleep=true; dc=new RecordingDc(); v.drawTimeExtras(dc,new SceneClock(),0x93DBE8);
    Test.assert(dc.texts.size()==0);
    return true;
}
(:test) function savedSettingsAndMenuRefresh(logger) {
    var oldField=Application.Properties.getValue("FieldTop");
    var oldUnit=Application.Properties.getValue("TemperatureUnit");
    var oldColor=Application.Properties.getValue("HourColor");
    try {
        Application.Properties.setValue("FieldTop",6);
        Application.Properties.setValue("TemperatureUnit",2);
        Application.Properties.setValue("HourColor",0);
        var o=new FourthOptions();
        Test.assert(o.values["FieldTop"]==6 && o.fahrenheit() && o.color("HourColor",0xFFFFFF)==0);
        Application.Properties.setValue("FieldTop",999); o.reload();
        Test.assert(o.values["FieldTop"]==1);
        var root=new FourthSettingsMenu(-1); Test.assert(root.getItem(5)!=null && root.getItem(6)==null);
        root.refresh(); Test.assert(root.getItem(6)==null);
        var fields=new FourthSettingsMenu(3); Test.assert(fields.getItem(4)!=null && fields.getItem(5)==null);
        fields.refresh(); Test.assert(fields.getItem(5)==null);
    } catch(e) {
        Application.Properties.setValue("FieldTop",oldField);
        Application.Properties.setValue("TemperatureUnit",oldUnit);
        Application.Properties.setValue("HourColor",oldColor);
        throw e;
    }
    Application.Properties.setValue("FieldTop",oldField);
    Application.Properties.setValue("TemperatureUnit",oldUnit);
    Application.Properties.setValue("HourColor",oldColor);
    return true;
}
