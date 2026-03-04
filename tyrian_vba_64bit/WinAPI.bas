Attribute VB_Name = "WinAPI"
' Window Styles
Public Const WS_OVERLAPPED As Long = &H0&
Public Const WS_MAXIMIZE As Long = &H10000000
Public Const WS_MAXIMIZEBOX As Long = &H10000
Public Const WS_MINIMIZEBOX As Long = &H20000
Public Const WS_THICKFRAME As Long = &H40000
Public Const WS_SYSMENU As Long = &H80000
Public Const WS_CAPTION As Long = &HC00000
Public Const WS_DISABLED As Long = &H800000
Public Const WS_CHILD As Long = &H40000000
Public Const WS_POPUP As Long = &H80000000
Public Const WS_OVERLAPPEDWINDOW As Long = (WS_OVERLAPPED Or WS_CAPTION Or WS_SYSMENU Or WS_THICKFRAME Or WS_MINIMIZEBOX _
                                            Or WS_MAXIMIZEBOX)
' Window Styles Extended
Public Const WS_EX_DLGMODALFRAME As Long = &H1&
Public Const WS_EX_NOPARENTNOTIFY As Long = &H4&
Public Const WS_EX_TOPMOST As Long = &H8&
Public Const WS_EX_TRANSPARENT As Long = &H20&
Public Const WS_EX_APPWINDOW As Long = &H40000

' Class Styles
Public Const CS_VREDRAW As Long = &H1
Public Const CS_HREDRAW As Long = &H2
Public Const CS_DBLCLKS As Long = &H8
Public Const CS_OWNDC As Long = &H20
Public Const CS_CLASSDC As Long = &H40
Public Const CS_PARENTDC As Long = &H80

Public Const IDI_APPLICATION As Long = 32512
Public Const IDC_ARROW As Long = 32512
Public Const COLOR_WINDOW As Long = 5
Public Const COLOR_BTNFACE As Long = 15
Public Const WHITE_BRUSH As Long = 0

Public Const CW_USEDEFAULT As Long = &H80000000

Public Const SW_SHOWNORMAL As Long = 1
Public Const SW_SHOW As Long = 5
Public Const SW_SHOWDEFAULT As Long = 10

' Window Messages
Public Const WM_CREATE As Long = &H1
Public Const WM_DESTROY As Long = &H2
Public Const WM_ACTIVATE As Long = &H6
Public Const WM_PAINT As Long = &HF
Public Const WM_ERASEBKGND As Long = &H14
Public Const WM_SHOWWINDOW As Long = &H18
Public Const WM_ACTIVATEAPP As Long = &H1C
Public Const WM_SETCURSOR As Long = &H20
Public Const WM_DRAWITEM As Long = &H2B
Public Const WM_NCHITTEST As Long = &H84
Public Const WM_NCPAINT As Long = &H85
Public Const WM_KEYDOWN As Long = &H100
Public Const WM_KEYUP As Long = &H101
Public Const WM_CHAR As Long = &H102
Public Const WM_TIMER As Long = &H113

Public Const WM_MOUSEMOVE As Long = &H200
Public Const WM_LBUTTONDOWN  As Long = &H201
Public Const WM_LBUTTONUP As Long = &H202
Public Const WM_LBUTTONDBLCLK As Long = &H203
Public Const WM_RBUTTONDOWN As Long = &H204
Public Const WM_RBUTTONUP As Long = &H205
Public Const WM_RBUTTONDBLCLK As Long = &H206
Public Const WM_MBUTTONDOWN As Long = &H207
Public Const WM_MBUTTONUP As Long = &H208
Public Const WM_MBUTTONDBLCLK  As Long = &H209

