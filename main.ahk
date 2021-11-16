﻿SetKeyDelay, -1, -1
SetWinDelay, -1

#Include %A_ScriptDir%\lib\utility.ahk
#Include %A_ScriptDir%\lib\log.ahk

#Include %A_ScriptDir%\config.ahk
#Include %A_ScriptDir%\ui.ahk
#Include %A_ScriptDir%\hotkeys.ahk

class Aerodrome
{
    static runCount := 0

    ; function we can call when we expect a loading screen and want to wait until the loading screen is over
    WaitLoadingScreen()
    {
        log.addLogEntry("$time: wait for loading screen")

        ; just sleep while we're in the loading screen
        while (UserInterface.IsInLoadingScreen()) {
            sleep 5
        }

        ; check any of the skills if they are visible
        while (!UserInterface.IsOutOfLoadingScreen()) {
            sleep 5
        }

        sleep 50
    }

    EnableSpeedHack()
    {
        loop, 5 {
            Configuration.EnableMovementSpeedhack()
            sleep 25
        }
    }

    DisableSpeedHack()
    {
        loop, 5 {
            Configuration.DisableMovementSpeedhack()
            sleep 25
        }
    }

    ; simply check for the buff food and use 
    CheckBuffFood()
    {
        log.addLogEntry("$time: checking buff food")

        ; check if buff food icon is visible
        if (!UserInterface.IsBuffFoodIconVisible()) {
            log.addLogEntry("$time: using buff food")

            Configuration.UseBuffFood()
            sleep 750
            send {w down}
            sleep 50
            send {w up}
            sleep 200
        }
    }

    ; walk to the eva sword from exit spawn
    EnterDungeon()
    {
        log.addLogEntry("$time: entering dungeon, runs done: " this.runCount)

        send {w down}
        send {Shift}

        while (!UserInterface.IsInLoadingScreen()) {
            sleep 25
        }

        Aerodrome.WaitLoadingScreen()

        return Aerodrome.MoveToDummies()
    }

    MoveToDummies()
    {
		sleep 1.5*1000

        Aerodrome.CheckRepair()
        Aerodrome.CheckBuffFood()

        log.addLogEntry("$time: moving to the dummy room")

        Aerodrome.EnableSpeedHack()

        send {w down}
        send {Shift}
        sleep 12*1000 / (Configuration.MovementSpeedhackValue())
        send {w up}
        sleep 50

        send {a down}
        sleep 11*1000 / Configuration.MovementSpeedhackValue()
        send {a up}
        sleep 50

        send {w down}
        send {Shift}
        sleep 6*1000 / (Configuration.MovementSpeedhackValue())
        send {w up}
        sleep 50

        send {a down}
        sleep 6*1000 / Configuration.MovementSpeedhackValue()
        send {a up}
        sleep 50

        Aerodrome.DisableSpeedHack()

        return Aerodrome.StartAutoCombat()
    }

    StartAutoCombat()
    {
        log.addLogEntry("$time: activating auto combat")

        Configuration.ToggleAutoCombat()

        sleep 5*1000

        while (!UserInterface.IsOutOfCombat() && !UserInterface.IsReviveVisible()) {
            sleep 25
        }

        if (UserInterface.IsReviveVisible()) {
            while (!UserInterface.IsInLoadingScreen()) {
                send 4
                sleep 25
            }

            Aerodrome.WaitLoadingScreen()

            return Aerodrome.ExitFromUnknownCamera()
        }

        sleep 2*1000

        Configuration.ToggleAutoCombat()

        return Aerodrome.FinishFight()
    }

    FinishFight()
    {
        log.addLogEntry("$time: go suicide for exit")

        Aerodrome.EnableSpeedHack()

        send {w down}
        send {Shift}
        sleep 6*1000 / (Configuration.MovementSpeedhackValue())
        sleep 50

        send {w up}
        send {d down}
        sleep 2*1000 / Configuration.MovementSpeedhackValue()
        send {w down}
        send {d up}
        sleep 50

        sleep 2*1000 / Configuration.MovementSpeedhackValue()

        send {w up}
        send {a down}
        sleep 2*1000 / Configuration.MovementSpeedhackValue()
        send {w down}
        send {a up}
        sleep 50

        sleep 2*1000 / Configuration.MovementSpeedhackValue()

        send {w up}

        Aerodrome.DisableSpeedHack()

        ; ToDo: add timeout with escape option
        start := A_TickCount
        while (!UserInterface.IsReviveVisible()) {
            if (A_TickCount > start + 120 * 1000) {
                return Aerodrome.EscapeDungeon()
            }

            sleep 250
        }

        return Aerodrome.ExitFromRevive()
    }

