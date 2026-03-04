VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Structure"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Class Structure

Public caption As String
Public behave As Behavior
Public hp As Long
Public hpMax As Long
Public shield As Long
Public shieldMax As Long
Public hit As Integer
Public img As Image
Public typ As StructType
Public trace As Path
Public prv As Structure
Public nxt As Structure
Public parent As Sector
Public enTime As Long
Public collisionDmg As Integer

Public x2 As Integer
Public y2 As Integer
Public xm As Integer
Public ym As Integer

Private sx As Single
Private dx As Single
Private sy As Single
Private dy As Single

Public Enum Behavior
    Fall = 1
    Follow = 2
    FallAndFollow = 3
    ByPath = 4
End Enum


Public Enum StructType
    Basic = 0
    Asteroid = 1
End Enum


Public Sub SetBounds(ByVal x1 As Single, ByVal y1 As Single, ByVal x2 As Single, ByVal y2 As Single)
    sx = x1
    sy = y1
    dx = x2
    dy = y2
End Sub

Public Static Sub PlaceImg()
    img.x = trace.current.x
    img.y = trace.current.y
    x2 = img.x + img.width
    y2 = img.y + img.height
End Sub


Public Sub SetBehavior(ByVal b As Behavior)
    behave = b
    Select Case behave
        Case ByPath
            Set trace = New Path
            trace.Generate SCR_HEIGHT / (2 + Rnd * 3), img.x, -img.height, img.x, SCR_HEIGHT + 10, Linear
            trace.onExit = Destroy
            
        Case Fall
            img.y = 2
            img.x = sx
            
        Case FallAndFollow
            img.y = 2
            img.x = sx
            
        Case Follow
            img.y = dy
            img.x = dx
    End Select
End Sub


Public Sub step()
    Select Case behave
        Case Fall
            img.y = img.y + 0.05
            If img.y > SCR_HEIGHT Then img.drawInLoop = False
            
        Case Follow
            If rocket.x > img.x + (img.width / 2) - (rocket.img.width / 2) Then img.x = img.x + 0.1
            If rocket.x < img.x + (img.width / 2) - (rocket.img.width / 2) Then img.x = img.x - 0.1
            If img.x < 0 Then img.x = 0
            If img.x > (SCR_WIDTH - img.width) Then img.x = SCR_WIDTH - img.width
            
        Case FallAndFollow
            img.y = img.y + 0.05
            If img.y > SCR_HEIGHT Then img.drawInLoop = False
            If rocket.x > img.x + (img.width / 2) - (rocket.img.width / 2) Then img.x = img.x + 0.1
            If rocket.x < img.x + (img.width / 2) - (rocket.img.width / 2) Then img.x = img.x - 0.1
            If img.x < 0 Then img.x = 0
            If img.x > (SCR_WIDTH - img.width) Then img.x = SCR_WIDTH - img.width
            
        Case ByPath
            If Not trace Is Nothing Then
                If Not trace.current Is Nothing Then
                    If Not trace.current.nxt Is Nothing Then
                        Set trace.current = trace.current.nxt
                        PlaceImg
                    Else
                        If trace.onExit = Destroy Then
                            ' code here
                            Delete
                        End If
                    End If
                End If
            End If
    End Select
    x2 = Round(img.x + img.width)
    y2 = Round(img.y + img.height)
    xm = Round(img.x + img.width / 2)
    ym = Round(img.y + img.height / 2)
    If typ <> Basic Then
        If img.x >= rocket.x And img.x <= rocket.x2 Or x2 >= rocket.x And x2 <= rocket.x2 Then
            If img.y >= rocket.y And img.y <= rocket.y2 Or y2 >= rocket.y And y2 <= rocket.y2 Then
                updateOSD = True
                rocket.moveBlock = 2
                If rocket.shield > 0 Then
                    rocket.shield = rocket.shield - collisionDmg
                End If
                If rocket.shield < 0 Then
                    rocket.hp = rocket.hp + rocket.shield
                    rocket.dmgTaken = 2
                    rocket.shield = 0
                    If rocket.hp <= 0 Then obj.GameOver
                End If
                rocket.y = y2
            End If
        End If
    End If
End Sub


Public Sub Delete()
    img.drawInLoop = False
    If prv Is Nothing Then
        Set parent.fStruct = nxt
    Else
        Set prv.nxt = nxt
    End If
    If Not nxt Is Nothing Then Set nxt.prv = prv
End Sub
'End of file


