# 🐾 Voz Animal

**Voz Animal** é uma plataforma mobile que conecta cidadãos a órgãos públicos e ONGs para denunciar e acompanhar casos de maus-tratos a animais — do registro da denúncia, com foto e localização, até a resolução pelo órgão responsável.

---

## Sobre o projeto

Denúncias de maus-tratos a animais frequentemente se perdem entre uma ligação, um print de WhatsApp e a falta de retorno de quem deveria agir. O **Voz Animal** existe para fechar essa lacuna: dá ao cidadão um jeito estruturado de registrar uma ocorrência (com foto e localização exata) e dá ao órgão responsável uma fila de trabalho real, com status, urgência e histórico.

O projeto nasceu como trabalho de portfólio, mas foi construído com as mesmas preocupações de um app que vai pra produção de verdade: autenticação real, regras de acesso a dados granulares, conformidade com a LGPD e acessibilidade.

## Funcionalidades

### Para o cidadão
- Cadastro e login com autenticação real via Firebase Auth (CPF é opcional — a denúncia não exige identificação)
- Registro de denúncia com foto, descrição e localização capturada por GPS (com geocodificação reversa do endereço)
- Acompanhamento do status de cada denúncia enviada
- Edição de perfil e **exclusão de conta**, incluindo todos os dados pessoais

### Para o órgão / ONG
- Login com verificação de CNPJ
- Fila de denúncias com urgência calculada automaticamente no servidor
- Transição controlada de status: `aberta → em análise → em andamento → resolvida / recusada`
- Relatórios consolidados
- Reabertura automática de denúncias que ficam "esquecidas" em andamento por tempo demais

## Acessibilidade

O app respeita a configuração de fonte do sistema operacional **e** oferece controle manual no próprio cabeçalho — botões **T−** / **T+** presentes em todas as telas, não só na home. O ajuste é persistido entre sessões, tem alvo de toque adequado e é compatível com leitores de tela.

## Segurança e privacidade

- **Autenticação real via Firebase Auth** (hash/salt de senha, proteção contra força bruta) — nenhuma senha é armazenada pelo app.
- **Regras do Firestore por dono do documento**: cada usuário só lê/escreve o próprio perfil; o órgão só altera o que as regras permitem em cada transição de status, com os campos do denunciante travados contra alteração indevida.
- **Checagem de CPF/CNPJ duplicado** via documentos-índice (sem expor a base de usuários a buscas abertas).
- **LGPD**: exclusão de conta sob demanda, com remoção dos dados pessoais e dos índices associados.

## Stack tecnológica

| Camada | Tecnologia |
|---|---|
| App | Flutter / Dart |
| Gerenciamento de estado | Provider |
| Autenticação | Firebase Authentication |
| Banco de dados | Cloud Firestore |
| Armazenamento de mídia | Firebase Storage |
| Lógica de servidor | Cloud Functions (Node.js) |
| Localização | Geolocator + Geocoding |
| CI/CD | GitHub Actions |

```

A separação `services` → `repositories` → Firebase existe pra manter a lógica de negócio testável e independente da camada de dados: os services não conhecem detalhes de UI, e as views não falam direto com o Firebase.

## Como rodar localmente

**Pré-requisitos**: Flutter SDK 3.x, uma conta no [Firebase](https://firebase.google.com/) e o [Firebase CLI](https://firebase.google.com/docs/cli) instalado.

```bash
# 1. Clone o repositório
git clone https://github.com/eduardahor/voz-animal.git
cd voz-animal

# 2. Instale as dependências
flutter pub get

# 3. Configure o Firebase
#    - Crie um projeto no Firebase Console
#    - Ative Authentication (e-mail/senha), Firestore e Storage
#    - Baixe o google-services.json (Android) e/ou GoogleService-Info.plist (iOS)
#      e coloque em android/app/ e ios/Runner/, respectivamente
#    - Faça o deploy das regras de segurança:
firebase deploy --only firestore:rules

# 4. Rode o app
flutter run
```

## Testes

```bash
flutter test
```

A suíte cobre modelos (`Localizacao`, `StatusDenuncia`) e o `AuthService` (login, cadastro, troca de senha, exclusão de conta), usando `fake_cloud_firestore` e `mocktail` pra isolar os testes do Firebase real. O pipeline de CI roda `flutter analyze` e `flutter test` a cada pull request.

## Como contribuir

Este projeto aceita sugestões, relatos de problemas e contribuições de código, respeitando os termos da licença abaixo (uso pessoal, educacional e acadêmico — sem fins comerciais).

1. Abra uma [issue](https://github.com/eduardahor/voz-animal/issues) descrevendo o problema ou a sugestão.
2. Para contribuir com código: faça um fork, crie uma branch e abra um pull request.
3. Mantenha os créditos e a licença original em qualquer redistribuição.

## Licença

Clique aqui para ler nossa [LICENSE](./LICENSE) 

---

Criado por **Eduarda Horning Bzunek** ([@eduardahor](https://github.com/eduardahor)).
