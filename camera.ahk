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
        send {AltDown}
        sleep 250

        UserInterface.ClickTrackingMap()
        sleep 250

        UserInterface.MoveMouseOverMap()
        sleep 50

        ; zoom out completely
        loop, 5 {
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

        return true
    }
}