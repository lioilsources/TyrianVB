Attribute VB_Name = "Module"
Option Explicit

Public WND_WIDTH As Long
Public WND_HEIGHT As Long
Public Const OSD_WIDTH As Long = 280
Public OSD_HEIGHT As Long
Public SCR_WIDTH As Long
Public SCR_HEIGHT As Long

Public Const FRAME_DELAY As Long = 25
Public Const STAR_COUNT As Long = 1000
Public Const CC_COLOR_COUNT As Integer = 12
Public Const PI As Single = 3.14159265359
Public Const MAX_WEAP_LEV As Integer = 25
Public Const EXPLOSION_STEPS As Integer = 15
Public Const EXPLOSION_VAR As Integer = 4

Private Const CLASS_NAME = "FSClass"
Private starFieldHeight As Long
Private Const WND_STYLE = WS_EX_TOPMOST Or WS_EX_NOPARENTNOTIFY
Private Const SIZE_UNIT As Double = 3.77926421404682E-02
Private Const IMG_DIR As String = "C:\Users\geeol\Code\TyrianVB\img\"

' Font style for MakeFont()
Public Const FONT_BOLD As Byte = 1
Public Const FONT_UNDERLINED As Byte = 2
Public Const FONT_ITALIC As Byte = 4
Public Const FONT_STRIKEOUT As Byte = 8

Public Const MB_LEFT = 1
Public Const MB_MIDDLE = 2
Public Const MB_RIGHT = 4

Public Const STATE_FILE_NAME As String = "state.d"
Public Const LOG_FILE_NAME As String = "log.txt"

Public mx As Integer
Public my As Integer
Public elapsed As Long
Public mbutt As Integer
Public updateOSD As Boolean
Public displayComCenter As Boolean
Public exiting As Boolean
Public osdFocus As Boolean
Public s As GpStatus
Public IsCursor As Boolean
Public Restart As Boolean
Public starCount As Integer
Public wDir As String
Public fname As String
Public imgDir As String
Public instantMove As Boolean
Public pause As Boolean
Public hwndForm As LongPtr
Public pausedTime As Long
Public pauseStartTime As Single
Public running As Boolean
Public test As Boolean
Public r As Recordset
Public textFieldx1 As Integer
Public textFieldy1 As Integer
Public textFieldx2 As Integer
Public textFieldy2 As Integer
Public textFieldEdit As Byte
Public minScore As Long
Public scores(1 To 10) As Record
Public scoresChanged As Boolean
Public saved As Boolean

Private initPilotName As String
Private LAYERS As Variant           ' const array of transparent color layers
Public ROMNUM As Variant
Private startTime As Long
Private lastElVal As Long
Private avg As Single
Private state As Long
Private ticks As Long
Private lastShowFPSTime As Long
Private upadateOSD As Boolean
Private dt As Long
Private token As LongPtr
Private g As LongPtr
Private gm As LongPtr
Private hdc As LongPtr
Private ib As GdiplusStartupInput
Private worldMatrix As LongPtr
Private ltime As Long, t As Long
Private tmp As Long
Private grad As Variant
Private tmpDC As LongPtr
Private lastCredit As Long
Private fStream As Variant
Private fState As String
Private lStream As Variant
Private TimerID As LongPtr
Private logFile As Variant

Public imgLib As New Library
Public rocket As New Vessel
Public currentSector As Sector
Public cCenter As New ComCenter
Public obj As New Objects
Public explosions(1 To EXPLOSION_VAR, 1 To EXPLOSION_STEPS) As Image
Private starField(1 To STAR_COUNT) As Image


' Screen buffers
Private BDC As LongPtr      ' main area DC
Private bmp As LongPtr      ' main area Bitmap
Private odc As LongPtr      ' right panel DC
Private osdBmp As LongPtr   ' right panel bitmap
Private osdBDC As LongPtr   ' right panel background DC
Private osdBBmp As LongPtr  ' right panel background bitmap


' temporary
Private i As Integer, d As Integer
Private an As Single
Private tx As Texture
Private i1 As Long, i2 As Long
Private tex1 As LongPtr
Private mat1 As LongPtr
Private tb As Button
Private ts As Long


' ----------------------------------------------------------------------------------------------------------------------
' ----------------------------------------------------------------------------------------------------------------------
' ----------------------------------------------------------------------------------------------------------------------



Public Function ArcSin(ByVal x As Double) As Double
    ArcSin = Atn(x / Sqr(-x * x + 1))
End Function


Public Function ArcCos(ByVal x As Double) As Double
    ArcCos = Atn(-x / Sqr(-x * x + 1)) + 2 * Atn(1)
End Function


Public Function Max(ByVal x1 As Long, ByVal x2 As Long) As Long
    If x1 > x2 Then Max = x1 Else Max = x2
End Function


Public Function Min(ByVal x1 As Long, ByVal x2 As Long) As Long
    If x1 < x2 Then Min = x1 Else Min = x2
End Function


Public Sub HideCur(Optional dummy As Boolean = False)
    If IsCursor Then
        IsCursor = False
        Call ShowCursor(False)
    End If
End Sub


Public Sub ShowCur(Optional dummy As Boolean = False)
    If Not IsCursor Then
        IsCursor = True
        Call ShowCursor(True)
    End If
End Sub


Public Sub text(ByVal dc As LongPtr, ByVal x As Long, ByVal y As Long, ByVal str As String, _
        Optional ByVal fColor As Long = &HFFFFFF)
    Call SetTextColor(dc, fColor)
    Call TextOut(dc, x, y, str, Len(str))
End Sub


Public Sub SText(ByVal dc As LongPtr, ByVal x As Long, ByVal y As Long, ByVal str As String, Optional shift As Long = 2, _
        Optional ByVal fColor As Long = &HF0E0E0, Optional ByVal bColor As Long = &H505050)
    Call SetTextColor(dc, bColor)
    Call TextOut(dc, x + shift, y + shift, str, Len(str))
    Call SetTextColor(dc, fColor)
    Call TextOut(dc, x, y, str, Len(str))
End Sub


Public Sub ButtonBox(ByVal dc As LongPtr, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long, _
        ByVal color1 As Long, ByVal color2 As Long, ByVal color3 As Long)
    Dim tc1 As LongPtr, tc2 As LongPtr, tc3 As LongPtr
    tc1 = CreatePen(PS_SOLID, 1, color1)
    tc2 = CreateSolidBrush(color2)
    tc3 = CreatePen(PS_SOLID, 1, color3)
    Call SelectObject(dc, tc1)
    Call SelectObject(dc, tc2)
    Call BeginPath(dc)
    Call Rectangle(dc, x, y, x + w, y + h)
    Call EndPath(dc)
    Call StrokeAndFillPath(dc)
    Call SelectObject(dc, tc3)
    Call BeginPath(dc)
    Call Rectangle(dc, x + 1, y + 1, x + w - 1, y + h - 1)
    Call EndPath(dc)
    Call StrokePath(dc)
    Call DeleteObject(tc1)
    Call DeleteObject(tc2)
    Call DeleteObject(tc3)
End Sub


Public Sub HrzBox(ByVal dc As LongPtr, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long)
    Call BeginPath(dc)
    Call MoveToEx(dc, x, y, 0)
    Call LineTo(dc, x + w, y)
    Call MoveToEx(dc, x, y + h, 0)
    Call LineTo(dc, x + w, y + h)
    Call EndPath(dc)
    Call StrokePath(dc)
End Sub


Public Function CreateImage(ByVal hBitmap As LongPtr, ByVal x As Long, ByVal y As Long, ByVal w As Long, ByVal h As Long) As Image
    Dim i As New Image
    i.hBitmap = hBitmap
    i.filename = "#" & hBitmap
    i.drawInLoop = True
    i.x = x
    i.y = y
    i.width = w
    i.height = h
    i.size = Sqr(w * w + h * h)
    i.filterColor = &HFFFFFF
    Set CreateImage = i
End Function


Public Function CloneImage(orig As Image) As Image
    Dim i As New Image
    i.hBitmap = orig.hBitmap
    i.hMask = orig.hMask
    i.handle = orig.handle
    i.filename = orig.filename
    i.drawInLoop = orig.drawInLoop
    i.x = orig.x
    i.y = orig.y
    i.width = orig.width
    i.height = orig.height
    i.size = orig.size
    i.filterColor = orig.filterColor
    Set CloneImage = i
End Function


Public Function CreateMask(ByVal hBitmap As LongPtr, ByVal width As Long, ByVal height As Long, _
            Optional ByVal maskColor = &HFFFFFFFF) As LongPtr
    Dim nb As LongPtr, b As LongPtr, clr As Long
    Dim x As Integer, y As Integer
    
    s = GdipCreateBitmapFromHBITMAP(hBitmap, 0, b)
    For x = 0 To width - 1
        For y = 0 To height - 1
            s = GdipBitmapGetPixel(b, x, y, clr)
            clr = clr And maskColor
            If clr = maskColor Then clr = 0 Else clr = maskColor
            s = GdipBitmapSetPixel(b, x, y, clr)
        Next y
    Next x
    s = GdipCreateHBITMAPFromBitmap(b, nb, &H0&)
    CreateMask = nb
End Function


Public Function ApplyAlpha(ByVal color As Long, ByVal alpha As Long) As Long
    Dim c As Long
    Dim n As Long
    
    If alpha = 0 Then
        ApplyAlpha = color And &HFFFFFF
    Else
        c = color
        For i = 0 To 2
            n = c And &HFF
            n = (n * alpha) / &H100
            ApplyAlpha = ApplyAlpha + n * (&H100 ^ i)
            c = c And &HFFFF00
            c = c / &H100
        Next i
    End If
End Function


Public Sub CreateImageMask(i As Image)
    Dim clr As Long, dc As LongPtr, b As LongPtr
    Dim hpal As LongPtr
    Dim x As Integer, y As Integer
    Dim alpha As Long
    Dim dColor As Long
    
    If Not i.pict Is Nothing Then hpal = i.pict.hpal
    s = GdipCreateBitmapFromHBITMAP(i.hBitmap, hpal, b)
    'alpha = (i.filterColor And &HFF000000) / &H1000000
    'i.filterColor = i.filterColor And &HFFFFFF
    'dColor = ApplyAlpha(i.filterColor, alpha)
    For x = 0 To i.width - 1
        For y = 0 To i.height - 1
            s = GdipBitmapGetPixel(b, x, y, clr)
            clr = (clr And i.filterColor)
            If clr = i.filterColor Then clr = 0 Else clr = &HFFFFFFFF
            s = GdipBitmapSetPixel(b, x, y, clr)
        Next y
    Next x
    Dim nb As LongPtr
    s = GdipCreateHBITMAPFromBitmap(b, nb, &H0&)
    i.hMask = nb
End Sub


