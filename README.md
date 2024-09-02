# Annotation Tools

This repository contains MATLAB tools for annotating transverse MRI sections (such as those of the right forearm). The primary tool in this repository is the `annotateSlices.m` function, which provides an interactive interface for manually annotating MRI slices.

## Features

- **Interactive Annotation**: Click on a specific location in the MRI image to annotate it with the corresponding channel number.
- **Channel Selection**: Specify the channel number using a spinbox before placing the annotation.
- **Slice Navigation**: Use the up and down arrow keys to navigate through the slices.
- **Visual Feedback**: The annotated points are displayed on the image with the channel number superimposed.
- **CSV Export**: Save the annotations in a CSV file containing the channel, slice number, and X, Y coordinates.

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
* **`DefaultSliceSearchPath`**: (string) Default path used by the directory selection dialog. Default is `'C:/Data/Anatomy'`.
* **`ImageFilePrefix`**: (string) Prefix of the image file names in the folder. Default is `'R_Forearm_Section_'`.
* **`ImageFileType`**: (string) The file type/extension of the image files (e.g., `.png`, `.jpg`). Default is `'.png'`.
* **`MarkerSize`**: (double) Size of the markers used for annotations. Default is `16`.
* **`NumChannels`**: (integer) Number of channels to annotate. Default is `128`.
