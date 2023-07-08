
enlargementfactor = 2.5; //How many microns to expand the line ROIs
scalesettings = "distance=1 known=0.1438612 unit=um" //This means 1 px = 0.1438612 microns, check metadata

path2save = getDirectory("Choose folder containing images.")
filelist = getFileList(path2save) 
for (i = 0; i < lengthOf(filelist); i++) {
    if (endsWith(filelist[i], ".nd2")) { 
        open(path2save + File.separator + filelist[i]);
    } 
    rootname = filelist[i];
    
	run("Enhance Contrast", "saturated=0.35");
	saveAs("Tiff", path2save + File.separator + "MAX_SCALED_" + rootname + "combined.tif");
	run("Linear Stack Alignment with SIFT", "initial_gaussian_blur=1.60 steps_per_scale_octave=3 minimum_image_size=64 maximum_image_size=2048 feature_descriptor_size=2 feature_descriptor_orientation_bins=8 closest/next_closest_ratio=0.92 maximal_alignment_error=25 inlier_ratio=0.05 expected_transformation=Translation interpolate");
	saveAs("Tiff", path2save + File.separator + "ALIGNED_SCALED_MAX_" + rootname + "combined.tif");
	close();
	}