Public Sub SmoothBitmap(hBitmap As LongPtr, ByVal width As Long, ByVal height As Long)
    Dim clr As Long, dc As LongPtr, tdc As LongPtr, bm As LongPtr, tbm As LongPtr
    Dim r As Long, g As Long, b As Long
    Dim rs As Long, gs As Long, bs As Long
    Dim pxCount As Integer
    Dim clr2 As Long
    Dim x As Integer, y As Integer, w As Integer, h As Integer
    
    dc = CreateCompatibleDC(hdc)
    Call SelectObject(dc, hBitmap)
    tdc = CreateCompatibleDC(hdc)
    tbm = CreateCompatibleBitmap(hdc, width, height)
    Call SelectObject(tdc, tbm)
    For x = 0 To width
        For y = 0 To height
            clr = GetPixel(dc, x, y)
            clr = clr And &HFFFFFF
            If clr <> &HFFFFFF Then ' don't touch pixels with mask color
                pxCount = 0
                rs = 0
                gs = 0
                bs = 0
                For w = -1 To 1 Step 1
                    For h = -1 To 1 Step 1
                        If x + w >= 0 And y + h >= 0 And x + w <= width And y + h <= height Then
                            clr = GetPixel(dc, x + w, y + h)
                            If clr <> &HFFFFFF Then
                                pxCount = pxCount + 1
                                r = clr And &HFF&
                                g = (clr And &HFF00&) / &H100&
                                b = (clr And &HFF0000) / &H10000
                                rs = rs + r
                                gs = gs + g
                                bs = bs + b
                            End If
                        End If
                    Next h
                Next w
                If pxCount = 9 Then
                    rs = rs / pxCount
                    gs = gs / pxCount
                    bs = bs / pxCount
                    clr2 = (bs * 65536 + gs * 256 + rs)
                    Call SetPixel(tdc, x, y, clr2)
                Else
                    Call SetPixel(tdc, x, y, clr)
                End If
            Else
                SetPixel tdc, x, y, clr
            End If
        Next y
    Next x
    Call DeleteDC(dc)
    Call DeleteDC(tdc)
    Call DeleteObject(hBitmap)
    hBitmap = tbm
End Sub


Public Function LoadImg(ByVal name As String, Optional ByVal x As Long = -1, Optional ByVal y As Long = -1, _
            Optional ByVal w As Long = -1, Optional ByVal h As Long = -1) As Image
On Error GoTo lerr
    Dim i As New Image
    i.filename = name
    Set i.pict = LoadPicture(imgDir & name)
    i.hBitmap = i.pict.handle
    If x >= 0 Then i.x = x
    If y >= 0 Then i.y = y
    If w >= 0 Then i.width = w Else i.width = Round(i.pict.width * SIZE_UNIT)
    If h >= 0 Then i.height = h Else i.height = Round(i.pict.height * SIZE_UNIT)
    i.size = CSng(Sqr(CDbl(i.width * i.width + i.height * i.height)))
    i.drawInLoop = True
    i.filterColor = &HFFFFFF
    Set LoadImg = i
    Exit Function
lerr:
    Dim es As String
    es = Error
    es = Replace(es, "'", "")
    Logt "LoadImg: " & es, False
    Set LoadImg = Nothing
End Function


Public Function GdipLoadImg(ByVal name As String, Optional ByVal x As Long = -1, Optional ByVal y As Long = -1, _
            Optional ByVal w As Long = -1, Optional ByVal h As Long = -1) As Image
    Dim i As New Image
    Dim hImg As LongPtr
    Dim val As Long
    i.filename = name
    s = GdipLoadImageFromFile(StrConv(imgDir & name, vbUnicode), hImg)
    i.handle = hImg
    If x >= 0 Then i.x = x
    If y >= 0 Then i.y = y
    If w >= 0 Then val = w Else s = GdipGetImageWidth(i.handle, val)
    i.width = val
    If h >= 0 Then val = h Else s = GdipGetImageHeight(i.handle, val)
    i.height = val
    i.size = CSng(Sqr(CDbl(i.width * i.width + i.height * i.height)))
    i.drawInLoop = True
    i.filterColor = &HFFFFFF
    Set GdipLoadImg = i
End Function


Public Sub DrawImage(ByVal dc As LongPtr, graphics As LongPtr, i As Image, Optional ByVal x As Integer = -1000, _
        Optional ByVal y As Integer = -1000)

    If x > -1000 Then i.x = x
    If y > -1000 Then i.y = y
    If i.hBitmap <> 0 Then
        If i.hMask <> 0 Then
            Call SelectObject(tmpDC, i.hMask)
            Call MaskBlt(dc, Round(i.x), Round(i.y), i.width, i.height, tmpDC, 0, 0, 0, 0, 0, SRCPAINT)
            Call SelectObject(tmpDC, i.hBitmap)
            Call MaskBlt(dc, Round(i.x), Round(i.y), i.width, i.height, tmpDC, 0, 0, 0, 0, 0, SRCAND)
        Else
            Call SelectObject(tmpDC, i.hBitmap)
            Call MaskBlt(dc, Round(i.x), Round(i.y), i.width, i.height, tmpDC, 0, 0, 0, 0, 0, SRCCOPY)
        End If
    Else
        Call GdipDrawImage(graphics, i.handle, i.x, i.y)
    End If
End Sub


Public Sub DrawButton(ByVal dc As LongPtr, graphics As LongPtr, b As Button)
    Static bx As Integer
    Static a As Integer
    
    bx = b.x
    If b.param2 > 0 Then
        a = 0 - (cCenter.wPage - 1) * cCenter.pageSize
        If a = 0 Then
            If b.param2 <= cCenter.pageSize Then DrawButtonIntr dc, graphics, b, bx, b.y
        Else
            If (b.param2 + a) > 0 Then DrawButtonIntr dc, graphics, b, bx + 180 * a, b.y
        End If
    Else
        DrawButtonIntr dc, graphics, b, bx, b.y
    End If
End Sub


Public Sub DrawButtonIntr(ByVal dc As LongPtr, graphics As LongPtr, b As Button, ByVal bx As Integer, ByVal by As Integer)
    If b.over Then
        If b.pressed Then
            Call DrawImage(dc, graphics, b.imgDown, bx, by)
        Else
            Call DrawImage(dc, graphics, b.imgOver, bx, by)
        End If
    Else
        Call DrawImage(dc, graphics, b.imgUp, bx, by)
    End If
End Sub


Public Function CloneBitmap(ByVal bmp As LongPtr, ByVal w As Long, ByVal h As Long) As LongPtr
    Dim sdc As LongPtr, ddc As LongPtr
    Dim bm As LongPtr
    sdc = CreateCompatibleDC(hdc)
    Call SelectObject(sdc, bmp)
    ddc = CreateCompatibleDC(hdc)
    bm = CreateCompatibleBitmap(hdc, w, h)
    Call SelectObject(ddc, bm)
    Call MaskBlt(ddc, 0, 0, w, h, sdc, 0, 0, 0, 0, 0, SRCCOPY)
    Call DeleteDC(sdc)
    Call DeleteDC(ddc)
    CloneBitmap = bm
End Function


Public Function CopyImage(i As Image, ByVal x As Long, ByVal y As Long, ByVal c As Single, _
        Optional ByVal ratio As Single = 1, Optional layer As Boolean = False, _
        Optional ByVal layNum As Integer = -1, Optional stretchMode As Integer = -1) As Image
    
    Dim n As New Image
    If Not i Is Nothing Then
        Dim dg As LongPtr, br As LongPtr
        Dim ln As Integer
        
        n.drawInLoop = True
        If ratio <> 1 Then
            Dim sdc As LongPtr, ddc As LongPtr
            Dim bm As LongPtr
            Dim nw As Long, nh As Long
            
            nw = Round(ratio * i.width)
            nh = Round(ratio * i.height)
            n.width = nw
            n.height = nh
            n.size = Sqr(nw * nw + nh * nh)
            ' stretch mask
            sdc = CreateCompatibleDC(hdc)
            Call SelectObject(sdc, i.hMask)
            ddc = CreateCompatibleDC(hdc)
            If stretchMode <= 0 Then
                If ratio < 0.9 Then
                    Call SetStretchBltMode(sdc, STRETCH_DELETESCANS)
                    Call SetStretchBltMode(ddc, STRETCH_DELETESCANS)
                Else
                    Call SetStretchBltMode(sdc, STRETCH_HALFTONE)
                    Call SetStretchBltMode(ddc, STRETCH_HALFTONE)
                End If
            Else
                Call SetStretchBltMode(sdc, stretchMode)
                Call SetStretchBltMode(ddc, stretchMode)
            End If
            bm = obj.RegObject(CreateCompatibleBitmap(hdc, nw, nh))
            Call SelectObject(ddc, bm)
            Call StretchBlt(ddc, 0, 0, nw, nh, sdc, 0, 0, i.width, i.height, SRCCOPY)
            n.hMask = bm
            'stretch image
            Call SelectObject(sdc, i.hBitmap)
            bm = obj.RegObject(CreateCompatibleBitmap(hdc, nw, nh))
            Call SelectObject(ddc, bm)
            Call StretchBlt(ddc, 0, 0, nw, nh, sdc, 0, 0, i.width, i.height, SRCCOPY)
            n.hBitmap = bm
            If layer Then
                ln = layNum
                If ln < 0 Then ln = Round(Rnd * 3)
                n.filterColor = LAYERS(ln)
                s = GdipCreateFromHDC(ddc, dg)
                s = GdipCreateSolidFill(LAYERS(ln), br)
                s = GdipFillRectangle(dg, br, 0, 0, nw, nh)
                s = GdipDeleteGraphics(dg)
                Call SelectObject(sdc, n.hMask)
                Call MaskBlt(ddc, 0, 0, nw, nh, sdc, 0, 0, 0, 0, 0, MERGEPAINT)
            End If
            
            Call DeleteDC(sdc)
            Call DeleteDC(ddc)
        Else
            n.hBitmap = i.hBitmap
            n.hMask = i.hMask
            n.width = i.width
            n.height = i.height
            n.size = i.size
        End If
        n.x = x
        n.y = y
        n.cust = c
        n.filename = i.filename & " (copy)"
    End If
    Set CopyImage = n
End Function


Public Function CreatePBarGrad(ByVal x As Integer, ByVal y As Integer, ByVal w As Integer, _
        ByVal h As Integer, ByVal color1 As Long, ByVal color2 As Long) As LongPtr
    Dim p As LongPtr
    Dim grad As LongPtr
    s = GdipCreatePath(FillModeAlternate, p)
    s = GdipAddPathEllipse(p, x - w / 4, y - h, 2 * w, 4 * h)
    s = GdipCreatePathGradientFromPath(p, grad)
    s = GdipSetPathGradientCenterColor(grad, color1)
    s = GdipSetPathGradientSurroundColorsWithCount(grad, color2, 1)
    s = GdipDeletePath(p)
    CreatePBarGrad = grad
