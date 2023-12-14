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

![]()<img src="./Scriptschnipsel_Testfall1.png" width="1500" height="450">

## Testfall1

![]()<img src="./Testfall1 .png" width="1500" height="450">
Wie auf dem Bild ersichtlich, wollten wir auf das File "test.sh" zugreifen was aber nicht ganz funktionierte.
Uns wurde nach der Abfrage des Pfads gefragt, ob wir sicher seien.
Der Fehler Lag im Script "initialize_wp.sh" Zeile,68. Es fehlten Anführungs- und Schlusszeichen beim Code ( mv "$PATH_APACHE" ).
Nach der änderung, verlief alles einwandfrei.
