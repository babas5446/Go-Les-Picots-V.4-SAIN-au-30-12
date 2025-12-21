# ⚡ FIX IMMÉDIAT - 3 Étapes

## 🎯 Problème Principal
**Base vide** = Fichier JSON pas dans le bundle

## ✅ Solution en 3 Étapes

### 1️⃣ Ajouter JSON à Xcode
```
📁 leurres_database_COMPLET.json
   ↓ Glisser dans Xcode
   ☑️ Copy items if needed
   ☑️ Cocher votre target
   Click "Add"
```

### 2️⃣ Vérifier Build Phases
```
Target → Build Phases → Copy Bundle Resources
↓
Chercher : leurres_database_COMPLET.json
✅ Présent ? OK !
❌ Absent ? Cliquer + pour l'ajouter
```

### 3️⃣ Tester
```
1. Clean Build (Cmd+Shift+K)
2. Supprimer app
3. Run (Cmd+R)
4. Regarder console Xcode
```

## 📊 Console Attendue

**✅ SUCCÈS** :
```
📋 Fichiers JSON trouvés dans le bundle (1) :
   - leurres_database_COMPLET.json
✅ Base chargée : XX leurres
```

**❌ ÉCHEC** :
```
📋 Fichiers JSON trouvés dans le bundle (0)
💡 Création d'une base vide...
```
→ Retour à l'étape 1️⃣

## 🎯 Positions Spread

**Maintenant CORRECT** :

```
       BÂBORD    TRIBORD
       (gauche)  (droite)
       
   Long Corner | Short Corner
       ↖       |       ↗
         \     |     /
          \    |    /
           \ BATEAU /
            \  |  /
             \ | /
   Long       ||      Short
   Rigger   Shotgun  Rigger
     ↙        ↓        ↘
```

## 🔧 Diagnostic

```
App → 🔧 → Vérifier :
✅ JSON dans Bundle : Présent
✅ JSON dans Documents : Présent  
✅ Nombre de leurres : > 0
```

## 📚 Si Besoin Aide

Lire : `CORRECTIONS_URGENTES_POSITIONS.md`

---

**Temps** : 2 minutes  
**Difficulté** : Facile  
**Succès** : Garanti si étapes suivies