End Function


Public Sub DrawProgressBar(ByVal grad As LongPtr, ByVal x As Single, ByVal y As Single, ByVal w As Single, ByVal h As Single, _
        ByVal pct As Single)
    s = GdipFillRectangle(gm, grad, x, y, w * pct, h)
End Sub


Public Sub ScribeButtonImage(b As Button, ByVal str As String, ByVal font As LongPtr)
    Dim dc As LongPtr
    Dim bmp As LongPtr
    dc = CreateCompatibleDC(hdc)
    Call SetTextAlign(dc, TA_CENTER Or TA_BASELINE)
    Call SelectObject(dc, font)
    Call SetBkMode(dc, TRANSPARENT)
    bmp = obj.RegObject(CloneBitmap(b.imgUp.hBitmap, b.w, b.h))
    Call SelectObject(dc, bmp)
    Call SText(dc, b.w / 2, b.h * 0.7, str, 2, &H0, &H808080)
    b.imgUp.hBitmap = bmp
    bmp = obj.RegObject(CloneBitmap(b.imgDown.hBitmap, b.w, b.h))
    Call SelectObject(dc, bmp)
    Call text(dc, b.w / 2 + 2, b.h * 0.7 + 2, str, &H0)
    b.imgDown.hBitmap = bmp
    bmp = obj.RegObject(CloneBitmap(b.imgOver.hBitmap, b.w, b.h))
    Call SelectObject(dc, bmp)
    Call SText(dc, b.w / 2, b.h * 0.7, str, 2, &H0, &H808080)
    b.imgOver.hBitmap = bmp
    Call DeleteDC(dc)
End Sub


Public Sub CreateButtonImages(b As Button, ByVal w As Integer, ByVal h As Integer, ByVal caption As String, ByVal font As LongPtr)
    Dim dc As LongPtr
    b.w = w
    b.h = h
    b.x2 = b.x + w
    b.y2 = b.y + h
    dc = CreateCompatibleDC(hdc)
    bmp = obj.RegObject(CreateCompatibleBitmap(hdc, b.w, b.h))
    Call SelectObject(dc, bmp)
    SetTextAlign dc, TA_CENTER Or TA_BASELINE
    Call SelectObject(dc, font)
    Call SelectObject(dc, obj.oldPen)
    Call SelectObject(dc, obj.oldBrush)
    Call SetBkMode(dc, TRANSPARENT)
    Call ButtonBox(dc, 0, 0, w, h, &HF0F0F0, &HA0A0A0, &H80C0C0)
    Call SText(dc, b.w / 2, b.h * 0.7, caption, 2, &H0, &H808080)
    Set b.imgUp = New Image
    b.imgUp.hBitmap = bmp
    b.imgUp.Setup b.x, b.y, w, h
    b.imgUp.hMask = CreateMask(bmp, w, h)
    bmp = obj.RegObject(CreateCompatibleBitmap(hdc, b.w, b.h))
    Call SelectObject(dc, bmp)
    Call ButtonBox(dc, 0, 0, w, h, &HF0F0F0, &H909090, &H60A0A0)
    Call text(dc, b.w / 2 + 1, b.h * 0.7 + 1, caption, &H0)
    Set b.imgDown = New Image
    b.imgDown.hBitmap = bmp
    b.imgDown.Setup b.x, b.y, w, h
    b.imgDown.hMask = CreateMask(bmp, w, h)
    bmp = obj.RegObject(CreateCompatibleBitmap(hdc, b.w, b.h))
    Call SelectObject(dc, bmp)
    Call ButtonBox(dc, 0, 0, w, h, &HD0D0D0, &H808080, &H60A0A0)
    Call SText(dc, b.w / 2, b.h * 0.7, caption, 2, &H0, &H808080)
    Set b.imgOver = New Image
    b.imgOver.hBitmap = bmp
    b.imgOver.Setup b.x, b.y, w, h
    b.imgOver.hMask = CreateMask(bmp, w, h)
    Call DeleteDC(dc)
End Sub


Private Function CreateTexture(ByVal i As Image) As Texture
    Dim t As New Texture
    Dim tex As LongPtr
    s = GdipCreateTexture(i.handle, WrapModeClamp, tex)
    s = GdipTranslateTextureTransform(tex, -i.width / 2, -i.height / 2, MatrixOrderAppend)
    t.tex = tex
    t.x = i.x
    t.y = i.y
    t.w = i.width
    t.h = i.height
    t.size = Sqr(t.w * t.w + t.h * t.h)
    Set CreateTexture = t
End Function


Private Sub PlaceTexture(t As Texture)
    Dim mat As LongPtr, tex As LongPtr
    tex = t.tex
    s = GdipSaveGraphics(g, state)
    s = GdipCreateMatrix(mat)
    s = GdipTranslateMatrix(mat, t.x, t.y, MatrixOrderAppend)
    s = GdipSetWorldTransform(g, mat)
    s = GdipFillRectangle(g, tex, -t.size / 2, -t.size / 2, t.size, t.size)
    s = GdipDeleteMatrix(mat)
    s = GdipRestoreGraphics(g, state)
End Sub


Private Function CreateOSD(Optional dummy As Boolean = False) As LongPtr
    Dim p As LongPtr, grad As LongPtr, gmb As LongPtr, dc As LongPtr, b As LongPtr, pen As LongPtr
    Dim x As Integer, y As Integer
    dc = CreateCompatibleDC(hdc)
    osdBBmp = CreateCompatibleBitmap(hdc, OSD_WIDTH, OSD_HEIGHT)
    SelectObject dc, osdBBmp
    s = GdipCreateFromHDC(dc, gmb)
    s = GdipCreatePath(FillModeAlternate, p)
    s = GdipAddPathRectangle(p, 0, 0, OSD_WIDTH * 2.5, OSD_HEIGHT * 1.3)
    s = GdipCreatePathGradientFromPath(p, grad)
    s = GdipSetPathGradientCenterColor(grad, &HFF001A08)
    s = GdipSetPathGradientSurroundColorsWithCount(grad, &HFF106040, 1)
    s = GdipFillRectangle(gmb, grad, 0, 0, OSD_WIDTH, OSD_HEIGHT)
    s = GdipDrawRectangle(gmb, obj.gpen, 1, 1, OSD_WIDTH - 2, OSD_HEIGHT - 2)
    s = GdipDeletePath(p)
    s = GdipCreatePen1(&HFF105030, 0.5, GpUnit.UnitPixel, pen)
    For x = 6 To OSD_WIDTH - 6 Step 6
        Call GdipDrawLine(gmb, pen, x, 8, x, OSD_HEIGHT - 8)
    Next x
    For y = 6 To OSD_HEIGHT - 6 Step 6
        Call GdipDrawLine(gmb, pen, 8, y, OSD_WIDTH - 8, y)
    Next y
    s = GdipCreateSolidFill(&H90101010, b)
    s = GdipFillRectangle(gmb, b, 5, 5, OSD_WIDTH - 10, OSD_HEIGHT - 10)
    s = GdipCreateSolidFill(&H66101010, b)
    s = GdipFillRectangle(gmb, b, 13, 48, OSD_WIDTH - 25, 17)
    ' Message panel
    s = GdipDrawRectangle(gmb, obj.gpen3, 7, 309, OSD_WIDTH - 14, 246)
    s = GdipCreateSolidFill(&H20101010, b)
    s = GdipFillRectangle(gmb, b, 8, 310, OSD_WIDTH - 16, 245)
    s = GdipCreateSolidFill(&H40101010, b)
    s = GdipFillRectangle(gmb, b, 10, 312, OSD_WIDTH - 20, 241)
    s = GdipCreateSolidFill(&H80101010, b)
    s = GdipFillRectangle(gmb, b, 12, 314, OSD_WIDTH - 24, 237)
    Call SelectObject(dc, obj.whitePen)
    Call BeginPath(dc)
    Call Rectangle(dc, 13, 48, OSD_WIDTH - 13, 64)
    Call EndPath(dc)
    Call StrokePath(dc)
    Call HrzBox(dc, 165, 81, 100, 18)
    Call HrzBox(dc, 165, 101, 100, 18)
    Call HrzBox(dc, 165, 121, 100, 18)
    Call SelectObject(dc, obj.osdFont)
    Call SetBkMode(dc, TRANSPARENT)
    Call SText(dc, 13, 17, "Level", 2, &HA0D0D0, &H306030)
    Call SText(dc, 15, 82, "HP", 2, &HA0B0C0, &H605040)
    Call SText(dc, 15, 102, "Shield", 2, &HA0B0C0, &H605040)
    Call SText(dc, 15, 122, "Generator", 2, &HA0B0C0, &H605040)
    Call SText(dc, 15, 152, "Front", 2, &HA0B0C0, &H605040)
    Call SText(dc, 15, 172, "Left", 2, &HA0B0C0, &H605040)
    Call SText(dc, 15, 192, "Right", 2, &HA0B0C0, &H605040)
    Call SText(dc, 15, 220, "Credit", 2, &HA0C0C0, &H605040)
    If test Then Call SText(dc, 10, 560, "Test MODE", 2, &HA0C0C0, &H605040)
    Call SelectObject(dc, obj.smallFont)
    'text dc, 10, OSD_HEIGHT - 35, "Total"
    'text dc, 140, OSD_HEIGHT - 35, "Paint"
    'text dc, 190, OSD_HEIGHT - 35, "Rocket"
    'text dc, 240, OSD_HEIGHT - 35, "Obj"
    s = GdipFlush(gmb, FlushIntentionFlush)
    s = GdipDeleteGraphics(gmb)
    Call GdiFlush
    CreateOSD = dc
End Function


