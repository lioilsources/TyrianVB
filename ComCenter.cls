VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "ComCenter"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Class ComCenter

Public wPage As Integer                         ' current weapon page
Public nWeapons As Integer                      ' available weapons, now 4 (set in CreateCC)
Public nPages As Integer
Public pageSize As Integer

Private ccBDC As LongPtr                           ' command center background DC
Private ccBBmp(1 To CC_COLOR_COUNT) As LongPtr     ' command center background Bitmap
Private scoreStrCache(1 To 10) As String        ' string score representation
Private frontWNames As Variant
Private sideWNames As Variant
Private backIndex As Integer
Private backStep As Integer
Private backStepDir As Integer


Public Sub CreateCC(ByVal hdc As LongPtr)
    Dim p As LongPtr, grad As LongPtr, gmb As LongPtr, dc As LongPtr
    Dim p1 As LongPtr, p2 As LongPtr, p3 As LongPtr
    Dim b As LongPtr
    Dim xd As Single
    Dim yd As Single
    Dim cv As Long
    Dim clrShift As Double
    Dim clt As Long
    Dim bmp As LongPtr
    Dim tdc As LongPtr
    
    backIndex = 1
    backStepDir = 1
    nWeapons = 4    ' bubbles, vulcan, blast/star, lasers
    wPage = 1
    frontWNames = Array("Bubble Gun", "Vulcan Cannon", "Blaster", "Laser")
    sideWNames = Array("Small Bubble", "Small Vulcan", "Star Gun", "Small Laser")
    
    pageSize = (SCR_WIDTH - 660) / 200
    If pageSize <= 0 Then pageSize = 1
    nPages = Ceil(nWeapons / pageSize)
    dc = CreateCompatibleDC(hdc)
    
    tdc = CreateCompatibleDC(hdc)
    bmp = CreateCompatibleBitmap(hdc, SCR_WIDTH, SCR_HEIGHT)
    Call SelectObject(tdc, bmp)
    s = GdipCreateFromHDC(tdc, gmb)
    s = GdipCreatePath(FillModeAlternate, p)
    s = GdipAddPathEllipse(p, -SCR_WIDTH / 2, -SCR_HEIGHT, 4 * SCR_WIDTH, 3 * SCR_HEIGHT)
    s = GdipCreatePathGradientFromPath(p, grad)
    s = GdipSetPathGradientCenterColor(grad, &HFF307050)
    s = GdipSetPathGradientSurroundColorsWithCount(grad, &HFF206040, 3)
    s = GdipFillRectangle(gmb, grad, 0, 0, SCR_WIDTH, OSD_HEIGHT)
    s = GdipDrawRectangle(gmb, obj.gpen, 1, 1, SCR_WIDTH - 2, SCR_HEIGHT - 2)
    s = GdipDeletePath(p)
    
    For clr = 1 To CC_COLOR_COUNT
        Logt "Generating bitmaps (" & Math.Round(clr / CC_COLOR_COUNT * 100) & "%)", False
        SetFormLabel "Starting (Bitmaps " & Math.Round(clr / CC_COLOR_COUNT * 100) & "%)"
        ccBBmp(clr) = CreateCompatibleBitmap(hdc, SCR_WIDTH, SCR_HEIGHT)
        Call SelectObject(dc, ccBBmp(clr))
        MaskBlt dc, 0, 0, SCR_WIDTH, SCR_HEIGHT, tdc, 0, 0, 0, 0, 0, SRCCOPY
        s = GdipCreateFromHDC(dc, gmb)
        p1 = obj.RegObject(CreatePen(PS_SOLID, 1, &H306000))
        p2 = obj.RegObject(CreatePen(PS_SOLID, 1, &H503000))
        'p3 = obj.RegObject(CreatePen(PS_SOLID, 1, &H301010))
        xd = 255 / SCR_WIDTH
        yd = 255 / SCR_HEIGHT
        clrShift = 30 / (SCR_WIDTH + SCR_HEIGHT)
        For n = 0 To SCR_WIDTH Step 20
            For m = 0 To SCR_HEIGHT Step 20
                Call SelectObject(dc, p1)
                Call BeginPath(dc)
                Call Rectangle(dc, n, m, n + 17, m + 17)
                Call EndPath(dc)
                Call StrokePath(dc)
                Call SelectObject(dc, p2)
                Call BeginPath(dc)
                Call MoveToEx(dc, n + 1, m + 15, 0)
                Call LineTo(dc, n + 1, m + 1)
                Call LineTo(dc, n + 16, m + 1)
                Call MoveToEx(dc, n + 17, m + 1, 0)
                Call LineTo(dc, n + 17, m + 17)
                Call LineTo(dc, n + 1, m + 17)
                Call EndPath(dc)
                Call StrokePath(dc)
                cv = Round(n / 2 + m / 2 + clr * 26) Mod 255
                If (n + m) Mod 40 = 0 Then
                    clt = 30 - (clrShift * (n + m))
                    p3 = CreatePen(PS_SOLID, 1, "&H" & Hex(Round((255 - cv) / 5 + 70 - clt) * 65536 + Round(Abs(128 - cv) / 5 + 80 - clt) * 256 + Round(cv / 5) + 70 - clt))
                    Call SelectObject(dc, p3)
                    Call BeginPath(dc)
                    Call Rectangle(dc, n + 5, m + 5, n + 12, m + 12)
                    Call EndPath(dc)
                    Call StrokePath(dc)
                    Call DeleteObject(p3)
                End If
            Next m
        Next n
        s = GdipCreateSolidFill(&H90101010, b)
        s = GdipFillRectangle(gmb, b, 2, 20, SCR_WIDTH - 4, 70)
        s = GdipFillRectangle(gmb, b, 40, 150, 538, 280)
        s = GdipFillRectangle(gmb, b, 620, 150, pageSize * 180 + 20, 510)
        s = GdipFillRectangle(gmb, b, 40, 500, 538, 60)
        s = GdipFillRectangle(gmb, b, textFieldx1, textFieldy1, textFieldx2 - textFieldx1, textFieldy2 - textFieldy1)
        s = GdipFillRectangle(gmb, b, 40, 580, 538, 350)
        s = GdipFillRectangle(gmb, b, 2, SCR_HEIGHT - 70, SCR_WIDTH - 4, 60)
        Call SelectObject(dc, obj.ccBigFont)
        Call SetBkMode(dc, TRANSPARENT)
        Call SetTextAlign(dc, TA_LEFT)
        Call SText(dc, 30, 30, "Command Center", 4, &HF0C0A0, &H503020)
        Call SelectObject(dc, obj.osdFont2)
        Call SText(dc, 60, 518, "Pilot name", 2, &HA0D0D0, &H304040)
        Call SText(dc, 60, 160, "MODEL", 2, &HA0D0D0, &H304040)
        Call SText(dc, 640, 160, "Front", 2, &HA0D0D0, &H304040)
        Call SText(dc, 640, 410, "Sides", 2, &HA0D0D0, &H304040)
        Call SelectObject(dc, obj.osdFont)
        Call SText(dc, 200, 190, "HP           |  SHIELD", 2, &HA0D0D0, &H304040)
        Call SText(dc, 60, 232, "Ship slots", 2, &HA0D0D0, &H304040)
        Call SText(dc, 60, 340, "Generator ", 2, &HA0D0D0, &H304040)
        Call SetTextAlign(dc, TA_RIGHT)
        Call SText(dc, 155, 253, "Front", 2, &HA0D0D0, &H304040)
        Call SText(dc, 155, 276, "Left", 2, &HA0D0D0, &H304040)
        Call SText(dc, 155, 299, "Right", 2, &HA0D0D0, &H304040)
        Call SText(dc, 155, 400, "DPS ", 2, &HA0D0D0, &H304040)
        Call SetTextAlign(dc, TA_LEFT)
        SelectObject dc, obj.tableFontBig
        Call SText(dc, 60, 600, "Top 10", 2, &HA0D0D0, &H304040)
        s = GdipFlush(gmb, FlushIntentionFlush)
        s = GdipDeleteGraphics(gmb)
        Call GdiFlush
    Next clr
    ccBDC = dc
