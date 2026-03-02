VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Objects"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Class Objects
Private Const ICON_WIDTH As Long = 35
Private Const ICON_HEIGHT As Long = 35
Private Const MAX_MSG_COUNT As Integer = 12

Public font As LongPtr
Public hwnd As LongPtr

Public fButton As Button
Public fColl As Collectable
Public fMessage As Message
Public fSector As Sector
Public fText As FloatText
Public fExp As Explosion
Public lExp As Explosion
Public lastSectorNumber As Long

Public shield As LongPtr
Public ShieldMask As LongPtr
Public Health As LongPtr
Public HealthMask As LongPtr
Public Generator As LongPtr
Public GeneratorMask As LongPtr
Public Weapon As LongPtr
Public WeaponMask As LongPtr
Public Money As LongPtr
Public MoneyMask As LongPtr

Public gpen As LongPtr
Public gpen2 As LongPtr
Public gpen3 As LongPtr
Public bBrush As LongPtr
Public gBrush As LongPtr
Public oldPen As LongPtr
Public oldPen2 As LongPtr
Public whitePen As LongPtr
Public yellowPen As LongPtr
Public grayPen As LongPtr
Public greenPen As LongPtr
Public bluePen As LongPtr
Public redPen As LongPtr
Public blueBrush As LongPtr
Public oldBrush As LongPtr
Public oldBrush2 As LongPtr
Public whiteBrush As LongPtr
Public white1Brush As LongPtr
Public blackBrush As LongPtr
Public redBrush As LongPtr
Public greenBrush As LongPtr
Public iFont As LongPtr
Public mFont As LongPtr
Public mFontU As LongPtr
Public mFontI As LongPtr
Public mFontB As LongPtr
Public mFontBU As LongPtr
Public mFontBI As LongPtr
Public mFontIU As LongPtr
Public mFontBIU As LongPtr
Public ftFont As LongPtr
Public osdFont As LongPtr
Public osdFontSmall As LongPtr
Public osdFont2 As LongPtr
Public osdBigFont As LongPtr
Public smallFont As LongPtr
Public ccBigFont As LongPtr
Public tableFont As LongPtr
Public tableFontNum As LongPtr
Public tableFontBig As LongPtr
Public progressBarGradL As LongPtr
Public progressBarGradH As LongPtr
Public progressBarGradS As LongPtr
Public progressBarGradG As LongPtr

Private ci(1 To 5) As Image

Private created() As LongPtr
Private expOffsets(1 To EXPLOSION_STEPS) As Integer
Private initialized As Boolean
Private ast(0 To 3) As Image
' factories
Private Coll As Collectable


Public Enum HostType
    falcon1 = 1
    falcon2 = 2
    falcon3 = 3
    falcon4 = 4
    falcon5 = 5
    falcon6 = 6
    falconx = 7
    falconx2 = 8
    falconx3 = 9
    falconxb = 10
    falconxt = 11
    bouncer = 12
End Enum


Public Static Function GetHostHpMax(eType As HostType) As Long
    Select Case eType
        Case falcon1
            GetHostHpMax = 100
        Case falcon2
            GetHostHpMax = 120
        Case falcon3
            GetHostHpMax = 140
        Case falcon4
            GetHostHpMax = 160
        Case falcon5
            GetHostHpMax = 180
        Case falcon6
            GetHostHpMax = 200
        Case falconx
            GetHostHpMax = 1000
        Case falconx2
            GetHostHpMax = 2000
        Case falconx3
            GetHostHpMax = 3000
        Case falconxb
            GetHostHpMax = 5000
        Case falconxt
            GetHostHpMax = 10000
        Case bouncer
            GetHostHpMax = 100000
        Case Else
            GetHostHpMax = 1
            Logt "GetHostHpMax: Unknown HostType " & eType
    End Select
End Function


Public Function HostCap(ByVal ht As HostType) As String
    Select Case ht
        Case falcon1
            HostCap = "Falcon I"
        Case falcon2
            HostCap = "Falcon II"
        Case falcon3
            HostCap = "Falcon III"
        Case falcon4
            HostCap = "Falcon IV"
        Case falcon5
            HostCap = "Falcon V"
        Case falcon6
            HostCap = "Falcon VI"
        Case falconx
            HostCap = "Falcon X"
        Case falconx2
            HostCap = "Falcon X-2"
        Case falconx3
            HostCap = "Falcon X-3"
        Case falconxb
            HostCap = "Falcon X-B"
        Case falconxt
            HostCap = "Falcon X-T"
        Case bouncer
            HostCap = "Bouncer"
        Case Else
            HostCap = "Unknown"
    End Select
