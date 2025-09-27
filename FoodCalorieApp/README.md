# FoodCalorieApp

O aplicatie iOS stilata care iti permite sa fotografiezi ce mananci, iar un AI personalizat iti estimeaza caloriile.

## Caracteristici planificate
- Capturare foto cu camera (SwiftUI + AVFoundation)
- Procesare imagine si detectie alimente (Vision + modele ML personalizate)
- Engine de estimare calorica cu reguli nutritionale si modele statistice
- Jurnal mese si istoricul estimarilor
- Confidentialitate locala (on-device ML unde este posibil)

## Structura proiect
- FoodCalorieApp/ – codul aplicatiei (SwiftUI)
- AIEngine/ – engine-ul AI personalizat (procesare imagine, calcule calorice, modele)

## Cerinte
- Xcode 15+, iOS 16+
- Swift 5.9+

## Rulare
In Xcode: File > Open > selecteaza repository-ul (Package.swift suportat) si ruleaza pe simulator/dispozitiv.
