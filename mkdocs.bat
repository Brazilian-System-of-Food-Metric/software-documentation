@echo off
setlocal

REM Executa no diretorio do projeto
cd /d "%~dp0"

REM Tenta py launcher primeiro (Windows padrao)
where py >nul 2>&1
if %errorlevel%==0 (
    py -m mkdocs %*
    exit /b %errorlevel%
)

REM Fallback para python no PATH
where python >nul 2>&1
if %errorlevel%==0 (
    python -m mkdocs %*
    exit /b %errorlevel%
)

REM Fallback para instalacao local comum
if exist "C:\Python314\python.exe" (
    "C:\Python314\python.exe" -m mkdocs %*
    exit /b %errorlevel%
)

echo [ERRO] Python nao encontrado. Instale Python e MkDocs:
echo        pip install mkdocs mkdocs-material
exit /b 1
