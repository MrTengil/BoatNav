import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class BoatNavSummaryView extends WatchUi.View {
    private var _stats as Dictionary;

    function initialize(stats as Dictionary) {
        View.initialize();
        _stats = stats;
    }

    function onLayout(dc as Dc) as Void {
    }

    function onUpdate(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;

        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_WHITE);
        dc.clear();

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 85, Graphics.FONT_SMALL, "RESA KLAR",
                   Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        var elapsed = _stats["elapsed"] as Number;
        var h = elapsed / 3600;
        var m = (elapsed % 3600) / 60;
        var s = elapsed % 60;
        var timeStr = Lang.format("$1$:$2$:$3$",
            [h.format("%d"), m.format("%02d"), s.format("%02d")]);

        var distance = _stats["distance"] as Float;
        var avgSpeed = _stats["avgSpeed"] as Float;
        var maxSpeed = _stats["maxSpeed"] as Float;

        var c1 = cx - 55;
        var c2 = cx + 55;

        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(c1, cy - 42, Graphics.FONT_XTINY, "TID",
                   Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(c2, cy - 42, Graphics.FONT_XTINY, "STRÄCKA",
                   Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x002288, Graphics.COLOR_TRANSPARENT);
        dc.drawText(c1, cy - 22, Graphics.FONT_SMALL, timeStr,
                   Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(c2, cy - 22, Graphics.FONT_SMALL, distance.format("%.2f") + " NM",
                   Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0xCCCCCC, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(cx - 80, cy + 5, cx + 80, cy + 5);

        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(c1, cy + 22, Graphics.FONT_XTINY, "MEDELFART",
                   Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(c2, cy + 22, Graphics.FONT_XTINY, "MAXFART",
                   Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x002288, Graphics.COLOR_TRANSPARENT);
        dc.drawText(c1, cy + 42, Graphics.FONT_SMALL, avgSpeed.format("%.1f") + " kn",
                   Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.drawText(c2, cy + 42, Graphics.FONT_SMALL, maxSpeed.format("%.1f") + " kn",
                   Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 85, Graphics.FONT_XTINY, "Tryck BACK",
                   Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }
}

class BoatNavSummaryDelegate extends WatchUi.BehaviorDelegate {
    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
