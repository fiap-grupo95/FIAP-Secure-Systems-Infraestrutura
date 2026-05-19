# FUNCTIONAL_SPEC.MD - Especificação Funcional e Casos de Uso

Este documento descreve as funcionalidades obrigatórias do MVP e como elas são expostas via API Gateway [cite: 49, 337].

## 1. Casos de Uso (User Stories)

### UC01: Upload de Diagrama
* **Ator:** Desenvolvedor / Arquiteto
* **Fluxo:** O usuário envia uma imagem ou PDF do diagrama. O sistema valida o arquivo, armazena e retorna um ID de acompanhamento [cite: 51, 140].
* **Endpoint:** `POST /api/diagrams`

### UC02: Consulta de Status
* **Ator:** Desenvolvedor / Arquiteto
* **Fluxo:** O usuário consulta o progresso da análise através do ID recebido. Os status possíveis são: *Recebido, Em processamento, Analisado* ou *Erro* [cite: 28, 53].
* **Endpoint:** `GET /api/process/{processId}/status`

### UC03: Visualização do Relatório
* **Ator:** Desenvolvedor / Arquiteto
* **Fluxo:** Após o status ser confirmado como "Analisado", o usuário requisita o relatório técnico que contém componentes identificados, riscos e recomendações [cite: 57, 142].
* **Endpoint:** `GET /api/reports/{reportId}`

## 2. Máquina de Estados (Orquestração)
O sistema deve garantir a transição correta entre os estados:
1.  **RECEBIDO:** Arquivo salvo e na fila de processamento [cite: 53].
2.  **EM PROCESSAMENTO:** IA iniciou a análise [cite: 54].
3.  **ANALISADO:** Relatório disponível para leitura [cite: 55].
4.  **ERRO:** Falha técnica ou falha na inferência da IA [cite: 56].

## 3. Segurança e Validação
* **Input Validation:** Validação de formato de imagem e tamanho de PDF no Gateway [cite: 128].
* **IA Guardrails:** Validação da consistência das respostas da IA antes da persistência do relatório [cite: 83, 130].