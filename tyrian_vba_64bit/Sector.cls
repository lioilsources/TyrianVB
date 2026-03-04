VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Sector"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Class Sector

Private Const DELAY_ON_COMPLETE = 2

Public caption As String
Public level As Long
Public fFleet As Fleet
Public fStruct As Structure
Public sectorBonus As Long
Public complete As Boolean
Public parent As Objects
Public nxt As Sector
Public prv As Sector
Public count As Long
Public startCount As Long
Public aid As Long

Private minTime As Long
Private completeTime As Long
Private hStat As New Hostile


Public Function GetLastFleet() As Fleet
    Dim f As Fleet
    If fFleet Is Nothing Then
        Set f = Nothing
    Else
        Set f = fFleet
        While Not f.nxt Is Nothing
            Set f = f.nxt
        Wend
    End If
    Set GetLastFleet = f
End Function


Public Function CreateFleet(ByVal enTime As Double, ByVal cap As String, ByVal ht As HostType, ByVal count As Long, _
        ByVal bon As CollType, ByVal trigger As Long, ByVal durationSec As Double, _
        ByVal srcX As Integer, ByVal srcY As Integer, ByVal dstX As Integer, ByVal dstY As Integer, _
        ByVal pType As PathType, Optional ByVal amplitude As Integer = 1, Optional ByVal cycles As Double = 1, _
        Optional ByVal amplMultiplier As Double = 1, Optional ByVal bonusValue As Long = 0, _
        Optional defaultPathAction As PathAction = Destroy) As Fleet
    
    startCount = startCount + 1
    Dim f As New Fleet
    Set f.parent = Me
    f.id = startCount
    If obj.GetHostHpMax(ht) > (rocket.dps * 0.25) Then f.showDamage = True Else f.showDamage = False
    f.enterTime = CLng(enTime)
    If Len(cap) = 0 Then
        cap = count & " x " & obj.HostCap(ht)
    Else
        cap = cap & " (" & obj.HostCap(ht) & ")"
    End If
    f.caption = cap
    f.hType = ht
    f.count = count
    f.bonus = bon
    f.defPathAction = defaultPathAction
    f.bonusMoney = bonusValue
    f.triggerSteps = trigger
    f.active = True
    f.started = False
    Call f.CreatePath().Generate(Round(durationSec * CDbl(1000) / CDbl(FRAME_DELAY)), _
            srcX, srcY, dstX, dstY, _
            pType, amplitude, cycles, amplMultiplier)
    Call f.ResetArea
    If minTime = 0 Then minTime = enTime
    If Not fFleet Is Nothing Then
        Dim lf As Fleet
        Set lf = GetLastFleet
        Set lf.nxt = f
        Set f.prv = lf
    Else
        Set fFleet = f
    End If
    Set CreateFleet = f
End Function


Public Function GetLastStruct() As Structure
    Dim s As Structure
    If fStruct Is Nothing Then
        Set s = Nothing
    Else
        Set s = fStruct
        While Not s.nxt Is Nothing
            Set s = s.nxt
        Wend
    End If
    Set GetLastStruct = s
End Function


Public Function CreateStruct(img As Image, ByVal hpMax As Long, ByVal x As Single, ByVal y As Single, _
        ByVal stype As StructType, Optional ByVal caption As String = "Structure") As Structure

    Dim s As New Structure
    Set s.parent = Me
    s.caption = caption
    If s.caption = "Structure" And stype = Asteroid Then
        aid = aid + 1
        s.caption = "Asteroid " & aid
    End If
    s.typ = stype
    s.collisionDmg = 1
    If stype = Asteroid Then s.collisionDmg = level
    Set s.img = CloneImage(img)
    s.hp = hpMax
    s.hpMax = hpMax
    s.img.x = x
    s.img.y = y
    s.x2 = Round(s.img.x + s.img.width)
    s.y2 = Round(s.img.y + s.img.height)
    s.img.drawInLoop = True
    If Not fStruct Is Nothing Then
        Dim ls As Structure
        Set ls = GetLastStruct
        Set ls.nxt = s
        Set s.prv = ls
    Else
        Set fStruct = s
    End If
    Set CreateStruct = s
End Function


Public Function Completed() As Single
    Dim s As Single
    s = 1
    If startCount > 0 And count > 0 Then s = (startCount - count) / startCount
    Completed = s
End Function


Public Sub EndSector()
    completeTime = elapsed + 3
    Set fFleet = Nothing
    Set fStruct = Nothing
    Set fExp = Nothing
End Sub