Private Sub OSDPaint(Optional info As String = "")
    Static cnt As Integer
    Static m As Message
    Static b As Button
    Static fColor As Long
    Static changeColor As Integer
    
    MaskBlt odc, 0, 0, OSD_WIDTH, OSD_HEIGHT, osdBDC, 0, 0, 0, 0, 0, SRCCOPY
    ' display state here
    SelectObject odc, obj.osdBigFont
    SetTextAlign odc, TA_LEFT
    If Not currentSector Is Nothing Then
        SText odc, 68, 16, currentSector.level, 2, &HF0F0F0, &H306030
    Else
        SText odc, 68, 16, CStr(obj.lastSectorNumber + 1), 2, &HF0F0F0, &H306030
    End If
    SelectObject odc, obj.osdFont
    SetTextAlign odc, TA_RIGHT
    If Not currentSector Is Nothing And Not displayComCenter Then
        DrawProgressBar obj.progressBarGradL, 15, 50, OSD_WIDTH - 30, 11.5, currentSector.Completed()
    End If
    DrawProgressBar obj.progressBarGradH, 165, 82, 100, 16, rocket.hp / rocket.hpMax
    DrawProgressBar obj.progressBarGradS, 165, 102, 100, 16, rocket.shield / rocket.shieldMax
    DrawProgressBar obj.progressBarGradG, 165, 122, 100, 16, rocket.genValue / rocket.genMax
    
    SText odc, 265, 152, rocket.GetSlotName(FrontGun), 2, &HA0A0D0
    SText odc, 265, 172, rocket.GetSlotName(LeftGun), 2, &HA0A0D0
    SText odc, 265, 192, rocket.GetSlotName(RightGun), 2, &HA0A0D0
    SelectObject odc, obj.tableFontNum
    fColor = &HF0F0F0
    If rocket.credit <> lastCredit Then changeColor = 5
    lastCredit = rocket.credit
    If changeColor > 0 Then
        fColor = &HF0F0&
        changeColor = changeColor - 1
    End If
    SText odc, 265, 219, "$ " & NumSpac(rocket.credit), 2, fColor
    SText odc, OSD_WIDTH - 10, 560, Format(time, "h:mm"), 2, &HC0C0C0, &H605040
    
    ' messages
    cnt = 0
    SetTextAlign odc, TA_LEFT
    Set m = obj.GetMessages
    If Not m Is Nothing Then
        While Not m Is Nothing
            cnt = cnt + 1
            SelectObject odc, obj.mFont
            If m.bold Then SelectObject odc, obj.mFontB
            If m.italic Then SelectObject odc, obj.mFontI
            If m.underlined Then SelectObject odc, obj.mFontU
            If m.bold And m.underlined Then SelectObject odc, obj.mFontBU
            If m.bold And m.italic Then SelectObject odc, obj.mFontBI
            If m.italic And m.underlined Then SelectObject odc, obj.mFontIU
            text odc, 13, 300 + cnt * 18, m.GetText, m.color
            Set m = m.nxt
        Wend
    End If
    
    'status
    If Len(info) > 0 Then
        SelectObject odc, obj.smallFont
        text odc, 10, OSD_HEIGHT - 20, info, &HFFFFFF
        If Not displayComCenter Then text odc, 10, OSD_HEIGHT - 35, "Time: " & elapsed, &HFFFFFF
    End If
    
    Set b = obj.GetButtons
    While Not b Is Nothing
        If b.domain = OSD And b.display Then
            DrawButton odc, gm, b
        End If
        Set b = b.nxt
    Wend
    
    If rocket.fire Then
        SelectObject odc, obj.osdFont
        SText odc, 15, 250, "Fire On", 2, &H9090FF, &H605040
    End If
    
    MaskBlt hdc, SCR_WIDTH, 0, OSD_WIDTH, OSD_HEIGHT, odc, 0, 0, 0, 0, 0, SRCCOPY
End Sub


Private Sub CCenterPaint(Optional dummy As Boolean = False)
    Call cCenter.PaintBack(BDC)
    Call cCenter.Paint(BDC)
    Dim b As Button
    Set b = obj.GetButtons
    While Not b Is Nothing
        If b.domain = CommandCenter And b.display Then
            If rocket.score >= b.score Then
                Call DrawButton(BDC, g, b)
            End If
        End If
        Set b = b.nxt
    Wend
    If rocket.shield < rocket.shieldMax Then
        rocket.shield = Round(rocket.shield + 1)
        updateOSD = True
    End If
    
    Call MaskBlt(hdc, 0, 0, SCR_WIDTH, SCR_HEIGHT, BDC, 0, 0, 0, 0, 0, SRCCOPY)
End Sub


Private Sub GenerateBeamGrad(dt As DevType)
    Dim steps As Long
    Dim step As Long
    Dim i As Integer
    Dim c As Long
    Dim p As LongPtr

    steps = Int(dt.seqs / 2)
    step = Round(256 / steps)
    Dim a() As LongPtr
    ReDim a(0 To dt.seqs + 1) As LongPtr
    For i = 0 To steps
        c = i * step
        'p = CreatePen(PS_SOLID, 1, 65536 * c + 256 * c + c)
        p = CreatePen(PS_SOLID, 1, 256 * CLng((i / steps) * step) + i * step)
        a(i) = p
        a(dt.seqs + 1 - i) = p
    Next i
    grad = a
End Sub


Private Sub DrawBeam(d As Device, Optional ByVal fat As Boolean = False)
    SelectObject BDC, grad(d.beamActive)
    BeginPath BDC
    MoveToEx BDC, d.sx, d.sy, 0
    LineTo BDC, d.dx, d.dy
    EndPath BDC
    StrokePath BDC
    If fat Then
        SelectObject BDC, grad(d.beamActive - 1)
        BeginPath BDC
        MoveToEx BDC, d.sx - 1, d.sy, 0
        LineTo BDC, d.dx - 1, d.dy
        MoveToEx BDC, d.sx + 1, d.sy, 0
        LineTo BDC, d.dx + 1, d.dy
        EndPath BDC
        StrokePath BDC
    End If
End Sub


Private Sub WPaint()
    Static co As Collectable
    Static h As Hostile
    Static f As Fleet
    Static dv As Device
    Static pr As Projectile
    Static st As Structure
    Static ex As Explosion
    Static ft As FloatText
    Static x As Integer
    Static t As Variant
    Static tex As LongPtr
    
    BeginPath BDC
    SelectObject BDC, obj.blackBrush
    Rectangle BDC, 0, 0, SCR_WIDTH + 1, SCR_HEIGHT + 1
    EndPath BDC
    FillPath BDC
    
    Set ft = obj.GetTexts
    SetTextAlign BDC, TA_CENTER
    While Not ft Is Nothing
        SelectObject BDC, ft.font
        If ft.stationary Then
            SText BDC, SCR_WIDTH / 2, 400, ft.text, 2, ft.color, ft.shadowColor
        Else
            SText BDC, ft.trace.current.x, ft.trace.current.y, ft.text, 2, ft.color, ft.shadowColor
        End If
        Set ft = ft.nxt
    Wend

    For x = 1 To starCount
        If starField(x).y < SCR_HEIGHT Then
            If starField(x).x > -10 And starField(x).x < SCR_WIDTH Then DrawImage BDC, g, starField(x)
        End If
    Next x
    
    If Not currentSector Is Nothing Then
        ' Structures
        Set st = currentSector.fStruct
        While Not st Is Nothing
            If st.img.drawInLoop Then
                If st.enTime <= elapsed Then
                    If st.hit > 0 Then st.hit = st.hit - 1
                    If st.hit > 0 Then
                        DrawImage BDC, g, st.img
                        Call SelectObject(tmpDC, st.img.hMask)
                        Call MaskBlt(BDC, Round(st.img.x), Round(st.img.y), st.img.width, st.img.height, tmpDC, 0, 0, 0, 0, 0, SRCPAINT)
                    Else
                        DrawImage BDC, g, st.img
                    End If
                    If st.hp < st.hpMax And st.hp > 0 And st.img.y > 0 Then
                        ' Show struct health
                        SelectObject BDC, obj.greenBrush
                        BeginPath BDC
                        Rectangle BDC, Round(st.img.x) + 2, _
                                        Round(st.img.y - 1), _
                                        Round(st.img.x) + 2 + Round((st.img.width - 4) * (st.hp / st.hpMax)), _
                                        Round(st.img.y - 4)
                        EndPath BDC
                        FillPath BDC
                        SelectObject BDC, obj.greenPen
                        BeginPath BDC
                        Rectangle BDC, Round(st.img.x), Round(st.img.y), st.x2, Round(st.img.y - 6)
                        EndPath BDC
                        StrokePath BDC
                    End If
                End If
            End If
            Set st = st.nxt
        Wend
        ' Fleets
        Set f = currentSector.fFleet
        While Not f Is Nothing
            If f.active Then
                Call f.ResetArea
                Set h = f.lHost
                While Not h Is Nothing
                    If h.img.drawInLoop Then
                        If h.hit = 2 Then
                            DrawImage BDC, g, h.img
                            Call SelectObject(tmpDC, h.img.hMask)
                            Call MaskBlt(BDC, Round(h.img.x), Round(h.img.y), h.img.width, h.img.height, tmpDC, 0, 0, 0, 0, 0, SRCPAINT)
                        Else
                            DrawImage BDC, g, h.img
                        End If
                        If h.hit > 0 Then h.hit = h.hit - 1
                        If f.showDamage Then
                            ' Show unit health
                            If h.hp < h.hpMax And h.hp > 0 And h.img.y > 1 Then
                                SelectObject BDC, obj.greenBrush
                                BeginPath BDC
                                Rectangle BDC, Round(h.img.x) + 2, _
                                                Round(h.img.y - 1), _
                                                Round(h.img.x) + 2 + Round((h.img.width - 4) * (h.hp / h.hpMax)), _
                                                Round(h.img.y - 4)
                                EndPath BDC
                                FillPath BDC
                                SelectObject BDC, obj.greenPen
                                BeginPath BDC
                                Rectangle BDC, Round(h.img.x), Round(h.img.y), h.x2, Round(h.img.y - 6)
                                EndPath BDC
                                StrokePath BDC
                            End If
                        End If
                        If f.minx > h.img.x Then f.minx = h.img.x
                        If f.maxx < h.x2 Then f.maxx = h.x2
                        If f.miny > h.img.y Then f.miny = h.img.y
                        If f.maxy < h.y2 Then f.maxy = h.y2
                    End If
                    Set h = h.prv
                Wend
                If Not f.weap Is Nothing Then
                    Set pr = f.weap.fProjectile
                    While Not pr Is Nothing
                        DrawImage BDC, g, pr.img
                        Set pr = pr.nxt
                    Wend
                End If
            End If
            Set f = f.nxt
        Wend
    End If
    
    ' Mark target
    If VarType(rocket.closestEnemy) = vbObject Then
        Set t = rocket.closestEnemy
        If Not t Is Nothing Then
            SelectObject BDC, obj.grayPen
            BeginPath BDC
            MoveToEx BDC, t.img.x - 4, t.img.y + 6, 0
            LineTo BDC, t.img.x - 4, t.img.y - 4
            LineTo BDC, t.img.x + 6, t.img.y - 4
            MoveToEx BDC, t.x2 - 6, t.img.y - 4, 0
            LineTo BDC, t.x2 + 4, t.img.y - 4
            LineTo BDC, t.x2 + 4, t.img.y + 6
            MoveToEx BDC, t.x2 + 4, t.y2 - 6, 0
            LineTo BDC, t.x2 + 4, t.y2 + 4
            LineTo BDC, t.x2 - 6, t.y2 + 4
            MoveToEx BDC, t.img.x + 6, t.y2 + 4, 0
            LineTo BDC, t.img.x - 4, t.y2 + 4
            LineTo BDC, t.img.x - 4, t.y2 - 6
            EndPath BDC
            StrokePath BDC
        End If
    End If
    
    Set dv = rocket.GetDevices
    While Not dv Is Nothing
        If dv.beamActive > 0 Then
            If dv.slot = FrontGun Then
                DrawBeam dv, True
            Else
                DrawBeam dv
            End If
            dv.beamActive = dv.beamActive - 1
        Else
            Set pr = dv.fProjectile
            While Not pr Is Nothing
                DrawImage BDC, g, pr.img
                Set pr = pr.nxt
            Wend
        End If
        Set dv = dv.nxt
    Wend
    
    Set co = obj.GetColls
    While Not co Is Nothing
        If co.img.drawInLoop Then DrawImage BDC, g, co.img
        Set co = co.nxt
    Wend
    
    Set ex = obj.fExp
    While Not ex Is Nothing
        DrawImage BDC, g, ex.img
        Set ex = ex.nxt
    Wend
    
    If rocket.dmgTaken > 0 Then
        SelectObject BDC, obj.redPen
        BeginPath BDC
        Rectangle BDC, 1, 1, SCR_WIDTH - 1, SCR_HEIGHT - 1
        EndPath BDC
        StrokePath BDC
        rocket.dmgTaken = rocket.dmgTaken - 1
    End If
    
    DrawImage BDC, g, rocket.img
    
    i = i + d
    If i >= 20 Or i <= 1 Then d = d * (-1)
    
    'tex = tx.tex
    's = GdipRotateTextureTransform(tex, 0.5, MatrixOrderAppend)
    'tx.tex = tex
    'PlaceTexture tx
    MaskBlt hdc, 0, 0, SCR_WIDTH, SCR_HEIGHT, BDC, 0, 0, 0, 0, 0, SRCCOPY
