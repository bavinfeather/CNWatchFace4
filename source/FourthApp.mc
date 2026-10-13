import Toybox.Application;
import Toybox.WatchUi;

class FourthApp extends Application.AppBase {
    var license;
    var view;
    function initialize() { AppBase.initialize(); license = new LicenseProvider(); }
    function getInitialView() { view = new FourthView(); return [view]; }
    function getSettingsView() { var menu=new FourthSettingsMenu(-1); return [menu,new FourthSettingsDelegate(menu)]; }
    function onSettingsChanged() { license.loadSettings(); if(view!=null){view.reloadSettings();} WatchUi.requestUpdate(); }
}
