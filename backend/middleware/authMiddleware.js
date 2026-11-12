const jwt = require('jsonwebtoken');

function verifyToken(req, res, next) {
    const token = req.headers.authorization?.split(' ')[1];

    if (!token) {
        return res.status(401).json({
            message: 'Akses ditolak. Silakan login terlebih dahulu.'
        });
    }

    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        req.user = decoded;

        next();
    } catch (error) {
        return res.status(403).json({
            message: 'Token tidak valid atau sudah kedaluwarsa.'
        });
    }
}

function verifyAdmin(req, res, next) {
    if (req.user.role !== 'admin') {
        return res.status(403).json({
            message: 'Akses khusus Admin.'
        });
    }

    next();
}

module.exports = {
    verifyToken,
    verifyAdmin
};