VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "Explosion"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
Option Compare Database

Public parent As Objects
Public img As Image
Public stp As Integer
Public maxStp As Integer
Public nxt As Explosion
Public prv As Explosion
Public hostSize As Integer
Public sx As Integer
Public sy As Integer



