VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Message"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Class Message (OSD)

Public text As String
Public duration As Integer
Public startTime As Long
Public underlined As Boolean
Public italic As Boolean
Public bold As Boolean
Public color As Long

Public nxt As Message
Public prv As Message
Public parent As Objects


Public Sub Delete()
    If prv Is Nothing Then
        Set parent.fMessage = nxt
    Else
        Set prv.nxt = nxt
    End If
    If Not nxt Is Nothing Then Set nxt.prv = prv
    updateOSD = True
End Sub


Public Function GetText() As String
    If elapsed > startTime + duration Then Delete
    GetText = text
End Function

'End of file


