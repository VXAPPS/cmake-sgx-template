#
# Copyright (c) 2021 Florian Becker <fb@vxapps.com> (VX APPS).
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

# hard overwrite a sgx hw build
set(SGX_MODE "SW" CACHE STRING "Run SGX on hardware with HW, other for simulation.")

include(CMakeParseArguments)

set(SGX_FOUND "NO")

# Find intel sgx
if(EXISTS SGX_DIR)
    set(SGX_PATH ${SGX_DIR})
elseif(EXISTS SGX_ROOT)
    set(SGX_PATH ${SGX_DIR})
elseif(EXISTS $ENV{SGX_SDK})
    set(SGX_PATH $ENV{SGX_SDK})
elseif(EXISTS $ENV{SGX_DIR})
    set(SGX_PATH $ENV{SGX_DIR})
elseif(EXISTS $ENV{SGX_ROOT})
    set(SGX_PATH $ENV{SGX_ROOT})
else()
    set(SGX_PATH /opt/intel/sgxsdk)
endif()

# 32bit or 64bit usage
if(CMAKE_SIZEOF_VOID_P EQUAL 4)
    set(SGX_COMMON_CFLAGS -m32)
    set(SGX_LIBRARY_PATH ${SGX_PATH}/lib32)
    set(SGX_ENCLAVE_SIGNER ${SGX_PATH}/bin/x86/sgx_sign)
    set(SGX_EDGER8R ${SGX_PATH}/bin/x86/sgx_edger8r)
else()
    set(SGX_COMMON_CFLAGS -m64)
    set(SGX_LIBRARY_PATH ${SGX_PATH}/lib64)
    set(SGX_ENCLAVE_SIGNER ${SGX_PATH}/bin/x64/sgx_sign)
    set(SGX_EDGER8R ${SGX_PATH}/bin/x64/sgx_edger8r)
endif()

find_path(SGX_INCLUDE_DIR sgx.h "${SGX_PATH}/include" NO_DEFAULT_PATH)
find_path(SGX_LIBRARY_DIR libsgx_urts.so "${SGX_LIBRARY_PATH}" NO_DEFAULT_PATH)

if(SGX_INCLUDE_DIR AND SGX_LIBRARY_DIR)
    set(SGX_FOUND "YES")
    set(SGX_INCLUDE_DIR "${SGX_PATH}/include" CACHE PATH "Intel SGX include directory" FORCE)
    set(SGX_TLIBC_INCLUDE_DIR "${SGX_INCLUDE_DIR}/tlibc" CACHE PATH "Intel SGX tlibc include directory" FORCE)
    set(SGX_LIBCXX_INCLUDE_DIR "${SGX_INCLUDE_DIR}/libcxx" CACHE PATH "Intel SGX libcxx include directory" FORCE)
    set(SGX_INCLUDE_DIRS ${SGX_INCLUDE_DIR} ${SGX_TLIBC_INCLUDE_DIR} ${SGX_LIBCXX_INCLUDE_DIR})
    mark_as_advanced(SGX_INCLUDE_DIR SGX_TLIBC_INCLUDE_DIR SGX_LIBCXX_INCLUDE_DIR SGX_LIBRARY_DIR)
    message(STATUS "Found Intel SGX SDK.")
endif()

