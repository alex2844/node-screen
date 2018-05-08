﻿// 2>nul||@goto :batch
/*
:batch
@echo off
setlocal

:: find csc.exe
set "csc="
for /r "%SystemRoot%\Microsoft.NET\Framework\" %%# in ("*csc.exe") do  set "csc=%%#"

if not exist "%csc%" (
   echo no .net framework installed
   exit /b 10
)

if not exist "%~n0.exe" (
   call %csc% /nologo /r:"Microsoft.VisualBasic.dll" /out:"%~n0.exe" "%~dpsfnx0" || (
      exit /b %errorlevel% 
   )
)
%~n0.exe %*
endlocal & exit /b %errorlevel%

*/

using System;
using System.Runtime.InteropServices;

namespace MouseMover {
    public class MouseSimulator {
        [DllImport("user32.dll", SetLastError = true)]
        static extern uint SendInput(uint nInputs, ref INPUT pInputs, int cbSize);
        [DllImport("user32.dll")]
        public static extern int SetCursorPos(int x, int y);
        [DllImport("user32.dll")]
        public static extern bool ClientToScreen(IntPtr hWnd, ref POINT lpPoint);
        [DllImport("user32.dll")]
        static extern void ClipCursor(ref Rect rect);
        [DllImport("user32.dll")]
        static extern void ClipCursor(IntPtr rect);
        [DllImport("user32.dll", SetLastError = true)]
        static extern IntPtr CopyImage(IntPtr hImage, uint uType, int cxDesired, int cyDesired, uint fuFlags);
        [DllImport("user32.dll")]
        static extern bool CopyRect(out Rect lprcDst, [In] ref Rect lprcSrc);
		[DllImport("user32.dll")]
		static extern int GetSystemMetrics(SystemMetric smIndex);
		[DllImport("user32.dll",CharSet=CharSet.Auto, CallingConvention=CallingConvention.StdCall)]
		static extern void mouse_event(long dwFlags, long dx, long dy, long cButtons, long dwExtraInfo);

        [StructLayout(LayoutKind.Sequential)]
        struct INPUT {
            public SendInputEventType type;
            public MouseKeybdhardwareInputUnion mkhi;
        }
        [StructLayout(LayoutKind.Explicit)]
        struct MouseKeybdhardwareInputUnion {
            [FieldOffset(0)]
            public MouseInputData mi;

            [FieldOffset(0)]
            public KEYBDINPUT ki;

            [FieldOffset(0)]
            public HARDWAREINPUT hi;
        }
        [StructLayout(LayoutKind.Sequential)]
        struct KEYBDINPUT {
            public ushort wVk;
            public ushort wScan;
            public uint dwFlags;
            public uint time;
            public IntPtr dwExtraInfo;
        }
        [StructLayout(LayoutKind.Sequential)]
        struct HARDWAREINPUT {
            public int uMsg;
            public short wParamL;
            public short wParamH;
        }
        [StructLayout(LayoutKind.Sequential)]
        public struct POINT {
            public int X;
            public int Y;
            public POINT(int x, int y) {
                this.X = x;
                this.Y = y;
            }
        }
        struct MouseInputData {
            public int dx;
            public int dy;
            public uint mouseData;
            public MouseEventFlags dwFlags;
            public uint time;
            public IntPtr dwExtraInfo;
        }
        struct Rect {
            public long left;
            public long top;
            public long right;
            public long bottom;
            public Rect(long left,long top,long right , long bottom) {
                this.left = left;
                this.top = top;
                this.right = right;
                this.bottom = bottom;
            }
        }
        [Flags]
        enum MouseEventFlags : uint {
            MOUSEEVENTF_MOVE = 0x0001,
            MOUSEEVENTF_XDOWN = 0x0080,
            MOUSEEVENTF_XUP = 0x0100,
            MOUSEEVENTF_WHEEL = 0x0800,
            MOUSEEVENTF_VIRTUALDESK = 0x4000,
            MOUSEEVENTF_ABSOLUTE = 0x8000
        }
        enum SendInputEventType : int {
            InputMouse,
            InputKeyboard,
            InputHardware
        }
		enum SystemMetric {
		  SM_CXSCREEN = 0,
		  SM_CYSCREEN = 1,
		}
		static int CalculateAbsoluteCoordinateX(int x) {
		  return (x * 65536) / GetSystemMetrics(SystemMetric.SM_CXSCREEN);
		}
		static int CalculateAbsoluteCoordinateY(int y) {
		  return (y * 65536) / GetSystemMetrics(SystemMetric.SM_CYSCREEN);
		}
        static void mouseMove(int x, int y) {
            INPUT mouseInput = new INPUT();
            mouseInput.type = SendInputEventType.InputMouse;
            mouseInput.mkhi.mi.dwFlags = MouseEventFlags.MOUSEEVENTF_MOVE|MouseEventFlags.MOUSEEVENTF_ABSOLUTE;
            mouseInput.mkhi.mi.dx = CalculateAbsoluteCoordinateX(x);
            mouseInput.mkhi.mi.dy = CalculateAbsoluteCoordinateY(y);
            SendInput(1, ref mouseInput, Marshal.SizeOf(mouseInput));
        }
        static void mouseClick(int code) {
			if (code == 1)
				mouse_event(0x02 | 0x04, 0, 0, 0, 0);
			else if (code == 2)
				mouse_event(0x20 | 0x40, 0, 0, 0, 0);
			else if (code == 3)
				mouse_event(0x08 | 0x10, 0, 0, 0, 0);
		}
       static void PrintHelp() {
            String filename = Environment.GetCommandLineArgs()[0];
            filename = filename.Substring(0, filename.Length);
            Console.WriteLine(filename+" controls the mouse cursor through command line ");
            Console.WriteLine("Usage:");
            Console.WriteLine("");
            Console.WriteLine(filename+" action [arguments]");
            Console.WriteLine("Actions:");
            Console.WriteLine("mouseclick 1 - clicks with the left mouse button at the current position");
            Console.WriteLine("mouseclick 2 - clicks with the middle mouse button at the current position");
            Console.WriteLine("mouseclick 3 - clicks with the right mouse button at the current position");
            Console.WriteLine("mousemove X Y - moves the mouse curosor to absolute coordinates.Requires two numbers separated by low case 'x' .");
            Console.WriteLine("");
            Console.WriteLine("Consider using only " +filename+" (without extensions) to prevent print of the errormessages after the first start");
            Console.WriteLine("  in case you are using batch-wrapped script.");
        }
        public static void Main(String[] args) {
            if (args.Length == 0 || args[0].ToLower() == "-help" || args[0].ToLower() == "-h") {
                PrintHelp();
                System.Environment.Exit(0);
            }else if (args[0].ToLower() == "mouseclick")
				mouseClick(int.Parse(args[1]));
			else if (args[0].ToLower() == "mousemove")
                mouseMove(int.Parse(args[1]), int.Parse(args[2]));
            else{
                Console.WriteLine("Invalid action : " + args[0]);
                System.Environment.Exit(10);
            }
        }
    }
}
