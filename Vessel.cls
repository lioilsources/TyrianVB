VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Vessel"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Class Vessel
Option Explicit

Public name As String
Public pilotName As String
Public img As Image
Public imgOffX As Long
Public imgOffY As Long
Public x As Single, x2 As Single, xm As Single
Public y As Single, y2 As Single, ym As Single
Public hp As Long
Public hpMax As Long
Public shield As Single
Public shieldRegen As Single
Public shieldMax As Single
Public genPower As Single
Public genMax As Single
Public genValue As Single
Public speed As Single
Public guidedWeapon As Boolean
Public moving As Boolean
Public moveBlock As Integer '0 = free, 1 = X axis, 2 = Y axis
Public credit As Long
Public score As Long
Public dps As Single
Public lastMaxDps As Single
Public pps As Single
Public dmgTaken As Byte
Public lvlNum As Long
Public fire As Boolean
Public WepLevScores As Variant
Public NextWeaponLevel As Integer      ' index to WepLevScores

Public fDevice As Device
Public closestEnemy As Variant

Private dx As Single
Private dy As Single
Private dist As Single
Private minDist As Single
Private scrW As Long
Private scrH As Long
Private isStructure As Boolean

' step temp variables
Private d As Device
Private p As Projectile
Private s As Structure
Private f As Fleet
Private h As Hostile
Private delp As Projectile
Private setNext As Boolean
Private btmp As Boolean
Private btmp2 As Boolean


Public Enum Slots
    FrontGun = 1
    Generator = 2
    LeftGun = 3
    NotAvailable = 4
    RightGun = 5
    Satellite = 6
    ShieldCapacitor = 7
End Enum


Public Sub Init(ByVal sw As Long, ByVal sh As Long, ByVal iname As String, obj As Objects)
    Set img = imgLib.GetItem(iname)
    scrW = sw
    scrH = sh
    Call ResetVessel
End Sub


Public Sub ResetVessel()
    Set fDevice = Nothing
    name = "Puddle Jumper"
    credit = 0
    score = 0
    score = 0
    speed = 0.2
    x = img.x
    y = img.y
    x2 = x + img.width
    y2 = y + img.height
    imgOffX = img.width / 2
    imgOffY = img.height / 2
    xm = x + imgOffX
    ym = y = imgOffY
    genMax = 100
    genValue = 100
    genPower = 4
    hpMax = 125
    hp = hpMax
    shield = 100
    shieldRegen = 0.1
    shieldMax = 100
    dps = 0
    lastMaxDps = 0
    pps = 0
    lvlNum = 0
    fire = False
    moveBlock = 0
    WepLevScores = Array(0, 400000, 4000000, 14000000)
    NextWeaponLevel = 1
    Call SetupDevice("Falcon Basic", Slots.Generator)
    Call CreateBubbleGun
    'Call CreateLaser
End Sub


Public Sub AddScore(ByVal s As Long)
    If (CDbl(score) + CDbl(s)) > 2147483647 Then
        obj.CreateMessage "Max score!", FONT_BOLD
        score = 2147483647
        Exit Sub
    End If
    score = score + s
    If NextWeaponLevel <= UBound(WepLevScores) Then
        If score > WepLevScores(NextWeaponLevel) Then
            NextWeaponLevel = NextWeaponLevel + 1
            obj.CreateText "Weapon level " & ROMNUM(NextWeaponLevel) & " unlocked", 200, False
        End If
    End If
End Sub


Public Sub AddCredit(ByVal c As Long)
    If (CDbl(credit) + CDbl(c)) > 2147483647 Then
        obj.CreateMessage "Max money!", FONT_BOLD
        credit = 2147483647
        Exit Sub
    End If
    credit = credit + c
End Sub