End Sub


Public Sub PaintBack(ByVal dc As LongPtr)
    SelectObject ccBDC, ccBBmp(backIndex)
    MaskBlt dc, 0, 0, SCR_WIDTH, SCR_HEIGHT, ccBDC, 0, 0, 0, 0, 0, SRCCOPY
    backStep = backStep + 1
    If backStep >= 4 Then
        backStep = 0
        backIndex = backIndex + backStepDir
        If backIndex = CC_COLOR_COUNT Then backIndex = 1
    End If
End Sub


Public Sub Paint(ByVal dc As LongPtr)
    Call SetTextAlign(dc, TA_LEFT)
    Call SelectObject(dc, obj.osdFont)
    Call SText(dc, 200, 164, rocket.name, 2, &HA0D0D0, &H304040)
    Call SText(dc, 230, 190, rocket.hpMax, 2, &HFFFFFF, &H304040)
    Call SText(dc, 350, 190, rocket.shieldMax, 2, &HFFFFFF, &H304040)
    Call SText(dc, 200, 253, rocket.GetSlotName(FrontGun), 2, &HA0D0D0, &H304040)
    Call SText(dc, 200, 276, rocket.GetSlotName(LeftGun), 2, &HA0D0D0, &H304040)
    Call SText(dc, 200, 299, rocket.GetSlotName(RightGun), 2, &HA0D0D0, &H304040)
    Call SText(dc, 200, 340, rocket.GetSlotName(Generator), 2, &HA0D0D0, &H304040)
    Call SelectObject(dc, obj.osdFontSmall)
    Call SText(dc, 200, 368, rocket.GenInfo, 2, &HA0D0D0, &H304040)
    Call SelectObject(dc, obj.osdBigFont)
    Call SText(dc, 200, 398, Round(rocket.CalculateDPS), 2, &HFFFFFF, &H304040)
    If textFieldEdit > 0 Then
        If textFieldEdit = 2 Then
            BeginPath dc
            SelectObject dc, obj.yellowPen
            Rectangle dc, textFieldx1, textFieldy1, textFieldx2, textFieldy2
            EndPath dc
            StrokePath dc
        End If
        Call SText(dc, textFieldx1 + 10, textFieldy1 + 10, rocket.pilotName & "_", 2, &HE8E8E8, &H304040)
    Else
        Call SText(dc, textFieldx1 + 10, textFieldy1 + 10, rocket.pilotName, 2, &HE8E8E8, &H304040)
    End If
    Dim j As Integer
    For j = 1 To 10
        If Not scores(j) Is Nothing Then
            Call SelectObject(dc, obj.tableFont)
            Call SetTextAlign(dc, TA_RIGHT)
            SText dc, 75, 620 + j * 26, CStr(j), 2, &HA0D0D0, &H304040
            Call SetTextAlign(dc, TA_LEFT)
            SText dc, 100, 620 + j * 26, scores(j).name, 2, &HA0D0D0, &H304040
            Call SelectObject(dc, obj.osdFontSmall)
            SText dc, 350, 624 + j * 26, "Lev " & scores(j).level, 2, &HA0D0D0, &H304040
            Call SelectObject(dc, obj.tableFontNum)
            Call SetTextAlign(dc, TA_RIGHT)
            SText dc, 560, 620 + j * 26, scoreStrCache(j), 2, &HA0D0D0, &H304040
        End If
    Next j
    
    Call SetTextAlign(dc, TA_LEFT)
    For j = 1 To pageSize
        Call PaintWeapon(dc, j + (wPage - 1) * pageSize, j)
    Next j
    
    If test Then
        Dim bww As Integer
        bww = 1398
        If SCR_WIDTH < bww Then bww = SCR_WIDTH
        SelectObject dc, obj.blackBrush
        Rectangle dc, 630, 695, bww, 950
        For j = 1 To 5
            DrawImage dc, 0, obj.geti(j), 600 + j * 40, 700
        Next j
        DrawImage dc, 0, rocket.img, 640, 740
        Static h As Hostile
        Dim xx As Integer
        If h Is Nothing Then Set h = New Hostile
        xx = 590
        For j = 1 To 12
            Call obj.SetType(h, j)
            If Not h.img Is Nothing Then
                xx = xx + h.img.width + 10
                If j = 12 Then xx = xx + 12
                DrawImage dc, 0, h.img, xx, 787
            End If
        Next j
        xx = 635
        For j = 1 To EXPLOSION_STEPS
            DrawImage dc, 0, explosions(1, j), xx, 860
            xx = xx + explosions(1, j).width + 10
        Next j
    End If
