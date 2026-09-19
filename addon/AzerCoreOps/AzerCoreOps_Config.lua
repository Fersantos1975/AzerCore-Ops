-- AzerCore Ops configuration defaults
-- Loaded before the main addon so settings and migrations have one owner.
AzerCoreOpsConfig = AzerCoreOpsConfig or {}
AzerCoreOpsConfig.Schema = 1
AzerCoreOpsConfig.Build = "0.7.5f"
AzerCoreOpsConfig.Defaults = {
  startMinimized=true,showMinimap=true,showMini=true,mbfCompatibility=true,scale=1,roleMode="AUTOMATIC",
  characterRaid="ICC",characterRaidDifficulty="10N",characterRaidLocked=true,
  confirmCommands=true,hideAuditChat=true,defaultDifficulty=0,
  auditTooltips=true,wrapAuditReasons=true,mouseWheelAudit=true,problemsFirst=false,
  rememberAuditFilter=true,autoReaudit=false,confirmResetSelected=true,
  warnNoTarget=true,compactAuditRows=false,auditFontSize=10,shiftClickInsert=true,

  showTooltips=true,
  instanceRecordingMode="MANUAL",
  recordingDetailLevel="STANDARD",
  recordingCustomBoss=true,
  recordingCustomPhases=true,
  recordingCustomObjects=true,
  recordingCustomLifecycle=true,
  recordingCustomTrash=false,
  recordingCustomSpells=false,
  recordingCustomAuras=false,
  recordingShareExportFull=true,
  recordingSelectableExport=true,
  recordingStatusButton=true,
  recordingStatusLocked=false,
  recordingStatusShowElapsed=true,
  recordingStatusX=360,
  recordingStatusY=40,
  recordingResumeSameInstance=true,
  recordingContinueWhileAway=true,
  recordingFinalizeOnComplete=true,
  recordingLifecycleEvents=true,
  recordingNotifications=true,
  recordingOpenCompleted=false,
  recordingRetention=10,
  recordingSettingsX=0,
  recordingSettingsY=0,
}