End Function


Public Sub SetType(h As Hostile, ByVal eType As HostType)
    Static tmpImg As Image
    
    h.caption = HostCap(eType)
    h.hpMax = GetHostHpMax(eType)
    h.hp = h.hpMax
    Select Case eType
        Case falcon1
            Set tmpImg = imgLib.GetItem("falcon1")
            Set h.img = CloneImage(tmpImg)
            h.collisionDmg = 1
        Case falcon2
            Set tmpImg = imgLib.GetItem("falcon2")
            Set h.img = CloneImage(tmpImg)
            h.collisionDmg = 1
        Case falcon3
            Set tmpImg = imgLib.GetItem("falcon3")
            Set h.img = CloneImage(tmpImg)
            h.collisionDmg = 1
        Case falcon4
            Set tmpImg = imgLib.GetItem("falcon4")
            Set h.img = CloneImage(tmpImg)
            h.collisionDmg = 1
        Case falcon5
            Set tmpImg = imgLib.GetItem("falcon5")
            Set h.img = CloneImage(tmpImg)
            h.collisionDmg = 2
        Case falcon6
            Set tmpImg = imgLib.GetItem("falcon6")
            Set h.img = CloneImage(tmpImg)
            h.collisionDmg = 2
        Case falconx
            Set tmpImg = imgLib.GetItem("falconx")
            Set h.img = CloneImage(tmpImg)
            h.collisionDmg = 4
        Case falconx2
            Set tmpImg = imgLib.GetItem("falconx2")
            Set h.img = CloneImage(tmpImg)
            h.collisionDmg = 6
        Case falconx3
            Set tmpImg = imgLib.GetItem("falconx3")
            Set h.img = CloneImage(tmpImg)
            h.collisionDmg = 8
        Case falconxb
            Set tmpImg = imgLib.GetItem("falconxb")
            Set h.img = CloneImage(tmpImg)
            h.collisionDmg = 10
        Case falconxt
            Set tmpImg = imgLib.GetItem("falconxt")
            Set h.img = CloneImage(tmpImg)
            h.collisionDmg = 12
        Case bouncer
            Set tmpImg = imgLib.GetItem("bouncer")
            Set h.img = CloneImage(tmpImg)
            h.collisionDmg = 20
        Case Else
            Logt "SetType: Unknown HostType: " & eType
    End Select
End Sub


Public Sub PreInit()
    Dim n As Integer
    ReDim Preserve created(0) As LongPtr
End Sub

