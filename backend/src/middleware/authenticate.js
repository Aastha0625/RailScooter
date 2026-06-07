const {
  authClient,
  runWithUserClient,
} = require('../config/supabase');

async function authenticate(req, res, next) {
  const authorization = req.get('authorization') || '';
  const [scheme, accessToken] = authorization.split(' ');

  if (scheme?.toLowerCase() !== 'bearer' || !accessToken) {
    return res.status(401).json({ error: 'Bearer token required' });
  }

  try {
    const { data, error } = await authClient.auth.getUser(accessToken);
    if (error || !data.user) {
      return res.status(401).json({ error: 'Invalid or expired token' });
    }

    req.user = data.user;
    return runWithUserClient(accessToken, data.user, next);
  } catch (err) {
    return next(err);
  }
}

module.exports = { authenticate };
