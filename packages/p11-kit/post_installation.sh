#!/bin/bash

ln -sfv /usr/libexec/p11-kit/trust-extract-compat /usr/bin/update-ca-certificates

ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so
