VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Device"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Class Device

Public name As String
Public imgName As String
Public price As Long
Public upgCost As Single
Public displayName As String
Public level As Byte
Public slot As Slots
Public damage As Long
Public speed As Integer
Public guide As Integer
Public pwrNeed As Single
Public pwrGen As Single
Public cooldown As Single
Public beam As Byte
Public beamActive As Byte
Public seqs As Byte
Public activateBy As Integer
Public xShift As Integer
Public xShiftMax As Integer
Public xShiftDir As Integer
Public proj As Image
Public minProjScale As Single
Public maxProjScale As Single
Public scaleProjectile As Boolean
Public parent As Vessel
Public host As Hostile
Public nxt As Device
Public prv As Device
Public fProjectile As Projectile
Public lProjectile As Projectile
Public proPool As Projectile        ' projectile pool
Public cd As Single                 ' CoolDown
Public sx As Integer                ' beam coords
Public sy As Integer
Public dx As Integer
Public dy As Integer

'Private p As Projectile
Private xOffset As Integer
Private yOffset As Integer

Private id As Integer


Public Sub SetOffsets(ByVal xo As Integer, ByVal yo As Integer)
    xOffset = xo
    yOffset = yo
End Sub


Public Sub Create(Optional host As Hostile = Nothing)
    Static p As Projectile
    
    If pwrGen > 0 Then Exit Sub
    If cd <= 0 Then
        cd = cooldown
        If beam > 0 Then
            beamActive = seqs
            parent.genValue = parent.genValue - pwrNeed
            'beam weapons have no projectiles
            Exit Sub
        End If
        If proPool Is Nothing Then
            Set p = New Projectile
        Else
            Set p = proPool
            Set proPool = proPool.nxt
            If Not proPool Is Nothing Then
                Set proPool.prv = Nothing
            End If
        End If
        Set p.nxt = Nothing
        Set p.prv = Nothing
        If host Is Nothing Then
            p.pool = False
            p.damage = damage
            p.speed = Abs(speed)
            If p.img Is Nothing Then Set p.img = CloneImage(proj)
            Select Case slot
                Case FrontGun
                    p.img.x = parent.x + xOffset
                    p.x2 = parent.x + xOffset + p.img.width
                    p.img.y = parent.y + yOffset + 4
                Case LeftGun
                    p.img.x = parent.x - proj.width / 2
                    p.x2 = parent.x + p.img.width
                    p.img.y = parent.y + yOffset + 24 'ship image dependent
                Case RightGun
                    p.img.x = parent.x + parent.img.width - proj.width / 2
                    p.x2 = parent.x + xOffset + parent.img.width
                    p.img.y = parent.y + yOffset + 24
            End Select
            If p.parent Is Nothing Then Set p.parent = Me
            If xShiftMax <> 0 Then
                xShift = xShift + xShiftDir * 7
                p.img.x = p.img.x + xShift
                If xShift <= -xShiftMax Then xShiftDir = 1
                If xShift >= xShiftMax Then xShiftDir = -1
            End If
            parent.genValue = parent.genValue - pwrNeed
            If Not fProjectile Is Nothing Then
                Set lProjectile.nxt = p
                Set p.prv = lProjectile
                Set lProjectile = p
            Else
                Set fProjectile = p
                Set lProjectile = p
            End If
        Else
            If p.img Is Nothing Then Set p.img = CloneImage(proj)
            If p.parent Is Nothing Then Set p.parent = Me
            p.speed = -Abs(speed)
            p.damage = damage
            p.img.x = host.img.x + host.img.width / 2 - p.img.width / 2
            p.x2 = p.img.x + p.img.width
            p.img.y = host.img.y + host.img.height + 5
            p.y2 = p.img.y + p.img.height
            host.pFleet.weapCD = 0
            If Not fProjectile Is Nothing Then
                Set lProjectile.nxt = p
                Set p.prv = lProjectile
                Set lProjectile = p
            Else
                Set fProjectile = p
                Set lProjectile = p
            End If
        End If
    End If
End Sub


Public Sub Upgrade()
    If level = 25 Then
        If displayComCenter Then
            Call obj.CreateMessage("Max. level reached !")
        Else
            Dim bv As Long
            bv = 25000
            If currentSector.level >= 5 Then bv = 50000
            If currentSector.level >= 10 Then bv = 100000
            If currentSector.level >= 15 Then bv = 250000
            If currentSector.level >= 20 Then bv = 500000
            If currentSector.level >= 25 Then bv = 1000000
            If currentSector.level >= 30 Then bv = 2500000
            If currentSector.level >= 40 Then bv = 5000000
            Call obj.CreateMessage("Max. level! Sold for $ " & NumSpac(bv))
            rocket.AddCredit bv
            rocket.AddScore bv
        End If
        Exit Sub
    End If
    damage = Round(damage * 1.1)
    pwrNeed = Round(pwrNeed * 1.2)
    cooldown = cooldown / 1.02
    level = level + 1
    price = Round(price * (1 + upgCost))
    If pwrGen > 0 Then
        pwrGen = pwrGen * 1.255
        parent.genPower = pwrGen
        parent.genMax = parent.genMax * 1.2
        Call obj.CreateMessage("Upgraded " & name & " (" & Round(parent.GeneratorLoad) & "%)")
    Else
        If scaleProjectile Then
            Set proj = CopyImage(imgLib.GetItem(imgName), _
                proj.x, proj.y, 0, minProjScale + (maxProjScale - minProjScale) / MAX_WEAP_LEV * level, _
                False, 0, STRETCH_HALFTONE)
            Call SetOffsets(rocket.img.width / 2 - proj.width / 2, -proj.height)
        End If
        Call obj.CreateMessage("Upgraded " & name & " (dps " & Round(parent.CalculateDPS) & ")")
    End If
    displayName = name & " " & ROMNUM(level)
    parent.dps = parent.CalculateDPS
    parent.pps = parent.CalculatePPS
End Sub


Public Sub ResetLists()
    Set fProjectile = Nothing
    Set proPool = Nothing
End Sub

'End of file
