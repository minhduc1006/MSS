$services = @(
    @{ Name = "auth-service";       Color = "Cyan" },
    @{ Name = "billing-service";    Color = "Green" },
    @{ Name = "facility-service";   Color = "Yellow" },
    @{ Name = "security-service";  Color = "Magenta" },
    @{ Name = "operations-service"; Color = "Red" }
)

$logDir = Join-Path $PSScriptRoot ".logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir | Out-Null }

$processes = @()

Write-Host "`n[! ] Robustly stopping any existing Java/Maven processes to release file locks..." -ForegroundColor Yellow
# Kill Java, Maven, and cmd processes that might be running mvn
taskkill /F /IM java.exe 2>$null | Out-Null
taskkill /F /IM mvn.cmd 2>$null | Out-Null
taskkill /F /IM cmd.exe /FI "WINDOWTITLE eq mvn*" 2>$null | Out-Null
Start-Sleep -Seconds 3

Write-Host "--- Initializing Microservices (File-Tailing Mode) ---" -ForegroundColor White

foreach ($service in $services) {
    $name = $service.Name
    $color = $service.Color
    $path = Join-Path $PSScriptRoot $name

    if (-not (Test-Path $path)) {
        Write-Host "Warning: Service directory not found: $path" -ForegroundColor Red
        continue
    }

    $logFile = Join-Path $logDir "$name.log"
    if (Test-Path $logFile) { Remove-Item $logFile -Force }
    # Create empty file
    New-Item -ItemType File -Path $logFile | Out-Null

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "cmd.exe"
    # Added 'clean' to ensure properties are re-copied to target/classes
    $psi.Arguments = "/c mvn clean spring-boot:run > `"$logFile`" 2>&1"
    $psi.WorkingDirectory = $path
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $psi

    try {
        if ($process.Start()) {
            $processes += $process
            # Store metadata for tailing
            $service.Add("Process", $process)
            $service.Add("LogFile", $logFile)
            $service.Add("Offset", 0)
            Write-Host "Started $name (PID: $($process.Id)) -> $name.log" -ForegroundColor Gray
            # Stagger startup slightly
            Start-Sleep -Seconds 1
        } else {
            Write-Host "Failed to start $name" -ForegroundColor Red
        }
    } catch {
        Write-Host "Exception starting ${name}: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nAll services starting. Monitoring logs... Press Ctrl+C to stop.`n" -ForegroundColor Cyan

# Main loop to tail logs and monitor processes
try {
    while ($true) {
        foreach ($s in $services) {
            if (-not $s.ContainsKey("LogFile")) { continue }
            
            try {
                if (Test-Path $s.LogFile) {
                    $file = [System.IO.File]::Open($s.LogFile, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
                    if ($file.Length -gt $s.Offset) {
                        $file.Seek($s.Offset, [System.IO.SeekOrigin]::Begin) | Out-Null
                        $reader = New-Object System.IO.StreamReader($file)
                        while (-not $reader.EndOfStream) {
                            $line = $reader.ReadLine()
                            if ($null -ne $line) {
                                Write-Host "[$($s.Name)] " -NoNewline -ForegroundColor $s.Color
                                Write-Host $line
                            }
                        }
                        $s.Offset = $file.Position
                    }
                    $file.Close()
                }
            } catch {
                # Silently ignore read errors during startup/rotation
            }

            # Check for exits
            $p = $s.Process
            if ($p.HasExited) {
                if ($null -ne $p.Tag -and $p.Tag -eq "Reported") { continue }
                Write-Host "[$($s.Name)] Process exited with code $($p.ExitCode)" -ForegroundColor Red
                $p | Add-Member -MemberType NoteProperty -Name "Tag" -Value "Reported" -Force
            }
        }
        
        Start-Sleep -Milliseconds 250
    }
} catch {
    Write-Host "CRITICAL ERROR in main loop: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Write-Host "`nShutting down all services..." -ForegroundColor White
    foreach ($p in $processes) {
        if (-not $p.HasExited) {
            Write-Host "Stopping $($p.Id)..." -ForegroundColor Gray
            taskkill /T /F /PID $p.Id 2>&1 | Out-Null
        }
    }
    # Optional: Clean up log directory
    # Remove-Item $logDir -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cleanup complete." -ForegroundColor White
}
