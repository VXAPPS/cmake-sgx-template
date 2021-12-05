/*
 * Copyright (C) 2011-2021 Intel Corporation. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *   * Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in
 *     the documentation and/or other materials provided with the
 *     distribution.
 *   * Neither the name of Intel Corporation nor the names of its
 *     contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 */

/* c header */
#include <cassert>
#include <cstdio>
#include <cstring>

/* system header */
# include <pwd.h>
# include <unistd.h>

/* sgx header */
#include <sgx_urts.h>

/* stl header */
#include <iostream>

/* local header */
#include "App.h"
#include "Enclave_u.h"

/* Global EID shared by multiple threads */
sgx_enclave_id_t global_eid = 0;

typedef struct _sgx_errlist_t {
  sgx_status_t err;
  const char *msg;
  const char *sug; /* Suggestion */
} sgx_errlist_t;

/* Error code returned by sgx_create_enclave */
static sgx_errlist_t sgx_errlist[] = {
  {
    SGX_ERROR_UNEXPECTED,
    "Unexpected error occurred.",
    nullptr
  },
  {
    SGX_ERROR_INVALID_PARAMETER,
    "Invalid parameter.",
    nullptr
  },
  {
    SGX_ERROR_OUT_OF_MEMORY,
    "Out of memory.",
    nullptr
  },
  {
    SGX_ERROR_ENCLAVE_LOST,
    "Power transition occurred.",
    "Please refer to the sample \"PowerTransition\" for details."
  },
  {
    SGX_ERROR_INVALID_ENCLAVE,
    "Invalid enclave image.",
    nullptr
  },
  {
    SGX_ERROR_INVALID_ENCLAVE_ID,
    "Invalid enclave identification.",
    nullptr
  },
  {
    SGX_ERROR_INVALID_SIGNATURE,
    "Invalid enclave signature.",
    nullptr
  },
  {
    SGX_ERROR_OUT_OF_EPC,
    "Out of EPC memory.",
    nullptr
  },
  {
    SGX_ERROR_NO_DEVICE,
    "Invalid SGX device.",
    "Please make sure SGX module is enabled in the BIOS, and install SGX driver afterwards."
  },
  {
    SGX_ERROR_MEMORY_MAP_CONFLICT,
    "Memory map conflicted.",
    nullptr
  },
  {
    SGX_ERROR_INVALID_METADATA,
    "Invalid enclave metadata.",
    nullptr
  },
  {
    SGX_ERROR_DEVICE_BUSY,
    "SGX device was busy.",
    nullptr
  },
  {
    SGX_ERROR_INVALID_VERSION,
    "Enclave version was invalid.",
    nullptr
  },
  {
    SGX_ERROR_INVALID_ATTRIBUTE,
    "Enclave was not authorized.",
    nullptr
  },
  {
    SGX_ERROR_ENCLAVE_FILE_ACCESS,
    "Can't open enclave file.",
    nullptr
  },
  {
    SGX_ERROR_NDEBUG_ENCLAVE,
    "The enclave is signed as product enclave, and can not be created as debuggable enclave.",
    nullptr
  },
};

/* Check error conditions for loading enclave */
void print_error_message( sgx_status_t ret ) {

  std::size_t idx = 0;
  std::size_t ttl = sizeof sgx_errlist / sizeof sgx_errlist[0];

  for ( idx = 0; idx < ttl; idx++ ) {

    if ( ret == sgx_errlist[idx].err ) {

      if ( nullptr != sgx_errlist[idx].sug ) {

        std::cout << "Info: " << sgx_errlist[idx].sug << std::endl;
      }
      std::cout << "Error: " << sgx_errlist[idx].sug << std::endl;
      break;
    }
  }

  if ( idx == ttl ) {

    std::cout << "Error: Unexpected error occurred." << std::endl;
  }
}

/* Initialize the enclave:
 *   Call sgx_create_enclave to initialize an enclave instance
 */
bool initialize_enclave() {

  sgx_status_t ret = SGX_ERROR_UNEXPECTED;

  /* Call sgx_create_enclave to initialize an enclave instance */
  /* Debug Support: set 2nd parameter to 1 */
  ret = sgx_create_enclave( ENCLAVE_FILENAME, SGX_DEBUG_FLAG, nullptr, nullptr, &global_eid, nullptr );
  if ( ret != SGX_SUCCESS ) {

    print_error_message( ret );
  }
  return ret != SGX_SUCCESS;
}

/* OCall functions */
void ocall_print_string( const char *str ) {

  /* Proxy/Bridge will check the length and null-terminate
   * the input string to prevent buffer overflow.
   */
  std::cout << str;
}

/* Application entry */
int main() {

  /* Initialize the enclave */
  if ( initialize_enclave() ) {

    return EXIT_FAILURE;
  }

  /* Utilize trusted libraries */
  ecall_libcxx_functions();

  /* Destroy the enclave */
  sgx_destroy_enclave( global_eid );

  std::cout << "Info: Cxx14DemoEnclave successfully returned." << std::endl;

  return EXIT_SUCCESS;
}
