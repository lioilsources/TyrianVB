VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Library"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Class Library (image lib)

Private head As LibItem
Private tail As LibItem


Public Sub AddItem(ByVal name As String, ByVal i As Image, Optional draw As Boolean = False, Optional CreateMask As Boolean = True)
    If i Is Nothing Then
        Logt "AddItem skipped: [" & name & "] has no image object", False
        Exit Sub
    End If
    Dim it As New LibItem
    it.name = name
    Set it.img = i
    If CreateMask And i.handle = 0 Then Call CreateImageMask(i)
    it.img.drawInLoop = draw
    If tail Is Nothing Then
        Set head = it
        Set tail = it
    Else
        Set tail.nxt = it
        Set tail = it
    End If
    Logt it.img.width & "x" & it.img.height & " " & it.name & "=" & it.img.filename, False
End Sub


Public Function GetItem(ByVal name As String) As Image
    Dim it As LibItem
    Set it = head
    While Not it Is Nothing
        If it.name = name Then
            Set GetItem = it.img
            Exit Function
        End If
        Set it = it.nxt
    Wend
    Set GetItem = Nothing
End Function


Public Sub Clear()
    While Not head Is Nothing
        If head.img.handle <> 0 Then
            Call GdipDisposeImage(head.img.handle)
            If test Then Logt "Disposed " & head.img.filename, False
        End If
        Set head = head.nxt
    Wend
    Set tail = Nothing
End Sub

'End of file