End Sub



' ----------------------------------------------------------------------------------------------------------------------
' ----------------------------------------------------------------------------------------------------------------------
' ----------------------------------------------------------------------------------------------------------------------


Private Sub MoveStars(Optional ByVal s As Single = 0.5)
    Static tmp As Single
    Static n As Integer
    
    For n = 1 To starCount
        With starField(n)
            .y = .y + .cust
            If .y < SCR_HEIGHT Then
                tmp = .cust / 3
                If .x < (SCR_WIDTH / 2) Then tmp = -tmp
                .x = .x + tmp
            End If
            If .y > starFieldHeight Then
                .x = .startX
                If .cust < 0.25 And Abs(.x - SCR_WIDTH / 2) < 200 And Rnd < 0.5 Then
                    .y = SCR_HEIGHT * Rnd * 0.8
                Else
                    .y = -.height
                End If
            End If
        End With
    Next n
End Sub


' ----------------------------------------------------------------------------------------------------------------------
' ------------------------------------------[   C O N T R O L S   ]-----------------------------------------------------
' ----------------------------------------------------------------------------------------------------------------------


Private Sub OnMouseMove(Optional mouseX As Integer = 0)
    Static devi As Device
    Static b As Button
    Static bx As Integer
    Static bx2 As Integer
    Static a As Integer
    
    Set b = obj.GetButtons
    While Not b Is Nothing
        If b.display Then
            bx = b.x
            bx2 = b.x2
            If b.param2 > 0 Then
                a = 0 - (cCenter.wPage - 1) * cCenter.pageSize
                If a <> 0 Then
                    bx = bx + 180 * a
                    bx2 = bx + b.w
                End If
            End If
        
            If (displayComCenter And b.domain = CommandCenter) Or b.domain = OSD Then
                If mx > bx And mx < bx2 And my > b.y And my < b.y2 Then
                    b.over = True
                    updateOSD = True
                Else
                    If b.over Then updateOSD = True
                    b.over = False
                End If
            End If
        End If
        Set b = b.nxt
    Wend
    If displayComCenter Then
        If mx > textFieldx1 And mx < textFieldx2 And my > textFieldy1 And my < textFieldy2 Then
            If textFieldEdit = 0 Then textFieldEdit = 1
        Else
            If textFieldEdit = 1 Then textFieldEdit = 0
        End If
    End If
End Sub


Private Sub OnLeftUp(Optional mouseX As Integer = 0)
On Error GoTo err
    Static sta As String
    Static b As Button
    
    sta = "GetButtons"
    Set b = obj.GetButtons
    While Not b Is Nothing
        If b.over And b.pressed And b.display Then
            Select Case b.ac
                Case Buy
                    sta = "Buy"
                    Dim dt As DevType
                    Set dt = cCenter.GetDevType(b.param)
                    If dt.price <= rocket.credit Then
                        Dim r As Single
                        Dim sl As Slots
                        sl = NotAvailable
                        r = 1
                        Select Case b.param
                            Case "Bubble Gun"
                                If rocket.GetSlotDevice(FrontGun) Is Nothing Then sl = FrontGun
                                r = 1
                            Case "Small Bubble"
                                If rocket.GetSlotDevice(RightGun) Is Nothing Then sl = RightGun
                                If rocket.GetSlotDevice(LeftGun) Is Nothing Then sl = LeftGun
                                r = 0.5
                            Case "Vulcan Cannon"
                                If rocket.GetSlotDevice(FrontGun) Is Nothing Then sl = FrontGun
                            Case "Small Vulcan"
                                If rocket.GetSlotDevice(RightGun) Is Nothing Then sl = RightGun
                                If rocket.GetSlotDevice(LeftGun) Is Nothing Then sl = LeftGun
                                r = 0.7
                            Case "Star Gun"
                                If rocket.GetSlotDevice(RightGun) Is Nothing Then sl = RightGun
                                If rocket.GetSlotDevice(LeftGun) Is Nothing Then sl = LeftGun
                                r = 0.5
                            Case "Blaster"
                                If rocket.GetSlotDevice(FrontGun) Is Nothing Then sl = FrontGun
                                r = 0.5
                            Case "Laser"
                                If rocket.GetSlotDevice(FrontGun) Is Nothing Then sl = FrontGun
                                r = 1
                            Case "Small Laser"
                                If rocket.GetSlotDevice(RightGun) Is Nothing Then sl = RightGun
                                If rocket.GetSlotDevice(LeftGun) Is Nothing Then sl = LeftGun
                                r = 0.5
                            Case Else
                                Call obj.CreateMessage("Unknown device " & b.param)
                        End Select
                        If sl = NotAvailable Then
                            Call obj.CreateMessage("Slot not available")
                        Else
                            Call rocket.SetupDevice(b.param, sl, r)
                            rocket.credit = rocket.credit - dt.price
                        End If
                    Else
                        Call obj.CreateMessage("Low credit. You need $ " & NumSpac(dt.price))
                    End If
                    
                Case Continue
                    sta = "Continue"
                    saved = False
                    rocket.fire = False
                    textFieldEdit = 0
                    rocket.pilotName = NormalizePilotName(rocket.pilotName)
                    If rocket.CalculateDPS = 0 Then
                        obj.CreateMessage "Can't start. No weapon !", FONT_BOLD Or FONT_ITALIC
                    Else
                        Set currentSector = obj.GetLastIncompleteSector()
                        Set obj.fMessage = Nothing
                        rocket.ResetDevices
                        displayComCenter = False
                        ActivateButtons Screen
                        If osdFocus Then
                            rocket.AdjustPosition SCR_WIDTH, my, instantMove
                        Else
                            rocket.AdjustPosition mx, my, instantMove
                        End If
                        BeginPath BDC
                        SelectObject BDC, obj.blackBrush
                        Rectangle BDC, 0, 0, SCR_WIDTH + 1, SCR_HEIGHT + 1
                        EndPath BDC
                        FillPath BDC
                        If currentSector Is Nothing Then
                            obj.CreateSector (obj.lastSectorNumber + 1) & ": Unknown sector"
                            Set currentSector = obj.GetLastIncompleteSector()
                            currentSector.SetupRandom
                        Else
                            currentSector.Setup
                        End If
                        rocket.lvlNum = currentSector.level
                        startTime = Timer - pausedTime
                    End If
                    
                Case ExitApp
                    sta = "ExitApp"
                    SaveScore rocket.pilotName, rocket.score, rocket.lvlNum
                    exiting = True
                    
                Case NextPage
                    cCenter.NextPage
                    
                Case Sell
                    rocket.Sell b.param
                    
                Case Upgrade
                    Dim d As Device
                    Set d = rocket.GetSlotDevice(b.param)
                    If Not d Is Nothing Then
                        If d.level < MAX_WEAP_LEV Then
                            If rocket.credit >= d.upgCost * d.price Then
                                rocket.AddCredit d.price
                                Call d.Upgrade
                                rocket.credit = rocket.credit - d.price
                                If d.pwrGen = 0 Then
                                    If Round(d.cooldown) < d.seqs Then Logt "Weapon error: Cooldown smaller then Seq: " & d.name
                                End If
                            Else
                                Dim np As Long
                                np = Round(d.price * (1 + d.upgCost))
                                Call obj.CreateMessage("Low credit. You need $ " & NumSpac(np - d.price))
                            End If
                        Else
                            Call obj.CreateMessage("Max. level reached !")
                        End If
                    Else
                        Call obj.CreateMessage("Device no." & b.param & " not installed")
                    End If
                Case Else
            End Select
            b.pressed = False
        End If
        updateOSD = True
        Set b = b.nxt
    Wend
    
    sta = "textField"
    If displayComCenter Then
        If mx > textFieldx1 And mx < textFieldx2 And my > textFieldy1 And my < textFieldy2 Then
            If textFieldEdit = 1 Then textFieldEdit = 2
        Else
            textFieldEdit = 0
            rocket.pilotName = NormalizePilotName(rocket.pilotName)
        End If
    Else
        rocket.fire = Not rocket.fire
    End If
    
    Exit Sub
err:
    Logt "MBL: " & sta & ": " & Error
    obj.CreateMessage "MBL: " & sta & ": " & Error, FONT_ITALIC
End Sub


Private Sub OnMouseButton(Optional dummy As Boolean = False)
    Static b As Button
    
    Set b = obj.GetButtons
    If mbutt And MB_LEFT Then
        While Not b Is Nothing
            If b.over And b.display Then
                b.pressed = (mbutt And MB_LEFT)
                updateOSD = True
            End If
            Set b = b.nxt
        Wend
    End If
    
    If mbutt And MB_RIGHT Then
    End If
    
    If mbutt And MB_MIDDLE Then
    End If
    
End Sub


Public Sub ActivateButtons(ByVal dom As ButtonDomain)
    Dim b As Button
    Set b = obj.GetButtons
    While Not b Is Nothing
        If b.domain = dom Or b.domain = OSD Then b.display = True Else b.display = False
        Set b = b.nxt
    Wend
End Sub


