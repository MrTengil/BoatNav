import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.Position;
import Toybox.Time;
import Toybox.Timer;
import Toybox.WatchUi;

class BoatNavView extends WatchUi.View {
    private var _tracking as Boolean = false;
    private var _gpsQuality as Number = Position.QUALITY_NOT_AVAILABLE;
    private var _headingRad as Float = 0.0f;
    private var _speedKnots as Float = 0.0f;
    private var _lat as Float = 0.0f;
    private var _lon as Float = 0.0f;
    private var _distanceNm as Float = 0.0f;
    private var _prevLat as Float = 0.0f;
    private var _prevLon as Float = 0.0f;
    private var _hasFirstFix as Boolean = false;
    private var _maxSpeedKnots as Float = 0.0f;
    private var _startTime as Time.Moment or Null = null;
    private var _timer as Timer.Timer or Null = null;

    function initialize() {
        View.initialize();
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
        if (!_tracking) {
            var wasTracking = Application.Storage.getValue("tracking");
            if (wasTracking != null) {
                _tracking = true;
                _hasFirstFix = false;
                var dist = Application.Storage.getValue("distance");
                if (dist != null) { _distanceNm = dist as Float; }
                var maxSpd = Application.Storage.getValue("maxSpeed");
                if (maxSpd != null) { _maxSpeedKnots = maxSpd as Float; }
                var startSec = Application.Storage.getValue("startTime");
                if (startSec != null) { _startTime = new Time.Moment(startSec as Number); }
                var t = new Timer.Timer();
                t.start(method(:onTimer), 1000, true);
                _timer = t;
            }
        }
        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    function onHide() as Void {
        if (_tracking) {
            Application.Storage.setValue("tracking", true);
            Application.Storage.setValue("distance", _distanceNm);
            Application.Storage.setValue("maxSpeed", _maxSpeedKnots);
            if (_startTime != null) {
                Application.Storage.setValue("startTime", (_startTime as Time.Moment).value());
            }
        }
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
            _timer = null;
        }
    }

    function stopGps() as Void {
        Position.enableLocationEvents(Position.LOCATION_DISABLE, method(:onPosition));
        if (_timer != null) {
            (_timer as Timer.Timer).stop();
            _timer = null;
        }
        Application.Storage.deleteValue("tracking");
        Application.Storage.deleteValue("distance");
        Application.Storage.deleteValue("maxSpeed");
        Application.Storage.deleteValue("startTime");
    }

    function isTracking() as Boolean {
        return _tracking;
    }

    function toggleTracking() as Void {
        if (!_tracking) {
            _tracking = true;
            _distanceNm = 0.0f;
            _maxSpeedKnots = 0.0f;
            _hasFirstFix = false;
            _startTime = Time.now();
            var t = new Timer.Timer();
            t.start(method(:onTimer), 1000, true);
            _timer = t;
        } else {
            _tracking = false;
            if (_timer != null) {
                (_timer as Timer.Timer).stop();
                _timer = null;
            }
            Application.Storage.deleteValue("tracking");
            Application.Storage.deleteValue("distance");
            Application.Storage.deleteValue("maxSpeed");
            Application.Storage.deleteValue("startTime");
            var elapsed = 0;
            if (_startTime != null) {
                elapsed = (Time.now().subtract(_startTime as Time.Moment) as Time.Duration).value();
            }
            var avgSpeed = 0.0f;
            if (elapsed > 0) {
                avgSpeed = _distanceNm / (elapsed.toFloat() / 3600.0f);
            }
            var stats = {
                "distance" => _distanceNm,
                "elapsed" => elapsed,
                "maxSpeed" => _maxSpeedKnots,
                "avgSpeed" => avgSpeed
            };
            WatchUi.pushView(new BoatNavSummaryView(stats), new BoatNavSummaryDelegate(), WatchUi.SLIDE_UP);
        }
        WatchUi.requestUpdate();
    }

    function onTimer() as Void {
        WatchUi.requestUpdate();
    }

    function onPosition(info as Position.Info) as Void {
        _gpsQuality = info.accuracy;
        if (info.speed != null) {
            _speedKnots = (info.speed * 1.94384f).toFloat();
            if (_tracking && _speedKnots > _maxSpeedKnots) {
                _maxSpeedKnots = _speedKnots;
            }
        }
        if (info.heading != null) {
            _headingRad = info.heading.toFloat();
        }
        if (info.position != null) {
            var deg = info.position.toDegrees();
            var newLat = deg[0].toFloat();
            var newLon = deg[1].toFloat();
            if (_tracking && _hasFirstFix) {
                _distanceNm += haversineNm(_prevLat, _prevLon, newLat, newLon);
            }
            _lat = newLat;
            _lon = newLon;
            _prevLat = newLat;
            _prevLon = newLon;
            if (_tracking) { _hasFirstFix = true; }
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;
        var r = cx - 4;

        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_WHITE);
        dc.clear();

        drawCompassRing(dc, cx, cy, r);
        drawArrow(dc, cx, cy, r);
        drawSpeed(dc, cx, cy);
        drawBottomSection(dc, cx, cy);
        drawGpsIndicator(dc, cx, cy);
    }

