#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; Keyboard OSD
; Keyviz-inspired / AutoHotkey v2
;
; Ctrl + Alt + F11 : 启用/暂停 OSD
; Ctrl + Alt + F12 : 退出
; ============================================================

InstallKeybdHook()


; ============================================================
; 配置
; ============================================================

global CFG := {
    ; ---------- 行为 ----------
    OnlyShortcuts: true,       ; true = 只显示 Modifier + 普通键
    FollowActiveMonitor: true,  ; 跟随活动窗口所在显示器

    ; ---------- 防卡键 ----------
    ReconcileInterval: 120,
    ReconcileGrace: 90,

    ; ---------- 位置 ----------
    MarginRight: 24,
    MarginBottom: 24,

    ; ---------- Keycap ----------
    PillHeight: 38,
    Gap: 7,
    RowGap: 7,
    MaxRowWidth: 720,

    ; ---------- 字体 ----------
    FontName: "Segoe UI",
    FontSize: 12,

    ; ---------- Primary ----------
    PrimaryBG: "2C313A",
    PrimaryText: "FFFFFF",
    PrimaryWeight: 700,

    ; ---------- Modifier ----------
    ; Ctrl / Alt / Shift / Win / Caps
    ModifierBG: "202735",
    ModifierText: "C4D5F3",
    ModifierWeight: 600,

    ; ---------- Alpha ----------
    FullAlpha: 245,
    GhostAlpha: 175,

    ; ---------- 消失动画 ----------
    HoldDelay: 380,
    FadeInterval: 16,
    FadeAmount: 14
}


global KeyboardApp :=
    KeyboardVisualizer(CFG)

KeyboardApp.Start()


; ============================================================
; 快捷键
; ============================================================

^!F11::KeyboardApp.Toggle()
^!F12::ExitApp()



; ============================================================
; KeyboardVisualizer
; ============================================================

class KeyboardVisualizer
{
    __New(cfg)
    {
        this.Cfg := cfg

        this.Enabled := true

        ; 当前物理按住的键
        this.Keys := Map()

        ; 实际按下顺序
        this.Order := []

        ; 最近一次 KeyDown 时的完整 chord
        ;
        ; Ctrl
        ; Ctrl+C
        ; Ctrl
        ; Ctrl+V
        ;
        ; 最终残影应为 Ctrl+V
        this.LastChord := []

        ; 避免重复重绘
        this.LastSignature := ""

        this.OSD :=
            PillOSD(cfg)


        ; ----------------------------------------------------
        ; InputHook
        ; ----------------------------------------------------

        this.IH :=
            InputHook("V")

        this.IH.KeyOpt(
            "{All}",
            "N"
        )


        this.DownCallback :=
            ObjBindMethod(
                this,
                "OnKeyDown"
            )

        this.UpCallback :=
            ObjBindMethod(
                this,
                "OnKeyUp"
            )

        this.ReconcileCallback :=
            ObjBindMethod(
                this,
                "ReconcileKeys"
            )

        this.ExitCallback :=
            ObjBindMethod(
                this,
                "Shutdown"
            )

        this.ToggleCallback :=
            ObjBindMethod(
                this,
                "Toggle"
            )

        this.MenuExitCallback :=
            ObjBindMethod(
                this,
                "ExitFromMenu"
            )


        this.IH.OnKeyDown :=
            this.DownCallback

        this.IH.OnKeyUp :=
            this.UpCallback
    }


    ; ========================================================
    ; Start
    ; ========================================================

    Start()
    {
        this.SetupTray()

        this.IH.Start()

        SetTimer(
            this.ReconcileCallback,
            this.Cfg.ReconcileInterval
        )

        OnExit(
            this.ExitCallback
        )
    }


    ; ========================================================
    ; Tray
    ; ========================================================

    SetupTray()
    {
        try A_TrayMenu.Delete()

        A_TrayMenu.Add(
            "启用 OSD",
            this.ToggleCallback
        )

        A_TrayMenu.Check(
            "启用 OSD"
        )

        A_TrayMenu.Add()

        A_TrayMenu.Add(
            "退出",
            this.MenuExitCallback
        )
    }


