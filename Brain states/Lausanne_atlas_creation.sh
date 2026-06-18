#!/bin/bash
#export OMP_NUM_THREADS=1

subs=$(</home/brankovk/Masterarbeit/HCP_1200_ids.txt)

HCP=/slow/projects/HCP_1200/01_complete_batch
OUT=/home/brankovk/Masterarbeit/results
T1=/home/brankovk/Masterarbeit/HCP_1200
LUT=/home/brankovk/Masterarbeit/Laus250AllLut.txt

# Handle Ctrl+C (SIGINT)
trap 'echo "Stopping..."; kill 0; exit 1' SIGINT

task () {
    local j=$1

    echo "Processing subject: ${j}"

    mkdir -p ${OUT}/${j}
    mkdir -p ${OUT}/${j}/T1w/mri
    mkdir -p ${OUT}/${j}/MNINonLinear/{Native,fsaverage_LR32k}


# (works): Convert Lausanne-250 freesurfer image to nii
mri_convert -rt nearest -rl ${T1}/${j}/T1w/T1w_acpc_dc_restore.nii.gz ${HCP}/${j}/T1w/freesurfer/mri/lausanne250+aseg.mgz ${OUT}/${j}/T1w/mri/laus250_1mm.nii.gz

# (works): And takes a while - transforms to MNI space
applywarp --rel --interp=nn -i ${OUT}/${j}/T1w/mri/laus250_1mm.nii.gz -r ${T1}/${j}/MNINonLinear/T1w_restore.nii.gz --premat=$FSLDIR/etc/flirtsch/ident.mat -o ${OUT}/${j}/T1w/mri/laus250.nii.gz
applywarp --rel --interp=nn -i ${OUT}/${j}/T1w/mri/laus250_1mm.nii.gz -r ${T1}/${j}/MNINonLinear/T1w_restore.nii.gz -w ${T1}/${j}/MNINonLinear/xfms/acpc_dc2standard -o ${OUT}/${j}/MNINonLinear/laus250.nii.gz #transforms to atlas space

# (works): assign labels to native and atlas spaced image, labels from Laus250, modified with Matlab to match format
wb_command -volume-label-import ${OUT}/${j}/MNINonLinear/laus250.nii.gz ${LUT} ${OUT}/${j}/MNINonLinear/laus250.nii.gz -drop-unused-labels

# (works): create gii
mris_convert --annot ${HCP}/${j}/T1w/freesurfer/label/rh.lausanne250.annot ${HCP}/${j}/T1w/freesurfer/surf/rh.white ${OUT}/${j}/MNINonLinear/Native/${j}.R.Laus250.native.label.gii
mris_convert --annot ${HCP}/${j}/T1w/freesurfer/label/lh.lausanne250.annot ${HCP}/${j}/T1w/freesurfer/surf/lh.white ${OUT}/${j}/MNINonLinear/Native/${j}.L.Laus250.native.label.gii

# (works): do some label stuff
wb_command -set-structure ${OUT}/${j}/MNINonLinear/Native/${j}.L.Laus250.native.label.gii "CORTEX_LEFT"
wb_command -set-structure ${OUT}/${j}/MNINonLinear/Native/${j}.R.Laus250.native.label.gii "CORTEX_RIGHT"

wb_command -set-map-names ${OUT}/${j}/MNINonLinear/Native/${j}.L.Laus250.native.label.gii -map 1 ${j}_L_Laus250
wb_command -set-map-names ${OUT}/${j}/MNINonLinear/Native/${j}.R.Laus250.native.label.gii -map 1 ${j}_R_Laus250

wb_command -gifti-label-add-prefix ${OUT}/${j}/MNINonLinear/Native/${j}.L.Laus250.native.label.gii L ${OUT}/${j}/MNINonLinear/Native/${j}.L.Laus250.native.label.gii
wb_command -gifti-label-add-prefix ${OUT}/${j}/MNINonLinear/Native/${j}.R.Laus250.native.label.gii R ${OUT}/${j}/MNINonLinear/Native/${j}.R.Laus250.native.label.gii

# (works): make gifti label
wb_command -label-resample ${OUT}/${j}/MNINonLinear/Native/${j}.R.Laus250.native.label.gii ${T1}/${j}/MNINonLinear/Native/${j}.R.sphere.MSMSulc.native.surf.gii ${T1}/${j}/MNINonLinear/fsaverage_LR32k/${j}.R.sphere.32k_fs_LR.surf.gii BARYCENTRIC ${OUT}/${j}/MNINonLinear/fsaverage_LR32k/${j}.R.Laus250.32k_fs_LR.label.gii -largest
wb_command -label-resample ${OUT}/${j}/MNINonLinear/Native/${j}.L.Laus250.native.label.gii ${T1}/${j}/MNINonLinear/Native/${j}.L.sphere.MSMSulc.native.surf.gii ${T1}/${j}/MNINonLinear/fsaverage_LR32k/${j}.L.sphere.32k_fs_LR.surf.gii BARYCENTRIC ${OUT}/${j}/MNINonLinear/fsaverage_LR32k/${j}.L.Laus250.32k_fs_LR.label.gii -largest

wb_command -cifti-create-label ${OUT}/${j}/MNINonLinear/fsaverage_LR32k/${j}.Laus250.32k_fs_LR.dlabel.nii -left-label ${OUT}/${j}/MNINonLinear/fsaverage_LR32k/${j}.L.Laus250.32k_fs_LR.label.gii -roi-left ${T1}/${j}/MNINonLinear/fsaverage_LR32k/${j}.L.atlasroi.32k_fs_LR.shape.gii  -right-label ${OUT}/${j}/MNINonLinear/fsaverage_LR32k/${j}.R.Laus250.32k_fs_LR.label.gii -roi-right ${T1}/${j}/MNINonLinear/fsaverage_LR32k/${j}.R.atlasroi.32k_fs_LR.shape.gii
wb_command -set-map-names ${OUT}/${j}/MNINonLinear/fsaverage_LR32k/${j}.Laus250.32k_fs_LR.dlabel.nii -map 1 ${j}_Laus250

echo "Finished subject: ${j}"

}

N=28
(
for j in $subs; do
   ((i=i%N)); ((i++==0)) && wait
   task "$j" & 
done
)
        
   

        
        
