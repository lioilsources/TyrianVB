VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Hostile"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Hostile class
Option Explicit

Public caption As String
Public id As Integer
Public img As Image
Public hp As Long
Public hpMax As Long
Public damage As Integer
Public shield As Long
Public shieldMax As Long
Public hit As Integer
Public trace As Path
Public pFleet As Fleet
Public actionPathId As Integer
Public pAction As PathAction
Public nxt As Hostile
Public prv As Hostile
Public collisionDmg As Integer

Public xm As Integer
Public ym As Integer
Public x2 As Integer
Public y2 As Integer


Public Sub SetAction(ByVal pathId As Integer, ByVal Action As PathAction)
    actionPathId = pathId
    pAction = Action
End Sub


Public Static Sub PlaceImg()
    img.x = trace.current.x
    img.y = trace.current.y
End Sub


Public Static Sub step()
    If Not img.drawInLoop Then Exit Sub
    If Not trace Is Nothing Then
        If Not trace.current.nxt Is Nothing Then
            Set trace.current = trace.current.nxt
            PlaceImg
        Else
            If trace.onExit = Destroy Then
                ' code here
                Delete
            End If
            Dim ho As Hostile
            If trace.onExit = FreezeFleet Then
                Set ho = pFleet.fHost
                While Not ho Is Nothing
                    ho.trace.Finish
                    Set ho = ho.nxt
                Wend
            End If
            If trace.onExit = ReplacePath Then
                Set ho = pFleet.fHost
                While Not ho Is Nothing
                    ho.CyclePath pFleet.altParam1, pFleet.altParam2, pFleet.altParam3, pFleet.altParam4
                    Set ho = ho.nxt
                Wend
            End If
        End If
    End If
    xm = img.x + img.width / 2
    ym = img.y + img.height / 2
    x2 = img.x + img.width
    y2 = img.y + img.height
    If pFleet.weapCharge > 0 Then
        If pFleet.weapCD < pFleet.weapCharge Then pFleet.weapCD = pFleet.weapCD + 1
        If pFleet.weapCD = pFleet.weapCharge Then
            If y2 > 0 And xm > 0 And xm < SCR_WIDTH And Not pFleet.weap Is Nothing Then
                pFleet.weap.Create Me
                pFleet.weapCD = 0
            End If
        End If
    End If
    If img.x > rocket.x And img.x < rocket.x2 Or x2 > rocket.img.x And x2 < rocket.x2 Then
        If img.y > rocket.y And img.y < rocket.y2 Or y2 > rocket.img.y And y2 < rocket.y2 Then
            updateOSD = True
            If rocket.shield > 0 Then
                rocket.shield = rocket.shield - collisionDmg
            End If
            If rocket.shield < 0 Then
                rocket.hp = rocket.hp + rocket.shield
                rocket.dmgTaken = 2
                rocket.shield = 0
                If rocket.hp <= 0 Then obj.GameOver
            End If
        End If
    End If
End Sub


Public Static Sub Delete()
    pFleet.Delete Me
End Sub


Public Sub CyclePath(ByVal steps As Integer, ByVal dx As Integer, ByVal dy As Integer, ByVal pt As PathType)
    Dim x As Single
    Dim y As Single
    x = trace.current.x
    y = trace.current.y
    Set trace = New Path
    Call trace.Generate(steps, x, y, x + dx, y + dy, pt, Math.Sqr(dx * dx + dy * dy), 1)
    Call trace.Generate(steps, x + dx, y + dy, x, y, pt, -Math.Sqr(dx * dx + dy * dy), 1)
    Call trace.encycle
End Sub


'End of file

