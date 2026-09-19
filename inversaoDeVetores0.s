; Seção de macros

%macro pushgeral 0                             ; macro para salvar data registers (usar junto com popgeral)

    push rax                                   ; salva rax
    push rbx                                   ; salva rbx
    push rcx                                   ; salva rcx
    push rdx                                   ; salva rdx
    push rdi                                   ; salva rdi
    push rsi                                   ; salva rsi

%endmacro

%macro popgeral 0                              ; macro para restaurar data registers (usar junto com pushgeral)

    pop rsi                                    ; restaura rsi
    pop rdi                                    ; restaura rdi
    pop rdx                                    ; restaura rdx
    pop rcx                                    ; restaura rcx
    pop rbx                                    ; restaura rbx
    pop rax                                    ; restaura rax

%endmacro

%macro escrever 2                              ; macro para escrever no terminal (1 = começo da mensagem | 2 = tamanho da mensagem em bytes)

    mov rax, SYS_WRITE                         ; especificar chamada de escrita
    mov rdi, STDOUT                            ; especificar onde escrever
    mov rsi, %1                                ; mensagem
    mov rdx, %2                                ; tamanho da mensagem
    syscall                                    ; chamada ao SO

%endmacro

%macro ler 2                                   ; macro para ler um valor do teclado (1 = endereço onde ler | 2 = quantos bytes ler)

    mov rax, SYS_READ                          ; especificar chamada de leitura
    mov rdi, STDIN                             ; especificar de onde coletar o input
    mov rsi, %1                                ; endereço onde ler
    mov rdx, %2                                ; quantos bytes ler
    syscall                                    ; chamada ao SO

%endmacro

%macro alloc_array_uint32 2                    ; macro para alocar um array de uint32 (1 - onde salvar o endereço do começo do array | 2 - quantos uint32 alocar)

    xor rax, rax                               ; zerar rax para maior controle dos valores
    mov dword eax, %2                          ; colocar a quantidade de uint32 em rax (double word)
    shl rax, 2                                 ; shift left by 2 (múltiplica por 2^2 o rax, pois 1 uint32 é 4 bytes)
    sub rsp, rax                               ; subtrai quantos bytes o array vai ocupar do stack pointer
    mov %1, rsp                                ; salva o endereço do começo do array no local especificado

%endmacro

; Fim da seção de macros

;========================================================================================================================================================================================

section .data                                                                   ; seção de dados inicializados e constantes

PedidoTamanhoArray     db  'Escolha o tamanho do array: ', 0x00                 ; mensagem 1 (29 bytes)
lenPedidoTamanhoArray  equ $ - PedidoTamanhoArray                               ; tamanho mensagem 1
PedidoElementoArray    db  'Digite um elemento para o array[*]: ', 0x00         ; mensagem 2 (34 bytes)
lenPedidoElementoArray equ $ - PedidoElementoArray                              ; tamanho mensagem 2
msgArrayOriginal       db  'O array original é: ', 0x00                         ; mensagem 3 (22 bytes)
lenMsgArrayOriginal    equ $ - msgArrayOriginal                                 ; tamanho mensagem 3
msgArrayInvertido      db  'O array invertido é: ', 0x00                        ; mensagem 4 (23 bytes)
lenMsgArrayInvertido   equ $ - msgArrayInvertido                                ; tamanho mensagem 4
quebraLinha            db  0xa                                                  ; quebra de linha (1 byte)
lenQuebraLinha         equ 1                                                    ; tamanho da quebra de linha

array                  dq      0                                                ; variável que armazena o endereço da primeira posição do array de uint32
tamanhoArray           dd      0                                                ; variável para armazenar o tamanho do array
finalBufferOut         dd      0                                                ; quantidade de elementos no buffer de saída
posAtualbufferin       dd      0

SYS_READ               equ     0                                                ; Descritor para chamada de leitura
STDIN                  equ     0                                                ; Descritor para fluxo padrão de entrada
SYS_WRITE              equ     1                                                ; Descritor para chamada de escrita
STDOUT                 equ     1                                                ; Descritor para fluxo padrão de saída
SYS_EXIT               equ  0x3c                                                ; Descritor para chamada de encerramento

SIZBUFIN               equ   256                                                ; tamanho do buffer de entrada
SIZBUFOUT              equ  8192                                                ; tamanho do buffer de saída
CAPUINT32              equ     4                                                ; capacidade em bytes de um uint32
ENDERECOx64            equ     8                                                ; tamanho de um endereço em bytes na arquitetura x86_64

