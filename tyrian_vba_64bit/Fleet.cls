VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Fleet"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Class Fleet
Option Explicit

Public caption As String
Public id As Integer
Public showDamage As Boolean
Public enterTime As Long
Public count As Integer
Public kills As Integer
Public bonus As CollType
Public bonusMoney As Long
Public fHost As Hostile
Public lHost As Hostile
Public hType As HostType
Public triggerSteps As Integer
Public active As Boolean
Public started As Boolean
Public maxx As Integer
Public maxy As Integer
Public minx As Integer
Public miny As Integer
Public weap As Device
Public weapCD As Integer
Public weapCharge As Integer
Public IsRandom As Boolean
Public defPathAction As PathAction
Public pth As Path
Public altParam1 As Integer             ' ReplacePath proc parameters
Public altParam2 As Integer
Public altParam3 As Integer
Public altParam4 As PathType

Public parent As Sector
Public nxt As Fleet
Public prv As Fleet

Private extraPath As Path
Private deleted As Integer
Private stepCount As Long
Private tr As Integer

Private h As Hostile
Private delh As Hostile
Private p As Projectile
Private delp As Projectile
Private f As Fleet
Private d As Device
Private setNext As Boolean
Private btmp As Boolean
Private btmp2 As Boolean


Public Function CreatePath() As Path
    Set pth = New Path
    Set CreatePath = pth
End Function


Public Function GetExtraPath() As Path
    Set GetExtraPath = extraPath
End Function


Public Function SetExtraPath(p As Path) As Path
    Set extraPath = p
    Set SetExtraPath = p
End Function


Public Sub step()
    stepCount = stepCount + 1
    tr = Int(stepCount / triggerSteps)
    If stepCount Mod triggerSteps = 0 And tr <= count Then
        Set h = New Hostile
        Set h.pFleet = Me
        obj.SetType h, hType
        h.img.drawInLoop = True
        Set h.trace = pth.Clone
        h.trace.onExit = defPathAction
        If Not extraPath Is Nothing Then Call h.trace.AddPath(extraPath)
        h.id = tr
        h.hit = 0
        If fHost Is Nothing Then
            Set fHost = h
            Set lHost = h
            Set h.prv = Nothing
        Else
            Set lHost.nxt = h
            Set h.prv = lHost
            Set lHost = h
        End If
    End If
    Set h = fHost
    While Not h Is Nothing
        h.step
        If h.hp <= 0 And h.img.drawInLoop Then
            'Set d = rocket.GetDevices
            'While Not d Is Nothing
            '    If d.pwrGen = 0 And d.beamActive > 0 Then d.beamActive = 0
            '    Set d = d.nxt
            'Wend
            kills = kills + 1
            rocket.AddCredit h.hpMax
            rocket.AddScore h.hpMax
            Set delh = h
            Set h = h.nxt
            'Delete delh
            If delh.img.drawInLoop Then
                delh.img.drawInLoop = False
                obj.CreateExplosion delh
            End If
            
            If deleted < count Then deleted = deleted + 1
            If (kills = count) Then
                If bonus <> CollType.none Then
                    obj.CreateColl bonus, delh.img.x, delh.img.y, bonusMoney
                    updateOSD = True
                End If
            End If
        Else
            Set h = h.nxt
        End If
    Wend
    Set delh = Nothing
    Set h = Nothing
    If (count = deleted) Then
        If weap Is Nothing Then
             active = False
        Else
            If weap.fProjectile Is Nothing Then active = False
        End If
        If Not active Then
            Dim f As Fleet
            Dim a As Boolean
            Dim etToActivate As Long
            a = False
            Set f = currentSector.fFleet
            While Not f Is Nothing
                If f.enterTime < elapsed Then
                    If f.active Then a = True
                End If
                Set f = f.nxt
            Wend
            If Not nxt Is Nothing And Not a Then
                ' activate next fleets
                If nxt.active And nxt.IsRandom And nxt.enterTime > (elapsed + 2) Then
                    etToActivate = nxt.enterTime
                    nxt.enterTime = (elapsed + 2)
                    Set f = nxt
                    While Not f Is Nothing
                        If f.enterTime = etToActivate Then f.enterTime = elapsed + 2
                        Set f = f.nxt
                    Wend
                End If
            End If
            If prv Is Nothing Then
                Set parent.fFleet = nxt
            Else
                Set prv.nxt = nxt
            End If
            If Not nxt Is Nothing Then Set nxt.prv = prv
        End If
    End If
    If Not weap Is Nothing Then
        If weap.cd > 0 Then weap.cd = weap.cd - 1
        Set p = weap.fProjectile
        While Not p Is Nothing
            setNext = False
            p.img.y = Round(p.img.y - p.speed)
            p.y2 = p.img.y + p.img.height
            If p.img.y > SCR_HEIGHT Then
                Set delp = p
                Set p = p.nxt
                delp.Delete
                setNext = True
            Else
                btmp = ((p.img.y >= rocket.y) And (p.img.y <= rocket.y2))
                btmp2 = False
                If Not btmp Then btmp2 = ((p.y2 >= rocket.y) And (p.y2 <= rocket.y2))
                If btmp Or btmp2 Then
                    btmp = ((p.img.x >= rocket.x) And (p.img.x <= rocket.x2))
                    btmp2 = False
                    If Not btmp Then btmp2 = ((p.x2 >= rocket.x) And (p.x2 <= rocket.x2))
                    If btmp Or btmp2 Then
                        rocket.shield = rocket.shield - p.damage
                        If rocket.shield < 0 Then
                            rocket.hp = rocket.hp + rocket.shield
                            rocket.dmgTaken = 4
                            rocket.shield = 0
                            If rocket.hp <= 0 Then obj.GameOver
                        End If
                        updateOSD = True
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
    End If
End Sub


Public Static Sub Delete(ByRef ho As Hostile)
    'stack overflow
    If Not ho.prv Is Nothing Then Set ho.prv.nxt = ho.nxt Else Set fHost = ho.nxt
    If Not ho.nxt Is Nothing Then Set ho.nxt.prv = ho.prv Else Set lHost = ho.prv
    If deleted < count Then deleted = deleted + 1
End Sub


Public Static Sub ResetArea()
    maxx = -1
    minx = 20000
    maxy = -1
    miny = 20000
End Sub

'End of file


