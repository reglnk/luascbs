#ifndef LUASCBS_PLATFORM_H
#define LUASCBS_PLATFORM_H

/* detect host OS */
#ifdef __GNUC__
#  if defined(__WIN32__)
#    define LUASCBS_SOURCE_OS "win32"
#  elif defined(__linux__)
#    define LUASCBS_SOURCE_OS "linux"
#  elif defined(__unix__)
#    define LUASCBS_SOURCE_OS "unix"
#  elif defined(__FreeBSD__)
#    define LUASCBS_SOURCE_OS "freebsd"
#  elif defined(__APPLE__)
#    define LUASCBS_SOURCE_OS "apple"
#  else
#    error Failed to detect host OS
#  endif
#elif defined(_MSC_VER)
#    define LUASCBS_SOURCE_OS "win32"
#endif

/* detect host architecture */
#ifdef __GNUC__
#  if defined(__i386__)
#    define LUASCBS_SOURCE_ARCH "i386"
#  elif defined(__x86_64__)
#    define LUASCBS_SOURCE_ARCH "x86_64"
#  elif defined(__aarch64__)
#    define LUASCBS_SOURCE_ARCH "aarch64"
#  elif defined(__arm__)
#    if __ARM_ARCH == 7
#      if __ARM_ARCH_PROFILE == 'A'
#        define LUASCBS_SOURCE_ARCH "armv7a"
#      elif __ARM_ARCH_PROFILE == 'R'
#        define LUASCBS_SOURCE_ARCH "armv7r"
#      elif __ARM_ARCH_PROFILE == 'M'
#        define LUASCBS_SOURCE_ARCH "armv7m"
#      else
#        define LUASCBS_SOURCE_ARCH "armv7"
#      endif
#    elif __ARM_ARCH == 6
#      if __ARM_ARCH_PROFILE == 'M'
#        define LUASCBS_SOURCE_ARCH "armv6m"
#      else
#        define LUASCBS_SOURCE_ARCH "armv6"
#      endif
#    else
#      error Unknown ARM architecture
#    endif
#  else
#    error Failed to detect host architecture
#  endif
#elif defined(_MSC_VER)
#  if defined(_M_IX86)
#    define LUASCBS_SOURCE_ARCH "i386"
#  elif defined(_M_AMD64)
#    define LUASCBS_SOURCE_ARCH "x86_64"
#  elif defined(_M_ARM)
#    define LUASCBS_SOURCE_ARCH "armv7"
#  elif defined(_M_ARM64)
#    define LUASCBS_SOURCE_ARCH "aarch64"
#  endif
#else
#  error Unknown compiler
#endif

#endif