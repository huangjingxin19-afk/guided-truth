[CmdletBinding()]
param(
    [string]$Godot = 'godot'
)

$ErrorActionPreference = 'Stop'
$engine = Get-Command -Name $Godot -CommandType Application -ErrorAction SilentlyContinue
if (-not $engine) {
    throw 'Godot was not found. Add it to PATH or supply -Godot with the full executable path.'
}

$repo = Split-Path -Parent $PSScriptRoot
$project = Join-Path $repo 'gotdot'
$runtime = Join-Path $repo ".test-runtime/check-game-$([guid]::NewGuid())"
$checks = @(
    @{ Name = 'room-102-inspection'; Script = 'room_102_inspection.gd' }
    @{ Name = 'room-102-reenactment'; Script = 'room_102_reenactment.gd' }
    @{ Name = 'chapter-route'; Script = 'chapter_one_route.gd' }
    @{ Name = 'chapter-route-watch-pickup'; Script = 'chapter_one_route.gd'; Phases = @('--watch-pickup') }
    @{ Name = 'autosave'; Script = 'autosave.gd'; Phases = @('first', 'second', 'third', 'resume', 'backup', 'reset', 'damaged') }
    @{
        Name = 'autosave-appointment'
        Script = 'autosave.gd'
        Phases = @(
            'first', 'second', 'third', 'appointment-plan', 'appointment-start',
            'appointment-return', 'appointment-finish', 'appointment-complete',
            'final-review-start', 'final-review-resume'
        )
    }
)

$originalAppData = $env:APPDATA
$results = [ordered]@{}
try {
    foreach ($check in $checks) {
        $name = $check.Name
        $env:APPDATA = (New-Item -ItemType Directory -Force -Path (Join-Path $runtime $name)).FullName
        $results[$name] = 'PASS'
        $phases = @('')
        if ($check.Phases) {
            $phases = $check.Phases
        }

        foreach ($phase in $phases) {
            $logPath = Join-Path $env:APPDATA "godot$phase.log"
            $godotArgs = @('--headless', '--path', $project, '--log-file', $logPath, '--script', "../tests/$($check.Script)")
            if ($phase) {
                $godotArgs += @('--', $phase)
            }

            Write-Host "Running $name $phase"
            & $engine.Source @godotArgs | Out-Host
            $completed = (Test-Path -LiteralPath $logPath -PathType Leaf) -and
                (Select-String -LiteralPath $logPath -Pattern 'failures: 0\s*$' -Quiet)
            if ($LASTEXITCODE -ne 0 -or -not $completed) {
                $results[$name] = "FAIL (exit $LASTEXITCODE, log $logPath)"
                break
            }
        }
    }
} finally {
    $env:APPDATA = $originalAppData
}

Write-Host "`nRegression results (logs: $runtime)"
foreach ($name in $results.Keys) {
    Write-Host "$name`: $($results[$name])"
}
if ($results.Values -like 'FAIL*') {
    exit 1
}
exit 0
