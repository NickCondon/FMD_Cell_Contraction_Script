//This script is written in the IJ1 Language

print("\\Clear")

//	MIT License

//	Copyright (c) 2019 Nicholas Condon n.condon@uq.edu.au

//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:

//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.

//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//	SOFTWARE.


//Script Details and Acknowledgement
scripttitle="Felicity - Ca 2+ Quantification Script";
version="1.0";
date="27/03/19";
description="This script takes 2-channel images and measures intensity (red/green), cell length over time. "
+" <br> <br> Total cell intensity can be normalised using the Simple Ratio method in FIJI."
+" <br> <br> This script can be run in the background by selecting Batch Mode."
    showMessage("Institute for Molecular Biosciences ImageJ Script", "<html>" 
    +"<h1><font size=6 color=Teal>ACRF: Cancer Biology Imaging Facility</h1>
    +"<h1><font size=5 color=Purple><i>The University of Queensland</i></h1>
    +"<h4><a href=http://imb.uq.edu.au/Microscopy/>ACRF: Cancer Biology Imaging Facility</a><\h4>"
    +"<h1><font color=black>ImageJ Script Macro: "+scripttitle+"</h1> "
    +"<p1>Version: "+version+" ("+date+")</p1>"
    +"<H2><font size=3>Created by Nicholas Condon</H2>"	
    +"<p1><font size=2> contact n.condon@uq.edu.au \n </p1>" 
    +"<P4><font size=2> Available for use/modification/sharing under the "+"<p4><a href=https://opensource.org/licenses/MIT/>MIT License</a><\h4> </P4>"
    +"<h3>   <\h3>"    
    +"<p1><font size=3 \b i>"+description+"</p1>"
   	+"<h1><font size=2> </h1>"  
	+"<h0><font size=5> </h0>"
    +"");

//Creates a Parameters dialog box
ext = ".oir";
Dialog.create("Parameters");
	Dialog.addMessage("Configuration Controls:")
	Dialog.addMessage(" ");
  	Dialog.addString("Choose your file extension:", ext);				//Option to choose your file extension
 	Dialog.addMessage("(For example .czi  .lsm  .nd2  .lif  .ims)");
 	Dialog.addMessage(" ");
 	Dialog.addCheckbox("Run Bleaching Normalisation", true);			//Option for bleach mode
 	Dialog.addCheckbox("Run in batch mode (Background)", true);			//Option for batch mode
Dialog.show();
  
ext 		= 	Dialog.getString();			//Updates file extension variable
Bleach 		= 	Dialog.getCheckbox();		//Updates Bleach correction variable
batch		=	Dialog.getCheckbox();		//Updates Batch mode variable
	
	if (batch==1) {setBatchMode(true); print("Batch Mode: ON");}
	if (batch==0) {setBatchMode(false); print("Batch Mode: OFF");}

	
run("Set Measurements...", "area mean standard modal min feret's median display");		//Sets measurements needed for all analysis
getDateAndTime(year, month, week, day, hour, min, sec, msec);							//Gets date and time info for folders


print("\\Clear");						//Clears log window
roiManager("Reset");					//Clears ROI manager
run("Clear Results");					//Clears Results Window

path = getDirectory("Choose Source Directory ");
list = getFileList(path);


resultsDir = path+"_Results_"+"_"+year+"-"+month+"-"+day+"_at_"+hour+"."+min+"/";		//Defines Results Directory filepath and name
File.makeDirectory(resultsDir);															//Creates Results directory

start = getTime();																		//Starts timer