;========================================================================================================================================================================================

section .bss                                                    ; seção de dados não inicializados

bufferin  resb  256                                             ; buffer de entrada
bufferout resb 8192                                             ; buffer de saída

;========================================================================================================================================================================================

section .text                                                   ; seção de código
    global _start                                               ; especificar qual o entry point do código

_start:                                                         ; entry point do código

.tamanho_invalido:                                              ; label para repetir leitura de tamanho do array
    mov rdi, PedidoTamanhoArray                                 ; carrega rdi com o começo da mensagem a ser escrita
    mov rsi, lenPedidoTamanhoArray                              ; carrega rsi com o tamanho da mensagem a ser escrita
    call .insta_print                                           ; escreve mensagem no terminal

    call .scan_uint32                                           ; lê um uint32 (uint32 lido -> rax)

    cmp dword eax, 0                                            ; confere se tamanho do array é nulo
je .tamanho_invalido                                            ; volta para fazer releitura caso tamanho seja nulo

mov dword [rel tamanhoArray], eax                               ; salva o tamanho do array na memória
alloc_array_uint32 [rel array], [rel tamanhoArray]              ; desloca o stack pointer register para alocar o array e salva o endereço na memória (var array)

mov rdi, quebraLinha                                            ; carrega rdi com o começo da mensagem a ser escrita
mov rsi, lenQuebraLinha                                         ; carrega rsi com o tamanho da mensagem a ser escrita
call .insta_print                            

mov rdi, [rel array]                                            ; carrega rdi com o endereço do primeiro uint32 do array
xor rsi, rsi                                                    ; zera rsi para maior controle dos valores
mov dword esi, [rel tamanhoArray]                               ; carrega rsi (double word) com o tamanho do array
call .ler_array_uint32                                          ; lê o array posição por posição

mov rdi, quebraLinha                                            ; carrega rdi com o começo da mensagem a ser escrita
mov rsi, lenQuebraLinha                                         ; carrega rsi com o tamanho da mensagem a ser escrita
call .insta_print                                               ; escreve mensagem no terminal                            

mov rdi, msgArrayOriginal                                       ; carrega rdi com o começo da mensagem a ser escrita
mov rsi, lenMsgArrayOriginal                                    ; carrega rsi com o tamanho da mensagem a ser escrita
call .insta_print                                               ; escreve mensagem no terminal                  

mov rdi, [rel array]                                            ; carrega rdi com o endereço do array
xor rsi, rsi                                                    ; zera rsi para maior controle dos valores
mov dword esi, [rel tamanhoArray]                               ; carrega rsi (double word) com o tamanho do array
call .parse_array_uint32_to_buffer_out                          ; posiciona elementos do array no buffer de saída

call .flush_buffer_out                                          ; esvazia buffer de saída

mov rdi, quebraLinha                                            ; carrega rdi com o começo da mensagem a ser escrita
mov rsi, lenQuebraLinha                                         ; carrega rsi com o tamanho da mensagem a ser escrita
call .insta_print                                               ; escreve mensagem no terminal                            

mov rdi, [rel array]                                            ; carrega rdi com o endereço do array
xor rsi, rsi                                                    ; zera rsi para maior controle dos valores
mov dword esi, [rel tamanhoArray]                               ; carrega rsi (double word) com o tamanho do array
call .inverte_array_uint32                                      ; inverte um array com algoritmo in-place

mov rdi, msgArrayInvertido                                      ; carrega rdi com o começo da mensagem a ser escrita
mov rsi, lenMsgArrayInvertido                                   ; carrega rsi com o tamanho da mensagem a ser escrita
call .insta_print                                               ; escreve mensagem no terminal               

mov rdi, [rel array]                                            ; carrega rdi com o endereço do array
xor rsi, rsi                                                    ; zera rsi para maior controle dos valores
mov dword esi, [rel tamanhoArray]                               ; carrega rsi (double word) com o tamanho do array
call .parse_array_uint32_to_buffer_out                          ; posiciona elementos do array no buffer de saída

call .flush_buffer_out                                          ; esvazia buffer de saída

mov rax, SYS_EXIT                                               ; prepara para saída do programa
xor rdi, rdi                                                    ; flag de encerramento bem-sucedido
syscall                                                         ; chamada ao SO

