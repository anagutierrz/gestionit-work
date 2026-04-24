# Gestión IT Portal — Guía de despliegue completo
# Supabase + Netlify · Autenticación segura

## ──────────────────────────────────────────
## PASO 1: SUPABASE — Crear proyecto y base de datos
## ──────────────────────────────────────────

1. Ve a https://supabase.com y crea una cuenta gratuita
2. Clic en "New Project"
   - Nombre: gestion-it-portal
   - Password: genera una contraseña fuerte (guárdala)
   - Region: elige la más cercana (ej: US East)
3. Espera ~2 minutos a que el proyecto se inicialice

4. Ve a: Dashboard > SQL Editor > New query
5. Copia y pega TODO el contenido de supabase_schema.sql
6. Clic en "Run" — verás las tablas creadas en el panel izquierdo

7. Copia tus credenciales (las necesitarás después):
   - Project URL: Settings > API > Project URL
   - Anon Key: Settings > API > Project API Keys > anon/public


## ──────────────────────────────────────────
## PASO 2: SUPABASE — Configurar autenticación
## ──────────────────────────────────────────

1. Authentication > Settings:
   - Site URL: https://TU-SITIO.netlify.app (lo tendrás en el Paso 4)
   - Redirect URLs: añadir https://TU-SITIO.netlify.app/**

2. Authentication > Email Templates:
   - Personaliza el email de invitación con el logo de Gestión IT

3. Authentication > Providers:
   - Email: ✓ Habilitado
   - "Confirm email": ✓ Activado (seguridad adicional)
   - "Secure email change": ✓ Activado

4. IMPORTANTE — Para el primer admin, crea el usuario manualmente:
   Authentication > Users > "Invite user"
   - Ingresa tu correo institucional
   - El usuario recibirá un email para crear su contraseña
   
5. Después de crear el primer usuario, ve a SQL Editor y ejecuta:
   UPDATE public.profiles 
   SET role = 'admin' 
   WHERE email = 'TU_CORREO@gestionit.com';


## ──────────────────────────────────────────
## PASO 3: CONFIGURAR index.html
## ──────────────────────────────────────────

Abre index.html y busca la sección "CONFIGURACIÓN" (~línea 380):

  const SUPABASE_URL = 'https://TU_PROJECT_ID.supabase.co';
  const SUPABASE_ANON_KEY = 'TU_ANON_KEY_AQUI';

Reemplaza con tus valores reales:

  const SUPABASE_URL = 'https://abcdefghij.supabase.co';
  const SUPABASE_ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...';

⚠️ La anon key es pública por diseño — Supabase la usa con RLS para
   controlar qué puede hacer cada usuario autenticado. Es seguro.


## ──────────────────────────────────────────
## PASO 4: NETLIFY — Desplegar el portal
## ──────────────────────────────────────────

OPCIÓN A — Drag & Drop (más fácil, 2 minutos):
1. Ve a https://app.netlify.com
2. Crea cuenta gratuita
3. En el dashboard, arrastra la CARPETA gestion-it-portal al área de deploy
4. Netlify te asignará una URL: https://random-name.netlify.app
5. Puedes cambiar el nombre en: Site settings > Site name

OPCIÓN B — Git (recomendado para updates continuos):
1. Sube la carpeta a un repositorio GitHub
2. Netlify > "Import from Git" > selecciona el repositorio
3. Build settings: dejar todo vacío (es HTML estático)
4. Deploy — cada push a main se despliega automáticamente

Dominio personalizado (opcional):
- Netlify > Domain settings > Add custom domain
- Apunta tu DNS a Netlify siguiendo las instrucciones
- HTTPS se configura automáticamente (Let's Encrypt)


## ──────────────────────────────────────────
## PASO 5: CREAR USUARIOS ADICIONALES
## ──────────────────────────────────────────

Como Admin, desde el portal:
1. Ir a "Usuarios" en el sidebar
2. Clic en "Invitar usuario"
3. Ingresar correo, nombre y rol
4. El usuario recibe email con link para crear su contraseña

Roles disponibles:
- viewer:  Solo puede ver el dashboard y pipeline (sin crear/editar)
- manager: Puede crear y editar leads, ver todo el portal
- admin:   Acceso total + gestión de usuarios

Desde Supabase Dashboard (alternativa):
- Authentication > Users > Invite user
- Luego en SQL Editor asignar rol:
  UPDATE profiles SET role = 'manager' WHERE email = 'vendedor@gestionit.com';


## ──────────────────────────────────────────
## SEGURIDAD — Qué protege este sistema
## ──────────────────────────────────────────

✓ Contraseñas: nunca almacenadas en texto plano (bcrypt via Supabase)
✓ Sesiones: JWT con expiración automática
✓ Base de datos: Row Level Security — cada usuario solo ve lo que puede
✓ HTTPS: obligatorio en Netlify (certificado automático)
✓ Sin acceso sin login: toda la app requiere sesión activa
✓ Roles granulares: viewer / manager / admin
✓ Auditoría: tabla de actividades registra quién hace qué

Para seguridad adicional (producción):
- Activar 2FA en Supabase Dashboard > Auth > MFA
- Revisar logs de acceso: Supabase > Auth > Logs
- Configurar alertas de login sospechoso


## ──────────────────────────────────────────
## ARCHIVOS INCLUIDOS
## ──────────────────────────────────────────

gestion-it-portal/
├── index.html          ← Portal completo (login + dashboard + CRM)
├── supabase_schema.sql ← Schema de base de datos + RLS + triggers
└── SETUP.md            ← Esta guía


## ──────────────────────────────────────────
## COSTOS (plan gratuito)
## ──────────────────────────────────────────

Supabase Free:
- 500 MB base de datos
- 50,000 usuarios activos/mes
- 2 GB de storage
- Suficiente para 5–20 usuarios internos

Netlify Free:
- 100 GB de bandwidth/mes
- Deploys ilimitados
- HTTPS gratuito

→ Costo total: $0/mes para empezar
→ Upgrade a Supabase Pro ($25/mo) si necesitas más de 500MB o backups diarios