    ; ========================================================
    ; Toggle
    ; ========================================================

    Toggle(*)
    {
        this.Enabled :=
            !this.Enabled


        if this.Enabled
        {
            try A_TrayMenu.Check(
                "启用 OSD"
            )

            this.ResetRound()

            ; 如果启用时用户正按着键，
            ; 立即同步当前状态。
            if this.Keys.Count > 0
                this.Refresh(true)
        }
        else
        {
            try A_TrayMenu.Uncheck(
                "启用 OSD"
            )

            this.OSD.HideImmediate()

            this.ResetRound()
        }
    }


    ExitFromMenu(*)
    {
        ExitApp()
    }


    ; ========================================================
    ; Shutdown
    ; ========================================================

    Shutdown(
        ExitReason := "",
        ExitCode := 0
    )
    {
        try SetTimer(
            this.ReconcileCallback,
            0
        )

        try this.IH.Stop()

        try this.OSD.Destroy()
    }


    ; ========================================================
    ; Key Down
    ; ========================================================

    OnKeyDown(
        IH,
        VK,
        SC
    )
    {
        id :=
            this.MakeKeyID(
                VK,
                SC
            )


        ; 长按产生重复 KeyDown
        if this.Keys.Has(id)
            return


        ; 从 0 个键开始：
        ; 新的一轮输入。
        if this.Keys.Count = 0
            this.ResetRound()


        keySpec :=
            Format(
                "vk{:X}sc{:X}",
                VK,
                SC
            )


        rawName := ""

        try rawName :=
            GetKeyName(keySpec)


        if rawName = ""
        {
            rawName :=
                Format(
                    "VK{:02X}",
                    VK
                )
        }


        name :=
            this.NormalizeKeyName(
                rawName
            )


        this.Keys[id] := {
            Name: name,
            Raw: rawName,

            VK: VK,
            SC: SC,

            PhysicalSpec:
                this.MakePhysicalSpec(
                    VK,
                    SC
                ),

            DownAt:
                A_TickCount
        }


        this.Order.Push(id)


        ; true:
        ; 这是 KeyDown，所以更新 LastChord。
        this.Refresh(true)
    }


    ; ========================================================
    ; Key Up
    ; ========================================================

    OnKeyUp(
        IH,
        VK,
        SC
    )
    {
        id :=
            this.MakeKeyID(
                VK,
                SC
            )


        if !this.Keys.Has(id)
            return


        this.RemoveKey(id)


        ; KeyUp 不更新 LastChord。
        this.Refresh(false)
    }


    ; ========================================================
    ; 防卡键
    ; ========================================================

    ReconcileKeys()
    {
        if this.Keys.Count = 0
            return


        stale := []


        for id, info in this.Keys
        {
            age :=
                A_TickCount
                - info.DownAt


            ; 刚按下时给 Hook 一个保护时间
            if age < this.Cfg.ReconcileGrace
                continue


            isDown := true


            try
            {
                isDown :=
                    GetKeyState(
                        info.PhysicalSpec,
                        "P"
                    )
            }
            catch
            {
                continue
            }


            if !isDown
                stale.Push(id)
        }


        if stale.Length = 0
            return


        for _, id in stale
            this.RemoveKey(id)


        this.Refresh(false)
    }


    ; ========================================================
    ; Refresh
    ; ========================================================

