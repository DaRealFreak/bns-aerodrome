SetKeyDelay, -1, -1
SetWinDelay, -1

#Include %A_ScriptDir%\lib\utility.ahk
#Include %A_ScriptDir%\lib\log.ahk

#Include %A_ScriptDir%\camera.ahk
#Include %A_ScriptDir%\config.ahk
#Include %A_ScriptDir%\ui.ahk
#Include %A_ScriptDir%\sync.ahk
#Include %A_ScriptDir%\hotkeys.ahk

class Aerodrome
{
    static warlock := false

    static runCount := 0

    static successfulRuns := []
    static failedRuns := []

    static diedInRun := false
    static runStartTimeStamp := 0

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
            Configuration.EnableLobbySpeedhack()
            sleep 25
        }
    }

    EnableAnimationSpeedHack()
    {
        loop, 5 {
            Configuration.EnableAnimationSpeedHack()
            sleep 25
        }
    }

    DisableSpeedHack()
    {
        loop, 5 {
            Configuration.DisableLobbySpeedhack()
            sleep 25
        }
    }

    DisableAnimationSpeedHack()
    {
        loop, 5 {
            Configuration.DisableAnimationSpeedhack()
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

    ; function we use for checking if we should check potions
    CheckHealth()
    {
        if (UserInterface.IsHpBelowCritical()) {
            Configuration.UseHealthPotion()
        }
    }

    EnterLobby(warlock)
    {
        this.warlock := warlock

        log.addLogEntry("$time: moving to dungeon")

        this.runStartTimeStamp := A_TickCount
        this.diedInRun := false

        if (!this.warlock || Configuration.IsWarlockTest()) {
            if (!Configuration.IsWarlockTest()) {
                lastInvite := 0
                while (!UserInterface.IsDuoReady() && Utility.GameActive()) {
                    if (lastInvite + 3*1000 <= A_TickCount) {
                        UserInterface.ClickChat()
                        Configuration.InviteDuo()
                        send {Enter}
                        lastInvite := A_TickCount
                    }
                    sleep 25
                }

            }

            Aerodrome.EnableSpeedHack()

            while (!UserInterface.IsInLoadingScreen()) {
                ; sometimes stage selection is out of focus, so we try to set it twice
                stage := Configuration.AerodromeStage()
                loop, 2 {
                    UserInterface.EditStage()
                    sleep 250
                    send %stage%
                    sleep 250
                }

                UserInterface.ClickEnterDungeon()
                start := A_TickCount

                ; repeat loop every 3 seconds but break as soon as we see the loading screen
                while (start + 3*1000 >= A_TickCount) {
                    if (UserInterface.IsInLoadingScreen()) {
                        break
                    }
                    sleep 25
                }
            }

            Aerodrome.DisableSpeedHack()
        } else {
            ; receiver clears previous states to prevent desyncs
            Sync.ClearStates()

            while (!UserInterface.HasPartyMemberInLobby()) {
                ; click somewhere so we're not in the chatbox anymore
                UserInterface.ClickReady()
                ; accept invites
                send y
            }

            while (!UserInterface.IsReady()) {
                ; click ready
                UserInterface.ClickReady()
                sleep 1*1000
            }
        }

        Aerodrome.WaitLoadingScreen()

        return Aerodrome.EnterDungeon()
    }

    EnterDungeon()
    {
        log.addLogEntry("$time: entering dungeon")

        send {w down}
        send {Shift}

        sleep 250

        start := A_TickCount
        while (!UserInterface.IsInLoadingScreen()) {
            if (mod(Round(A_TickCount / 1000), 5) == 0) {
                Random, rand, 1, 10
                if (rand >= 5) {
                    send {Space down}
                    sleep 200
                    send {Space up}
                }
                ; sleep 0.5 seconds so we don't run into the modulo check again in this cycle
                sleep 1000
            }

            sleep 25
        }

        Aerodrome.WaitLoadingScreen()

        return Aerodrome.MoveToDummies()
    }

    MoveToDummies()
    {
		if (!this.warlock) {
            Aerodrome.CheckRepair()
        }

		sleep 1*1000

        Aerodrome.CheckBuffFood()

        if (!this.warlock) {
            sleep 0.5*1000
            Aerodrome.CheckHealth()

            log.addLogEntry("$time: waiting for portal")
            Sync.WaitForState("portal")

            ; portal creation failed
            if (Sync.HasState("exit_dungeon")) {
                return Aerodrome.ExitDungeon()
            }
        } else {
            log.addLogEntry("$time: creating portal")
            Aerodrome.MakePortalBoss(1)

            start := A_TickCount
            while (A_TickCount < start + 10*1000) {
                if (UserInterface.IsPortalIconVisible()) {
                    Sync.SetState("portal")
                    break
                }

                sleep 25
            }

            ; portal creation failed
            if (!Sync.HasState("portal")) {
                ; create exit dungeon and portal states to reach portal sync point and instantly exit
                Sync.SetState("exit_dungeon")
                Sync.SetState("portal")

                return Aerodrome.ExitDungeon()
            }
        }

        return Aerodrome.MoveFirstBoss()
    }

    MoveFirstBoss()
    {
        log.addLogEntry("$time: moving to first boss")

        while (UserInterface.IsPortalIconVisible()) {
            send f
            sleep 25
        }

        Configuration.EnableMovementSpeedhack()

        send {w down}

        start := A_TickCount
        while (!UserInterface.IsBossHealthbarVisible()) {
            if (A_TickCount > start+(50*1000 / (Configuration.MovementSpeedhackValue()))) {
                log.addLogEntry("$time: couldn't reach first boss, probably got stuck somewhere")

                Configuration.ClipShadowPlay()

                ; ToDo Sync
                return Aerodrome.ExitDungeon()
            }

            sleep 25
        }

        send {w up}

        Configuration.DisableMovementSpeedhack()

        return Aerodrome.FightFirstBoss()
    }

    FightFirstBoss()
    {
        log.addLogEntry("$time: fighting first boss")

        Configuration.ToggleAutoCombat()
        Configuration.EnableMovementSpeedhack()

        ; sleep to get into combat, else the check will instantly think the fight is over
        sleep 10*1000

        start := A_TickCount
        while (true) {
            if (UserInterface.IsOutOfCombat() || UserInterface.IsReviveVisible()) {
                Configuration.ToggleAutoCombat()
                break
            }

            if (Utility.GameActive()) {
                ; use talisman if in the game
                Configuration.UseTalisman()

                if (UserInterface.IsHpBelowCritical()) {
                    Configuration.CriticalHpAction()
                }

                sleep 25
            }

            if (A_TickCount > (start + 6*60*1000)) {
                ; timeout for autocombat are 6 minutes, probably being stuck somewhere, safety exit over lobby which works even when dead
                Configuration.DisableAnimationSpeedhack()
                return Aerodrome.ExitOverLobby()
            }

            if (UserInterface.IsInLoadingScreen()) {
                ; autocombat pressed 4 without ahk noticing
                this.diedInRun := true
                Aerodrome.WaitLoadingScreen()

                ; ToDo: sync
                return Aerodrome.ExitDungeon()
            }

            sleep 25
        }

        ; reset camera to run north again to boss two
        if (!Camera.ResetCamera()) {
            log.addLogEntry("$time: unable to reset camera, resetting run")
            Sync.SetState("exit_dungeon")
        }
        
        ExitApp
    }

    MoveToPortalToSecondBoss()
    {
        log.addLogEntry("$time: moving to portal to second boss")

        send {w down}
        while (!UserInterface.IsInLoadingScreen()) {
            sleep 25
        }
        send {w up}
        Aerodrome.DisableMovementSpeedhack()

        Aerodrome.WaitLoadingScreen()

        return Aerodrome.MoveToSecondBoss()
    }

    MoveToSecondBoss()
    {
        log.addLogEntry("$time: moving to second boss")

        ; ToDo: portal for wl, wait and run straight for carry
    }

    FightSecondBoss()
    {
        log.addLogEntry("$time: fighting second boss")

        send 2
        sleep 250

        start := A_TickCount
        while (A_TickCount < start + 15*1000) {
            if (UserInterface.IsLootIconVisible()) {
                break
            }
            send t
            sleep 15
        }

        sleep 500
        Aerodrome.LootBoss()

        return Aerodrome.ExitDynamic()
    }

    MakePortalBoss(boss)
    {
        ; activate clip
        loop, 5 {
            Configuration.EnableClip()
            sleep 200
        }

        if (boss == 1) {
            loop, 5 {
                Configuration.EnableClipBossOne()
                sleep 25
            }
        } else {
            loop, 5 {
                Configuration.EnableClipBossTwo()
                sleep 25
            }
        }

        ; position update
        send {w down}
        sleep 250
        send {w up}

        sleep 500

        ; spawn thrall
        send {Tab}
        sleep 2*1000

        if (boss == 1) {
            loop, 3 {
                Configuration.DisableClipBossOne()
                sleep 25
            }
        } else {
            loop, 5 {
                Configuration.DisableClipBossTwo()
                sleep 25
            }
        }

        ; position update
        send {w down}
        sleep 250
        send {w up}

        ; use block to get into combat to despawn thrall due to distance
        sleep 250
        send {1}

        ; disable clip
        loop, 5 {
            Configuration.DisableClip()
            sleep 200
        }
    }

    ExitOverLobby()
    {
        log.addLogEntry("$time: exiting over lobby")
        while (!UserInterface.IsInLoadingScreen()) {            
            send {AltDown}
            sleep 150
            MouseClick, Left, 318, 78
            sleep 150
            send {AltUp}

            sleep 500
            send y
        }

        UserInterface.WaitLoadingScreen()

        return Aerodrome.ExitDungeon()
    }

    ExitDynamic()
    {
        log.addLogEntry("$time: taking dynamic")

        send {AltDown}
        sleep 150
        MouseClick, Left, 1628, 690
        sleep 150
        send {AltUp}

        sleep 500
        send y
        sleep 500
        send n
        sleep 500
        send y
        sleep 500

        return Aerodrome.ExitDungeon()
    }

    Revive()
    {
        Aerodrome.EnableSpeedHack()

        ; ToDo: add timeout
        while (!UserInterface.IsInLoadingScreen()) {
            send 4
            sleep 25
        }

        Aerodrome.DisableSpeedHack()
        Aerodrome.WaitLoadingScreen()
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

        while (!UserInterface.IsInF8Lobby()) {
            if (!Utility.GameActive()) {
                log.addLogEntry("$time: couldn't find game process, exiting")
                ExitApp
            }

            ; revive to prevent appearing in death logs
            if (UserInterface.IsReviveVisible()) {
                Aerodrome.Revive()
            }

            ; walk a tiny bit so possible confirmation windows (like cd on escape)
            send {w}
            sleep 250

            send {Esc}
            sleep 1*1000

            UserInterface.ClickExit()
            sleep 1*1000
            send y
        }

        if (!this.diedInRun) {
            log.addLogEntry("$time: run took " Utility.RoundDecimal(((A_TickCount - this.runStartTimeStamp) / 1000)) " seconds")
            this.successfulRuns.Push(((A_TickCount - this.runStartTimeStamp) / 1000))
        } else {
            log.addLogEntry("$time: failed run after " Utility.RoundDecimal(((A_TickCount - this.runStartTimeStamp) / 1000)) " seconds")
            this.failedRuns.Push(((A_TickCount - this.runStartTimeStamp) / 1000))
        }

        this.runCount += 1

        Aerodrome.LogStatistics()

        return true
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