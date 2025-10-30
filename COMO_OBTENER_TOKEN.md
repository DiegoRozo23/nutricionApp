# 🔑 Cómo Obtener un Token de GitHub (Para Subir el Código)

## Paso 1: Crear el Repositorio en GitHub

1. Ve a **https://github.com**
2. Haz clic en el botón **"New"** (verde, arriba a la izquierda)
3. Nombre: `nutricion_app` (o el que prefieras)
4. **Importante**: Selecciona ✅ **PRIVATE**
5. NO marques nada más (README, .gitignore, license)
6. Haz clic en **"Create repository"**

## Paso 2: Generar un Personal Access Token

1. Ve a: **https://github.com/settings/tokens**
   - O: Ve a tu perfil → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Haz clic en **"Generate new token (classic)"**
3. Configura:
   - **Note**: "NutricionApp - Flutter Project"
   - **Expiration**: 90 days (o más)
   - **Scopes**: ✅ Marca la casilla **`repo`** (esto marcará todas las sub-casillas automáticamente)
4. Haz clic en **"Generate token"** (abajo de la página)
5. **¡COPIA EL TOKEN INMEDIATAMENTE!** (se verá así: `ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`)
6. Guárdalo en un lugar seguro, NO lo compartas

## Paso 3: Comandos para Ejecutar

### Primero: Crear el repositorio (manual en GitHub)
- ✅ Ya lo hiciste en el Paso 1

### Segundo: Darme la información

Necesito que me digas:
1. **Tu nombre de usuario de GitHub**: ________________
2. **El nombre del repositorio**: ________________
3. **El token que generaste**: ________________

Con esa información, puedo ejecutar:

```bash
git remote add origin https://github.com/TU_USUARIO/nutricion_app.git
git push -u origin master
```

Y te pedirá las credenciales que tendrás que poner manualmente.

## ⚠️ Alternativa: Usar GitHub CLI

Si tienes **GitHub CLI** instalado:

```bash
# Verificar si está instalado
gh --version

# Si no está instalado, instálalo desde:
# https://cli.github.com/

# Autenticarse
gh auth login

# Crear el repositorio PRIVADO desde la CLI
gh repo create nutricion_app --private --source=. --remote=origin --push
```

Este comando:
- ✅ Crea el repositorio en GitHub
- ✅ Lo marca como PRIVADO
- ✅ Lo vincula a tu repo local
- ✅ Sube todo el código automáticamente

---

## 🤔 ¿Cuál Opción Prefieres?

**Opción A**: Me das los datos y yo ejecuto `git push`  
**Opción B**: Instalas GitHub CLI y ejecutas `gh repo create`  
**Opción C**: Haces el push manualmente con la guía que te di

¿Cuál prefieres?

