==============================================================
  UNIVERSAL AUTOLOAD (Loki_79)
==============================================================

  This specialisation is globally applied to all configured pallets and trailers.  There is no separate version of each vehicle to buy from the shop, and there is no configuration to select, it will just work on the supported vehicles.
  
  If you already own a configured vehicle in your save game, then the autoloading specialisation will be applied with the mod, i.e. there is no need to sell and buy each vehicle again.  It can also be removed form all vechicles by simply removing the mod, your trailer will not disappear.

  Base game supported trailers are defined in the file "SupportedVehicles.xml".  For some trailers only certain configurations are supported, such as the bale trailer configuration (see list below).  It is a requirement that the configuration includes the "tension belts" specialisation.
  
  SUPPORTED TRAILERS: Name (specialisation)
   · Brantner DD 24073/2 XXL (bale trailer)
   · Bremer Transportwagen TP 500 S
   · BÖCKMANN MH-AL 4320/35
   · Demco Steel Drop Deck
   · Farmtech DPW 1800 (standard)
   · Fliegl DTS 5.9
   · KRONE Trailer Profi Liner
   · Kröger PWO 24 (standard)
   · LODE KING Renown Drop Deck
   · Welger DK 115 (bale trailer)


==============================================================
  PALLETS/CONTAINERS:
==============================================================

  All base game pallets and containers (bigbags, IBCs, etc) are supported for autoloading.  This includes production pallets and any that can be purchased from the shop.  The method for identifying a pallet is to map the i3d file name to a predefined size.  The sizes for base game pallets are defined in the file "ContainerTypes.xml".  **Please NOTE that currently only square bales are supported** - I plan to include support for round bales and a work mode for collecting bales in a future release.
  
  MOD PALLETS:
  (A) If a mod pallet uses a base game i3d file, e.g. "bakeryBoxPallet.i3d", and the size has not been changed, then your mod pallet should work without any additional configuration.  If the size has changed, then you need to rename the i3d file (and see B).
  
  (B) If a mod file has a unique i3d file name, then the dimensions will be obtained from the object xml file.  Please make sure that the sizes listed are accurate and equal to (or slightly larger than) the collision box for your pallet model.  If any dimension given is too small (or much too large), then the pallets will not pack efficiently.

	<vehicle>
		<base>
			<typeDesc>$l10n_typeDesc_pallet</typeDesc>
			<filename>Vehicles/PotatoBoxes/PotatoBox.i3d</filename>
			<size width="1.850" length="1.200" height="1.100" />  <!-- DIMENSIONS OBTAINED FROM HERE -->
			<canBeReset>false</canBeReset>
			...
		</base>
	</vehicle>


==============================================================
  VEHICLES/TRAILERS:
==============================================================
  There is a hard coded list of supported base game trailers, but the specialisation will also be applied to any correctly configured mod trailers.  There is no need to add any shapes or objects to your model.  All that is required is some additions to the vehcile xml.
  

  Add the following to your xml to use the specialisation in your mod trailer:
	<vehicle>
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
	</vehicle>


  CONFIGURATION PARAMETERS:
    [selectedConfigs] - The index (or comma separated indexes) for configurations autoloading will be applied to.  Use the index corresponding to the order in which the configurations were defined.  If this parameter is not provided, autoloading will be applied to all configurations.

  OPTIONS:
    [noLoadingIfUnfolded] - If true this parameter will prevent loading if the trailer is folded.  It will also prevent loading while it is folding or unfolding.  Use this if your unfolded trailer is not level or if the folding animation somehow blocks the loading area.

    [isCurtainTrailer] - This is an option specifically designed for the KRONE Profi Liner curtain trailer.  If true the autoloading script will detect the correct load side when open IF the tipSide.animation.name contains the string "Left" or "Right". Where:
	tipSide = self.spec_trailer.tipSides[self.spec_trailer.currentTipSideIndex] and self.spec_trailer.tipState == 2

    [enableRearLoading] - This is also designed for the KRONE Profi Liner curtain trailer, but can be applied to any trailer where automatic loading is required.  A pallet trigger is created at the rear of the trailer, and will load any valid objects detected here that are dynamically mounted to another vehcile (e.g. a forklift).

    [showDebug] - This option will enable a graphical debugging display for the specific trailer.  It shows the loading triggers, unloading triggers, player trigger, rear loading trigger (if enabled) and detected pallet dimensions.  The detected pallets are also colour coded depending if they are valid for loading/unloading.
  
  LOADING AREA:
	The loading area must be defined slightly smaller than the available volume.  Pallets should fit inside this defined volume without clipping any part of the model.
	
	width  - The width (X dimension) of the loading area
	height - The height (Y dimension) of the loading area
    length - The length (Z dimension) of the loading area
	offset - The offset to the defined loading area from the vehicle root node

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


