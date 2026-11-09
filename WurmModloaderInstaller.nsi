;-------------------------------------------------------------------------------
; Wurm Unlimited Client Modloader Installer
;
; Installs Ago's WurmClientModLauncher v0.15 for Wurm Unlimited.
; Detects Steam libraries, validates the game folder and Java,
; patches client.jar while keeping a backup, manages existing mods, registers
; itself in Programs and Features and can fully restore the original client.
;
; Build: build.bat          (release, per-machine, requires admin)
;        build.bat test     (test build, per-user, separate registry keys)
;
; Requires NSIS 3.x (developed against 3.13) with Modern UI 2.
;-------------------------------------------------------------------------------

Unicode true
!cd "${__FILEDIR__}"

!include "MUI2.nsh"
!include "LogicLib.nsh"
!include "FileFunc.nsh"
!include "StrFunc.nsh"
!include "nsDialogs.nsh"
!include "Sections.nsh"
!include "WinMessages.nsh"
!include "x64.nsh"

${Using:StrFunc} StrLoc
${Using:StrFunc} StrStr
${Using:StrFunc} StrRep
${Using:StrFunc} StrTrimNewLines

;-------------------------------------------------------------------------------
; Product information
;-------------------------------------------------------------------------------

!define APP_NAME "Wurm Unlimited Client Modloader"
!define APP_VERSION "1.0.0"
!define APP_VERSION4 "1.0.0.0"
!define LOADER_VERSION "0.15"
!define PUBLISHER "Jubaroo"
!define PROJECT_URL "https://forum.wurmonline.com/index.php?/topic/159953-installer-for-agos-client-mod-loader-w-mods/"
!define STEAM_APP_ID "366220"
!define DEFAULT_INSTDIR "$PROGRAMFILES\Steam\steamapps\common\Wurm Unlimited\WurmLauncher"

!ifdef TEST_BUILD
  !define APP_DISPLAY_NAME "${APP_NAME} (Test)"
  !define OUT_FILE "build\Wurm Client Modloader Setup ${APP_VERSION} TEST.exe"
  !define REG_BASE "Software\Wurm Client Modloader TEST"
  !define UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\WurmClientModloaderTEST"
  !define UNINST_EXE "Uninstall ${APP_DISPLAY_NAME}.exe"
!else
  !define APP_DISPLAY_NAME "${APP_NAME}"
  !define OUT_FILE "build\Wurm Client Modloader Setup ${APP_VERSION}.exe"
  !define REG_BASE "Software\Wurm Client Modloader"
  !define UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\WurmClientModloader"
  !define UNINST_EXE "Uninstall ${APP_DISPLAY_NAME}.exe"
!endif


Name "${APP_DISPLAY_NAME}"
Caption "${APP_DISPLAY_NAME} ${APP_VERSION} Setup"
OutFile "${OUT_FILE}"

!ifdef TEST_BUILD
  RequestExecutionLevel user
!else
  RequestExecutionLevel admin
!endif
ManifestDPIAware true
ManifestSupportedOS all

InstallDir "${DEFAULT_INSTDIR}"
AllowRootDirInstall false
BrandingText "Jubaroo - ${APP_NAME}"
ShowInstDetails show
ShowUninstDetails show
CRCCheck on
SetOverwrite on
XPStyle on
SetCompressor /SOLID lzma
SetCompressorDictSize 32

VIProductVersion "${APP_VERSION4}"
VIAddVersionKey /LANG=1033 "ProductName" "${APP_NAME}"
VIAddVersionKey /LANG=1033 "CompanyName" "${PUBLISHER}"
VIAddVersionKey /LANG=1033 "FileDescription" "${APP_NAME} Setup"
VIAddVersionKey /LANG=1033 "FileVersion" "${APP_VERSION}"
VIAddVersionKey /LANG=1033 "ProductVersion" "${APP_VERSION}"
VIAddVersionKey /LANG=1033 "LegalCopyright" "(C) ${PUBLISHER}"
VIAddVersionKey /LANG=1033 "Comments" "Installs Ago's WurmClientModLauncher ${LOADER_VERSION}"

;-------------------------------------------------------------------------------
; Global variables
;-------------------------------------------------------------------------------

Var DetectedPath
Var DetectedSource
Var DetectedSourceId
Var TryPath
Var TrySource
Var TryFound
Var JavaExe
Var JavaSource
Var JavaVersion
Var JavaDisplay
Var PatchState
Var PatchResult
Var ClientStatus
Var StatusNote
Var StatusSeen
Var RestoreClient
Var SkipPatch
Var WriteLog
Var LogPath
Var FinishDetails
Var ModsIni
Var ModCount
Var ModsOn
Var ModsOff
Var ModAction
Var ModBase
Var ModsAction
Var ApplyErrors
Var InstallSizeKb
Var DeleteMods
Var OptSkipPatch
Var OptNoRestore
Var hStatusDialog
Var hChkRestore
Var hChkSkip
Var hChkLog
Var hModsDialog
Var hModsList
Var hModsStatus
Var hBtnToggle
Var hBtnEnableAll
Var hBtnDisableAll
Var hBtnOpenMods
Var hUnDialog
Var hUnChkRestore
Var hUnChkDeleteMods

;-------------------------------------------------------------------------------
; Modern UI settings
;-------------------------------------------------------------------------------

!define MUI_ICON "assets\Wurm.ico"
!define MUI_UNICON "assets\Wurm.ico"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP "assets\WurmBanner.bmp"
!define MUI_WELCOMEFINISHPAGE_BITMAP "assets\welcome.bmp"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "assets\unwelcome.bmp"
!define MUI_ABORTWARNING
!define MUI_UNABORTWARNING

!define MUI_WELCOMEPAGE_TITLE "Wurm Unlimited Client Modloader ${APP_VERSION}"
!define MUI_WELCOMEPAGE_TEXT "$(WELCOME_TEXT)"

!define MUI_COMPONENTSPAGE_TEXT_TOP "$(COMPONENTS_TOP)"

!define MUI_DIRECTORYPAGE_TEXT_TOP "$(DIRECTORY_TOP)"

!define MUI_FINISHPAGE_TITLE "$(FINISH_TITLE)"
!define MUI_FINISHPAGE_TEXT_LARGE
!define MUI_FINISHPAGE_TEXT "$FinishDetails"
!define MUI_FINISHPAGE_RUN "$INSTDIR\WurmLauncher.exe"
!define MUI_FINISHPAGE_RUN_TEXT "$(FINISH_RUN)"
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\mods"
!define MUI_FINISHPAGE_SHOWREADME_TEXT "$(FINISH_README)"
!define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
!define MUI_FINISHPAGE_NOREBOOTSUPPORT
!define MUI_FINISHPAGE_LINK "$(FINISH_LINK)"
!define MUI_FINISHPAGE_LINK_LOCATION "${PROJECT_URL}"

!define MUI_LANGDLL_REGISTRY_ROOT "HKCU"
!define MUI_LANGDLL_REGISTRY_KEY "${REG_BASE}"
!define MUI_LANGDLL_REGISTRY_VALUENAME "Installer Language"
!define MUI_LANGDLL_ALLLANGUAGES

;-------------------------------------------------------------------------------
; Pages
;-------------------------------------------------------------------------------

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_COMPONENTS
!define MUI_PAGE_CUSTOMFUNCTION_LEAVE DirectoryLeave
!insertmacro MUI_PAGE_DIRECTORY
Page custom StatusPageShow StatusPageLeave
Page custom ModsPageShow ModsPageLeave
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; MUI2 unsets the unprefixed defines after the installer page, so the
; uninstaller welcome page needs its own copies.
!define MUI_WELCOMEPAGE_TITLE "$(UNW_TITLE)"
!define MUI_WELCOMEPAGE_TEXT "$(UNW_TEXT)"
!define MUI_PAGE_CUSTOMFUNCTION_SHOW un.WelcomeShow
!insertmacro MUI_UNPAGE_WELCOME
UninstPage custom un.RestorePageShow un.RestorePageLeave
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;-------------------------------------------------------------------------------
; Languages
;-------------------------------------------------------------------------------

