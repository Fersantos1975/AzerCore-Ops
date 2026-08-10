# AzerothCore loads this hook by matching it to the canonical directory name.
# It runs after AzerothCore creates the static/dynamic module targets.
# It exposes the generated build-info header and the active CMake configuration.
set(AZERCORE_OPS_GENERATED_INCLUDE_DIR "${CMAKE_BINARY_DIR}/modules/mod-azercore-ops")

if(TARGET modules)
    target_include_directories(modules PRIVATE "${AZERCORE_OPS_GENERATED_INCLUDE_DIR}")
    target_compile_definitions(modules PRIVATE AZERCORE_OPS_BUILD_TYPE="$<CONFIG>")
endif()

if(TARGET mod_mod-azercore-ops)
    target_include_directories(mod_mod-azercore-ops PRIVATE "${AZERCORE_OPS_GENERATED_INCLUDE_DIR}")
    target_compile_definitions(mod_mod-azercore-ops PRIVATE AZERCORE_OPS_BUILD_TYPE="$<CONFIG>")
endif()
