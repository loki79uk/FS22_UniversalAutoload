To add the Ford truck that FSG was using on Middleburgh:

First download the mod if you don't already have it, but you MUST rename it from `OKUM_GMYK_FS22_64Ford_T850_Flatbed.zip` to `FS22_64Ford_T850_Flatbed_OKUM_GMYK.zip` so that it is loaded before UAL.

Then add the following to your user mod settings file in the <vehicleConfigurations> section:

		<vehicleConfiguration configFileName="FS22_64Ford_T850_Flatbed_OKUM_GMYK/1964Ford.xml">  
			<loadingArea offset="0.000 1.285 -1.750" width="2.45" height="1.5" length="3.2" baleHeight="1.85"/>
			<options enableRearLoading="true" enableSideLoading="true"/>
		</vehicleConfiguration>

The user config file can be found in:
"..\Documents\My Games\FarmingSimulator2022\modSettings\UniversalAutoload.xml"