!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "French"
!insertmacro MUI_LANGUAGE "German"
!insertmacro MUI_LANGUAGE "Spanish"
!insertmacro MUI_LANGUAGE "SpanishInternational"
!insertmacro MUI_LANGUAGE "Portuguese"
!insertmacro MUI_LANGUAGE "PortugueseBR"
!insertmacro MUI_LANGUAGE "Italian"
!insertmacro MUI_LANGUAGE "Dutch"
!insertmacro MUI_LANGUAGE "Danish"
!insertmacro MUI_LANGUAGE "Swedish"
!insertmacro MUI_LANGUAGE "Norwegian"
!insertmacro MUI_LANGUAGE "Finnish"
!insertmacro MUI_LANGUAGE "Polish"
!insertmacro MUI_LANGUAGE "Czech"
!insertmacro MUI_LANGUAGE "Slovak"
!insertmacro MUI_LANGUAGE "Hungarian"
!insertmacro MUI_LANGUAGE "Romanian"
!insertmacro MUI_LANGUAGE "Croatian"
!insertmacro MUI_LANGUAGE "Bulgarian"
!insertmacro MUI_LANGUAGE "Russian"
!insertmacro MUI_LANGUAGE "Ukrainian"
!insertmacro MUI_LANGUAGE "Turkish"
!insertmacro MUI_LANGUAGE "Greek"
!insertmacro MUI_LANGUAGE "SimpChinese"
!insertmacro MUI_LANGUAGE "TradChinese"
!insertmacro MUI_LANGUAGE "Japanese"
!insertmacro MUI_LANGUAGE "Korean"
!insertmacro MUI_LANGUAGE "Indonesian"
!insertmacro MUI_LANGUAGE "Catalan"

!insertmacro MUI_RESERVEFILE_LANGDLL