End Sub


Private Sub PaintWeapon(ByVal dc As LongPtr, ByVal n As Integer, ByVal slot As Integer)
    If n > nWeapons Then Exit Sub
    Call DevPaint(dc, frontWNames(n - 1), 640 + (slot - 1) * 180, 200)
    Call DevPaint(dc, sideWNames(n - 1), 640 + (slot - 1) * 180, 450)
End Sub


Public Sub DevPaint(ByVal dc As LongPtr, ByVal devName As String, ByVal x As Integer, ByVal y As Integer)
    Dim dt As DevType
    Dim im As Image
    Set dt = GetDevType(devName)
    Call BeginPath(dc)
    Call SelectObject(dc, obj.yellowPen)
    Call SelectObject(dc, obj.oldBrush2)
    Call Rectangle(dc, x, y, x + 160, y + 182)
    Call EndPath(dc)
    Call StrokeAndFillPath(dc)
    Set im = imgLib.GetItem(dt.imgName)
    If Not im Is Nothing Then Call DrawImage(dc, 0, im, x + 80 - im.width / 2, y + 10)
    Call SelectObject(dc, obj.osdFont)
    Call SText(dc, x + 10, y + 45, dt.name, 2, &HA0D0D0, &H304040)
    Call SText(dc, x + 10, y + 65, "Damage: " & dt.damage, 2, &HA0D0D0, &H304040)
    Call SText(dc, x + 10, y + 85, "Speed: " & 16 - Round(dt.cooldown), 2, &HA0D0D0, &H304040)
    Call SText(dc, x + 10, y + 105, "Price: $" & dt.price, 2, &HA0D0D0, &H304040)
    Set dt = Nothing
