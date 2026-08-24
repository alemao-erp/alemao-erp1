// Loader do ERP completo.
// Remove apenas as chaves temporárias usadas pela versão simplificada,
// preservando os dados do Supabase e a sessão normal do supabase-js.
try {
  localStorage.removeItem('erp_access_token');
  localStorage.removeItem('erp_user_email');
} catch (e) {}

import './app.js';