==============================================================
 TRANSLATION - PL by ELRICOFATAL
==============================================================


Ta modyfikacja jest globalnie stosowana do wszystkich skonfigurowanych palet i naczep. Nie ma oddzielnej wersji każdego pojazdu do kupienia w sklepie i nie ma konfiguracji do wyboru, będzie działać tylko na obsługiwanych pojazdach.
  
  Jeśli posiadasz już skonfigurowany pojazd w zapisanym stanie gry, wraz z modyfikacją zostanie zastosowana specjalizacja automatycznego ładowania, co oznacza, że nie ma potrzeby ponownego sprzedawania i kupowania każdego pojazdu. Można go również usunąć ze wszystkich pojazdów, po prostu usuwając mod, twoja przyczepa nie zniknie.

  Obsługiwane pojazdy z gry  są zdefiniowane w pliku „SupportedVehicles.xml”. W przypadku niektórych przyczep obsługiwane są tylko niektóre konfiguracje, takie jak konfiguracja przyczepy do bel (patrz lista poniżej). Wymagane jest, aby konfiguracja zawierała specjalizację „pasy napinające”.
  
  OBSŁUGIWANE PRZYCZEPY: Nazwa (specjalizacja)
   · Brantner DD 24073/2 XXL (przyczepa do bel)
   · Bremer Transportwagen TP 500 S
   · BÖCKMANN MH-AL 4320/35
   · Pokład zrzutowy ze stali Demco
   · Farmtech DPW 1800 (standard)
   · Fliegl DTS 5.9
   · KRONE Trailer Profi Liner
   · Kröger PWO 24 (standard)
   · Zrzut talii sławy LODE KING
   · Welger DK 115 (przyczepa do bel)

==============================================================
  PALETY/POJEMNIKI:
==============================================================

  Wszystkie palety i pojemniki z gry (bigbagi, IBC itp.) są obsługiwane przez skrypt. Obejmuje to palety produkcyjne i wszystkie, które można kupić w sklepie. Metodą identyfikacji palety jest odwzorowanie nazwy pliku i3d na predefiniowany rozmiar. Rozmiary palet z gry są zdefiniowane w pliku „ContainerTypes.xml”. **Proszę PAMIĘTAĆ, że obecnie obsługiwane są tylko bele kwadratowe** - Planuję włączyć obsługę bel okrągłych oraz tryb pracy do zbierania bel w przyszłej wersji.
  
  PALETY MODOWE:
  (A) Jeśli paleta modów używa pliku i3d z gry podstawowej, np. "bakeryBoxPallet.i3d", a rozmiar nie został zmieniony, to twoja paleta modów powinna działać bez dodatkowej konfiguracji. Jeśli rozmiar się zmienił, musisz zmienić nazwę pliku i3d (i patrz B).
  
  (B) Jeśli plik mod ma unikalną nazwę pliku i3d, wtedy wymiary zostaną uzyskane z pliku xml obiektu. Upewnij się, że podane rozmiary są dokładne i równe (lub nieco większe) od  kolizyji dla Twojego modelu palety. Jeśli któryś z podanych wymiarów jest za mały (lub znacznie za duży), to palety nie będą się sprawnie pakować.

        <vehicle>
		<base>
			<typeDesc>$l10n_typeDesc_pallet</typeDesc>
			<filename>Vehicles/PotatoBoxes/PotatoBox.i3d</filename>
			<size width="1.850" length="1.200" height="1.100" />  <!-- Rozmiary Podawać Tutaj! -->
			<canBeReset>false</canBeReset>
			...
		</base>
	</vehicle>

==============================================================
  POJAZDY/PRZYCZEPY:
==============================================================
  Istnieje zakodowana na stałe lista obsługiwanych naczep z gry, ale specjalizacja zostanie również zastosowana do wszystkich poprawnie skonfigurowanych modów. Nie ma potrzeby dodawania do modelu żadnych kształtów ani obiektów. Wszystko, co jest wymagane, to kilka dodatków do pliku xml pojazdu.
  

  Dodaj następujące elementy do swojego pliku xml, aby użyć specjalizacji w swoim zwiastunie modów:
  
	<vehicle>
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
	</vehicle>


==============================================================
  PARAMETRY KONFIGURACJI:
==============================================================
PARAMETRY KONFIGURACJI:
    [selectedConfigs] — zostanie zastosowany indeks (lub indeksy oddzielone przecinkami) do automatycznego ładowania konfiguracji. Użyj indeksu odpowiadającego kolejności, w jakiej konfiguracje zostały zdefiniowane. Jeśli ten parametr nie zostanie podany, automatyczne ładowanie zostanie zastosowane do wszystkich konfiguracji.

  OPCJE:
    [noLoadingIfUnfolded] — Jeśli true ten parametr uniemożliwi załadunek, jeśli naczepa jest złożona. Uniemożliwi również ładowanie podczas składania lub rozkładania. Użyj tego, jeśli twoja rozłożona naczepa nie jest wypoziomowana lub jeśli animacja składania w jakiś sposób blokuje obszar załadunku.

    [isCurtainTrailer] - Jest to opcja specjalnie zaprojektowana dla naczepy kurtynowej KRONE Profi Liner. Jeśli prawda, skrypt automatycznego ładowania wykryje poprawną stronę ładowania po otwarciu JEŚLI tipSide.animation.name zawiera ciąg „Left” lub „Right”. Gdzie:
tipSide = self.spec_trailer.tipSides[self.spec_trailer.currentTipSideIndex] i self.spec_trailer.tipState == 2

    [enableRearLoading] - Jest to również przeznaczone do naczepy kurtynowej KRONE Profi Liner, ale może być zastosowane do dowolnej naczepy, w której wymagany jest automatyczny załadunek. Z tyłu przyczepy tworzony jest wyzwalacz palety, który ładuje wszystkie wykryte tutaj prawidłowe obiekty, które są dynamicznie montowane do innego pojazdu (np. wózka widłowego).

    [showDebug] - Ta opcja włączy graficzne wyświetlanie debugowania dla określonego obiektu. Pokazuje obszar ładowania, obszar rozładowywania, obszar gracza, obszar tylnego załadunku (jeśli jest włączony) i wykryte wymiary palet. Wykryte palety są również kodowane kolorami w zależności od tego, czy nadają się do załadunku/rozładunku.
  
  STREFA ZAŁADUNKU:
Obszar załadunku musi być nieco mniejszy niż dostępna objętość. Palety powinny mieścić się w tej określonej objętości bez przycinania jakiejkolwiek części modelu.

szerokość - szerokość (wymiar X) obszaru załadunku
wysokość - wysokość (wymiar Y) powierzchni ładunkowej
    długość - długość (wymiar Z) powierzchni ładunkowej
offset — przesunięcie do zdefiniowanego obszaru załadunku od środka głównego pojazdu

   WSKAZÓWKA: Aby zmierzyć parametry obszaru załadunku w GIANTS Editor
   · Utwórz kostkę  i ustaw "Translate Y" = 0,5
   · "Freeze Transformations" z domyślnymi opcjami (obszar odniesienia powinien przesunąć się na dolny środek)
   · Użyj opcji „Interactive Placement”, aby ustawić wysokość
        - Ctrl+B z zaznaczonym polem
        - Kliknij lewym przyciskiem na obszar załadunku przyczepy
        - Ręcznie ustaw współrzędne X i Z z powrotem na zero
   · Dostosuj Skalę (X,Y,Z) i Przesuń Z (jeśli to konieczne), aby ustawić i przeskalować obszar załadunku
   · Skopiuj te wartości do pliku XML pojazdu, używając formatu:
    <loadingArea offset="offsetX offsetY offsetZ" width="scaleX" height="scaleY" length="scaleZ"/>
   · Usuń Kwadrat lub zamknij bez zapisywania (potrzebujemy TYLKO wartości)