for (i=0; i<list.length; i++) {															//Loop for file opening
	if (endsWith(list[i], ext)){														//Filter for only files ending in extension
	if (batch==1) {setBatchMode(true);}													//Re-confirms batch mode being on
		open(path+list[i]);																//Opens files iteratively

		roiManager("Reset");															//Clears ROI manager
		run("Clear Results");															//Clears Results Window
  		
		windowtitle = getTitle();														//Defines file name variable
		windowtitlenoext = replace(windowtitle, ext, "");								//Creates a variable with no extension

		run("Duplicate...", "title=Green duplicate channels=1");						//Duplicates Green Channel
		run("Duplicate...", "title=Green2 duplicate channels=1");						//Duplicates Green Channel
		selectWindow(windowtitle);
		run("Duplicate...", "title=Red duplicate channels=2");							//Duplicates Red Channel
		if (Bleach==1) {
			run("Bleach Correction", "correction=[Simple Ratio]");						//Runs bleach correction if selected above
			rename("Red");
			}
		run("Duplicate...", "title=Red2 duplicate channels=2");							//Duplicates Red Channel


		selectWindow("Green");															//Begins cell segmentation
		run("Z Project...", "projection=[Standard Deviation]");							//Flattens over time using SD Projection
		run("Median...", "radius=2 stack");												//Smooths image for thresholding
		run("Subtract Background...", "rolling=50");									//Normalises background intensity
		setAutoThreshold("Li dark");													//Thresholds cells
		run("Convert to Mask");															//Creates a binary image
		run("Watershed");																//Cuts segmentations that combine multiple ROIs into one
		run("Analyze Particles...", "size=15-Infinity show=Masks display exclude clear add");	//Removes smaller particles (noise)
		rename("Green-Mask");															//Renames image for saving later


		print("\\Clear");																//Clears Log Window
		
		selectWindow("Green2");															//Selects Green only image
		for (r=0; r<roiManager("count"); r++){											//Runs if ROIs have been found
			ArrayName = "Array"+r;														//Creates an Array name for each loop (cell)
			ArrayName = newArray(nSlices+1);											//Creates the array with the name from above
			ArrayName[0] = "Green-Intensity_ROI-Position "+(r+1);						//Defines the first cell of the array as the measurement + ROI name
			roiManager("Select", r);													//Selects the ROI (cell) of the current loop (ie cell 1, 2, 3, 4...)
			for (k = 0; k<nSlices; k++){												//Creates a loop to run over each frame
				setSlice(k+1);															//Iteratively moves to each frame
				run("Clear Results");													//Clears the results window
				run("Measure");															//Measures the cell area for that ROI and frame
				ArrayName[k+1] = getResult("Mean", 0);									//Pastes the result (mean) into the array at the corresponding position
				}
			string = Array.print(ArrayName);											//Prints the array into the Log window for each ROI
			}
		selectWindow("Log");															//Selects the log window
		saveAs("Text", resultsDir+windowtitlenoext+"_GreenIntensity.csv");				//Saves the log to the results directory
		print("\\Clear");																//Clears the log window
		run("Clear Results");															//Clears the results window



		selectWindow("Red");															//Selects Red only image
		for (r=0; r<roiManager("count"); r++){											//Runs if ROIs have been found
			ArrayName = "Array"+r;														//Creates an Array name for each loop (cell)
			ArrayName = newArray(nSlices+1);											//Creates the array with the name from above
			ArrayName[0] = "Red-Intensity_ROI-Position "+(r+1);							//Defines the first cell of the array as the measurement + ROI name
			roiManager("Select", r);													//Selects the ROI (cell) of the current loop (ie cell 1, 2, 3, 4...)
			for (k = 0; k<nSlices; k++){												//Creates a loop to run over each frame
				setSlice(k+1);															//Iteratively moves to each frame
				run("Clear Results");													//Clears the results window
				run("Measure");															//Measures the cell area for that ROI and frame
				ArrayName[k+1] = getResult("Mean", 0);									//Pastes the result (mean) into the array at the corresponding position
				}
			string = Array.print(ArrayName);											//Prints the array into the Log window for each ROI
			}	
		selectWindow("Log");															//Selects the log window
		saveAs("Text", resultsDir+windowtitlenoext+"_RedIntensity.csv");				//Saves the log to the results directory
		print("\\Clear");																//Clears the log window
		run("Clear Results");															//Clears the results window

				
		selectWindow("Red2");															//Selects Red only image
		for (r2 = 0; r2<roiManager("count"); r2++){										//Runs if ROIs have been found
			roiManager("Select", r2);													//Selects the ROI (cell) of the current loop (ie cell 1, 2, 3, 4...)
			run("Enlarge...", "enlarge=2 pixel");										//Enlarges the selection of the ROI (cell)
			run("Duplicate...", "title=redcell duplicate");								//Duplicates the expanded ROI (bounding box)
			run("Select All");															//Selects all pixels
			run("Median...", "radius=2 stack");											//Smooths the dataset for thresholding
			setAutoThreshold("Li dark");												//Thresholds the cell intensity within this ROI
			run("Convert to Mask", "method=Li background=Dark black");					//Makes a Binary of the cell
			FeretArray = newArray(nSlices+1);											//Creates a new Array
			FeretArray[0] = "Feret-Diameter_ROI-Position "+(r2+1);						//Defines the first cell of the array as the measurement + ROI name
			for (k = 0; k<nSlices; k++){												//Creates a loop to run over each frame
				setSlice(k+1);															//Iteratively moves to each frame
				run("Clear Results");													//Clears the results window
				run("Analyze Particles...", "size=0.5-Infinity show=Nothing display clear ");	//Detects larger objects within the ROI and measures them
				if (nResults != 00) {FeretArray[k+1] = getResult("Feret", 0);}			//If a result is recorded (ie cell found) the results is collected
				else FeretArray[k+1] = "NaN";											//If no result was recorded (ie no cell found) then "NaN" (not a number) is printed
				}
			string = Array.print(FeretArray);											//Prints the array into the Log window for each ROI
			selectWindow("redcell");													//Selects window of duplicated ROI area
			close();																	//Closes window
			}
	
		selectWindow("Log");															//Selects the log window
		saveAs("Text", resultsDir+windowtitlenoext+"_Feret_Diameter.csv");				//Saves the log to the results directory
		print("\\Clear");																//Clears the log window
		run("Clear Results");															//Clears the results window
	
	
		selectWindow("Green2");															//Selects Green Window
		run("Median...", "radius=2 stack");												//Smooths the green window
		setSlice(nSlices/2);															//Moves to the middle slice
		resetMinAndMax;																	//Resets the Brightness/Contrast
		roiManager("Measure");															//Measures the ROIs from the ROI manager
			roiManager("Set Color", "Gray");
		roiManager("Set Line Width", 1);
		selectWindow("Green2");															//Selects the new Window
		run("From ROI Manager");														//Creates the coloured overlay from ROI manager 
		run("Flatten", "stack");														//Burns in the overlay into the image
		run("AVI... ", "compression=JPEG frame=10 save=["+resultsDir+windowtitlenoext+"_Overlay_Green2.avi]");	//Saves time-series as an AVI with multi-coloured overlays of ROIs
		saveAs("Tiff", resultsDir+ windowtitle + "_OverlayStack.tif");					//Saves a .tif stack of image with overlays.


		selectWindow(windowtitle);															//Selects Green Window
		run("Median...", "radius=2 stack");												//Smooths the green window
		setSlice(nSlices/4);															//Moves to the middle slice
		Stack.setChannel(1);
		run("Enhance Contrast", "saturated=0.15");
		Stack.setChannel(2);
		run("Enhance Contrast", "saturated=0.15");
		roiManager("Measure");															//Measures the ROIs from the ROI manager
		roiManager("Set Color", "Gray");
		roiManager("Set Line Width", 1);
		
		run("From ROI Manager");														//Creates the coloured overlay from ROI manager 
		run("Flatten", "stack");														//Burns in the overlay into the image
		run("AVI... ", "compression=JPEG frame=10 save=["+resultsDir+windowtitlenoext+"_Overlay_Merged.avi]");	//Saves time-series as an AVI with multi-coloured overlays of ROIs
		saveAs("Tiff", resultsDir+ windowtitle + "Merged_OverlayStack.tif");					//Saves a .tif stack of image with overlays.





		//Saving out files
		selectWindow("Green-Mask");														//Selects the Green Mask Image
		saveAs("Tiff", resultsDir+ windowtitlenoext + "Green-Mask.tif");				//Saves image to results directory
		close();																		//Closes the window
		roiManager("Save", resultsDir+ windowtitlenoext + "RoiSet.zip");				//Saves the ROIs into the results directory


		while (nImages>0) { 															//Looks for any residual open images
			selectImage(nImages); 														//Selects the open images
      		close(); 																	//Closes the images
      		} 
	}
	}

//Writes to log window script title and acknowledgement
print("\\Clear");
print("");
print("FIJI Macro: "+scripttitle);
print("Version: "+version+" Version Date: "+date);
print("ACRF: Cancer Biology Imaging Facility");
print("By Nicholas Condon (2019) n.condon@uq.edu.au");
print("");
print("Script Run Date: "+day+"/"+(month+1)+"/"+year+"  Time: " +hour+":"+min+":"+sec);
print("");
print("Working Directory Location: "+path);
print("Files Processed: "+i);
print("");
if (batch==1) {print("Batch Mode: ON");}
if (batch==0) {print("Batch Mode: OFF");}
if (Bleach==1) {print("Bleach correction Mode: ON");}
if (Bleach==0) {print("Bleach correction Mode: OFF");}
print("File extension used: " +ext);
print("");
print("Batch Completed");
print("Total Runtime was:");
print((getTime()-start)/1000); 

selectWindow("Log");					//Selects the Log window
saveAs("Text", resultsDir+"Log.txt");	//Saves the log window





//exit message to notify user that the script has finished.
title = "Batch Completed";
msg = "Put down that coffee! Your analysis is finished";
waitForUser(title, msg);  
