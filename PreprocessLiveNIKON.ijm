
enlargementfactor = 4; //How many microns to expand the line ROIs
scalesettings = "distance=1 known=0.1438612 unit=um" //This means 1 px = 0.1438612 microns, check metadata
img_scale = 0.1438612;

path2save = getDirectory("Choose folder containing images.")
path = File.openDialog("Select a File");
filename = File.getName(path);
open(path2save + File.separator + filename);

run("Z Project...", "projection=[Min Intensity]");
run("Enhance Contrast", "saturated=0.35");

/*
filelist = getFileList(path2save) 
for (i = 0; i < lengthOf(filelist); i++) {
    if (endsWith(filelist[i], ".tif")) { 
        open(path2save + File.separator + filelist[i]);
    } 
    rootname = filelist[i];
    
    run("Z Project...", "projection=[Max Intensity] all");
	run("Enhance Contrast", "saturated=0.35");
	saveAs("Tiff", path2save + File.separator + "MAX_SCALED_" + rootname + "combined.tif");
	run("Linear Stack Alignment with SIFT", "initial_gaussian_blur=1.60 steps_per_scale_octave=3 minimum_image_size=64 maximum_image_size=2048 feature_descriptor_size=2 feature_descriptor_orientation_bins=8 closest/next_closest_ratio=0.92 maximal_alignment_error=25 inlier_ratio=0.05 expected_transformation=Translation interpolate");
	saveAs("Tiff", path2save + File.separator + "ALIGNED_SCALED_MAX_" + rootname + "combined.tif");
	}
*/

run("Set Scale...", scalesettings);
	run("ROI Manager...");
	setTool("freeline");
	
	i=0;
	run("ROI Manager...");
	roiManager("Show all");
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
	roiManager("Save", path2save + File.separator + filename + "combined.zip");
	
	// SAVE MEASUREMENTS
	selectWindow("Results");
	saveAs("Results", path2save + "/Measure of " + filename + ".csv");
	
	// TURN ALL ROIS INTO SINGLE ROI TO USE IN TRACKMATE
	roiManager("Combine");
	    
	   
run("TrackMate");

waitForUser("Select ok when done running Trackmate. Don't forget to save XML and run Capture Overlay!");

selectWindow("TrackMate capture of " + filename);
saveAs("Tiff", path2save + File.separator + "TrackMate capture of " + filename + ".tif");
close(); close(); close(); close();