Public Static Sub levelAction(ByVal dummy As Boolean)
    Dim lastLevel As Long
    If Not currentSector Is Nothing Then
        If lastLevel <> currentSector.level Then
            lastLevel = currentSector.level
            If lastLevel = 3 Then
                
            End If
            If lastLevel = 8 Then
            End If
        End If
    End If
End Sub

' -------
Private Function TimerProc() As Long
    Logt "Timer"
    exiting = True
End Function


Private Function TryAdd(ByVal fname As String, ByVal itemName As String, ByVal altItemName As String, _
        ByVal layNum As Integer, ByVal ratio As Single)
    Dim ti As Image
    Dim cmask As Boolean
    cmask = False
    Set ti = LoadImg(fname)
    If ti Is Nothing Then
        Set ti = CopyImage(imgLib.GetItem(altItemName), -200, -200, 0, ratio, True, layNum)
    Else
        cmask = True
    End If
    Call imgLib.AddItem(itemName, ti, False, cmask)
End Function

' ----------------------------------------------------------------------------------------------------------------------
' ------------------------------------------[    W I N D O W   P R O C    ]---------------------------------------------
' ----------------------------------------------------------------------------------------------------------------------
Private Function WindowProc(ByVal hwnd As LongPtr, ByVal uMsg As Long, ByVal wParam As LongPtr, ByVal lParam As LongPtr) As LongPtr
On Error GoTo err
    Static sta As String
    Static dev As Device
    
    sta = "uMsg=" & uMsg
    Select Case uMsg
        Case WM_CREATE
            Dim n As Integer
            Dim m As Integer
            Dim timg As Image
            
            sta = "WM_CREATE"
            SetFormLabel "Starting (Init)"
            test = False
            hdc = GetDC(hwnd)
            tmpDC = CreateCompatibleDC(hdc)
            obj.PreInit
            IsCursor = True
            Randomize
            textFieldx1 = 250
            textFieldy1 = 510
            textFieldx2 = 550
            textFieldy2 = 550
            textFieldEdit = 0
            LAYERS = Array(&H20FF0000, &H200000FF, &H20FFFF00, &H0&, &H50D0D000, _
                        &H2810FF10, &H5510FF10, &H381040FF, &H701040FF, &H30FF1010, &H60FF1010)
            ROMNUM = Array("", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII", "XIII", "XIV", "XV", _
                            "XVI", "XVII", "XVIII", "XIX", "XX", "XXI", "XXII", "XXIII", "XXIV", "XXV")
            Dim f As Variant
            Dim sz As Long
            SetFormLabel "Starting (File)"
            Set fStream = CreateObject("Scripting.FileSystemObject")
            Set f = fStream.GetFile(imgDir + STATE_FILE_NAME)
            sz = f.size
            Set f = fStream.OpenTextFile(imgDir + STATE_FILE_NAME, 1, False)
            If Not f Is Nothing Then
                fState = f.Read(sz)
                f.Close
                If Len(fState) > 0 Then ParseFileState (fState)
            End If
            
            ib.GdiplusVersion = 2
            ib.SuppressBackgroundThread = 0
            ib.SuppressExternalCodecs = 0
            s = GdiplusStartup(token, ib, 0)
            Call SetStretchBltMode(hdc, STRETCH_HALFTONE)
            s = GdipCreateFromHDC(hdc, g)
            s = GdipSetCompositingQuality(g, QualityMode.QualityModeHigh)
            Call obj.Init(hwnd)
            
            sta = "WM_CREATE: Load"
            SetFormLabel "Starting (Load images)"
            Call imgLib.AddItem("btnCloseDown", GdipLoadImg("btn_close_down.png"))
            Call imgLib.AddItem("btnCloseUp", GdipLoadImg("btn_close_up.png"))
            Call imgLib.AddItem("btnCloseOver", GdipLoadImg("btn_close_over.png"))
            Call imgLib.AddItem("puddleJumper", LoadImg("vessel.bmp"))
            Call imgLib.AddItem("aster0", LoadImg("asteroid.bmp"), False, True)
            Call imgLib.AddItem("aster1", LoadImg("asteroid1.bmp"), False, True)
            Call imgLib.AddItem("aster2", LoadImg("asteroid2.bmp"), False, True)
            Call imgLib.AddItem("aster3", LoadImg("asteroid3.bmp"), False, True)
            Call imgLib.AddItem("rodo", LoadImg("Rododendron.bmp"), False, False)
            'Call imgLib.AddItem("rodo", GdipLoadImg("Rododendron.bmp", SCR_WIDTH / 2, SCR_HEIGHT / 2))
            'Set tx = CreateTexture(imgLib.GetItem("rodo"))
            
            Call imgLib.AddItem("falcon", LoadImg("falcon.bmp"))
            TryAdd "falcon1.bmp", "falcon1", "falcon", 5, 1.01
            TryAdd "falcon2.bmp", "falcon2", "falcon", 6, 1.01
            TryAdd "falcon3.bmp", "falcon3", "falcon", 7, 1.01
            TryAdd "falcon4.bmp", "falcon4", "falcon", 8, 1.01
            TryAdd "falcon5.bmp", "falcon5", "falcon", 9, 1.01
            TryAdd "falcon6.bmp", "falcon6", "falcon", 10, 1.01
            TryAdd "falconx.bmp", "falconx", "falcon", 3, 1.5
            TryAdd "falconx2.bmp", "falconx2", "falconx", 5, 1.01
            TryAdd "falconx3.bmp", "falconx3", "falconx", 7, 1.01
            TryAdd "falconxb.bmp", "falconxb", "falconx", 6, 1.2
            TryAdd "falconxt.bmp", "falconxt", "falconx", 8, 1.33
            Call imgLib.AddItem("bouncer", LoadImg("bouncer.bmp"))
            Call imgLib.AddItem("bubble", LoadImg("bubble.bmp"))
            Call imgLib.AddItem("vulcan", LoadImg("vulcan.bmp"))
            Call imgLib.AddItem("blaster", LoadImg("blaster.bmp"))
            Call imgLib.AddItem("laser", LoadImg("laser.bmp"))
            Call imgLib.AddItem("starg", LoadImg("starg.bmp"))
            ' same square dimensions expected for all
            Call imgLib.AddItem("explo1", LoadImg("explosion1.bmp"))
            Call imgLib.AddItem("explo2", LoadImg("explosion2.bmp"))
            Call imgLib.AddItem("explo3", LoadImg("explosion3.bmp"))
            Call imgLib.AddItem("explo4", LoadImg("explosion4.bmp"))
            
            ' create star field
            sta = "WM_CREATE: Stars"
            SetFormLabel "Starting (Stars)"
            Call imgLib.AddItem("star", LoadImg("star.bmp", -1, -1))
            Dim cma As Double
            cma = 0
            Dim x As Long, y As Long, c As Single, r As Single, high As Single, low As Single
            For n = 1 To STAR_COUNT
                x = Int(SCR_WIDTH * Rnd - 2)
                y = Int(3 * SCR_HEIGHT * Rnd + 1)
                r = Abs((x - SCR_WIDTH / 2) / SCR_WIDTH * 1.85) * Rnd + 0.35
                c = 3 * r * r 'speed
                'c = 3 * Rnd + 0.35
                If c < 2.5 Then c = c / 2
                If c < 0.01 Then c = 0.01
                If c > high Then high = c
                If c < low Then low = c
                If Rnd < 0.05 Then r = 0.7 + Rnd * 0.3
                If r > 1 Then r = 1
                Set starField(n) = CopyImage(imgLib.GetItem("star"), x, y, c, r, True)
                starField(n).startX = x
                starField(n).startY = y
            Next n
            
            sta = "WM_CREATE: Explosions"
            For n = 1 To EXPLOSION_VAR
                Set timg = imgLib.GetItem("explo" & n)
                For m = 1 To EXPLOSION_STEPS
                    Set explosions(n, m) = CopyImage(timg, -100, -100, 0, m / EXPLOSION_STEPS, False)
                Next m
            Next n
            obj.InitExpOffsets
            
            sta = "WM_CREATE: Init graphics"
            ltime = timeGetTime()
            i = 1
            d = 1
            avg = 0
            ticks = 0
            mx = WND_WIDTH / 2
            my = WND_HEIGHT / 2
            BDC = CreateCompatibleDC(hdc)
            bmp = CreateCompatibleBitmap(hdc, WND_WIDTH, WND_HEIGHT)
            Call SelectObject(BDC, bmp)
            s = GdipCreateFromHDC(BDC, g)
            odc = CreateCompatibleDC(hdc)
            osdBmp = CreateCompatibleBitmap(hdc, OSD_WIDTH, OSD_HEIGHT)
            Call SelectObject(odc, osdBmp)
            s = GdipCreateFromHDC(odc, gm)
                        
            SetFormLabel "Starting (Generate)"
            sta = "WM_CREATE: OSD"
            osdBDC = CreateOSD()
            sta = "WM_CREATE: CCenter"
            Call cCenter.CreateCC(hdc)
            Call SetBkMode(BDC, TRANSPARENT)
            Call SetBkMode(odc, TRANSPARENT)
            Call timeBeginPeriod(1)
            
            sta = "WM_CREATE: Objects"
            
            Call GenerateBeamGrad(cCenter.GetDevType("Laser"))
            Set timg = obj.GetAsteroid
            Call rocket.Init(SCR_WIDTH, SCR_HEIGHT, "puddleJumper", obj)
            Dim im As Image
            Set im = imgLib.GetItem("btnCloseDown")
            Call obj.CreateButton(OSD, ExitApp, OSD_WIDTH - im.width - 8, 0, 6)
            Call obj.GetLastButton().Load("btnCloseDown", "btnCloseUp", "btnCloseOver")
            Call obj.CreateButton(CommandCenter, Continue, SCR_WIDTH - 121 - 20, SCR_HEIGHT - 37 - 20)
            Set tb = obj.GetLastButton
            Call CreateButtonImages(obj.GetLastButton(), 102, 35, "Play", obj.osdFont)
            
            Call obj.CreateButton(CommandCenter, Buy, 660, 340, "Bubble Gun", 1, 0)
            Call CreateButtonImages(obj.GetLastButton(), 120, 36, "Buy", obj.osdFont)
            Call obj.CreateButton(CommandCenter, Buy, 660, 590, "Small Bubble", 1, 0)
            Call CreateButtonImages(obj.GetLastButton(), 120, 36, "Buy", obj.osdFont)
            Call obj.CreateButton(CommandCenter, Buy, 840, 340, "Vulcan Cannon", 2, rocket.WepLevScores(1))
            Call CreateButtonImages(obj.GetLastButton(), 120, 36, "Buy", obj.osdFont)
            Call obj.CreateButton(CommandCenter, Buy, 840, 590, "Small Vulcan", 2, rocket.WepLevScores(1))
            Call CreateButtonImages(obj.GetLastButton(), 120, 36, "Buy", obj.osdFont)
            Call obj.CreateButton(CommandCenter, Buy, 1020, 340, "Blaster", 3, rocket.WepLevScores(2))
            Call CreateButtonImages(obj.GetLastButton(), 120, 36, "Buy", obj.osdFont)
            Call obj.CreateButton(CommandCenter, Buy, 1020, 590, "Star Gun", 3, rocket.WepLevScores(2))
            Call CreateButtonImages(obj.GetLastButton(), 120, 36, "Buy", obj.osdFont)
            Call obj.CreateButton(CommandCenter, Buy, 1200, 340, "Laser", 4, rocket.WepLevScores(3))
            Call CreateButtonImages(obj.GetLastButton(), 120, 36, "Buy", obj.osdFont)
            Call obj.CreateButton(CommandCenter, Buy, 1200, 590, "Small Laser", 4, rocket.WepLevScores(3))
            Call CreateButtonImages(obj.GetLastButton(), 120, 36, "Buy", obj.osdFont)
            If cCenter.nPages > 1 Then
                Call obj.CreateButton(CommandCenter, NextPage, 620, 660, "NxtPg", 0, 0)
                Call CreateButtonImages(obj.GetLastButton(), 70, 36, "Next", obj.osdFont)
            End If
            
            'obj.CreateButton CommandCenter, Upgrade, 500, 164, "Vessel"
            'CreateButtonImages obj.GetLastButton(), 76, 22, "Upgrade", obj.mFont
            Call obj.CreateButton(CommandCenter, Sell, 410, 251, FrontGun)
            Call CreateButtonImages(obj.GetLastButton(), 56, 22, "Sell", obj.mFont)
            Call obj.CreateButton(CommandCenter, Sell, 410, 274, LeftGun)
            Call CreateButtonImages(obj.GetLastButton(), 56, 22, "Sell", obj.mFont)
            Call obj.CreateButton(CommandCenter, Sell, 410, 297, RightGun)
            Call CreateButtonImages(obj.GetLastButton(), 56, 22, "Sell", obj.mFont)
            
            Call obj.CreateButton(CommandCenter, Upgrade, 480, 251, FrontGun)
            Call CreateButtonImages(obj.GetLastButton(), 76, 22, "Upgrade", obj.mFont)
            Call obj.CreateButton(CommandCenter, Upgrade, 480, 274, LeftGun)
            Call CreateButtonImages(obj.GetLastButton(), 76, 22, "Upgrade", obj.mFont)
            Call obj.CreateButton(CommandCenter, Upgrade, 480, 297, RightGun)
            Call CreateButtonImages(obj.GetLastButton(), 76, 22, "Upgrade", obj.mFont)
            
            Call obj.CreateButton(CommandCenter, Upgrade, 480, 338, Generator)
            Call CreateButtonImages(obj.GetLastButton(), 76, 22, "Upgrade", obj.mFont)
            startTime = Timer
            Restart = False
            mbutt = 0
            displayComCenter = True
            avg = 0
            starCount = 70
            lastShowFPSTime = 0
            pausedTime = 0
            pauseStartTime = 0
            pause = False
            If test Then
                rocket.credit = 2000905744
                rocket.score = rocket.WepLevScores(3)
                rocket.NextWeaponLevel = 4
            End If
            obj.CreateMessage "Press SPACE to Hide / Show window", FONT_ITALIC, &HD0E0F0, 45
            rocket.pilotName = initPilotName
            If Not cCenter Is Nothing Then cCenter.FillStrCache
            Set currentSector = obj.GetLastIncompleteSector()
            Logt "Initialized at " & time, True
            If test Then Logt "Test Mode On"
            
        Case WM_ERASEBKGND
            WindowProc = 0
            Exit Function
            
        Case WM_TIMER
            Logt "WMTimer", False
            exiting = True
            
        Case WM_PAINT
            If exiting Then
                Call DestroyWindow(hwnd)
            Else
                If Not pause Then
                    ts = timeGetTime()
                    elapsed = Timer - startTime - pausedTime
                    If Not displayComCenter And lastElVal <> elapsed Then
                        lastElVal = elapsed
                        If Not currentSector Is Nothing Then
                            currentSector.TimedAction elapsed
                        End If
                    End If
                    dt = ts - ltime
                    If Not displayComCenter Then
                        If osdFocus Then
                            rocket.AdjustPosition SCR_WIDTH, my, instantMove
                        Else
                            rocket.AdjustPosition mx, my, instantMove
                        End If
                    End If
                    If dt >= FRAME_DELAY Then
                        ltime = ts
                        If displayComCenter Then
                            If Restart Then
                                Set obj.fMessage = Nothing
                                Set obj.fText = Nothing
                                obj.ShowScore
                                SaveScore rocket.pilotName, rocket.score, rocket.lvlNum
                                obj.InitSectors
                                rocket.ResetVessel
                                Restart = False
                            End If
                            Call CCenterPaint
                            lastShowFPSTime = 0
                        Else
                            sta = "MoveStars"
                            MoveStars
                            sta = "rocket.step()"
                            rocket.step
                            sta = "obj.step()"
                            obj.step
                            sta = "WPaint"
                            WPaint
                            sta = "fire"
                            If rocket.fire Then
                                Set dev = rocket.GetDevices
                                While Not dev Is Nothing
                                    If dev.pwrNeed <= rocket.genValue Then Call dev.Create
                                    Set dev = dev.nxt
                                Wend
                            End If
                        End If
                        sta = "OSD"
                        ts = timeGetTime()
                        avg = (avg * ticks + (ts - ltime)) / (ticks + 1)
                        If avg < 9 Then instantMove = False Else instantMove = True
                        If avg <= 13 Then
                            If starCount < STAR_COUNT Then starCount = starCount + 5
                            lastShowFPSTime = elapsed + 3
                        End If
                        If avg >= 17 And Not displayComCenter Then
                            If starCount >= 20 Then starCount = starCount - 10
                            lastShowFPSTime = elapsed + 3
                        End If
                        If ticks < 30 Then ticks = ticks + 1
                        If i = 1 Or ticks = 1 Or updateOSD Then
                            If updateOSD Then updateOSD = False
                            If lastShowFPSTime > elapsed Then
                                OSDPaint "Frame time = " & Round(avg * 10) / 10 & " ms  ( " & starCount & " stars )"
                            Else
                                OSDPaint
                            End If
                        End If
                        sta = "mouse"
                        If mbutt > 0 And mx < SCR_WIDTH Then OnMouseButton
                        's = GdipFlush(g, FlushIntention.FlushIntentionSync)
                        GdiFlush
                    End If
                End If
            End If
            
        Case WM_MOUSEMOVE
            CopyMemory mx, ByVal VarPtr(lParam), 2
            CopyMemory my, ByVal VarPtr(lParam) + 2, 2
            If Not rocket.img Is Nothing Then
                If mx < SCR_WIDTH Then
                    If Not displayComCenter Then
                        mx = mx - rocket.imgOffX
                        my = my - rocket.imgOffY
                    End If
                    osdFocus = False
                    If displayComCenter Then ShowCur Else HideCur
                Else
                    mx = mx - SCR_WIDTH
                    osdFocus = True
                    Call ShowCur
                End If
            End If
            Call OnMouseMove
            
        Case WM_SETCURSOR
            WindowProc = DefWindowProc(hwnd, uMsg, wParam, lParam)
            Exit Function
            
        Case WM_LBUTTONDOWN
            mbutt = mbutt Or MB_LEFT
            updateOSD = True
        
        Case WM_LBUTTONUP
            mbutt = mbutt And 6
            OnLeftUp
            
        Case WM_RBUTTONDOWN
            mbutt = mbutt Or MB_RIGHT
            
        Case WM_RBUTTONUP
            mbutt = mbutt And 5
            
        Case WM_MBUTTONDOWN
            mbutt = mbutt Or MB_MIDDLE
            
        Case WM_MBUTTONUP
            mbutt = mbutt And 3
            
        Case WM_NCHITTEST
            WindowProc = DefWindowProc(hwnd, uMsg, wParam, lParam)
            Exit Function
            
        Case WM_KEYUP
            If wParam = 32 And textFieldEdit < 2 Then
                pause = Not pause
                If pause Then
                    ShowCur
                    pauseStartTime = Timer
                    SetWindowPos hwnd, 0, 0, 0, WND_WIDTH, WND_HEIGHT, SWP_HIDEWINDOW
                    'SetWindowPos hwnd, 0, 0, 0, 100, 16, SWP_SHOWWINDOW
                    SetFormLabel "Pause"
                    Logt "Paused"
                Else
                    UnPause
                End If
            Else
                If textFieldEdit = 2 Then
                    If wParam = 8 Then
                        If Len(rocket.pilotName) > 0 Then rocket.pilotName = Left(rocket.pilotName, Len(rocket.pilotName) - 1)
                    Else
                        If wParam = 13 Then
                            textFieldEdit = 0
                            If Len(rocket.pilotName) > 0 Then
                                rocket.pilotName = NormalizePilotName(rocket.pilotName)
                            Else
                                rocket.pilotName = "Johny Walker"
                            End If
                        Else
                            If Len(rocket.pilotName) < 20 Then
                                If wParam = 190 Then
                                    rocket.pilotName = rocket.pilotName + Chr(46)
                                Else
                                    rocket.pilotName = rocket.pilotName + Chr(CLng(wParam))
                                End If
                            End If
                        End If
                    End If
                    
                End If
            End If
            
        Case WM_DESTROY
            sta = "WM_DESTROY"
            timeEndPeriod 1
            GdiplusShutdown token
            ShowCur
            PostQuitMessage 0
            
        Case Else
            sta = "Else: hwnd=" & hwnd & ", uMsg=" & uMsg & ", wParam=" & wParam & ", lParam=" & lParam
            WindowProc = DefWindowProc(hwnd, uMsg, wParam, lParam)
            Exit Function
            
    End Select
    WindowProc = 0
    Exit Function
    
