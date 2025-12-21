# 🎣 Guide d'Import Rapide - 63 Leurres

## 🚀 3 Solutions Rapides pour Intégrer vos Leurres

Fini la saisie manuelle ! Voici 3 méthodes efficaces pour ajouter vos 63 leurres en quelques minutes (ou secondes).

---

## ⚡️ Solution 1 : Import Immédiat (RECOMMANDÉ)

**Temps requis : 1 seconde**

### Avantages
- ✅ **Le plus rapide** : 1 clic et c'est fait
- ✅ **Aucune préparation** nécessaire
- ✅ **63 leurres pré-configurés** pour la Nouvelle-Calédonie
- ✅ **Tous les champs remplis** automatiquement

### Comment faire
1. Ouvrez l'app **Go Les Picots**
2. Allez dans **"Ma Boîte"**
3. Cliquez sur le menu **⋯** en haut à droite
4. Sélectionnez **"Import rapide (63 leurres)"**
5. Choisissez **"Import immédiat"**
6. Cliquez sur **"Importer"**
7. **C'est fait ! ⚡️**

### Ce qui est inclus
- 20 poissons nageurs (Rapala, Yo-Zuri, Halco, Nomad...)
- 10 poppers & stickbaits
- 13 jigs métalliques
- 8 cuillers (Mepps, Blue Fox...)
- 12 leurres souples

### Données pré-configurées
Chaque leurre contient :
- ✓ Nom, marque, modèle
- ✓ Type de leurre et technique de pêche
- ✓ Longueur et poids
- ✓ Couleurs (principale + secondaire)
- ✓ Profondeur de nage (si traîne)
- ✓ Vitesse de traîne recommandée
- ✓ **Zones adaptées calculées automatiquement**
- ✓ **Espèces cibles déduites**
- ✓ **Positions spread optimales**
- ✓ **Conditions optimales**

---

## 📊 Solution 2 : Import CSV (Excel/Numbers)

**Temps requis : 10-15 minutes**

### Avantages
- ✅ **Vos propres leurres** : personnalisez tout
- ✅ **Interface familière** : Excel, Numbers ou Google Sheets
- ✅ **Modification facile** : copier/coller, formules
- ✅ **Réutilisable** : gardez votre fichier pour plus tard

### Comment faire

#### Étape 1 : Créer le fichier Excel/Numbers

Créez un tableau avec ces colonnes (dans cet ordre) :

| nom | marque | modele | type | technique | longueur | poids | couleur1 | couleur2 | notes |
|-----|--------|--------|------|-----------|----------|-------|----------|----------|-------|
| Rapala X-Rap 10 | Rapala | X-Rap | poissonNageur | traine | 10 | 13 | bleuArgente | blanc | Polyvalent |
| Mepps Aglia 3 | Mepps | Aglia | cuiller | lancer | 6 | 9 | argente | | |

#### Étape 2 : Remplir les données

**Colonnes obligatoires :**
- `nom` : Nom du leurre
- `marque` : Marque
- `type` : Type de leurre (voir valeurs ci-dessous)
- `technique` : Technique de pêche (voir valeurs ci-dessous)
- `longueur` : En centimètres
- `couleur1` : Couleur principale

**Colonnes facultatives :**
- `modele` : Modèle spécifique
- `poids` : En grammes
- `couleur2` : Couleur secondaire
- `notes` : Remarques personnelles

#### Étape 3 : Valeurs acceptées

**Types de leurre :**
- `poissonNageur`
- `cuiller`
- `leurresSouples`
- `jigMetallique`
- `poppers`
- `stickbait`
- `jerkbait`

**Techniques de pêche :**
- `traine`
- `lancer`
- `jigging`
- `traineLegers`
- `poppers`

**Couleurs :**
- `bleuArgente`, `vert`, `orange`, `rose`, `rouge`
- `jaune`, `noir`, `blanc`, `argente`, `dore`
- `naturel`, `multicolore`

#### Étape 4 : Exporter en CSV

**Excel :**
1. Fichier → Enregistrer sous
2. Format : **CSV UTF-8 (délimité par des virgules)**
3. Enregistrer