' Raster OPerations
Public Const SRCCOPY As Long = &HCC0020     'dest = source
Public Const SRCPAINT As Long = &HEE0086    'dest = source OR dest
Public Const SRCAND As Long = &H8800C6      'dest = source AND dest
Public Const SRCINVERT As Long = &H660046   'dest = source XOR dest
Public Const SRCERASE As Long = &H440328    'dest = source AND (NOT dest)
Public Const NOTSRCCOPY As Long = &H330008  'dest = (NOT source)
Public Const NOTSRCERASE As Long = &H1100A6 'dest = (NOT source) AND (NOT dest)
Public Const MERGECOPY As Long = &HC000CA   'dest = (source AND pattern)
Public Const MERGEPAINT As Long = &HBB0226  'dest = (NOT source) OR dest
Public Const PATCOPY As Long = &HF00021     'dest = pattern
Public Const PATPAINT As Long = &HFB0A09    'dest = DPSnoo
Public Const PATINVERT As Long = &H5A0049   'dest = pattern XOR dest
Public Const DSTINVERT As Long = &H550009   'dest = (NOT dest)
Public Const BLACKNESS As Long = &H42       'dest = BLACK
Public Const WHITENESS As Long = &HFF0062   'dest = WHITE

' SetWindowPos Flags
Public Const SWP_SHOWWINDOW As Long = &H40
Public Const SWP_HIDEWINDOW As Long = &H80


' Pen styles
Public Const PS_SOLID As Long = 0
Public Const PS_DASH As Long = 1
Public Const PS_DOT As Long = 2

' Brush styles
Public Const BS_SOLID As Long = 0
Public Const BS_NULL As Long = 1
Public Const BS_HOLLOW As Long = BS_NULL
Public Const BS_HATCHET As Long = 2
Public Const BS_PATTERN As Long = 3

'Hatch styles
Public Const HS_HORIZONTAL As Long = 0
Public Const HS_VERTICAL As Long = 1
Public Const HS_FDIAGONAL As Long = 2
Public Const HS_BDIAGONAL As Long = 3
Public Const HS_CROSS As Long = 4
Public Const HS_DIAGCROSS As Long = 5
Public Const HS_FDIAGONAL1 As Long = 6
Public Const HS_BDIAGONAL1 As Long = 7
Public Const HS_SOLID As Long = 8
Public Const HS_DENSE1 As Long = 9
Public Const HS_DENSE2 As Long = 10
Public Const HS_DENSE3 As Long = 11
Public Const HS_DENSE4 As Long = 12
Public Const HS_DENSE5 As Long = 13
Public Const HS_DENSE6 As Long = 14
Public Const HS_DENSE7 As Long = 15
Public Const HS_DENSE8 As Long = 16
Public Const HS_NOSHADE As Long = 17
Public Const HS_HALFTONE As Long = 18
Public Const HS_SOLIDCLR As Long = 19
Public Const HS_DITHEREDCLR As Long = 20
Public Const HS_SOLIDTEXTCLR As Long = 21
Public Const HS_DITHEREDTEXTCLR As Long = 22
Public Const HS_SOLIDBKCLR As Long = 23
Public Const HS_DITHEREDBKCLR As Long = 24
Public Const HS_API_MAX As Long = 25

' Background modes
Public Const TRANSPARENT As Long = 1
Public Const OPAQUE As Long = 2
Public Const BK_LAST As Long = 2

' DrawText format flags
Public Const DT_TOP As Long = &H0
Public Const DT_LEFT As Long = &H0
Public Const DT_CENTER As Long = &H1
Public Const DT_RIGHT As Long = &H2
Public Const DT_VCENTER As Long = &H4
Public Const DT_BOTTOM As Long = &H8
Public Const DT_WORDBREAK As Long = &H10
Public Const DT_SINGLELINE As Long = &H20
Public Const DT_EXPANDTABS As Long = &H40
Public Const DT_TABSTOP As Long = &H80
Public Const DT_NOCLIP As Long = &H100
Public Const DT_EXTERNALLEADING As Long = &H200
Public Const DT_CALCRECT As Long = &H400
Public Const DT_NOPREFIX As Long = &H800
Public Const DT_INTERNAL As Long = &H1000