Public Sub Init(ByVal wnd As LongPtr)
    hwnd = wnd
    font = f
    If Not initialized Then
        Set Coll = New Collectable
        Set Coll.parent = Me
        oldPen = RegObject(CreatePen(PS_SOLID, 4, &HA0F0A0))
        oldPen2 = RegObject(CreatePen(PS_SOLID, 4, &H80D080))
        whitePen = RegObject(CreatePen(PS_SOLID, 1, &HFFFFFF))
        yellowPen = RegObject(CreatePen(PS_SOLID, 1, &HA0F0F0))
        grayPen = RegObject(CreatePen(PS_SOLID, 1, &H808080))
        greenPen = RegObject(CreatePen(PS_SOLID, 1, &H105000))
        bluePen = RegObject(CreatePen(PS_SOLID, 1, &HFF0000))
        redPen = RegObject(CreatePen(PS_SOLID, 2, &HFF&))
        oldBrush = RegObject(CreateSolidBrush(&HFFFFFF))
        oldBrush2 = RegObject(CreateSolidBrush(&H505010))
        whiteBrush = RegObject(CreateSolidBrush(&HFFFFFF))
        white1Brush = RegObject(CreateSolidBrush(&HF0F0F0))
        blackBrush = RegObject(CreateSolidBrush(&H0&))
        redBrush = RegObject(CreateSolidBrush(&HFF&))
        greenBrush = RegObject(CreateSolidBrush(&H60FF40))
        blueBrush = RegObject(CreateSolidBrush(&HFFD0C0))
        osdFont = RegObject(MakeFont("Castellar", 19, 9))
        osdFontSmall = RegObject(MakeFont("Castellar", 15, 8))
        osdFont2 = RegObject(MakeFont("Castellar", 25, 15))
        osdBigFont = RegObject(MakeFont("Castellar", 22, 12))
        ccBigFont = RegObject(MakeFont("Castellar", 50, 40, FONT_BOLD))
        smallFont = RegObject(MakeFont("Onyx", 15, 6))
        iFont = RegObject(MakeFont("Engravers MT", 32, 16))
        tableFont = RegObject(MakeFont("Castellar", 22, 12))
        tableFontNum = RegObject(MakeFont("Batang", 18, 9, FONT_BOLD))
        tableFontBig = RegObject(MakeFont("Castellar", 28, 18, FONT_UNDERLINED))
        mFont = RegObject(MakeFont("Gulim", 12, 7))
        mFontU = RegObject(MakeFont("Gulim", 12, 7, FONT_UNDERLINED))
        mFontI = RegObject(MakeFont("Gulim", 12, 7, FONT_ITALIC))
        mFontB = RegObject(MakeFont("Gulim", 12, 7, FONT_BOLD))
        mFontBU = RegObject(MakeFont("Gulim", 12, 7, FONT_BOLD Or FONT_UNDERLINED))
        mFontBI = RegObject(MakeFont("Gulim", 12, 7, FONT_BOLD Or FONT_ITALIC))
        mFontIU = RegObject(MakeFont("Gulim", 12, 7, FONT_ITALIC Or FONT_UNDERLINED))
        mFontBIU = RegObject(MakeFont("Gulim", 12, 7, FONT_BOLD Or FONT_ITALIC Or FONT_UNDERLINED))
        ftFont = RegObject(MakeFont("Castellar", 40, 40))
    
        s = GdipCreatePen1(&HFF103030, 2, GpUnit.UnitPixel, gpen)
        s = GdipCreatePen1(&HFF103030, 2, GpUnit.UnitPixel, gpen2)
        s = GdipCreatePen1(&HFF384450, 1, GpUnit.UnitPixel, gpen3)
        s = GdipCreateSolidFill(&H608080FF, bBrush)
        s = GdipCreateSolidFill(&HFFFFFFFF, gBrush)
        progressBarGradL = CreatePBarGrad(15, 50, OSD_WIDTH - 30, 12, &HFFFF0000, &HFF00FF00)
        progressBarGradH = CreatePBarGrad(165, 80, 100, 15, &HFF00F000, &HFF203000)
        progressBarGradS = CreatePBarGrad(165, 100, 100, 15, &HFFC0C0FF, &HFF0000B0)
        progressBarGradG = CreatePBarGrad(165, 120, 100, 11, &HFFF0C040, &HFFD00000)
        
        shield = Coll.CreateLetterIcon("S", 10, 2, &HFF7070FF, &HFF000040, &HFFA0F0)
        ShieldMask = CreateMask(shield, ICON_WIDTH, ICON_HEIGHT)
        Health = Coll.CreateLetterIcon("H", 8, 1, &HFF70A070, &HFF002A00, &H60C060)
        HealthMask = CreateMask(Health, ICON_WIDTH, ICON_HEIGHT)
        Generator = Coll.CreateLetterIcon("G", 7, 1, &HFFFF9000, &HFF800000, &H80A0FF)
        GeneratorMask = CreateMask(Generator, ICON_WIDTH, ICON_HEIGHT)
        Weapon = Coll.CreateLetterIcon("W", 6, 2, &HFFA0A040, &HFF302040, &HFF&)
        WeaponMask = CreateMask(Weapon, ICON_WIDTH, ICON_HEIGHT)
        Money = Coll.CreateLetterIcon("$", 11, 1, &HFFD0D000, &HFF202000, &HE0E01F)
        MoneyMask = CreateMask(Money, ICON_WIDTH, ICON_HEIGHT)
        
        Set ci(1) = Coll.CreateGenerator
        Set ci(2) = Coll.CreateHealth
        Set ci(3) = Coll.CreateShield
        Set ci(4) = Coll.CreateMoney
        Set ci(5) = Coll.CreateWeapon
        
        Call InitSectors
        initialized = True
    End If
End Sub


Public Function geti(ByVal i As Integer) As Image
    Set geti = ci(i)
End Function

