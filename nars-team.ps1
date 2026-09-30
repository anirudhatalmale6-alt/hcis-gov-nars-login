<#
  NARS - create the Health Department assessors on THIS box.

  The four people who carry out needs assessments. Their names and email
  addresses are here; their PASSWORDS ARE NOT, deliberately.

  Each account is created with a temporary password that you choose, and is
  flagged so that the person must set their own the first time they sign in.
  NARS implements that screen (app.js checks it and calls hcis_change_password),
  so it works - they will not be stuck.

  Why not just set their real passwords here:

    * this file goes in a public repository, and four live government
      credentials are not something to publish;
    * a password one other person has typed in is a password two people know,
      and that stops being true the moment they set their own.

  The temporary password is shared between the four until each one changes it.
  That is normal for handing out new accounts, and is why the forced change is
  not optional.

  -Password exists so a test can drive this. Use the prompt in real life.
#>

param(
    [string]$Password   = '',
    [string]$Db         = 'hcis_db',
    [string]$DbUser     = 'postgres',
    [string]$DbPassword = 'HcisStaging@2026',
    [string]$PgBin      = ''
)

$ErrorActionPreference = 'Stop'
function Say($m, $c = 'Gray') { Write-Host "  $m" -ForegroundColor $c }

# Name, username and email exactly as the Health Department gave them.
$TEAM = @(
    @{ User = 'marylene.lucas'; First = 'Marylene'; Last = 'Lucas';        Email = 'Marylene.Lucas@health.gov.sc' },
    @{ User = 'vlmarie';        First = 'Veriene';  Last = 'Louis-Marie';  Email = 'vlmarie@health.gov.sc' },
    @{ User = 'fiona.paulin';   First = 'Fiona';    Last = 'Paulin';       Email = 'fiona.paulin@health.gov.sc' },
    @{ User = 'r.burka';        First = 'Rhonda';   Last = 'Burka';        Email = 'r.burka@health.gov.sc' }
)

$sql = Join-Path $PSScriptRoot 'sql\health_account.sql'
if (-not (Test-Path $sql)) {
    Say 'This is not unpacked - sql\health_account.sql is not next to this script.' 'Red'
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

Write-Host ''
Say '============================================================'
Say ' NARS - the Health Department assessors'
Say '============================================================'
Write-Host ''
Say 'This creates these four accounts on THIS box:'
Write-Host ''
foreach ($p in $TEAM) {
    Say ("  {0,-16} {1} {2}" -f $p.User, $p.First, $p.Last)
}
Write-Host ''
Say 'They all get the SAME temporary password, and each of them must'
Say 'set their own the first time they sign in. So the one you type'
Say 'here only has to survive until they each log in once.'
Write-Host ''

if (-not $Password) {
    $a = Read-Host '  Temporary password (at least 10 characters)' -AsSecureString
    $b = Read-Host '  Type it again' -AsSecureString
    $pa = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($a)
    $pb = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($b)
    try {
        $s1 = [Runtime.InteropServices.Marshal]::PtrToStringAuto($pa)
        $s2 = [Runtime.InteropServices.Marshal]::PtrToStringAuto($pb)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pa)
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pb)
    }
    if ($s1 -cne $s2) { Say 'Those two do not match. Nothing was changed.' 'Red'; exit 1 }
    $Password = $s1
}
if (-not $Password) { Say 'Nothing typed. Stopping without changing anything.' 'Yellow'; exit 1 }

if ($DbPassword -and -not $env:PGPASSWORD) { $env:PGPASSWORD = $DbPassword }

$failed = @()
foreach ($p in $TEAM) {
    Write-Host ''
    Say ("---- {0} ({1} {2})" -f $p.User, $p.First, $p.Last) 'Cyan'
    & $psql -q -U $DbUser -d $Db -v ON_ERROR_STOP=1 `
            -v ("usr=" + $p.User) -v ("pwd=" + $Password) `
            -v ("email=" + $p.Email) -v ("firstname=" + $p.First) `
            -v ("lastname=" + $p.Last) -v "mustchange=yes" -f $sql
    if ($LASTEXITCODE -ne 0) { $failed += $p.User }
}

Write-Host ''
Say '============================================================'
if ($failed.Count -gt 0) {
    # Say which ones, by name. "Some failed" is not something anyone can act on.
    Say ('THESE DID NOT WORK: ' + ($failed -join ', ')) 'Red'
    Say 'The others above were created. Send me a photo of this window.' 'Red'
    Say '============================================================'
    Write-Host ''
    if ($Host.Name -eq 'ConsoleHost') { Read-Host 'Press Enter to close' | Out-Null }
    exit 1
}

Say 'All four created.' 'Green'
Write-Host ''
Say 'Each table above says in words whether the password works and'
Say 'whether NARS will accept the account. All four should say yes.'
Write-Host ''
Say 'Give each person the temporary password. NARS will ask them to' 'Yellow'
Say 'set their own the first time they sign in.' 'Yellow'
Say '============================================================'
Write-Host ''
if ($Host.Name -eq 'ConsoleHost') { Read-Host 'Press Enter to close' | Out-Null }
exit 0