Public Const TA_NOUPDATECP As Long = 0
Public Const TA_UPDATECP As Long = 1
Public Const TA_LEFT As Long = 0
Public Const TA_RIGHT As Long = 2
Public Const TA_CENTER As Long = 6
Public Const TA_TOP As Long = 0
Public Const TA_BOTTOM As Long = 8
Public Const TA_BASELINE As Long = 24
Public Const TA_MASK As Long = (TA_BASELINE + TA_CENTER + TA_UPDATECP)

' StretchBlt Modes
Public Const STRETCH_ANDSCANS As Long = 1
Public Const STRETCH_ORSCANS As Long = 2
Public Const STRETCH_DELETESCANS As Long = 3
Public Const STRETCH_HALFTONE As Long = 4


Public Type Bitmap '14 bytes
    bmType As Long
    bmWidth As Long
    bmHeight As Long
    bmWidthBytes As Long
    bmPlanes As Integer
    bmBitsPixel As Integer
    bmBits As LongPtr
End Type

Public Type BITMAPCOREHEADER '12 bytes - DIB
    bcSize As Long
    bcWidth As Integer
    bcHeight As Integer
    bcPlanes As Integer
    bcBitCount As Integer
End Type


' biCompression field
Public Const BI_RGB As Long = 0&
Public Const BI_RLE8 As Long = 1&
Public Const BI_RLE4 As Long = 2&
Public Const BI_bitfields As Long = 3&

Public Type BITMAPINFOHEADER '40 bytes
    biSize As Long
    biWidth As Long
    biHeight As Long
    biPlanes As Integer
    biBitCount As Integer
    biCompression As Long
    biSizeImage As Long
    biXPelsPerMeter As Long
    biYPelsPerMeter As Long
    biClrUsed As Long
    biClrImportant As Long
End Type

Public Type RGBTRIPLE
    rgbtBlue As Byte
    rgbtGreen As Byte
    rgbtRed As Byte
End Type

Public Type RGBQUAD
    rgbBlue As Byte
    rgbGreen As Byte
    rgbRed As Byte
    rgbReserved As Byte
End Type

Public Type BITMAPINFO
    bmiHeader As BITMAPINFOHEADER
    bmiColors As RGBQUAD
End Type

Public Type BITMAPCOREINFO
    bmciHeader As BITMAPCOREHEADER
    bmciColors As RGBTRIPLE
End Type

Public Type POINTAPI
    x As Long
    y As Long
End Type

Public Type LOGPEN
    lopnStyle As Long
    lopnWidth As Long
    lopnColor As Long
End Type

Public Type LOGBRUSH
    lbStyle As Long
    lbColor As Long
    lbHatch As LongPtr
End Type

Public Type msg
    hwnd As LongPtr
    Message As Long
    wParam As LongPtr
    lParam As LongPtr
    time As Long
    pt As POINTAPI
End Type

Public Type WNDCLASSEX
    cbSize As Long
    style As Long
    lpfnWndProc As LongPtr
    cbClsExtra As Long
    cbWndExtra As Long
    hInstance As LongPtr
    hIcon As LongPtr
    hCursor As LongPtr
    hbrBackground As LongPtr
    lpszMenuName As String
    lpszClassName As String
    hIconSm As LongPtr
End Type

Type RECT
    Left As Long
    Top As Long
    Right As Long
    Bottom As Long
End Type

Type PAINTSTRUCT
    hdc As LongPtr
    fErase As Long
    rePaint As RECT
    fRestore As Long
    fIncUpdate As Long
    rgbReserved As Byte
End Type


' Logical font
Public Const LF_FACESIZE As Long = 32
Public Const LF_FULLFACESIZE As Long = 64

Public Type LOGFONT
    lfHeight As Long
    lfWidth As Long
    lfEscapement As Long
    lfOrientation As Long
    lfWeight As Long
    lfItalic As Byte
    lfUnderline As Byte
    lfStrikeOut As Byte
    lfCharset As Byte
    lfOutPrecision As Byte
    lfClipPrecision As Byte
    lfQuality As Byte
    lfPitchAndFamily As Byte
    lfFaceName(LF_FACESIZE) As Byte
End Type

