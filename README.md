# update-aidl-hal-interfaces-without-adding-new-version
When you edit existing AIDL HAL interfaces, this shell script can help you keep AIDL version number unchanged (bypassing AOSP update/freeze logic).

## AIDL HAL Version Problem
Due to introduction of stable AIDL HAL from Android10, everytime you modify a frozen AIDL interface,

you come across below error during compilation:

``` txt
###############################################################################
# ERROR: Modification detected of stable AIDL API file                        #
###############################################################################
Above AIDL file(s) has changed, resulting in a different hash. Hash values may
be checked at runtime to verify interface stability. If a device is shipped
with this change by ignoring this message, it has a high risk of breaking later
when a module using the interface is updated, e.g., Mainline modules.
```

While AOSP provides `m <package>-update-api` command to unfreeze AIDL interface,

and `m <package>-freeze-api` command to re-freeze AIDL interface after changes are made,

these commands automatically increase AIDL HAL version by 1.0, and

corresponding directory named by the new version number is created.


This is troublesome especially we want to develop a vendor AIDL HAL service, or extend

an existing AOSP AIDL HAL. Because what you've just added to your HAL can only be accessed with

the new version HAL interface, all the client processes have to change their reference HAL version, too.

On the other hand, leaving redundant HAL versions in native directory only brings chaos and confusion.

## Bypass HAL Version Increment
AOSP build tool relies on hash values to determine whether a stable AIDL HAL interface is changed.

If we calculate hash value for the modified AIDL HAL interface, then replace the cached value,

we can cheat AOSP build tool to make it think nothing is changed. As a result, error compilation is gone,

redundant AIDL HAL versions are gone.

## Usage
Put script `update_aidl_hal_apis.sh` under `hardware/interfaces/<packageName>/aidl/`,

where the `<packageName>` is path to the AIDL HAL you want to update, e.g. `hardware/interfaces/automotive/audiocontrol/aidl/`.

Then simply run the script and follow its prompts to choose target HAL, and wait until script tell you work is done.

