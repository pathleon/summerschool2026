#!/bin/bash

# SPDX-FileCopyrightText: 2026 CSC - IT Center for Science Ltd. <www.csc.fi>
#
# SPDX-License-Identifier: MIT

submit_job() {
  sub="$(sbatch "$@")"

  if [[ "$sub" =~ Submitted\ batch\ job\ ([0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}"
  else
    exit 1
  fi
}

echo "Submitting cpu job"
cpujobid=$(submit_job << 'EOF'
#!/bin/bash

#SBATCH --account=project_462000007
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem=13G
#SBATCH --time=00:30:00
#SBATCH --partition=debug
#SBATCH --exclusive

ml PrgEnv-cray

(srun CC -DOMP_TAYLOR -fopenmp -std=c++17 -O3 -Wall -Wextra -Wpedantic -pedantic-errors -o omp main.cpp) || { echo "Failed to build openMP code"; exit 1; }
(srun CC  -DSERIAL_TAYLOR      -std=c++17 -O3 -Wall -Wextra -Wpedantic -pedantic-errors -o serial main.cpp) || { echo "Failed to build serial code"; exit 1; }

export OMP_PROC_BIND=close
export OMP_PLACES=cores
export OMP_NUM_THREADS=${SLURM_CPUS_PER_TASK}

for i in 0 1 2 4 8 16
do
    srun ./serial $i > "serial_$i.dat"
    srun ./omp $i > "omp_$i.dat"
done

EOF
)

echo "Submitting gpu job"
gpujobid=$(submit_job << 'EOF'
#!/bin/bash

#SBATCH --account=project_462000007
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --gpus-per-task=1
#SBATCH --mem=13G
#SBATCH --time=00:30:00
#SBATCH --partition=dev-g
#SBATCH --exclusive

ml PrgEnv-cray
ml craype-accel-amd-gfx90a
ml rocm

(srun CC -DHIP_TAYLOR -xhip -std=c++17 -O3 -Wall -Wextra -Wpedantic -pedantic-errors -o hip main.cpp) || { echo "Failed to build hip code"; exit 1; }

for i in 0 1 2 4 8 16
do
    srun ./hip $i > "hip_$i.dat"
done
EOF
)
