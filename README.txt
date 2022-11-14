==============================================================
  UNIVERSAL AUTOLOAD (Loki_79)
==============================================================

  This specialisation is globally applied to all configured pallets and trailers.  There is no separate version of each vehicle to buy from the shop, and there is no configuration to select, it will just work on the supported vehicles.
  
  If you already own a configured vehicle in your save game, then the autoloading specialisation will be applied with the mod, i.e. there is no need to sell and buy each vehicle again.  It can also be removed form all vehicles by simply removing the mod, your trailer will not disappear.

  Base game supported trailers are defined in the file "SupportedVehicles.xml".  For some trailers only certain configurations are supported, such as the bale trailer configuration (see list below).  It is a requirement that the vehicle must have the "tension belts" specialisation.
  
  SUPPORTED TRAILERS:
   · Brantner DD 24073/2 XXL (bale trailer)
   · Bremer Transportwagen TP 500 S
   · BÖCKMANN MH-AL 4320/35
   · BÖCKMANN KK 3018/27 H
   · Demco Steel Drop Deck
   · Farmtech DPW 1800 (standard)
   · Fliegl DTS 5.9
   · KRONE Trailer Profi Liner
   · Kröger PWO 24
   · LODE KING Renown Drop Deck
   · Welger DK 115 (bale trailer)
   · Salek ANS-1900 (bale trailer)

  SUPPORTED VEHCILES:
   · Lizard Pickup 1986
   · Lizard Pickup 2017
   · Mahindra Retriever
   · JohnDeer XUV865M
   · Kubota RTV-XG850
   · Kubota RTV-X1140
   · Train (vehicle carriage)
   · Train (timber carriage)
   · Antonio Carraro Tigrecar 3200
   
  SUPPORTED FORESTRY VEHICLES/TRAILERS:
   · Anderson Group M160
   · Fliegl Timber Runner
   · Kesla 144ND
   · MAN TGX 26.640
   · ROTTNE F20D
   · PONSSE Bison Active Frame
   · KOMATSU 875

==============================================================
  USER OPTIONS: (SINGLE PLAYER ONLY)
==============================================================

	It is possible to override any default settings by editing the supplied settings file.  It will be created in the following location the first time the game is launched with the mod:  %userprofile%\Documents\My Games\FarmingSimulator2022\modSettings\UniversalAutoload.xml
	
	There is a new format with extra settings available.  You can copy this from inside the mod or if you simply delete your old settings file, then the new template will be created again the next time you run the game.

	A basic structure is supplied in the created file, and the usage should be (e.g.) as follows:
	
	<?xml version="1.0" encoding="utf-8" standalone="no"?>
	<universalAutoLoad showDebug="false" manualLoadingOnly="false" disableAutoStrap="false" pricePerPallet="0">

		<vehicleConfigurations showDebug="true">

			<vehicleConfiguration configFileName="FS22_20ftGooseneck/lizardgooseneck.xml">  
				<loadingArea offset="0.000 1.100 -0.300" width="3.00" height="2.20" length="7.50"/>
				<options enableRearLoading="true" enableSideLoading="true"/>
			</vehicleConfiguration>
			
		</vehicleConfigurations>
		
		<containerConfigurations>
	
			<containerConfiguration name="FS22_Seedpotato_Farm_Pack:PotatoBox" containerType="POTATOBOX"/>

		</containerConfigurations>
	</universalAutoLoad>
	
    GLOBAL CONFIGURATION PARAMETERS:
	[showDebug] - Used as an xml attribute in <universalAutoLoad> enables full debugging for all Autoload vehicle in the game (SP only)
	            - Used as an xml attribute in <vehicleConfigurations> enables full debugging for all Autoload vehicle defined in that section
	
	[manualLoadingOnly] - Setting this global attribute to true will prevent the autoloading button from functioning (default SHIFT-R).  This is intended as an "Autoload Light" option for players who would like to do most of the loading manually, but still benefit from the auto-stacking and unloading.  This setting will also enable rear loading and side loading on ALL TRAILERS regardless of the individual vehicle settings.
	
	[disableAutoStrap] - This setting can be applied globally in <universalAutoLoad> or to a specific vehicle in <options>, and will prevent the tension belts from automatically being applied after loading.
	
	[pricePerPallet] - This setting allows the user to apply a fee per pallet loaded to simulate a worker loading it for you.  Please be aware that the fee is still applied if you load by hand.  The default value is zero.
	
	(All other settings are the same as described below in the vehicles section)
	
==============================================================
  CONSOLE COMMANDS:
==============================================================
	ualImportUserConfigurations		- Force reload configurations from mod settings
	ualClearLoadedObjects			- Remove all loaded objects from current vehicle
	ualAddBales						- Fill current vehicle with specified bales
	ualAddPallets					- Fill current vehicle with random pallets (or specified by fillType)
	ualAddRoundBales_125			- Fill current vehicle with small round bales
	ualAddRoundBales_150			- Fill current vehicle with medium round bales
	ualAddRoundBales_180			- Fill current vehicle with large round bales
	ualAddSquareBales_180			- Fill current vehicle with small square bales
	ualAddSquareBales_220			- Fill current vehicle with medium square bales
	ualAddSquareBales_240			- Fill current vehicle with large square bales
	ualResetVehicles				- Reset all universal autoload vehicles
	ualCreateBoundingBox			- Create a bounding box around all loaded pallets (kind of pointless)
	
	The most useful console command is "ualImportUserConfigurations".  You can use in conjunction with the <showDebug="true"> property so that after editing the dimensions and values in your local user mod settings file, you can simply tab back to the game and use the console command to reload the configurations for pallets and vehicles to see the changes immediately without needing to restart the game.
	
	The other commands are just helpful to see how your loading settings will work with different pallets and bales.

==============================================================
  PALLETS/CONTAINERS:
==============================================================

  All base game pallets and containers (bigbags, IBCs, etc) are supported for autoloading.  This includes production pallets and any that can be purchased from the shop.  The method for identifying a pallet is to map the i3d file name to a predefined size.  The sizes for base game pallets are defined in the file "ContainerTypes.xml".
  
  If not already defined, the dimensions for mods are obtained from the object xml file.  Please make sure that the sizes listed are accurate and equal to (or slightly larger than) the collision box for your pallet model.  If any dimension given is too small (or much too large), then the pallets will not pack efficiently.

  PALLETS:
	<!-- <vehicle> -->
		<base>
			<typeDesc>$l10n_typeDesc_pallet</typeDesc>
			<filename>Vehicles/PotatoBoxes/PotatoBox.i3d</filename>
			<size width="1.850" length="1.200" height="1.100" />  <!-- DIMENSIONS OBTAINED FROM HERE -->
			<canBeReset>false</canBeReset>
			...
		</base>
	<!-- </vehicle> -->
	
  SQUAREBALES:
	<!-- <bale xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="../../../shared/xml/schema/bale.xsd"> -->
		<filename>$data/objects/squarebales/squarebale240/squarebale240.i3d</filename>
		<size isRoundbale="false" width="1.2" height="0.9" length="2.4"/>  <!-- DIMENSIONS OBTAINED FROM HERE -->
		<mountableObject triggerNode="0" forceAcceleration="7" forceLimitScale="1" axisFreeY="false" axisFreeX="false"/>
		...
	<!-- </bale> -->
	
  ROUNDBALES
	<!-- <bale xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="../../../shared/xml/schema/bale.xsd"> -->
		<filename>$data/objects/roundbales/roundbale180/roundbale180.i3d</filename>
		<size isRoundbale="true" width="1.2" diameter="1.80"/>  <!-- DIMENSIONS OBTAINED FROM HERE -->
		<mountableObject triggerNode="0" forceAcceleration="5" forceLimitScale="1" axisFreeY="false" axisFreeX="false"/>
		...
	<!-- </bale> -->

==============================================================
  VEHICLES/TRAILERS:
