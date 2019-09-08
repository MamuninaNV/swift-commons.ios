#ifndef __config_h__
#define __config_h__

/* Define it if we want to use libFoundation with GNUstep */
// #undef WITH_GNUSTEP

/* Define it if we want to use libFoundation with ffcall */
// #undef WITH_FFCALL

/* Define it if we use the Boehm's garbage collector */
// #undef WITH_GC

/* Macros that determine the Objective-C runtime and compiler */
#define NeXT_RUNTIME 1
// #undef GNU_RUNTIME

/* Define if the compiler does not support nested functions */
// #undef NO_NESTED_FUNCTIONS

/* Define if the compiler is broken when nested functions are used with
   Objective-C messages. */
// #undef BROKEN_COMPILER

/* Define if the __builtin_apply pseudo-function doesn't set the floating
   point return value at retframe + 8 on Intel machines. */
// #undef BROKEN_BUILTIN_APPLY

/* Define if system calls automatically restart after interruption
   by a signal.  */
// #undef HAVE_RESTARTABLE_SYSCALLS

/* Define if you have the vprintf function.  */
// #undef HAVE_VPRINTF

/* Define if you need to in order for stat and other things to work.  */
// #undef _POSIX_SOURCE

/* Define as the return type of signal handlers (int or void).  */
// #undef RETSIGTYPE

/* Define this if you have the sigsetmask function, eg the BSD signal
   handling. */
// #undef HAVE_SIGSETMASK

/* Define this if you have the sighold function, eg the System V signal
   handling. */
// #undef HAVE_SIGHOLD

/* Define if you have the sigset function. */
// #undef HAVE_SIGSET

/* Define if you have the sigaction function. */
// #undef HAVE_SIGACTION

/* Define if you have the gethostbyname_r function. */
// #undef HAVE_GETHOSTBYNAME_R

/* Define if you have the gethostbyaddr_r function. */
// #undef HAVE_GETHOSTBYADDR_R

/* Define if you have the gethostent_r function. */
// #undef HAVE_GETHOSTENT_R

/* Define if the Objective-C runtime contains the objc_thread_create function;
   this function was defined in the multi-thread support in the 960906
   version of runtime patch. */
// #undef HAVE_OBJC_THREAD_CREATE

/* Define if the Objective-C runtime contains the objc_mutex_allocate func;
   this function is not available in gcc 2.7.2. */
// #undef HAVE_OBJC_MUTEX_ALLOCATE

/* Define if the Objective-C runtime contains the objc_malloc function;
   this function is not available in gcc 2.7.2. */
// #undef HAVE_OBJC_MALLOC

/* Define if you have the memcpy function.  */
#define HAVE_MEMCPY 1

/* Define if you have the ualarm function.  */
// #undef HAVE_UALARM

/* Define if you have posix mmap function.  */
// #undef HAVE_MMAP

/* Define if you have the getcwd function */
// #undef HAVE_GETCWD

/* Define if you have the getuid function */
// #undef HAVE_GETUID

/* Define if you have the getpwnam function */
// #undef HAVE_GETPWNAM

/* Define if you have the getpwuid function */
// #undef HAVE_GETPWUID

/* Define if you have the kill function */
// #undef HAVE_KILL

/* Define if you have the getpagesize function */
// #undef HAVE_GETPAGESIZE

/* Define if you have the statvfs function */
// #undef HAVE_STATVFS

/* Define if you have the raise function */
// #undef HAVE_RAISE

/* Define if you have the gettimeofday function */
// #undef HAVE_GETTIMEOFDAY

/* Define if you have the GetLocalTime function */
// #undef HAVE_GETLOCALTIME

/* Define if you have the chown function */
// #undef HAVE_CHOWN

/* Define if you have the symlink function */
// #undef HAVE_SYMLINK

/* Define if you have the readlink function */
// #undef HAVE_READLINK

/* Define if you have the fsync function */
// #undef HAVE_FSYNC

/* Define if you have the opendir family of functions */
// #undef HAVE_OPENDIR

/* Define if you have the sysconf function */
// #undef HAVE_SYSCONF

/* Define if you have the GetSystemInfo function */
// #undef HAVE_GETSYSTEMINFO

/* Define if you have the <string.h> header file.  */
#define HAVE_STRING_H 1

/* Define if you have the <strings.h> header file.  */
#define HAVE_STRINGS_H 1

/* Define if you have the <memory.h> header file */
#define HAVE_MEMORY_H 1

/* Define if you have the <stdlib.h> header file.  */
#define HAVE_STDLIB_H 1

/* Define if you have the <libc.h> header file.  */
// #undef HAVE_LIBC_H

/* Define if you have the <sys/time.h> header file.  */
// #undef HAVE_SYS_TIME_H

/* Define if you have the <sys/stat.h> header file */
// #undef HAVE_SYS_STAT_H

/* Define if you have the <sys/vfs.h> header file */
// #undef HAVE_SYS_VFS_H

/* Define if you have the <sys/statfs.h> header file */
// #undef HAVE_SYS_STATFS_H

/* Define if you have the <sys/statvfs.h> header file */
// #undef HAVE_SYS_STATVFS_H

/* Define if you have the <netinet/in.h> header file */
#define HAVE_NETINET_IN_H 1

/* Define if you have the <windows.h> header file */
// #undef HAVE_WINDOWS_H

/* Define if you have the <Windows32/Sockets.h> header file */
// #undef HAVE_WINDOWS32_SOCKETS_H

/* Define if you have the <pwd.h> header file */
#define HAVE_PWD_H 1

/* Define if you have the <sys/param.h> header file */
// #undef HAVE_SYS_PARAM_H

/* Define if you have the <process.h> header file */
// #undef HAVE_PROCESS_H

/* Define if you have the <grp.h> header file */
// #undef HAVE_GRP_H

/* Define if you have the <sys/file.h> header file */
// #undef HAVE_SYS_FILE_H

/* Define if you have the <sys/select.h> header file */
// #undef HAVE_SYS_SELECT_H

/* Define if you have the <utime.h> header file */
// #undef HAVE_UTIME_H

/* Define if you have the <sys/errno.h> header file */
// #undef HAVE_SYS_ERRNO_H

/* Define if sys/wait.h is POSIX compatible */
// #undef HAVE_SYS_WAIT_H

/* Define this if you have the <vfork.h> header file */
// #undef HAVE_VFORK_H

/* Define for vfork in case it's not defined */
// #undef vfork

/* Define for pid_t in case it's not defined */
// #undef pid_t

/* Define if your processor stores words with the most significant
   byte first (like Motorola and SPARC, unlike Intel and VAX).  */
// #undef WORDS_BIGENDIAN

/* The following macros deal with directory entries. */
// #undef HAVE_DIRENT_H
// #undef HAVE_SYS_NDIR_H
// #undef HAVE_SYS_DIR_H
// #undef HAVE_NDIR_H
// #undef HAVE_DIR_H

/* The structure alignment as determined by configure */
// #define STRUCT_ALIGNMENT @STRUCT_ALIGNMENT@

/* The name of the target platform, obtained by configure */
// #define TARGET_PLATFORM		"@target@"

/*  Include this file here to give the above information to the configuration
	file if needs them. */
// #include "config/@target_cpu@/@target_os@.h"

/* This is a hack but I haven't found a way to check for it */
#ifndef __WIN32__
/* Define if your mkdir has two arguments.  */
// # define MKDIR_HAS_TWO_ARGS 1
#endif


#if LIB_FOUNDATION_BOEHM_GC
#  include <gc.h>
#  include <gc_typed.h>
#endif

#endif /* __config_h__ */
