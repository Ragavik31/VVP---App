const dotenv = require('dotenv');
dotenv.config();

const app = require('./app');
const connectDB = require('./config/db');
const http = require('http');
const { Server } = require('socket.io');
const socketUtil = require('./utils/socket');

const port = process.env.PORT || 5000;

connectDB()
  .then(() => {
    const server = http.createServer(app);

    const io = new Server(server, {
      cors: {
        origin: '*',
        methods: ['GET', 'POST', 'PATCH']
      }
    });

    io.on('connection', (socket) => {
      console.log('Socket connected:', socket.id);
      socket.on('disconnect', () => {
        console.log('Socket disconnected:', socket.id);
      });
    });

    // expose io through util for controllers
    socketUtil.setIO(io);

    server.listen(port, '0.0.0.0', () => {
      console.log(`Server running on http://0.0.0.0:${port}`);
      console.log(`Access from phone using: http://10.76.214.48:${port}`);
    });

  })
  .catch(error => {
    console.error('Failed to start server', error);
    process.exit(1);
  });
