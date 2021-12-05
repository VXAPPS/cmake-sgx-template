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

project(Cxx14SGXDemo_Enclave)

include_directories(${CMAKE_CURRENT_BINARY_DIR} ${SGX_INCLUDE_DIR} ${SGX_TLIBC_INCLUDE_DIR} ${SGX_LIBCXX_INCLUDE_DIR})

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ENCLAVE_CXX_FLAGS}")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${ENCLAVE_C_FLAGS}")

add_library(${PROJECT_NAME} SHARED
  Enclave.cpp
  Enclave.h
  Enclave.lds
  Enclave_debug.lds
  Enclave.config.xml
  TrustedLibrary/Libcxx.cpp
  TrustedLibrary/Libcxx.edl
)

set(EDL_FILES Enclave.edl)
generate_trusted_edl(${PROJECT_NAME} ${EDL_FILES})

target_link_libraries(${PROJECT_NAME} "${SGX_COMMON_CFLAGS} ${ENCLAVE_SECURITY_FLAGS} \
            -Wl,--no-undefined -nostdlib -nodefaultlibs -nostartfiles -L${SGX_LIBRARY_PATH} \
            -Wl,--whole-archive -l${SGX_TRTS_LIB} -Wl,--no-whole-archive \
            -Wl,--start-group ${TLIB_LIST} -l${SGX_STDC_LIB} -l${SGX_CXX_LIB} -l${SGX_KEY_EXCHANGE_LIB} -l${SGX_CRYPTO_LIB} -l${SGX_THREAD_LIB} -l${SGX_TSVC_LIB} -Wl,--end-group \
            -Wl,-Bstatic -Wl,-Bsymbolic -Wl,--no-undefined \
            -Wl,-pie,-eenclave_entry -Wl,--export-dynamic \
            -Wl,--version-script=${CMAKE_CURRENT_SOURCE_DIR}/Enclave_debug.lds \
            -Wl,--defsym,__ImageBase=0")

enclave_sign(${PROJECT_NAME} KEY Enclave_private_test.pem CONFIG Enclave.config.xml)
