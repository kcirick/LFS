#!/bin/bash

echo "Linking /usr/lib/libnssckbi.so ..."
ln -sfv ./pkcs11/p11-kit-trust.so /usr/lib/libnssckbi.so