**Numbers :**
1. Fichier → Exporter vers → CSV
2. Encodage de texte : **UTF-8**
3. Suivant → Exporter

**Google Sheets :**
1. Fichier → Télécharger → CSV

#### Étape 5 : Importer dans l'app

1. Transférez le fichier CSV sur votre iPhone/iPad
   - Via AirDrop
   - Via iCloud Drive
   - Via email
2. Dans l'app, allez dans **"Import rapide"**
3. Choisissez **"Import CSV"**
4. Cliquez sur **"Choisir le fichier CSV"**
5. Sélectionnez votre fichier
6. L'app importe automatiquement tous vos leurres

### Exemple de fichier CSV complet

```csv
nom,marque,modele,type,technique,longueur,poids,couleur1,couleur2,notes
Rapala X-Rap 10,Rapala,X-Rap,poissonNageur,traine,10,13,bleuArgente,blanc,Excellent pour le lagon
Rapala X-Rap 14,Rapala,X-Rap,poissonNageur,traine,14,22,bleuArgente,blanc,Passe et large
Yo-Zuri Crystal Minnow,Yo-Zuri,Crystal Minnow,poissonNageur,traine,11,14,argente,bleuArgente,Peu profond
Halco Laser Pro 190,Halco,Laser Pro,poissonNageur,traine,19,95,rose,blanc,Gros poissons
Mepps Aglia 2,Mepps,Aglia,cuiller,lancer,5,6,argente,,Lagon peu profond
Mepps Aglia 3,Mepps,Aglia,cuiller,lancer,6,9,argente,,Polyvalente
Williamson Speed Jig 60g,Williamson,Speed Jig,jigMetallique,jigging,10,60,argente,bleuArgente,Vertical
```

---

## 🔧 Solution 3 : Import JSON (Avancé)

**Temps requis : 15-20 minutes**

### Avantages
- ✅ **Format structuré** : précis et complet
- ✅ **Contrôle total** : tous les champs disponibles
- ✅ **Conversion automatique** : depuis d'autres sources
- ✅ **Backup facile** : format texte standard

### Comment faire

#### Étape 1 : Créer le fichier JSON

Le format JSON ressemble à ceci :

```json
[
  {
    "nom": "Rapala X-Rap 10",
    "marque": "Rapala",
    "modele": "X-Rap",
    "type": "poissonNageur",
    "technique": "traine",
    "longueur": 10,
    "poids": 13,
    "couleur1": "bleuArgente",
    "couleur2": "blanc",
    "profMin": 1.0,
    "profMax": 4.0,
    "vitesseMin": 4.0,
    "vitesseMax": 8.0,
    "notes": "Polyvalent pour le lagon"
  },
  {
    "nom": "Mepps Aglia 3",
    "marque": "Mepps",
    "type": "cuiller",
    "technique": "lancer",
    "longueur": 6,
    "poids": 9,
    "couleur1": "argente"
  }
]
```

#### Étape 2 : Champs disponibles

**Obligatoires :**
- `nom` : string
- `marque` : string
- `type` : string (voir liste)
- `technique` : string (voir liste)
- `longueur` : number (en cm)
- `couleur1` : string (voir liste)

**Facultatifs :**
- `modele` : string
- `poids` : number (en g)
- `couleur2` : string
- `profMin` : number (profondeur min en m)
- `profMax` : number (profondeur max en m)
- `vitesseMin` : number (vitesse min en nœuds)
- `vitesseMax` : number (vitesse max en nœuds)
- `notes` : string

#### Étape 3 : Convertir Excel en JSON

**Méthode 1 : Site web (csvjson.com)**
1. Exportez votre Excel en CSV
2. Allez sur https://csvjson.com
3. Collez votre CSV
4. Cliquez sur "Convert"
5. Copiez le JSON résultant

**Méthode 2 : Script Python (fourni)**
```bash
python3 convertir_json.py mes_leurres.csv
```

#### Étape 4 : Importer dans l'app

