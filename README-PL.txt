==============================================================
  UNIVERSAL AUTOLOAD by Loki_79
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