End Sub


Public Function GetDevType(ByVal dName As String) As DevType
    Dim dt As New DevType
    dt.name = dName
    dt.pwrGen = 0
    Select Case dName
        Case "Falcon Basic"
            dt.pwrGen = 4.35
            dt.price = 2000
            dt.upgCost = 0.35
            
        Case "Bubble Gun"
            dt.imgName = "bubble"
            dt.damage = 21
            dt.speed = 15
            dt.pwrNeed = 12
            dt.cooldown = 9
            dt.price = 2000
            dt.upgCost = 0.25
            dt.scaleProjectile = True
            dt.minProjScale = 0.5
            dt.maxProjScale = 0.85
            dt.beam = 0
            
        Case "Small Bubble"
            dt.imgName = "bubble"
            dt.damage = 6
            dt.speed = 15
            dt.pwrNeed = 4
            dt.cooldown = 9
            dt.price = 750
            dt.upgCost = 0.25
            dt.scaleProjectile = True
            dt.minProjScale = 0.3
            dt.maxProjScale = 0.55
            dt.beam = 0
            
        Case "Vulcan Cannon"
            dt.imgName = "vulcan"
            dt.damage = 24
            dt.speed = 30
            dt.pwrNeed = 16
            dt.cooldown = 3
            dt.xShiftMax = 14
            dt.price = 16000
            dt.upgCost = 0.3
            dt.scaleProjectile = True
            dt.minProjScale = 0.8
            dt.maxProjScale = 1
            dt.beam = 0
            
        Case "Small Vulcan"
            dt.imgName = "vulcan"
            dt.damage = 6
            dt.speed = 30
            dt.pwrNeed = 4
            dt.cooldown = 3
            dt.xShiftMax = 14
            dt.price = 8000
            dt.upgCost = 0.3
            dt.scaleProjectile = True
            dt.minProjScale = 0.65
            dt.maxProjScale = 0.8
            dt.beam = 0
            
        Case "Blaster"
            dt.imgName = "blaster"
            dt.damage = 250
            dt.speed = 27
            dt.guide = 2
            dt.pwrNeed = 85
            dt.cooldown = 15
            dt.price = 60000
            dt.upgCost = 0.3
            dt.scaleProjectile = True
            dt.minProjScale = 0.5
            dt.maxProjScale = 1
            dt.beam = 0
            
        Case "Star Gun"
            dt.imgName = "starg"
            dt.damage = 30
            dt.speed = 17
            dt.guide = 10
            dt.pwrNeed = 10
            dt.cooldown = 8
            dt.price = 30000
            dt.upgCost = 0.33
            dt.scaleProjectile = True
            dt.minProjScale = 0.5
            dt.maxProjScale = 0.8
            dt.beam = 0
            
        Case "Laser"
            dt.imgName = "laser"
            dt.damage = 64
            dt.speed = 12
            dt.guide = 3
            dt.pwrNeed = 66
            dt.cooldown = 15
            dt.price = 175000
            dt.upgCost = 0.42
            dt.beam = 1
            dt.seqs = 6
            
        Case "Small Laser"
            dt.imgName = "laser"
            dt.damage = 28
            dt.speed = 12
            dt.guide = 3
            dt.pwrNeed = 27
            dt.cooldown = 15
            dt.price = 80000
            dt.upgCost = 0.42
            dt.beam = 1
            dt.seqs = 6
        
        Case Else
            Call Logt("GetDevType error: unknow name " & dName)
    End Select
    Set GetDevType = dt
End Function


Public Sub FillStrCache()
    Dim i As Integer
    For i = LBound(scores) To UBound(scores)
        If Not scores(i) Is Nothing Then scoreStrCache(i) = NumSpac(scores(i).score)
    Next i
End Sub


Public Sub NextPage()
    wPage = wPage + 1
    If wPage > nPages Then wPage = 1
End Sub


Public Sub CleanUp()
    For n = 1 To CC_COLOR_COUNT
        Call DeleteObject(ccBBmp(n))
    Next n
    Call DeleteDC(ccBDC)
End Sub

'End of file


