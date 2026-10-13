import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Application;

class FourthView extends WatchUi.WatchFace {
    var width = 280;
    var scale = 1.0;
    var asleep = false;
    var wakeFramePending = false;
    var sharedAod;
    var aodFont;
    var smallFont;
    var battery;
    var data;
    var landscape;
    var timeFont;
    var fieldFont;
    var labelFont;
    var unitFont;
    var dateFont;
    var englishLabelFont;
    var compactFont;
    var temperatureFont;
    var options;
    var fontChinese = null;
    var fields = [1,2,3];
    var shortFields = [5,6];
    var shortIcons = [null,null];
    var shortIconIds = [0,0];

    (:amoled) function isAmoled() { return true; }
    (:mip) function isAmoled() { return false; }
    (:amoled) function activeTimeFont() { return WatchUi.loadResource(Rez.Fonts.Time07); }
    (:mip) function activeTimeFont() { return aodFont; }
    (:amoled) function chineseLabelFont() { return WatchUi.loadResource(Rez.Fonts.LabelZh); }
    (:amoled) function chineseDateFont() { return WatchUi.loadResource(Rez.Fonts.DateZh); }
    (:mip) function chineseLabelFont() { return smallFont; }
    (:mip) function chineseDateFont() { return smallFont; }
    (:amoled) function prepareFieldFonts() {
        fieldFont=WatchUi.loadResource(Rez.Fonts.Field07);
        compactFont=WatchUi.loadResource(Rez.Fonts.Compact07);
        unitFont=WatchUi.loadResource(Rez.Fonts.Unit07);
        englishLabelFont=WatchUi.loadResource(Rez.Fonts.LabelEn07);
    }
    (:mip) function prepareFieldFonts() {}
    function initialize() {
        WatchFace.initialize();
        data = new FourthData();
        landscape = new Landscape();
        options = new FourthOptions(); data.options=options;
        reloadSettings();
    }
    function reloadSettings() {
        options.reload(); fontChinese=null; wakeFramePending=false;
        var keys = ["FieldTop","FieldMiddle","FieldBottom"];
        for (var i=0;i<3;i+=1) {
            fields[i] = options.values[keys[i]];
        }
        var shortKeys = ["FieldUpperShort","FieldLowerShort"];
        for (var j=0;j<2;j+=1) {
            shortFields[j] = options.values[shortKeys[j]];
        }
    }
    function p(value) { return (value * scale).toNumber(); }
    function onLayout(dc) {
        width = dc.getWidth();
        scale = width / 280.0;
        aodFont = WatchUi.loadResource(Rez.Fonts.Aod);
        smallFont = WatchUi.loadResource(Rez.Fonts.Small);
        if (Graphics has :getVectorFont) {
            try {
                var nativeFont = Graphics.getVectorFont({:face=>["RobotoCondensedBold"],:size=>p(15)});
                if (nativeFont != null) { smallFont = nativeFont; }
            } catch(e) {}
        }
        if (isAmoled()) {
            timeFont = activeTimeFont(); fieldFont = smallFont; labelFont = smallFont; unitFont = smallFont;
            dateFont = smallFont;
            temperatureFont=smallFont;
            if (Graphics has :getVectorFont) {
                try { temperatureFont=Graphics.getVectorFont({:face=>["RobotoCondensedBold"],:size=>p(25)}); } catch(e) {}
                if(temperatureFont==null) { temperatureFont=smallFont; }
                if (fieldFont == null) { fieldFont = smallFont; }
                if (labelFont == null) { labelFont = smallFont; }
                if (unitFont == null) { unitFont = smallFont; }
                if (dateFont == null) { dateFont = smallFont; }
            }
            prepareFieldFonts();
            prepareTextFonts();
        }
    }
    function prepareTextFonts() {
        var chinese=options.chinese();
        if(fontChinese==chinese) { return; }
        var label=null; var date=null;
        if(Graphics has :getVectorFont) {
            try { label=Graphics.getVectorFont({:face=>[chinese?"NotoSansSCMedium":"RobotoCondensedRegular"],:size=>p(14)}); } catch(e) {}
            try { date=Graphics.getVectorFont({:face=>[chinese?"NotoSansSCMedium":"RobotoCondensedBold"],:size=>p(22)}); } catch(e) {}
        }
        labelFont=chinese?(label!=null?label:chineseLabelFont()):englishLabelFont;
        dateFont=date!=null?date:(chinese?chineseDateFont():smallFont);
        fontChinese=chinese;
    }
    function onEnterSleep() {
        asleep = true; landscape.releaseGraphics();
        WatchUi.requestUpdate();
    }
    function onExitSleep() { asleep = false; wakeFramePending=isAmoled(); WatchUi.requestUpdate(); }
    function readClock() { return System.getClockTime(); }
    function readDate() { return Gregorian.info(Time.now(),Time.FORMAT_SHORT); }
    function isLowPower() {
        return asleep || (isAmoled() && (System has :getDisplayMode) &&
            System.getDisplayMode()==System.DISPLAY_MODE_LOW_POWER);
    }
    function timeString(clock) {
        return options.timeText(clock);
    }
    // Shared AMOLED AOD; preserve the original MIP time/date/battery path.
    function drawAod(dc, clock, date) {
        if (isAmoled()) {
            if (sharedAod == null) { sharedAod = new SharedAod(); }
            var aodDate = options.enabled("ShowDate")?date.month.format("%02d") + "/" + date.day.format("%02d"):"";
            var ampm=options.amPm(clock);
            if(!ampm.equals("")) { aodDate=ampm+(aodDate.equals("")?"":" "+aodDate); }
            var aodFields = battery == null ? ["--"] : [battery.toNumber().format("%d")+"%"];
            sharedAod.draw(dc, clock.hour * 60 + clock.min, timeString(clock), aodDate, aodFields);
            return;
        }
        dc.setColor(0,0); dc.clear();
        var minute = clock.hour * 60 + clock.min;
        var offsetX = (minute % 5) - 2;
        var offsetY = ((minute / 5) % 5).toNumber() - 2;
        if(isAmoled()) { offsetY=minute%2==0?-70:70; }
        dc.setColor(0x666666, Graphics.COLOR_TRANSPARENT);
        dc.drawText(p(140+offsetX),p(105+offsetY),aodFont,timeString(clock),Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(0x555555, Graphics.COLOR_TRANSPARENT);
        var ds = date.month.format("%02d") + "/" + date.day.format("%02d");
        if(!options.enabled("ShowDate")) { ds=""; }
        var ampm=options.amPm(clock);
        if(!ampm.equals("")) { ds=ampm+(ds.equals("")?"":" "+ds); }
        if(!ds.equals("")) { dc.drawText(p(140+offsetX),p(151+offsetY),smallFont,ds,Graphics.TEXT_JUSTIFY_CENTER); }
        if (battery != null) {
            dc.drawText(p(140+offsetX),p(177+offsetY),smallFont,battery.format("%.0f")+"%",Graphics.TEXT_JUSTIFY_CENTER);
        }
        if(!isLowPower() && options.enabled("ShowSecondsActive") && (clock has :sec)) {
            dc.drawText(p(140),p(214),smallFont,":"+clock.sec.format("%02d"),Graphics.TEXT_JUSTIFY_CENTER);
        }
    }
    function onUpdate(dc) {
        var clock = readClock();
        var date = readDate();
        var low = isLowPower();
        if (!isAmoled()) {
            try { battery = System.getSystemStats().battery; } catch(e) {}
        } else {
            try {
                var aodBattery = System.getSystemStats().battery;
                if (aodBattery != null) { battery = aodBattery; }
            } catch(e) {}
        }
        if (!isAmoled() || low) { drawAod(dc, clock, date); return; }
        var deferRefresh=wakeFramePending && data.canReuseWake(date);
        wakeFramePending=false;
        if(deferRefresh) {
            var now=data.nowSeconds(); data.expireWeather(now); data.expireMetrics(now);
        } else { data.update(date); }
        drawActive(dc, clock, date);
    }
    function centered(dc,x,y,font,text) {
        dc.drawText(p(x),p(y),font,text,Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
    // Separate display units without changing metric conversion or missing values.
    function valueParts(value) {
        var end=value.length();
        while(end>0) {
            var c=value.substring(end-1,end);
            if(!c.equals("k") && !c.equals("m") && !c.equals("f") &&
                !c.equals("t") && !c.equals("h") && !c.equals("%")) { break; }
            end-=1;
        }
        return [value.substring(0,end),value.substring(end,value.length())];
    }
    function drawActive(dc,clock,date) {
        data.options=options;
        prepareTextFonts();
        landscape.draw(dc,width,clock.hour*60+clock.min,data.sunrise,data.sunset,data.condition);
        var light=landscape.light(clock.hour*60+clock.min,data.sunrise,data.sunset);
        var accent=landscape.mix(0x93DBE8,0xFFCAA1,light[3]);
        if(options.enabled("ShowDate")) {
            dc.setColor(options.color("DateColor",0xB4C3CD),Graphics.COLOR_TRANSPARENT);
            var dateText=options.dateText(date); var font=dateFont;
            if(dc.getTextWidthInPixels(dateText,font)>p(80)) { font=smallFont; if(options.chinese()){font=labelFont;} }
            centered(dc,104,40,font,dateText);
        }
        dc.setColor(options.color("HourColor",0xECF0F1),Graphics.COLOR_TRANSPARENT);
        centered(dc,104,84,timeFont,options.hourText(clock.hour));
        dc.setColor(options.color("MinuteColor",accent),Graphics.COLOR_TRANSPARENT);
        centered(dc,104,143,timeFont,clock.min.format("%02d"));
        drawTimeExtras(dc,clock,accent);
        drawTemperatureWeather(dc);
        drawBattery(dc,options.color("BatteryColor",accent));
        drawShortField(dc,0,60);
        var labels=options.chinese()?["","步数","身体电量","海拔","电池","压力","恢复时间"]:
            ["","STEPS","BB","ALT","BAT","STRESS","RECOVERY"];
        for(var i=0;i<3;i+=1) {
            var y=86+i*50;
            var id=fields[i];
            if(id==0) { continue; }
            dc.setColor(options.color("FieldLabelColor",0xADC3CD),Graphics.COLOR_TRANSPARENT);
            dc.drawText(p(185),p(y),labelFont,labels[id],Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            var parts=valueParts(data.fieldValue(id,battery == null ? null : battery.toNumber()));
            var font=fieldFont;
            var maxWidth=i==2?p(64):p(74);
            var unitWidth=dc.getTextWidthInPixels(parts[1],unitFont);
            var gap=parts[1].equals("")?0:p(2);
            if(dc.getTextWidthInPixels(parts[0],font)+gap+unitWidth>maxWidth){font=compactFont!=null?compactFont:smallFont;}
            var numberWidth=dc.getTextWidthInPixels(parts[0],font);
            var left=p(185);
            dc.setColor(options.color("FieldValueColor",0xF0EBE2),Graphics.COLOR_TRANSPARENT);
            dc.drawText(left,p(y+20),font,parts[0],Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            if(!parts[1].equals("")) {
                dc.setColor(options.color("FieldLabelColor",0xADC3CD),Graphics.COLOR_TRANSPARENT);
                dc.drawText(left+numberWidth+gap,p(y+23),
                    unitFont,parts[1],Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
            }
        }
        drawShortField(dc,1,230);
    }
    function drawTimeExtras(dc,clock,accent) {
        if(isLowPower()) { return; }
        var ampm=options.amPm(clock);
        var seconds=options.enabled("ShowSecondsActive") && (clock has :sec)?":"+clock.sec.format("%02d"):"";
        dc.setColor(options.color("SecondaryColor",accent),Graphics.COLOR_TRANSPARENT);
        if(!ampm.equals("")) { centered(dc,seconds.equals("")?104:82,188,smallFont,ampm); }
        if(!seconds.equals("")) { centered(dc,ampm.equals("")?104:126,188,smallFont,seconds); }
    }
    function weatherText() {
        var kind=landscape.weatherKind(data.condition);
        var labels=options.chinese()?["晴","少云","多云","雨","雪","雷雨","雾","未知","雨雪","冰雹","沙尘","风暴","结冰","大风"]:
            ["CLEAR","PARTLY","CLOUDY","RAIN","SNOW","STORM","FOG","--","RAIN/SNOW","HAIL","DUST","STORM","ICE","WIND"];
        return labels[kind];
    }
    function drawTemperatureWeather(dc) {
        dc.setColor(options.color("WeatherColor",0xECF0F1),Graphics.COLOR_TRANSPARENT);
        var text=data.temperatureText(); var font=temperatureFont!=null?temperatureFont:fieldFont;
        if(!(Graphics has :VectorFont) || !(font instanceof Graphics.VectorFont)) { font=Graphics.FONT_SMALL; }
        if(dc.getTextWidthInPixels(text,font)>p(44)) {
            font=smallFont;
            if(!(Graphics has :VectorFont) || !(font instanceof Graphics.VectorFont)) { font=Graphics.FONT_XTINY; }
        }
        centered(dc,84,247,font,text);
        if(!options.enabled("ShowWeatherText")) { return; }
        var left=p(84)+dc.getTextWidthInPixels(text,font)/2+p(5);
        var weather=weatherText(); var weatherFont=labelFont;
        dc.drawText(left,p(247),weatherFont,weather,Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }
    function drawBattery(dc,accent) {
        dc.setPenWidth(p(2)+1);
        var level=battery==null?0:landscape.max(0,landscape.min(100,battery));
        var filledEnd=143+75*level/100.0;
        for(var i=0;i<15;i+=1) {
            var start=143+i*5; var end=start+3.3;
            dc.setColor(0x334559,Graphics.COLOR_TRANSPARENT);
            dc.drawArc(p(140),p(140),p(129),Graphics.ARC_COUNTER_CLOCKWISE,start,end);
            if(filledEnd>start) {
                dc.setColor(accent,Graphics.COLOR_TRANSPARENT);
                dc.drawArc(p(140),p(140),p(129),Graphics.ARC_COUNTER_CLOCKWISE,start,landscape.min(end,filledEnd));
            }
        }
        dc.setPenWidth(1);
    }
    function drawShortField(dc,slot,y) {
        var id=shortFields[slot];
        if(id==0) { shortIcons[slot]=null; shortIconIds[slot]=0; return; }
        if(shortIcons[slot]==null || shortIconIds[slot]!=id) {
            var resources=[Rez.Drawables.ShortSteps,Rez.Drawables.ShortBody,Rez.Drawables.ShortAltitude,
                Rez.Drawables.ShortBattery,Rez.Drawables.ShortStress,Rez.Drawables.ShortRecovery];
            shortIcons[slot]=WatchUi.loadResource(resources[id-1]); shortIconIds[slot]=id;
        }
        var parts=valueParts(data.shortFieldValue(id,battery == null ? null : battery.toNumber()));
        var font=compactFont!=null?compactFont:smallFont;
        // Compact fields share the same center line as the three main pairs.
        var icon=p(13); var gap=p(4);
        var unitWidth=parts[1].equals("")?0:p(1)+dc.getTextWidthInPixels(parts[1],unitFont);
        var textWidth=dc.getTextWidthInPixels(parts[0],font);
        var total=icon+gap+textWidth+unitWidth;
        if(total>p(48)) { font=labelFont; textWidth=dc.getTextWidthInPixels(parts[0],font); total=icon+gap+textWidth+unitWidth; }
        var left=p(213)-total/2;
        dc.drawBitmap2(left,p(y)-icon/2,shortIcons[slot],{:bitmapWidth=>icon,:bitmapHeight=>icon,
            :tintColor=>options.color("FieldLabelColor",0xADC3CD)});
        dc.setColor(options.color("FieldValueColor",0xF0EBE2),Graphics.COLOR_TRANSPARENT);
        dc.drawText(left+icon+gap,p(y),font,parts[0],Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        if(!parts[1].equals("")) {
            dc.setColor(options.color("FieldLabelColor",0xADC3CD),Graphics.COLOR_TRANSPARENT);
            dc.drawText(left+icon+gap+textWidth+p(1),p(y+2),unitFont,parts[1],
                Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }
}
