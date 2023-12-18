# Introduction

Hier werden wir alle unsere Testfälle dokumentieren und schildern, die wir vorgenommen haben, um die Wordpress Installation möglichst automatisiert durchzuführen und ein funktionierendes Script abgeben zu können.

# Members

Jason Norde, Ariona Elshani, Céline König

# Instructions/Description Scripts

## Bash Script

Unser erstelltes Bash-Script erstellt eine EC2-Instanz in AWS und installiert Wordpress darauf. Im selben Script wird eine zweite Instanz konfiguriert, welche haupsächlich dazu dient die Datenbank von Wordpress isoliert von der VM wo Wordpress läuft zu haben.

## Apache.txt

Diese Datei wird benötigt um bei der Konfiguration der EC2 Instanz, die Installation des Apache-Webservers direkt mitzugeben. 

# Testing 

## Testfall Codeschnipsel apache.txt
- Testzeitpunkt: 13.12.23
- Testperson: Céline König

Im anfolgenden Screenshot ist ein Codeschnipsel des ersten Entwurfs des `initialize_instances.sh` Scripts zusehen. Wobei ich testen wollte, ob sich in diesem Abschnitt ein Fehler eingeschlichen hat, weil er für mich (Céline) etwas komplexer zzum zusammenstellen war.

![]()<img src="./Scriptschnipsel_Testfall1.png" width="1200" height="400">






In diesem Ausschnit der Shell ist ersichtlich, dass ich den Schnipsel in ein seperates Script packte, weil es zu viel Aufwand wäre alles andere im Script als Kommentar zu hinterlegen. Ich vergab meinem User Ausführrechte, um das Script effektiv zu testen und startete einen ersten Versuch.
Ich erwartete, dass wenn ich den korrekten **absoluten Pfad** zu **apache.txt** angebe, dass dieses dann automatisch in den richtigen Ordner verschoben wird, um den restlichen Ablauf zu erleichtern. Es geschah allerdings nicht, egal welchen Pfad ich angab die Datei wurde nie verschoben und sprang immer direkt zum **else statement**.

![]()<img src="./Testfall1 .png" width="900" height="300">

Demnach suchte ich im Schnipsel den/die Fehler, welche ich nach kurzer Zeit fand, nämlich hab ich die double quotes um die Variablen vergessen, wodurch die Shell die Variablen womöglich anders interpretierte als eigentlich gewollt. Also setzte ich diese im **If-Statement** und nun trat auch dieser Schritt mal in Kraft.

Diesen Fehler hätte ich umgehen können, indem sich die Datei bereits im Ordner befindet wodurch ich mir ebenfalls einige Zeilen an Code und Zeit hätte sparen können. Jetzt sollten sich alle notwendigen Daten, die für die Initialisierung der Instanzen gebraucht werden im Ordner **ec2instances** befinden, der ohne Mühe für die Ausführung heruntergeladen und ausgeführt werden kann ohne eine Bestätigung des Pfades durch den User verlangen zu müssen.

## Fehlende Double Quotes
![]()<img src="./Testfall2.png" width="2104" height="69">
...

## Testfall3
![]()<img src="./Testfall3.png" width="900" height="300">
