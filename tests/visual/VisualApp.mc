import Toybox.Application;
import Toybox.Weather;

// Comparison fixture only: calls the unchanged production renderer.
class VisualApp extends FourthApp {
    function initialize() { FourthApp.initialize(); }
    function getInitialView() { view=new VisualView(); return [view]; }
}
class VisualView extends FourthView {
    function initialize() {
        FourthView.initialize();
        data=new FourthData();
        data.steps=8200; data.body=88; data.altitude=1286;
        data.stress=28; data.recoveryMinutes=720;
        data.temperature=18; data.condition=Weather.CONDITION_CLEAR;
        data.sunrise=360; data.sunset=1080; battery=75;
        options.values["TemperatureUnit"]=1; options.values["ElevationUnit"]=1;
    }
    (:dusk) function fixtureClock() { return new VisualClock(); }
    (:night) function fixtureClock() { var clock=new VisualClock(); clock.hour=22; return clock; }
    function onUpdate(dc) { drawActive(dc,fixtureClock(),new VisualDate()); }
}
class VisualClock { var hour=18; var min=8; var sec=32; }
class VisualDate { var day_of_week=5; var day=1; var month=10; }
