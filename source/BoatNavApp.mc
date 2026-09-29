import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

class BoatNavApp extends Application.AppBase {
    private var _view as BoatNavView or Null = null;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
        if (_view != null) {
            (_view as BoatNavView).stopGps();
        }
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        var view = new BoatNavView();
        _view = view;
        return [view, new BoatNavDelegate(view)];
    }
}
