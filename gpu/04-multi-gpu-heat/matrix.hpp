#pragma once
#include <vector>
#include <cassert>
#define __HIP_PLATFORM_AMD__
#include <hip/hip_runtime.h>
#include "../error_checking.hpp"

// Generic 2D matrix array class.
//
// Internally data is stored in 1D vector but is
// accessed using index function that maps i and j
// indices to an element in the flat data vector.
// Row major storage is used
// For easier usage, we overload parentheses () operator
// for accessing matrix elements in the usual (i,j)
// format.

enum storage_spec {
  DEVICE_ONLY,
  HOST_ONLY,
  HOST_AND_DEVICE
};

template<typename T>
struct MatrixView {
  T* _data;
  const size_t nrows, ncols;

  __host__ __device__ T& operator()(size_t i, size_t j) {
    return _data[i*ncols+j]; 
  }
};

template <typename T, storage_spec mem_location>
class Allocator {
    static void apply(T** data, size_t size);
};

template <typename T >
struct Allocator<T, HOST_ONLY> {
    static void apply(T** data, size_t size) { *data = new T[size]; }
};

template <typename T >
struct Allocator<T, DEVICE_ONLY> {
  static void apply(T** data, size_t size) {
    HIP_ERRCHK(hipMalloc(data, size));
  }
};

template <typename T >
struct Allocator<T, HOST_AND_DEVICE> {
  static void apply(T** data, size_t size) {
    HIP_ERRCHK(hipMallocManaged(data, size));
  }
};

template<typename T, storage_spec mem_location>
class Matrix
{

private:

    // Internal storage

    // Internal 1D indexing (row major)
  __host__ __device__ int indx(int i, int j) const {
    return i * ncols + j;
  }

  void allocate(T** data, size_t size){
    Allocator<T, mem_location>::apply(&this->data, sizeof(T)*this->nrows*this->ncols);
  }

public:

    T* _data;
    const size_t nrows, ncols;

  //const storage_spec mem_location;

    MatrixView<T> view() const { return MatrixView<T>(_data, nrows, ncols); }

    Matrix(const Matrix&) = delete; // Delete copy constructor

    // Make a deep copy from a view
    Matrix(MatrixView<T,mem_location> view) : nrows(view.nrows), ncols(view.ncols) {
      allocate();
      HIP_ERRCHK(hipMemCpy(_data, view.data, sizeof(T)*view.nrows*view.ncols, hipMemcpyDefault));
    }
    
    // Allocate at the time of construction
    Matrix(size_t nrows, size_t ncols) : nrows(nrows), ncols(ncols) {
      allocate();
    }

    ~Matrix() {
      if (_data) {
        if constexpr (mem_location == HOST_ONLY) { 
          delete[] _data; 
        }
        else {
          hipFree(_data);
        }
      }
    }

    // standard (i,j) syntax for setting elements
    __host__ __device__ inline T& operator()(int i, int j) {
        return _data[ indx(i, j) ];
    }

    // standard (i,j) syntax for getting elements
    __host__ __device__ inline const T& operator()(int i, int j) const {
        return _data[ indx(i, j) ];
    }

    // provide possibility to get raw pointer for data at index (i,j) (needed for MPI)
    __host__ __device__ inline T* data(int i=0, int j=0) {return _data + indx(i,j);}
};



#if 0
template<typename T>
void Matrix<T, DEVICE_ONLY>::Allocator {
  static void apply(Matrix<T, DEVICE_ONLY>* M) {
  HIP_ERRCHK(hipMalloc(&(M->_data), sizeof(T)*M->nrows*M->ncols));
  }
};

template<typename T>
void Matrix<T, HOST_AND_DEVICE>::Allocator {
  static void apply(Matrix<T, HOST_AND_DEVICE>* M) {
    HIP_ERRCHK(hipMallocManaged(&M->_data, sizeof(T)*M->nrows*M->ncols));
  }
};
  {
      switch(mem_location) {
        case DEVICE_ONLY:
          HIP_ERRCHK(hipMalloc(&_data, sizeof(T)*nrows*ncols));
          break;
        case HOST_ONLY:
          _data = new T[nrows*ncols];
          break;
        case HOST_AND_DEVICE:
          HIP_ERRCHK(hipMallocManaged(&_data, sizeof(T)*nrows*ncols));
          break;
      }
    }
#endif