    Refresh(
        fromKeyDown := false
    )
    {
        names :=
            this.BuildDisplayKeys()


        ; OSD 被暂停时：
        ; 状态仍然继续维护，但不显示。
        if !this.Enabled
            return


        ; ====================================================
        ; 还有按键
        ; ====================================================

        if names.Length > 0
        {
            ; ------------------------------------------------
            ; 每次 KeyDown 都保存“最近完整 chord”
            ;
            ; 比使用最大长度 Peak 更合理。
            ; ------------------------------------------------

            if fromKeyDown
            {
                this.LastChord :=
                    this.CopyArray(names)
            }


            ; ------------------------------------------------
            ; Hotkey Filter
            ; ------------------------------------------------

            if !this.ShouldDisplay(names)
            {
                this.OSD.HideImmediate()

                this.LastSignature := ""

                return
            }


            signature :=
                this.MakeSignature(names)


            ; ------------------------------------------------
            ; 相同视觉状态不重复 Render
            ;
            ; 但如果当前正在 fading，
            ; 新输入必须恢复。
            ; ------------------------------------------------

            if (
                signature != this.LastSignature
                || this.OSD.State != "visible"
            )
            {
                this.OSD.ShowLive(
                    names
                )

                this.LastSignature :=
                    signature
            }


            return
        }


        ; ====================================================
        ; 所有键松开
        ; ====================================================

        this.LastSignature := ""


        snapshot :=
            this.CopyArray(
                this.LastChord
            )


        if (
            snapshot.Length > 0
            && this.ShouldDisplay(snapshot)
        )
        {
            this.OSD.Release(
                snapshot
            )
        }
        else
        {
            this.OSD.HideImmediate()
        }
    }


    ; ========================================================
    ; OnlyShortcuts Filter
    ; ========================================================

    ShouldDisplay(names)
    {
        if !this.Cfg.OnlyShortcuts
            return true


        hasModifier := false
        hasPrimary := false


        for _, name in names
        {
            if this.IsModifier(name)
                hasModifier := true
            else
                hasPrimary := true
        }


        return (
            hasModifier
            && hasPrimary
        )
    }


    ; ========================================================
    ; Reset Round
    ; ========================================================

    ResetRound()
    {
        this.LastChord := []

        this.LastSignature := ""
    }


    ; ========================================================
    ; Remove
    ; ========================================================

    RemoveKey(id)
    {
        if this.Keys.Has(id)
            this.Keys.Delete(id)


        for index, orderID in this.Order
        {
            if orderID = id
            {
                this.Order.RemoveAt(
                    index
                )

                break
            }
        }
    }


    ; ========================================================
    ; Build Display
    ; ========================================================

    BuildDisplayKeys()
    {
        result := []


        ; ----------------------------------------------------
        ; 修饰键保持稳定顺序
        ; ----------------------------------------------------

        modifiers := [
            "Ctrl",
            "Alt",
            "Shift",
            "Win",
            "Caps"
        ]


        for _, modifier in modifiers
        {
            if this.HasDisplayName(
                modifier
            )
            {
                result.Push(
                    modifier
                )
            }
        }


        ; ----------------------------------------------------
        ; 普通键按真实按下顺序
        ; ----------------------------------------------------

        for _, id in this.Order
        {
            if !this.Keys.Has(id)
                continue


            name :=
                this.Keys[id].Name


            if this.IsModifier(name)
                continue


            result.Push(name)
        }


        return result
    }


    ; ========================================================
    ; Modifier
    ; ========================================================

    IsModifier(name)
    {
        return (
            name = "Ctrl"
            || name = "Alt"
            || name = "Shift"
            || name = "Win"
            || name = "Caps"
        )
    }


    HasDisplayName(name)
    {
        for _, info in this.Keys
        {
            if info.Name = name
                return true
        }


        return false
    }


    ; ========================================================
    ; Key Names
    ; ========================================================