;========================================================================================================================================================================================

.scan_buffer_in:                                                        ; rotina para ler inputs e armazenar no buffer de entrada (sem argumentos)

    call .flush_buffer_out                                              ; esvazia buffer de saída se tiver algo
    ler bufferin, SIZBUFIN                                              ; leitura no buffer de entrada
    dec rax                                                             ; desconsidera a quebra de linha dada pelo usuário (ou último digito em caso de buffer "overflow")
    mov byte [bufferin + rax], 0x00                                     ; substitue o último caractere (\n caso não tenha overflow) por um \0

ret                                                                     ; volta ao fluxo (quantidade de caracteres lidos -> rax)

.check_buffer_in_valido:                                                ; rotina para verificar se há números no bufferin retirar caracteres indesejados (endereço atual onde bufferin está sendo lido -> rdi)

    .posicao_invalida:                                                  ; loop para verificar por caracteres invalidos

        mov rax, 1                                                      ; setup para operação lógica AND

        cmp byte [rdi], 0                                               ; confere se é o fim do bufferin
        je .acabou_varredura                                            ; sair da rotina se houver número(s) no bufferin
        
        cmp byte [rdi], 48                                              ; compara 1 byte do bufferin com o lower_bound dos números ('0')
        setge cl                                                        ; se for maior ou igual a zero, liga o cl (desliga caso contrário)
        and al, cl                                                      ; realiza operação AND com setup inicial

        cmp byte [rdi], 57                                              ; compara 1 byte do bufferin com o upper_bound dos números ('9')
        setle cl                                                        ; se for menor ou igual a nove, liga o cl (desliga caso contrário)
        and al, cl                                                      ; faz operação AND com o resultado acumulado anteriormente

        test al, al                                                     ; confere se o digito está no intervalor (1) ou não (0)
        jnz .valido                                                     ; encerra rotina se achar caractere válido

        inc rdi                                                         ; incrementa endereço para o próximo caractere
        inc dword [rel posAtualbufferin]                                ; incrementa posição global do bufferin
    jmp .posicao_invalida                                               ; retorna para analizar próximo caractere
    .acabou_varredura:                                                  ; label caso chegue ao fim do bufferin sem caracteres válidos
    
    xor al, al                                                          ; zera flag de retorno para comunicar que bufferin não é válido
    
    ret                                                                 ; volta o fluxo ([0 -> rax] para bufferin inválido)
    .valido:                                                            ; label caso bufferin seja válido

ret                                                                     ; volta o fluxo ([1 -> rax] para bufferin válido)

.scan_uint32:                                                           ; rotina para ler uint32 (Sem argumentos)

    .input_so_com_caractere_invalido:                                   ; label caso bufferin seja inválido (sem números)
    
        xor rdi, rdi                                                    ; zera para maior controle dos valores
        mov edi, [rel posAtualbufferin]                                 ; copia endereço de bufferin para rdi
        lea rdi, [bufferin + rdi]                                       ; desloca para posição atual de leitura do bufferin
        call .check_buffer_in_valido                                    ; checa e varre bufferin
        
        test al, al                                                     ; confere se bufferin é váldo
        jnz .buffer_com_conteudo                                        ; salta leitura se houver conteúdo em bufferin


        mov dword [rel posAtualbufferin], 0                             ; move a leitura do bufferin para o começo

        call .scan_buffer_in                                            ; coleta input do teclado e armazena no buffer

    jmp .input_so_com_caractere_invalido                                ; volta para conferir buffer
    .buffer_com_conteudo:                                               ; label para quando buffer for válido

    call .calcular_tamanho_proximo_uint32_buffer_in                     ; calcula quantos caracteres o próximo número do buffer tem (tamanho -> rax)
    
    xor rdi, rdi                                                        ; zeera rdi para maior controle dos valores
    mov edi, eax                                                        ; copia quantidade de digitos no próximo número a ser lido em rdi (double word)
    call .parse_buffer_in_to_uint32                                     ; faz o parse do buffer de entrada para uint32 

ret                                                                     ; retorna o fluxo (uint32 parsiado -> rax)
 
