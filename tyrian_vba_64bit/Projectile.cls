VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Projectile"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
' Class Projectile

Public img As Image
Public damage As Long
Public speed As Integer
Public parent As Device
Public nxt As Projectile
Public prv As Projectile
Public pool As Boolean
Public x2 As Integer
Public y2 As Integer


Public Sub Delete()
    Static p As Projectile
    pool = True
    If prv Is Nothing Then
        Set parent.fProjectile = nxt
    Else
        Set prv.nxt = nxt
    End If
    If Not nxt Is Nothing Then Set nxt.prv = prv Else Set parent.lProjectile = prv
    Set prv = Nothing
    If parent.proPool Is Nothing Then
        Set nxt = Nothing
        Set parent.proPool = Me
    Else
        Set nxt = parent.proPool
        Set nxt.prv = Me
        Set parent.proPool = Me
    End If
End Sub

'End of file