Public Const CCHDEVICENAME As Long = 32
Public Const CCHFORMNAME As Long = 32
Public Const DM_SPECVERSION As Long = &H320

Public Type DEVMODE
    dmDeviceName As String * CCHDEVICENAME
    dmSpecVersion As Integer
    dmDriverVersion As Integer
    dmSize As Integer
    dmDriverExtra As Integer
    dmFields As Long
    dmOrientation As Integer
    dmPaperSize As Integer
    dmPaperLength As Integer
    dmPaperWidth As Integer
    dmScale As Integer
    dmCopies As Integer
    dmDefaultSource As Integer
    dmPrintQuality As Integer
    dmColor As Integer
    dmDuplex As Integer
    dmYResolution As Integer
    dmTTOption As Integer
    dmCollate As Integer
    dmFormName As String * CCHFORMNAME
    dmUnusedPadding As Integer
    dmBitsPerPel As Integer
    dmPelsWidth As Long
    dmPelsHeight As Long
    dmDisplayFlags As Long
    dmDisplayFrequency As Long
End Type

Public Const LOGPIXELSX As Long = 88
Public Const LOGPIXELSY As Long = 90
Public Const PHYSICALOFFSETX As Long = 112
Public Const PHYSICALOFFSETY As Long = 113

' ----------------------------------------------------------------------------------------------------------------------
' ----------------------------------------------- U S E R 3 2 ----------------------------------------------------------
' ----------------------------------------------------------------------------------------------------------------------
Declare PtrSafe Function BeginPaint Lib "user32" (ByVal hwnd As LongPtr, lpPaint As PAINTSTRUCT) As LongPtr
Declare PtrSafe Function CloseWindow Lib "user32" (ByVal hwnd As LongPtr) As Long
Declare PtrSafe Function CreateWindowEx Lib "user32" Alias "CreateWindowExA" (ByVal dwExStyle As Long, _
                            ByVal lpClassName As String, ByVal lpWindowName As String, ByVal dwStyle As Long, _
                            ByVal x As Long, ByVal y As Long, ByVal nWidth As Long, ByVal nHeight As Long, _
                            ByVal hWndParent As LongPtr, ByVal hMenu As LongPtr, ByVal hInstance As LongPtr, lpParam As Any) As LongPtr
Declare PtrSafe Function DefWindowProc Lib "user32" Alias "DefWindowProcA" (ByVal hwnd As LongPtr, ByVal wMsg As Long, _
                            ByVal wParam As LongPtr, ByVal lParam As LongPtr) As LongPtr
Declare PtrSafe Function DestroyWindow Lib "user32" (ByVal hwnd As LongPtr) As Long
Declare PtrSafe Function DispatchMessage Lib "user32" Alias "DispatchMessageA" (lpMsg As msg) As LongPtr
Declare PtrSafe Function DrawText Lib "user32" Alias "DrawTextA" (ByVal hdc As LongPtr, ByVal lpStr As String, ByVal nCount As Long, _
                            lpRect As RECT, ByVal wFormat As Long) As Long
Declare PtrSafe Function EndPaint Lib "user32" (ByVal hwnd As LongPtr, lpPaint As PAINTSTRUCT) As Long
Declare PtrSafe Function GetClientRect Lib "user32" (ByVal hwnd As LongPtr, lpRect As RECT) As Long
Declare PtrSafe Function GetDC Lib "user32" (ByVal hwnd As LongPtr) As LongPtr
Declare PtrSafe Function GetMessage Lib "user32" Alias "GetMessageA" (lpMsg As msg, ByVal hwnd As LongPtr, _
                            ByVal wMsgFilterMin As Long, ByVal wMsgFilterMax As Long) As Long
Declare PtrSafe Function GetMessageTime Lib "user32" () As Long
Declare PtrSafe Function GetWindowDC Lib "user32" (ByVal hwnd As LongPtr) As LongPtr
Declare PtrSafe Function InvalidateRect Lib "user32" (ByVal hwnd As LongPtr, lpRect As RECT, ByVal bErase As Long) As Long
Declare PtrSafe Function KillTimer Lib "user32" (ByVal hwnd As LongPtr, ByVal nIDEvent As LongPtr) As Long
Declare PtrSafe Function LoadBitmap Lib "user32" Alias "LoadBitmapA" (ByVal hInstance As LongPtr, ByVal lpBitmapName As String) _
                            As LongPtr
