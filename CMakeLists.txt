set(AZERCORE_OPS_MODULE_VERSION "0.5.3")
set(AZERCORE_OPS_RELEASE_CHANNEL "character-raid-catalog")
set(AZERCORE_OPS_CAPABILITIES "BUILD_INFO,INSTANCE_SEARCH,INSTANCE_AUDIT,INSTANCE_STRUCTURED_BINDS,INSTANCE_ENCOUNTER_PROGRESS,INSTANCE_BATCH_UNBIND,QUEST_SEARCH,QUEST_INFO,QUEST_GROUP_AUDIT,QUEST_TARGET_LOG,CHARACTER_INSPECT,CHARACTER_INVENTORY,CHARACTER_PROFESSIONS,CHARACTER_RAID_EXPERIENCE,CHARACTER_RAID_CATALOG,CHARACTER_TECHNICAL,CHARACTER_SAVE_TARGET,ROLE_PERMISSIONS,REPORT_EXPORT,DESIGN_SYSTEM,MOVEMENT_WORKSPACE,OPERATIONS_WORKFLOW")
set(AZERCORE_OPS_PROTOCOL_VERSION "1")

function(azercoreops_git_revision directory output_hash output_dirty)
    execute_process(
        COMMAND git -C "${directory}" rev-parse --short=9 HEAD
        OUTPUT_VARIABLE revision
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
        RESULT_VARIABLE revision_result)
    if(NOT revision_result EQUAL 0 OR revision STREQUAL "")
        set(revision "unknown")
    endif()

    execute_process(
        COMMAND git -C "${directory}" status --porcelain
        OUTPUT_VARIABLE changes
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
        RESULT_VARIABLE status_result)
    if(status_result EQUAL 0 AND NOT changes STREQUAL "")
        set(dirty "yes")
    elseif(status_result EQUAL 0)
        set(dirty "no")
    else()
        set(dirty "unknown")
    endif()

    set(${output_hash} "${revision}" PARENT_SCOPE)
    set(${output_dirty} "${dirty}" PARENT_SCOPE)
endfunction()

azercoreops_git_revision("${CMAKE_CURRENT_LIST_DIR}" AZERCORE_OPS_MODULE_GIT_HASH AZERCORE_OPS_MODULE_GIT_DIRTY)
azercoreops_git_revision("${CMAKE_SOURCE_DIR}" AZERCORE_OPS_CORE_GIT_HASH AZERCORE_OPS_CORE_GIT_DIRTY)
azercoreops_git_revision("${CMAKE_SOURCE_DIR}/modules/mod-playerbots" AZERCORE_OPS_PLAYERBOTS_GIT_HASH AZERCORE_OPS_PLAYERBOTS_GIT_DIRTY)

configure_file(
    "${CMAKE_CURRENT_LIST_DIR}/src/azercoreops_build_info.h.in"
    "${CMAKE_BINARY_DIR}/modules/mod-azercore-ops/azercoreops_build_info.generated.h"
    @ONLY)

AC_ADD_SCRIPT("${CMAKE_CURRENT_LIST_DIR}/src")
