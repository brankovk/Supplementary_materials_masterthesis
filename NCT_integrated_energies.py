# import packages

import os
import numpy as np
import pandas as pd  # to load excel tables
from scipy.io import loadmat, savemat  # to load mats

from nctpy.energies import integrate_u, get_control_inputs
from nctpy.utils import matrix_normalization, convert_states_str2int, normalize_state
from nctpy.metrics import ave_control
from nctpy.pipelines import ComputeControlEnergy


# load needed data
id_file = r"C:\Users\brank\Desktop\Masterarbeit_offiziell\Data\Task Data\WM brain states\Vorbereitung_extraction\HCP_1200_ids.txt"

# directory where data is stored
results_dir = r"C:\Users\brank\Desktop\Masterarbeit_offiziell\Python\Global energies"
adjacency_dir = r"C:\Users\brank\Desktop\Masterarbeit_offiziell\Matlab\Connectomes prepared"
states_dir = r"C:\Users\brank\Desktop\Masterarbeit_offiziell\Matlab\States prepared"

# load subject list
with open(id_file) as f:
    subjects = [line.strip() for line in f if line.strip()]

# these are only for saving afterwards, I have this folder structure already set up:
Ts = np.array([0.5, 1, 1.5, 2])
Rhos = np.array([1, 0.1, 0.01, 0.001])
Ts_string = np.array(['T05', 'T1', 'T15', 'T2'], dtype=str)
Rhos_string = np.array(['Rho1', 'Rho01', 'Rho001', 'Rho0001'], dtype=str)

for subj in subjects:
    print(f"\nProcessing subject {subj}")

    try:
        # load adjacency matrix
        adj_file = os.path.join(adjacency_dir, f"A_{subj}.mat")

        adj_data = loadmat(adj_file)
        adjacency = adj_data[f"A_{subj}"]
        n_nodes = adjacency.shape[0]

        print("Adjacency shape:", adjacency.shape)

       # load all states
        states_file = os.path.join(
            states_dir, subj, "MNINonLinear", "Results", f"{subj}_states.xlsx")

        if not os.path.exists(adj_file) or not os.path.exists(states_file):
            print("DEBUG SUBJECT:", subj)
            print("Adj exists:", os.path.exists(adj_file))
            print("States exists:", os.path.exists(states_file))
            continue

        states = pd.read_excel(states_file)

        state0 = states["cope10"].astype(float).to_numpy()
        state2 = states["cope9"].astype(float).to_numpy()

        all_states = np.column_stack((state0, state2))
        n_states = all_states.shape[1]

        print("States shape:", all_states.shape)

        # actual NCT:
        system = "continuous"  # building on prior work + because we are interested
        # in specific intermediary states; modeling fMRI so should be OK
        # remove following line here bc control energy will normalize itself
        # adjacency_norm = matrix_normalization(adjacency, system=system, c=1)
        control_set = np.eye(n_nodes)
        trajectory_constraints = np.eye(n_nodes)

        for t in Ts:
            for r in Rhos:
                control_tasks = []
                th_string = Ts_string[np.where(Ts == t)[0][0]]
                rho_string = Rhos_string[np.where(Rhos == r)[0][0]]
                steps = int((t*1000)+1)
                print(f"number of time steps: {steps}, rho: {r}")
                outdir = os.path.join(results_dir, th_string, rho_string)
                os.makedirs(outdir, exist_ok=True)

               # Loop over columns, get initial state
                for i in range(all_states.shape[1]):
                    initial_state = all_states[:, i]
                    all_targets = []  # we'll store results here
                    for j in range(all_states.shape[1]):  # Loop over columns
                        target_state = all_states[:, j]
                        print(f"start state: {i+1}, target state {j+1}")
                        control_task = dict()
                        control_task["x0"] = initial_state
                        control_task["xf"] = target_state
                        control_task["B"] = control_set
                        control_task["S"] = trajectory_constraints
                        control_task["rho"] = r
                        control_task["T"] = t
                        control_task["xr"] = target_state
                        control_tasks.append(control_task)
                        # xr: x and u constrained toward target start;
                        # essentially: Don't stray away too far from target

                compute_control_energies = ComputeControlEnergy(
                    A=adjacency,
                    control_tasks=control_tasks,
                    system="continuous",
                    c=1
                )
                print("Full number of states:")
                print(n_states)

                compute_control_energies.run()

                global_energies = np.reshape(
                    compute_control_energies.E, (n_states, n_states)
                )

                savemat(
                    os.path.join(
                        outdir, f"{subj}_alltransitions_integrated.mat"),
                    {"global_energies": global_energies}
                )

                print(f"Saved subject {subj} | {t} | {r}")

    except Exception as e:
        print(f"Error in subject {subj}: {e}")
