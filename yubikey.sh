#!/bin/bash

# reset yubikey
ykman fido reset
ykman otp delete 1
ykman otp delete 2
ykman piv reset
ykman oath reset
ykman openpgp reset
ykman config usb --disable otp
