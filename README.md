# Introduction

In diesem Git-Repo befinden sich alle Dateien die benötigt werden, um AWS EC2-Instanzen starten zu lassen und dabei ein klassisches Worpress zu konfigurieren.  
Hinzu haben wir alle Testfälle sauber in einem Markdown-file dokumentiert. Dieses befindet sich im Ordner **documentation** unter dem Namen **testing-documentation.md**


# Overview

**ec2instances** -> Hier drin befinden sich alle Dateien die für die Automation von Wordpress in AWS benötigt werden. 

**documentation** -> Dieser Ordner enthält jegliche Informationen von unserer Dokumentation

**documentation/pictures** -> Hier drin befinden sich alle Scrennshots von verschiedenen Testfällen des Automationsprozesses

## Vorgehen

Für ein erfolgreiches Endergebnis von einer automatisierten AWS EC2 Initialisierung wird der ganze **ec2instances** Ordner benötigt. Hierfür kann folgender Befehl verwendet werden, um dieses Repo klonen zu können: ``


### Installation

Ist das Repo auf ihrem lokalen Rechner vorhanden, so muss in das korrekte Verzeichnis gewechselt und das **initialize-instances.sh** Bash-Script ausgeführt werden über folgenden Befehl: `./initalize-instances.sh`
Alles weitere wird vom Script ausgeführt.


## Ziel

Schlussendlich sollten einige Zeilen am Ende des Scripts ausgegeben werden, die verschiedene Verbindungsmöglichkeiten ausgeben, wie unteranderem die konfigurierte Worpress-Webseite.
