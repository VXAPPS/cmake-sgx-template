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

set(WARNING_FLAGS

  # Own parameter
  -Wno-c++98-compat # C++11
  -Wno-c++98-compat-pedantic # C++11
  -Wno-padded

  # intel sgx
  -Wno-reserved-id-macro

  # intel sgx stdlib
  -Wno-extra-semi

  # intel sgx stdcxx
  -Wno-implicit-exception-spec-mismatch
  -Wno-zero-as-null-pointer-constant
  -Wno-sign-conversion

  # intel sgx sgx_defs.h
  -Wno-variadic-macros

  # intel sgx generated trusted
  -Wno-unused-macros
  -Wno-missing-variable-declarations

  -Wno-missing-prototypes
  -Wno-format-nonliteral
)

set(WARNING_FLAGS_VERSION12

  # macOS cppunit include path from brew
  -Wno-poison-system-directories
)

set(WARNING_FLAGS_VERSION13

  # cppunit
  -Wno-reserved-identifier
)
