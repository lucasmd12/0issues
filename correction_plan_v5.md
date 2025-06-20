# Plano de Correção Estrutural - V5 (Eliminação de Duplicidades)

Baseado na auditoria estrutural (etapa 005) que identificou duplicação significativa de arquivos e diretórios, este plano foca em **eliminar a ambiguidade estrutural** para permitir que o analisador do Flutter funcione corretamente.

**Decisão Estrutural:** Manter a estrutura principal diretamente sob `lib/` (ex: `lib/models`, `lib/services`, `lib/screens`, `lib/shared/widgets`) e remover a estrutura duplicada/conflitante dentro de `lib/src/`.

**Bloco 1: Remoção da Estrutura Duplicada**

1.  **Ação:** Remover recursivamente o diretório `lib/src/` e todo o seu conteúdo.
    *   Comando: `rm -rf lib/src` (a ser executado em `/home/ubuntu/lucasbeats_v4/project_android`)
2.  **Ação:** Remover o arquivo redundante/conflitante `lib/utils/log.dart`.
    *   Comando: `rm lib/utils/log.dart` (a ser executado em `/home/ubuntu/lucasbeats_v4/project_android`)

**Bloco 2: Limpeza Pós-Remoção e Verificação**

1.  **Ação:** Executar `flutter clean` para remover caches que possam referenciar a estrutura antiga.
2.  **Ação:** Executar `flutter pub get` para garantir que as dependências estejam corretas após a limpeza.
3.  **Ação:** Rodar `flutter analyze` para verificar o impacto da remoção da estrutura duplicada. A expectativa é que os erros de "classe não definida" e "método não definido" relacionados às duplicidades desapareçam ou mudem significativamente, revelando os erros reais de código (se houver) na estrutura mantida.

**Próximo Passo (Plano 007):**
*   Executar as ações dos Blocos 1 e 2 deste plano, **em sequência**.
*   Analisar cuidadosamente a saída do `flutter analyze` no final do Bloco 2.
*   Se a análise mostrar uma redução drástica dos erros críticos (idealmente, apenas erros de código na estrutura mantida, ou warnings/infos), prosseguir para a **re-identificação das pendências restantes** (retornando à etapa 004 do plano macro, mas com um cenário limpo) e planejar as correções de código necessárias.
*   Se erros estruturais muito semelhantes persistirem, investigar problemas mais profundos (ex: permissões de arquivo, corrupção do SDK Flutter).
