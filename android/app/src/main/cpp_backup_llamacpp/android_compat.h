#ifndef ANDROID_COMPAT_H
#define ANDROID_COMPAT_H

#include <stddef.h>    // For size_t
#include <sys/types.h> // For additional types

#ifdef __cplusplus
extern "C" {
#endif

// Stub implementation for posix_madvise which is missing in Android NDK
int android_posix_madvise_stub(void* addr, size_t len, int advice);

#ifdef __cplusplus
}
#endif

#endif // ANDROID_COMPAT_H


