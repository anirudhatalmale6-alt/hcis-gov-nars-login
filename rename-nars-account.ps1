<#
  Rename the NARS account on screen so it cannot be mistaken for the real one.

  "Evans Nars" -> "Evans (NARS assessor)".

  Displayed name only. Username, password, role, group and status are all left
  exactly as they are, so nothing about signing in changes.

  No password is asked for, because none is needed.
#>

param(
    [string]$Username   = 'evans.nars',
    [string]$First      = 'Evans',
    [string]$Last       = '(NARS assessor)',
    [string]$Db         = 'hcis_db',
    [string]$DbUser     = 'postgres',
    [string]$DbPassword = '',
    [string]$PgBin      = ''
)

$ErrorActionPreference = 'Stop'
function Say($m, $c = 'Gray') { Write-Host "  $m" -ForegroundColor $c }

$sql = Join-Path $PSScriptRoot 'sql\rename_nars_account.sql'
if (-not (Test-Path $sql)) {
    Say 'This is not unpacked - sql\rename_nars_account.sql is not next to this script.' 'Red'
    Say 'Right-click the zip, Extract All, then run it from that folder.' 'Red'
    exit 1
}

if (-not $PgBin) {
    $PgBin = @('C:\PostgreSQL\16\bin', 'C:\PostgreSQL\17\bin',
               'C:\Program Files\PostgreSQL\16\bin', 'C:\Program Files\PostgreSQL\17\bin') |
             Where-Object { Test-Path (Join-Path $_ 'psql.exe') } | Select-Object -First 1
}
if (-not $PgBin) { Say 'psql.exe was not found on this machine.' 'Red'; exit 1 }
$psql = Join-Path $PgBin 'psql.exe'

# Without this psql stops and asks for the database password, and the window
# just sits there looking frozen. That happened to the client on 30 September.
# The database password is no longer written into this file - it used to be,
# and these scripts are published publicly. db-access.ps1 finds it: already in
# the environment, or saved on this machine by SET-DB-PASSWORD.bat, or it asks
# once. Without it psql stops and waits for input and the window looks frozen.
if ($DbPassword) { $env:PGPASSWORD = $DbPassword }
. (Join-Path $PSScriptRoot 'db-access.ps1')
if (-not (Set-DbPassword)) { exit 1 }

Write-Host ''
Say '============================================================'
Say ' Rename the NARS account on screen'
Say '============================================================'
Write-Host ''
Say ("{0}  will show as  `"{1} {2}`"" -f $Username, $First, $Last)
Write-Host ''
Say 'Name only. The username, password, role and access all stay'
Say 'exactly as they are - signing in does not change.'
Write-Host ''

& $psql -q -U $DbUser -d $Db -v ON_ERROR_STOP=1 `
        -v ("usr=" + $Username) -v ("first=" + $First) -v ("last=" + $Last) -f $sql
$rc = $LASTEXITCODE

Write-Host ''
if ($rc -ne 0) {
    Say '------------------------------------------------------------' 'Red'
    Say 'IT DID NOT WORK. Nothing was changed.' 'Red'
    Say 'The message above says why. Send me a photo of this window.' 'Red'
    Say '------------------------------------------------------------' 'Red'
} else {
    Say '------------------------------------------------------------' 'Green'
    Say 'Done. The table above shows how both accounts now read.' 'Green'
    Write-Host ''
    Say 'Sign out and back in to see the new name in the corner.' 'Yellow'
    Say '------------------------------------------------------------' 'Green'
}
Write-Host ''
if ($Host.Name -eq 'ConsoleHost') { Read-Host 'Press Enter to close' | Out-Null }
exit $rc