    NormalizeKeyName(name)
    {
        switch name
        {
            ; Modifier

            case "Control",
                 "LControl",
                 "RControl",
                 "LCtrl",
                 "RCtrl":
                return "Ctrl"


            case "LAlt",
                 "RAlt":
                return "Alt"


            case "LShift",
                 "RShift":
                return "Shift"


            case "LWin",
                 "RWin":
                return "Win"


            case "CapsLock":
                return "Caps"


            ; Common

            case "Escape":
                return "Esc"


            case "Return":
                return "Enter"


            case "Delete":
                return "Del"


            case "Insert":
                return "Ins"


            case "NumLock":
                return "Num"


            case "ScrollLock":
                return "Scroll"


            case "PrintScreen":
                return "PrtSc"


            case "AppsKey":
                return "Menu"


            ; Navigation

            case "Left":
                return "←"

            case "Right":
                return "→"

            case "Up":
                return "↑"

            case "Down":
                return "↓"


            ; Numpad

            case "NumpadEnter":
                return "Num Enter"

            case "NumpadAdd":
                return "Num +"

            case "NumpadSub":
                return "Num −"

            case "NumpadMult":
                return "Num ×"

            case "NumpadDiv":
                return "Num ÷"

            case "NumpadDot":
                return "Num ."


            ; Volume

            case "Volume_Up":
                return "Vol +"

            case "Volume_Down":
                return "Vol −"

            case "Volume_Mute":
                return "Mute"


            ; Media

            case "Media_Play_Pause":
                return "Play"

            case "Media_Next":
                return "Next"

            case "Media_Prev":
                return "Prev"

            case "Media_Stop":
                return "Stop"


            ; Browser

            case "Browser_Back":
                return "Browser ←"

            case "Browser_Forward":
                return "Browser →"

            case "Browser_Refresh":
                return "Refresh"

            case "Browser_Home":
                return "Browser Home"


            default:
                return name
        }
    }


    ; ========================================================
    ; ID
    ; ========================================================

    MakeKeyID(
        VK,
        SC
    )
    {
        return Format(
            "{:02X}:{:03X}",
            VK,
            SC
        )
    }


    MakePhysicalSpec(
        VK,
        SC
    )
    {
        if SC
        {
            return Format(
                "sc{:03X}",
                SC
            )
        }


        return Format(
            "vk{:02X}",
            VK
        )
    }


    ; ========================================================
    ; Helpers
    ; ========================================================

    MakeSignature(names)
    {
        result := ""


        for _, name in names
        {
            result .=
                Chr(31)
                . name
        }


        return result
    }


    CopyArray(source)
    {
        result := []


        for _, value in source
            result.Push(value)


        return result
    }
}



; ============================================================
; PillOSD
; ============================================================

class PillOSD
{
    __New(cfg)
    {
        this.Cfg := cfg

        this.Pool := []

        this.VisibleCount := 0

        this.CurrentAlpha :=
            cfg.FullAlpha


        ; hidden / visible / waiting / fading
        this.State :=
            "hidden"


        this.BeginFadeCallback :=
            ObjBindMethod(
                this,
                "_BeginFade"
            )

        this.FadeCallback :=
            ObjBindMethod(
                this,
                "_FadeTick"
            )
    }


    ; ========================================================
    ; Live
    ; ========================================================

    ShowLive(names)
    {
        this.CancelAnimation()


        this.State :=
            "visible"


        this.CurrentAlpha :=
            this.Cfg.FullAlpha


        this.ShowNames(
            names,
            this.Cfg.FullAlpha
        )
    }


    ; ========================================================
    ; Release
    ; ========================================================

    Release(snapshot)
    {
        if snapshot.Length = 0
        {
            this.HideImmediate()
            return
        }


        this.CancelAnimation()


        ; 直接用 ghost alpha 恢复完整 chord。
        ; 不先 FullAlpha，避免闪一下。
        this.ShowNames(
            snapshot,
            this.Cfg.GhostAlpha
        )


        this.CurrentAlpha :=
            this.Cfg.GhostAlpha


        this.State :=
            "waiting"


        ; 负数周期 = 单次 timer
        SetTimer(
            this.BeginFadeCallback,
            -this.Cfg.HoldDelay
        )
    }


    ; ========================================================
    ; Fade
    ; ========================================================

    _BeginFade()
    {
        if this.State != "waiting"
            return


        this.State :=
            "fading"


        SetTimer(
            this.FadeCallback,
            this.Cfg.FadeInterval
        )
    }


    _FadeTick()
    {
        if this.State != "fading"
        {
            SetTimer(
                this.FadeCallback,
                0
            )

            return
        }


        this.CurrentAlpha -=
            this.Cfg.FadeAmount


        if this.CurrentAlpha <= 0
        {
            this.HideImmediate()
            return
        }


        this.SetAlpha(
            this.CurrentAlpha
        )
    }


