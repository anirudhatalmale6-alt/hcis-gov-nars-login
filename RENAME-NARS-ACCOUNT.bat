@echo off
REM ============================================================
REM  Rename the NARS account on screen so it cannot be mistaken
REM  for your real one:
REM
REM    "Evans Nars"  ->  "Evans (NARS assessor)"
REM
REM  Name only. Username, password, role and access are all left
REM  exactly as they are - signing in does not change.
REM
REM  Double-click it.
REM ============================================================
setlocal
set HERE=%~dp0
if not exist "%HERE%rename-nars-account.ps1" (
  echo ERROR: rename-nars-account.ps1 is missing from this folder.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%HERE%rename-nars-account.ps1"
