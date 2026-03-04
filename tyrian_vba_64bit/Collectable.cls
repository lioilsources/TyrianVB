VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Collectable"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Class Collectable

Private Const ICON_WIDTH As Long = 35
Private Const ICON_HEIGHT As Long = 35


Public caption As String
Public img As Image
Public trace As Path
Public effect As Action
Public prv As Collectable
Public nxt As Collectable
Public parent As Objects
Public cType As CollType
Public value As Long

Private x2 As Integer
Private y2 As Integer

Public Enum Action
    BonusHealth = 1
    BonusShield = 2
    'BonusCredit = 3
End Enum


Public Enum CollType
    none = 0
    FrontWepUpgrade = 1
    LeftWepUpgrade = 2
    RightWepUpgrade = 3
    HealthUpgrade = 4
    ShieldUpgrade = 5
    GeneratorUpgrade = 6
    BonusCredit = 7
End Enum


Public Function GetShield() As LongPtr
    GetShield = parent.shield
End Function


Public Function GetShieldMask() As LongPtr
    GetShieldMask = parent.ShieldMask
End Function


Public Function GetHealth() As LongPtr
    GetHealth = parent.Health
End Function


Public Function GetHealthMask() As LongPtr
    GetHealthMask = parent.HealthMask
End Function


Public Function GetGenerator() As LongPtr
    GetGenerator = parent.Generator
End Function


Public Function GetGeneratorMask() As LongPtr
    GetGeneratorMask = parent.GeneratorMask
End Function


Public Function GetWeapon() As LongPtr
    GetWeapon = parent.Weapon
End Function


Public Function GetWeaponMask() As LongPtr
    GetWeaponMask = parent.WeaponMask
End Function


Public Function GetMoney() As LongPtr
    GetMoney = parent.Money
End Function


Public Function GetMoneyMask() As LongPtr
    GetMoneyMask = parent.MoneyMask
End Function


Public Sub PlaceImg()
    img.x = trace.current.x
    img.y = trace.current.y
End Sub


Public Function CreateLetterIcon(ByVal ch As String, ByVal xOffset As Integer, Optional ByVal yOffset As Integer = 2, _
        Optional ByVal midColor As Long = &HFF8080FF, Optional ByVal borderColor As Long = &HFF000030, _
        Optional ByVal fontColor As Long = &HFFA0A0) As LongPtr
    Dim dc As LongPtr, Bmp As LongPtr, gdc As LongPtr
    Dim brush As LongPtr
    Dim p As LongPtr, grad As LongPtr
    
    dc = CreateCompatibleDC(GetDC(parent.hwnd))
    Bmp = CreateCompatibleBitmap(GetDC(parent.hwnd), ICON_WIDTH, ICON_HEIGHT)
    brush = CreateSolidBrush(&HFFFFFF)
    Call SelectObject(dc, Bmp)
    Call SelectObject(dc, brush)
    Call BeginPath(dc)
    Call Rectangle(dc, 0, 0, ICON_WIDTH + 1, ICON_HEIGHT + 1)
    Call EndPath(dc)
    Call FillPath(dc)
    Call DeleteObject(brush)
    s = GdipCreateFromHDC(dc, gdc)
    s = GdipCreatePath(FillModeAlternate, p)
    s = GdipAddPathEllipse(p, 0, 0, ICON_WIDTH + 1, ICON_HEIGHT + 1)
    s = GdipCreatePathGradientFromPath(p, grad)
    s = GdipSetPathGradientCenterColor(grad, midColor)
    s = GdipSetPathGradientSurroundColorsWithCount(grad, borderColor, 1)
    s = GdipFillEllipse(gdc, grad, 0, 0, ICON_WIDTH, ICON_HEIGHT)
    s = GdipDeletePath(p)
    s = GdipDeleteGraphics(gdc)
    Call SetTextColor(dc, fontColor)
    Call SetBkMode(dc, TRANSPARENT)
    Call SelectObject(dc, parent.iFont)
    Call TextOut(dc, xOffset, yOffset, ch, 1)
    Call DeleteDC(dc)
    CreateLetterIcon = Bmp
End Function


Public Function CreateShield() As Image
    Dim s As Image
    Set s = CreateImage(GetShield, -100, -100, 35, 35)
    s.hMask = GetShieldMask
    Set img = s
    Set CreateShield = s
End Function


Public Function CreateHealth() As Image
    Dim s As Image
    Set s = CreateImage(GetHealth, -100, -100, 35, 35)
    s.hMask = GetHealthMask
    Set img = s
    Set CreateHealth = s
End Function


Public Function CreateGenerator() As Image
    Dim s As Image
    Set s = CreateImage(GetGenerator, -100, -100, 35, 35)
    s.hMask = GetGeneratorMask
    Set img = s
    Set CreateGenerator = s
End Function


