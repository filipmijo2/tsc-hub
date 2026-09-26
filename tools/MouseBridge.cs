// TSC MouseBridge: Roblox sieht Maus 4/5 nicht. Solange Roblox im Vordergrund ist, werden
// XButton1 -> F13 und XButton2 -> F14 (gedrückt halten bleibt gedrückt halten). Sonst normale Seitentasten.
// Tray-Icon mit "Beenden". Build: csc /target:winexe /r:System.Windows.Forms.dll /r:System.Drawing.dll MouseBridge.cs
using System;
using System.Diagnostics;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;

static class MouseBridge
{
    const int WH_MOUSE_LL = 14;
    const int WM_XBUTTONDOWN = 0x020B, WM_XBUTTONUP = 0x020C;
    const uint LLMHF_INJECTED = 0x1;
    const ushort VK_F13 = 0x7C, VK_F14 = 0x7D;
    const uint KEYEVENTF_KEYUP = 0x2;

    [StructLayout(LayoutKind.Sequential)] struct POINT { public int x, y; }
    [StructLayout(LayoutKind.Sequential)] struct MSLLHOOKSTRUCT { public POINT pt; public uint mouseData, flags, time; public IntPtr extra; }
    [StructLayout(LayoutKind.Sequential)] struct KEYBDINPUT { public ushort wVk, wScan; public uint dwFlags, time; public IntPtr extra; }
    [StructLayout(LayoutKind.Sequential)] struct MOUSEINPUT { public int dx, dy; public uint mouseData, dwFlags, time; public IntPtr extra; }
    [StructLayout(LayoutKind.Explicit)] struct INPUTUNION { [FieldOffset(0)] public MOUSEINPUT mi; [FieldOffset(0)] public KEYBDINPUT ki; }
    [StructLayout(LayoutKind.Sequential)] struct INPUT { public uint type; public INPUTUNION u; }

    delegate IntPtr HookProc(int nCode, IntPtr wParam, IntPtr lParam);
    [DllImport("user32.dll")] static extern IntPtr SetWindowsHookEx(int id, HookProc fn, IntPtr mod, uint thread);
    [DllImport("user32.dll")] static extern IntPtr CallNextHookEx(IntPtr h, int n, IntPtr w, IntPtr l);
    [DllImport("user32.dll")] static extern bool UnhookWindowsHookEx(IntPtr h);
    [DllImport("kernel32.dll")] static extern IntPtr GetModuleHandle(string name);
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
    [DllImport("user32.dll")] static extern uint SendInput(uint n, INPUT[] inputs, int size);
    [DllImport("user32.dll")] static extern uint MapVirtualKey(uint code, uint type);

    static HookProc proc = Hook;
    static IntPtr hook;
    static IntPtr lastFg = IntPtr.Zero;
    static bool lastWasRoblox;
    static readonly bool[] down = new bool[3];

    static bool RobloxForeground()
    {
        IntPtr fg = GetForegroundWindow();
        if (fg == lastFg) return lastWasRoblox;
        lastFg = fg;
        uint pid; GetWindowThreadProcessId(fg, out pid);
        try { lastWasRoblox = Process.GetProcessById((int)pid).ProcessName.StartsWith("RobloxPlayer", StringComparison.OrdinalIgnoreCase); }
        catch { lastWasRoblox = false; }
        return lastWasRoblox;
    }

    static void Key(ushort vk, bool up)
    {
        var inp = new INPUT[1];
        inp[0].type = 1;
        inp[0].u.ki.wVk = vk;
        inp[0].u.ki.wScan = (ushort)MapVirtualKey(vk, 0);
        inp[0].u.ki.dwFlags = up ? KEYEVENTF_KEYUP : 0;
        SendInput(1, inp, Marshal.SizeOf(typeof(INPUT)));
    }

    static IntPtr Hook(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0)
        {
            int msg = wParam.ToInt32();
            if (msg == WM_XBUTTONDOWN || msg == WM_XBUTTONUP)
            {
                var info = (MSLLHOOKSTRUCT)Marshal.PtrToStructure(lParam, typeof(MSLLHOOKSTRUCT));
                int btn = (int)(info.mouseData >> 16); // 1 = XButton1 (Maus 4), 2 = XButton2 (Maus 5)
                if ((info.flags & LLMHF_INJECTED) == 0 && (btn == 1 || btn == 2))
                {
                    ushort vk = btn == 1 ? VK_F13 : VK_F14;
                    bool isDown = msg == WM_XBUTTONDOWN;
                    // Loslassen immer weitergeben, wenn wir das Drücken umgemappt haben (auch wenn Fokus gewechselt hat)
                    if (isDown ? RobloxForeground() : down[btn])
                    {
                        down[btn] = isDown;
                        Key(vk, !isDown);
                        return (IntPtr)1; // Original-Klick schlucken
                    }
                }
            }
        }
        return CallNextHookEx(hook, nCode, wParam, lParam);
    }

    [STAThread]
    static void Main()
    {
        bool fresh;
        using (var mtx = new Mutex(true, "TSC_MouseBridge_Single", out fresh))
        {
            if (!fresh) return;
            hook = SetWindowsHookEx(WH_MOUSE_LL, proc, GetModuleHandle(null), 0);
            var tray = new NotifyIcon { Icon = SystemIcons.Application, Visible = true, Text = "TSC MouseBridge (Maus4=F13, Maus5=F14 in Roblox)" };
            var menu = new ContextMenuStrip();
            menu.Items.Add("Beenden", null, (s, e) => Application.Exit());
            tray.ContextMenuStrip = menu;
            Application.Run();
            tray.Visible = false;
            UnhookWindowsHookEx(hook);
        }
    }
}
