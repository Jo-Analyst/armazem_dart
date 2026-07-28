Atue como um desenvolvedor Sênior Flutter e arquitetura de software. Preciso que você construa o código base para um aplicativo de Controle de Almoxarifado multiplataforma (Android e Windows) utilizando SQLite.

### 1. Arquitetura e Estrutura de Pastas Exigida:
Organize estritamente o projeto na pasta `lib/` seguindo a estrutura:
- `core/database/database_helper.dart` -> Inicialização do SQLite com sqflite_common_ffi para desktop (Windows) e sqflite para Android.
- `core/locator/locator.dart` -> Configuração do Service Locator usando GetIt.
- `models/` -> Classes Data/POCO com métodos `toMap` e `fromMap`.
- `repositories/` -> Camada de acesso direto ao SQLite (CRUD de Categorias, Produtos e Movimentações).
- `controllers/` -> Lógica de negócios e estado usando `signals` (signals_flutter).
- `pages/` -> Telas do aplicativo organizadas em subpastas por módulo. Quando a tela possuir componentes customizados, crie uma subpasta `widgets/` dentro do módulo correspondente.

### 2. Requisitos de Dados e Regras do Almoxarifado:
- Categoria: id, nome.
- Produto: id, nome, categoria_id, quantidade (REAL), unidade_medida (TEXT: UN, KG, PCT, FARDO, CX, LT, MALA, OUTROS).
- Movimentação: id, produto_id, tipo ('ENTRADA' | 'SAIDA'), quantidade (REAL), data (TEXT ISO8601), observacao (TEXT).

### 3. Gerenciamento de Estado (Signals):
Nos controllers, utilize `signal()` ou `listSignal()` para armazenar estados reativos e estados de carregamento/erro. Nas views, utilize `Watch()` ou `.watch(context)` do pacote `signals_flutter` para renderização reativa limpa.

### 4. Módulos / Telas Exigidas:
1. `pages/categories/` -> Gestão de categorias.
2. `pages/products/` -> Listagem e cadastro de produtos (com busca por nome e filtro por categoria).
3. `pages/movements/` -> Telas de Entrada e Saída de produtos no estoque (com validação de saldo negativo na saída).
4. `pages/reports/` -> Relatório de movimentações filtrado por período.
5. `pages/backup/` -> Exportação e restauração do arquivo .db do SQLite.

Por favor, comece gerando a classe `DatabaseHelper`, os `Models`, a classe de injeção de dependência `locator.dart` e o primeiro Repository.