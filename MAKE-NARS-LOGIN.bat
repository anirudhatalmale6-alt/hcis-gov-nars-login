@echo off
REM ============================================================
REM  NARS - create a Health Department account on THIS box.
REM
REM  Run this if NARS says:
REM    "This account is not in the Health Department group..."
REM
REM  Double-click it. It calls nars-account.ps1 for you, so there
REM  is no right-clicking and no execution-policy message.
REM ============================================================
setlocal
set HERE=%~dp0
if not exist "%HERE%nars-account.ps1" (
  echo ERROR: nars-account.ps1 is missing from this folder.
  echo Right-click the zip, choose Extract All, and run it from there.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%HERE%nars-account.ps1"
