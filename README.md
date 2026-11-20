# Gatos

Aplicativo Flutter para descobrir e organizar fotos de gatos.

## Funcionalidades

- Cadastro, login e logout com Firebase Authentication.
- Login social com GitHub.
- Busca de gatos pela [CATAAS](https://cataas.com/), aleatória ou por tags.
- Interpretação de pedidos em linguagem natural com Gemini (opcional).
- Biblioteca pessoal sincronizada com Cloud Firestore.
- Filtros e edição de tags dos gatos salvos.
- Gato favorito usado como foto de perfil.

## Tecnologias

Flutter/Dart, Firebase Authentication, Cloud Firestore, CATAAS API e Gemini API.

## Como executar

Pré-requisitos: Flutter instalado e um projeto Firebase configurado para as
plataformas desejadas.

```bash
flutter pub get
flutter run
```

Para habilitar a busca por descrição, informe a chave do Gemini sem gravá-la no
código:

```bash
flutter run --dart-define=GEMINI_API_KEY=sua_chave
```

O ponto de entrada está em [`lib/main.dart`](lib/main.dart). As telas ficam em
[`lib/screens`](lib/screens), os serviços em [`lib/services`](lib/services) e
os componentes reutilizáveis em [`lib/components`](lib/components).

## Telas do aplicativo

As principais telas estão organizadas abaixo em uma grade compacta:

| Criar conta<br><sub>Cadastro de usuário</sub> | Logar<br><sub>Acesso à conta</sub> |
|---|---|
| <img src="screenshots/criarconta.jpg" alt="Tela de criação de conta" width="220"> | <img src="screenshots/logar.jpg" alt="Tela de login" width="220"> |

| Menu<br><sub>Navegação principal</sub> | Buscar por tags com Gemini<br><sub>Busca por descrição</sub> |
|---|---|
| <img src="screenshots/menu.jpg" alt="Menu principal" width="220"> | <img src="screenshots/buscarportagsgemini.jpg" alt="Busca por tags com Gemini" width="220"> |

| Filtrar por tags<br><sub>Filtro da biblioteca</sub> | Editar tags<br><sub>Edição de tags salvas</sub> |
|---|---|
| <img src="screenshots/filtrarportags.jpg" alt="Filtro por tags" width="220"> | <img src="screenshots/editartags.jpg" alt="Edição de tags" width="220"> |

| Definir gato favorito<br><sub>Foto de perfil</sub> | Excluir gato<br><sub>Remoção da biblioteca</sub> |
|---|---|
| <img src="screenshots/definirgatofavorito.jpg" alt="Definição de gato favorito" width="220"> | <img src="screenshots/excluirgato.jpg" alt="Exclusão de gato" width="220"> |
