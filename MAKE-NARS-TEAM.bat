@echo off
REM ============================================================
REM  NARS - create the four Health Department assessors on
REM  THIS box:
REM
REM    marylene.lucas   Marylene Lucas
REM    vlmarie          Veriene Louis-Marie
REM    fiona.paulin     Fiona Paulin
REM    r.burka          Rhonda Burka
REM
REM  You type ONE temporary password. Each of them is then made
REM  to set their own the first time they sign in to NARS.
REM
REM  Double-click it.
REM ============================================================
setlocal
set HERE=%~dp0
if not exist "%HERE%nars-team.ps1" (
  echo ERROR: nars-team.ps1 is missing from this folder.
  echo Right-click the zip, choose Extract All, and run it from there.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%HERE%nars-team.ps1"