Public Sub AdjustPosition(ByVal mx As Long, ByVal my As Long, Optional ByVal immediate As Boolean = True)
    Static devi As Device
    
    If hp <= 0 Then Exit Sub
    If immediate Then
        If moveBlock <> 1 Then x = mx
        If moveBlock <> 2 Then y = my
    Else
        dx = mx - x
        dy = my - y
        dist = Sqr(dx * dx + dy * dy)
        moving = False
        If Round(x) <> mx And moveBlock <> 1 Then
            x = x + (dx / dist) * speed
            moving = True
        End If
        If Round(y) <> my And moveBlock <> 2 Then
            y = y + (dy / dist) * speed
            moving = True
        End If
    End If
    If Round(x) > (scrW - img.width) Then
        x = scrW - img.width
    Else
        If x < 0 Then x = 0
    End If
    If Round(y) > (scrH - img.height) Then
        y = scrH - img.height
    Else
        If y < 0 Then y = 0
    End If
    x2 = x + img.width
    y2 = y + img.height
    xm = x + imgOffX
    ym = y + imgOffY
    rocket.img.x = Round(x)
    rocket.img.y = Round(y)
    Set devi = fDevice
    While Not devi Is Nothing
        If devi.beamActive > 0 Then
            If closestEnemy Is Nothing Then
                Select Case devi.slot
                    Case Slots.FrontGun
                        devi.sx = xm
                        devi.sy = y - 5
                    Case Slots.LeftGun
                        devi.sx = img.x
                        devi.sy = y + 9
                    Case Slots.RightGun
                        devi.sx = x2
                        devi.sy = y + 9
                End Select
            Else
                Select Case devi.slot
                    Case Slots.FrontGun
                        devi.sx = xm
                        devi.sy = y - 5
                    Case Slots.LeftGun
                        devi.sx = img.x
                        devi.sy = y + 9
                    Case Slots.RightGun
                        devi.sx = x2
                        devi.sy = y + 9
                End Select
            End If
        End If
        Set devi = devi.nxt
    Wend
End Sub


Public Function GetDevices() As Device
    Set GetDevices = fDevice
End Function


Public Function GetLastDevice() As Device
    Dim d As Device
    If fDevice Is Nothing Then
        Set d = Nothing
    Else
        Set d = fDevice
        While Not d.nxt Is Nothing
            Set d = d.nxt
        Wend
    End If
    Set GetLastDevice = d
End Function


Public Function CreateDevice(ByVal name As String, ByVal s As Slots, projImg As Image, Optional minScale As Single = 1, _
        Optional maxScale As Single = 1) As Device
    Dim d As New Device
    d.name = name
    d.displayName = name
    d.minProjScale = minScale
    d.maxProjScale = maxScale
    Set d.proj = projImg
    Set d.parent = Me
    d.slot = s
    d.xShiftDir = 1
    Call d.SetOffsets(imgOffX - projImg.width / 2, -projImg.height)
    If Not fDevice Is Nothing Then
        Dim ld As Device
        Set ld = GetLastDevice
        Set ld.nxt = d
        Set d.prv = ld
    Else
        Set fDevice = d
    End If
    Set CreateDevice = d
End Function


Public Function GetSlotName(ByVal s As Slots) As String
    Set d = fDevice
    While Not d Is Nothing
        If d.slot = s Then
            GetSlotName = d.displayName
            Exit Function
        End If
        Set d = d.nxt
    Wend
    GetSlotName = ""
End Function


Public Function GetSlotDevice(ByVal s As Slots) As Device
    Set d = fDevice
    While Not d Is Nothing
        If d.slot = s Then
            Set GetSlotDevice = d
            Exit Function
        End If
        Set d = d.nxt
    Wend
    Set GetSlotDevice = Nothing
End Function


Public Sub ResetDevices()
    Dim d As Device
    Set d = fDevice
    While Not d Is Nothing
        If d.pwrGen = 0 Then
            d.ResetLists
        End If
        Set d = d.nxt
    Wend
End Sub


Public Function CalculateDPS() As Single
    Dim dps As Single
    Dim d As Device
    
    dps = 0
    Set d = fDevice
    While Not d Is Nothing
        If d.pwrGen = 0 Then
            dps = dps + (d.damage * d.seqs) * (1000 / (d.cooldown * FRAME_DELAY))
        End If
        Set d = d.nxt
    Wend
    If dps > lastMaxDps Then lastMaxDps = dps
    CalculateDPS = dps