.calcular_tamanho_proximo_uint32_buffer_in:                             ; rotina para calcular quantos dígitos tem o próximo número a ser lido em bufferin (sem argumentos)

    xor rdi, rdi                                                        ; zera rdi para maior controle dos valores
    mov dword edi, [rel posAtualbufferin]                               ; copia o índice atual do bufferin para rdi (double word)

    .loop_contar_digitos:                                               ; loop para contar digitos do número

        mov al, 1                                                       ; setup para operação AND

        cmp byte [bufferin + rdi], 0                                    ; confere se é o fim do bufferin
        je .parar_contagem                                              ; sair da contagem se chegar no fim do bufferin 

        cmp byte [bufferin + rdi], 48                                   ; compara 1 byte do bufferin com o lower_bound dos números ('0')
        setge cl                                                        ; se for maior ou igual a zero, liga o cl (desliga caso contrário)
        and al, cl                                                      ; realiza operação AND com setup inicial

        cmp byte [bufferin + rdi], 57                                   ; compara 1 byte do bufferin com o upper_bound dos números ('9')
        setle cl                                                        ; se for menor ou igual a nove, liga o cl (desliga caso contrário)
        and al, cl                                                      ; faz operação AND com o resultado acumulado anteriormente

        test al, al                                                     ; confere se o digito está no intervalor (1) ou não (0)
        jz .parar_contagem                                              ; para contagem se caractere não estiver na contagem

        inc rdi                                                         ; salta para próximo caractere do bufferin

    jmp .loop_contar_digitos                                            ; voltar para checar mais caracteres
    .parar_contagem:                                                    ; label para encerrar contagem se chegou ao fim do número

    sub dword edi, [rel posAtualbufferin]                               ; tamanho = posição final - posição inicial
    mov rax, rdi                                                        ; encaminha tamanho do número para registrador de retorno

ret                                                                     ; volta ao fluxo (quantidade de dígitos no número -> rax)

.parse_buffer_in_to_uint32:                                             ; rotina para converter buffer de entrada em uint32 (quantidade de dígitos no número -> rdi)

    xor rsi, rsi                                                        ; zera para maior controle dos valores
    mov esi, [rel posAtualbufferin]                                     ; pega endereço do começo do buffer de entrada
    lea rsi, [bufferin + rsi]                                           ; calcula offset da posição atual do buffer de entrada

    add dword [rel posAtualbufferin], edi                               ; adianta o registro do salto no bufferin
    
    xor rdi, rdi                                                        ; zera para maior controle dos valores
    mov edi, [rel posAtualbufferin]                                     ; carrega rdi com o endereço do começo do buffer
    lea rdi, [bufferin + rdi]                                           ; calcula  offset do final do número no buffer de saída

    mov ebx, 1                                                          ; colocar 10^0 em ebx, onde será ditado a ordem da base decimal
    xor rcx, rcx                                                        ; zerar rcx para usá-lo como acumulador do resultado do parse

    .loop_parse_buffer_in_to_uint32:                                    ; começo do processo de converter caracteres em números

        dec rdi                                                         ; salto ao próximo char a ser lido em bufferin

        xor rax, rax                                                    ; zerar rax para usar em operações aritméticas
        
        mov byte al, [rdi]                                              ; copiar caracter para al
        sub al, 48                                                      ; subtrair '0' de al para ter o valor concreto do número
        mul ebx                                                         ; multiplicar a potência de 10 atual (ebx) com o número atual (eax | al) 
        add ecx, eax                                                    ; adicionar o resultado da multiplicação no registrador de resultado

        mov eax, 10                                                     ; mover 10 para eax para aumentar a ordem do número
        mul ebx                                                         ; múltiplicar 10 por 10^(ordem atual)
        mov ebx, eax                                                    ; colocar o resultado em ebx, onde deve estar a potência de 10

        cmp rdi, rsi                                                    ; decrementar quantidade de dígitos que faltam
    jne .loop_parse_buffer_in_to_uint32                                 ; faz o processo mais uma vez se tiver mais dígitos

    mov rax, rcx                                                        ; carregar o registrador de retorno com o resultado do parse

ret                                                                     ; voltar ao fluxo (resultado do parse em rax)

