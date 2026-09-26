string(APPEND CFLAGS " -gopt  -time")
if (compile_threaded)
  string(APPEND CFLAGS " -mp")
endif()

if (NOT DEBUG)
  string(APPEND CFLAGS " -O -Mnofma")
  string(APPEND CXXFLAGS " -O2 -Mnofma")
  # Temporary workaround for nvhpc/25.9 LLVM backend causing non-bit-for-bit
  # restarts; add issue/release-note link here if/when available.
  string(APPEND FFLAGS " -O -Mnofma -MllvmO0")
else()
  string(APPEND CFLAGS " -O0 -Mnofma -g -Wall -Kieee -traceback")
  string(APPEND CXXFLAGS " -O0 -Mnofma -g -Wall -Kieee -traceback")
  string(APPEND FFLAGS " -O0 -g -Ktrap=fp -Mbounds -Kieee")
endif()

string(APPEND CFLAGS " -Mnofma")
string(APPEND FFLAGS " -Mnofma")

string(APPEND CPPDEFS " -DFORTRANUNDERSCORE -DNO_SHR_VMATH -DNO_R16 -DCPRNVIDIA -DNO_QUAD_PRECISION -DCPRPGI")

set(CXX_LINKER "CXX")
set(FC_AUTO_R8 "-r8")
string(APPEND FFLAGS " -i4 -gopt -time -Mextend -byteswapio -Mflushz -Kieee")
string(APPEND CXXFLAGS " -Mflushz -Kieee")
if (COMP_NAME IN_LIST "datm;dlnd;drof;dwav;dice;docn")
  string(APPEND FFLAGS " -Mnovect")
endif()
set(FFLAGS_NOOPT "-O0")
set(FIXEDFLAGS "-Mfixed")
set(FREEFLAGS "-Mfree")
set(HAS_F2008_CONTIGUOUS "FALSE")
set(LDFLAGS "-time -Wl,--allow-multiple-definition")
if (compile_threaded)
  string(APPEND CFLAGS " -mp")
  string(APPEND CXXFLAGS " -mp")
  string(APPEND FFLAGS " -mp")
  string(APPEND LDFLAGS " -mp")
endif()
set(MPICC "mpicc")
set(MPICXX "mpicxx")
set(MPIFC "mpif90")
set(SCC "nvc")
set(SCXX "nvc++")
set(SFC "nvfortran")

if (COMP_NAME STREQUAL mpi-serial)
  string(APPEND CFLAGS " -std=gnu89")
  string(APPEND CXXFLAGS " -std=c++17")
else()
  string(APPEND CFLAGS " -std=gnu99")
  string(APPEND CXXFLAGS " -std=c++17")
endif()

