VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "FloatText"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Class FloatText

Public text As String
Public trace As Path
Public font As LongPtr
Public color As Long
Public shadowColor As Long
Public stationary As Boolean

Public parent As Objects
Public nxt As FloatText
Public prv As FloatText

Private duration As Integer
Private sDuration As Integer


Public Sub SetDuration(ByVal d As Integer)
    duration = d
    sDuration = d
End Sub


Public Sub step()
    If Not stationary Then
        If Not trace Is Nothing Then
            If Not trace.current.nxt Is Nothing Then
                Set trace.current = trace.current.nxt
            End If
        End If
    End If
    duration = duration - 1
    If duration < sDuration / 2 Then
        color = DimColor(color)
        shadowColor = DimColor(shadowColor)
    End If
    If duration <= 0 Then Delete
End Sub


Public Function DimColor(ByVal c As Long, Optional ByVal amount As Single = 0.9) As Long
    Dim r As Long, g As Long, b As Long
    r = c And &HFF&
    g = (c And &HFF00&) / &H100&
    b = (c And &HFF0000) / &H10000
    r = Round(r * amount)
    g = Round(g * amount)
    b = Round(b * amount)
    DimColor = (b * 65536 + g * 256 + r)
End Function


Public Sub Delete()
    If prv Is Nothing Then
        Set parent.fText = nxt
    Else
        Set prv.nxt = nxt
    End If
    If Not nxt Is Nothing Then Set nxt.prv = prv
End Sub

'End of file