    EscapeDungeon()
    {
        log.addLogEntry("$time: unable to suicide, using escape")

        while (UserInterface.IsOutOfCombat()) {
            ; walk a tiny bit so possible confirmation windows (like cd on escape)
            send {w}
            sleep 250

            send {Esc}
            sleep 1*1000

            UserInterface.ClickEscape()            
        }

        while (!UserInterface.IsInLoadingScreen()) {
            sleep 25
        }

        Aerodrome.WaitLoadingScreen()

        return Aerodrome.ExitFromUnknownCamera()
    }

    ExitFromUnknownCamera()
    {
        log.addLogEntry("$time: died from dummies, camera angle unknown")

        Aerodrome.EnableSpeedHack()

        ; try to walk out of the dungeon backwards
        send {s down}
        start := A_TickCount
        while (UserInterface.IsOutOfLoadingScreen()) {
            if (A_TickCount > start + (10 * 1000  / Configuration.MovementSpeedhackValue()) + 3 * 1000) {
                log.addLogEntry("$time: walking backwards was not successful")
                break
            }
            sleep 25
        }
        send {s up}

        ; walking backwards was successful
        if (!UserInterface.IsOutOfLoadingScreen()) {
            Aerodrome.DisableSpeedHack()
            while (!UserInterface.IsInLoadingScreen()) {
                sleep 25
            }
            Aerodrome.WaitLoadingScreen()

            Configuration.ClipShadowPlay()
            return Aerodrome.FinishRun()
        }

        ; try to walk out of the dungeon forwards
        send {w down}
        start := A_TickCount
        while (UserInterface.IsOutOfLoadingScreen()) {
            if (A_TickCount > start + (10 * 1000  / Configuration.MovementSpeedhackValue()) + 3 * 1000) {
                log.addLogEntry("$time: walking forwards was not successful")
                break
            }
            sleep 25
        }
        send {w up}

        ; walking forwards was successful
        if (!UserInterface.IsOutOfLoadingScreen()) {
            Aerodrome.DisableSpeedHack()
            while (!UserInterface.IsInLoadingScreen()) {
                sleep 25
            }
            Aerodrome.WaitLoadingScreen()

            Configuration.ClipShadowPlay()
            return Aerodrome.FinishRun()
        }

        Aerodrome.DisableSpeedHack()
        log.addLogEntry("$time: unable to navigate out of the dungeon, exiting")
        Configuration.ClipShadowPlay()
        sleep 50
        ExitApp
    }

    FinishRun()
    {
        this.runCount += 1
        return Aerodrome.EnterDungeon()
    }

    ExitFromRevive()
    {
        log.addLogEntry("$time: revive and exit the dungeon")

        Aerodrome.EnableSpeedHack()

        while (!UserInterface.IsInLoadingScreen()) {
            send 4
            sleep 25
        }

        Aerodrome.DisableSpeedHack()
        Aerodrome.WaitLoadingScreen()

        log.addLogEntry("$time: exiting dungeon")

        send {a down}
        while (!UserInterface.IsInLoadingScreen()) {
            sleep 25
        }
        send {a up}

        Aerodrome.WaitLoadingScreen()

        return Aerodrome.FinishRun()
    }

    CheckRepair()
    {
        ; repair weapon after the defined amount of runs
        if (mod(this.runCount, Configuration.UseRepairToolsAfterRunCount()) == 0 || this.runCount == 0) {
            Aerodrome.RepairWeapon()
        }
    }

    ExitDungeon()
    {
        log.addLogEntry("$time: exiting dungeon")

        while (UserInterface.IsOutOfCombat()) {
            ; walk a tiny bit so possible confirmation windows (like cd on escape)
            send {w}
            sleep 250

            send {Esc}
            sleep 1*1000

            UserInterface.ClickExit()
        }

        while (!UserInterface.IsInLoadingScreen()) {
            sleep 25
        }

        Aerodrome.WaitLoadingScreen()

        return Aerodrome.UseExitPortal()
    }

    ; repair the weapon
    RepairWeapon()
    {
        log.addLogEntry("$time: repairing weapon")

        start := A_TickCount
        while (A_TickCount < start + 5.5*1000) {
            Configuration.UseRepairTools()
            sleep 5
        }
    }

    Exiting()
    {
        Utility.ReleaseAllKeys()

        if (Configuration.ShutdownComputerAfterCrash()) {
            WinGet, currentProcess, ProcessName, A
            if (currentProcess != "BNSR.exe") {
                ; normal shutdown and force close applications
                Shutdown, 5
            }
        }
    }
}