# Introduction

In diesem Git-Repo befinden sich alle Dateien die benötigt werden, um AWS EC2-Instanzen starten zu lassen und dabei ein klassisches Worpress zu konfigurieren.  
Hinzu haben wir alle Testfälle sauber in einem Markdown-file dokumentiert. Dieses befindet sich im Ordner **documentation** unter dem Namen **testing-documentation.md**


# Overview

**ec2instances** -> Hier drin befinden sich alle Dateien die für die Automation von Wordpress in AWS benötigt werden. 

**documentation** -> Dieser Ordner enthält jegliche Informationen von unserer Dokumentation
# Instructions/Description Scripts

## Bash Script

Unser erstelltes Bash-Script erstellt eine EC2-Instanz in AWS und installiert Wordpress darauf. Im selben Script wird eine zweite Instanz konfiguriert, welche haupsächlich dazu dient die Datenbank von Wordpress isoliert von der VM wo Wordpress läuft zu haben. 

## Cloud-init

Die Konfiguration der Wordpress-Seite, wie auch der MariaDB-Datenbank erfolgt über sogenannte cloudconfig-files. Praktisch an jenen ist dass diese verschiedene Konfigurationen bei der Initialisierung der Instanz vornimmt. So kann man ohne extra eine Verbindung via SSH Konfigurationen automatisieren. 
In diesem Beispiel benötigen wir zwei cloud-config files. Einmal **cloudconfig-db** und **cloudconfig-web**.

### Cloudconfig-DB

Dieses Cloudconfig file führt die nötigen Konfigurationsschritte für die Initialisierung der Wordpress-DB aus. Darin werden beispielsweise das PW's des Root-Users gesetzt oder ein weiterer User erstellt, da es sicherheitstechnisch nicht sonderlich schlau ist alles über den Root-user zu erledigen.

### Cloudconfig-Web

Dieses Cloudconfig file führt die Schritte aus, die benötigt werden um die Wordpress-Seite zu erstellen. Sei dies der Webserver oder die Angabe der DB-Informationen. Hier wurde nur das Wordpress-package heruntergeladen, da die weiter benötigten Packages als Dependencies mit heruntergeladen werden, wie apache oder php.

## How to

Für ein erfolgreiches Endergebnis von einer automatisierten AWS EC2 Initialisierung wird der ganze **ec2instances** Ordner benötigt. Hierfür kann folgender Befehl verwendet werden, um dieses Repo klonen zu können: ``


### Installation

Ist das Repo auf ihrem lokalen Rechner vorhanden, so muss in das korrekte Verzeichnis gewechselt und das **initialize-instances.sh** Bash-Script ausgeführt werden über folgenden Befehl: `./initalize-instances.sh`
Alles weitere wird vom Script ausgeführt.