Declare PtrSafe Function LoadCursor Lib "user32" Alias "LoadCursorA" (ByVal hInstance As LongPtr, ByVal lpCursorName As LongPtr) _
                            As LongPtr
Declare PtrSafe Function LoadCursorFromFile Lib "user32" Alias "LoadCursorFromFileA" (ByVal lpFileName As String) As LongPtr
Declare PtrSafe Function LoadIcon Lib "user32" Alias "LoadIconA" (ByVal hInstance As LongPtr, ByVal lpIconName As LongPtr) As LongPtr
Declare PtrSafe Sub PostQuitMessage Lib "user32" (ByVal nExitCode As Long)
Declare PtrSafe Function RegisterClassEx Lib "user32" Alias "RegisterClassExA" (lpwcx As WNDCLASSEX) As Long
Declare PtrSafe Function SendMessage Lib "user32" Alias "SendMessageA" (ByVal hwnd As LongPtr, ByVal wMsg As Long, _
                            ByVal wParam As LongPtr, ByVal lParam As LongPtr) As LongPtr
Declare PtrSafe Function SetCursor Lib "user32" (ByVal hCursor As LongPtr) As LongPtr
Declare PtrSafe Function SetCursorPos Lib "user32" (ByVal x As Long, ByVal y As Long) As Long
Declare PtrSafe Function SetTimer Lib "user32" (ByVal hwnd As LongPtr, ByVal nIDEvent As LongPtr, ByVal uElapse As Long, _
                            ByVal lpTimerFunc As LongPtr) As LongPtr
Declare PtrSafe Function SetWindowPos Lib "user32" (ByVal hwnd As LongPtr, ByVal hWndInsertAfter As LongPtr, ByVal x As Long, _
                            ByVal y As Long, ByVal cx As Long, ByVal cy As Long, ByVal wFlags As Long) As Long
Declare PtrSafe Function ShowCursor Lib "user32" (ByVal bShow As Long) As Long
Declare PtrSafe Function ShowWindow Lib "user32" (ByVal hwnd As LongPtr, ByVal nCmdShow As Long) As Long
Declare PtrSafe Function TranslateMessage Lib "user32" (lpMsg As msg) As Long
Declare PtrSafe Function UpdateWindow Lib "user32" (ByVal hwnd As LongPtr) As Long

' ----------------------------------------------------------------------------------------------------------------------
' ---------------------------------------------- K E R N E L 3 2 -------------------------------------------------------
' ----------------------------------------------------------------------------------------------------------------------
Declare PtrSafe Sub CopyMemory Lib "kernel32" Alias "RtlMoveMemory" (src As Any, dst As Any, ByVal cbLen As LongPtr)
Declare PtrSafe Function GetModuleHandle Lib "kernel32" Alias "GetModuleHandleA" (ByVal lpModuleName As LongPtr) As LongPtr
'Declare PtrSafe Function GetCurrentDirectory Lib "kernel32" (ByVal bufLen As Long, lpDir As String) As Long
Declare PtrSafe Function GetCurrentDirectory Lib "kernel32" Alias "GetCurrentDirectoryA" (ByVal bufLen As Long, ByVal lpDir As String) As Long
Declare PtrSafe Function GetSystemDirectory Lib "kernel32" Alias "GetSystemDirectoryA" (ByVal lpBuffer As String, _
                            ByVal nSize As Long) As Long
Declare PtrSafe Sub Sleep Lib "kernel32" (ByVal dwMilliseconds As Long)


' ----------------------------------------------------------------------------------------------------------------------
' -------------------------------------------------- G D I 3 2 ---------------------------------------------------------
' ----------------------------------------------------------------------------------------------------------------------
Declare PtrSafe Function Arc Lib "gdi32" (ByVal hdc As LongPtr, ByVal x1 As Long, ByVal y1 As Long, ByVal x2 As Long, _
                            ByVal y2 As Long, ByVal u As Double, ByVal v As Double) As Long
