#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

class Camera
{
    static fullTurn := 3174

    Spin(degrees)
    {
        pxls := this.fullTurn / 360 * degrees
        ; you have to experiment a little with your settings here due to your DPI, ingame sensitivity etc
        DllCall("mouse_event", "UInt", 0x0001, "UInt", pxls, "UInt", 0)
    }

    SpinPxls(pxls)
    {
        ; you have to experiment a little with your settings here due to your DPI, ingame sensitivity etc
        DllCall("mouse_event", "UInt", 0x0001, "UInt", pxls, "UInt", 0)
    }

    ResetCamera()
    {
        ; initial turn since we're close to 180° away from the portal
        Camera.SpinPxls(1400)

        ; make sure map is not transparent
        if (UserInterface.IsMapTransparent()) {
            Configuration.ToggleMapTransparency()
            sleep 500
        }

        send {AltDown}
        sleep 250

        UserInterface.ClickTrackingMap()
        sleep 350

        UserInterface.MoveMouseOverMap()
        sleep 50

        ; zoom out completely
        loop, 7 {
            MouseClick, WheelUp
            sleep 75
        }

        send {AltUp}

        total := 0
        while (!UserInterface.MapFixpoint()) {            
            if (total > this.fullTurn) {
                return false
            }

            Camera.SpinPxls(1)
            total += 1
        }

        log.addLogEntry("$time: had to spin camera by " total " pixels (" Utility.RoundDecimal(total / this.fullTurn) ")")

        return true
    }
}