==============================================================
  There is a hard coded list of supported base game trailers, but the specialisation will also be applied to any correctly configured mod trailers.  There is no need to add any shapes or objects to your model.  All that is required is some additions to the vehicle xml.  (NOTE: the <vehicle> tag is not required since it is already the root element in the xml file)
  

  Add the following to your vehicle xml to use the specialisation in your mod trailer.  ALTERNATIVELY you can simply add the <vehicleConfiguration> to the local user mod settings file described earlier.
  	<!-- <vehicle> -->
	
		<universalAutoLoad>
			<vehicleConfigurations>
				<vehicleConfiguration>
					<loadingArea offset="0.000 1.050 -1.055" width="2.40" height="2.20" length="4.50"/>
				</vehicleConfiguration>
			</vehicleConfigurations>
		</universalAutoLoad>
		
	<!-- </vehicle> -->
	

  A more complicated version with different options for different configurations:
	<!-- <vehicle> -->
	
		<universalAutoLoad>
			<vehicleConfigurations>
				<vehicleConfiguration selectedConfigs="1">
					<loadingArea offset="0.000 1.050 -1.055" width="2.40" height="2.20" length="4.50"/>
					<options noLoadingIfUnfolded="true" isCurtainTrailer="false" enableRearLoading="false" showDebug="false"/>
				</vehicleConfiguration>
				<vehicleConfiguration selectedConfigs="2,3,4">
					<loadingArea offset="0.000 1.050 -1.055" width="2.40" height="2.20" length="4.50"/>
					<options noLoadingIfUnfolded="false" isCurtainTrailer="false" enableRearLoading="false" showDebug="false"/>
				</vehicleConfiguration>
			</vehicleConfigurations>
		</universalAutoLoad>
		
	<!-- </vehicle> -->


  CONFIGURATION PARAMETERS:
    [selectedConfigs] - The index (or comma separated indexes) for configurations autoloading will be applied to (see useConfigName for more details).  Use the index corresponding to the order in which the configurations were defined.  If this parameter is not provided, autoloading will be applied to all configurations.
	
    [useConfigName] - Specific configuration to be used as the configuration referred to by 'selectedConfigs'.  If no value is supplied, then the default is to use any detected configuration sets, or a configuration name of "design" otherwise.

  OPTIONS:
    [noLoadingIfFolded] - If true this parameter will prevent loading when the trailer is folded.  It will also prevent loading while it is folding or unfolding.  Use this if the loading area is only valid for the unfolded state.
	
    [noLoadingIfUnfolded] - If true this parameter will prevent loading when the trailer is unfolded.  It will also prevent loading while it is folding or unfolding.  Use this if your unfolded trailer is not level or if the folding animation somehow blocks the loading area.
	
    [noLoadingIfCovered] - If true this parameter will prevent loading when the trailer is covered.  Use this if the loading area is only valid for the uncovered state.
	
    [noLoadingIfUncovered] - If true this parameter will prevent loading when the trailer is unfolded.  Use this if the loading area is only valid for the covered state.

    [isBoxTrailer] - This is an option designed for any trailers with rear doors that are opened via the unfolding action.  If true the autoloading script will enable/disable loading according to the noLoadingIfFolded or noLoadingIfUnfolded (one of these two options MUST be supplied).
	
	[isLogTrailer] - This is an option designed for forestry/logging trailers that should only be used to load logs. Logs will be dropped in from above the loading volume until the trailer is full, so it should only be used on trailers with 'sides' to contain the logs.  Most loading options (e.g. selection of container type, material type, etc.) will be ignored for log trailers.
	
	[isBaleTrailer] - This is an option designed for bale trailers that would typically be used to load bales rather than pallets. There will be a key binding available to toggle a "Bale Collection Mode" where bales will automatically be loaded whenever they are detected.  Due to issues with movement, bales remain in a "not added to physics" state until the bale collection mode is exited, or if the game is saved.
	
	[isCurtainTrailer] - This is an option specifically designed for the KRONE Profi Liner curtain trailer.  If true the autoloading script will detect the correct load side when open IF the tipSide.animation.name contains the string "Left" or "Right". Where:	tipSide = self.spec_trailer.tipSides[self.spec_trailer.currentTipSideIndex] and self.spec_trailer.tipState == 2

    [enableRearLoading] - This is also designed for the KRONE Profi Liner curtain trailer, but can be applied to any trailer where automatic loading is required.  A pallet trigger is created at the rear of the trailer, and will load any valid objects detected here that are dynamically mounted to another vehicle (e.g. a forklift).
	
    [enableSideLoading] - This is designed for any trailer where automatic loading is required.  A pallet trigger is created at either side of the trailer, and will load any valid objects detected here that are dynamically mounted to another vehicle (e.g. a forklift).
	
	[rearUnloadingOnly] - If true the vehicle will use the rear unloading zone only (not side zones)
	
	[frontUnloadingOnly] - If true the vehicle will use the front unloading zone only (not side zones)
	
	[horizontalLoading] - If true the vehicle will start with horizontal loading enabled.  The state can still be toggled if key is bound, and the saved state will be loaded each time.
	
	[disableAutoStrap] - If true this parameter will disable the automatic application of tension belts after loading
	
	[disableHeightLimit] - If true this parameter will disable the density based stacking height limit - use with caution, especially on vehicles with a narrow wheel base
	
	[zonesOverlap] - Flag to identify when the loading areas overlap each other so that the calculated loading patterns do not intersect
	
    [showDebug] - This option will enable a graphical debugging display for the specific trailer.  It shows the loading triggers, unloading triggers, player trigger, rear loading trigger (if enabled) and detected pallet dimensions.  The detected pallets are also colour coded depending if they are valid for loading/unloading.

		
  LOADING AREA:
	The loading area must be defined slightly smaller than the available volume.  Pallets should fit inside this defined volume without clipping any part of the model.
	
	width  - The width (X dimension) of the loading area
	height - The height (Y dimension) of the loading area
	length - The length (Z dimension) of the loading area
	offset - The offset to the defined loading area from the vehicle root node
	baleHeight - Alternative height of the loading area to be used for BALES only

   TIP: To measure the loading area parameters in the GIANTS Editor
   · Create a unit cube and set "Translate Y" = 0.5
   · "Freeze Transformations" with default options (reference node should move to centre of lower face)
   · Use "Interactive Placement" to set the height
        - Ctrl+B with the box selected
        - Left-click on the bed of the trailer
        - Manually set both X and Z coordinates back to zero
   · Adjust Scale (X,Y,Z) and Translate Z (if required) to position and scale the loading area
   · Copy those values into the vehicle xml using the format:
    <loadingArea offset="offsetX offsetY offsetZ" width="scaleX" height="scaleY" length="scaleZ"/>
   · Delete the shape or close without saving (we ONLY need the values)
