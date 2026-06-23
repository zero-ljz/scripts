Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Mag {
    [DllImport("Magnification.dll")]
    public static extern bool MagInitialize();

    [DllImport("Magnification.dll")]
    public static extern bool MagUninitialize();

    [DllImport("Magnification.dll")]
    public static extern bool MagSetFullscreenTransform(float magLevel, int xOffset, int yOffset);

    [DllImport("Magnification.dll")]
    public static extern bool MagSetFullscreenColorEffect(ref MAGCOLOREFFECT effect);

    [StructLayout(LayoutKind.Sequential)]
    public struct MAGCOLOREFFECT {
        [MarshalAs(UnmanagedType.ByValArray, SizeConst = 25)]
        public float[] transform;
    }
}
"@

# 0.55 = 55%亮度，越小越暗
$brightness = 0.55

[Mag]::MagInitialize() | Out-Null
[Mag]::MagSetFullscreenTransform(1.0, 0, 0) | Out-Null

$effect = New-Object Mag+MAGCOLOREFFECT
$effect.transform = @(
    $brightness, 0, 0, 0, 0,
    0, $brightness, 0, 0, 0,
    0, 0, $brightness, 0, 0,
    0, 0, 0, 1, 0,
    0, 0, 0, 0, 1
)

[Mag]::MagSetFullscreenColorEffect([ref]$effect) | Out-Null

Write-Host "已启用全局调暗。按 Ctrl+C 退出并恢复。"

try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
}
finally {
    $reset = New-Object Mag+MAGCOLOREFFECT
    $reset.transform = @(
        1,0,0,0,0,
        0,1,0,0,0,
        0,0,1,0,0,
        0,0,0,1,0,
        0,0,0,0,1
    )
    [Mag]::MagSetFullscreenColorEffect([ref]$reset) | Out-Null
    [Mag]::MagUninitialize() | Out-Null
}