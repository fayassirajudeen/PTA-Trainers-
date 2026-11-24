module.exports = function handler(req, res) {
  const { SUPABASE_URL: url, SUPABASE_PUBLISHABLE_KEY: key } = process.env;
  res.setHeader('Cache-Control','no-store');
  if (!url || !key) return res.status(503).json({message:'Staff sign-in requires database configuration.'});
  res.json({url,key});
};
