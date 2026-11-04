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
  string(APPEND CFLAGS " -O0 -Mnofma -g -Wall -Knoieee -traceback")
  string(APPEND CXXFLAGS " -O0 -Mnofma -g -Wall -Knoieee -traceback")
  string(APPEND FFLAGS " -O0 -g -Ktrap=fp -Mbounds -Knoieee")
endif()

# nvhpc flag policy (CPU and GPU, DEBUG and production): -Knoieee and no FMA
# on all code; GPU code adds -gpu=...,nofma,math_uniform (OPENACC_GPU_FLAGS
# below). math_uniform makes the GPU's math intrinsics match the host's
# default (-Knoieee) routines, so CPU and GPU runs agree bit for bit. Which
# files get -acc is decided only in Depends.nvhpc; everything else -noacc.
string(APPEND CFLAGS " -Mnofma -Knoieee")
string(APPEND FFLAGS " -Mnofma")

string(APPEND CPPDEFS " -DFORTRANUNDERSCORE -DNO_SHR_VMATH -DNO_R16 -DCPRNVIDIA -DNO_QUAD_PRECISION -DCPRPGI")

set(CXX_LINKER "CXX")
set(FC_AUTO_R8 "-r8")
string(APPEND FFLAGS " -i4 -gopt -time -Mextend -byteswapio -Mflushz -Knoieee")
string(APPEND CXXFLAGS " -Mflushz -Knoieee")
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

# nvfortran adds an accelerator-runtime hook to every file unless -acc or
# -noacc is explicit. Files built via the generic compile rules get
# neither, so the ambient CRAY_ACCEL_TARGET (from the cuda/* module)
# silently enables it -- causing "undefined reference to __acc_compiled"
# in shared-library components (e.g. csm_share) if a GPU case builds that
# shared pool first. ACC_OFF_FLAG forces -noacc on the generic rules only
# (empty for gnu/intel); OPENACC_GPU_FLAGS stays reserved for the explicit
# GPU-enabled object list (GPU_OBJS in Depends.nvhpc).
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