End Function


Public Function CalculatePPS() As Single
    Dim pps As Single
    pps = 0
    Dim d As Device
    Set d = fDevice
    While Not d Is Nothing
        If d.pwrGen = 0 Then
            pps = pps + d.pwrNeed * (1000 / (d.cooldown * FRAME_DELAY))
        End If
        Set d = d.nxt
    Wend
    CalculatePPS = pps
End Function


Public Function GeneratorLoad() As Single
    Dim pwr As Single
    Dim p As Single
    Dim d As Device
    Set d = fDevice
    While Not d Is Nothing
        If d.pwrGen > 0 Then
            p = p + d.pwrGen * (1000 / FRAME_DELAY)
        End If
        Set d = d.nxt
    Wend
    GeneratorLoad = CalculatePPS / p * 100
End Function


Public Function GenInfo() As String
    Dim d As Device
    Dim gl As Single
    Dim str As String
    gl = GeneratorLoad
    str = "Cap " & Int(genMax) & " | Load " & Round(gl) & "%"
    Set d = fDevice
    While Not d Is Nothing
        If d.pwrNeed > Me.genMax Then
            str = str + " | " & d.name & " off"
            Set d = Nothing
        Else
            Set d = d.nxt
        End If
    Wend
    If gl > 100 Then str = str & " | low"
    GenInfo = str
End Function


Public Sub TestDistance(h As Variant, grat As Single, ByVal isStruct As Boolean)
    If isStruct Then
        If h.typ = Asteroid Then Exit Sub
    End If
    If h.xm < SCR_WIDTH And h.xm > 0 And h.img.y < y And h.y2 > 0 Then
        dx = Abs(h.xm - xm)
        dy = Abs(h.ym - ym)
        dist = Sqr(dx * dx + dy * dy)
        If dy <> 0 Then
            If dist < minDist And (grat >= (dx / dy)) Then
                minDist = dist
                Set closestEnemy = h
                isStructure = isStruct
                Set d = fDevice
                While Not d Is Nothing
                    If d.beamActive > 0 Then
                        d.dx = closestEnemy.xm
                        d.dy = closestEnemy.ym
                    End If
                    Set d = d.nxt
                Wend
            End If
        End If
    End If
End Sub