Public Function CreateWeapon() As Image
    Dim s As Image
    Set s = CreateImage(GetWeapon, -100, -100, 35, 35)
    s.hMask = GetWeaponMask
    Set img = s
    Set CreateWeapon = s
End Function


Public Function CreateMoney() As Image
    Dim s As Image
    Set s = CreateImage(GetMoney, -100, -100, 35, 35)
    s.hMask = GetMoneyMask
    Set img = s
    Set CreateMoney = s
End Function


Public Function CreatePath() As Path
    Set trace = New Path
    Set CreatePath = trace
End Function


Public Sub step()
    If Not trace Is Nothing Then
        If Not trace.current.nxt Is Nothing Then
            Set trace.current = trace.current.nxt
            Call PlaceImg
        Else
            If trace.onExit = Destroy Then
                ' code here
                Delete
            End If
        End If
    End If
    x2 = img.x + img.width
    y2 = img.y + img.height
    If img.x > rocket.x And img.x < rocket.x2 Or x2 > rocket.x And x2 < rocket.x2 Then
        If img.y > rocket.y And img.y < rocket.y2 Or y2 > rocket.img.y And y2 < rocket.y2 Then
            Action
            Delete
        End If
    End If
End Sub


Public Sub Delete()
    If prv Is Nothing Then
        Set parent.fColl = nxt
    Else
        Set prv.nxt = nxt
    End If
    If Not nxt Is Nothing Then Set nxt.prv = prv
End Sub


Public Sub Action()
    Dim d As Device
    
    Select Case cType
        Case FrontWepUpgrade
            Set d = rocket.GetSlotDevice(FrontGun)
            If d Is Nothing Then
                Set d = rocket.CreateBubbleGun
                rocket.dps = rocket.CalculateDPS
                rocket.pps = rocket.CalculatePPS
                Call parent.CreateMessage("Collected " & d.name & " (dps " & Round(rocket.dps) & ")")
            Else
                Call d.Upgrade
            End If
            
        Case LeftWepUpgrade
            Set d = rocket.GetSlotDevice(LeftGun)
            If d Is Nothing Then
                Set d = rocket.CreateSmallBubble(LeftGun)
                rocket.dps = rocket.CalculateDPS
                rocket.pps = rocket.CalculatePPS
                Call parent.CreateMessage("Collected " & d.name & " (dps " & Round(rocket.dps) & ")")
            Else
                Call d.Upgrade
            End If
            
        Case RightWepUpgrade
            Set d = rocket.GetSlotDevice(RightGun)
            If d Is Nothing Then
                Set d = rocket.CreateSmallBubble(RightGun)
                rocket.dps = rocket.CalculateDPS
                rocket.pps = rocket.CalculatePPS
                Call parent.CreateMessage("Collected " & d.name & " (dps " & Round(rocket.dps) & ")")
            Else
                Call d.Upgrade
            End If
            
        Case HealthUpgrade
            If rocket.hp > (rocket.hpMax / 2) Then
                rocket.hp = rocket.hp + Round(0.25 * rocket.hpMax)
                If rocket.hpMax < 2000 Then
                    rocket.hpMax = Round(rocket.hpMax * 1.05)
                    Call parent.CreateMessage("Repair 25%, Hull +5%")
                Else
                    rocket.hpMax = Round(rocket.hpMax + 50)
                    Call parent.CreateMessage("Repair 25%, Hull +")
                End If
            Else
                rocket.hp = rocket.hp + Round(0.5 * rocket.hpMax)
                Call parent.CreateMessage("Repair 50%")
            End If
            If rocket.hp > rocket.hpMax Then rocket.hp = rocket.hpMax
        
        Case ShieldUpgrade
            If rocket.shieldMax < 1500 Then
                rocket.shield = rocket.shield + Round(0.3 * rocket.shieldMax)
                rocket.shieldMax = Round(rocket.shieldMax * 1.1)
                rocket.shieldRegen = rocket.shieldRegen * 1.1
                Call parent.CreateMessage("Shield recharge 30%, Power +10%")
            Else
                rocket.shield = rocket.shield + Round(0.35 * rocket.shieldMax)
                rocket.shieldMax = Round((rocket.shieldMax + 25) / 25) * 25
                rocket.shieldRegen = rocket.shieldRegen * 1.025
                Call parent.CreateMessage("Shield recharge 35%, Power +")
            End If
            
            
            If rocket.shield > rocket.shieldMax Then rocket.shield = rocket.shieldMax
            
        
        Case GeneratorUpgrade
            Set d = rocket.GetSlotDevice(Generator)
            If Not d Is Nothing Then
                Call d.Upgrade
            End If
            
        Case BonusCredit
            rocket.AddCredit value
            Call parent.CreateMessage("Collected scraps for $ " & NumSpac(value))
            
    End Select
    If Not d Is Nothing Then
        If d.level = 0 Then
            d.displayName = d.name
        Else
            d.displayName = d.name & " " & ROMNUM(d.level)
        End If
    End If
    updateOSD = True
End Sub

'End of file


