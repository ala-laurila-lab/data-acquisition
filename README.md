# Data Acquisition Toolbox

Data Acquisition customized from [Symphony](http://symphony-das.github.io/) for performing Multi electrode patch clamp recordings.

It uses [ToolboxToolbox](https://github.com/ToolboxHub/ToolboxToolbox) for dependency management

### Installation

1. Download and install ToolboxToolbox from above link
2. Download the [startup.m](https://gist.github.com/ragavsathish/e4e58150c8a6c8ffe95b0ef632715fbe) and save it in MATLAB user path.
3. git clone  `https://github.com/Schwartz-AlaLaurila-Labs/data-acquisition.git` into  `projects/data-acquistion`
4. To update `tbUseProject('data-acquisition')`

### Folder organization

1. Like symphony, it follows maven style folder organization
2. All the dependency goes in to .lib folder

### Usage

1. Add the `src\main\matlab` and `.lib\sa-labs-extension\src\main\matlab` to symphony class path settings
2. Add [symphony_startup.m](./src/main/matlab/symphony_startup.m) and [symphony_cleanup.m](./src/main/matlab/symphony_cleanup.m) to symphony startup and clean up settings
3. Restart the Symphony

### Matlab dependencies

	Dependency hierarchy
		|____ app-toolboxes
		|		|____ mdepin (Matlab dependency injection framework) 
		|		|____ appbox (Model view presenter based user interface)
		|		|____ Java Table Wrapper
		|		|____ Property Grid	 
		|		|____ Matlab tree data structure  
		|		|____ Jsonlab 
		|		|____ Logging for Matlab		
		|		|____ Matlab Query (LINQ style query processor)		 
		|
		|____ sa-labs-extension (Stimulus protocols, common rig and device configurations)
		|		|____ Symphony2 & Stage VSS (run time dependency)
		|				|___ appbox 
		|				
		|___ sa-labs-analysis-core
		|		|____ app-toolboxes							
		|
		|____ matlab-lcr (Light crafter c++ bindings for Matlab)
		|
		|____ calibration-module (Stimulus calibration toolbox)
				|___ Matlab persistence architecture (ORM based persistence architecture)