; Generated from tools/lang/*.json by tools/gen-lang.mjs
!include "lang\strings.nsh"

;-------------------------------------------------------------------------------
; Installer sections
;-------------------------------------------------------------------------------

Section "$(SEC_CORE_NAME)" SEC_CORE
  SectionIn RO
  SetOutPath "$INSTDIR"
  File "payload\modlauncher.jar"
  File "payload\patcher.jar"
  File "payload\javassist.jar"
  File "payload\patcher.bat"
  File "payload\patcher.sh"
  File "payload\logging.properties"
  CreateDirectory "$INSTDIR\mods"
  WriteUninstaller "$INSTDIR\${UNINST_EXE}"
SectionEnd

Section "$(SEC_MODS_NAME)" SEC_MODSFOLDER
  SetOutPath "$INSTDIR\mods"
  File "payload\mods\_Readme - Wurm Modloader.txt"
  SetOutPath "$INSTDIR"
SectionEnd

Section "$(SEC_SM_NAME)" SEC_SM
  CreateDirectory "$SMPROGRAMS\Wurm Unlimited"
  CreateShortCut "$SMPROGRAMS\Wurm Unlimited\Wurm Unlimited.lnk" "$INSTDIR\WurmLauncher.exe" "" "$INSTDIR\WurmLauncher.exe" 0
  CreateShortCut "$SMPROGRAMS\Wurm Unlimited\Mods Folder.lnk" "$INSTDIR\mods"
  CreateShortCut "$SMPROGRAMS\Wurm Unlimited\Uninstall ${APP_DISPLAY_NAME}.lnk" "$INSTDIR\${UNINST_EXE}"
SectionEnd

Section /o "$(SEC_DESK_NAME)" SEC_DESK
  CreateShortCut "$DESKTOP\Wurm Unlimited.lnk" "$INSTDIR\WurmLauncher.exe" "" "$INSTDIR\WurmLauncher.exe" 0
SectionEnd

Section "-Finalize"
  ${If} $OptSkipPatch == 1
    StrCpy $SkipPatch 1
  ${EndIf}
  ${If} $OptNoRestore == 1
    StrCpy $RestoreClient 0
  ${EndIf}

  Call FindJava
  Call UpdatePatchState
  Call ResolveSource

  ${If} $LogPath != ""
    Delete "$LogPath"
    Push "${APP_DISPLAY_NAME} ${APP_VERSION} - installation log"
    Call LogWrite
    Push "Install folder: $INSTDIR"
    Call LogWrite
    Push "Detected via: $DetectedSource"
    Call LogWrite
    Push "Java runtime: $JavaExe ($JavaVersion)"
    Call LogWrite
    Push "client.jar before install: $PatchState"
    Call LogWrite
    Push "Installer options: SkipPatch=$SkipPatch Restore=$RestoreClient ModsAction=$ModsAction"
    Call LogWrite
  ${EndIf}

  Call ApplyModChanges
  Call PatchClient
  Call ComputeInstallSize
  Call WriteInstallRegistry
  Call BuildFinishSummary
SectionEnd

Section "Uninstall"
  ${If} $RestoreClient == 1
    Call un.RestoreClientJar
  ${EndIf}

  ${If} $DeleteMods == 1
    RMDir /r "$INSTDIR\mods"
    DetailPrint "$(DP_MODS_REMOVED)"
  ${Else}
    Delete "$INSTDIR\mods\_Readme - Wurm Modloader.txt"
    RMDir "$INSTDIR\mods"
  ${EndIf}

  Delete "$INSTDIR\javassist.jar"
  Delete "$INSTDIR\logging.properties"
  Delete "$INSTDIR\modlauncher.jar"
  Delete "$INSTDIR\patcher.bat"
  Delete "$INSTDIR\patcher.jar"
  Delete "$INSTDIR\patcher.sh"
  Delete "$INSTDIR\modloader-install.log"
  Delete "$INSTDIR\client.jar.tmp"

  Delete "$SMPROGRAMS\Wurm Unlimited\Wurm Unlimited.lnk"
  Delete "$SMPROGRAMS\Wurm Unlimited\Mods Folder.lnk"
  Delete "$SMPROGRAMS\Wurm Unlimited\Uninstall ${APP_DISPLAY_NAME}.lnk"
  RMDir "$SMPROGRAMS\Wurm Unlimited"
  Delete "$DESKTOP\Wurm Unlimited.lnk"

  DeleteRegKey SHCTX "${UNINST_KEY}"
  DeleteRegKey SHCTX "${REG_BASE}"

  Delete "$INSTDIR\${UNINST_EXE}"
  RMDir "$INSTDIR"
SectionEnd

;-------------------------------------------------------------------------------
; Utility functions
;-------------------------------------------------------------------------------

Function LogWrite
  Exch $0
  Push $1
  ${If} $LogPath != ""
    ClearErrors
    FileOpen $1 "$LogPath" a
    ${IfNot} ${Errors}
      FileSeek $1 0 END
      FileWrite $1 "$0$\r$\n"
      FileClose $1
    ${EndIf}
  ${EndIf}
  Pop $1
  Pop $0
FunctionEnd

Function GetSizeOf
  Exch $0
  Push $1
  Push $2
  StrCpy $2 -1
  ClearErrors
  FileOpen $1 "$0" r
  IfErrors gso_done
  FileSeek $1 0 END $2
  FileClose $1
  gso_done:
  StrCpy $0 $2
  Pop $2
  Pop $1
  Exch $0
FunctionEnd

Function ExtractLastQuoted
  Exch $0
  Push $1
  Push $2
  StrCpy $1 ""
  elq_loop:
    ${StrLoc} $2 "$0" '"' ">"
    StrCmp $2 "" elq_done
    IntOp $2 $2 + 1
    StrCpy $0 "$0" "" $2
    ${StrLoc} $2 "$0" '"' ">"
    StrCmp $2 "" elq_done
    StrCpy $1 "$0" $2
    IntOp $2 $2 + 1
    StrCpy $0 "$0" "" $2
    Goto elq_loop
  elq_done:
  StrCpy $0 "$1"
  Pop $2
  Pop $1
  Exch $0
FunctionEnd

;-------------------------------------------------------------------------------
; Detection
;-------------------------------------------------------------------------------

Function TryWurmPath
  StrCpy $TryFound 0
  ${If} $TryPath == ""
    Return
  ${EndIf}

  StrCpy $0 "$TryPath"
  StrCpy $1 "$0" 1 -1
  ${If} $1 == "\"
    StrCpy $0 "$0" -1
  ${EndIf}

  ${If} ${FileExists} "$0\client.jar"
    StrCpy $DetectedPath "$0"
    Goto twp_success
  ${EndIf}

  ${If} ${FileExists} "$0\WurmLauncher\client.jar"
    StrCpy $DetectedPath "$0\WurmLauncher"
    Goto twp_success
  ${EndIf}

  ${If} ${FileExists} "$0\steamapps\common\Wurm Unlimited\WurmLauncher\client.jar"
    StrCpy $DetectedPath "$0\steamapps\common\Wurm Unlimited\WurmLauncher"
    Goto twp_success
  ${EndIf}

  ${If} ${FileExists} "$0\steamapps\appmanifest_${STEAM_APP_ID}.acf"
    StrCpy $2 ""
    ClearErrors
    FileOpen $3 "$0\steamapps\appmanifest_${STEAM_APP_ID}.acf" r
    ${IfNot} ${Errors}
      ${Do}
        ClearErrors
        FileRead $3 $4
        ${If} ${Errors}
          ${ExitDo}
        ${EndIf}
        ${StrTrimNewLines} $4 "$4"
        ${StrStr} $5 "$4" '"installdir"'
        ${If} $5 != ""
          Push "$4"
          Call ExtractLastQuoted
          Pop $2
          ${ExitDo}
        ${EndIf}
      ${Loop}
      FileClose $3
    ${EndIf}
    ${If} $2 == ""
      StrCpy $2 "Wurm Unlimited"
    ${EndIf}
    ${If} ${FileExists} "$0\steamapps\common\$2\WurmLauncher\client.jar"
      StrCpy $DetectedPath "$0\steamapps\common\$2\WurmLauncher"
      Goto twp_success
    ${EndIf}
  ${EndIf}

  Return

  twp_success:
  StrCpy $TryFound 1
  StrCpy $DetectedSourceId "$TrySource"
FunctionEnd

Function ParseLibraryFolders
  Exch $0
  Push $R0
  Push $1
  Push $2
  Push $3
  Push $4

  ClearErrors
  FileOpen $R0 "$0" r
  ${IfNot} ${Errors}
    ${Do}
      ClearErrors
      FileRead $R0 $2
      ${If} ${Errors}
        ${ExitDo}
      ${EndIf}
      ${StrTrimNewLines} $2 "$2"
      ${If} $2 != ""
        Push "$2"
        Call ExtractLastQuoted
        Pop $3
        ${If} $3 != ""
          ${StrStr} $4 "$3" ":"
          ${If} $4 != ""
            ${StrStr} $4 "$3" "\"
            ${If} $4 != ""
              ${StrRep} $3 "$3" "\\" "\"
              StrCpy $4 "$3" 1 -1
              ${If} $4 == "\"
                StrCpy $3 "$3" -1
              ${EndIf}
              StrCpy $TryPath "$3"
              StrCpy $TrySource "steam"
              Call TryWurmPath
              ${If} $TryFound == 1
                ${ExitDo}
              ${EndIf}
            ${EndIf}
          ${EndIf}
        ${EndIf}
      ${EndIf}
    ${Loop}
    FileClose $R0
  ${EndIf}

  Pop $4
  Pop $3
  Pop $2
  Pop $1
  Pop $R0
  Pop $0
FunctionEnd

Function TrySteamRoot
  ${If} $TryPath == ""
    Return
  ${EndIf}
  StrCpy $TrySource "steam"
  Call TryWurmPath
  ${If} $TryFound == 1
    Return
  ${EndIf}
  ${If} ${FileExists} "$TryPath\steamapps\libraryfolders.vdf"
    Push "$TryPath\steamapps\libraryfolders.vdf"
    Call ParseLibraryFolders
  ${EndIf}
FunctionEnd

Function DetectWurm
  ; 1. previous installation of this installer
  ReadRegStr $0 SHCTX "${REG_BASE}" "InstallDir"
  ${If} $0 != ""
    StrCpy $TryPath "$0"
    StrCpy $TrySource "prev"
    Call TryWurmPath
    ${If} $TryFound == 1
      Return
    ${EndIf}
  ${EndIf}

  ; 2. older Jubaroo installer (v0.8.1)
  ReadRegStr $0 HKCU "Software\Wurm Client Modloader v0.8.1" ""
  ${If} $0 != ""
    StrCpy $TryPath "$0"
    StrCpy $TrySource "old"
    Call TryWurmPath
    ${If} $TryFound == 1
      Return
    ${EndIf}
  ${EndIf}

  ; 3. Steam path from HKCU
  ReadRegStr $0 HKCU "Software\Valve\Steam" "SteamPath"
  ${If} $0 != ""
    StrCpy $TryPath "$0"
    Call TrySteamRoot
    ${If} $TryFound == 1
      Return
    ${EndIf}
  ${EndIf}

  ; 4. Steam install path from HKLM (32-bit view)
  ReadRegStr $0 HKLM "Software\Valve\Steam" "InstallPath"
  ${If} $0 != ""
    StrCpy $TryPath "$0"
    Call TrySteamRoot
    ${If} $TryFound == 1
      Return
    ${EndIf}
  ${EndIf}

  ; 5. Steam install path from HKLM (64-bit view)
  ${If} ${RunningX64}
    SetRegView 64
    ReadRegStr $0 HKLM "Software\Valve\Steam" "InstallPath"
    SetRegView 32
    ${If} $0 != ""
      StrCpy $TryPath "$0"
      Call TrySteamRoot
      ${If} $TryFound == 1
        Return
      ${EndIf}
    ${EndIf}
  ${EndIf}

  ; 6. Steam app uninstall entry (per user)
  ReadRegStr $0 HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\Steam App ${STEAM_APP_ID}" "InstallLocation"
  ${If} $0 != ""
    StrCpy $TryPath "$0"
    StrCpy $TrySource "app"
    Call TryWurmPath
    ${If} $TryFound == 1
      Return
    ${EndIf}
  ${EndIf}

  ; 7. Steam app uninstall entry (per machine)
  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\Steam App ${STEAM_APP_ID}" "InstallLocation"
  ${If} $0 != ""
    StrCpy $TryPath "$0"
    StrCpy $TrySource "app"
    Call TryWurmPath
    ${If} $TryFound == 1
      Return
    ${EndIf}
  ${EndIf}

  ; 8. common locations
  StrCpy $TryPath "$PROGRAMFILES\Steam"
  Call TrySteamRoot
  ${If} $TryFound == 1
    Return
  ${EndIf}
  StrCpy $TryPath "C:\Program Files (x86)\Steam"
  Call TrySteamRoot
  ${If} $TryFound == 1
    Return
  ${EndIf}
  StrCpy $TryPath "C:\Program Files\Steam"
  Call TrySteamRoot
  ${If} $TryFound == 1
    Return
  ${EndIf}
  StrCpy $TryPath "C:\SteamLibrary"
  Call TrySteamRoot
  ${If} $TryFound == 1
    Return
  ${EndIf}
  StrCpy $TryPath "D:\SteamLibrary"
  Call TrySteamRoot
  ${If} $TryFound == 1
    Return
  ${EndIf}
  StrCpy $TryPath "D:\Steam"
  Call TrySteamRoot
  ${If} $TryFound == 1
    Return
  ${EndIf}
  StrCpy $TryPath "E:\SteamLibrary"
  Call TrySteamRoot
FunctionEnd

;-------------------------------------------------------------------------------
; Java runtime detection
;-------------------------------------------------------------------------------

Function FindJava
  StrCpy $JavaExe ""
  StrCpy $JavaSource ""

  ${If} ${FileExists} "$INSTDIR\..\runtime\bin\java.exe"
    GetFullPathName $JavaExe "$INSTDIR\..\runtime\bin\java.exe"
    StrCpy $JavaSource "Wurm Unlimited bundled runtime"
  ${ElseIf} ${FileExists} "$INSTDIR\runtime\bin\java.exe"
    GetFullPathName $JavaExe "$INSTDIR\runtime\bin\java.exe"
    StrCpy $JavaSource "Wurm Unlimited bundled runtime"
  ${Else}
    ReadRegStr $0 HKLM "SOFTWARE\JavaSoft\Java Runtime Environment" "CurrentVersion"
    ${If} $0 != ""
      ReadRegStr $1 HKLM "SOFTWARE\JavaSoft\Java Runtime Environment\$0" "JavaHome"
      ${If} $1 != ""
      ${AndIf} ${FileExists} "$1\bin\java.exe"
        StrCpy $JavaExe "$1\bin\java.exe"
        StrCpy $JavaSource "JavaSoft registry (32-bit)"
      ${EndIf}
    ${EndIf}
    ${If} $JavaExe == ""
    ${AndIf} ${RunningX64}
      SetRegView 64
      ReadRegStr $0 HKLM "SOFTWARE\JavaSoft\Java Runtime Environment" "CurrentVersion"
      ${If} $0 != ""
        ReadRegStr $1 HKLM "SOFTWARE\JavaSoft\Java Runtime Environment\$0" "JavaHome"
        ${If} $1 != ""
        ${AndIf} ${FileExists} "$1\bin\java.exe"
          StrCpy $JavaExe "$1\bin\java.exe"
          StrCpy $JavaSource "JavaSoft registry (64-bit)"
        ${EndIf}
      ${EndIf}
      SetRegView 32
    ${EndIf}
    ${If} $JavaExe == ""
      ReadEnvStr $0 "JAVA_HOME"
      ${If} $0 != ""
      ${AndIf} ${FileExists} "$0\bin\java.exe"
        StrCpy $JavaExe "$0\bin\java.exe"
        StrCpy $JavaSource "JAVA_HOME"
      ${Else}
        ClearErrors
        SearchPath $0 "java.exe"
        ${If} $0 != ""
          StrCpy $JavaExe "$0"
          StrCpy $JavaSource "system PATH"
        ${EndIf}
      ${EndIf}
    ${EndIf}
  ${EndIf}

  StrCpy $JavaVersion ""
  ${If} $JavaExe != ""
    nsExec::ExecToStack '"$JavaExe" -version'
    Pop $0
    Pop $1
    ${StrLoc} $2 "$1" 'version "' ">"
    ${If} $2 != ""
      IntOp $2 $2 + 9
      StrCpy $1 "$1" "" $2
      ${StrLoc} $2 "$1" '"' ">"
      ${If} $2 != ""
        StrCpy $1 "$1" $2
        StrCpy $JavaVersion "$1"
      ${EndIf}
    ${EndIf}
  ${EndIf}
FunctionEnd

;-------------------------------------------------------------------------------
; client.jar state and patching
;-------------------------------------------------------------------------------

Function UpdatePatchState
  ${IfNot} ${FileExists} "$INSTDIR\client.jar"
    StrCpy $PatchState "missing"
    Return
  ${EndIf}

  Push "$INSTDIR\client.jar"
  Call GetSizeOf
  Pop $0

  ${If} ${FileExists} "$INSTDIR\client-patched.jar"
    ${If} $0 > 0
    ${AndIf} $0 < 1048576
      StrCpy $PatchState "patched"
    ${Else}
      StrCpy $PatchState "backup-stale"
    ${EndIf}
  ${Else}
    ${If} $0 > 0
    ${AndIf} $0 < 1048576
      StrCpy $PatchState "patched-nobackup"
    ${Else}
      StrCpy $PatchState "original"
    ${EndIf}
  ${EndIf}
FunctionEnd

Function RestoreClientJar
  DetailPrint "$(DP_RESTORE)"
  Delete "$INSTDIR\client.jar.tmp"
  ClearErrors
  CopyFiles /SILENT "$INSTDIR\client-patched.jar" "$INSTDIR\client.jar.tmp"
  ${If} ${Errors}
    Push "ERROR: could not copy client-patched.jar"
    Call LogWrite
    StrCpy $PatchResult "restore-failed"
    Return
  ${EndIf}
  Delete "$INSTDIR\client.jar"
  ClearErrors
  Rename "$INSTDIR\client.jar.tmp" "$INSTDIR\client.jar"
  ${If} ${Errors}
    Push "ERROR: could not replace client.jar"
    Call LogWrite
    StrCpy $PatchResult "restore-failed"
    Return
  ${EndIf}
  Delete "$INSTDIR\client-patched.jar"
  Push "Original client.jar restored"
  Call LogWrite
FunctionEnd

Function PatchClient
  StrCpy $PatchResult "notrun"

  ${If} $SkipPatch == 1
    StrCpy $PatchResult "skipped"
    Push "Patching skipped by user"
    Call LogWrite
    Return
  ${EndIf}

  ${IfNot} ${FileExists} "$INSTDIR\client.jar"
    StrCpy $PatchResult "missing"
    Push "ERROR: client.jar not found - cannot patch"
    Call LogWrite
    Return
  ${EndIf}

  ${If} $RestoreClient == 1
  ${AndIf} ${FileExists} "$INSTDIR\client-patched.jar"
    Call RestoreClientJar
    ${If} $PatchResult == "restore-failed"
      Return
    ${EndIf}
  ${EndIf}

  Call FindJava
  ${If} $JavaExe == ""
    StrCpy $PatchResult "nojava"
    Push "ERROR: no Java runtime found - cannot patch"
    Call LogWrite
    Return
  ${EndIf}

  SetOutPath "$INSTDIR"
  DetailPrint "$(DP_PATCHING)"
  Push "Running: $JavaExe -classpath patcher.jar;javassist.jar org.gotti.wurmunlimited.patcher.PatchClientJar"
  Call LogWrite

  nsExec::ExecToStack '"$JavaExe" -classpath "$INSTDIR\patcher.jar;$INSTDIR\javassist.jar" org.gotti.wurmunlimited.patcher.PatchClientJar'
  Pop $0
  Pop $1

  ${If} $LogPath != ""
    ClearErrors
    FileOpen $2 "$LogPath" a
    ${IfNot} ${Errors}
      FileSeek $2 0 END
      FileWrite $2 "--- patcher output (exit code $0) ---$\r$\n$1$\r$\n"
      FileClose $2
    ${EndIf}
  ${EndIf}

  DetailPrint "$(DP_PATCH_EXIT) $0"

  ${If} $0 == 0
    Push "$INSTDIR\client.jar"
    Call GetSizeOf
    Pop $2
    ${If} $2 > 0
    ${AndIf} $2 < 1048576
      StrCpy $PatchResult "patched"
      Push "client.jar patched successfully"
      Call LogWrite
    ${Else}
      StrCpy $PatchResult "failed"
      Push "ERROR: client.jar does not look patched after running the patcher"
      Call LogWrite
    ${EndIf}
  ${Else}
    StrCpy $PatchResult "failed"
    Push "ERROR: patcher exited with code $0"
    Call LogWrite
  ${EndIf}
FunctionEnd

Function ComputeInstallSize
  StrCpy $InstallSizeKb 0

  Push "$INSTDIR\modlauncher.jar"
  Call GetSizeOf
  Pop $0
  ${If} $0 > 0
    IntOp $InstallSizeKb $InstallSizeKb + $0
  ${EndIf}

  Push "$INSTDIR\patcher.jar"
  Call GetSizeOf
  Pop $0
  ${If} $0 > 0
    IntOp $InstallSizeKb $InstallSizeKb + $0
  ${EndIf}

  Push "$INSTDIR\javassist.jar"
  Call GetSizeOf
  Pop $0
  ${If} $0 > 0
    IntOp $InstallSizeKb $InstallSizeKb + $0
  ${EndIf}

  Push "$INSTDIR\logging.properties"
  Call GetSizeOf
  Pop $0
  ${If} $0 > 0
    IntOp $InstallSizeKb $InstallSizeKb + $0
  ${EndIf}

  Push "$INSTDIR\modloader-install.log"
  Call GetSizeOf
  Pop $0
  ${If} $0 > 0
    IntOp $InstallSizeKb $InstallSizeKb + $0
  ${EndIf}

  IntOp $InstallSizeKb $InstallSizeKb / 1024
  ${If} $InstallSizeKb < 1
    StrCpy $InstallSizeKb 1
  ${EndIf}
FunctionEnd

Function WriteInstallRegistry
  WriteRegStr SHCTX "${REG_BASE}" "InstallDir" "$INSTDIR"
  WriteRegStr SHCTX "${REG_BASE}" "Version" "${APP_VERSION}"
  WriteRegStr SHCTX "${REG_BASE}" "LoaderVersion" "${LOADER_VERSION}"
  WriteRegStr SHCTX "${REG_BASE}" "StartMenuFolder" "Wurm Unlimited"

  WriteRegStr SHCTX "${UNINST_KEY}" "DisplayName" "${APP_DISPLAY_NAME}"
  WriteRegStr SHCTX "${UNINST_KEY}" "DisplayVersion" "${APP_VERSION}"
  WriteRegStr SHCTX "${UNINST_KEY}" "DisplayIcon" "$INSTDIR\WurmLauncher.exe,0"
  WriteRegStr SHCTX "${UNINST_KEY}" "Publisher" "${PUBLISHER}"
  WriteRegStr SHCTX "${UNINST_KEY}" "URLInfoAbout" "${PROJECT_URL}"
  WriteRegStr SHCTX "${UNINST_KEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr SHCTX "${UNINST_KEY}" "UninstallString" '"$INSTDIR\${UNINST_EXE}"'
  WriteRegStr SHCTX "${UNINST_KEY}" "QuietUninstallString" '"$INSTDIR\${UNINST_EXE}" /S'
  WriteRegDWORD SHCTX "${UNINST_KEY}" "EstimatedSize" "$InstallSizeKb"
  WriteRegDWORD SHCTX "${UNINST_KEY}" "NoModify" 1
  WriteRegDWORD SHCTX "${UNINST_KEY}" "NoRepair" 1
FunctionEnd

Function BuildFinishSummary
  StrLen $0 "$INSTDIR"
  ${If} $0 > 46
    IntOp $0 $0 - 43
    StrCpy $1 "$INSTDIR" "" $0
    StrCpy $R0 "...$1"
  ${Else}
    StrCpy $R0 "$INSTDIR"
  ${EndIf}
  StrCpy $FinishDetails "$(FINISH_INSTALLED) $R0.$\r$\n$\r$\n"
  ${If} $PatchResult == "patched"
    StrCpy $FinishDetails "$FinishDetails$(FINISH_PATCHED)"
  ${ElseIf} $PatchResult == "skipped"
    StrCpy $FinishDetails "$FinishDetails$(FINISH_SKIPPED)"
  ${ElseIf} $PatchResult == "failed"
    StrCpy $FinishDetails "$FinishDetails$(FINISH_FAILED)"
  ${ElseIf} $PatchResult == "nojava"
    StrCpy $FinishDetails "$FinishDetails$(FINISH_NOJAVA)"
  ${ElseIf} $PatchResult == "missing"
    StrCpy $FinishDetails "$FinishDetails$(FINISH_NOCLIENT)"
  ${Else}
    StrCpy $FinishDetails "$FinishDetails$(FINISH_FILES)"
  ${EndIf}
  ${If} $ApplyErrors != ""
    StrCpy $FinishDetails "$FinishDetails$\r$\n$(FINISH_MODS_WARN)"
  ${EndIf}
FunctionEnd

;-------------------------------------------------------------------------------
; Directory page validation
;-------------------------------------------------------------------------------

Function DirectoryLeave
  StrCpy $0 "$INSTDIR" 1 -1
  ${If} $0 == "\"
    StrCpy $INSTDIR "$INSTDIR" -1
  ${EndIf}

  ${IfNot} ${FileExists} "$INSTDIR\*.*"
    MessageBox MB_OK|MB_ICONEXCLAMATION "$(MSG_FOLDER_MISSING)$\r$\n$INSTDIR$\r$\n$\r$\n$(MSG_PICK_WURMLAUNCHER)"
    Abort
  ${EndIf}

  ${GetFileName} "$INSTDIR" $0
  ${If} $0 == "WurmServerLauncher"
    MessageBox MB_OK|MB_ICONEXCLAMATION "$(MSG_SERVER_DIR)"
    Abort
  ${EndIf}

  ${IfNot} ${FileExists} "$INSTDIR\client.jar"
    ${If} ${FileExists} "$INSTDIR\WurmLauncher\client.jar"
      StrCpy $INSTDIR "$INSTDIR\WurmLauncher"
    ${ElseIf} ${FileExists} "$INSTDIR\WurmLauncher.exe"
      MessageBox MB_YESNO|MB_ICONEXCLAMATION "$(MSG_INCOMPLETE_HEAD)$\r$\n$INSTDIR$\r$\n$\r$\n$(MSG_INCOMPLETE)" IDYES dl_continue
      Abort
      dl_continue:
    ${Else}
      MessageBox MB_OK|MB_ICONEXCLAMATION "$(MSG_NO_CLIENT_HEAD)$\r$\n$INSTDIR$\r$\n$\r$\n$(MSG_PICK_WURMLAUNCHER)"
      Abort
    ${EndIf}
  ${EndIf}

  ${If} $INSTDIR != $DetectedPath
    StrCpy $DetectedSourceId "manual"
  ${EndIf}
FunctionEnd

;-------------------------------------------------------------------------------
; Status page
;-------------------------------------------------------------------------------

; Detection runs in .onInit, where language strings still resolve to the
; default language, so only a token is stored there.
Function ResolveSource
  ${If} $DetectedSourceId == "steam"
    StrCpy $DetectedSource "$(SRC_STEAM)"
  ${ElseIf} $DetectedSourceId == "prev"
    StrCpy $DetectedSource "$(SRC_PREV)"
  ${ElseIf} $DetectedSourceId == "old"
    StrCpy $DetectedSource "$(SRC_OLD)"
  ${ElseIf} $DetectedSourceId == "app"
    StrCpy $DetectedSource "$(SRC_APPENTRY)"
  ${ElseIf} $DetectedSourceId == "command"
    StrCpy $DetectedSource "$(SRC_COMMAND)"
  ${ElseIf} $DetectedSourceId == "manual"
    StrCpy $DetectedSource "$(SRC_MANUAL)"
  ${Else}
    StrCpy $DetectedSource "$(SRC_NOTFOUND)"
  ${EndIf}
FunctionEnd

Function StatusPageShow
  !insertmacro MUI_HEADER_TEXT "$(ST_TITLE)" "$(ST_SUB)"

  Call ResolveSource
  Call FindJava
  Call UpdatePatchState

  ${If} $PatchState == "original"
    StrCpy $ClientStatus "$(ST_CL_ORIGINAL)"
  ${ElseIf} $PatchState == "patched"
    StrCpy $ClientStatus "$(ST_CL_PATCHED)"
  ${ElseIf} $PatchState == "backup-stale"
    StrCpy $ClientStatus "$(ST_CL_STALE)"
  ${ElseIf} $PatchState == "patched-nobackup"
    StrCpy $ClientStatus "$(ST_CL_NOBACKUP)"
  ${Else}
    StrCpy $ClientStatus "$(ST_CL_MISSING)"
  ${EndIf}

  StrCpy $JavaDisplay "$JavaExe"
  ${If} $JavaDisplay == ""
    StrCpy $JavaDisplay "$(ST_CL_MISSING)"
  ${EndIf}

  StrCpy $StatusNote ""
  ${If} $PatchState == "missing"
    StrCpy $StatusNote "$(ST_NOTE_MISSING)"
  ${ElseIf} $PatchState == "patched-nobackup"
    StrCpy $StatusNote "$(ST_NOTE_NOBACKUP)"
  ${ElseIf} $JavaExe == ""
    StrCpy $StatusNote "$(ST_NOTE_NOJAVA)"
  ${ElseIf} $PatchState == "backup-stale"
    StrCpy $StatusNote "$(ST_NOTE_STALE)"
  ${EndIf}

  nsDialogs::Create 1018
  Pop $hStatusDialog
  ${If} $hStatusDialog == error
    Abort
  ${EndIf}

  ${NSD_CreateLabel} 0 0 100% 12u "$(ST_INTRO)"
  Pop $0

  ${NSD_CreateGroupBox} 0 15u 100% 62u "$(ST_GROUP)"
  Pop $0

  ${NSD_CreateLabel} 5u 25u 62u 8u "$(ST_LBL_FOLDER)"
  Pop $0
  ${NSD_CreateText} 70u 24u -76u 10u "$INSTDIR"
  Pop $1
  SendMessage $1 ${EM_SETREADONLY} 1 0

  ${NSD_CreateLabel} 5u 36u 62u 8u "$(ST_LBL_SOURCE)"
  Pop $0
  ${NSD_CreateLabel} 70u 36u -76u 8u "$DetectedSource"
  Pop $0

  ${NSD_CreateLabel} 5u 46u 62u 8u "$(ST_LBL_JAVA)"
  Pop $0
  ${NSD_CreateText} 70u 45u -76u 10u "$JavaDisplay"
  Pop $1
  SendMessage $1 ${EM_SETREADONLY} 1 0

  ${NSD_CreateLabel} 5u 57u 62u 8u "$(ST_LBL_JAVAVER)"
  Pop $0
  ${NSD_CreateLabel} 70u 57u -76u 8u "$JavaVersion"
  Pop $0

  ${NSD_CreateLabel} 5u 67u 62u 8u "$(ST_LBL_CLIENT)"
  Pop $0
  ${NSD_CreateLabel} 70u 67u -76u 8u "$ClientStatus"
  Pop $0

  ${NSD_CreateCheckBox} 0 82u 100% 10u "$(ST_CHK_RESTORE)"
  Pop $hChkRestore
  ${NSD_OnClick} $hChkRestore OnRestoreClick
  ${NSD_CreateCheckBox} 0 92u 100% 10u "$(ST_CHK_SKIP)"
  Pop $hChkSkip
  ${NSD_OnClick} $hChkSkip OnSkipClick
  ${NSD_CreateCheckBox} 0 102u 100% 10u "$(ST_CHK_LOG)"
  Pop $hChkLog

  ${NSD_CreateLabel} 0 113u 100% 24u "$StatusNote"
  Pop $1
  SetCtlColors $1 0x0000C0 "transparent"

  ${If} $StatusSeen == 1
    ${If} $RestoreClient == 1
      ${NSD_Check} $hChkRestore
    ${EndIf}
    ${If} $SkipPatch == 1
      ${NSD_Check} $hChkSkip
    ${EndIf}
    ${If} $WriteLog == 1
      ${NSD_Check} $hChkLog
    ${EndIf}
  ${Else}
    ${If} $PatchState == "patched"
      ${NSD_Check} $hChkRestore
    ${EndIf}
    ${If} $WriteLog == 1
      ${NSD_Check} $hChkLog
    ${EndIf}
    ${If} $JavaExe == ""
    ${OrIf} $PatchState == "missing"
    ${OrIf} $PatchState == "patched-nobackup"
      ${NSD_Check} $hChkSkip
    ${EndIf}
    StrCpy $StatusSeen 1
  ${EndIf}

  Call SyncPatchOptions

  nsDialogs::Show
FunctionEnd

; Restore and Skip contradict each other: restoring the backup and then
; not patching would silently undo the install.
Function SyncPatchOptions
  ${NSD_GetState} $hChkRestore $0
  ${NSD_GetState} $hChkSkip $1

  StrCpy $2 1
  ${If} $PatchState != "patched"
    StrCpy $2 0
  ${EndIf}

  StrCpy $3 1
  ${If} $JavaExe == ""
  ${OrIf} $PatchState == "missing"
  ${OrIf} $PatchState == "patched-nobackup"
    StrCpy $3 0
  ${EndIf}

  ${If} $1 == ${BST_CHECKED}
    StrCpy $2 0
  ${ElseIf} $0 == ${BST_CHECKED}
    StrCpy $3 0
  ${EndIf}

  EnableWindow $hChkRestore $2
  EnableWindow $hChkSkip $3
FunctionEnd

Function OnRestoreClick
  Pop $0
  ${NSD_GetState} $hChkRestore $1
  ${If} $1 == ${BST_CHECKED}
    ${NSD_Uncheck} $hChkSkip
  ${EndIf}
  Call SyncPatchOptions
FunctionEnd

Function OnSkipClick
  Pop $0
  ${NSD_GetState} $hChkSkip $1
  ${If} $1 == ${BST_CHECKED}
    ${NSD_Uncheck} $hChkRestore
  ${EndIf}
  Call SyncPatchOptions
FunctionEnd

Function StatusPageLeave
  ${NSD_GetState} $hChkRestore $0
  ${If} $0 == ${BST_CHECKED}
    StrCpy $RestoreClient 1
  ${Else}
    StrCpy $RestoreClient 0
  ${EndIf}

  ${NSD_GetState} $hChkSkip $0
  ${If} $0 == ${BST_CHECKED}
    StrCpy $SkipPatch 1
  ${Else}
    StrCpy $SkipPatch 0
  ${EndIf}

  ${NSD_GetState} $hChkLog $0
  ${If} $0 == ${BST_CHECKED}
    StrCpy $WriteLog 1
    ${If} $LogPath == ""
      StrCpy $LogPath "$INSTDIR\modloader-install.log"
    ${EndIf}
  ${Else}
    StrCpy $WriteLog 0
    StrCpy $LogPath ""
  ${EndIf}
FunctionEnd

;-------------------------------------------------------------------------------
; Mods page
;-------------------------------------------------------------------------------

Function RegisterMod
  ReadINIStr $0 "$ModsIni" "mods" "$ModBase"
  ${If} $0 != ""
    Return
  ${EndIf}

  ${If} ${FileExists} "$INSTDIR\mods\$ModBase.properties"
    StrCpy $0 "on"
  ${ElseIf} ${FileExists} "$INSTDIR\mods\$ModBase.properties.disabled"
    StrCpy $0 "off"
  ${ElseIf} ${FileExists} "$INSTDIR\mods\$ModBase\$ModBase.jar"
    StrCpy $0 "on"
  ${Else}
    StrCpy $0 "off"
  ${EndIf}

  IntOp $ModCount $ModCount + 1
  WriteINIStr "$ModsIni" "mods" "$ModBase" "$0"
  WriteINIStr "$ModsIni" "order" "$ModCount" "$ModBase"

  ${If} $0 == "on"
    IntOp $ModsOn $ModsOn + 1
  ${Else}
    IntOp $ModsOff $ModsOff + 1
  ${EndIf}
FunctionEnd

Function ScanMods
  StrCpy $ModCount 0
  StrCpy $ModsOn 0
  StrCpy $ModsOff 0

  ; Keep previously staged toggles when the page is shown again
  Delete "$ModsIni.prev"
  ${If} ${FileExists} "$ModsIni"
    Rename "$ModsIni" "$ModsIni.prev"
  ${EndIf}
  Delete "$ModsIni"

  ${IfNot} ${FileExists} "$INSTDIR\mods\*.*"
    Delete "$ModsIni.prev"
    Return
  ${EndIf}

  ClearErrors
  FindFirst $R0 $R1 "$INSTDIR\mods\*"
  ${If} ${Errors}
    Delete "$ModsIni.prev"
    Return
  ${EndIf}

  ${Do}
    ${If} $R1 == ""
      ${ExitDo}
    ${EndIf}

    ${If} $R1 != "."
    ${AndIf} $R1 != ".."
      StrCpy $R3 "$R1"
      ${StrLoc} $R4 "$R1" ".disabled" "<"
      ${If} $R4 == "0"
        StrCpy $R3 "$R1" -9
      ${EndIf}
      ${If} ${FileExists} "$INSTDIR\mods\$R1\$R3.jar"
        StrCpy $ModBase "$R3"
        Call RegisterMod
      ${EndIf}

      ${StrLoc} $R4 "$R1" ".properties.disabled" "<"
      ${If} $R4 == "0"
        StrCpy $R3 "$R1" -20
        StrCpy $ModBase "$R3"
        Call RegisterMod
      ${Else}
        ${StrLoc} $R4 "$R1" ".properties" "<"
        ${If} $R4 == "0"
          StrCpy $R3 "$R1" -11
          StrCpy $ModBase "$R3"
          Call RegisterMod
        ${EndIf}
      ${EndIf}
    ${EndIf}

    FindNext $R0 $R1
  ${Loop}

  FindClose $R0

  ${If} ${FileExists} "$ModsIni.prev"
    StrCpy $R0 1
    ${Do}
      ${If} $R0 > $ModCount
        ${ExitDo}
      ${EndIf}
      ReadINIStr $R1 "$ModsIni" "order" "$R0"
      ReadINIStr $R2 "$ModsIni.prev" "mods" "$R1"
      ${If} $R2 == "on"
      ${OrIf} $R2 == "off"
        ReadINIStr $R3 "$ModsIni" "mods" "$R1"
        ${If} $R3 != $R2
          WriteINIStr "$ModsIni" "mods" "$R1" "$R2"
          ${If} $R2 == "on"
            IntOp $ModsOn $ModsOn + 1
            IntOp $ModsOff $ModsOff - 1
          ${Else}
            IntOp $ModsOn $ModsOn - 1
            IntOp $ModsOff $ModsOff + 1
          ${EndIf}
        ${EndIf}
      ${EndIf}
      IntOp $R0 $R0 + 1
    ${Loop}
    Delete "$ModsIni.prev"
  ${EndIf}

  WriteINIStr "$ModsIni" "meta" "count" "$ModCount"
FunctionEnd

Function PopulateModsList
  SendMessage $hModsList ${LB_RESETCONTENT} 0 0

  StrCpy $R0 1
  ${Do}
    ${If} $R0 > $ModCount
      ${ExitDo}
    ${EndIf}
    ReadINIStr $R1 "$ModsIni" "order" "$R0"
    ReadINIStr $R2 "$ModsIni" "mods" "$R1"
    ${If} $R2 == "on"
      StrCpy $R3 "$(MODS_ON)"
    ${Else}
      StrCpy $R3 "$(MODS_OFF)"
    ${EndIf}
    StrCpy $R3 "$R3   $R1"
    SendMessage $hModsList ${LB_ADDSTRING} 0 "STR:$R3"
    IntOp $R0 $R0 + 1
  ${Loop}

  ${NSD_SetText} $hModsStatus "$(MODS_STATUS) $ModsOn / $ModCount"
FunctionEnd

Function ModsPageShow
  Call ScanMods
  ${If} $ModCount == 0
    Abort
  ${EndIf}

  !insertmacro MUI_HEADER_TEXT "$(MODS_TITLE)" "$(MODS_SUB)"

  nsDialogs::Create 1018
  Pop $hModsDialog
  ${If} $hModsDialog == error
    Abort
  ${EndIf}

  ${NSD_CreateLabel} 0 0 100% 24u "$(MODS_INTRO)"
  Pop $0

  ${NSD_CreateListBox} 0 26u 100% 64u ""
  Pop $hModsList

  ${NSD_CreateButton} 0 92u 88u 13u "$(MODS_TOGGLE)"
  Pop $hBtnToggle
  ${NSD_OnClick} $hBtnToggle OnToggleMod

  ${NSD_CreateButton} 91u 92u 88u 13u "$(MODS_ENABLE_ALL)"
  Pop $hBtnEnableAll
  ${NSD_OnClick} $hBtnEnableAll OnEnableAllMods

  ${NSD_CreateButton} 182u 92u 88u 13u "$(MODS_DISABLE_ALL)"
  Pop $hBtnDisableAll
  ${NSD_OnClick} $hBtnDisableAll OnDisableAllMods

  ${NSD_CreateLabel} 0 108u 206u 12u ""
  Pop $hModsStatus

  ${NSD_CreateButton} 214u 107u 76u 13u "$(MODS_OPEN)"
  Pop $hBtnOpenMods
  ${NSD_OnClick} $hBtnOpenMods OnOpenModsFolder

  StrLen $0 "$INSTDIR\mods"
  ${If} $0 > 64
    IntOp $0 $0 - 61
    StrCpy $1 "$INSTDIR\mods" "" $0
    StrCpy $R0 "...$1"
  ${Else}
    StrCpy $R0 "$INSTDIR\mods"
  ${EndIf}
  ${NSD_CreateLabel} 0 124u 100% 12u "$(MODS_FOLDER) $R0"
  Pop $0
  SetCtlColors $0 0x666666 "transparent"

  Call PopulateModsList
  nsDialogs::Show
FunctionEnd

Function ModsPageLeave
FunctionEnd

Function OnToggleMod
  Pop $0
  SendMessage $hModsList ${LB_GETCURSEL} 0 0 $0
  ${If} $0 < 0
    Return
  ${EndIf}

  IntOp $0 $0 + 1
  ReadINIStr $1 "$ModsIni" "order" "$0"
  ${If} $1 == ""
    Return
  ${EndIf}

  ReadINIStr $2 "$ModsIni" "mods" "$1"
  ${If} $2 == "on"
    WriteINIStr "$ModsIni" "mods" "$1" "off"
    IntOp $ModsOn $ModsOn - 1
    IntOp $ModsOff $ModsOff + 1
  ${Else}
    WriteINIStr "$ModsIni" "mods" "$1" "on"
    IntOp $ModsOn $ModsOn + 1
    IntOp $ModsOff $ModsOff - 1
  ${EndIf}

  Call PopulateModsList
FunctionEnd

Function OnEnableAllMods
  Pop $0
  StrCpy $R0 1
  ${Do}
    ${If} $R0 > $ModCount
      ${ExitDo}
    ${EndIf}
    ReadINIStr $R1 "$ModsIni" "order" "$R0"
    WriteINIStr "$ModsIni" "mods" "$R1" "on"
    IntOp $R0 $R0 + 1
  ${Loop}
  StrCpy $ModsOn $ModCount
  StrCpy $ModsOff 0
  Call PopulateModsList
FunctionEnd

Function OnDisableAllMods
  Pop $0
  StrCpy $R0 1
  ${Do}
    ${If} $R0 > $ModCount
      ${ExitDo}
    ${EndIf}
    ReadINIStr $R1 "$ModsIni" "order" "$R0"
    WriteINIStr "$ModsIni" "mods" "$R1" "off"
    IntOp $R0 $R0 + 1
  ${Loop}
  StrCpy $ModsOn 0
  StrCpy $ModsOff $ModCount
  Call PopulateModsList
FunctionEnd

Function OnOpenModsFolder
  Pop $0
  ExecShell "open" "$INSTDIR\mods"
FunctionEnd

;-------------------------------------------------------------------------------
; Applying mod changes
;-------------------------------------------------------------------------------

Function ApplyModState
  ${If} $ModAction == "enable"
    ${If} ${FileExists} "$INSTDIR\mods\$ModBase.properties.disabled"
      ${If} ${FileExists} "$INSTDIR\mods\$ModBase.properties"
        Delete "$INSTDIR\mods\$ModBase.properties"
      ${EndIf}
      ClearErrors
      Rename "$INSTDIR\mods\$ModBase.properties.disabled" "$INSTDIR\mods\$ModBase.properties"
      ${If} ${Errors}
        StrCpy $ApplyErrors "$ApplyErrors$ModBase (properties); "
      ${EndIf}
    ${EndIf}
    ${If} ${FileExists} "$INSTDIR\mods\$ModBase.disabled\*.*"
      ${IfNot} ${FileExists} "$INSTDIR\mods\$ModBase\*.*"
        ClearErrors
        Rename "$INSTDIR\mods\$ModBase.disabled" "$INSTDIR\mods\$ModBase"
        ${If} ${Errors}
          StrCpy $ApplyErrors "$ApplyErrors$ModBase (folder); "
        ${EndIf}
      ${EndIf}
    ${EndIf}
  ${Else}
    ${If} ${FileExists} "$INSTDIR\mods\$ModBase.properties"
      ${If} ${FileExists} "$INSTDIR\mods\$ModBase.properties.disabled"
        Delete "$INSTDIR\mods\$ModBase.properties.disabled"
      ${EndIf}
      ClearErrors
      Rename "$INSTDIR\mods\$ModBase.properties" "$INSTDIR\mods\$ModBase.properties.disabled"
      ${If} ${Errors}
        StrCpy $ApplyErrors "$ApplyErrors$ModBase (properties); "
      ${EndIf}
    ${EndIf}
    ${If} ${FileExists} "$INSTDIR\mods\$ModBase\*.*"
      ${IfNot} ${FileExists} "$INSTDIR\mods\$ModBase.disabled\*.*"
        ClearErrors
        Rename "$INSTDIR\mods\$ModBase" "$INSTDIR\mods\$ModBase.disabled"
        ${If} ${Errors}
          StrCpy $ApplyErrors "$ApplyErrors$ModBase (folder); "
        ${EndIf}
      ${EndIf}
    ${EndIf}
  ${EndIf}

  ${If} $ApplyErrors != ""
    Push "Mod change problem: $ApplyErrors"
    Call LogWrite
  ${EndIf}
FunctionEnd

Function ApplyModChanges
  ${If} $ModsAction != ""
    Call ScanMods
    ${If} $ModCount == 0
      Return
    ${EndIf}
    StrCpy $R0 1
    ${Do}
      ${If} $R0 > $ModCount
        ${ExitDo}
      ${EndIf}
      ReadINIStr $R1 "$ModsIni" "order" "$R0"
      ${If} $ModsAction == "enable"
        StrCpy $ModAction "enable"
      ${Else}
        StrCpy $ModAction "disable"
      ${EndIf}
      StrCpy $ModBase "$R1"
      Call ApplyModState
      IntOp $R0 $R0 + 1
    ${Loop}
    Return
  ${EndIf}

  ${IfNot} ${FileExists} "$ModsIni"
    Return
  ${EndIf}

  StrCpy $R0 1
  ${Do}
    ${If} $R0 > $ModCount
      ${ExitDo}
    ${EndIf}
    ReadINIStr $R1 "$ModsIni" "order" "$R0"
    ReadINIStr $R2 "$ModsIni" "mods" "$R1"
    ${If} $R2 == "on"
      StrCpy $ModAction "enable"
    ${Else}
      StrCpy $ModAction "disable"
    ${EndIf}
    StrCpy $ModBase "$R1"
    Call ApplyModState
    IntOp $R0 $R0 + 1
  ${Loop}
FunctionEnd

;-------------------------------------------------------------------------------
; Installer initialization
;-------------------------------------------------------------------------------

Function .onInit
  !insertmacro MUI_LANGDLL_DISPLAY

  SetRegView 32
!ifdef TEST_BUILD
  SetShellVarContext current
!else
  SetShellVarContext all
!endif

  StrCpy $DetectedPath ""
  StrCpy $DetectedSource ""
  StrCpy $DetectedSourceId "none"
  StrCpy $TryPath ""
  StrCpy $TrySource ""
  StrCpy $TryFound 0
  StrCpy $JavaExe ""
  StrCpy $JavaSource ""
  StrCpy $JavaVersion ""
  StrCpy $JavaDisplay ""
  StrCpy $PatchState "missing"
  StrCpy $PatchResult ""
  StrCpy $ClientStatus ""
  StrCpy $StatusNote ""
  StrCpy $StatusSeen 0
  StrCpy $RestoreClient 0
  StrCpy $SkipPatch 0
  StrCpy $WriteLog 1
  StrCpy $LogPath ""
  StrCpy $FinishDetails ""
  StrCpy $ModsIni "$TEMP\WurmModloaderMods.ini"
  StrCpy $ModCount 0
  StrCpy $ModsOn 0
  StrCpy $ModsOff 0
  StrCpy $ModAction ""
  StrCpy $ModBase ""
  StrCpy $ModsAction ""
  StrCpy $ApplyErrors ""
  StrCpy $InstallSizeKb 0
  StrCpy $DeleteMods 0
  StrCpy $OptSkipPatch 0
  StrCpy $OptNoRestore 0

  ${GetParameters} $R0
  ${If} $R0 != ""
    ${GetOptions} $R0 "/LOG=" $R1
    ${If} $R1 != ""
      StrCpy $LogPath "$R1"
    ${EndIf}

    ${StrStr} $R1 "$R0" "/NOLOG"
    ${If} $R1 != ""
      StrCpy $LogPath ""
      StrCpy $WriteLog 0
    ${EndIf}

    ${StrStr} $R1 "$R0" "/NOPATCH"
    ${If} $R1 != ""
      StrCpy $OptSkipPatch 1
    ${EndIf}

    ${StrStr} $R1 "$R0" "/NORESTORE"
    ${If} $R1 != ""
      StrCpy $OptNoRestore 1
    ${EndIf}

    ${StrStr} $R1 "$R0" "/DISABLEMODS"
    ${If} $R1 != ""
      StrCpy $ModsAction "disable"
    ${EndIf}

    ${StrStr} $R1 "$R0" "/ENABLEMODS"
    ${If} $R1 != ""
      StrCpy $ModsAction "enable"
    ${EndIf}

    ${StrStr} $R1 "$R0" "/NOMODS"
    ${If} $R1 != ""
      SectionSetFlags ${SEC_MODSFOLDER} 0
    ${EndIf}

    ${StrStr} $R1 "$R0" "/NOSTARTMENU"
    ${If} $R1 != ""
      SectionSetFlags ${SEC_SM} 0
    ${EndIf}

    ${StrStr} $R1 "$R0" "/DESKTOP"
    ${If} $R1 != ""
      SectionSetFlags ${SEC_DESK} ${SF_SELECTED}
    ${EndIf}

    ${StrStr} $R1 "$R0" "/NODESKTOP"
    ${If} $R1 != ""
      SectionSetFlags ${SEC_DESK} 0
    ${EndIf}

    ${StrStr} $R1 "$R0" "/HELP"
    ${If} $R1 != ""
      IfSilent help_quit
      MessageBox MB_OK "Wurm Unlimited Client Modloader ${APP_VERSION}$\r$\n$\r$\nUsage: setup.exe /S /D=<WurmLauncher folder> [options]$\r$\n$\r$\nOptions:$\r$\n  /NOPATCH      Do not patch client.jar$\r$\n  /NORESTORE    Do not restore client.jar first$\r$\n  /NOMODS       Do not install the mods layout guide$\r$\n  /NOSTARTMENU  No Start Menu shortcuts$\r$\n  /DESKTOP      Create a desktop shortcut$\r$\n  /NODESKTOP    No desktop shortcut$\r$\n  /DISABLEMODS  Disable all existing mods$\r$\n  /ENABLEMODS   Enable all existing mods$\r$\n  /LOG=<file>   Write an installation log to <file>$\r$\n  /NOLOG        Do not write a log file$\r$\n  /HELP         Show this help"
      help_quit:
      Quit
    ${EndIf}
  ${EndIf}

  ; /D takes priority; otherwise try to find Wurm Unlimited
  ${If} $INSTDIR != "${DEFAULT_INSTDIR}"
    StrCpy $DetectedPath "$INSTDIR"
    StrCpy $DetectedSourceId "command"
  ${Else}
    Call DetectWurm
    ${If} $DetectedPath != ""
      StrCpy $INSTDIR "$DetectedPath"
    ${EndIf}
  ${EndIf}

  ${If} $LogPath == ""
  ${AndIf} $WriteLog == 1
    StrCpy $LogPath "$INSTDIR\modloader-install.log"
  ${EndIf}

  IfSilent 0 oninit_done
  ${IfNot} ${FileExists} "$INSTDIR\client.jar"
    SetErrorLevel 2
    Quit
  ${EndIf}
  oninit_done:
FunctionEnd

;-------------------------------------------------------------------------------
; Uninstaller
;-------------------------------------------------------------------------------

Function un.GetSizeOf
  Exch $0
  Push $1
  Push $2
  StrCpy $2 -1
  ClearErrors
  FileOpen $1 "$0" r
  IfErrors ugs_done
  FileSeek $1 0 END $2
  FileClose $1
  ugs_done:
  StrCpy $0 $2
  Pop $2
  Pop $1
  Exch $0
FunctionEnd

Function un.DetectClientState
  ${IfNot} ${FileExists} "$INSTDIR\client.jar"
    StrCpy $PatchState "missing"
    Return
  ${EndIf}

  Push "$INSTDIR\client.jar"
  Call un.GetSizeOf
  Pop $0

  ${If} ${FileExists} "$INSTDIR\client-patched.jar"
    ${If} $0 > 0
    ${AndIf} $0 < 1048576
      StrCpy $PatchState "patched"
    ${Else}
      StrCpy $PatchState "backup-stale"
    ${EndIf}
  ${Else}
    ${If} $0 > 0
    ${AndIf} $0 < 1048576
      StrCpy $PatchState "patched-nobackup"
    ${Else}
      StrCpy $PatchState "original"
    ${EndIf}
  ${EndIf}
FunctionEnd

Function un.RestoreClientJar
  DetailPrint "$(DP_RESTORE)"
  Delete "$INSTDIR\client.jar.tmp"
  ClearErrors
  CopyFiles /SILENT "$INSTDIR\client-patched.jar" "$INSTDIR\client.jar.tmp"
  ${If} ${Errors}
    DetailPrint "$(DP_ERR_COPY)"
    Return
  ${EndIf}
  Delete "$INSTDIR\client.jar"
  ClearErrors
  Rename "$INSTDIR\client.jar.tmp" "$INSTDIR\client.jar"
  ${If} ${Errors}
    DetailPrint "$(DP_ERR_REPLACE)"
    Return
  ${EndIf}
  Delete "$INSTDIR\client-patched.jar"
  DetailPrint "$(DP_RESTORED)"
FunctionEnd

Function un.WelcomeShow
  StrLen $0 "$INSTDIR"
  ${If} $0 > 48
    IntOp $0 $0 - 45
    StrCpy $1 "$INSTDIR" "" $0
    StrCpy $R0 "...$1"
  ${Else}
    StrCpy $R0 "$INSTDIR"
  ${EndIf}
  ${NSD_SetText} $mui.WelcomePage.Text "$(UNW_TEXT)$\r$\n$\r$\n$R0$\r$\n$\r$\n$(UNW_TEXT2)"
FunctionEnd

Function un.RestorePageShow
  !insertmacro MUI_HEADER_TEXT "$(UN_TITLE)" "$(UN_SUB)"

  Call un.DetectClientState

  ${If} $PatchState == "patched"
    StrCpy $0 "$(UN_NOTE_PATCHED)"
  ${ElseIf} $PatchState == "patched-nobackup"
    StrCpy $0 "$(UN_NOTE_NOBACKUP)"
  ${ElseIf} $PatchState == "original"
    StrCpy $0 "$(UN_NOTE_ORIGINAL)"
  ${Else}
    StrCpy $0 "$(UN_NOTE_MISSING)"
  ${EndIf}

  nsDialogs::Create 1018
  Pop $hUnDialog
  ${If} $hUnDialog == error
    Abort
  ${EndIf}

  ${NSD_CreateLabel} 0 0 100% 26u "$0"
  Pop $0

  ${NSD_CreateCheckBox} 0 32u 100% 10u "$(UN_CHK_RESTORE)"
  Pop $hUnChkRestore
  ${If} $PatchState == "patched"
    ${NSD_Check} $hUnChkRestore
  ${Else}
    EnableWindow $hUnChkRestore 0
  ${EndIf}

  ${NSD_CreateCheckBox} 0 44u 100% 10u "$(UN_CHK_DELETE)"
  Pop $hUnChkDeleteMods
  ${IfNot} ${FileExists} "$INSTDIR\mods\*.*"
    EnableWindow $hUnChkDeleteMods 0
  ${EndIf}

  ${NSD_CreateLabel} 0 58u 100% 30u "$(UN_NOTE)"
  Pop $0

  nsDialogs::Show
FunctionEnd

Function un.RestorePageLeave
  ${NSD_GetState} $hUnChkRestore $0
  ${If} $0 == ${BST_CHECKED}
    StrCpy $RestoreClient 1
  ${Else}
    StrCpy $RestoreClient 0
  ${EndIf}

  ${NSD_GetState} $hUnChkDeleteMods $0
  ${If} $0 == ${BST_CHECKED}
    StrCpy $DeleteMods 1
  ${Else}
    StrCpy $DeleteMods 0
  ${EndIf}

  ${If} $DeleteMods == 1
    MessageBox MB_YESNO|MB_ICONEXCLAMATION "$(MSG_DELETE_MODS)" IDYES upl_mods_ok
    Abort
    upl_mods_ok:
  ${EndIf}

  ${If} $RestoreClient == 0
  ${AndIf} $PatchState == "patched"
    MessageBox MB_YESNO|MB_ICONEXCLAMATION "$(MSG_NO_RESTORE)" IDYES upl_restore_ok
    Abort
    upl_restore_ok:
  ${EndIf}
FunctionEnd

Function un.onInit
  !insertmacro MUI_UNGETLANGUAGE

  SetRegView 32
!ifdef TEST_BUILD
  SetShellVarContext current
!else
  SetShellVarContext all
!endif

  ReadRegStr $0 SHCTX "${REG_BASE}" "InstallDir"
  ${If} $0 != ""
  ${AndIf} ${FileExists} "$0\client.jar"
    StrCpy $INSTDIR "$0"
  ${EndIf}

  StrCpy $DeleteMods 0
  StrCpy $RestoreClient 0
  Call un.DetectClientState
  ${If} $PatchState == "patched"
    StrCpy $RestoreClient 1
  ${EndIf}
FunctionEnd

;-------------------------------------------------------------------------------
; Section descriptions
;-------------------------------------------------------------------------------

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_CORE} "$(SEC_CORE_DESC)"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_MODSFOLDER} "$(SEC_MODS_DESC)"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_SM} "$(SEC_SM_DESC)"
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC_DESK} "$(SEC_DESK_DESC)"
!insertmacro MUI_FUNCTION_DESCRIPTION_END