Public Function GetAsteroid() As Image
    If ast(0) Is Nothing Then
        Set ast(0) = imgLib.GetItem("aster0")
        Set ast(1) = imgLib.GetItem("aster1")
        Set ast(2) = imgLib.GetItem("aster2")
        Set ast(3) = imgLib.GetItem("aster3")
    End If
    Set GetAsteroid = ast(Round(Rnd * 3))
End Function


Public Sub InitSectors()
    Set fSector = Nothing
    lastSectorNumber = 0
    If Not test Then
        Call CreateSector("System perimeter")
        Call CreateSector("Inner zone")
        Call CreateSector("Planet perimeter")
        Call CreateSector("Planet patrol")
        Call CreateSector("Planet orbit")
        Call CreateSector("Industry zone")
        Call CreateSector("Industry headquarters")
    Else
        lastSectorNumber = 22
    End If
End Sub

Public Sub InitExpOffsets()
    Dim n As Integer, m As Integer
    For m = 1 To EXPLOSION_STEPS
        expOffsets(m) = Round((explosions(1, EXPLOSION_STEPS).width - explosions(1, m).width) / 2)
    Next m
End Sub


Public Function RegObject(ByVal hObject As LongPtr) As LongPtr
    Dim ub As Long
    On Error Resume Next
    ub = UBound(created)
    If Err.Number <> 0 Then
        Err.Clear
        ReDim created(0 To 1) As LongPtr
        created(1) = hObject
        RegObject = hObject
        On Error GoTo 0
        Exit Function
    End If
    On Error GoTo 0
    ReDim Preserve created(0 To ub + 1) As LongPtr
    created(ub + 1) = hObject
    RegObject = hObject
End Function


Public Sub Destroy()
    Dim ub As Long
    On Error Resume Next
    ub = UBound(created)
    If Err.Number = 0 Then
        If ub > 0 Then
            For i = 1 To ub
                Call DeleteObject(created(i))
            Next i
        End If
    Else
        Err.Clear
    End If
    On Error GoTo 0
    Call DeleteObject(shield)
    Call DeleteObject(ShieldMask)
    Call DeleteObject(Health)
    Call DeleteObject(HealthMask)
    Call DeleteObject(Generator)
    Call DeleteObject(GeneratorMask)
    Call DeleteObject(Weapon)
    Call DeleteObject(WeaponMask)
    Call DeleteObject(Money)
    Call DeleteObject(MoneyMask)
    Set fButton = Nothing
    Set fColl = Nothing
    Set fHost = Nothing
    Set fMessage = Nothing
    Set fStruct = Nothing
    Set fExp = Nothing
    'Set fSector = Nothing
    initialized = False
End Sub


Public Function GetButtons() As Button
    Set GetButtons = fButton
End Function


Public Function GetLastButton() As Button
    Dim b As Button
    If fButton Is Nothing Then
        Set b = Nothing
    Else
        Set b = fButton
        While Not b.nxt Is Nothing
            Set b = b.nxt
        Wend
    End If
    Set GetLastButton = b
End Function


Public Sub AddButton(b As Button)
    If Not fButton Is Nothing Then
        Dim lb As Button
        Set lb = GetLastButton
        Set lb.nxt = b
    Else
        Set fButton = b
    End If
End Sub


Public Function GetColls() As Collectable
    Set GetColls = fColl
End Function


Public Function GetLastColl() As Collectable
    Dim c As Collectable
    If fColl Is Nothing Then
        Set c = Nothing
    Else
        Set c = fColl
        While Not c.nxt Is Nothing
            Set c = c.nxt
        Wend
    End If
    Set GetLastColl = c
End Function


Public Function GetMessages() As Message
    Set GetMessages = fMessage
End Function


Public Function GetLastMessage(c As Integer) As Message
    Dim m As Message
    c = 0
    If fMessage Is Nothing Then
        Set m = Nothing
    Else
        Set m = fMessage
        While Not m.nxt Is Nothing
            c = c + 1
            Set m = m.nxt
        Wend
    End If
    Set GetLastMessage = m
End Function


Public Function GetSectors() As Sector
    Set GetSectors = fSector
End Function


Public Function GetLastSector() As Sector
    Dim s As Sector
    If fSector Is Nothing Then
        Set s = Nothing
    Else
        Set s = fSector
        While Not s.nxt Is Nothing
            Set s = s.nxt
        Wend
    End If
    Set GetLastSector = s
End Function


