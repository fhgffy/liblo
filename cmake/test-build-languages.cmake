cmake_minimum_required(VERSION 3.5)

# Run with cmake -P from a directory where build-language-tests can be created,
# or pass -DTEST_BINARY_DIR=/path/to/an/unused/directory before -P.
if(NOT DEFINED TEST_BINARY_DIR)
  set(TEST_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}/build-language-tests")
endif()
get_filename_component(TEST_BINARY_DIR "${TEST_BINARY_DIR}" ABSOLUTE)
if(EXISTS "${TEST_BINARY_DIR}")
  message(FATAL_ERROR "Use an unused TEST_BINARY_DIR: ${TEST_BINARY_DIR}")
endif()

function(check_build_languages name needs_cxx)
  set(build_dir "${TEST_BINARY_DIR}/${name}")
  set(compiler_option)
  if(NOT needs_cxx)
    set(compiler_option
      "-DCMAKE_CXX_COMPILER=${TEST_BINARY_DIR}/unavailable-cxx-compiler")
  endif()
  execute_process(
    COMMAND "${CMAKE_COMMAND}" "${CMAKE_CURRENT_LIST_DIR}"
      ${compiler_option} ${ARGN}
    WORKING_DIRECTORY "${build_dir}"
    RESULT_VARIABLE result
    OUTPUT_VARIABLE output
    ERROR_VARIABLE error)
  file(WRITE "${build_dir}/configure.log" "${output}${error}")
  if(NOT result EQUAL 0)
    message(FATAL_ERROR "${name} failed to configure:\n${output}${error}")
  endif()
  file(GLOB cxx_files "${build_dir}/CMakeFiles/*/CMakeCXXCompiler.cmake")
  if(needs_cxx AND NOT cxx_files)
    message(FATAL_ERROR "${name} did not enable the required CXX language")
  elseif(NOT needs_cxx AND cxx_files)
    message(FATAL_ERROR "${name} enabled an unnecessary CXX language")
  endif()
  message(STATUS "${name}: expected build languages enabled")
endfunction()

foreach(name tests-disabled cpp-tests-disabled all-tests-disabled
    cpp-tests-enabled cxx-library cxx-library-without-cpp-tests)
  file(MAKE_DIRECTORY "${TEST_BINARY_DIR}/${name}")
endforeach()

check_build_languages(tests-disabled FALSE -DWITH_TESTS=OFF)
check_build_languages(cpp-tests-disabled FALSE -DWITH_CPP_TESTS=OFF)
check_build_languages(all-tests-disabled FALSE
  -DWITH_TESTS=OFF -DWITH_CPP_TESTS=OFF)
check_build_languages(cpp-tests-enabled TRUE)
check_build_languages(cxx-library TRUE -DWITH_TESTS=OFF -DBUILD_LANGUAGE=CXX)
check_build_languages(cxx-library-without-cpp-tests TRUE
  -DWITH_TESTS=OFF -DWITH_CPP_TESTS=OFF -DBUILD_LANGUAGE=CXX)