.ler_array_uint32:                                                      ; rotina para ler array de uint32 (endereço do array -> rdi, tamanho do array -> rsi)

    mov r8, rdi                                                         ; libera rdi para ser usado como argumento
    mov r9, rsi                                                         ; libera rsi para ser usado como índice
    xor rsi, rsi                                                        ; zerar índice

    .loop_leitura_array_uint32:                                         ; começo do processo de ler uma posição do array

        cmp r9, 0                                                       ; confere se chegou no fim do array
        je .encerrar_leitura_array_uint32                               ; encerra leitura se chegou no fim do array
        
        push rsi                                                        ; armazena índice do array
        
        mov rdi, bufferin                                               ; copia endereço do começo do buffer de entrada
        add edi, [rel posAtualbufferin]                                 ; desloca para o endereço do byte imediatamente após o último byte usado do buffer de entrada
        call .check_buffer_in_valido                                    ; confere se buffer de entrada é válido e retorna uma flag

        test al, al                                                     ; teste do retorno da checagem de buffer 
        jnz .buffer_com_resquicio                                       ; instrução para pular mensagem de pedido no terminal em caso de buffer de entrada válido
            
            push rsi                                                    ; carrega a pilha com argumento para rotina (copiar_ao_buffer_out_com_curinga)

            mov rdi, PedidoElementoArray                                ; Carrega rdi com mensagem pedindo elemento
            mov rsi, 1                                                  ; carrega rsi com a quantidade de argumentos na pilha
            call .copiar_ao_buffer_out_com_curinga                      ; pede um input
            
            lea rsp, [rsp + ENDERECOx64 * 1]                            ; restaura pilha para antes dos argumentos da rotina com stack-frame

        .buffer_com_resquicio:                                          ; label para pular mensagem de pedido no terminal se tiver algo no buffer

        call .scan_uint32                                               ; lê um uint32 (uint32 lido -> rax)

        pop rsi                                                         ; restaura índice do array

        mov dword [r8], eax                                             ; posiciona o uint32 no array
        lea r8, [r8 + CAPUINT32]                                        ; calcula o endereço da próxima posição do array
        inc rsi                                                         ; incrementa índice para colocar na string de pedido de elemento

        dec r9                                                          ; decrementa quantos elementos faltam ler
    jmp .loop_leitura_array_uint32                                      ; retorna pro começo do loop para pegar mais inputs
    .encerrar_leitura_array_uint32:                                     ; encerra loop de leitura do array

ret                                                                     ; volta o fluxo (sem retorno)

.parse_array_uint32_to_buffer_out:                                      ; rotina para colocar array de uint32 no buffer de saída (endereço do array -> rdi, tamanho do array -> rsi)

    mov r9, rsi                                                         ; libera o rsi para ser usado como índice
    xor rsi, rsi                                                        ; zerar rsi para maior controle dos valores
    mov dword esi, [rel finalBufferOut]                                 ; carrega rsi (double word) com a quantidade de elementos no buffer de saída

    .loop_colocar_uint32_buffer_out:                                    ; começo do loop de posicionar números no buffer de saída

        cmp r9, 0                                                       ; confere se chegou no fim do array
        je .encerrar_colocar_uint32_buffer_out                          ; encerra loop se array acabou

        push rdi                                                        ; salva endereço do elemento atual do array
        mov edi, [rdi]                                                  ; carrega rdi (double word) com o uint32 a ser parsiado
        call .parse_uint32_to_buffer_out                                ; colocar o uint32 no buffer de saída (final do buffer de saída -> rax)
        pop rdi                                                         ; restaura endereço do elemento do array

        lea rdi, [rdi + CAPUINT32]                                      ; saltar para o próximo uint32 do array

        cmp r9, 1                                                       ; checar se é o último elemento para ver se adiciona um espaço ou não
        je .pular_espaco_str                                            ; pula a adição de espaço caso seja o último elemento

            call .evitar_buffer_out_overflow                            ; esvazia buffer de saída caso esteja cheio e zera registrador de controle atual do fim do buffer 
            mov byte [bufferout + rsi], ' '                             ; adiciona um espaço no buffer de saída
            inc dword [rel finalBufferOut]                              ; incrementa o registro de final do buffer
            inc rsi                                                     ; salta para próxima posição livre do buffer
        
        .pular_espaco_str:                                              ; label para pular a adição de espaço

        dec r9                                                          ; decrementa quantos elementos do array faltam colocar
    jmp .loop_colocar_uint32_buffer_out                                 ; instrução para voltar e pegar o próximo uint32 
    .encerrar_colocar_uint32_buffer_out:                                ; label para encerrar posicionamento de uint32 no buffer de saída

    mov rax, rsi                                                        ; copiar o índice final do buffer de saída para rax