Declare PtrSafe Function BeginPath Lib "gdi32" (ByVal hdc As LongPtr) As Long
Declare PtrSafe Function BitBlt Lib "gdi32" (ByVal hDestDC As LongPtr, ByVal x As Long, ByVal y As Long, ByVal nWidth As Long, _
                            ByVal nHeight As Long, ByVal hSrcDC As LongPtr, ByVal xSrc As Long, ByVal ySrc As Long, _
                            ByVal dwROP As Long) As Long
Declare PtrSafe Function CreateBrushIndirect Lib "gdi32" (lpLogBrush As LOGBRUSH) As LongPtr
Declare PtrSafe Function CreateBitmap Lib "gdi32" (ByVal nWidth As Long, ByVal nHeight As Long, ByVal nPlanes As Long, _
                            ByVal nBitCount As Long, lpBits As Any) As LongPtr
Declare PtrSafe Function CreateCompatibleBitmap Lib "gdi32" (ByVal hdc As LongPtr, ByVal nWidth As Long, ByVal nHeight As Long) As LongPtr
Declare PtrSafe Function CreateCompatibleDC Lib "gdi32" (ByVal hdc As LongPtr) As LongPtr
Declare PtrSafe Function CreateDC Lib "gdi32" Alias "CreateDCA" (ByVal lpDriverName As String, ByVal lpDeviceName As String, _
                            ByVal lpOutput As String, lpInitData As DEVMODE) As LongPtr
Declare PtrSafe Function CreateFontIndirect Lib "gdi32" Alias "CreateFontIndirectA" (lpLogFont As LOGFONT) As LongPtr
Declare PtrSafe Function CreatePen Lib "gdi32" (ByVal nPenStyle As Long, ByVal nWidth As Long, ByVal crColor As Long) As LongPtr
Declare PtrSafe Function CreateSolidBrush Lib "gdi32" (ByVal crColor As Long) As LongPtr
Declare PtrSafe Function DeleteDC Lib "gdi32" (ByVal hdc As LongPtr) As Long
Declare PtrSafe Function DeleteObject Lib "gdi32" (ByVal hObject As LongPtr) As Long
Declare PtrSafe Function Ellipse Lib "gdi32" (ByVal hdc As LongPtr, ByVal x1 As Long, ByVal y1 As Long, ByVal x2 As Long, _
                            ByVal y2 As Long) As Long
Declare PtrSafe Function EndPath Lib "gdi32" (ByVal hdc As LongPtr) As Long
Declare PtrSafe Function EnumFontFamilies Lib "gdi32" Alias "EnumFontFamiliesA" (ByVal hdc As LongPtr, ByVal lpszFontFamily As String, _
                            ByVal lpEnumFontFamProc As LongPtr, ByVal lParam As LongPtr) As Long
Declare PtrSafe Function FillPath Lib "gdi32" (ByVal hdc As LongPtr) As Long
Declare PtrSafe Function FloodFill Lib "gdi32" (ByVal hdc As LongPtr, ByVal x As Long, ByVal y As Long, ByVal style As Long) As Long
Declare PtrSafe Function GdiFlush Lib "gdi32" () As Long
Declare PtrSafe Function GetDeviceCaps Lib "gdi32" (ByVal hdc As LongPtr, ByVal nIndex As Long) As Long
Declare PtrSafe Function GetPixel Lib "gdi32" (ByVal hdc As LongPtr, ByVal x As Long, ByVal y As Long) As Long
Declare PtrSafe Function GetStockObject Lib "gdi32" (ByVal fnObject As Long) As LongPtr
Declare PtrSafe Function InvertRgn Lib "gdi32" (ByVal hdc As LongPtr, ByVal hRgn As LongPtr) As Long
Declare PtrSafe Function LineTo Lib "gdi32" (ByVal hdc As LongPtr, ByVal x As Long, ByVal y As Long) As Long
Declare PtrSafe Function MaskBlt Lib "gdi32" (ByVal hdcDest As LongPtr, ByVal xDest As Long, ByVal yDest As Long, ByVal wdthDest As Long, _
                            ByVal hghtDest As Long, ByVal hdcSrc As LongPtr, ByVal xSrc As Long, ByVal ySrc As Long, _
                            ByVal hbmMask As LongPtr, ByVal xMask As Long, ByVal yMask As Long, ByVal dwROP As Long) As Long
