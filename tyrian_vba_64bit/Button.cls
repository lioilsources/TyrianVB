VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Button"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Class Button

Public x As Integer
Public y As Integer
Public x2 As Integer
Public y2 As Integer
Public w As Integer
Public h As Integer
Public display As Boolean
Public over As Boolean
Public pressed As Boolean
Public param As Variant
Public param2 As Variant
Public score As Long
Public nxt As Button
Public ac As ButtonAction
Public domain As ButtonDomain
Public imgDown As Image
Public imgUp As Image
Public imgOver As Image
Public parent As Objects


Public Enum ButtonAction
    Buy = 999
    Continue = 1000
    ExitApp = 1001
    NotAssigned = 1002
    Sell = 1003
    Upgrade = 1004
    NextPage = 1005
End Enum


Public Enum ButtonDomain
    CommandCenter
    OSD
    Screen
End Enum


Public Sub Load(ByVal imgDownName As String, ByVal imgUpName As String, ByVal imgOverName As String)
    Set imgDown = CloneImage(imgLib.GetItem(imgDownName))
    w = imgDown.width
    h = imgDown.height
    Set imgUp = CloneImage(imgLib.GetItem(imgUpName))
    If imgUp.width <> w Or imgUp.height <> h Then Logt "Warning: Button image " & imgUpName & " size differs from " & imgDownName
    Set imgOver = CloneImage(imgLib.GetItem(imgOverName))
    If imgOver.width <> w Or imgOver.height <> h Then Logt "Warning: Button image " & imgOverName & " size differs from " & imgDownName
    x2 = x + w
    y2 = y + h
End Sub

'End of file