Public Function GetLastIncompleteSector() As Sector
    Dim s As Sector
    Dim found As Boolean
    found = False
    If fSector Is Nothing Then
        Set s = Nothing
    Else
        Set s = fSector
        While Not s Is Nothing And Not found
            found = Not s.complete
            If s.complete Then Set s = s.nxt
        Wend
    End If
    Set GetLastIncompleteSector = s
End Function


Public Function GetTexts() As FloatText
    Set GetTexts = fText
End Function


Public Function GetLastText() As FloatText
    Dim t As FloatText
    If fText Is Nothing Then
        Set t = Nothing
    Else
        Set t = fText
        While Not t.nxt Is Nothing
            Set t = t.nxt
        Wend
    End If
    Set GetLastText = t
End Function


Public Function CreateButton(ByVal bdom As ButtonDomain, ByVal bAction As ButtonAction, ByVal x As Integer, ByVal y As Integer, _
        Optional ByVal param As Variant = "", Optional ByVal param2 As Variant = 0, Optional ByVal minScore As Long = 0) As Button
    Dim b As New Button
    Set b.parent = Me
    b.domain = bdom
    b.param = param
    b.param2 = param2
    b.display = True
    b.x = x
    b.y = y
    b.w = w
    b.h = h
    b.x2 = x + w
    b.y2 = y + h
    b.ac = bAction
    b.domain = bdom
    b.score = minScore
    Call AddButton(b)
    Set CreateButton = b
End Function


Public Function CreateColl(ByVal coType As CollType, Optional ByVal x As Integer = 700, _
        Optional ByVal y As Integer = -50, Optional ByVal value As Long = 0) As Collectable
    Dim c As New Collectable
    
    Set c.parent = Me
    c.caption = caption
    c.cType = coType
    c.value = value
    If Not fColl Is Nothing Then
        Dim lc As Collectable
        Set lc = GetLastColl
        Set lc.nxt = c
        Set c.prv = lc
    Else
        Set fColl = c
    End If
    Select Case coType
        Case FrontWepUpgrade
            Call c.CreateWeapon
            Call c.CreatePath().Generate(600, x, y, x, SCR_HEIGHT + 1, Cosinus, 20, Round((SCR_HEIGHT - y) / CSng(100)))
        Case LeftWepUpgrade
            Call c.CreateWeapon
            Call c.CreatePath().Generate(600, x, y, x, SCR_HEIGHT + 1, Cosinus, 20, Round((SCR_HEIGHT - y) / CSng(100)))
        Case RightWepUpgrade
            Call c.CreateWeapon
            Call c.CreatePath().Generate(600, x, y, x, SCR_HEIGHT + 1, Cosinus, 20, Round((SCR_HEIGHT - y) / CSng(100)))
        Case HealthUpgrade
            Call c.CreateHealth
            Call c.CreatePath().Generate(600, x, y, x, SCR_HEIGHT + 1, Cosinus, 7, Round((SCR_HEIGHT - y) / CSng(33)))
        Case ShieldUpgrade
            Call c.CreateShield
            Call c.CreatePath().Generate(600, x, y, x, SCR_HEIGHT + 1, Cosinus, 30, Round((SCR_HEIGHT - y) / CSng(133)))
        Case GeneratorUpgrade
            Call c.CreateGenerator
            Call c.CreatePath().Generate(600, x, y, x, SCR_HEIGHT + 1, Cosinus, 20, Round((SCR_HEIGHT - y) / CSng(100)))
        Case BonusCredit
            Call c.CreateMoney
            Call c.CreatePath().Generate(600, x, y, x, SCR_HEIGHT + 1, Cosinus, 20, Round((SCR_HEIGHT - y) / CSng(100)))
        Case Else
            Call Logt("Unknow CollType: coType")
            Set c = Nothing
    End Select
    Set CreateColl = c
End Function


Public Function CreateMessage(ByVal mText As String, Optional ByVal fontStyle As Byte = 0, _
        Optional color As Long = &H90A0B0, Optional ByVal duration As Integer = 20) As Message
    Dim m As New Message
    Dim cnt As Integer
    Set m.parent = Me
    m.text = mText
    m.duration = duration
    m.startTime = elapsed
    m.bold = fontStyle And FONT_BOLD
    m.italic = fontStyle And FONT_ITALIC
    m.underlined = fontStyle And FONT_UNDERLINED
    m.color = color
    If Not fMessage Is Nothing Then
        Dim lm As Message
        Set lm = GetLastMessage(cnt)
        Set lm.nxt = m
        If cnt = MAX_MSG_COUNT Then
            Set fMessage = fMessage.nxt
        End If
    Else
        Set fMessage = m
    End If
    updateOSD = True
    Set CreateMessage = m
