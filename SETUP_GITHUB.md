# 🚀 Guía para Subir tu Proyecto a GitHub como Privado

## 📋 Pasos Manuales

### 1️⃣ Crea un Repositorio en GitHub

1. Ve a [github.com](https://github.com) e inicia sesión
2. Haz clic en el botón verde **"New"** (o el botón **"+"** → New repository)
3. Configura el repositorio:
   - **Repository name**: `nutricion_app` (o el nombre que prefieras)
   - **Description**: "Sistema de nutrición personalizada en Flutter"
   - **Visibilidad**: ✅ **Private** (importante - escoje privado)
   - ❌ NO marques "Add a README file" (ya lo tienes)
   - ❌ NO marques "Add .gitignore" (ya lo tienes)
   - ❌ NO marques "Choose a license" (por ahora)
4. Haz clic en **"Create repository"**

### 2️⃣ Copia la URL de tu Repositorio

Después de crear el repositorio, GitHub te mostrará una página con comandos.
**Copia la URL** que se verá así:
```
https://github.com/TU_USUARIO/nutricion_app.git
```
⚠️ Reemplaza `TU_USUARIO` con tu nombre de usuario

### 3️⃣ Ejecuta estos Comandos en tu Terminal

Abre tu terminal en la carpeta del proyecto (`C:\Users\DIEGO\Desktop\Flutter\`)

#### Paso 1: Verifica que estás en master
```bash
git branch
```
Debería mostrar `* master`

#### Paso 2: Agrega el repositorio remoto
```bash
git remote add origin https://github.com/TU_USUARIO/nutricion_app.git
```
⚠️ Reemplaza `TU_USUARIO` con tu usuario y `nutricion_app` si le diste otro nombre

#### Paso 3: Verifica el remoto
```bash
git remote -v
```
Debería mostrar la URL que agregaste

#### Paso 4: Sube tu código
```bash
git push -u origin master
```

**Si te pide autenticación:**
- GitHub ya NO acepta passwords normales
- Usa un **Personal Access Token** (PAT)
- Ve a GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
- Genera un nuevo token con permisos `repo`
- Úsalo como password cuando te lo pida

### 4️⃣ Verifica en GitHub

Ve a tu repositorio en GitHub y deberías ver todos tus archivos:
- ✅ README.md
- ✅ requerimientos.md
- ✅ nutricion_app/
- ✅ Todos tus commits

## 🔐 Autenticación con GitHub

### Opción A: Personal Access Token (Recomendado)

1. Ve a: [github.com/settings/tokens](https://github.com/settings/tokens)
2. Click en **"Generate new token (classic)"**
3. Configura:
   - **Note**: "NutricionApp Local Development"
   - **Expiration**: 90 días o más
   - **Scopes**: ✅ Marca `repo` (todos los permisos)
4. **Generate token**
5. **Copia el token** (solo lo verás una vez)
6. Úsalo como password cuando hagas `git push`

### Opción B: GitHub CLI

```bash
# Instalar GitHub CLI
gh auth login

# Ya está autenticado, ahora puedes hacer push
git push -u origin master
```

## ⚠️ Troubleshooting

**Error: "fatal: remote origin already exists"**
```bash
git remote remove origin
git remote add origin https://github.com/TU_USUARIO/nutricion_app.git
```

**Error: "repository not found"**
- Verifica que el repositorio se haya creado correctamente
- Verifica que pusiste "Private" en lugar de "Public"
- Verifica que el token tiene permisos de repo

**Error: "failed to push some refs"**
```bash
git pull origin master --allow-unrelated-histories
git push -u origin master
```

**Error de autenticación**
- Asegúrate de usar un Personal Access Token, no tu password
- Verifica que el token tiene expiración válida

## 📝 Siguiente Paso

Una vez que esté en GitHub:
1. Agrega una descripción al repositorio
2. Configura issues y pull requests si necesitas
3. Agrega colaboradores si trabajas en equipo
4. Considera agregar GitHub Actions para CI/CD

## 🆘 ¿Necesitas Ayuda?

Si tienes problemas, asegúrate de:
- ✅ Tener una cuenta de GitHub
- ✅ Estar logueado en GitHub
- ✅ Haber creado el repositorio como **PRIVATE**
- ✅ Tener un Personal Access Token válido

---

**¿Listo?** Crea el repositorio en GitHub y luego ejecuta los comandos de arriba! 🚀

