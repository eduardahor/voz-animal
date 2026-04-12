# 🐾 Voz Animal

Aplicativo Flutter para registro, acompanhamento e denúncia de situações envolvendo animais.

## 📱 Funcionalidades

- **Cadastro e Login** de usuários
- **Registro de denúncias** com descrição, foto (simulada), localização (simulada) e tipo de ocorrência
- **Listagem** de todas as denúncias com estatísticas
- **Visualização detalhada** de cada denúncia
- **Marcar como resolvida**
- **Perfil do usuário** com estatísticas pessoais

## 🧠 Conceitos de POO Aplicados

### Encapsulamento
- Campos privados com `_` e acesso via getters/setters em todas as models (`Usuario`, `Denuncia`, `Localizacao`)
- Validação nos setters (ex: `telefone`)

### Abstração
- Classe abstrata `RegistroBase` define interface comum com métodos abstratos `obterResumo()` e `isValido()`

### Herança
- `Denuncia` herda de `RegistroBase`, reutilizando campos e comportamentos comuns

### Polimorfismo
- `Denuncia` implementa os métodos abstratos de `RegistroBase` com comportamento específico
- Usado na tela de detalhe ao chamar `denuncia.obterResumo()`

## 📂 Estrutura do Projeto

```
lib/
├── main.dart                  # Ponto de entrada
├── models/                    # Camada de modelos
│   ├── registro_base.dart     # Classe abstrata (abstração)
│   ├── usuario.dart           # Model de usuário
│   ├── denuncia.dart          # Model de denúncia (herança)
│   ├── localizacao.dart       # Model de localização
│   ├── tipo_ocorrencia.dart   # Enum de tipos
│   └── status_denuncia.dart   # Enum de status
├── services/                  # Camada de serviços
│   ├── auth_service.dart      # Autenticação
│   └── denuncia_service.dart  # Gerenciamento de denúncias
├── views/                     # Camada de visualização
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── cadastro_screen.dart
│   ├── home_screen.dart
│   ├── nova_denuncia_screen.dart
│   ├── detalhe_denuncia_screen.dart
│   └── perfil_screen.dart
└── widgets/                   # Componentes reutilizáveis
    └── denuncia_card.dart
```

## 🚀 Como Executar

1. Certifique-se de ter o Flutter instalado (>=3.0.0)
2. Extraia o projeto
3. Crie a pasta `assets/images/` na raiz do projeto
4. Execute:
   ```bash
   flutter pub get
   flutter run
   ```

## 📦 Dependências

- `provider` — Gerenciamento de estado
- `uuid` — Geração de IDs únicos
- `intl` — Formatação de datas