Public Sub step()
    Dim maxg As Integer
    Dim maxgspd As Integer
    Dim grat As Single
    
    If genValue < genMax Then
        genValue = genValue + genPower
        updateOSD = True
    End If
    If genValue > genMax Then genValue = genMax
    ' Find device with max guidance
    maxg = 0
    
    Set d = fDevice
    While Not d Is Nothing
        If d.guide > maxg Then
            maxg = d.guide
            maxgspd = d.speed
        End If
        If d.beam > 0 Then
            d.dx = d.sx
            d.dy = 0
        End If
        Set d = d.nxt
    Wend
    If maxg > 0 Then
        grat = maxg / maxgspd
    End If
    
    ' Find closest & reachable enemy
    If guidedWeapon Then
        If Not currentSector Is Nothing Then
            minDist = 10000
            Set closestEnemy = Nothing
            Set f = currentSector.fFleet
            While Not f Is Nothing
                If f.active Then
                    Set h = f.fHost
                    While Not h Is Nothing
                        If Not h.img Is Nothing Then
                            If h.img.drawInLoop Then
                                TestDistance h, grat, False
                            End If
                        End If
                        Set h = h.nxt
                    Wend
                End If
                Set f = f.nxt
            Wend
            Set s = currentSector.fStruct
            While Not s Is Nothing
                If s.img.drawInLoop Then TestDistance s, grat, True
                Set s = s.nxt
            Wend
        End If
    End If
    
    ' Process device projectiles
    Set d = fDevice
    While Not d Is Nothing
        If d.pwrGen = 0 Then
            If d.cd > 0 Then d.cd = d.cd - 1
            If d.beam = 0 Then
                Set p = d.fProjectile
                While Not p Is Nothing
                    setNext = False
                    p.img.y = p.img.y - p.speed
                    p.y2 = p.img.y + p.img.height
                    If d.guide > 0 Then
                        ' adjust projectile x-position
                        If Not closestEnemy Is Nothing Then
                            dx = (p.img.x + p.img.width / 2) - (closestEnemy.xm)
                            If Abs(dx) > d.guide Then dx = Sgn(dx) * d.guide
                            p.img.x = p.img.x - dx
                            p.x2 = p.img.x + p.img.width
                        End If
                    End If
                    If p.y2 < 0 Then
                        Set delp = p
                        Set p = p.nxt
                        delp.Delete
                        setNext = True
                    Else
                        If ProcessEnemies(d, p, p.img.x, p.img.y, p.x2, p.y2) Then
                            If Not p Is Nothing Then
                                Set delp = p
                                Set p = p.nxt
                                delp.Delete
                                setNext = True
                            End If
                        End If
                    End If
                    If Not setNext Then Set p = p.nxt
                Wend
                Set p = Nothing
            Else
                If d.beamActive > 0 Then
                    If Not closestEnemy Is Nothing Then
                        closestEnemy.hp = closestEnemy.hp - d.damage
                        If closestEnemy.hit = 0 Then closestEnemy.hit = 2
                        If isStructure Then
                            If closestEnemy.typ = Basic Then
                                AddScore d.damage
                                AddCredit d.damage
                            End If
                        End If
                    End If
                End If
            End If
        End If
        Set d = d.nxt
    Wend
    
    Set d = Nothing
    If shield < shieldMax Then
        If genValue > 0 Then
            shield = shield + shieldRegen
            If shield > shieldMax Then shield = shieldMax
        End If
    End If
    
    If hp <= 0 Then fire = False
End Sub


Public Function ProcessEnemies(d As Device, p As Projectile, ByVal px1 As Single, ByVal py1 As Single, _
            ByVal px2 As Single, ByVal py2 As Single) As Boolean
    Dim dmg As Long
    Dim delproj As Boolean
    Dim breakLoop As Boolean
    
    delproj = False
    breakLoop = False
    If p Is Nothing Then
        dmg = d.damage
    Else
        dmg = p.damage
    End If
    If Not currentSector Is Nothing Then
        Set f = currentSector.fFleet
        While Not f Is Nothing
            If f.active Then
                btmp = ((py1 >= f.miny) And (py1 <= f.maxy) And (px1 >= f.minx) And (px1 <= f.maxx))
                btmp2 = False
                If Not btmp Then btmp2 = ((py2 >= f.miny) And (py2 <= f.maxy) And (px2 >= f.minx) And (px2 <= f.maxx))
                If btmp Or btmp2 Then
                    Set h = f.fHost
                    While Not h Is Nothing
                        If h.img.drawInLoop Then
                            btmp = (py1 >= h.img.y And py1 <= h.y2)
                            If Not btmp Then btmp2 = (py2 >= h.img.y And py2 <= h.y2) Else btmp2 = False
                            If btmp Or btmp2 Then
                                btmp = (px1 >= h.img.x And px1 <= h.x2)
                                If Not btmp Then btmp2 = (px2 >= h.img.x And px2 <= h.x2) Else btmp2 = False
                                If btmp Or btmp2 Then
                                    h.hp = h.hp - dmg
                                    If h.hit = 0 Then h.hit = 2
                                    delproj = True
                                    breakLoop = True
                                End If
                            End If
                        End If
                        If breakLoop Then Set h = Nothing Else Set h = h.nxt
                    Wend
                End If
            End If
            If breakLoop Then Set f = Nothing Else Set f = f.nxt
        Wend
        
        Set s = currentSector.fStruct
        While Not breakLoop And Not s Is Nothing
            If s.img.drawInLoop And s.y2 > 0 Then
                btmp = (py1 >= s.img.y And py1 <= s.y2)
                If Not btmp Then btmp2 = (py2 >= s.img.y And py2 <= s.y2) Else btmp2 = False
                If btmp Or btmp2 Then
                    btmp = (px1 >= s.img.x And px1 <= s.x2)
                    If Not btmp Then btmp2 = (px2 >= s.img.x And px2 <= s.x2) Else btmp2 = False
                    If btmp Or btmp2 Then
                        If s.typ <> Asteroid Then s.hp = s.hp - dmg
                        If s.typ = Basic Then
                            AddScore dmg
                            AddCredit dmg
                        End If
                        delproj = True
                        breakLoop = True
                    End If
                End If
            End If
            If breakLoop Then Set s = Nothing Else Set s = s.nxt
        Wend
    End If
    ProcessEnemies = delproj
