// 2>nul||@goto :batch
/*
:batch
@echo off
setlocal

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
using System.Drawing;
using System.Drawing.Imaging;

namespace NodeScreen {
	public class screen {
		public static Image CaptureScreen(){
			return CaptureWindow(User32.GetDesktopWindow());
		}
		public static Image CaptureWindow(IntPtr handle) {
			IntPtr hdcSrc = User32.GetWindowDC(handle);
			User32.RECT windowRect = new User32.RECT();
			User32.GetWindowRect(handle, ref windowRect);
			int width = windowRect.right - windowRect.left;
			int height = windowRect.bottom - windowRect.top;
			IntPtr hdcDest = GDI32.CreateCompatibleDC(hdcSrc);
			IntPtr hBitmap = GDI32.CreateCompatibleBitmap(hdcSrc, width, height);
			IntPtr hOld = GDI32.SelectObject(hdcDest, hBitmap);
			GDI32.BitBlt(hdcDest, 0, 0, width, height, hdcSrc, 0, 0, GDI32.SRCCOPY);
			GDI32.SelectObject(hdcDest, hOld);
			GDI32.DeleteDC(hdcDest);
			User32.ReleaseDC(handle, hdcSrc);
			Image img = Image.FromHbitmap(hBitmap);
			GDI32.DeleteObject(hBitmap);
			return img;
		}
		private static ImageCodecInfo GetEncoderInfo(String mimeType) {
			int j;
			ImageCodecInfo[] encoders;
			encoders = ImageCodecInfo.GetImageEncoders();
			for (j = 0; j < encoders.Length; ++j) {
				if (encoders[j].MimeType == mimeType)
					return encoders[j];
			}
			return null;
		}
		public static void CaptureScreenToFile(string filename, int resize) {
			Image img = CaptureScreen();
			if (resize == 0)
				img.Save(filename, System.Drawing.Imaging.ImageFormat.Jpeg);
			else{
				img = img.GetThumbnailImage(resize, (resize * img.Height) / img.Width, null, IntPtr.Zero);
				ImageCodecInfo myImageCodecInfo;
				myImageCodecInfo = GetEncoderInfo("image/jpeg");
				var eps = new EncoderParameters(1);
				eps.Param[0] = new EncoderParameter(Encoder.Quality, (long) (resize / 20));
				img.Save(filename, myImageCodecInfo, eps);
			}
		}
		private class GDI32 {
			public const int SRCCOPY = 0x00CC0020;
			[DllImport("gdi32.dll")]
			public static extern bool BitBlt(IntPtr hObject, int nXDest, int nYDest, int nWidth, int nHeight, IntPtr hObjectSource, int nXSrc, int nYSrc, int dwRop);
			[DllImport("gdi32.dll")]
			public static extern IntPtr CreateCompatibleBitmap(IntPtr hDC, int nWidth, int nHeight);
			[DllImport("gdi32.dll")]
			public static extern IntPtr CreateCompatibleDC(IntPtr hDC);
			[DllImport("gdi32.dll")]
			public static extern bool DeleteDC(IntPtr hDC);
			[DllImport("gdi32.dll")]
			public static extern bool DeleteObject(IntPtr hObject);
			[DllImport("gdi32.dll")]
			public static extern IntPtr SelectObject(IntPtr hDC, IntPtr hObject);
		}
		private class User32 {
			[StructLayout(LayoutKind.Sequential)]
			public struct RECT {
				public int left;
				public int top;
				public int right;
				public int bottom;
			}
			[DllImport("user32.dll")]
			public static extern IntPtr GetDesktopWindow();
			[DllImport("user32.dll")]
			public static extern IntPtr GetWindowDC(IntPtr hWnd);
			[DllImport("user32.dll")]
			public static extern IntPtr ReleaseDC(IntPtr hWnd, IntPtr hDC);
			[DllImport("user32.dll")]
			public static extern IntPtr GetWindowRect(IntPtr hWnd, ref RECT rect);
		}
		static void PrintHelp() {
			String filename = Environment.GetCommandLineArgs()[0];
			filename = filename.Substring(0, filename.Length);
			Console.WriteLine(filename+" captures the screen and saves it to a file.");
			Console.WriteLine("Usage:");
			Console.WriteLine("");
			Console.WriteLine(filename+" filename [width]");
		}
		public static void Main(String[] args) {
			if (args.Length == 0 || args[0].ToLower() == "-help" || args[0].ToLower() == "-h") {
				PrintHelp();
				System.Environment.Exit(0);
			}else
				CaptureScreenToFile(args[0], ((args.Length > 1) ? int.Parse(args[1]) : 0));
		}
	}
}
