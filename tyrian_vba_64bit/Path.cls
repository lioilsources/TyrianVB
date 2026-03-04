VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Path"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Class Path

Public current As Position
Public first As Position
Public last As Position
Public onExit As PathAction

Public Enum PathAction
    Destroy
    FreezeFleet
    Noop
    ReplacePath
    Stay
End Enum

Public Enum PathType
    Linear = 1
    Cosinus = 2
    SinCos = 3
    Sinus = 4
End Enum


Public Sub AddPath(p As Path)
    If last Is Nothing Then
        Set first = p.first
    Else
        Set last.nxt = p.first
    End If
    onExit = p.onExit
End Sub


Public Sub Generate(ByVal steps As Long, ByVal sx As Long, ByVal sy As Long, ByVal dx As Long, ByVal dy As Long, _
        Optional ByVal typ As PathType = Linear, Optional ByVal amplitude As Integer = 100, _
        Optional ByVal cycles As Double = 4, Optional amplMultiplier As Double = 1)

    Dim p As Position
    Dim ampl As Single
    Dim xs As Single, ys As Single
    Dim ax As Single, ay As Single, cx As Single, cy As Single, ang As Single, angStep As Single
    Dim length As Single
    
    ampl = amplitude
    length = Sqr((dx - sx) * (dx - sx) + (dy - sy) * (dy - sy))     'total streight length
    xs = (dx - sx) / length
    ys = (dy - sy) / length
    ax = (dx - sx) / steps
    ay = (dy - sy) / steps
    cx = sx
    cy = sy
    ang = 0
    angStep = (2 * PI * cycles) / (length)
    For n = 1 To steps
        Set p = New Position
        Select Case typ
            Case Linear
                p.x = cx
                p.y = cy
            
            Case Cosinus
                p.x = cx + Sin(ang) * ampl * ys
                p.y = cy
                ang = ang + angStep
            
            Case Sinus
                p.x = cx
                p.y = cy + Sin(ang) * ampl * xs
                ang = ang + angStep
            
            Case SinCos
                p.x = cx + Sin(ang) * ampl * ys
                p.y = cy + Cos(ang) * ampl * xs
                ang = ang + angStep
        End Select
        cx = cx + ax
        cy = cy + ay
        If Not last Is Nothing Then
            Set last.nxt = p
            Set last = p
        Else
            Set first = p
            Set last = p
        End If
        ampl = ampl * amplMultiplier
    Next n
    onExit = Noop
    Set current = first
End Sub


Public Sub Reset()
    Set current = first
End Sub


Public Sub Finish()
    Set current = last
End Sub


Public Function Clone() As Path
    Dim np As New Path
    Set np.first = first
    Set np.current = first
    Set np.last = last
    np.onExit = onExit
    Set Clone = np
End Function


Public Sub encycle()
    If Not last Is Nothing Then Set last.nxt = first
End Sub


'End of file


