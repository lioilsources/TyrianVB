Attribute VB_Name = "GdiPlus"
Option Explicit


Public Const LF_FACESIZEW As Long = LF_FACESIZE * 2

Public Const FlatnessDefault As Single = 1# / 4#

Public Const AlphaShift = 24
Public Const RedShift = 16
Public Const GreenShift = 8
Public Const BlueShift = 0

Public Const AlphaMask = &HFF000000
Public Const RedMask = &HFF0000
Public Const GreenMask = &HFF00
Public Const BlueMask = &HFF

' ----------------------------------------------------------------------------------------------------------------------

Public Type POINTL
    x As Long
    y As Long
End Type

Public Type POINTF
    x As Single
    y As Single
End Type

Public Type RECTL
    Left As Long
    Top As Long
    Right As Long
    Bottom As Long
End Type

Public Type RECTF
    Left As Single
    Top As Single
    Right As Single
    Bottom As Single
End Type

Public Type COLORBYTES
    BlueByte As Byte
    GreenByte As Byte
    RedByte As Byte
    AlphaByte As Byte
End Type

Public Type COLORLONG
    longval As Long
End Type


' Enums ------------------------------------------------------------------

Public Type GdiplusStartupInput
    GdiplusVersion As Long
    DebugEventCallback As LongPtr
    SuppressBackgroundThread As Long
    SuppressExternalCodecs As Long
End Type

Public Enum GpStatus
    Ok = 0
    GenericError = 1
    InvalidParameter = 2
    OutOfMemory = 3
    ObjectBusy = 4
    InsufficientBuffer = 5
    NotImplemented = 6
    Win32Error = 7
    WrongState = 8
    Aborted = 9
    FileNotFound = 10
    ValueOverflow = 11
    AccessDenied = 12
    UnknownImageFormat = 13
    FontFamilyNotFound = 14
    FontStyleNotFound = 15
    NotTrueTypeFont = 16
    UnsupportedGdiplusVersion = 17
    GdiplusNotInitialized = 18
    PropertyNotFound = 19
    PropertyNotSupported = 20
End Enum

Public Enum GpUnit
    UnitWorld = 0           ' World coordinate (non-physical unit)
    UnitDisplay = 1         ' Variable - for PageTransform only
    UnitPixel = 2           ' Each unit is device pixel
    UnitPoint = 3           ' Each unit is printer's point, or 1/72 inch.
    UnitInch = 4
    UnitDocument = 5        ' Each unit is 1/300 inch.
    UnitMillimeter = 6
End Enum

Public Enum CompositingMode
    CompositingModeSourceOver = 0
    CompositinModeSourceCopy = 1
End Enum

Public Enum QualityMode
    QualityModeInvalid = -1
    QualityModeDefault = 0
    QualityModeLow = 1
    QualityModeHigh = 2
End Enum

Public Enum FlushIntention
    FlushIntentionFlush = 0
    FlushIntentionSync = 1
End Enum

Public Enum BrushType
    BrushTypeSolidColor = 0
    BrushTypeHatchFill = 1
    BrushTypeTextureFill = 2
    BrushTypePathGradient = 3
    BrushTypeLinearGradient = 4
End Enum

Public Enum WrapMode
    WrapModeTile = 0
    WrapModeTileFilpX = 1
    WrapModeTileFlipY = 2
    WrapModeTileFlipXY = 3
    WrapModeClamp = 4
End Enum

Public Enum MatrixOrder
    MatrixOrderPrepend = 0
    MatrixOrderAppend = 1
End Enum

Public Enum FillMode
    FillModeAlternate = 0
    FillModeWinding = 1
End Enum

' ----------------------------------------------------------------------------------------------------------------------

Public Declare PtrSafe Function GdipAddPathEllipse Lib "gdiplus" (ByVal Path As LongPtr, ByVal x As Single, ByVal y As Single, _
        ByVal w As Single, ByVal h As Single) As GpStatus
Public Declare PtrSafe Function GdipAddPathLine Lib "gdiplus" (ByVal Path As LongPtr, ByVal x1 As Single, ByVal y1 As Single, _
        ByVal x2 As Single, ByVal y2 As Single) As GpStatus