    CancelAnimation()
    {
        SetTimer(
            this.BeginFadeCallback,
            0
        )


        SetTimer(
            this.FadeCallback,
            0
        )
    }


    ; ========================================================
    ; Render
    ; ========================================================

    ShowNames(
        names,
        alpha
    )
    {
        this.GetTargetWorkArea(
            &workLeft,
            &workTop,
            &workRight,
            &workBottom
        )


        availableWidth :=
            workRight
            - workLeft
            - 40


        maxRowWidth :=
            Min(
                this.Cfg.MaxRowWidth,
                availableWidth
            )


        rows :=
            this.BuildRows(
                names,
                maxRowWidth
            )


        this.EnsurePool(
            names.Length
        )


        totalHeight :=
            rows.Length
            * this.Cfg.PillHeight


        if rows.Length > 1
        {
            totalHeight +=
                (
                    rows.Length - 1
                )
                * this.Cfg.RowGap
        }


        y :=
            workBottom
            - this.Cfg.MarginBottom
            - totalHeight


        index := 1


        for _, row in rows
        {
            ; 每一行都右对齐
            x :=
                workRight
                - this.Cfg.MarginRight
                - row.Width


            for _, item in row.Items
            {
                pill :=
                    this.Pool[index]


                pill.Show(
                    item.Name,
                    item.Type,

                    x,
                    y,

                    item.Width,
                    this.Cfg.PillHeight,

                    alpha
                )


                x +=
                    item.Width
                    + this.Cfg.Gap


                index++
            }


            y +=
                this.Cfg.PillHeight
                + this.Cfg.RowGap
        }


        ; 隐藏 pool 中多余窗口
        while index <= this.Pool.Length
        {
            this.Pool[index].Hide()

            index++
        }


        this.VisibleCount :=
            names.Length
    }


    ; ========================================================
    ; Layout
    ; ========================================================

    BuildRows(
        names,
        maxWidth
    )
    {
        rows := []

        items := []

        rowWidth := 0


        for _, name in names
        {
            width :=
                this.GetPillWidth(name)


            type :=
                this.IsModifier(name)
                    ? "modifier"
                    : "primary"


            required := width


            if items.Length
                required += this.Cfg.Gap


            if (
                items.Length
                && rowWidth + required > maxWidth
            )
            {
                rows.Push({
                    Items: items,
                    Width: rowWidth
                })


                items := []
                rowWidth := 0
            }


            if items.Length
                rowWidth += this.Cfg.Gap


            items.Push({
                Name: name,
                Width: width,
                Type: type
            })


            rowWidth += width
        }


        if items.Length
        {
            rows.Push({
                Items: items,
                Width: rowWidth
            })
        }


        return rows
    }


    ; ========================================================
    ; Modifier
    ;
    ; 与 Keyviz 的设计思路一致：
    ; Modifier 始终有自己的视觉身份，
    ; 不因为只有一个键就改变样式。
    ; ========================================================

    IsModifier(name)
    {
        return (
            name = "Ctrl"
            || name = "Alt"
            || name = "Shift"
            || name = "Win"
            || name = "Caps"
        )
    }


    ; ========================================================
    ; Width
    ; ========================================================

