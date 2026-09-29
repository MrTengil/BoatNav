import Toybox.Lang;
import Toybox.WatchUi;

class BoatNavDelegate extends WatchUi.InputDelegate {
    private var _view as BoatNavView;

    function initialize(view as BoatNavView) {
        InputDelegate.initialize();
        _view = view;
    }

    function onKey(keyEvent as WatchUi.KeyEvent) as Boolean {
        var key = keyEvent.getKey();
        if (key == WatchUi.KEY_ENTER) {
            _view.toggleTracking();
            return true;
        }
        if (key == WatchUi.KEY_ESC && _view.isTracking()) {
            return true;
        }
        return false;
    }

    function onSwipe(swipeEvent as WatchUi.SwipeEvent) as Boolean {
        if (swipeEvent.getDirection() == WatchUi.SWIPE_LEFT && _view.isTracking()) {
            return true;
        }
        return false;
    }
}
