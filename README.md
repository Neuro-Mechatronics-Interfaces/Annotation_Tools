# Annotation Tools

This repository contains MATLAB tools for annotating transverse MRI sections (such as those of the right forearm). The primary tool in this repository is the `annotateSlices.m` function, which provides an interactive interface for manually annotating MRI slices.

## Features

- **Interactive Annotation**: Click on a specific location in the MRI image to annotate it with the corresponding channel number.
- **Channel Selection**: Specify the channel number using a spinbox before placing the annotation.
- **Slice Navigation**: Use the up and down arrow keys to navigate through the slices.
- **Visual Feedback**: The annotated points are displayed on the image with the channel number superimposed.
- **Table Export**: Save the annotations in a spreadsheet file containing the original and re-mapped channel numbers, associated section/slice index, and X/Y pixel coordinates (5 columns). Each column is a numeric `double` in the MATLAB interface.

## File Structure
- **annotateSlices.m**: The main MATLAB function providing the annotation interface.
- **README.md**: This documentation file.

## Usage
### Syntax ###
```matlab
    annotateSlices(folderPath);
    fig = annotateSlices(folderPath, 'Name', value, ...);
```  
### Arguments ###  
*  **`folderPath`**: (Optional) The path to the folder containing MRI slice images. 
   + If not provided, a directory selection dialog will open. Default is an empty string.  

### Options ###  
* **`CData`**: (numeric matrix) Custom color data for channels, with each row representing RGB values. If not provided, a default colormap (`winter`) is used.
* **`ChannelMap`**: (1 x nChannels integer array). Can be specified as a `1 x options.NumChannels` integer array mapping the sample rows (channels) read from the device to a grid or other arranged ordering as-desired. Default value is `[]`; in this case, the map becomes `1:options.NumChannels` (see `NumChannels` descriptor below). 
* **`ConfigOut`**: (string) The default save name for output file. The actual file name option can be adjusted in the 'Save As...' dialog when you click `Save` in the interface. Default value is 'annotations.csv'. 
* **`DefaultSliceSearchPath`**: (string) Default path used by the directory selection dialog. Default is `'C:/Data/Anatomy'`.
* **`ImageFilePrefix`**: (string) Prefix of the image file names in the folder. Default is `'R_Forearm_Section_'`.
* **`ImageFileType`**: (string) The file type/extension of the image files (e.g., `.png`, `.jpg`). Default is `'.png'`.
* **`MarkerSize`**: (double) Size of the markers used for annotations. Default is `8`.
* **`NumChannels`**: (integer) Number of channels to annotate. Default is `64`.
* **`NumChannelsPerArc`**: (integer) Number of channels to add along arc when holding `shift` while clicking on image to draw arc of channel/points. Default is `8`.  
* **`SliceOffset`**: Sets the slice offset that should be added for all slices in the image dataset. Default value is empty (`[]`); with this setting, it attempts to guess the slice offset based on matching to a numeric part of the image section name (i.e. if you have files like R_Forearm_Section_105.png, R_Forearm_Section_106.png, ... then it will detect offset as 104). 

### Interface ###  
* To adjust the slice (image) shown for associating a channel location, use the `up-arrow` or `w` keys to increase to the next slice index, or the `down-arrow` or `s` keys to decrease to the previous slice index.  
  + All incrementing operations are modulo so if you are at the first slice and decrease you'll loop back to the final slice.  
* To specify the location of a channel in the current slice, left click the desired pixel. Adding a channel will auto-increment to the next channel, as indicated by the spinbox on the right and the progress bar at the top.  
  + To move to an arbitrary channel, you can either manually input it in the spinbox; or
  + Press the `right-arrow` or `d` keys to increase the channel, or `left-arrow` or `a` keys to decrease the channel; or
  + Click to the desired channel along the length of the progress-bar at the top. 
* To specify the location of multiple channels (for example, all channels belonging to a grid column placed along a given section), hold down the left `shift` key. The cursor will change to a cross-hair. You will now click three times:  
  1. First click sets the beginning of the channel set.  
  2. Second click sets the end of the channel set.  
  3. Final click sets the control point dictating how the curve will bend.  
* The interface stores `UNDO` information for exactly one `UNDO` operation. To reset to the previous state, you can hold `CTRL` while pressing `z`.  

When you are done adding all channels, the progress bar at the top should be fully colored (indicating that all channels have been placed). Click the `Save` button (bottom-right) and specify the name and location where you want to save the output annotations table. 