Declare PtrSafe Function MoveToEx Lib "gdi32" (ByVal hdc As LongPtr, ByVal x As Long, ByVal y As Long, ByVal u As LongPtr) As Long
Declare PtrSafe Function Rectangle Lib "gdi32" (ByVal hdc As LongPtr, ByVal x1 As Long, ByVal y1 As Long, ByVal x2 As Long, _
                            ByVal y2 As Long) As Long
Declare PtrSafe Function SaveDC Lib "gdi32" (ByVal hdc As LongPtr) As Long
Declare PtrSafe Function SelectObject Lib "gdi32" (ByVal hdc As LongPtr, ByVal hObject As LongPtr) As LongPtr
Declare PtrSafe Function SetBkColor Lib "gdi32" (ByVal hdc As LongPtr, ByVal crColor As Long) As Long
Declare PtrSafe Function SetBkMode Lib "gdi32" (ByVal hdc As LongPtr, ByVal nBkMode As Long) As Long
Declare PtrSafe Function SetPixel Lib "gdi32" (ByVal hdc As LongPtr, ByVal x As Long, ByVal y As Long, ByVal color As Long) As Long
Declare PtrSafe Function SetPixelV Lib "gdi32" (ByVal hdc As LongPtr, ByVal x As Long, ByVal y As Long, ByVal color As Long) As Long
Declare PtrSafe Function SetTextAlign Lib "gdi32" (ByVal hdc As LongPtr, ByVal wFlags As Long) As Long
Declare PtrSafe Function SetTextColor Lib "gdi32" (ByVal hdc As LongPtr, ByVal crColor As Long) As Long
Declare PtrSafe Function SetStretchBltMode Lib "gdi32" (ByVal hdc As LongPtr, ByVal nStretchMode As Long) As Long
Declare PtrSafe Function StretchBlt Lib "gdi32" (ByVal hdc As LongPtr, ByVal x As Long, ByVal y As Long, _
                            ByVal nWidth As Long, ByVal nHeight As Long, ByVal hSrcDC As LongPtr, ByVal xSrc As Long, _
                            ByVal ySrc As Long, ByVal nSrcWidth As Long, ByVal nSrcHeight As Long, ByVal dwROP As Long) _
                            As Long
Declare PtrSafe Function StrokePath Lib "gdi32" (ByVal hdc As LongPtr) As Long
Declare PtrSafe Function StrokeAndFillPath Lib "gdi32" (ByVal hdc As LongPtr) As Long
Declare PtrSafe Function TextOut Lib "gdi32" Alias "TextOutA" (ByVal hdc As LongPtr, ByVal x As Long, ByVal y As Long, _
                            ByVal lpString As String, ByVal nCount As Long) As Long


' ----------------------------------------------------------------------------------------------------------------------
' -------------------------------------------------- O T H E R ---------------------------------------------------------
' ----------------------------------------------------------------------------------------------------------------------
Declare PtrSafe Function DeviceCapabilities Lib "winspoll.drv" Alias "DeviceCapabilitiesA" (ByVal lpDeviceName As String, _
                            ByVal lpPort As String, ByVal iIndex As Long, ByVal lpOutput As String, _
                            lpDevMode As DEVMODE) As Long
Declare PtrSafe Function timeGetTime Lib "winmm" () As Long
Declare PtrSafe Function timeBeginPeriod Lib "winmm" (ByVal uPeriod As Integer) As Long
Declare PtrSafe Function timeEndPeriod Lib "winmm" (ByVal uPeriod As Integer) As Long

'End of file