ret                                                                     ; volta o fluxo (final do buffer de saída -> rax)

.parse_uint32_to_buffer_out:                                            ; rotina para pegar um uint32 e colocar no buffer de saída (uint32 -> rdi)

    xor rsi, rsi                                                        ; zera rsi para maior controle dos valores
    mov dword esi, [rel finalBufferOut]                                 ; carregar rsi (double word) com índice do final do buffer de saída para posicionar caracteres
    mov rbx, 10                                                         ; mover 10 para rbx, preparando para divisões suscessivas por 10

    xor rax, rax                                                        ; zerar rax para maior controle dos valores a frente
    xor rcx, rcx                                                        ; zera rcx para usar como contador de caracteres

    .loop_pegar_digitos:                                                ; início da decomposição do uint32

        xor edx, edx                                                    ; 4 bytes superiores do uint32 em 8 bytes copiados para edx (é sempre 0)
        mov dword eax, edi                                              ; 4 bytes inferiores do uint32 em 8 bytes copiados para eax
        div ebx                                                         ; divisão por 10 (edx:eax / ebx) | ebx == 10

        mov dword edi, eax                                              ; copia o quociente para a posição do uint32
        add edx, 48                                                     ; adiciona 48 ao resto para sair de dígito para caracter
        push rdx                                                        ; salva o caracter na pilha

        inc rcx                                                         ; aumenta a contagem de caracters | digitos

        cmp ax, 0                                                       ; confere se o quociente é zero

    jne .loop_pegar_digitos                                             ; volta se o quociente não for zero

    .loop_desempilhar_digitos:                                          ; posicionar caracteres no buffer de saída na ordem certa

        pop rax                                                         ; recolhe o caracter
        call .evitar_buffer_out_overflow                                ; esvazia buffer de saída caso esteja cheio e zera registrador de controle atual do fim do buffer
        mov byte [bufferout + rsi], al                                  ; posiciona o caracter
        inc dword [rel finalBufferOut]                                  ; incrementa o registro de final do buffer
        inc rsi                                                         ; avança para próxima posição livre no buffer

    loop .loop_desempilhar_digitos                                      ; voltar para pegar o próximo caracter

    mov rax, rsi                                                        ; copiar o índice final do buffer de saída para rax

ret                                                                     ; volta o fluxo (final do buffer de saída -> rax)

.insta_print:                                                           ; rotina para escrever uma mensagem imediatamente no terminal (começo da mensagem -> rdi, tamanho da mensagem -> rsi)

    mov rdx, rsi                                                        ; posiciona argumento no lugar certo para syscall
    mov rsi, rdi                                                        ; posiciona argumento no lugar certo para syscall
    escrever rsi, rdx                                                   ; escreve mensagem na tela

ret                                                                     ; volta ao fluxo (sem retorno) 

.copiar_ao_buffer_out_com_curinga:                                      ; rotina para copiar texto ao buffer e substituir curinga (*) por uint32 (texto a copiar [com \0] -> rdi, quantidade de curingas -> rsi)

    push rbp                                                            ; salva valor âncora do stack-frame da rotina
    mov rbp, rsp                                                        ; copia estado da pilha no início da rotina para rbp

    inc rsi                                                             ; incrementa offset de argumentos para encontrar posição real na pilha pós-call
    mov r10, rsi                                                        ; copia offset para r10
    mov rdx, rdi                                                        ; libera rdi para ser usado como argummento depois
    xor rsi, rsi                                                        ; zera rsi para maior controle dos valores
    mov dword esi, [rel finalBufferOut]                                 ; carrega rsi com o índice final atual do buffer de saída

    .colocar_caracter:                                                  ; início da cópia de caracteres

        cmp byte [rdx], 0                                               ; confere se chegou no fim da string
        je .encerrar_colocar_caracter                                   ; instrução para encerrar parsing se chegou ao fim da string

        cmp byte [rdx], '*'                                             ; confere se caracter atual é curinga
        jne .nao_curinga                                                ; ignora adição de uint32 se não for curinga

            push rdx                                                    ; salva endereço atual da string sendo copiada
            mov rdi, [rbp + r10 * ENDERECOx64]                          ; recolhe argumento uint32 da pilha (stack-frame) para rdi
            call .parse_uint32_to_buffer_out                            ; faz parse para buffer de saída no valor de rdi

            pop rdx                                                     ; restaura endereço da string

            dec r10                                                     ; reduz quantidade de argumentos na pilha
            inc rdx                                                     ; salta para o próximo caracter da string a ser copiada                                                    

            jmp .colocar_caracter                                       ; volta para pegar próximo caracter

        .nao_curinga:                                                   ; label para pular substituição de curinga

        mov byte al, [rdx]                                              ; copia caracter da string para al (mov memória, memória não é possível)
        mov byte [bufferout + rsi], al                                  ; posiciona caracter no buffer de saída
        inc dword [rel finalBufferOut]                                  ; incrementa contagem de caracteres no buffer
        inc rsi                                                         ; incrementa posição atual do buffer de saída

        inc rdx                                                         ; incrementa endereço do caracter da string

    jmp .colocar_caracter                                               ; pegar próximo caracter se tiver
    .encerrar_colocar_caracter:                                         ; label para encerrar parsing

    mov rsp, rbp                                                        ; restaura estado da pilha do começo da rotina
    pop rbp                                                             ; desfaz stack-frame