End Function


Public Function ShowScore()
    obj.CreateMessage "Your score is " & NumSpac(rocket.score), FONT_BOLD, &HD0E0F0, 30
End Function


Public Function CreateSector(Optional ByVal caption As String = "Sector") As Sector
    Dim s As New Sector
    Set s.parent = Me
    s.level = lastSectorNumber + 1
    s.caption = caption
    If Not fSector Is Nothing Then
        Dim ls As Sector
        Set ls = GetLastSector
        Set ls.nxt = s
        Set s.prv = ls
    Else
        Set fSector = s
    End If
    lastSectorNumber = s.level
    Set CreateSector = s
End Function


Public Sub CreateExplosion(h As Hostile)
    Dim ex As New Explosion
    Dim n As Integer
    Set ex.parent = Me
    ex.hostSize = h.img.size
    ex.sx = Round(h.img.x + h.img.width / 2 - explosions(1, EXPLOSION_STEPS).width / 2)
    ex.sy = Round(h.img.y + h.img.height / 2 - explosions(1, EXPLOSION_STEPS).width / 2)
    ex.stp = Floor(ex.hostSize / 20)
    If fExp Is Nothing Then
        Set fExp = ex
        Set ex.prv = Nothing
    Else
        Set lExp.nxt = ex
        Set ex.prv = lExp
    End If
    Set lExp = ex
End Sub


Public Sub DeleteExplosion(ex As Explosion)
    If Not ex.prv Is Nothing Then Set ex.prv.nxt = ex.nxt Else Set fExp = ex.nxt
    If Not ex.nxt Is Nothing Then Set ex.nxt.prv = ex.prv Else Set lExp = ex.prv
End Sub


Public Function CreateText(ByVal text As String, Optional dur As Integer = 200, Optional stat As Boolean = True, _
        Optional font As LongPtr = 0, Optional color As Long = &HA0FFFF, Optional shadowColor As Long = &H505050) As FloatText
    Dim t As New FloatText
    Set t.parent = Me
    t.text = text
    Call t.SetDuration(dur)
    t.color = color
    t.shadowColor = shadowColor
    t.font = font
    t.stationary = stat
    If font = 0 Then t.font = ftFont
    If Not stat Then
        Set t.trace = New Path
        Call t.trace.Generate(200, SCR_WIDTH / 2, 300, SCR_WIDTH / 2, 400, Linear)
    End If
    If Not fText Is Nothing Then
        Dim lt As FloatText
        Set lt = GetLastText
        Set lt.nxt = t
        Set t.prv = lt
    Else
        Set fText = t
    End If
    Set CreateText = t
End Function


Public Sub step()
    If Restart Then Exit Sub
    Dim c As Collectable
    Dim se As Sector
    Dim s As Structure
    Dim t As FloatText
    Dim ex As Explosion
    Dim dele As Explosion
    Dim biggerDim As Integer
    
    Set c = fColl
    While Not c Is Nothing
        If c.img.drawInLoop Then c.step
        Set c = c.nxt
    Wend
    
    If Not currentSector Is Nothing Then currentSector.step
    
    Set ex = fExp
    sta = "explo"
    Dim aix As Integer
    While Not ex Is Nothing
        ex.stp = ex.stp + 1
        Set dele = Nothing
        aix = Round(Rnd * (EXPLOSION_VAR - 1) + 1)
        If ex.stp <= EXPLOSION_STEPS Then
            Set ex.img = CloneImage(explosions(aix, ex.stp))
            ex.img.x = ex.sx + expOffsets(ex.stp)
            ex.img.y = ex.sy + expOffsets(ex.stp)
        Else
            Set dele = ex
        End If
        If ex.img.width > ex.hostSize Then Set dele = ex
        Set ex = ex.nxt
        If Not dele Is Nothing Then DeleteExplosion dele
    Wend
    
    Set t = fText
    While Not t Is Nothing
        t.step
        Set t = t.nxt
    Wend
End Sub


Public Sub GameOver()
    obj.CreateText "Game over", 80, False
    obj.GetLastIncompleteSector.EndSector
    Logt "Game over at level " & currentSector.level
    Restart = True
End Sub

'End of file


