# FocusBar 🎈

O **FocusBar** é um aplicativo nativo para macOS desenhado para maximizar a produtividade e eliminar distrações digitais. Operando diretamente na barra de menus, ele combina bloqueio de rede em nível de sistema (`/etc/hosts`) com monitoramento inteligente de navegadores para garantir sessões de hiperfoco sem interrupções.

## ✨ Funcionalidades Principais

* **Modo Hiperfoco:** Um "botão de pânico" produtivo. Bloqueia todas as distrações cadastradas de uma só vez, sobrepondo qualquer outra regra.
* **Foco Rápido (Timer de 30 minutos):** Ative bloqueios temporários para grupos específicos de sites. O tempo restante é exibido na barra de menus de forma discreta e nativa.
* **Agendamentos Inteligentes:** Defina dias da semana e horários específicos para ativar o bloqueio automaticamente (ex: Segunda a Sexta, das 08h às 18h).
* **Organização por Grupos:** Separe suas distrações em categorias (ex: Redes Sociais, Notícias, Vídeos) e gerencie os domínios de forma modular.
* **Wildcard & Bloqueio Dinâmico:** Cadastre domínios raiz (ex: `google.com`) ou palavras-chave (ex: `news`) e o sistema interceptará qualquer URL ou subdomínio que contenha o termo.
* **Segurança Profissional (XPC):** Ao invés de usar hacks inseguros de permissão, o FocusBar instala um *Privileged Helper Tool* invisível que edita os arquivos do sistema com segurança máxima.

## 🛠️ Como Funciona (Arquitetura Híbrida)

O FocusBar atua em duas camadas simultâneas para garantir que nenhuma distração passe:

1. **Camada de Rede (`/etc/hosts` via XPC Daemon):**
Utilizando um processo com privilégios de Root (solicitado apenas na primeira execução), o aplicativo redireciona o tráfego dos domínios exatos para `0.0.0.0`. O consumo de bateria e CPU desta camada é virtualmente zero.
2. **Camada de Navegador (AppleScript Automator):**
Para lidar com regras flexíveis (wildcards), o aplicativo verifica passivamente a URL ativa nos principais navegadores baseados em Chromium e WebKit (Safari, Google Chrome, Brave). Se uma distração for detectada, a aba é instantaneamente redirecionada para uma página local de foco (com interface *Frosted Glass* amigável aos modos Claro/Escuro do macOS).

## 🚀 Instalação

1. Acesse a aba[ ](https://github.com/SEU-USUARIO/FocusBar/releases)[Releases](https://github.com/cloviscarmezini/FocusBar/releases) do repositório.
2. Baixe o arquivo `FocusBar-Instalador.dmg` mais recente.
3. Abra o arquivo `.dmg` e arraste o **FocusBar** para a pasta **Aplicativos**.
4. Inicie o aplicativo. Na primeira execução, o macOS solicitará:
* **Senha de Administrador:** Para instalar o Helper Tool responsável por gerenciar a rede.
* **Permissão de Automação:** Para permitir que o app leia a URL do seu navegador e feche abas bloqueadas.



## 💻 Compilando a partir do Código-Fonte

Se desejar modificar ou compilar o FocusBar por conta própria:

1. Clone o repositório:
```bash
git clone https://github.com/seu-usuario/FocusBar.git

```


2. Abra o projeto no **Xcode** (`FocusBar.xcodeproj`).
3. Vá nas configurações do projeto e atualize o *Team/Bundle Identifier* para a sua conta de desenvolvedor da Apple.
* **Importante:** Certifique-se de assinar ambos os targets: `FocusBar` (App) e `FocusBarHelper` (Command Line Tool).


4. No menu superior, selecione **Product > Build** (ou `Cmd + R` para rodar em modo Debug).

## 🧰 Tecnologias Utilizadas

* **Swift 5 & SwiftUI:** Interface de usuário e lógica do motor de regras.
* **XPC Services & ServiceManagement:** Comunicação inter-processos com escalonamento de privilégios.
* **AppleScript:** Integração com navegadores para leitura assíncrona de URLs.
* **HTML/CSS:** Tela de bloqueio vetorial responsiva embarcada localmente.

## 📝 Licença

Este projeto é distribuído sob a licença MIT. Consulte o arquivo `LICENSE` para obter mais detalhes.