    GetPillWidth(name)
    {
        static Widths :=
            Map(
                "Ctrl",          58,
                "Alt",           48,
                "Shift",         64,
                "Win",           52,
                "Caps",          58,

                "Tab",           50,
                "Esc",           48,

                "Enter",         68,
                "Space",         78,
                "Backspace",     96,

                "Num",           54,
                "Scroll",        66,

                "PrtSc",         62,
                "Menu",          58,

                "Home",          60,
                "End",           50,
                "PgUp",          58,
                "PgDn",          58,
                "Ins",           48,
                "Del",           48,

                "←",             42,
                "→",             42,
                "↑",             42,
                "↓",             42,

                "Mute",          58,
                "Vol +",         62,
                "Vol −",         62,

                "Play",          58,
                "Next",          58,
                "Prev",          58,
                "Stop",          58,

                "Num +",         64,
                "Num −",         64,
                "Num ×",         64,
                "Num ÷",         64,
                "Num .",         60,
                "Num Enter",     88,

                "Refresh",       72,
                "Browser ←",     88,
                "Browser →",     88,
                "Browser Home",  108
            )


        if Widths.Has(name)
            return Widths[name]


        if StrLen(name) = 1
            return 42


        if RegExMatch(
            name,
            "^F(?:[1-9]|1\d|2[0-4])$"
        )
        {
            return 48
        }


        width :=
            28
            + StrLen(name) * 8


        return Min(
            130,
            Max(
                48,
                width
            )
        )
    }


    ; ========================================================
    ; Pool
    ; ========================================================

    EnsurePool(count)
    {
        while this.Pool.Length < count
        {
            this.Pool.Push(
                PillWindow(
                    this.Cfg
                )
            )
        }
    }


    ; ========================================================
    ; Alpha
    ; ========================================================

    SetAlpha(alpha)
    {
        Loop this.VisibleCount
        {
            this.Pool[A_Index]
                .SetAlpha(alpha)
        }
    }


    ; ========================================================
    ; Hide
    ; ========================================================

    HideImmediate()
    {
        this.CancelAnimation()


        Loop this.VisibleCount
        {
            this.Pool[A_Index]
                .Hide()
        }


        this.VisibleCount := 0

        this.CurrentAlpha :=
            this.Cfg.FullAlpha


        this.State :=
            "hidden"
    }


    ; ========================================================
    ; Monitor
    ; ========================================================

    GetTargetWorkArea(
        &left,
        &top,
        &right,
        &bottom
    )
    {
        ; 固定主屏
        if !this.Cfg.FollowActiveMonitor
        {
            primary :=
                MonitorGetPrimary()


            MonitorGetWorkArea(
                primary,
                &left,
                &top,
                &right,
                &bottom
            )


            return
        }


        hwnd :=
            WinExist("A")


        bestMonitor := 0
        bestArea := 0


        if hwnd
        {
            try
            {
                WinGetPos(
                    &wx,
                    &wy,
                    &ww,
                    &wh,
                    "ahk_id " hwnd
                )


                if (
                    ww > 0
                    && wh > 0
                )
                {
                    windowRight :=
                        wx + ww


                    windowBottom :=
                        wy + wh


                    count :=
                        MonitorGetCount()


                    Loop count
                    {
                        i :=
                            A_Index


                        MonitorGet(
                            i,
                            &ml,
                            &mt,
                            &mr,
                            &mb
                        )


                        ow :=
                            Min(
                                windowRight,
                                mr
                            )
                            - Max(
                                wx,
                                ml
                            )


                        oh :=
                            Min(
                                windowBottom,
                                mb
                            )
                            - Max(
                                wy,
                                mt
                            )


                        if (
                            ow <= 0
                            || oh <= 0
                        )
                            continue


                        area :=
                            ow * oh


                        if area > bestArea
                        {
                            bestArea := area
                            bestMonitor := i
                        }
                    }
                }
            }
        }


        if bestMonitor = 0
        {
            bestMonitor :=
                MonitorGetPrimary()
        }


        MonitorGetWorkArea(
            bestMonitor,
            &left,
            &top,
            &right,
            &bottom
        )
    }


    ; ========================================================
    ; Destroy
    ; ========================================================

    Destroy()
    {
        this.CancelAnimation()


        for _, pill in this.Pool
            pill.Destroy()


        this.Pool := []

        this.VisibleCount := 0

        this.State := "hidden"
    }
}



; ============================================================
; PillWindow
; ============================================================

