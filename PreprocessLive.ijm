
enlargementfactor = 2.5; //How many microns to expand the line ROIs
scalesettings = "distance=1080 known=341.77248 unit=um" //This means 1080 px = 341.77 microns, check metadata

path2save = getDirectory("Choose folder containing images.")
filelist = getFileList(path2save) 
for (i = 0; i < lengthOf(filelist); i++) {
    if (endsWith(filelist[i], ".tif")) { 
        open(path2save + File.separator + filelist[i]);
    } 
}

rootname = replace(filelist[1],"t0000.tif","");

run("Concatenate...", "open image1=" + rootname + "t0000.tif image2=" + rootname + "t0001.tif image3=" + rootname + "t0002.tif");
run("Stack to Hyperstack...", "order=xyczt(default) channels=1 slices=7 frames=240 display=Color");
saveAs("Tiff", path2save + File.separator + rootname + "combined.tif");
run("Z Project...", "projection=[Max Intensity] all");
saveAs("Tiff", path2save + File.separator + "MAX_" + rootname + "combined.tif");
run("Linear Stack Alignment with SIFT", "initial_gaussian_blur=1.60 steps_per_scale_octave=3 minimum_image_size=64 maximum_image_size=1024 feature_descriptor_size=4 feature_descriptor_orientation_bins=8 closest/next_closest_ratio=0.92 maximal_alignment_error=25 inlier_ratio=0.05 expected_transformation=Translation interpolate");
saveAs("Tiff", path2save + File.separator + "ALIGNED_MAX_" + rootname + "combined.tif");
run("Set Scale...", scalesettings);
run("ROI Manager...");

run("Enhance Contrast", "saturated=0.35"); run("Close");
setTool("freeline");

i=0;
run("ROI Manager...");
while (true) {
    run("Select None");
    waitForUser("Draw ROI, then hit OK (or hit OK to finish)");
    if (getValue("selection.size")>0) {
    	name_ROI = "Line_";
		Roi.setName(name_ROI+i);
		roiManager("Add");	
		run("Measure");
    } else {
        // Prompt the user to draw an ROI or select "done"
        Dialog.create("Instructions");
		Dialog.addCheckbox("Done drawing ROIs?", true);	
		Dialog.show();
		choice = Dialog.getCheckbox;
        if (choice == 1) {
            // Exit the loop when the user selects "done"
            break;
        }
    }
    i++;
}

// EXPAND ALL LINE ROIS BY SET WIDTH  
roiManager("Show all");
n = roiManager('count');
for (i = 0; i < n; i++) {
    roiManager('select', i);
    run("Line to Area");
    run("Enlarge...", "enlarge=" + enlargementfactor);
    name_ROI = "Expanded_";
	Roi.setName(name_ROI+i);
	roiManager("Add");
	run("Measure");
}
roiManager("Save", path2save + File.separator + "ROIs_ALIGNED_MAX_" + rootname + "combined.zip");

// SAVE MEASUREMENTS
selectWindow("Results");
saveAs("Results", path2save + "/Measure of ROIs_ALIGNED_MAX_" + rootname + ".csv");

// TURN ALL ROIS INTO SINGLE ROI TO USE IN TRACKMATE
roiManager("Combine");
run("TrackMate");

waitForUser("Select ok when done running Trackmate. Don't forget to save XML and run Capture Overlay!");

selectWindow("TrackMate capture of ALIGNED_MAX_" + rootname + "combined");
saveAs("Tiff", path2save + File.separator + "TrackMate capture of ALIGNED_MAX_" + rootname + "combined.tif");
close(); close(); close(); close();
