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

    ; check state of game and check sync if the other computer eventually crashed
    CheckGameActivity()
    {
        if (!Utility.GameActive() || Sync.HasState("game_crash")) {
            Sync.SetState("game_crash")
            Reload
        }
    }

    EnterLobby(warlock)
    {
        this.warlock := warlock

        Aerodrome.CheckGameActivity()
        log.addLogEntry("$time: moving to dungeon")

        this.runStartTimeStamp := A_TickCount
        this.diedInRun := false

        if (this.warlock) {
            Sync.SetState("warlock")
        } else {
            Sync.SetState("carry")
        }

        ; sleep for both characters in lobby
        while (!Configuration.IsWarlockTest() && !(Sync.HasState("warlock") && Sync.HasState("carry"))) {
            sleep 25
        }

        if (this.warlock) {
            if (!Configuration.IsWarlockTest()) {
                lastInvite := 0
                while (!UserInterface.IsDuoReady() && Utility.GameActive()) {
                    if (lastInvite + 3*1000 <= A_TickCount) {
                        UserInterface.ClickChat()
                        ; clear possible leftovers in chat
                        loop, 10 {
                            send {BackSpace}
                            sleep 2
                        }
                        Configuration.InviteDuo()
                        send {Enter}
                        lastInvite := A_TickCount
                    }
                    sleep 25
                }

            }

            Aerodrome.EnableSpeedHack()

            while (!UserInterface.IsInLoadingScreen() && Utility.GameActive()) {
                ; sometimes stage selection is out of focus, so we try to set it twice
                stage := Configuration.AerodromeStage()
                UserInterface.EditStage()
                sleep 250
                send %stage%
                sleep 250

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
            while (!UserInterface.HasPartyMemberInLobby() && Utility.GameActive()) {
                ; click somewhere so we're not in the chatbox anymore
                UserInterface.ClickReady()
                ; accept invites
                send y
            }

            while (!UserInterface.IsReady() && Utility.GameActive()) {
                ; click ready
                UserInterface.ClickReady()
                sleep 1*1000
            }
        }

        Aerodrome.WaitLoadingScreen()

        if (this.warlock) {
            Sync.ClearStates()
        }

        return Aerodrome.EnterDungeon()
    }

    EnterDungeon()
    {
        Aerodrome.CheckGameActivity()
        log.addLogEntry("$time: entering dungeon")

        send {w down}
        send {Shift}

        sleep 250

        start := A_TickCount
        reachedPortal := false
        while (A_TickCount < start + 15*1000) {
            if (!UserInterface.IsOutOfLoadingScreen()) {
                reachedPortal := true
                break
            }

            if (mod(Round(A_TickCount / 1000), 3) == 0) {
                Random, rand, 1, 10
                if (rand >= 3) {
                    send {Space down}
                    sleep 200
                    send {Space up}
                }
                ; sleep 0.5 seconds so we don't run into the modulo check again in this cycle
                sleep 1000
            }

            sleep 25
        }

        if (!reachedPortal) {
            ; create exit dungeon and portal states to reach portal sync point and instantly exit
            Sync.SetState("exit_dungeon")
            Sync.SetState("portal")

            return Aerodrome.ExitDungeon()
        }

        Aerodrome.WaitLoadingScreen()

        return Aerodrome.MoveToDummies()
    }

    MoveToDummies()
    {
        Aerodrome.CheckGameActivity()
        Aerodrome.CheckRepair()

		sleep 1*1000

        Aerodrome.CheckBuffFood()

        if (!this.warlock) {
            sleep 0.5*1000
            Aerodrome.CheckHealth()
            ; sleep to prevent portal icon disappearing for a split second
            sleep 0.5*1000

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
        Aerodrome.CheckGameActivity()
        if (Sync.HasState("exit_dungeon")) {
            return Aerodrome.ExitDungeon()
        }

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
                this.diedInRun := true

                Sync.SetState("exit_dungeon")
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
        Aerodrome.CheckGameActivity()
        if (this.warlock) {
            Sync.SetState("warlock_b1")
        } else {
            Sync.SetState("carry_b1")
        }

        ; sleep for both characters in front of b1
        while (!Configuration.IsWarlockTest() && !(Sync.HasState("warlock_b1") && Sync.HasState("carry_b1"))) {
            if (Sync.HasState("exit_dungeon")) {
                return Aerodrome.ExitDungeon()
            }
            sleep 25
        }

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

                Sync.SetState("exit_dungeon")
                return Aerodrome.ExitDungeon()
            }

            sleep 25
        }

        ; reset camera to run north again to boss two
        if (!Camera.ResetCamera()) {
            log.addLogEntry("$time: unable to reset camera, resetting run")
            Sync.SetState("exit_dungeon")

            return Aerodrome.ExitDungeon()
        }
        
        return Aerodrome.MoveToPortalToSecondBoss()
    }

    MoveToPortalToSecondBoss()
    {
        Aerodrome.CheckGameActivity()
        log.addLogEntry("$time: moving to portal to second boss")

        send {w down}
        send {Shift}

        start := A_TickCount
        while (!UserInterface.IsInLoadingScreen()) {
            ; timeout, probably stuck
            if (A_TickCount > start + 40*1000) {
                Sync.SetState("exit_dungeon")
                return Aerodrome.ExitDungeon()
            }

            sleep 25
        }

        send {w up}

        Aerodrome.DisableMovementSpeedhack()

        Aerodrome.WaitLoadingScreen()

        return Aerodrome.MoveToSecondBoss()
    }

    MoveToSecondBoss()
    {
        Aerodrome.CheckGameActivity()
        log.addLogEntry("$time: moving to second boss")

        if (this.warlock) {
            sleep 1*1000

            Aerodrome.MakePortalBoss(2)

            ; wait to get out of combat again for sprinting
            while (!UserInterface.IsOutOfCombat()) {
                sleep 25
            }

            Sync.SetState("port_b2")
        } else {
            start := A_TickCount
            while (A_TickCount < start + 60*1000) {
                if (Sync.HasState("port_b2")) {
                    break
                }

                if (Sync.HasState("exit_dungeon")) {
                    log.addLogEntry("$time: warlock failed to reset camera, abandon run")

                    return Aerodrome.ExitDungeon()
                }
            }
        }

        Configuration.EnableMovementSpeedhack()
        sleep 1.5*1000

        send {w down}
        send {Shift}

        start := A_TickCount
        while (!UserInterface.IsBossHealthbarVisible()) {
            if (A_TickCount > start+(60*1000 / (Configuration.MovementSpeedhackValue()))) {
                log.addLogEntry("$time: couldn't reach second boss, probably got stuck somewhere")

                Configuration.ClipShadowPlay()
                this.diedInRun := true

                Sync.SetState("exit_dungeon")
                return Aerodrome.ExitDungeon()
            }

            sleep 25
        }

        send {w up}

        Configuration.DisableMovementSpeedhack()

        return Aerodrome.FightSecondBoss()
    }

    FightSecondBoss()
    {
        Aerodrome.CheckGameActivity()
        if (this.warlock) {
            Sync.SetState("warlock_b2")
        } else {
            Sync.SetState("carry_b2")
        }

        ; sleep for both characters in front of b1
        while (!Configuration.IsWarlockTest() && !(Sync.HasState("warlock_b2") && Sync.HasState("carry_b2"))) {
            if (Sync.HasState("exit_dungeon")) {
                return Aerodrome.ExitDungeon()
            }
            sleep 25
        }

        log.addLogEntry("$time: fighting second boss")

        Configuration.EnableMovementSpeedhack()
        if (this.warlock) {
            send {w down}
            sleep 1*1000 / Configuration.MovementSpeedhackValue()
            send {w up}
            sleep 250
            send z
        }

        Configuration.ToggleAutoCombat()

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

                return Aerodrome.ExitDungeon()
            }

            sleep 25
        }

        if (this.warlock && !Configuration.IsWarlockTest()) {
            ; we expect wl to die but still want to at least get the dynamic
            Sync.WaitForState("exit_dungeon", 5*60*1000)
        } else {
            ; we can safely exit with the warlock char now too
            Sync.SetState("exit_dungeon")
        }

        return Aerodrome.ExitDungeon()
    }

    MakePortalBoss(boss)
    {
        Aerodrome.CheckGameActivity()
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
        Aerodrome.CheckGameActivity()
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
                Reload
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
            sleep 1000
            send y
            sleep 1000
            send y
            sleep 1000
            send n
            sleep 1000
            send y
            sleep 1000
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

    LogStatistics()
    {
        failedRuns := this.failedRuns.Length()
        failedRate := (failedRuns / this.runCount)
        successRate := 1.0 - failedRate

        averageRunTime := 0
        for _, v in this.successfulRuns {
            averageRunTime += v
        }
        averageRunTime /= this.successfulRuns.Length()

        if (!averageRunTime) {
            averageRunTime := 0
        }

        averageFailRunTime := 0
        for _, v in this.failedRuns {
            averageFailRunTime += v
        }
        averageFailRunTime /= this.failedRuns.Length()

        if (!averageFailRunTime) {
            averageFailRunTime := 0
        }

        averageRunsHour := 3600 / (averageRunTime * successRate + averageFailRunTime * failedRate)
        expectedSuccessfulRunsPerHour := averageRunsHour * successRate

        log.addLogEntry("$time: runs done: " this.runCount " (died in " (failedRuns) " out of " this.runCount " runs (" Utility.RoundDecimal(failedRate * 100) "%), average run time: " Utility.RoundDecimal(averageRunTime) " seconds)")
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