if(SGX_FOUND)

    if(SGX_MODE STREQUAL "HW")
        set(SGX_URTS_LIB sgx_urts)
        set(SGX_USVC_LIB sgx_uae_service)
        set(SGX_TRTS_LIB sgx_trts)
        set(SGX_TSVC_LIB sgx_tservice)
    else()
        set(SGX_URTS_LIB sgx_urts_sim)
        set(SGX_USVC_LIB sgx_uae_service_sim)
        set(SGX_TRTS_LIB sgx_trts_sim)
        set(SGX_TSVC_LIB sgx_tservice_sim)
    endif()
    set(SGX_CRYPTO_LIB sgx_tcrypto)
    set(SGX_STDC_LIB sgx_tstdc)
    set(SGX_CXX_LIB sgx_tcxx)
    set(SGX_KEY_EXCHANGE_LIB sgx_tkey_exchange)
    set(SGX_THREAD_LIB sgx_pthread)

    if(NOT ${SGX_SGXSSL_DIR} STREQUAL "" AND EXISTS ${SGX_SGXSSL_DIR}/lib64)
        set(SGX_SGXSSL_LIBRARY_PATH ${SGX_SGXSSL_DIR}/lib64)
        set(SGX_SGXSSL_INCLUDE_DIR ${SGX_SGXSSL_DIR}/include)
        message(STATUS "Using Intel SGXSSL from ${SGX_SGXSSL_DIR}")
    elseif(EXISTS /opt/intel/sgxssl)
        set(SGX_SGXSSL_LIBRARY_PATH /opt/intel/sgxssl/lib64)
        set(SGX_SGXSSL_INCLUDE_DIR /opt/intel/sgxssl/include)
        message(STATUS "Using Intel SGXSSL from /opt/intel/sgxssl")
    else()
        message(WARNING "Intel SGXSSL not found!")
    endif()

    set(ENCLAVE_INC_FLAGS "-I${SGX_INCLUDE_DIR} -I${SGX_TLIBC_INCLUDE_DIR} -I${SGX_LIBCXX_INCLUDE_DIR} -I${SGX_SGXSSL_INCLUDE_DIR}")
    set(ENCLAVE_C_FLAGS "${SGX_COMMON_CFLAGS} -nostdinc -fvisibility=hidden -fpie -fstack-protector-strong ${ENCLAVE_INC_FLAGS}")
    set(ENCLAVE_CXX_FLAGS "${ENCLAVE_C_FLAGS} -nostdinc++")

    set(APP_INC_FLAGS "-I${SGX_PATH}/include")
    set(APP_C_FLAGS "${SGX_COMMON_CFLAGS} -fPIC -Wno-attributes ${APP_INC_FLAGS}")
    set(APP_CXX_FLAGS "${APP_C_FLAGS}")

    function(generate_trusted_edl target files)
      foreach(EDL ${files})

        # Get path from edl and set as search path
        get_filename_component(EDL_DIR ${EDL} DIRECTORY)
        if(EDL_DIR)
          set(EDL_PATH ${CMAKE_CURRENT_SOURCE_DIR}/${EDL_DIR})
        else()
          set(EDL_PATH ${CMAKE_CURRENT_SOURCE_DIR})
        endif()

        # Get name from edl whatever
        get_filename_component(EDL_FILE ${EDL} NAME)

        # Get basename from edl whatever
        get_filename_component(EDL_BASE ${EDL} NAME_WLE)

        # Run edl foo for enclave - so trusted mode
        add_custom_command(OUTPUT ${EDL_BASE}_t.c ${EDL_BASE}_t.h
                           COMMAND ${SGX_EDGER8R} ${USE_PREFIX} --trusted ${EDL_FILE} --search-path ${EDL_PATH} --search-path ${SGX_INCLUDE_DIR}
                           WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                           DEPENDS ${EDL_PATH}/${EDL_FILE}
                           COMMENT "Generate trusted definitions..."
                           USES_TERMINAL)
      endforeach()

      target_sources(${target} PRIVATE
        ${files}
        ${CMAKE_CURRENT_BINARY_DIR}/${EDL_BASE}_t.c
        ${CMAKE_CURRENT_BINARY_DIR}/${EDL_BASE}_t.h
      )
    endfunction()

    function(generate_untrusted_edl target files)
      foreach(EDL ${files})

        # Get path from edl and set as search path
        get_filename_component(EDL_DIR ${EDL} DIRECTORY)
        if(EDL_DIR)
          set(EDL_PATH ${CMAKE_CURRENT_SOURCE_DIR}/${EDL_DIR})
        else()
          set(EDL_PATH ${CMAKE_CURRENT_SOURCE_DIR})
        endif()

        # Get name from edl whatever
        get_filename_component(EDL_FILE ${EDL} NAME)

        # Get basename from edl whatever
        get_filename_component(EDL_BASE ${EDL} NAME_WLE)

        # Run edl foo for enclave - so trusted mode
        add_custom_command(OUTPUT ${EDL_BASE}_u.c ${EDL_BASE}_u.h
                           COMMAND ${SGX_EDGER8R} ${USE_PREFIX} --untrusted ${EDL_FILE} --search-path ${EDL_PATH} --search-path ${SGX_INCLUDE_DIR}
                           WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
                           DEPENDS ${EDL_PATH}/${EDL_FILE}
                           COMMENT "Generate untrusted definitions..."
                           USES_TERMINAL)
      endforeach()

      target_sources(${target} PRIVATE
        ${files}
        ${CMAKE_CURRENT_BINARY_DIR}/${EDL_BASE}_u.c
        ${CMAKE_CURRENT_BINARY_DIR}/${EDL_BASE}_u.h
      )
    endfunction()

    set(ENCLAVE_SECURITY_FLAGS "-Wl,-z,relro,-z,now,-z,noexecstack")

    # sign the enclave, according to configurations one-step or two-step signing will be performed.
    # default one-step signing output enclave name is target.signed.so, change it with OUTPUT option.
    function(enclave_sign target)
        set(oneValueArgs KEY CONFIG OUTPUT)
        cmake_parse_arguments("SGX" "" "${oneValueArgs}" "" ${ARGN})
        if("${SGX_CONFIG}" STREQUAL "")
            message(FATAL_ERROR "${target}: SGX enclave config is not provided!")
        endif()
        if("${SGX_KEY}" STREQUAL "")
            if (NOT SGX_MODE STREQUAL "HW" OR NOT CMAKE_BUILD_TYPE STREQUAL "Release" AND NOT CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
                message(FATAL_ERROR "Private key used to sign enclave is not provided!")
            endif()
        else()
            get_filename_component(KEY_ABSPATH ${SGX_KEY} ABSOLUTE)
        endif()
        if("${SGX_OUTPUT}" STREQUAL "")
            set(OUTPUT_NAME "${target}.signed.so")
        else()
            set(OUTPUT_NAME ${SGX_OUTPUT})
        endif()

        get_filename_component(CONFIG_ABSPATH ${SGX_CONFIG} ABSOLUTE)

        if(SGX_MODE STREQUAL "HW" AND CMAKE_BUILD_TYPE STREQUAL "Release")
            add_custom_target(${target}-sign ALL
                              COMMAND ${SGX_ENCLAVE_SIGNER} gendata -config ${CONFIG_ABSPATH}
                                      -enclave $<TARGET_FILE:${target}> -out $<TARGET_FILE_DIR:${target}>/${target}_hash.hex
                              COMMAND ${CMAKE_COMMAND} -E cmake_echo_color
                                  --cyan "SGX production enclave first step signing finished, \
    use ${CMAKE_CURRENT_BINARY_DIR}/${target}_hash.hex for second step"
                              WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
        else()
            add_custom_target(${target}-sign ALL ${SGX_ENCLAVE_SIGNER} sign -key ${KEY_ABSPATH} -config ${CONFIG_ABSPATH}
                              -enclave $<TARGET_FILE:${target}> -out $<TARGET_FILE_DIR:${target}>/${OUTPUT_NAME}
                              WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
        endif()

        set(CLEAN_FILES "$<TARGET_FILE_DIR:${target}>/${OUTPUT_NAME};$<TARGET_FILE_DIR:${target}>/${target}_hash.hex")
        set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_MAKE_CLEAN_FILES "${CLEAN_FILES}")
    endfunction()

else(SGX_FOUND)
    message(WARNING "Intel SGX SDK not found!")
    if(SGX_FIND_REQUIRED)
        message(FATAL_ERROR "Could NOT find Intel SGX SDK!")
    endif()
endif(SGX_FOUND)
