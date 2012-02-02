#ifndef CGNSTYPES_F_H
#define CGNSTYPES_F_H

#define CG_BUILD_64BIT 0

#if CG_BUILD_64BIT
# define cgsize_t integer*8
# define CGSIZE_T integer*8
#else
# define cgsize_t integer*4
# define CGSIZE_T integer*4
#endif

#define cglong_t integer*8
#define CGLONG_T integer*8
#define cgid_t   real*8
#define CGID_T   real*8

#endif

