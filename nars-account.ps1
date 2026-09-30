<#
  NARS - give this box an account the Needs Assessment module will accept.

  The symptom this fixes:

    "This account is not in the Health Department group, so it has no access
     to the Needs Assessment module. Please use HCIS instead."

  That message means the password was RIGHT. Sign-in succeeded and NARS then
  turned the account away, because it checks the GROUP, not the role - a
  super_admin is refused just the same. The Needs Assessment module belongs to
  the Health Department.

  This box has no Health Department accounts at all: its accounts pre-date the
  NARS work. So one has to be created. That is all this does - one account, by
  name. Nothing else is touched.

  The password is typed masked and never leaves this script. An earlier tool
  here asked for it in the .bat with "set /p", which echoes every character to
  the screen, and the client sent a screenshot with his new password in it.

  -Username and -Password exist so a test can drive this. Use the prompts in
  real life.
#>

param(
    [string]$Username = '',
    [string]$Password = '',
    [string]$Db       = 'hcis_db',
    [string]$DbUser   = 'postgres',
    # The same default the catch-up package uses, so this just runs. Without it
    # psql prompts for the database password on its own and the window sits
    # there looking frozen, which is what happened the first time.
    [string]$DbPassword = 'HcisStaging@2026',
    [string]$PgBin    = ''
)

$ErrorActionPreference = 'Stop'
function Say($m, $c = 'Gray') { Write-Host "  $m" -ForegroundColor $c }

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
Say ' NARS - create a Health Department account on THIS box'
Say '============================================================'
Write-Host ''
Say 'NARS refuses any account that is not in the Health Department'
Say 'group. Your Evans account is a super_admin in Super Admin, so'
Say 'it signs in and is then turned away. That is correct - it just'
Say 'means this box needs a Health account, and it has none.'
Write-Host ''
Say 'Suggested username: evans.nars   (the same name as on the'
Say 'office server, but this is a SEPARATE account on this box,'
Say 'with its own password. The two machines share nothing.)'
Write-Host ''

if (-not $Username) { $Username = Read-Host '  Username to create [evans.nars]' }
if (-not $Username) { $Username = 'evans.nars' }

if (-not $Password) {
    # Masked, and asked twice - a typo here means an account nobody can reach.
    $a = Read-Host '  Password (at least 10 characters)' -AsSecureString
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

# psql reads the database password from this. Without it, it prompts once per
# call and the window just sits there looking frozen - which is exactly what
# happened when this was first moved out of the .bat.
if ($DbPassword -and -not $env:PGPASSWORD) { $env:PGPASSWORD = $DbPassword }

Write-Host ''
Say ("Creating `"{0}`" as a Health Department assessor..." -f $Username)
Write-Host ''

& $psql -q -U $DbUser -d $Db -v ON_ERROR_STOP=1 `
        -v ("usr=" + $Username) -v ("pwd=" + $Password) -f $sql
$rc = $LASTEXITCODE

Write-Host ''
if ($rc -ne 0) {
    Say '------------------------------------------------------------' 'Red'
    Say 'IT DID NOT WORK. Nothing was changed.' 'Red'
    Say 'The message above says why - usually the password was under' 'Red'
    Say '10 characters. Send me a photo of this window.' 'Red'
    Say '------------------------------------------------------------' 'Red'
} else {
    Say '------------------------------------------------------------' 'Green'
    Say 'DONE. The table above is the proof - it says in words whether' 'Green'
    Say 'the password works and whether NARS will accept the account.' 'Green'
    Write-Host ''
    Say ('Now open  http://localhost/nars/  and sign in as ' + $Username) 'Yellow'
    Say 'with the password you just typed.' 'Yellow'
    Write-Host ''
    Say 'This account is for NARS. Keep using Evans for HCIS itself.'
    Say '------------------------------------------------------------' 'Green'
}
Write-Host ''
if ($Host.Name -eq 'ConsoleHost') { Read-Host 'Press Enter to close' | Out-Null }
exit $rc