    private function drawCompassRing(dc as Dc, cx as Number, cy as Number, r as Number) as Void {
        dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(cx, cy, r);

        // Rotating tick marks (ring moves, arrow stays fixed)
        var outerR = (r - 2).toFloat();
        var minorR = (r - 10).toFloat();
        var majorR = (r - 18).toFloat();
        var labelR = (r - 28).toFloat();

        for (var i = 0; i < 36; i++) {
            var a = i * 10.0f * Math.PI / 180.0f - _headingRad;
            var sinA = Math.sin(a);
            var cosA = Math.cos(a);
            var isMajor = (i % 3 == 0);
            var innerR = isMajor ? majorR : minorR;
            dc.setColor(isMajor ? 0x222222 : 0xAAAAAA, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(isMajor ? 2 : 1);
            dc.drawLine(
                cx + (outerR * sinA).toNumber(),
                cy - (outerR * cosA).toNumber(),
                cx + (innerR * sinA).toNumber(),
                cy - (innerR * cosA).toNumber()
            );
        }

        dc.setPenWidth(1);
        var cardinals = ["N", "E", "S", "W"];
        for (var i = 0; i < 4; i++) {
            var a = i * 90.0f * Math.PI / 180.0f - _headingRad;
            dc.setColor(i == 0 ? Graphics.COLOR_RED : 0x333333, Graphics.COLOR_TRANSPARENT);
            dc.drawText(
                cx + (labelR * Math.sin(a)).toNumber(),
                cy - (labelR * Math.cos(a)).toNumber(),
                Graphics.FONT_XTINY, cardinals[i],
                Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
    }

    private function drawArrow(dc as Dc, cx as Number, cy as Number, r as Number) as Void {
        var tipY = cy - r + 8;
        var baseY = cy - r + 58;
        var notchY = baseY - 12;
        var hw = 14;
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[cx, tipY], [cx + hw, baseY], [cx, notchY], [cx - hw, baseY]]);
    }

    private function drawSpeed(dc as Dc, cx as Number, cy as Number) as Void {
        var speedStr = _tracking ? _speedKnots.format("%.1f") : "--.-";
        dc.setColor(_tracking ? 0x002288 : 0xAAAAAA, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 22, Graphics.FONT_NUMBER_HOT, speedStr,
                   Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy + 20, Graphics.FONT_XTINY, _tracking ? "KNOTS" : "TRYCK START",
                   Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    private function drawBottomSection(dc as Dc, cx as Number, cy as Number) as Void {
        var divY = cy + 34;
        dc.setColor(0xCCCCCC, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(1);
        dc.drawLine(cx - 82, divY, cx + 82, divY);

        if (_tracking) {
            // Vertical line with small gap at top, stops before compass tick area
            dc.drawLine(cx, divY + 4, cx, divY + 56);

            var lx = cx - 42;
            var rx = cx + 42;

            dc.setColor(0x888888, Graphics.COLOR_TRANSPARENT);
            dc.drawText(lx, divY + 11, Graphics.FONT_XTINY, "TRIP (NM)",
                       Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(rx, divY + 11, Graphics.FONT_XTINY, "LAT/LON",
                       Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            dc.setColor(0x002288, Graphics.COLOR_TRANSPARENT);
            dc.drawText(lx, divY + 32, Graphics.FONT_SMALL, _distanceNm.format("%.2f"),
                       Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

            dc.setColor(0x333333, Graphics.COLOR_TRANSPARENT);
            dc.drawText(rx, divY + 27, Graphics.FONT_SYSTEM_XTINY, formatCoord(_lat, true),
                       Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
            dc.drawText(rx, divY + 42, Graphics.FONT_SYSTEM_XTINY, formatCoord(_lon, false),
                       Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    private function drawGpsIndicator(dc as Dc, cx as Number, cy as Number) as Void {
        var color;
        if (_gpsQuality == Position.QUALITY_GOOD || _gpsQuality == Position.QUALITY_USABLE) {
            color = Graphics.COLOR_GREEN;
        } else if (_gpsQuality == Position.QUALITY_POOR || _gpsQuality == Position.QUALITY_LAST_KNOWN) {
            color = Graphics.COLOR_YELLOW;
        } else {
            color = Graphics.COLOR_RED;
        }
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx + 72, cy - 72, 4);
    }

    private function formatCoord(deg as Float, isLat as Boolean) as String {
        var dir = isLat ? (deg >= 0.0f ? "N" : "S") : (deg >= 0.0f ? "E" : "W");
        var abs = deg < 0.0f ? -deg : deg;
        var d = abs.toNumber();
        var minDec = (abs - d.toFloat()) * 60.0f;
        return Lang.format("$1$ $2$° $3$'", [dir, d, minDec.format("%.2f")]);
    }

    private function haversineNm(lat1 as Float, lon1 as Float, lat2 as Float, lon2 as Float) as Float {
        var R = 3440.065f;
        var dLat = (lat2 - lat1) * Math.PI / 180.0f;
        var dLon = (lon2 - lon1) * Math.PI / 180.0f;
        var a = Math.sin(dLat / 2.0f) * Math.sin(dLat / 2.0f) +
                Math.cos(lat1 * Math.PI / 180.0f) * Math.cos(lat2 * Math.PI / 180.0f) *
                Math.sin(dLon / 2.0f) * Math.sin(dLon / 2.0f);
        if (a > 1.0f) { a = 1.0f; }
        return R * 2.0f * Math.atan2(Math.sqrt(a), Math.sqrt(1.0f - a));
    }
}