# nvfortran/nvc/nvc++ compile *every* translation unit with an accelerator-
# runtime registration hook (references __acc_compiled / __pgi_uacc_*)
# regardless of whether any real OpenACC directives are used or -acc was
# passed -- see Depends.nvhpc's PUMAS_OBJS comment for the C/C++ side of
# this. Files compiled via cime/CIME/Tools/Makefile's generic .F.o/.f.o/
# .f90.o/.F90.o/.c.o/.cpp.o rules (i.e. every file NOT explicitly routed
# through a GPU-aware object list like KESSLER_OBJS/CCPP_CAP_OBJS/
# PUMAS_OBJS/RRTMGP_OBJS/CLUBB_OBJS in Depends.nvhpc, or MPAS's own
# libmpas: rule) get neither -acc nor -noacc, so on a GPU case the ambient
# CRAY_ACCEL_TARGET environment variable (set case-wide by the loaded
# cuda/* module, not by anything this build requests) silently makes
# nvfortran/nvc enable a real accelerator hook for them anyway -- confirmed
# directly: whichever case happens to be the first in a shared test-id's
# batch to trigger a shared component's build (e.g. csm_share) determines
# whether that component's compiled objects pick this up, causing a link
# failure ("undefined reference to __acc_compiled") for every OTHER case
# sharing that same build pool if a GPU case happened to go first. Applied
# via ACC_OFF_FLAG (deliberately a NEW, separate variable from
# OPENACC_GPU_FLAGS, not a reuse of it): OPENACC_GPU_FLAGS becomes real
# "-acc -gpu=..." on an actual GPU case, which is correct for the handful
# of explicitly GPU-aware object lists but would be wrong applied
# universally (it would silently give every other component in the build
# real GPU codegen it was never designed for -- the exact class of bug
# this whole investigation started from, just for MPAS's dycore instead of
# a shared library). ACC_OFF_FLAG is unconditionally -noacc regardless of
# GPU_TYPE/OPENACC_GPU_OFFLOAD, is used only by the generic compile rules,
# and is deliberately left undefined for gnu/intel (harmlessly empty,
# since -noacc is an nvhpc-only flag those compilers don't understand).
set(ACC_OFF_FLAG " -noacc ")
set(OPENACC_GPU_FLAGS " -noacc ")
set(OPENMP_GPU_FLAGS "")
if (OPENACC_GPU_OFFLOAD)
  # xdsl_ccpp's generated GPU data-movement directives (!$acc data/update/
  # enter data, from --directive acc) are wrapped in #ifdef USE_GPU ... #endif
  # in the generated cap; without this define they get preprocessed away
  # even though --directive acc was passed at cap-generation time.
  string(APPEND CPPDEFS " -DUSE_GPU")
endif()
if (GPU_TYPE STREQUAL v100)
  if (OPENACC_GPU_OFFLOAD)
    set(OPENACC_GPU_FLAGS " -acc -gpu=cc70,lineinfo,nofma,math_uniform -Minfo=accel ")
  endif()
  if (OPENMP_GPU_OFFLOAD)
    set(OPENMP_GPU_FLAGS " -mp=gpu -gpu=cc70,lineinfo,nofma,math_uniform -Minfo=accel ")
  endif()
endif()
if (GPU_TYPE STREQUAL a100)
  if (OPENACC_GPU_OFFLOAD)
    set(OPENACC_GPU_FLAGS " -acc -gpu=cc80,lineinfo,nofma,math_uniform -Minfo=accel ")
  endif()
  if (OPENMP_GPU_OFFLOAD)
    set(OPENMP_GPU_FLAGS " -mp=gpu -gpu=cc80,lineinfo,nofma,math_uniform -Minfo=accel ")
  endif()
endif()
if (GPU_TYPE STREQUAL a10 OR GPU_TYPE STREQUAL a2)
  if (OPENACC_GPU_OFFLOAD)
    set(OPENACC_GPU_FLAGS " -acc -gpu=cc86,lineinfo,nofma,math_uniform -Minfo=accel ")
  endif()
  if (OPENMP_GPU_OFFLOAD)
    set(OPENMP_GPU_FLAGS " -mp=gpu -gpu=cc86,lineinfo,nofma,math_uniform -Minfo=accel ")
  endif()
endif()
if (GPU_TYPE STREQUAL h100)
  if (OPENACC_GPU_OFFLOAD)
    set(OPENACC_GPU_FLAGS " -acc -gpu=cc90,lineinfo,nofma,math_uniform -Minfo=accel ")
  endif()
  if (OPENMP_GPU_OFFLOAD)
    set(OPENMP_GPU_FLAGS " -mp=gpu -gpu=cc90,lineinfo,nofma,math_uniform -Minfo=accel ")
  endif()
endif()
if (OPENACC_GPU_FLAGS)
  string(APPEND LDFLAGS " ${OPENACC_GPU_FLAGS}")
endif()
if (OPENMP_GPU_FLAGS)
  string(APPEND LDFLAGS " ${OPENMP_GPU_FLAGS}")
endif()
