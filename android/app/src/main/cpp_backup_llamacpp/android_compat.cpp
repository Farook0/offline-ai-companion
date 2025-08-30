// Android compatibility layer for llama.cpp
#include <sys/types.h>
#include "android_compat.h"

// Stub implementation for posix_madvise which is missing in Android NDK
int android_posix_madvise_stub(void* addr, size_t len, int advice) {
    // Android doesn't support posix_madvise, so we just return success
    // This is safe because it's only an optimization hint
    (void)addr;   // Suppress unused parameter warning
    (void)len;    // Suppress unused parameter warning
    (void)advice; // Suppress unused parameter warning
    return 0;
}