Public Sub TimedAction(ByVal seconds As Long)
    Dim f As Fleet
    Set f = fFleet
    While Not f Is Nothing
        If f.enterTime = seconds Then
            f.started = True
            completeTime = 0
            If f.IsRandom Then f.weapCharge = WeapCDFromDPS(rocket.dps, f.count)
            parent.CreateMessage "Inc. " & f.caption, FONT_ITALIC, &HD0E0F0
        End If
        Set f = f.nxt
    Wend
    If completeTime = 0 And count = 0 And seconds > minTime Then
        completeTime = seconds
        If rocket.hp > 0 Then
            parent.CreateText "Complete", 80, False
            parent.CreateText "Bonus $ " & NumSpac(sectorBonus), 70, False
            Set parent.GetLastText().trace = New Path
            parent.GetLastText().trace.Generate 200, SCR_WIDTH / 2, 350, SCR_WIDTH / 2, 450, Linear
            rocket.AddCredit sectorBonus
            Logt "Level " & currentSector.level & " done in " & ToTime(completeTime)
        End If
    End If
    If completeTime > 0 Then
        If seconds >= completeTime + DELAY_ON_COMPLETE Then
            complete = True
            displayComCenter = True
            mbutt = 0
            ActivateButtons CommandCenter
            Delete
            obj.ShowScore
        End If
    End If
End Sub


Public Sub step()
    Static f As Fleet
    Static s As Structure
    
    Set f = fFleet
    count = 0
    While Not f Is Nothing
        If f.started Then f.step
        count = count + 1
        Set f = f.nxt
    Wend

    Set s = fStruct
    rocket.moveBlock = 0
    While Not s Is Nothing
        If s.img.drawInLoop Then
            If s.enTime <= elapsed Then
                s.step
                If s.hp <= 0 Then AddStructScore s
            End If
        End If
        Set s = s.nxt
    Wend
End Sub


Public Sub Delete()
    If prv Is Nothing Then
        Set parent.fSector = nxt
    Else
        Set prv.nxt = nxt
    End If
    If Not nxt Is Nothing Then Set nxt.prv = prv
End Sub


Private Sub AddStructScore(s As Structure)
    s.img.drawInLoop = False
    rocket.AddCredit s.hpMax
    rocket.AddScore s.hpMax
    obj.CreateMessage s.caption & " destroyed."
    obj.CreateMessage "Bonus credit $ " & NumSpac(s.hpMax)
End Sub


Public Sub AddWeapon(ByVal dmg As Integer, ByVal recharge As Integer, Optional ByVal ht As HostType = falcon1)
    Dim f As Fleet
    Dim ratio As Single
    Dim devName As String
    
    Set f = GetLastFleet()
    ratio = dmg / 75
    If ratio < 0.3 Then ratio = 0.3
    If ratio > 1 Then ratio = 0.99
    devName = "Bubble Gun"
    Set f.weap = SetupDevice(devName, ratio, ht)
    f.weap.damage = dmg
    f.weapCharge = recharge
End Sub


Public Sub AddAsteroids(ByVal enTime As Long, ByVal count As Integer, ByVal x As Integer, ByVal wdth As Integer)
    Dim s As Structure
    For i = 0 To count - 1
        Set s = CreateStruct(obj.GetAsteroid(), 100000, Rnd * wdth + x, -10000, Asteroid)
        s.SetBehavior ByPath
        s.enTime = enTime + i
    Next i
End Sub


Private Sub SetAltParams(ByVal p1 As Integer, ByVal p2 As Integer, ByVal p3 As Integer, ByVal p4 As PathType, f As Fleet)
    f.altParam1 = p1
    f.altParam2 = p2
    f.altParam3 = p3
    f.altParam4 = p4
End Sub


