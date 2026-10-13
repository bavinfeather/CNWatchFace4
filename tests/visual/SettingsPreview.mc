// English-layout fixture; production defaults are not changed.
class SettingsEnglishPreviewApp extends VisualApp {
    function initialize() { VisualApp.initialize(); }
    function getInitialView() {
        view=new VisualView();
        view.options.values["Language"]=2;
        view.options.values["TimeFormat"]=1;
        view.options.values["ShowSecondsActive"]=true;
        view.options.values["TemperatureUnit"]=2;
        view.options.values["ElevationUnit"]=2;
        return [view];
    }
}