err:
    Logt "WindowProc: " & sta & ": " & Error
    obj.CreateMessage "WindowProc: " & sta & ": " & Error, FONT_ITALIC
    Sleep 1000
    exiting = True
    WindowProc = 1
End Function



' ----------------------------------------------------------------------------------------------------------------------
' ------------------------------------------[  O P E N  W I N D O W  ]--------------------------------------------------
' ----------------------------------------------------------------------------------------------------------------------


Public Sub OpenWindow(Optional dummy As Boolean = False)
    Static wcex As WNDCLASSEX
    Static wMessage As msg
    Dim zp As Integer
    Dim dc As LongPtr
    Dim a As Integer

    running = True
    exiting = False
    scoresChanged = False
    dc = GetDC(0)
    WND_WIDTH = GetDeviceCaps(dc, 8)    ' screen width
    WND_HEIGHT = GetDeviceCaps(dc, 10)  ' screen height
    'WND_WIDTH = 1450
    'WND_HEIGHT = 1050
    OSD_HEIGHT = WND_HEIGHT
    SCR_WIDTH = WND_WIDTH - OSD_WIDTH
    SCR_HEIGHT = WND_HEIGHT
    starFieldHeight = 3 * SCR_HEIGHT
    
    wDir = Space(255)
    Call GetCurrentDirectory(255, wDir)
    zp = InStr(1, wDir, Chr(0), vbBinaryCompare)
    If zp > 0 Then imgDir = Left(wDir, zp - 1) & "\img\" Else imgDir = wDir & "\img\"
    If LoadImg("vessel.bmp") Is Nothing Then imgDir = IMG_DIR
    Set lStream = CreateObject("Scripting.FileSystemObject")
    Set logFile = lStream.CreateTextFile(imgDir + LOG_FILE_NAME, True)
    
    Logt "Launch at " & time, False
    Logt "Monitor resolution " & WND_WIDTH & " x " & WND_HEIGHT, False
    Logt "Using [" & imgDir & "]", False
    wcex.cbSize = LenB(wcex)
    wcex.style = CS_VREDRAW Or CS_HREDRAW Or CS_OWNDC 'Or CS_DBLCLKS
    wcex.lpfnWndProc = FuncPtr(AddressOf WindowProc)
    wcex.cbClsExtra = 1
    wcex.cbWndExtra = 1
    wcex.hInstance = GetModuleHandle(0)
    wcex.hIcon = LoadIcon(0, IDI_APPLICATION)
    wcex.hCursor = LoadCursor(0, IDC_ARROW)
    wcex.hbrBackground = COLOR_WINDOW + 1
    wcex.lpszMenuName = vbNullString
    wcex.lpszClassName = CLASS_NAME
    wcex.hIconSm = LoadIcon(0, IDI_APPLICATION)
    RegisterClassEx wcex
    hwndForm = CreateWindowEx(WND_STYLE, CLASS_NAME, "Prehledy", WS_POPUP, 0, 0, WND_WIDTH, WND_HEIGHT, 0, 0, wcex.hInstance, 0)
    ShowWindow hwndForm, SW_SHOWDEFAULT
    UpdateWindow hwndForm
    
    'Logt "HWND = " & hwndForm
    'TimerID = SetTimer(hwndForm, 0, 25, FuncPtr(AddressOf TimerProc))
    'Logt "TimerID = " & TimerID
    Do While (GetMessage(wMessage, 0, 0, 0))
        TranslateMessage wMessage
        DispatchMessage wMessage
    Loop
    'If TimerID > 0 Then Call KillTimer(hwndForm, 0)
    
    If Not test Then SaveState
    DeleteObjects
    running = False
    pause = False
    Logt "Exit", True
    Logt "", False
    logFile.Close