Public Sub Setup()
On Error GoTo err

    Dim f As Fleet
    Dim ep2 As Path
    
    startCount = 0
    Select Case level
        Case 1
            Call CreateFleet(1, "Merchant sentry", falcon1, 8, FrontWepUpgrade, 75, 17, 200, -45, 400, SCR_HEIGHT + 5, Linear, 1, 1, 1, 1000)
            Call CreateFleet(12, "Asteroid miner fleet", falcon1, 8, FrontWepUpgrade, 75, 17, 300, -45, 500, SCR_HEIGHT + 5, Linear)
            Call CreateFleet(23, "Asteroid miner fleet 2", falcon2, 8, RightWepUpgrade, 75, 17, SCR_WIDTH - 200, -45, SCR_WIDTH - 400, SCR_HEIGHT + 5, Sinus, 20, 10)
            Call CreateFleet(34, "Asteroid miner fleet 3", falcon2, 8, LeftWepUpgrade, 75, 17, SCR_WIDTH - 300, -45, SCR_WIDTH - 500, SCR_HEIGHT + 5, Sinus, 20, 10)
            Call CreateFleet(52, "Asteroid miner escort", falcon3, 15, BonusCredit, 72, 27, 300, -45, 1100, SCR_HEIGHT + 5, Cosinus, 250, 10, 0.9991, 1000)
            Call AddWeapon(10, 300)
            Call CreateFleet(85, "Asteroid hunters", falcon1, 30, GeneratorUpgrade, 12, 26, SCR_WIDTH - 400, -200, 300, SCR_HEIGHT + 200, SinCos, 180, 10)
            Call CreateFleet(108, "", falcon4, 10, LeftWepUpgrade, 10, 27, 0, -400, SCR_WIDTH - 400, SCR_HEIGHT + 5, SinCos, 400, 10)
            Call CreateFleet(123, "", falcon4, 20, RightWepUpgrade, 20, 22, 0, -40, SCR_WIDTH - 100, SCR_HEIGHT + 5, Sinus, 100, 10)
            Call AddWeapon(15, 300)
            Call CreateFleet(152, "", falcon5, 20, FrontWepUpgrade, 25, 20, SCR_WIDTH, -40, 0, SCR_HEIGHT + 5, Sinus, 100, 12)
            Call AddWeapon(15, 275)
            Call CreateFleet(177, "", falcon6, 20, BonusCredit, 25, 24, -50, 200, SCR_WIDTH + 10, 200, Sinus, 100, 12, 1, 500)
            Call AddWeapon(18, 175)
            Call AddAsteroids(57, 20, Round(SCR_WIDTH / 5), Round(SCR_WIDTH / 2))
            sectorBonus = 5000
            
        Case 2
            Call CreateFleet(2, "", falcon3, 30, HealthUpgrade, 12, 27, SCR_WIDTH - 100, -200, 300, SCR_HEIGHT + 200, SinCos, 180, 10)
            Call AddWeapon(20, 400)
            Call CreateFleet(24, "", falcon4, 30, LeftWepUpgrade, 12, 27, 100, -200, SCR_WIDTH - 400, SCR_HEIGHT + 200, SinCos, 220, 10)
            Call AddWeapon(20, 400)
            Call CreateFleet(46, "", falcon5, 30, RightWepUpgrade, 12, 27, SCR_WIDTH - 100, -200, 300, SCR_HEIGHT + 200, SinCos, 180, 10)
            Call AddWeapon(20, 350)
            Call CreateFleet(68, "", falcon6, 30, ShieldUpgrade, 12, 27, 100, -200, SCR_WIDTH - 400, SCR_HEIGHT + 200, SinCos, 220, 10)
            Call AddWeapon(20, 350)
            Call CreateFleet(90, "", falcon4, 10, GeneratorUpgrade, 50, 16, 200, -45, SCR_WIDTH - 200, SCR_HEIGHT + 5, Linear)
            Call AddWeapon(20, 350)
            Call CreateFleet(94, "", falcon4, 12, LeftWepUpgrade, 50, 16, 300, -45, SCR_WIDTH - 100, SCR_HEIGHT + 5, Linear)
            Call AddWeapon(20, 300)
            Call CreateFleet(100, "", falcon5, 14, RightWepUpgrade, 50, 16, SCR_WIDTH - 200, -45, 200, SCR_HEIGHT + 5, Linear)
            Set f = CreateFleet(100, "", falconx2, 1, ShieldUpgrade, 12, 12, SCR_WIDTH, 0, 0, SCR_HEIGHT, Linear, 1, 1, 1, 1000)
            Dim ep As New Path
            Call ep.Generate(300, 0, SCR_HEIGHT, 0, -100, Cosinus, 100, 2)
            Call ep.Generate(400, -100, 0, 1300, SCR_HEIGHT, Linear)
            Call ep.Generate(200, 1300, SCR_HEIGHT, 680, 500, Linear)
            Call ep.Generate(2000, 680, 500, 680, 200, Linear)
            f.SetExtraPath(ep).onExit = Stay
            Call AddWeapon(30, 120)
            Call CreateFleet(104, "", falcon6, 16, ShieldUpgrade, 50, 16, SCR_WIDTH - 100, -45, 300, SCR_HEIGHT + 5, Linear)
            sectorBonus = 7500
            
        Case 3
            Call CreateFleet(2, "", falcon3, 50, GeneratorUpgrade, 12, 22, SCR_WIDTH + 100, -200, -100, SCR_HEIGHT + 200, SinCos, 180, 10)
            Call AddWeapon(33, 450)
            Call CreateFleet(18, "", falcon3, 50, ShieldUpgrade, 12, 22, -100, -200, SCR_WIDTH + 100, SCR_HEIGHT + 200, SinCos, 180, 10)
            Call AddWeapon(33, 450)
            Call CreateFleet(45, "", falcon3, 30, RightWepUpgrade, 70, 20, -100, -45, SCR_WIDTH + 100, SCR_HEIGHT + 5, Cosinus, 75, 11)
            Call AddWeapon(33, 300)
            Call CreateFleet(55, "", falconx, 8, none, 12, 85, SCR_WIDTH / 2 - 10, -200, SCR_WIDTH / 2 - 10, SCR_HEIGHT + 200, SinCos, 300, 8)
            Call AddWeapon(40, 350)
            Call CreateFleet(70, "", falcon4, 30, LeftWepUpgrade, 70, 20, SCR_WIDTH + 100, -45, -100, SCR_HEIGHT + 5, Cosinus, 75, 13)
            Call AddWeapon(33, 250)
            Call CreateFleet(75, "", falconx, 8, none, 12, 85, 690, -200, SCR_WIDTH / 2 - 10, SCR_HEIGHT + 200, SinCos, 300, 8)
            Call AddWeapon(40, 350)
            Call CreateFleet(120, "", falconx, 20, GeneratorUpgrade, 12, 75, SCR_WIDTH, -200, 0, SCR_HEIGHT + 200, SinCos, 300, 8)
            Call AddWeapon(40, 350)
            Call AddAsteroids(125, 20, 50, SCR_WIDTH - 50)
            sectorBonus = 10000
            
        Case 4
            Set f = CreateFleet(2, "", falconx2, 1, none, 12, 19, SCR_WIDTH, 0, 0, SCR_HEIGHT, Linear)
            Set ep2 = New Path
            Call ep2.Generate(350, 0, SCR_HEIGHT, 0, -100, Cosinus, 500, 2)
            Call ep2.Generate(500, -100, 0, SCR_WIDTH + 50, SCR_HEIGHT + 50, Linear)
            Call ep2.Generate(350, SCR_WIDTH - 100, SCR_HEIGHT, SCR_WIDTH / 2 - 20, 500, Linear)
            Call ep2.Generate(2400, SCR_WIDTH / 2 - 20, 500, SCR_WIDTH / 2 - 20, 20, Linear)
            f.SetExtraPath(ep2).onExit = Stay
            Set ep2 = GetLastFleet().GetExtraPath().Clone
            Call CreateFleet(4, "", falcon5, 150, HealthUpgrade, 10, 70, -180, -180, SCR_WIDTH + 180, SCR_HEIGHT + 180, SinCos, 160, 10)
            Call AddWeapon(35, 500)
            Call CreateFleet(5, "", falconx, 1, ShieldUpgrade, 12, 12, SCR_WIDTH, 0, 0, SCR_HEIGHT, Linear)
            Call GetLastFleet().SetExtraPath(ep2)
            Call AddWeapon(40, 350)
            Call CreateFleet(8, "", falconx, 1, none, 12, 12, SCR_WIDTH, 0, 0, SCR_HEIGHT, Linear)
            GetLastFleet().SetExtraPath ep2
            Call AddWeapon(40, 350)
            Call CreateFleet(11, "", falconx, 1, GeneratorUpgrade, 12, 12, SCR_WIDTH, 0, 0, SCR_HEIGHT, Linear)
            GetLastFleet().SetExtraPath ep2
            Call AddWeapon(40, 350)
            Call CreateFleet(14, "", falconx, 1, none, 12, 12, SCR_WIDTH, 0, 0, SCR_HEIGHT, Linear)
            Call GetLastFleet().SetExtraPath(ep2)
            Call AddWeapon(40, 350)
            Call CreateFleet(17, "", falconx2, 1, none, 12, 12, SCR_WIDTH, 0, 0, SCR_HEIGHT, Linear)
            Call GetLastFleet().SetExtraPath(ep2)
            Call AddWeapon(40, 350)
            Call CreateFleet(20, "", falconx2, 1, BonusCredit, 12, 14, SCR_WIDTH, 0, 0, SCR_HEIGHT, Linear, 1, 1, 1, 2500)
            Call GetLastFleet().SetExtraPath(ep2)
            Call AddWeapon(40, 350)
            Call CreateFleet(22, "", falconx2, 1, none, 12, 14, SCR_WIDTH, 0, 0, SCR_HEIGHT, Linear, 1, 1, 1, 2500)
            Call GetLastFleet().SetExtraPath(ep2)
            Call AddWeapon(40, 350)
            Call CreateFleet(24, "", falconx2, 1, none, 12, 14, SCR_WIDTH, 0, 0, SCR_HEIGHT, Linear, 1, 1, 1, 2500)
            Call GetLastFleet().SetExtraPath(ep2)
            Call AddWeapon(40, 300)
            Call CreateFleet(26, "", falconx2, 1, ShieldUpgrade, 12, 14, SCR_WIDTH, 0, 0, SCR_HEIGHT, Linear, 1, 1, 1, 2500)
            Call GetLastFleet().SetExtraPath(ep2)
            Call AddWeapon(40, 300)
            Call CreateFleet(28, "", falconx2, 1, none, 12, 14, SCR_WIDTH, 0, 0, SCR_HEIGHT, Linear, 1, 1, 1, 2500)
            Call GetLastFleet().SetExtraPath(ep2)
            Call AddWeapon(40, 300)
            Call CreateFleet(29, "", falconx2, 1, none, 12, 14, SCR_WIDTH, 0, 0, SCR_HEIGHT, Linear, 1, 1, 1, 2500)
            Call GetLastFleet().SetExtraPath(ep2)
            Call AddWeapon(40, 300)
            Call CreateFleet(30, "", falconx2, 1, BonusCredit, 12, 14, SCR_WIDTH, 0, 0, SCR_HEIGHT, Linear, 1, 1, 1, 3000)
            Call GetLastFleet().SetExtraPath(ep2)
            Call AddWeapon(40, 300)
            Call CreateFleet(31, "", falconx3, 1, ShieldUpgrade, 12, 16, SCR_WIDTH, 0, 0, SCR_HEIGHT, Linear, 1, 1, 1, 3000)
            Call GetLastFleet().SetExtraPath(ep2)
            Call AddWeapon(40, 275)
            Call CreateFleet(32, "", falconx3, 1, BonusCredit, 12, 16, SCR_WIDTH, 0, 0, SCR_HEIGHT, Linear, 1, 1, 1, 3000)
            Call GetLastFleet().SetExtraPath(ep2)
            Call AddWeapon(40, 275)
            Call CreateFleet(33, "", falconx3, 1, ShieldUpgrade, 12, 16, SCR_WIDTH, 0, 0, SCR_HEIGHT, Linear, 1, 1, 1, 3000)
            Call GetLastFleet().SetExtraPath(ep2)
            Call AddWeapon(40, 250)
            Call CreateFleet(34, "", falconx3, 1, BonusCredit, 12, 16, SCR_WIDTH, 0, 0, SCR_HEIGHT, Linear, 1, 1, 1, 3000)
            Call GetLastFleet().SetExtraPath(ep2)
            Call AddWeapon(40, 250)
            sectorBonus = 15000
            
        Case 5
            Call CreateFleet(2, "", falcon6, 19, GeneratorUpgrade, 25, 12, -50, 100, SCR_WIDTH - 58, 100, Linear, 1, 1, 1, 1, FreezeFleet)
            Call AddWeapon(15, 300)
            Call CreateFleet(3, "", falcon5, 19, BonusCredit, 25, 12, SCR_WIDTH + 5, 200, 2, 200, Linear, 1, 1, 1, 20000, FreezeFleet)
            Call AddWeapon(14, 300)
            Call CreateFleet(4, "", falcon4, 19, BonusCredit, 25, 12, -50, 300, SCR_WIDTH - 58, 300, Linear, 1, 1, 1, 18000, FreezeFleet)
            Call AddWeapon(13, 300)
            Call CreateFleet(5, "", falcon3, 19, BonusCredit, 25, 12, SCR_WIDTH + 5, 400, 2, 400, Linear, 1, 1, 1, 16000, FreezeFleet)
            Call AddWeapon(12, 300)
            Call CreateFleet(6, "", falcon2, 19, BonusCredit, 25, 12, -50, 500, SCR_WIDTH - 58, 500, Linear, 1, 1, 1, 14000, FreezeFleet)
            Call AddWeapon(11, 300)
            Call CreateFleet(7, "", falcon1, 19, BonusCredit, 25, 12, SCR_WIDTH + 5, 600, 2, 600, Linear, 1, 1, 1, 12000, FreezeFleet)
            Call AddWeapon(10, 300)
            Call SetAltParams(50, 40, 0, Cosinus, CreateFleet(15, "", falconx3, 14, FrontWepUpgrade, 35, 12, -50, 10, SCR_WIDTH - 90, 10, Linear, 1, 1, 1, 1, ReplacePath))
            Call AddWeapon(50, 225)
            Call SetAltParams(30, 20, 0, Cosinus, CreateFleet(45, "", falcon6, 19, HealthUpgrade, 25, 12, -50, 100, SCR_WIDTH - 66, 100, Linear, 1, 1, 1, 1, ReplacePath))
            Call AddWeapon(20, 275)
            Call SetAltParams(30, 20, 0, Cosinus, CreateFleet(46, "", falcon5, 19, ShieldUpgrade, 25, 12, SCR_WIDTH + 5, 200, 2, 200, Linear, 1, 1, 1, 20000, ReplacePath))
            Call AddWeapon(19, 275)
            Call SetAltParams(30, 20, 0, Cosinus, CreateFleet(47, "", falcon4, 19, BonusCredit, 25, 12, -50, 300, SCR_WIDTH - 58, 300, Linear, 1, 1, 1, 18000, ReplacePath))
            Call AddWeapon(18, 275)
            Call SetAltParams(30, 20, 0, Cosinus, CreateFleet(48, "", falcon3, 19, BonusCredit, 25, 12, SCR_WIDTH + 5, 400, 2, 400, Linear, 1, 1, 1, 16000, ReplacePath))
            Call AddWeapon(17, 275)
            Call SetAltParams(30, 20, 0, Cosinus, CreateFleet(49, "", falcon2, 19, BonusCredit, 25, 12, -50, 500, SCR_WIDTH - 58, 500, Linear, 1, 1, 1, 14000, ReplacePath))
            Call AddWeapon(16, 275)
            Call SetAltParams(30, 20, 0, Cosinus, CreateFleet(50, "", falcon1, 19, BonusCredit, 25, 12, SCR_WIDTH + 5, 600, 2, 600, Linear, 1, 1, 1, 12000, ReplacePath))
            Call AddWeapon(15, 275)
            Call AddAsteroids(57, 7, 50, SCR_WIDTH - 50)
            sectorBonus = 20000
            
        Case 6
            Set f = CreateFleet(3, "", falconx3, 28, FrontWepUpgrade, 100, 35, SCR_WIDTH / 2, -55, SCR_WIDTH / 2, SCR_HEIGHT + 5, Cosinus, 12, 10, 1.0025, 10000)
            Call AddWeapon(45, 250)
            Call CreateFleet(15, "", falcon1, 16, GeneratorUpgrade, 22, 12, 200, -45, SCR_WIDTH - 200, SCR_HEIGHT + 5, Linear)
            Call AddWeapon(10, 275)
            Call CreateFleet(15, "", falcon1, 16, BonusCredit, 22, 12, SCR_WIDTH - 200, -45, 200, SCR_HEIGHT + 5, Linear)
            Call AddWeapon(10, 275)
            Call CreateFleet(30, "", falcon2, 18, ShieldUpgrade, 22, 12, 200, -45, SCR_WIDTH - 200, SCR_HEIGHT + 5, Linear)
            Call AddWeapon(10, 275)
            Call CreateFleet(30, "", falcon2, 18, HealthUpgrade, 22, 12, SCR_WIDTH - 200, -45, 200, SCR_HEIGHT + 5, Linear)
            Call AddWeapon(10, 275)
            Call CreateFleet(45, "", falcon3, 20, BonusCredit, 22, 12, 200, -45, SCR_WIDTH - 200, SCR_HEIGHT + 5, Linear, 1, 1, 1, 3000)
            Call AddWeapon(10, 275)
            Call CreateFleet(45, "", falcon3, 20, BonusCredit, 22, 12, SCR_WIDTH - 200, -45, 200, SCR_HEIGHT + 5, Linear, 1, 1, 1, 5000)
            Call AddWeapon(10, 275)
            sectorBonus = 25000
            
        Case 7
            Call SetupRandom
            
        Case Else
            Call parent.CreateMessage("No other level prepared.")
            displayComCenter = True
    End Select
    Call parent.CreateText(caption, 200, False)
    
    Exit Sub
