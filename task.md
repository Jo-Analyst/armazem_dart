Atue como um desenvolvedor Sênior em Flutter e Arquitetura de Software. Preciso que você atualize o escopo do aplicativo de Controle de Almoxarifado multiplataforma (Android e Windows) utilizando SQLite.

### 1. Estrutura de Pastas e Padrão Exigido:
Organize estritamente o código em `lib/`:
- `core/database/database_helper.dart` -> Inicialização SQLite com suporte FFI para Windows e sqflite para Android.
- `core/locator/locator.dart` -> Injeção de dependência com GetIt.
- `models/` -> CategoryModel, ProductModel, MovementModel.
- `repositories/` -> CategoryRepository, ProductRepository, MovementRepository, BackupRepository.
- `controllers/` -> Gerenciamento de estado reativo utilizando `signals` (signals_flutter).
- `pages/` -> Telas do app organizadas em subpastas por módulo. Componentes customizados devem ficar dentro de `widgets/` no módulo específico da tela.

### 2. Regras de Negócio e Esquema do Banco de Dados:

Tabelas:
- categorias (id INTEGER PRIMARY KEY, nome TEXT UNIQUE)
- produtos (
    id INTEGER PRIMARY KEY AUTOINCREMENT, 
    nome TEXT NOT NULL, 
    categoria_id INTEGER NOT NULL,
    FOREIGN KEY (categoria_id) REFERENCES categorias (id) ON DELETE CASCADE
  )
- movimentacoes (
    id INTEGER PRIMARY KEY AUTOINCREMENT, 
    produto_id INTEGER NOT NULL, 
    tipo TEXT NOT NULL, -- 'ENTRADA' ou 'SAIDA'
    quantidade REAL NOT NULL, 
    unidade_medida TEXT NOT NULL, -- KG, UN, PCT, MALA, FARDO, CX, LT, OUTROS
    data_entrada TEXT NOT NULL, 
    data_saida TEXT, 
    observacao TEXT,
    FOREIGN KEY (produto_id) REFERENCES produtos (id) ON DELETE CASCADE
  )

Regras Importantes de Movimentação e Saldo:
- O Produto NÃO armazena quantidade física fixa nem unidade de medida; o saldo do produto é um cálculo dinâmico: Sum(Entradas) - Sum(Saídas).
- O cadastro de novos produtos deve permitir cadastrar ou selecionar a Categoria diretamente no formulário.
- A data de saída NÃO PODE ser inferior à data de entrada.
- Se o saldo do produto for 0, o sistema DEVE BLOQUEAR qualquer tentativa de registrar saída e exigir que o usuário faça um novo registro de entrada.
- Exemplo de cálculo: Entrou 10 KG de carne em 29/06/2026 e saiu 2 KG em 01/07/2026 -> Saldo = 8 KG.

### 3. Relatórios, Impressão e Compartilhamento:
- A tela de relatórios deve listar as entradas e saídas detalhadas.
- Permitir gerar e visualizar a lista em PDF para Impressão e Compartilhamento nativo no Android/Windows (use pacotes como `pdf` e `printing`).

### 4. Backup Automático, E-mail e Pacote de Arquivos:
- Substitua o `file_picker` pelo pacote `document_file_save_plus`.
- No primeiro acesso, o aplicativo deve solicitar e salvar o diretório local de destino do backup (usando `shared_preferences`). O usuário só informa o caminho uma única vez.
- O backup deve ser acionado automaticamente ao fechar a aplicação (usando AppLifecycleListener/WidgetsBindingObserver).
- O aplicativo deve exibir um indicador de progresso (LinearProgressIndicator ou Dialog) durante as ações de backup e restauração.
- Se houver conexão com a internet no momento da exportação do backup, envie uma cópia do arquivo .db compactado/anexado para um e-mail configurado (use `mailer` ou `flutter_email_sender`).

### 5. Transições e Diálogos:
- Transições de tela e diálogos suaves padronizadas via `AppRoutes`.

Por favor, forneça o `DatabaseHelper` atualizado e o `MovementModel` / `MovementRepository` adaptados para essa nova regra.