Public Declare PtrSafe Function GdipAddPathRectangle Lib "gdiplus" (ByVal Path As LongPtr, ByVal x As Single, ByVal y As Single, _
        ByVal w As Single, ByVal h As Single) As GpStatus
Public Declare PtrSafe Function GdipAlloc Lib "gdiplus" (ByVal size As LongPtr) As LongPtr
Public Declare PtrSafe Function GdipBitmapGetPixel Lib "gdiplus" (ByVal Bitmap As LongPtr, ByVal x As Long, ByVal y As Long, _
        color As Long) As GpStatus
Public Declare PtrSafe Function GdipBitmapSetPixel Lib "gdiplus" (ByVal Bitmap As LongPtr, ByVal x As Long, ByVal y As Long, _
        ByVal color As Long) As GpStatus
Public Declare PtrSafe Function GdipClonePath Lib "gdiplus" (ByVal Path As LongPtr, cloned As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipClosePathFigure Lib "gdiplus" (ByVal Path As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipCreateBitmapFromFile Lib "gdiplus" (ByVal filename As String, Bitmap As LongPtr) As GpStatus 'long
Public Declare PtrSafe Function GdipCreateBitmapFromGraphics Lib "gdiplus" (ByVal width As Long, ByVal height As Long, _
        ByVal graphics As LongPtr, Bitmap As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipCreateBitmapFromHBITMAP Lib "gdiplus" (ByVal hbm As LongPtr, ByVal hpal As LongPtr, Bitmap As LongPtr) _
        As GpStatus
Public Declare PtrSafe Function GdipCreateFromHDC Lib "gdiplus" (ByVal hdc As LongPtr, graphics As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipCreateFromHWND Lib "gdiplus" (ByVal hwnd As LongPtr, graphics As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipCreateHBITMAPFromBitmap Lib "gdiplus" (ByVal Bitmap As LongPtr, hBitmap As LongPtr, _
        ByVal background As Long) As GpStatus
Public Declare PtrSafe Function GdipCreateMatrix Lib "gdiplus" (matrix As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipCreateMatrix2 Lib "gdiplus" (ByVal m11 As Single, ByVal m12 As Single, ByVal m21 As Single, _
        ByVal m22 As Single, ByVal dx As Single, ByVal dy As Single, matrix As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipCreatePath Lib "gdiplus" (ByVal brushmode As FillMode, Path As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipCreatePathGradient Lib "gdiplus" (points As POINTF, ByVal count As Long, _
        ByVal wrapMd As WrapMode, polyGrad As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipCreatePathGradientFromPath Lib "gdiplus" (ByVal Path As LongPtr, polyGrad As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipCreatePen1 Lib "gdiplus" (ByVal color As Long, ByVal width As Single, ByVal unit As GpUnit, _
        pen As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipCreatePen2 Lib "gdiplus" (ByVal brush As LongPtr, ByVal width As Single, ByVal unit As GpUnit, _
        pen As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipCreateSolidFill Lib "gdiplus" (ByVal argb As Long, brush As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipCreateTexture Lib "gdiplus" (ByVal Image As LongPtr, ByVal wrapMd As WrapMode, Texture As LongPtr) _
        As GpStatus
Public Declare PtrSafe Function GdipDeleteGraphics Lib "gdiplus" (ByVal graphics As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipDeleteMatrix Lib "gdiplus" (ByVal matrix As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipDeletePath Lib "gdiplus" (ByVal Path As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipDisposeImage Lib "gdiplus" (ByVal Image As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipDrawArc Lib "gdiplus" (ByVal graphics As LongPtr, ByVal pen As LongPtr, ByVal x As Single, _
        ByVal y As Single, ByVal width As Single, ByVal height As Single, ByVal startAngle As Single, _
        ByVal sweepAngle As Single) As GpStatus
Public Declare PtrSafe Function GdipDrawArcI Lib "gdiplus" (ByVal graphics As LongPtr, ByVal pen As LongPtr, ByVal x As Long, _
        ByVal y As Long, ByVal width As Long, ByVal height As Long, ByVal startAngle As Long, _
        ByVal sweepAngle As Single) As GpStatus
Public Declare PtrSafe Function GdipDrawImage Lib "gdiplus" (ByVal graphics As LongPtr, ByVal Image As LongPtr, ByVal x As Single, _
        ByVal y As Single) As GpStatus
Public Declare PtrSafe Function GdipDrawImageI Lib "gdiplus" (ByVal graphics As LongPtr, ByVal Image As LongPtr, ByVal x As Long, _
        ByVal y As Long) As GpStatus
Public Declare PtrSafe Function GdipDrawLine Lib "gdiplus" (ByVal graphics As LongPtr, ByVal pen As LongPtr, ByVal x1 As Single, _
        ByVal y1 As Single, ByVal x2 As Single, ByVal y2 As Single) As GpStatus
Public Declare PtrSafe Function GdipDrawLineI Lib "gdiplus" (ByVal graphics As LongPtr, ByVal pen As LongPtr, ByVal x1 As Long, _
        ByVal y1 As Long, ByVal x2 As Long, ByVal y2 As Long) As GpStatus
Public Declare PtrSafe Function GdipDrawRectangle Lib "gdiplus" (ByVal graphics As LongPtr, ByVal pen As LongPtr, ByVal x As Single, _
        ByVal y As Single, ByVal width As Single, ByVal height As Single) As GpStatus
Public Declare PtrSafe Function GdipDrawRectangleI Lib "gdiplus" (ByVal graphics As LongPtr, ByVal pen As LongPtr, ByVal x As Long, _
        ByVal y As Long, ByVal width As Long, ByVal height As Long) As GpStatus
Public Declare PtrSafe Function GdipFillRectangle Lib "gdiplus" (ByVal graphics As LongPtr, ByVal brush As LongPtr, ByVal x As Single, _
        ByVal y As Single, ByVal width As Single, ByVal height As Single) As GpStatus
Public Declare PtrSafe Function GdipFillRectangleI Lib "gdiplus" (ByVal graphics As LongPtr, ByVal brush As LongPtr, ByVal x As Long, _
        ByVal y As Long, ByVal width As Long, ByVal height As Long) As GpStatus
Public Declare PtrSafe Function GdipFillEllipse Lib "gdiplus" (ByVal graphics As LongPtr, ByVal brush As LongPtr, ByVal x As Single, _
        ByVal y As Single, ByVal w As Single, ByVal h As Single) As GpStatus
Public Declare PtrSafe Function GdipFillEllipseI Lib "gdiplus" (ByVal graphics As LongPtr, ByVal brush As LongPtr, ByVal x As Long, _
        ByVal y As Long, ByVal w As Long, ByVal h As Long) As GpStatus
Public Declare PtrSafe Function GdipFlush Lib "gdiplus" (ByVal graphics As LongPtr, ByVal intention As FlushIntention) As GpStatus
Public Declare PtrSafe Sub GdipFree Lib "gdiplus" (ByVal ptr As LongPtr)
Public Declare PtrSafe Function GdipGetDC Lib "gdiplus" (ByVal graphics As LongPtr, hdc As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipGetImageGraphicsContext Lib "gdiplus" (ByVal Image As LongPtr, graphics As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipGraphicsClear Lib "gdiplus" (ByVal graphics As LongPtr, ByVal lColor As Long) As GpStatus
Public Declare PtrSafe Function GdipGetImageFlags Lib "gdiplus" (ByVal Image As LongPtr, flags As Long) As GpStatus
Public Declare PtrSafe Function GdipGetImageHeight Lib "gdiplus" (ByVal Image As LongPtr, height As Long) As GpStatus
Public Declare PtrSafe Function GdipGetImageWidth Lib "gdiplus" (ByVal Image As LongPtr, width As Long) As GpStatus
Public Declare PtrSafe Function GdipGetTextureImage Lib "gdiplus" (ByVal brush As LongPtr, Image As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipLoadImageFromFile Lib "gdiplus" (ByVal filename As String, Image As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipLoadImageFromFileICM Lib "gdiplus" (ByVal filename As String, Image As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipMultiplyMatrix Lib "gdiplus" (ByVal matrix As LongPtr, ByVal matrix2 As LongPtr, _
        ByVal order As MatrixOrder) As GpStatus
Public Declare PtrSafe Function GdipReleaseDC Lib "gdiplus" (ByVal graphics As LongPtr, ByVal hdc As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipResetPath Lib "gdiplus" (ByVal Path As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipRestoreGraphics Lib "gdiplus" (ByVal graphics As LongPtr, ByVal state As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipRotateMatrix Lib "gdiplus" (ByVal matrix As LongPtr, ByVal angle As Single, _
        ByVal order As MatrixOrder) As GpStatus
Public Declare PtrSafe Function GdipRotateTextureTransform Lib "gdiplus" (ByVal brush As LongPtr, ByVal angle As Single, _
        ByVal order As MatrixOrder) As GpStatus
Public Declare PtrSafe Function GdipSaveGraphics Lib "gdiplus" (ByVal graphics As LongPtr, state As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipSetRenderingOrigin Lib "gdiplus" (ByVal graphics As LongPtr, ByVal x As Long, _
        ByVal y As Long) As GpStatus

Public Declare PtrSafe Function GdipSetCompositingMode Lib "gdiplus" (ByVal graphics As LongPtr, ByVal compMode As CompositingMode) _
        As GpStatus
Public Declare PtrSafe Function GdipSetCompositingQuality Lib "gdiplus" (ByVal graphics As LongPtr, ByVal compQlty As QualityMode) _
        As GpStatus
Public Declare PtrSafe Function GdipSetPathGradientCenterColor Lib "gdiplus" (ByVal brush As LongPtr, ByVal color As Long) As GpStatus
Public Declare PtrSafe Function GdipSetPathGradientSurroundColorsWithCount Lib "gdiplus" (ByVal brush As LongPtr, argb As Long, _
        cnt As Long) As GpStatus
Public Declare PtrSafe Function GdipSetTextureTransform Lib "gdiplus" (ByVal brush As LongPtr, ByVal matrix As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipSetWorldTransform Lib "gdiplus" (ByVal graphics As LongPtr, ByVal matrix As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipStartPathFigure Lib "gdiplus" (ByVal Path As LongPtr) As GpStatus
Public Declare PtrSafe Function GdipTranslateMatrix Lib "gdiplus" (ByVal matrix As LongPtr, ByVal dx As Single, ByVal dy As Single, _
        ByVal rder As MatrixOrder) As GpStatus
Public Declare PtrSafe Function GdipTranslateTextureTransform Lib "gdiplus" (ByVal brush As LongPtr, ByVal dx As Single, ByVal dy As Single, _
        ByVal order As MatrixOrder) As GpStatus
Public Declare PtrSafe Function GdiplusStartup Lib "gdiplus" (token As LongPtr, inputbuf As GdiplusStartupInput, _
        Optional ByVal outputbuf As LongPtr = 0) As GpStatus
Public Declare PtrSafe Sub GdiplusShutdown Lib "gdiplus" (ByVal token As LongPtr)



' Helper Functions --------------------------------------------------------------------

Public Function ColorARGB(ByVal alpha As Byte, ByVal red As Byte, ByVal green As Byte, ByVal blue As Byte) As Long
    Dim bytestruct As COLORBYTES
    Dim result As COLORLONG
    
    With bytestruct
        .AlphaByte = alpha
        .RedByte = red
        .GreenByte = green
        .BlueByte = blue
    End With
    
    LSet result = bytestruct
    ColorARGB = result.longval
End Function


Public Function status(ByVal s As GpStatus) As String
    Select Case s
        Case 0
                status = "Ok"
        Case 1
                status = "GenericError"
        Case 2
                status = "InvalidParameter"
        Case 3
                status = "OutOfMemory"
        Case 4
                status = "ObjectBusy"
        Case 5
                status = "InsufficientBuffer"
        Case 6
                status = "NotImplemented"
        Case 7
                status = "Win32Error"
        Case 8
                status = "WrongState"
        Case 9
                status = "Aborted"
        Case 10
                status = "FileNotFound"
        Case 11
                status = "ValueOverflow"
        Case 12
                status = "AccessDenied"
        Case 13
                status = "UnknownImageFormat"
        Case 14
                status = "FontFamilyNotFound"
        Case 15
                status = "FontStyleNotFound"
        Case 16
                status = "NotTrueTypeFont"
        Case 17
                status = "UnsupportedGdiplusVersion"
        Case 18
                status = "GdiplusNotInitialized"
        Case 19
                status = "PropertyNotFound"
        Case 20
                status = "PropertyNotSupported"
        Case Else
                status = "Unknown"
    End Select
End Function


'End of file
