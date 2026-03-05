const jwt = require('jsonwebtoken');

const authenticate = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization || req.headers.Authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res
        .status(401)
        .json({ success: false, message: 'Authentication required' });
    }

    const token = authHeader.split(' ')[1];

    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    req.user = {
      _id: decoded.userId,
      id: decoded.userId,
      role: decoded.role,
    };

    return next();
  } catch (error) {
    console.error('Auth error', error);
    return res
      .status(401)
      .json({ success: false, message: 'Invalid or expired token' });
  }
};

const authorize = (...allowedRoles) => (req, res, next) => {
  if (!req.user || !allowedRoles.includes(req.user.role)) {
    return res
      .status(403)
      .json({ success: false, message: 'Forbidden: insufficient permissions' });
  }

  return next();
};

module.exports = {
  authenticate,
  authorize,
};