err:
     Logt "Setup: Level " & level & ": " & Error
End Sub


Public Sub SetupRandom()
On Error GoTo err
    Static sta As String
    Dim f As Fleet
    Dim etime As Double
    Dim Delay As Long
    Dim ftime As Integer
    Dim fleetCount As Long
    Dim host As HostType
    Dim hostCount As Integer
    Dim bon As Integer
    Dim amplit As Integer
    Dim amplMod As Double
    Dim trigger As Long
    Dim durat As Double
    Dim duratTotal As Double
    Dim durat2 As Double
    Dim PathType As Integer
    Dim shift As Integer
    Dim dt As DevType
    Dim maxHostLevel As Integer
    Dim maxFireLevel As Integer
    Dim durCoef As Double
    Dim startX As Integer
    Dim endX As Integer
    Dim startY As Integer
    Dim endY As Integer
    Dim simultan As Double
    Dim damage As Long
    Dim dcf As Double
    Dim weakEnemy As Boolean
    Dim heavyEnemy As Boolean
    Dim bVal As Long
    Dim dmgGrowLevel As Integer
    Dim d As Device
    Dim mwlev As Integer
    
    etime = 3
    dmgGrowLevel = 20
    simultan = 1
    fleetCount = Round(Rnd() * 15 + 5)
    obj.CreateMessage "Random level of " & fleetCount & " fleets", FONT_UNDERLINED, &HD0E0F0, 45
    sectorBonus = CLng(fleetCount) * CLng(2500) * level
    durat = 0
    rocket.dps = rocket.CalculateDPS
    startCount = 0
    dcf = 1
    If level >= dmgGrowLevel And Not test Then
        Dim dmgGrow As Single
        dmgGrow = 0.25
        If level >= 25 Then
            dmgGrow = 0.35
            If level >= 30 Then
                dmgGrow = 0.45
                If level >= 35 Then dmgGrow = 0.6
            End If
        End If
        dcf = 1 + ((level - dmgGrowLevel + 1) * dmgGrow)
        If dcf > 1 Then obj.CreateMessage "Enemy damage +" & Round((dcf - 1) * 100) & "%", FONT_UNDERLINED, &H90A0B0, 45
    End If
    
    If rocket.lastMaxDps <> rocket.dps Then
        obj.CreateMessage "Handicap " & Round(rocket.lastMaxDps * 100 / rocket.dps - 100) & "%", FONT_UNDERLINED, &H90A0B0, 45
    End If
    
    sta = "cycle"
    For n = 1 To fleetCount
        weakEnemy = False
        maxHostLevel = Round(6 * (rocket.lastMaxDps / 500))
        If maxHostLevel > (level + 2) Then maxHostLevel = level + 1
        If maxHostLevel > 10 Then maxHostLevel = 10
        If level >= 17 And rocket.dps > 10000 Then maxHostLevel = 11
        maxFireLevel = Round(rocket.lastMaxDps / 20)
        If maxFireLevel > 385 Then maxFireLevel = 385
        host = Round(1 + Rnd() * maxHostLevel)
        'If test Then host = bouncer
        hostCount = (Rnd * 4 + 1) * 5
        If (obj.GetHostHpMax(host) / rocket.lastMaxDps) > 2 Then
            If hostCount > 10 Then hostCount = 10
            If (obj.GetHostHpMax(host) / rocket.lastMaxDps) > 3 Then
                If hostCount > 5 Then
                    hostCount = 5
                    heavyEnemy = True
                End If
            End If
        Else
            heavyEnemy = False
            If (obj.GetHostHpMax(host) / rocket.lastMaxDps) < 0.09 Then
                hostCount = hostCount * 2
                weakEnemy = True
            End If
        End If
        PathType = Round(1 + Rnd * 3)
        sta = "amplit"
        amplit = Round(Rnd * 300)
        If PathType <> 3 Then shift = 0 Else shift = amplit
        If amplit <= 3 Then amplMod = 1.0025 Else amplMod = 0.9991
        startX = Rnd * SCR_WIDTH
        endX = Rnd * SCR_WIDTH
        startY = -70 - shift
        endY = SCR_HEIGHT + shift + 5
        If Rnd < 0.35 Then
            If Rnd < 0.5 Then
                startX = -70 - shift
                endX = SCR_WIDTH + shift
            Else
                startX = SCR_WIDTH + shift
                endX = -70 - shift
            End If
            startY = Rnd * SCR_HEIGHT / 2 + 75
            endY = Rnd * SCR_HEIGHT / 2 + SCR_HEIGHT / 2 - 75
        End If
        
        durCoef = 1.6
        If PathType > 1 And amplit >= 100 Then durCoef = durCoef + amplit / 66
        If durCoef > 4.7 Then durCoef = 4.7
        sta = "durTotal"
        duratTotal = CDbl(obj.GetHostHpMax(host) / rocket.lastMaxDps) * CDbl(hostCount) * durCoef
        sta = "trigger"
        trigger = Round(duratTotal) + Round(Rnd * 25) + 5
        If weakEnemy And trigger > 15 Then trigger = Round(trigger / 3)
        sta = "durat"
        durat = duratTotal - Round(trigger * FRAME_DELAY / 1000) * hostCount
        If PathType = 1 Then durat = durat + Abs(endX - startX) / 600
        If durat < 4 Then
            durat2 = 4
            duratTotal = durat2 + Round(trigger * FRAME_DELAY / CDbl(1000)) * CDbl(hostCount)
        Else
            durat2 = durat
        End If
        bon = Round(Rnd() * 7)
        bVal = Round(Rnd() * CLng(5000) * CLng(level ^ 2))
        If weakEnemy Then
            bon = BonusCredit
            bVal = bVal / 10
        End If
        Set d = rocket.fDevice
        mwlev = 0
        While Not d Is Nothing
            If d.slot = FrontGun Then mwlev = d.level
            Set d = d.nxt
        Wend
        If heavyEnemy And bon <> BonusHealth And bon <> BonusShield And mwlev < 25 Then bon = FrontWepUpgrade
        sta = "CreateFleet"
        Set f = CreateFleet(etime, "", host, hostCount, bon, trigger, durat2 + Delay, _
            startX, startY, endX, endY, PathType, amplit, Rnd * 10 + 1, amplMod, bVal)
        sta = "rnd"
        f.IsRandom = True
        If test Then
            If weakEnemy Then
                Logt "No." & CStr(n) & " at " & CStr(Round(etime)) & "s " & CStr(obj.HostCap(host)) & " x " & hostCount & " (weak)", False
            Else
                Logt "No." & CStr(n) & " at " & CStr(Round(etime)) & "s " & CStr(obj.HostCap(host)) & " x " & hostCount, False
            End If
        End If
        'etime = etime + Round(duratTotal)
        sta = "simultanDeterm"
        If Rnd > (0.55 / simultan) Then
            etime = Round(etime) + Round(duratTotal) + Delay
            Delay = 0
            simultan = 1
        Else
            Delay = Delay + Round(duratTotal)
            simultan = simultan + 1
        End If
        damage = Round(host * 5.555) * dcf
        AddWeapon damage, Round((400 - maxFireLevel) * 2 + 2), host
    Next n
    sta = "Asteroids"
    Dim ac As Integer, wdth As Integer
    Dim et As Integer, acnt As Integer
    ac = Round(Rnd * (fleetCount / 2))
    If ac > 0 Then
        If test Then Logt "Generating " & ac & " asteroid fields:", False
        For i = 0 To ac
            wdth = Rnd * (SCR_WIDTH - 100) + 100
            et = Round(etime / ac * i + Rnd * etime / ac)
            acnt = Round(Rnd * 15 + 5)
            Call AddAsteroids(et, acnt, Rnd * (SCR_WIDTH - wdth), wdth)
            If test Then Logt " at " & et & " sec " & acnt & " pcs / " & wdth & "px", False
        Next i
    End If
    sta = "CreateText"
    parent.CreateText caption, 200, False
    
    Exit Sub
