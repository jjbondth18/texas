$ErrorActionPreference = "Stop"
$adminDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFile = Join-Path $adminDir ".env.client"
$sshProcess = $null

function Import-AdminEnvironment([string]$Path) {
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Missing tools\admin\.env.client. Copy .env.client.example and configure SSH access."
  }
  Get-Content -LiteralPath $Path | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
      $parts = $line.Split("=", 2)
      if ($parts.Count -eq 2) {
        [Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim(), "Process")
      }
    }
  }
}

function Require-Value([string]$Name, [string]$Value) {
  if ([string]::IsNullOrWhiteSpace($Value)) { throw "$Name is required in .env.client." }
}

Import-AdminEnvironment $envFile
Require-Value "SSH_HOST" $env:SSH_HOST
Require-Value "SSH_USER" $env:SSH_USER
Require-Value "SSH_KEY_PATH" $env:SSH_KEY_PATH
if ($env:SSH_HOST -notmatch '^[A-Za-z0-9._:-]+$') { throw "SSH_HOST contains unsupported characters." }
if ($env:SSH_USER -notmatch '^[A-Za-z0-9._-]+$') { throw "SSH_USER contains unsupported characters." }
if (-not (Test-Path -LiteralPath $env:SSH_KEY_PATH -PathType Leaf)) { throw "SSH key not found: $($env:SSH_KEY_PATH)" }

$localPort = if ($env:ADMIN_LOCAL_PORT) { [int]$env:ADMIN_LOCAL_PORT } else { 8787 }
$remotePort = if ($env:ADMIN_REMOTE_PORT) { [int]$env:ADMIN_REMOTE_PORT } else { 8787 }
$sshPort = if ($env:SSH_PORT) { [int]$env:SSH_PORT } else { 22 }
foreach ($port in @($localPort, $remotePort, $sshPort)) {
  if ($port -lt 1 -or $port -gt 65535) { throw "Ports must be between 1 and 65535." }
}

$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $localPort)
try { $listener.Start() } catch { throw "Local port $localPort is already in use." } finally { $listener.Stop() }
if (-not (Get-Command ssh.exe -ErrorAction SilentlyContinue)) { throw "OpenSSH ssh.exe was not found." }

$sshArgs = @(
  "-N",
  "-T",
  "-p", "$sshPort",
  "-i", ('"' + $env:SSH_KEY_PATH + '"'),
  "-o", "ExitOnForwardFailure=yes",
  "-o", "ServerAliveInterval=30",
  "-o", "ServerAliveCountMax=3",
  "-L", "${localPort}:127.0.0.1:${remotePort}",
  "$($env:SSH_USER)@$($env:SSH_HOST)"
)

try {
  Write-Host "Opening SSH tunnel: 127.0.0.1:$localPort -> VM 127.0.0.1:$remotePort"
  $sshProcess = Start-Process -FilePath "ssh.exe" -ArgumentList $sshArgs -PassThru -WindowStyle Hidden
  $healthUrl = "http://127.0.0.1:$localPort/health"
  $ready = $false
  for ($attempt = 0; $attempt -lt 20; $attempt++) {
    Start-Sleep -Milliseconds 500
    if ($sshProcess.HasExited) { throw "SSH exited with code $($sshProcess.ExitCode). Check host, user, key, and VM Admin status." }
    try {
      $health = Invoke-RestMethod -Uri $healthUrl -Method Get -TimeoutSec 2
      if ($health.ok -and $health.service -eq "texas-admin") { $ready = $true; break }
    } catch {}
  }
  if (-not $ready) { throw "Tunnel opened but Admin health check failed at $healthUrl. Verify texas-admin is running on the VM." }
  Write-Host "Tunnel ready. Closing this window or pressing Ctrl+C will close it."
  Start-Process "http://127.0.0.1:$localPort"
  $sshProcess.WaitForExit()
  if ($sshProcess.ExitCode -ne 0) { throw "SSH tunnel closed with exit code $($sshProcess.ExitCode)." }
}
finally {
  if ($sshProcess -and -not $sshProcess.HasExited) {
    Stop-Process -Id $sshProcess.Id -Force -ErrorAction SilentlyContinue
    $sshProcess.WaitForExit()
  }
}
