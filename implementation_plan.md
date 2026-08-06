# Correção do MSIX — App não abre após instalação

## Diagnóstico

O aplicativo instala via MSIX com sucesso, mas não abre ao clicar no ícone. Após análise, foram identificados **dois problemas** que causam isso:

---

## Problemas Encontrados

### ❶ `sqlite3.dll` não está empacotada no MSIX

O app usa `sqflite_common_ffi`, que requer o arquivo `sqlite3.dll` na mesma pasta do executável. Na instalação via MSIX, esse arquivo **não é copiado automaticamente** — ele precisa ser instruído no `CMakeLists.txt`.

Sem esse DLL, o app inicia, tenta inicializar o banco de dados e **trava/fecha silenciosamente** antes de mostrar qualquer tela.

**Arquivos afetados:**
- `windows/CMakeLists.txt` — adicionar instrução de cópia do DLL
- Baixar `sqlite3.dll` para `windows/` (ou usar o que já está no cache do pub)

---

### ❷ `windows_single_instance` precisa de `protocol_activation` no `msix_config`

O pacote `windows_single_instance` usa um protocolo personalizado de IPC para comunicar instâncias. Quando o app está em MSIX (ambiente empacotado/sandboxed), esse mecanismo **exige que o protocolo esteja declarado no manifesto MSIX** via `protocol_activation`.

Sem isso, ao clicar para abrir o app pela segunda vez (ou às vezes até na primeira em MSIX), o app pode ficar preso no `ensureSingleInstance` e **fechar sem mostrar nada**.

**Arquivos afetados:**
- `pubspec.yaml` — adicionar `protocol_activation` no `msix_config`

---

## Proposed Changes

### `pubspec.yaml`

#### [MODIFY] [pubspec.yaml](file:///c:/Users/jojoc/OneDrive/Documentos/Projetos/Meus%20projetos/armazem/pubspec.yaml)

Adicionar `protocol_activation` ao bloco `msix_config`:

```yaml
msix_config:
    display_name: Almoxarifado
    output_name: Almoxarifado
    publisher_display_name: Joelmir Rogério Carvalho
    identity_name: com.flutter.armazem
    logo_path: assets/images/logo_image.png
    protocol_activation: armazem   # <-- NOVO: necessário para windows_single_instance
    capabilities: >-
      runFullTrust,
      internetClient,
      internetClientServer,
      privateNetworkClientServer
```

---

### `windows/CMakeLists.txt`

#### [MODIFY] [CMakeLists.txt](file:///c:/Users/jojoc/OneDrive/Documentos/Projetos/Meus%20projetos/armazem/windows/CMakeLists.txt)

Adicionar no final do arquivo a instrução para copiar o `sqlite3.dll`:

```cmake
# Bundling sqlite3.dll required by sqflite_common_ffi
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/sqlite3.dll"
  DESTINATION "${CMAKE_INSTALL_PREFIX}"
  COMPONENT Runtime)
```

---

### `windows/sqlite3.dll`

#### [NEW] `windows/sqlite3.dll`

O DLL será **copiado do cache do pub** (que já existe na máquina pois o pacote foi baixado), sem necessidade de download externo.

---

## Verification Plan

### Build Steps
```powershell
# 1. Copiar o sqlite3.dll do cache do pub para windows/
# 2. flutter clean
# 3. flutter build windows --release
# 4. dart run msix:create
```

### Manual Verification
- Instalar o novo MSIX no Windows
- Clicar no ícone do app — deve abrir normalmente
- Fechar e reabrir — o `windows_single_instance` deve trazer a janela ao foco

---

> [!IMPORTANT]
> O arquivo `sqlite3.dll` precisa ser o de **64 bits (x64)** para combinar com a build do Flutter.