ret                                                                     ; volta ao fluxo (sem retorno)

.evitar_buffer_out_overflow:                                            ; rotina para esvaziar buffer caso esteja cheio (sem argumentos)

    cmp dword [rel finalBufferOut], SIZBUFOUT                           ; compara se o buffer de saída está cheio
    jne .sem_buffer_overflow                                            ; pula o flush caso não esteja cheio
    
        call .flush_buffer_out                                          ; esvazia buffer de saída
        xor rsi, rsi                                                    ; rsi é usado na syscall, logo, é perdido e pode ser zerado pois subentende-se que ele é o controle do fim do buffer
    
    .sem_buffer_overflow:                                               ; label para pular esvaziamento do buffer de saída

ret                                                                     ; volta o fluxo (sem retorno)

.flush_buffer_out:                                                      ; rotina para esvaziar o buffer de saída (sem argumentos)

    cmp dword [rel finalBufferOut], 0                                   ; confere se tem algo no buffer de saída
    je .buffer_out_vazio                                                ; pula esvazziamento de buffer se não haver nada para printar

    mov rdi, bufferout                                                  ; carrega rdi com começo do buffer de saída
    xor rsi, rsi                                                        ; zerar rsi para maior controle dos valores
    mov dword esi, [rel finalBufferOut]                                 ; carrega rsi com quantidade de caracteres atual no buffer de saída
    call .insta_print                                                   ; mostra buffer de saída na tela

    mov [rel finalBufferOut], 0                                         ; zerar a contagem de caracteres no buffer
    .buffer_out_vazio:                                                  ; label para pular esvaziamento do buffer se estiver vazio

ret                                                                     ; volta o fluxo (sem retorno)

.inverte_array_uint32:                                                  ; rotina para inverter um array in-place (começo do array -> rdi | tamanho do array -> rsi)

    lea r8, [rdi + rsi * CAPUINT32 - CAPUINT32]                         ; calcula um endereço do fim do array a partir de rdi
    
    .loop_inversao_array_uint32:                                        ; começo do processo de trocar duas posições
    
        cmp r8, rdi                                                     ; confere se os endereços de começo e fim são coerentes (fim > começo)
        jle .encerrar_inversao                                          ; encerra a inversão caso tenha os endereços não sejam válidos

        mov dword r9d, [rdi]                                            ; A principio, copia-se [rdi] para r9d (r9d == [rdi] == A | [r8] == B)
        xor dword r9d, [r8]                                             ; A ^ B = C (r9d == A -> C)
        xor dword [r8], r9d                                             ; C ^ B = A ([r8] == B -> A)
        xor dword [rdi], r9d                                            ; C ^ A = B ([rdi] == A -> B)

        lea rdi, [rdi + CAPUINT32]                                      ; desloca ponteiro inferior 4 bytes para frente
        lea r8, [r8 - CAPUINT32]                                        ; desloca ponteiro superior 4 bytes para trás

        cmp r8, rdi                                                     ; confere se os ponteiros se encontraram ou cruzaram

    jmp .loop_inversao_array_uint32                                     ; volta se os ponteiros ainda não se encontraram
    .encerrar_inversao:                                                 ; label para encerrar inversão

ret                                                                     ; volta ao fluxo (sem retorno)