%% We need to slice the structural connectome matrices from fMRI of every participant, because they are 3D matrices
% and the NCT analysis requieres a 2D matrix. So, the matrix must be sliced at the third entry of the third dimension,
% the fractional anisotropy. At the end we have a 2D FA-weighted matrix.

%% Matrix slicen - from 3D to 2D matrix
A_subjID = connectivity(:,:,3);

%% See how many nodes in network because we use Lausanne-219 parcelled strucutral connectomes
nN = size(A_subjID,2); 

%% Save the extracted matrix in the created folder (i.e. Connectomes prepared)
save('A_subjID.mat', 'A_subjID', '-v7')

%% Clear the workspace field, because when the next matrix is loaded, the information for "connectivity", "nN", "regionDescriptions",
% "ROIs" and "weightDescriptions" of the previous matrix will overwrite, causing wrong
% information.
clear("connectivity","nN","regionDescriptions","ROIs","weightDescriptions");
