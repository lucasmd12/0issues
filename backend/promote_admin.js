const mongoose = require('mongoose');
require('dotenv').config();

// Conectar ao MongoDB
mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/federacaomad', {
  useNewUrlParser: true,
  useUnifiedTopology: true,
});

const User = require('./models/User');

async function promoteUserToAdmin() {
  try {
    console.log('Conectando ao banco de dados...');
    
    // Buscar o usuário "idcloned"
    const user = await User.findOne({ username: 'idcloned' });
    
    if (!user) {
      console.log('Usuário "idcloned" não encontrado!');
      console.log('Criando usuário "idcloned" como admin...');
      
      const newUser = new User({
        username: 'idcloned',
        password: 'admin123', // Senha padrão - deve ser alterada
        role: 'ADM'
      });
      
      await newUser.save();
      console.log('Usuário "idcloned" criado com sucesso como admin!');
    } else {
      console.log(`Usuário encontrado: ${user.username} (role atual: ${user.role})`);
      
      // Promover para admin
      user.role = 'ADM';
      await user.save();
      
      console.log(`Usuário "${user.username}" promovido para admin com sucesso!`);
    }
    
    console.log('Operação concluída!');
    process.exit(0);
  } catch (error) {
    console.error('Erro:', error);
    process.exit(1);
  }
}

promoteUserToAdmin();

