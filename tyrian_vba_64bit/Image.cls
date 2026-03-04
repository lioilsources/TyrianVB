VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Image"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Class Image

Public pict As StdPicture
Public filename As String
Public handle As LongPtr
Public hBitmap As LongPtr
Public hMask As LongPtr
Public width As Long
Public height As Long
Public x As Single
Public y As Single
Public size As Single
Public drawInLoop As Boolean
Public cust As Single
Public startX As Single
Public startY As Single
Public filterColor As Long


Public Sub Setup(ByVal px As Single, ByVal py As Single, ByVal w As Long, ByVal h As Long)
    x = px
    y = py
    width = w
    height = h
End Sub

'End of file


