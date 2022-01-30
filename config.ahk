#SingleInstance, Force
SendMode Input
SetWorkingDir, %A_ScriptDir%

/*
This class is primarily used for specific keys or optional settings like speedhack, cross server etc
*/
class Configuration 
{
    IsWarlockTest()
    {
        return false
    }

    ; which stage to farm
    AerodromeStage()
    {
        return 21
    }

    InviteDuo()
    {
        send /invite "StoneRRF BM"
    }

    ; shut down the computer if no bns processes are found anymore (dc or maintenance)
    ShutdownComputerAfterCrash()
    {
        return false
    }

    ; should the character even use buff food
    ShouldUseBuffFood()
    {
        return true
    }

    ; whatever we want to do if health is critical (f.e. hmb/drinking potions)
    CriticalHpAction()
    {
        loop, 15 {
            ; ToDo: change to F for auto hmb for BM when done
            send z
            sleep 5
        }

        Configuration.UseHealthPotion()
    }

    ; hotkey where the buff food is placed
    UseBuffFood()
    {
        ;send 6
    }

    ; hotkey where the field repair hammers are placed
    UseRepairTools()
    {
        send 7
    }

    UseHealthPotion()
    {
        send 5
    }

    ; after how many runs should we repair our weapon
    UseRepairToolsAfterRunCount()
    {
        return 7
    }

    ToggleMapTransparency()
    {
        send n
    }

    ToggleAutoCombat()
    {
        send {ShiftDown}{f4 down}
        sleep 250
        send {ShiftUp}{f4 up}
    }

    ; enable speed hack (sanic or normal ce speedhack)
    EnableLobbySpeedhack()
    {
        send {Numpad7}
    }

    ; disable movement speed hack (sanic or normal ce speedhack)
    DisableLobbySpeedhack()
    {
        send {Numpad3}
    }

    ; enable movement speed hack (sanic or normal ce speedhack)
    EnableMovementSpeedhack()
    {
        send {Numpad6}
    }

    ; disable movement speed hack (sanic or normal ce speedhack)
    DisableMovementSpeedhack()
    {
        send {Numpad3}
    }

    EnableClipBossOne()
    {
        send {Numpad8}
    }

    DisableClipBossOne()
    {
        send {Numpad4}
    }

    EnableClipBossTwo()
    {
        send {Numpad9}
    }

    DisableClipBossTwo()
    {
        send {Numpad5}
    }

    EnableClip()
    {
    }

    DisableClip()
    {
    }

    ; configured speed value
    MovementSpeedhackValue()
    {
        return 5.5
    }

    ; shortcut for shadowplay clip in case we want to debug how we got stuck or got to this point
    ClipShadowPlay()
    {
        send {alt down}{f10 down}
        sleep 1000
        send {alt up}{f10 up}
    }

    UseTalisman()
    {
        send r
    }
}