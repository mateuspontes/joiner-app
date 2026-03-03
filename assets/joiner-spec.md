# Joiner: Especificação de Aplicativo macOS para Barra de Menu

## 1. Visão Geral
Este documento especifica o desenvolvimento do "Joiner", um aplicativo nativo para a barra de menu do macOS projetado para simplificar a participação em videoconferências. O app exibe os próximos compromissos do Google Calendar (com suporte a múltiplas contas), identifica os links de reunião e gerencia notificações críticas.

A funcionalidade é inspirada no aplicativo Meeter, mas com aprimoramentos focados na organização visual de múltiplas agendas e gerenciamento de conflitos de horário.

---

## 2. Requisitos de Plataforma
* **SO:** macOS Catalina (10.15) ou superior.
* **Linguagem:** Swift / SwiftUI.
* **Framework de UI:** SwiftUI (para barra de menu e popover de preferências).

---

## 3. Funcionalidades Principais

### F01: Integração Multi-Conta com Google Calendar
* O app deve se autenticar via OAuth2 com o Google (usando o *Google Sign-In SDK for macOS*).
* **Suporte a Múltiplas Contas:** O usuário pode logar com 2 ou mais contas distintas (ex: `pessoal@gmail` e `trabalho@empresa`).
* **Sincronização:** O app deve buscar e mesclar os calendários de todas as contas conectadas, priorizando os calendários marcados como "visíveis" no Google.

### F02: Detecção Inteligente de Links de Reunião
* Ao sincronizar um evento, o Joiner deve escanear os campos `Location` (Local) e `Description` (Descrição) do evento.
* Deve-se usar expressões regulares (Regex) para identificar padrões de URL das principais plataformas:
    * **Google Meet:** `meet.google.com/`
    * **Zoom:** `zoom.us/j/` ou `zoom.us/my/`
    * **Microsoft Teams:** `teams.microsoft.com/l/meetup-join/`
    * **Slack Huddle:** `slack.com/huddle/`
* **Link Exclusivo:** O app deve armazenar o primeiro link válido encontrado para cada evento como o "link de entrada rápida".

### F03: Visualização do Menu Principal (Popover)
* **Ordenação:** Exibir os eventos do dia em ordem cronológica.
* **Aparência:** Seguir a estética translúcida do macOS.
* **Destaque:** Um card especial no topo para a reunião iminente (próximos 15 min).
* **Botão de Entrada:** Exibir um botão "Join" (Entrar) proeminente e colorido. Se não houver link detectado, o botão deve estar inativo ou oculto.
* **Gestão de Conflitos:** Se múltiplos eventos ocorrerem no mesmo horário (comum em "reuniões de backup"), eles devem ser agrupados com um aviso visual de "Conflito".
* **Ações ao Passar o Mouse:** Ao pairar sobre um evento, mostrar botões secundários: "Copiar Link" e "Ver Detalhes do Evento".

### F04: Sistema de Notificações
* **Faltando 5 Minutos (Pré-Notificação):**
    * Disparar um banner de notificação nativo do macOS.
    * **Sem Som.**
    * A notificação deve incluir um botão de ação "Join Now" (Entrar Agora).
* **Na Hora da Reunião (Notificação Crítica):**
    * Disparar um banner de notificação nativo.
    * **Com Som Ativado** (`UNNotificationSound.default`).
    * Deve incluir o botão de ação "Join Now".

### F05: Ícone da Barra de Menu Dinâmico
* O ícone padrão deve ser uma câmera ou calendário minimalista.
* Se houver um compromisso nos próximos 30 minutos, o ícone deve exibir a contagem regressiva (ex: `12m`) ao lado do símbolo.
* O ícone deve piscar ou mudar de cor (ex: vermelho) se a reunião já começou e o usuário não entrou.

---

## 4. UI/UX: Especificações de Mockup

### 4.1 Estrutura do Menu Principal (Popover)
O mockup visual deve incluir os seguintes elementos na janela translúcida que se abre ao clicar na barra de menu:

* **Topo:** Card de "Próximo" em destaque (fundo sólido, botão Join grande).
* **Lista (Hoje):** Listagem compacta. Cada item deve ter:
    * Um ponto colorido (Verde para Pessoal, Vermelho para Trabalho, etc.).
    * Horário (ex: `17:00`).
    * Título (ex: `FinOps Office Hours`).
    * Botão "Join".
* **Grupo de Conflito:** Uma seção claramente separada para as 4 reuniões das 18:00 (baseado na agenda de exemplo).
* **Base:** Atalho para Preferências e Botão Quit (Sair).

### 4.2 Tela de Preferências (Janela Separada)
Uma janela padrão de preferências do Mac (com ícones de barra de ferramentas no topo):

* **Aba "Contas":** Onde se adiciona/remove logins do Google Calendar.
* **Aba "Calendários":** Uma árvore de pastas onde o usuário marca quais calendários de quais contas ele quer ver.
* **Aba "Aparência/Notificações":** Configuração de ligar ou desligar o som, contagem regressiva e temas (futuro).

---

## 5. Arquitetura Técnica Sugerida
* **Banco de Dados:** CoreData ou SQLite (via SwiftData se possível) para cache de eventos.
* **Segurança:** Guardar tokens de autenticação exclusivamente no Keychain.
* **Sincronização:** Background Tasks para atualizar a agenda a cada 15-30 minutos, ou sob demanda ao abrir o menu.