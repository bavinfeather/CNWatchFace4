import Toybox.Application;
import Toybox.Lang;

// Extra custom field settings will use this verified-license boundary.
// Key entry alone is not proof of a purchase. Validation is not connected yet.
class LicenseProvider {
    var key = "";
    function initialize() { loadSettings(); }
    function loadSettings() {
        var entered = Application.Properties.getValue("LicenseKey");
        key = entered instanceof String ? entered : "";
    }
    // TODO: validate the key before enabling extra custom field settings.
    function isLicensed() { return false; }
}