err:
    Logt "SetupRnd: " & sta & ": " & Error
End Sub


Public Function WeapCDFromDPS(ByVal dps As Single, ByVal hostCount As Integer) As Integer
    Dim maxFL As Integer
    maxFL = Round(dps / 20)
    If maxFL > 385 Then maxFL = 385
    WeapCDFromDPS = Round((400 - maxFL) * 2 + 2)
End Function


Public Function CreateDev(ByVal name As String, projImg As Image) As Device
    Dim d As New Device
    d.name = name
    d.displayName = name
    Set d.proj = projImg
    'Set d.parent = Me
    d.xShiftDir = 1
    Set CreateDev = d
End Function


Public Function SetupDevice(ByVal devName As String, Optional ByVal ratio As Single = 1, Optional ByVal hotyp As HostType = falcon1) As Device
    Dim dev As Device
    Dim dt As DevType
    Dim i As Image
    Dim ln As Integer
    
    ln = 4
    If hotyp = bouncer Then ln = 10
    Set dt = cCenter.GetDevType(devName)
    Set i = CopyImage(imgLib.GetItem(dt.imgName), -50, -50, 0, ratio, True, ln)
    Set dev = CreateDev(devName, i)
    dev.damage = dt.damage
    dev.speed = dt.speed
    dev.pwrNeed = dt.pwrNeed
    dev.pwrGen = dt.pwrGen
    dev.cooldown = dt.cooldown
    dev.xShiftMax = dt.xShiftMax
    dev.price = dt.price
    dev.upgCost = dt.upgCost
    dev.slot = s
    Set SetupDevice = dev
End Function

'End of file

