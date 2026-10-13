// Release visual fixture: noon sun with the complete production time/field layout.
class SunPreviewApp extends VisualApp {
    function initialize() { VisualApp.initialize(); }
    function getInitialView() { view=new SunPreviewView(); return [view]; }
}
class SunPreviewView extends VisualView {
    function initialize() { VisualView.initialize(); }
    function fixtureClock() {
        var clock=new VisualClock(); clock.hour=12; clock.min=0; return clock;
    }
}