End Function


Public Function SetupDevice(ByVal devName As String, ByVal s As Slots, Optional ByVal ratio As Single = 1) As Device
    Dim r As Single
    Dim dev As Device, d As Device
    Dim dt As DevType
    Dim sm As Integer
    Set dt = cCenter.GetDevType(devName)
    r = ratio
    If dt.scaleProjectile Then
        r = dt.minProjScale
        If dt.minProjScale = 0 Then dt.minProjScale = 0.99
        If dt.maxProjScale = 0 Then dt.maxProjScale = 0.99
    End If
    If devName = "Bubble Gun" Or devName = "Small bubble" Then sm = STRETCH_HALFTONE
    Set dev = CreateDevice(devName, s, _
        CopyImage(imgLib.GetItem(dt.imgName), -50, -50, 0, r, False, 0), dt.minProjScale, dt.maxProjScale)
        ', STRETCH_HALFTONE
    dev.scaleProjectile = dt.scaleProjectile
    dev.imgName = dt.imgName
    dev.damage = dt.damage
    dev.speed = dt.speed
    dev.guide = dt.guide
    dev.pwrNeed = dt.pwrNeed
    dev.pwrGen = dt.pwrGen
    dev.cooldown = dt.cooldown
    dev.beam = dt.beam
    dev.seqs = dt.seqs
    If dev.seqs <= 0 Then dev.seqs = 1
    dev.xShiftMax = dt.xShiftMax
    dev.price = dt.price
    dev.upgCost = dt.upgCost
    dev.slot = s
    guidedWeapon = False
    Set d = fDevice
    While Not d Is Nothing
        If d.guide > 0 Then guidedWeapon = True
        Set d = d.nxt
    Wend
    Set SetupDevice = dev
End Function


Public Function CreateBubbleGun() As Device
    Set CreateBubbleGun = SetupDevice("Bubble Gun", FrontGun, 0.7)
End Function


Public Function CreateSmallBubble(ByVal s As Slots) As Device
    Set CreateSmallBubble = SetupDevice("Small Bubble", s, 0.3)
End Function


Public Function CreateVulcanCannon() As Device
    Set CreateVulcanCannon = SetupDevice("Vulcan cannon", FrontGun)
End Function


Public Function CreateSmallVulcan(ByVal s As Slots) As Device
    Set CreateSmallVulcan = SetupDevice("Small Vulcan", s, 0.7)
End Function


Public Function CreateStarGun(ByVal s As Slots) As Device
    Set CreateStarGun = SetupDevice("Star Gun", s, 0.5)
End Function


Public Function CreateBlaster(ByVal s As Slots) As Device
    Set CreateBlaster = SetupDevice("Blaster", s, 0.3)
End Function


Public Function CreateLaser() As Device
    Set CreateLaser = SetupDevice("Laser", FrontGun, 0)
End Function


Public Sub Sell(ByVal s As Slots)
    Dim d As Device
    Set d = fDevice
    While Not d Is Nothing
        If d.slot = s Then
            AddCredit d.price
            Call DeleteDevice(d)
        End If
        Set d = d.nxt
    Wend
End Sub


Public Sub DeleteDevice(d As Device)
    If d.prv Is Nothing Then
        Set fDevice = d.nxt
    Else
        Set d.prv.nxt = d.nxt
    End If
    If Not d.nxt Is Nothing Then Set d.nxt.prv = d.prv
End Sub


'End of file