End Sub


Public Sub Main()
    If running Then
        If pause Then UnPause
    Else
        Call OpenWindow
    End If
End Sub


Public Sub SaveState(Optional ByVal dummy As Boolean = False)
On Error Resume Next
    If Not test Then
        Dim s As String
        Dim f
        s = CreateFileState()
        If Not fStream Is Nothing Then
            Set f = fStream.OpenTextFile(imgDir + STATE_FILE_NAME, 2, 0)
            f.Write s
            f.Close
            Logt "Scores stored.", False
        End If
    End If
    saved = True
End Sub




' ----------------------------------------------------------------------------------------------------------------------
' --------------------------------------------[   H E L P E R S   ]-----------------------------------------------------
' ----------------------------------------------------------------------------------------------------------------------

Public Sub UnPause()
    Dim ps As Single
    Dim tm As Single
    pause = False
    tm = Timer
    ps = tm - pauseStartTime
    While ps < 0
        tm = tm + (24 * 3600)
        ps = tm - pauseStartTime
    Wend
    updateOSD = True
    pausedTime = pausedTime + CLng(ps)
    Logt "Resumed (" & ToTime(CLng(ps)) & ") Pause time: " & ToTime(pausedTime)
    SetFormLabel "Running"
    SetWindowPos hwndForm, 0, 0, 0, WND_WIDTH, WND_HEIGHT, SWP_SHOWWINDOW
End Sub


Public Sub Logt(line As Variant, Optional Persist As Boolean = True)
On Error Resume Next
    If Persist Then
        'CurrentDb.Execute ("INSERT INTO [Logt] ([EDate], [ETime], [Count], [Message]) VALUES ('" & Format(Date, "d.m.yyyy") & "', '" & Format(time, "hh:mm:ss") & "', '1', '" & line & "');")
        logFile.Write Date & " " & time & "    " & CStr(line) & Chr(13) & Chr(10)
    End If
    Debug.Print CStr(line)
End Sub


Public Function NormalizePilotName(ByVal pName As String) As String
    Dim name As String
    Dim str As String
    Dim sar As Variant
    Dim i As Integer
    
    name = ""
    sar = Split(Left(pName, 20), " ")
    For i = 0 To UBound(sar)
        str = Trim(LCase(sar(i)))
        str = UCase(Left(str, 1)) + Right(str, Len(str) - 1)
        If i > 0 Then name = name + " "
        name = name + str
    Next i
    NormalizePilotName = name
End Function


Private Sub DeleteObjects(Optional dummy As Boolean)
    Call imgLib.Clear
    Call obj.Destroy
    Set obj = Nothing
    Set rocket = Nothing
    Set imgLib = Nothing
    Call DeleteObject(bmp)
    Call DeleteDC(BDC)
    Call DeleteObject(osdBBmp)
    Call DeleteDC(osdBDC)
    Call DeleteObject(osdBmp)
    Call DeleteDC(odc)
    Call cCenter.CleanUp
    Call DeleteDC(tmpDC)
    Call GdipDeleteGraphics(g)
    Call GdipDeleteGraphics(gm)
End Sub


Public Function MakeFont(fontName As String, ByVal height As Long, ByVal width As Long, _
        Optional fontStyle As Byte = 0, Optional landscape As Boolean = False) As LongPtr
    Dim f As LOGFONT
    StrToByteArray fontName, f.lfFaceName
    f.lfHeight = Round(height)
    f.lfWidth = Round(width)
    f.lfWeight = 400
    f.lfCharset = 1
    f.lfPitchAndFamily = 1
    If landscape Then f.lfEscapement = 2700 Else f.lfEscapement = 0
    If fontStyle And FONT_BOLD Then f.lfWeight = 900
    If fontStyle And FONT_UNDERLINED Then f.lfUnderline = 1
    If fontStyle And FONT_ITALIC Then f.lfItalic = 1
    If fontStyle And FONT_STRIKEOUT Then f.lfStrikeOut = 1
    MakeFont = CreateFontIndirect(f)
End Function


Private Function FuncPtr(ByVal p As LongPtr) As LongPtr
    FuncPtr = p
End Function


Public Sub StrToByteArray(fn As String, into As Variant)
    Dim i As Integer
    
    For i = 1 To LF_FACESIZE
        If (i <= Len(fn)) Then
            into(Len(fn) - i) = Asc(Right(fn, i))
        Else
            into(i - 1) = 0
        End If
    Next i
End Sub


Public Static Function NumSpac(ByVal v As Long) As String
    Dim o As String
    Dim n As Integer
    Dim c As Integer
    c = 0
    If v = 0 Then o = "0" Else o = ""
    While v > 0
        n = v Mod 10
        o = n & o
        v = (v - n) / 10
        c = c + 1
        If (c Mod 3 = 0) And (v > 0) Then o = "'" & o
    Wend
    NumSpac = o
End Function


Public Function LastChar(ByVal str As String) As String
    LastChar = Right(str, 1)
End Function


Public Function Ceil(ByVal s As Single) As Long
    Dim l As Long
    l = Round(s)
    If l < s Then Ceil = l + 1 Else Ceil = l
End Function


Public Function Floor(ByVal s As Single) As Integer
    Dim i As Integer
    i = Round(s)
    If i < s Then Floor = i - 1 Else Floor = i
End Function


Public Sub SaveScore(ByVal name As String, ByVal s As Long, ByVal lev As Long)
    If test Then Exit Sub
    If s < minScore Then Exit Sub
    Dim i As Integer
    Dim added As Boolean
    
    scoresChanged = True
    added = False
    For i = LBound(scores) To UBound(scores)
        If Not scores(i) Is Nothing Then
            If s > scores(i).score Then
                Dim j As Integer
                For j = 9 To i Step -1
                    Set scores(j + 1) = scores(j)
                Next j
                Set scores(i) = New Record
                scores(i).name = name
                scores(i).score = s
                scores(i).level = lev
                Exit For
            End If
        Else
            If Not added Then
                Set scores(i) = New Record
                scores(i).name = name
                scores(i).score = s
                scores(i).level = lev
                added = True
        End If
        End If
    Next i
    If Not cCenter Is Nothing Then cCenter.FillStrCache
End Sub


Private Sub ParseFileState(ByVal s As String)
    Dim l, v, sv
    Dim n As Long, lev As Long, sc As Long
    l = Split(s, ";")
    For i = LBound(l) To UBound(l)
        If Len(l(i)) > 0 Then
            v = Split(l(i), "=")
            If v(0) = "pilotName" Then
                rocket.pilotName = v(1)
                initPilotName = v(1)
            Else
                n = CLng(v(0))
                sv = Split(v(1), ",")
                If scores(n) Is Nothing Then Set scores(n) = New Record
                scores(n).name = CStr(sv(0))
                scores(n).level = CLng(sv(1))
                scores(n).score = CLng(sv(2))
            End If
        End If
    Next i
    If Len(initPilotName) = 0 Then initPilotName = "Johny Walker"
End Sub


Private Function CreateFileState() As String
    Dim s As String
    s = "pilotName=" & rocket.pilotName & ";"
    For i = LBound(scores) To UBound(scores)
        If Not scores(i) Is Nothing Then
            s = s & CStr(i) & "=" & scores(i).name & "," + CStr(scores(i).level) & "," & CStr(scores(i).score) & ";"
        End If
    Next i
    CreateFileState = s
End Function


Public Function ToTime(ByVal sec As Long) As String
    Dim str As String
    Dim num As Long
    str = ""
    If sec > 3600 Then
        str = Int(sec / 3600) & ":"
        sec = sec Mod 3600
    End If
    
    num = Int(sec / 60)
    sec = sec Mod 60
    If num >= 10 Then
        str = str & num & ":"
    Else
        str = str & "0" & num & ":"
    End If
    
    If sec >= 10 Then
        str = str & sec
    Else
        str = str & "0" & sec
    End If
    ToTime = str
End Function


Public Sub SetFormLabel(ByVal str As String)
    ' form removed
End Sub

'End of file


