/* PREPROCESS LIVE NIKON 
 * This script is designed to open a Nikon .nd2 file, generate a MinIP, prompt the user to draw ROIs,  
 *  and run Trackmate analysis suite. Ideally it would loop for multiple file throughput, but it doesn't yet.
 */

filetype = ".nd2";
enlargementfactor = 4; //How many microns to expand the line ROIs
img_scale = 0.1438612; //This means 1 px = 0.1438612 microns, check metadata
scalesettings = "distance=1 known=" + img_scale + " unit=um"; 

path2save = getDirectory("Choose folder containing images.")
path = File.openDialog("Select a File");
filename = File.getName(path);
filename=substring(filename,0,lengthOf(filename)-4); //Remove file extension
open(path2save + File.separator + filename + filetype);

run("Z Project...", "projection=[Min Intensity]");
saveAs("Tiff", path2save + File.separator + "MIN_" + filename + ".tif");
selectWindow(filename + filetype);
//run("Enhance Contrast", "saturated=0.35"); //This is an option but did not use for GRC analysis

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
	
	// Allow user to draw desired number of ROIs using freehand line tool to trace axons
	i=0;
	run("ROI Manager...");
	roiManager("Show all");
	while (true) {
	    run("Select None");
	    waitForUser("Draw ROI, then hit OK (or hit OK now to finish)");
	    if (getValue("selection.size")>0) {
	    	name_ROI = "Line_";
			Roi.setName(name_ROI+i);
			roiManager("Add");	
			run("Measure");
	    } else {
	        // User has selected OK to move on. Prompt user to draw more ROIs or confirm "done"
	        Dialog.create("Instructions");
			Dialog.addCheckbox("Done drawing ROIs?", true);	
			Dialog.show();
			choice = Dialog.getCheckbox;
	        if (choice == 1) {
	            // Exit the loop; the user has selected "done"
	            break; // This would give Prof. Booth a heart attack but I don't care
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
	roiManager("Select All");
	roiManager("Combine");
	
	run("TrackMate");
	waitForUser("Select ok when done running Trackmate. Don't forget to save XML and run Capture Overlay!");
	close("TrackMate on " + filename);

	selectWindow("TrackMate capture of " + filename);
	saveAs("Tiff", path2save + File.separator + "TrackMate capture of " + filename + ".tif");
	close("MIN_" + filename + ".tif");
	close(filename + filetype);
	close("ROI Manager");
	close("Results");
	close("TrackMate capture of " + filename + ".tif");
	run("Collect Garbage");