class PillWindow
{
    __New(cfg)
    {
        this.Cfg := cfg


        this.Window :=
            Gui(
                "+AlwaysOnTop"
                " -Caption"
                " +ToolWindow"
                " +E0x20"
            )


        ; 点击穿透
        this.Window.MarginX := 0
        this.Window.MarginY := 0


        this.Window.BackColor :=
            cfg.PrimaryBG


        this.Window.SetFont(
            "s" cfg.FontSize
            " c" cfg.PrimaryText
            " w" cfg.PrimaryWeight,
            cfg.FontName
        )


        this.Label :=
            this.Window.AddText(
                "x0 y0 w42 h38"
                " Center"
                " +0x200",
                ""
            )


        this.Hwnd :=
            this.Window.Hwnd


        this.Visible := false

        this.LastWidth := 0
        this.LastHeight := 0

        this.LastAlpha := -1

        this.CurrentStyle := ""
    }


    ; ========================================================
    ; Show
    ; ========================================================

    Show(
        text,
        type,
        x,
        y,
        width,
        height,
        alpha
    )
    {
        this.ApplyStyle(type)


        this.Label.Text :=
            text


        this.Label.Move(
            0,
            0,
            width,
            height
        )


        ; ----------------------------------------------------
        ; 首次显示时：
        ;
        ; 先放到屏幕外创建真正窗口，
        ; 然后设置圆角和透明度，
        ; 再移动到最终位置。
        ;
        ; 避免首次出现时闪烁。
        ; ----------------------------------------------------

        if !this.Visible
        {
            this.Window.Show(
                "NoActivate"
                " x-32000"
                " y-32000"
                " w" width
                " h" height
            )


            this.Visible := true


            this.ApplyRegion(
                width,
                height
            )


            this.SetAlpha(alpha)


            this.Window.Show(
                "NoActivate"
                " x" Round(x)
                " y" Round(y)
                " w" width
                " h" height
            )


            return
        }


        this.ApplyRegion(
            width,
            height
        )


        this.SetAlpha(alpha)


        this.Window.Show(
            "NoActivate"
            " x" Round(x)
            " y" Round(y)
            " w" width
            " h" height
        )
    }


    ; ========================================================
    ; Style
    ; ========================================================

    ApplyStyle(type)
    {
        if type = this.CurrentStyle
            return


        if type = "modifier"
        {
            this.Window.BackColor :=
                this.Cfg.ModifierBG


            this.Label.SetFont(
                "s" this.Cfg.FontSize
                " c" this.Cfg.ModifierText
                " w" this.Cfg.ModifierWeight,
                this.Cfg.FontName
            )
        }
        else
        {
            this.Window.BackColor :=
                this.Cfg.PrimaryBG


            this.Label.SetFont(
                "s" this.Cfg.FontSize
                " c" this.Cfg.PrimaryText
                " w" this.Cfg.PrimaryWeight,
                this.Cfg.FontName
            )
        }


        this.CurrentStyle :=
            type
    }


    ; ========================================================
    ; Round Region
    ; ========================================================

    ApplyRegion(
        width,
        height
    )
    {
        if (
            width = this.LastWidth
            && height = this.LastHeight
        )
            return


        try
        {
            WinSetRegion(
                "0-0"
                " W" width
                " H" height
                " R11-11",
                "ahk_id " this.Hwnd
            )


            this.LastWidth := width
            this.LastHeight := height
        }
    }


    ; ========================================================
    ; Alpha
    ; ========================================================

    SetAlpha(alpha)
    {
        if !this.Visible
            return


        alpha :=
            Max(
                0,
                Min(
                    255,
                    Round(alpha)
                )
            )


        ; 相同 alpha 不重复调用 Windows API
        if alpha = this.LastAlpha
            return


        try
        {
            WinSetTransparent(
                alpha,
                "ahk_id " this.Hwnd
            )


            this.LastAlpha :=
                alpha
        }
    }


    ; ========================================================
    ; Hide
    ; ========================================================

    Hide()
    {
        if !this.Visible
            return


        try this.Window.Hide()


        this.Visible := false
    }


    ; ========================================================
    ; Destroy
    ; ========================================================

    Destroy()
    {
        try this.Window.Destroy()

        this.Visible := false
    }
}