1. Dans l'app, allez dans **"Import rapide"**
2. Choisissez **"Import JSON"**
3. **Option A :** Collez votre JSON dans la zone de texte
4. **Option B :** Cliquez sur "Charger un fichier" et sélectionnez votre .json
5. Cliquez sur **"Importer les leurres"**

---

## 📋 Comparaison des Solutions

| Critère | Import Immédiat | CSV | JSON |
|---------|----------------|-----|------|
| **Rapidité** | ⭐️⭐️⭐️⭐️⭐️ (1 sec) | ⭐️⭐️⭐️ (15 min) | ⭐️⭐️ (20 min) |
| **Facilité** | ⭐️⭐️⭐️⭐️⭐️ | ⭐️⭐️⭐️⭐️ | ⭐️⭐️ |
| **Personnalisation** | ⭐️ | ⭐️⭐️⭐️⭐️⭐️ | ⭐️⭐️⭐️⭐️⭐️ |
| **Contrôle** | ⭐️ | ⭐️⭐️⭐️⭐️ | ⭐️⭐️⭐️⭐️⭐️ |
| **Recommandé pour** | Démarrage rapide | Vos propres leurres | Utilisateurs avancés |

---

## 🎯 Quelle Solution Choisir ?

### Choisissez **Import Immédiat** si :
- ✅ Vous voulez tester l'app rapidement
- ✅ Vous avez des leurres courants (Rapala, Mepps, Williamson...)
- ✅ Vous voulez 63 leurres tout de suite
- ✅ Vous ajusterez les détails plus tard

### Choisissez **CSV** si :
- ✅ Vous avez une liste Excel de vos leurres
- ✅ Vous voulez personnaliser tous les détails
- ✅ Vous êtes à l'aise avec Excel/Numbers
- ✅ Vous avez 15 minutes devant vous

### Choisissez **JSON** si :
- ✅ Vous avez déjà des données structurées
- ✅ Vous importez depuis une autre app
- ✅ Vous connaissez le format JSON
- ✅ Vous voulez un contrôle total

---

## 🛠️ Après l'Import

Une fois vos leurres importés, l'app calcule **automatiquement** :

1. **Contraste** : Naturel, Flashy, Sombre ou Contraste
2. **Zones adaptées** : Lagon, Récif, Passe, Large, DCP
3. **Espèces cibles** : Wahoo, Thon, Mahi-mahi, Barracuda...
4. **Positions spread** : Pour la traîne (si applicable)
5. **Conditions optimales** : Moment, état mer, turbidité

Vous pouvez ensuite :
- ✏️ **Modifier** chaque leurre individuellement
- 📸 **Ajouter des photos** (caméra, galerie ou URL)
- 🔍 **Filtrer et rechercher** dans votre collection
- 🎯 **Recevoir des suggestions** basées sur les conditions

---

## ❓ FAQ

### Q : Puis-je combiner plusieurs méthodes ?
**R :** Oui ! Vous pouvez importer les 63 leurres par défaut, puis en ajouter d'autres via CSV ou manuellement.

### Q : Les leurres importés peuvent-ils être modifiés ?
**R :** Absolument ! Tous les leurres sont modifiables après import.

### Q : Que se passe-t-il en cas d'erreur dans mon CSV/JSON ?
**R :** L'app affiche les lignes qui ont échoué. Les leurres valides sont quand même importés.

### Q : Puis-je supprimer tous les leurres et recommencer ?
**R :** Oui, dans "Ma Boîte", faites un swipe vers la gauche sur chaque leurre pour le supprimer.

### Q : Les photos sont-elles importées ?
**R :** Non, les photos doivent être ajoutées manuellement après l'import (via l'appareil photo, la galerie ou une URL).

### Q : Puis-je exporter mes leurres ?
**R :** Pas encore, mais cette fonctionnalité sera ajoutée dans une future mise à jour.

---

## 🎉 Prêt à Démarrer ?

1. Ouvrez **Go Les Picots**
2. Allez dans **"Ma Boîte"**
3. Menu **⋯** → **"Import rapide"**
4. **Choisissez votre méthode**
5. **C'est parti ! 🎣**

---

**Besoin d'aide ?** Consultez la documentation complète dans l'app ou contactez le support.
