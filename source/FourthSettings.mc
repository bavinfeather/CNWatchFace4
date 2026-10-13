import Toybox.Application;
import Toybox.WatchUi;

class FourthSettingsMenu extends WatchUi.Menu2 {
    var group;
    var rows;
    var options;
    var items = {};
    function initialize(section) {
        options=new FourthOptions(); group=section;
        var groups=FourthSettingsData.groups();
        Menu2.initialize({:title=>group<0?options.text("表盘设置","Face settings"):groups[group][options.chinese()?0:1]});
        rows=FourthSettingsData.rows();
        refresh();
    }
    function refresh() {
        options.reload();
        var chinese=options.chinese();
        var groups=FourthSettingsData.groups();
        setTitle(group<0?options.text("表盘设置","Face settings"):groups[group][chinese?0:1]);
        if(group<0) {
            for(var g=0;g<groups.size();g+=1) { updateRow(g,groups[g][chinese?0:1],null); }
            return;
        }
        for(var i=0;i<rows.size();i+=1) {
            var row=rows[i]; if(row[3]!=group) { continue; }
            var label=row[0].equals("LicenseKey")?(options.values[row[0]].equals("")?options.text("未填写","Not entered"):"••••••"):"";
            var choices=FourthSettingsData.choices(row[0]);
            if(choices!=null) {
                for(var c=0;c<choices.size();c+=1) {
                    if(choices[c][0]==options.values[row[0]]) { label=choices[c][chinese?1:2]; break; }
                }
            }
            updateRow(i,row[chinese?1:2],label);
        }
    }
    function updateRow(id,title,label) {
        if(!items.hasKey(id)) { items[id]=new WatchUi.MenuItem(title,label,id,null); addItem(items[id]); }
        else { items[id].setLabel(title); items[id].setSubLabel(label); }
    }
    function onShow() { refresh(); }
}
class FourthSettingsDelegate extends WatchUi.Menu2InputDelegate {
    var menu;
    function initialize(m) { Menu2InputDelegate.initialize(); menu=m; }
    function onSelect(item) {
        var id=item.getId();
        if(menu.group<0) {
            var next=new FourthSettingsMenu(id);
            WatchUi.pushView(next,new FourthSettingsDelegate(next),WatchUi.SLIDE_IMMEDIATE); return;
        }
        var row=menu.rows[id]; var choices=FourthSettingsData.choices(row[0]);
        if(choices==null) {
            WatchUi.pushView(new WatchUi.TextPicker(menu.options.values[row[0]]),new FourthKeyDelegate(),WatchUi.SLIDE_IMMEDIATE); return;
        }
        var sub=new WatchUi.Menu2({:title=>row[menu.options.chinese()?1:2]});
        for(var c=0;c<choices.size();c+=1) {
            sub.addItem(new WatchUi.MenuItem(choices[c][menu.options.chinese()?1:2],
                choices[c][0]==menu.options.values[row[0]]?menu.options.text("当前","Current"):null,c,null));
        }
        WatchUi.pushView(sub,new FourthChoiceDelegate(row[0],choices),WatchUi.SLIDE_IMMEDIATE);
    }
    function onBack() { WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); }
}
class FourthChoiceDelegate extends WatchUi.Menu2InputDelegate {
    var key; var choices;
    function initialize(k,c) { Menu2InputDelegate.initialize(); key=k; choices=c; }
    function onSelect(item) {
        Application.Properties.setValue(key,choices[item.getId()][0]);
        Application.getApp().onSettingsChanged();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
    }
    function onBack() { WatchUi.popView(WatchUi.SLIDE_IMMEDIATE); }
}
class FourthKeyDelegate extends WatchUi.TextPickerDelegate {
    function initialize() { TextPickerDelegate.initialize(); }
    function onTextEntered(text,changed) {
        if(changed) { Application.Properties.setValue("LicenseKey",text); Application.getApp().onSettingsChanged(); }
        return true;
    }
    function onCancel() { return true; }
}
