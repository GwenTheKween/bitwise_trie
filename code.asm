#####################################################################################################################
##########################  Trabalho feito por: Bruno Piazera Larsen, Numero USP: 9283872  ##########################
##########################      desenvolvido e testado no simulador Mars, versao 4.5       ##########################
#####################################################################################################################

	.data
	.align 2

#----------------------------------------------------------------------------------------------------------------------------------------------------------------
#valores com relacao a struct
node_size: .word 16
node_p_offset: .word 0 #poteiro para o pai
node_fe_offset: .word 4 #ponteiro para o filho esquerdo
node_fd_offset: .word 8 #ponteiro para o filho direito
node_terminal_offset: .word 12 #indicativo se o no eh terminal

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
#strings
#funcao main:
main_str_err: .asciiz "Opcao invalida, digite um numero entre 1 e 5, inclusive\n"
main_str_1: .asciiz "Escolha uma opcao:\n1)Adicionar um numero\n2)Buscar na arvore\n3)Remover um numero\n4)Imprimir a arvore\n5)sair\n"
main_str_2: .asciiz "Retornando ao Menu.\n"
#insert
add1_str: .asciiz "digite o binario para insercao: "
add2_str: .asciiz "Chave inserida com sucesso.\n"
add3_str: .asciiz "Chave repetida. Insercao nao permitida.\n"
#remove
rem1_str: .asciiz "digite o binario para remocao: "
rem2_str: .asciiz "Chave removida com sucesso.\n"
#busca
src1_str: .asciiz "digite o binario para busca: "
src2_str: .asciiz "Chave encontrada na arvore: "
src3_str: .asciiz "Chave nao encontrada na arvore: -1\n"
#imprime
imprime_nivel_str: .asciiz "N"
#imprimir o caminho
imprime_caminho_base_str: .asciiz "Caminho percorrido na arvore: raiz"
imprime_caminho_esq_str: .asciiz " esq"
imprime_caminho_dir_str: .asciiz " dir"
#imprime_no
imprime_no_abre_str: .asciiz " ("
imprime_no_raiz_str: .asciiz "raiz"
imprime_no_NT_str: .asciiz " NT"
imprime_no_T_str: .asciiz " T"
imprime_no_null_str: .asciiz " null"
imprime_no_fecha_str: .asciiz ")"
#controle
err_input: .asciiz "Chave invalida. Insira somente numeros binarios (ou -1 para retornar ao menu).\n"
debug_str: .asciiz "funcionando\n"
cmp_str: .asciiz "01\n-" #valores que a string de input pode assumir
EOL_str: .asciiz "\n"
virg_str: .asciiz ","
space_str: .asciiz " "
line_brk_str: .asciiz "____________________________________________________________________________________________________________\n"

#---------------------------------------------------------------------------------------------------------------------------------------------------------------
#espaco para armazenar a string de input
str_space: .space 17 #15 caracteres + "\n\0"
str_size: .word 17


#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
#variaveis globais:
#s6: numero de nos na arvore
#s7: endereco da raiz da arvore

	.text
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
#funcao main
main:
	#cria a raiz da arvore
	jal create_root
	
	#main menu loop
	main_loop_principal:
		#immprime string inicial do menu
		li $v0,4
		la $a0,main_str_1
		syscall
		
		#le numero do teclado
		li $v0,5
		syscall
		
		#armazena a opcao escolhida
		move $s0,$v0
	
		#switch case, input
		beq $s0,5,end_loop_principal#input = 5 : break
		ble $s0,0,main_loop_principal_wrong_input #input<=0 valor impossivel
		bgt $s0,5,main_loop_principal_wrong_input #input>5 valor impossivel
		beq $s0,4,main_loop_principal_prt #input = 4, imprime a arvore

		main_loop_secundario:
			#loop de selecao de chaves para uma operacao escolhida acima
			#quando o usuario digitar -1, a funcao retorna -1 em v0
			
			beq $s0,1,main_loop_secundario_add #if input = 1
			beq $s0,2,main_loop_secundario_src #if input = 2
			#else (input = 3)
				#funcao para remover uma chave da arvore
				jal remove
				beq $v0,-1,end_loop_secundario
				j main_loop_secundario
			main_loop_secundario_add:
				#funcao para inserir uma chave na arvore
				jal insere
				beq $v0,-1,end_loop_secundario
				j main_loop_secundario
			main_loop_secundario_src:
				#funcao de busca de uma chave
				jal busca
				beq $v0,-1,end_loop_secundario
				j main_loop_secundario
	end_loop_secundario:
		#ao sair do loop secundario, volta ao loop de escolher operacao
		j main_loop_principal
	main_loop_principal_prt:
		#imprime a arvore inteira
		jal imprime
		j main_loop_principal
	main_loop_principal_wrong_input:
		#caso o usuario tenha entrado com um valor impossivel (menor que 0, ou maior que 5)
		li $v0,4
		la $a0,main_str_err
		syscall
		j main_loop_principal
	end_loop_principal:
	#sai do programa
	li $v0,10
	syscall


#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
#argumentos: void
#retorno: v0:2(chave repetida), 1(sucess0), 0(chave incorreta) ou -1 (sair do loop)
insere:
	#push ra
	addi $sp,$sp,-4
	sw $ra,0($sp)
	#imprime strings iniciais
	li $v0,4
	la $a0,line_brk_str
	syscall
	la $a0,add1_str
	syscall
	#le a chave do teclado
	jal read_key
	#se a chave foi -1, retorna -1, indicando que deve-se sair do loop secundario na funcao main
	beq $v1,1,insere_exit_main_loop
	#se a chave foi invalida, retorna 0
	beqz $v0,insere_return
	
	#prepara os argumentos da busca, para saber se a chave ja foi inserida
	#no para realizaar a busca
	move $a0,$s7
	#chave buscada
	move $a1,$v0
	#profundidade atual
	li $a2,0
	jal rec_src
	
	#caso foi encontrado o no exato, retorna 2
	beq $v1,-1,insere_chave_encontrada
	
	#caso comtrario, cria o caminho para o no a ser inserido:
	#salva valor de v0 em s0
	addi $sp,$sp,-4
	sw $s0,0($sp)
	#v0 contem o no mais proximo ao que deve ser inserido, entao a insercao ocorre a partir dele
	move $s0,$v0
	
	#calcula profundidade desejada
	move $a0,$a1
	jal calc_prof
	#salva a profundidade desejada em s1
	addi $sp,$sp,-4
	sw $s1,0($sp)
	move $s1,$v0
	
	#salva a chave a ser inserida em s2
	addi $sp,$sp,-4
	sw $s2,0($sp)
	move $s2,$a1
	
	#salva profundidade atual em s3
	addi $sp,$sp,-4
	sw $s3,0($sp)
	move $s3,$v1
	
	insere_loop:
		#prepara os argumentos para chamar a funcao que cria um novo no
		#no atual, para ser o pai do no  recem inserido
		move $a0,$s0
		#endereco do caracter a ser inserido
		add $a1,$s2,$s3
		jal new_node
		#salva o novo no como "no atual"
		move $s0,$v0
		#incrementa a profundidade atual
		addi $s3,$s3,1
		#se a profundidade atual for igual a profundidade desejada, sai do loop
		beq $s3,$s1,insere_end_loop
		j insere_loop
	insere_end_loop:
	#armazena o no atual como terminal
	move $a0,$s0
	jal get_terminal
	li $a0,1
	sw $a0,($v0)
	#restaura o contexto
	lw $s3,0($sp)
	lw $s2,4($sp)
	lw $s1,8($sp)
	lw $s0,12($sp)
	addi $sp,$sp,16
	j insercao_bem_sucedida
	
insere_exit_main_loop:
	#a chave inserida foi -1, retorna -1 para informar o loop principal que deve-se sair do loop secundario
	li $v0,4
	la $a0,main_str_2
	syscall
	la $a0,line_brk_str
	syscall
	li $v0,-1
	j insere_return
insere_chave_encontrada:
	#a chave a ser inserida foi encontrada
	move $a0,$v0
	jal get_terminal
	lw $t0,($v0)
	#se t0 != 0, o no atual eh terminal, e portanto a chave ja foi inserida.
	bnez $t0,insere_chave_repetida
	#caso contrario, para inserir a chave, basta armazenar 1 em n->terminal para inserir
	li $t0,1
	sw $t0,($v0)
insercao_bem_sucedida:
	#avisa que a insercao bem sucedida
	li $v0,4
	la $a0,add2_str
	syscall
	la $a0,line_brk_str
	syscall
	# retorna 1
	li $v0,1
	j insere_return
insere_chave_repetida:
	#avisa que a insercao nao pode ser efetuada, por se tratar de uma chave repetida
	li $v0,4
	la $a0,add3_str
	syscall
	la $a0,line_brk_str
	syscall
	li $v0,2
	#j insere_return
insere_return:
	lw $ra,0($sp)
	addi $sp,$sp,4
	jr $ra
	

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
#argumentos: void
#retorni: $v0: -1 se for pra sair do loop
remove:
	#armazena o valor de retorno
	addi $sp,$sp,-4
	sw $ra,0($sp)
	
	#imprime as linhas iniciais
	li $v0,4
	la $a0,line_brk_str
	syscall
	la $a0,rem1_str
	syscall
	
	jal read_key
	
	beq $v1,1,remove_exit_loop
	
	#realiza uma busca, para saber se o no existe
	#a busca eh chamada aqui pois os passos, e o que deve ser impresso, sao quase iguais e - portanto - basta saber quem chamou a funcao de busca para ter a formatacao correta
	#para essa informacao, a funcao busca checa o registrador $s0, se ele contiver o valor 3, quem foi cahamdo na funcao main era a funcao remove, portanto a formatacao de "remove" eh usada
	jal busca
	#se a busca (e nao rec_src) retorna 0, o no nao foi encontrado, portanto pode-se sair da funcao
	beqz $v0,remove_return
	
	#armazena o contexto
	addi $sp,$sp,-8
	sw $s0,4($sp)
	sw $s1,0($sp)
	
	#salva o no a ser removido
	move $s0,$v0
	move $a0,$s0
	jal get_terminal
	#informa que o no onao eh mais terminal
	sw $zero,($v0)
	
	#loop para removao de todos os nos que pertenciam a apenas o caminho do noo removido
	#todas as condicoes de saida do loop devem ser checadas primeiro pois mesmo o primeiro no pode ser parte de outro caminho
	remove_loop:
		#se chegou na raiz, termina o loop
		beq $s0,$s7,remove_end_loop
		#se o no for terminal, termina o loop
		jal get_terminal
		lw $v0,($v0)
		bnez $v0,remove_end_loop
		#se o no tiver filhos termina o loop
		move $a0,$s0
		jal get_fe
		lw $v0,($v0)
		bnez $v0,remove_end_loop
		jal get_fd
		lw $v0,($v0)
		bnez $v0,remove_end_loop
		
		#se nenhuma da scondicoes acima ocorreu, o no precisa ser removido
		#reduz 1 na contagem de nos da arvore
		addi $s6,$s6,-1
		#O valor do pai eh zerado, para evitar vazamento de informacoes
		jal get_p
		 #armazena o no pai, que sera o novo no atual
		lw $s1,($v0)
		#zera o valor do pai no no filho
		sw $zero,($v0)
		#nenhum outro valor precisa ser emxido pois as checagens no comeco do loop
		#garantem que todas as outras informacoes sao nulas
		
		#remove a inforacao do no recem removido de seu no pai, para que o pai nao seja incorretamente classificado como um no ainda importante
		move $a0,$s1
		jal get_fe
		lw $t0,($v0)
		#se o no atual eh igual ao filho esquerdo do no pai, eh realizada a remocao do filho esquerdo
		beq $t0,$s0,remove_loop_esq
		#remove_loop_dir
			#caso contrario eh realizada a remocao do filho direito
			jal get_fd
			sw $zero,($v0)
			j remove_loop_end_if
		remove_loop_esq:
			sw $zero,($v0)
			#j remove_loop_end_if
		remove_loop_end_if:
		#muda o no atual para o pai do no recem-removido
		move $s0,$s1
		j remove_loop
	remove_end_loop:
	#imprime as strings finais
	li $v0,4
	la $a0,rem2_str
	syscall
	la $a0,line_brk_str
	syscall
	li $v0,0
	
	#restaura o contexto
	lw $s1,0($sp)
	lw $s0,4($sp)
	addi $sp,$sp,8
	j remove_return
	
	remove_exit_loop:
		#sair do loop secundario da funcao main
	li $v0,4
	la $a0,main_str_2
	syscall
	la $a0,line_brk_str
	syscall
	li $v0,-1
	#j remove_return
	
	remove_return:
	lw $ra,0($sp)
	addi $sp,$sp,4
	jr $ra
	


#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
#argumentos:void
#retorno: v0: endereco do no buscado (ou NULL), -1 para sair do loop
busca:
	#push ra
	addi $sp,$sp,-4
	sw $ra,0($sp)
	
	#se, quem chamou foi a funcao de remocao, pula a leitura de chave
	beq $s0,3,busca_pula_leitura
	
	#imprime string inicial
	li $v0,4
	la $a0,line_brk_str
	syscall
	la $a0,src1_str
	syscall
	#le a chave a ser buscada
	jal read_key
	beq $v1,1,busca_exit_loop
	beqz $v0,busca_input_errado
	
	busca_pula_leitura:
	#prepara os argumnetos da funcao recursiva de busca
	move $a0,$s7 #primeiro argumento: raiz da arvore
	move $a1,$v0 #segundo argumento, chave buscada
	li $a2,0 #terceiro argumento, profundidade
	jal rec_src
	
	#processa o retorno da busca
	bgez $v1, busca_node_not_found #if(v1>=0) node_not_found
	move $a0,$v0
	jal get_terminal
	lw $v0,($v0)
	beqz $v0, busca_node_not_found #if(node->terminal == 0) node_not_found

	#busca_node_found:
		#armazena o ponteiro do no
		addi $sp,$sp,-4
		sw $a0,($sp)
		#avisa que o no foi encontrado
		li $v0,4
		la $a0,src2_str
		syscall
		#imprime a chave encontrada
		move $a0,$a1
		syscall
		
		j busca_imprime_caminho
	busca_node_not_found:
		#avisa que o no nao foi encontrado
		addi $sp,$sp,-4
		#armazena NULL para ser retornado pela funcao
		sw $zero,($sp)
		li $v0,4
		la $a0,src3_str
		syscall
	busca_imprime_caminho:
	#prepara os argumentos
	#raiz da arvore
	move $a0,$s7
	jal imprime_caminho
	#carrega o valor de retorno da pilha
	lw $v0,($sp)
	addi $sp,$sp,4
	#se a busca foi chamada pela funcao de remocao, pula a impressao do final da funcao
	beq $s0,3,busca_retorno_sem_imprimir
	j busca_retorno
		
#chave digitada foi -1
busca_exit_loop:
	li $v0,4
	la $a0,main_str_2
	syscall
	li $v0,-1
	j busca_retorno
#input com erro
busca_input_errado:
	li $v0,0
	#j busca_retorno
busca_retorno:
	#imprime string final
	move $t0,$v0 #proteje o retorno
	li $v0,4
	la $a0,line_brk_str
	syscall
	move $v0,$t0
busca_retorno_sem_imprimir:
	lw $ra,0($sp)
	addi $sp,$sp,4
	jr $ra

	
	
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
#argumentos: void
#retorno: void
imprime:
	#a funcao funciona por realizar uma busca em largura na arvore, usando a pilha como um vetor de variaveis locais, e interpretando esse vetor como uma pilha
	#salva o contexto
	addi $sp,$sp,-28
	sw $ra,24($sp)
	sw $s0,20($sp) #armazenara o no atual
	sw $s1,16($sp) #armazenara a frente da fila
	sw $s2,12($sp) #armazenara o fim da fila
	sw $s3,8($sp) #armazenara a condicao para imprimir EOL
	sw $s4,4($sp) #armazenara a profundidade atual
	sw $s5,0($sp) #armazenara quantos nos foram impressos
	#imprime o line break inicial
	li $v0,4
	la $a0,line_brk_str
	syscall
	#aloca memoria local
	li $t0,-4
	mult $t0,$s6 #multiplica a quantidade de nos por -4
	mflo $t0
	add $sp,$sp,$t0 #aloca um vetor de inteiros de tamanho $s6 na pilha, como variaveis locais
	
	#se a quantidade de nos for apenas 1, so eh necessario imprimir a raiz
	#essa diferenca evita que algumas condicoes de contorno tenham que ser checadas no comeco do loop, que so ocorrem se a arvore for ocmposta apenas de raiz
	beq $s6,1,imprime_unico_elemento
	
	#armazena a raiz da arvore como no atual
	move $s0,$s7
	#aponta os ponteiros da fila
	move $s1,$sp
	move $s2,$sp
	#nenhum no foi impresso ate agora
	li $s5,0
	
	#insere o primeiro elemento na fila
	sw $s0,($s2)
	addi $s2,$s2,4
	#imprime o identificador de nivel
	li $v0,4
	la $a0,imprime_nivel_str
	syscall
	li $v0,1
	li $a0,0
	syscall
	#a condicao de EOL eh calculada como o elemento mais a esquerda do proximo nivel, ja que a busca ocorre da esquerda para a direita
	#quando ela for atingida, o valor eh resetado para 0, para o caso em que o caminho atual terminou, mas essa nao eh a profuncidade maxima da arvore
	#A primeira condicao de EOL eh o filho esquerdo da raiz, se ele existir, ou oo filho direito, se o primeiro nao existir
	move $a0,$s0
	jal get_fe
	lw $v0,($v0)
	beqz $v0, imprime_raiz_direito
	#imprime_raiz_esquerdo
		#a condicao de EOL sera quando o filho esquedo da raiz for encontrado
		move $s3,$v0
		j imprime_loop
	imprime_raiz_direito:
		jal get_fd
		lw $s3,($v0)
	
	imprime_loop:
		#pop $s0
		lw $s0,($s1)
		addi $s1,$s1,4
		
		 #se a condicao de EOL tem valor 0, a profundidade eh a mesma
		beqz $s3,imprime_loop_mesma_profundidade
		#se o no atual nao eh igual a condicao de EOL, a profundidade eh a mesma
		bne $s0,$s3,imprime_loop_mesma_profundidade 
		#imprime_loop_muda_profundidade
			#imprime "\n'
			li $v0,4
			la $a0,EOL_str
			syscall
			#imprime o indicador de nivel
			la $a0,imprime_nivel_str
			syscall
			#imprime o valor do nivel atual
			addi $a0,$s4,1
			li $v0,1
			syscall
			#aumenta a profundidade e reseta a condicao de EOL
			move $s4,$a0
			li $s3,0
		imprime_loop_mesma_profundidade:
		move $a0,$s0
		#se s3!=0 a condicao de EOL esta ok, nao precisa ser mudada
		bnez $s3,imprime_loop_skip_EOL
		#imprime_loop_set_EOL
			jal get_fe
			lw $v0,($v0)
			#se o no possui filho esquerdo, este eh a nova condicao de EOL
			beqz $v0,imprime_loop_set_EOL_fd
			#imprime_loop_set_EOL_fe
				move $s3,$v0
				j imprime_loop_skip_EOL
			imprime_loop_set_EOL_fd:
				jal get_fd
				#se o no tiver um filho direito, a condicao de EOL esta corretamente configurada
				#se o filho direito nao existir, a condicao de EOL continua com 0
				lw $s3,($v0)
				
		imprime_loop_skip_EOL:
		#imprime o no, segundo a epecificacao
		jal imprime_no
		#adiciona o filho esquerdo a fila, se ele existir
		move $a0,$s0
		jal get_fe
		lw $v0,($v0)
		beqz $v0,imprime_loop_push_fd
		#if fe!=NULL
		#imprime_loop_push_fe
			sw $v0,($s2)
			addi $s2,$s2,4
		imprime_loop_push_fd:
		#adiciona o filho direito a fila, se ele existir
		jal get_fd
		lw $v0,($v0)
		beqz $v0,imprime_loop_continue
		#if fd!=NULL
			sw $v0,($s2)
			addi $s2,$s2,4
		imprime_loop_continue:
		#aumenta 1 na quantidade de nos impressos
		addi $s5,$s5,1
		#caso tenham sido impressos menos nos que o total presente na arvore, roda o loop novamente
		blt $s5,$s6,imprime_loop
	#depois de terminar o loop eh necessario imprimir EOL novamente
	li $v0,4
	la $a0,EOL_str
	syscall
	j imprime_return
	
	imprime_unico_elemento:
	#so existe a raiz na arvore
		li $v0,4
		la $a0,imprime_nivel_str
		syscall
		li $v0,1
		li $a0,0
		syscall
		move $a0,$s7
		jal imprime_no
		li $v0,4
		la $a0,EOL_str
		syscall
	#j imprime_return
	
	imprime_return:
	#imprime o line break final
	li $v0,4
	la $a0,line_brk_str
	syscall
	#ignora as variaveis locais
	li $t0,4
	mult $t0,$s6
	mflo $t0
	add $sp,$sp,$t0
	#restaura o contexto
	lw $s5,0($sp)
	lw $s4,4($sp)
	lw $s3,8($sp)
	lw $s2,12($sp)
	lw $s1,16($sp)
	lw $s0,20($sp)
	lw $ra,24($sp)
	addi $sp,$sp,28
	jr $ra
	
	
	
	
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
#argumentos: void
#Return: s6:numero de nos; s7: raiz da arvore
create_root:
	#salva o endereco de retorno
	addi $sp,$sp,-4
	sw $ra,0($sp)
	#aloca memoria pra raiz
	li $v0,9
	lw $a0,node_size
	syscall
	
	#salva o endereco da raiz
	move $s7,$v0
	move $a0,$s7
	
	#carrega o outro valor global
	li $s6,1
	
	#configura todos os campos da raiz como 0
	jal get_p
	sw $zero,0($v0)
	
	jal get_fe
	sw $zero,0($v0)
	
	jal get_fd
	sw $zero,0($v0)
	
	jal get_terminal
	sw $zero,0($v0)
	
	#return
	lw $ra,0($sp)
	addi $sp,$sp,4
	jr $ra


#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
#argumentos: a0 node* pai,a1: char* k
#return: v0: enderco do novo no
new_node:
	#push s0,s1
	add $sp,$sp,-12
	sw $ra,8($sp)
	sw $s0,4($sp)
	sw $s1,0($sp)
	#salvar os argumentos:
	move $s0,$a0
	move $s1,$a1
	
	#aloca memoria
	li $v0,9
	lw $a0,node_size
	syscall
	
	move $a0,$v0
	
	#configura o pai
	jal get_p
	sw $s0,0($v0)
	
	#configura o ponteiro do pai para o filho
	move $s0,$a0 #armazena o ponteiro recem alocado
	move $a0,$v0 #carrega o ponteiro do pai
	lw $a0,($a0)
	#carrega o byte da chave inserida
	lb $t0,($s1)
	#se a chave for 1, o filho direito esta sendo inserido
	beq $t0,'1',new_node_dir
	#new_node_esq
		#caso contrario, configura o ponteiro do filho esquerdo
		jal get_fe
		sw $s0,0($v0)
		j new_node_end_if
	new_node_dir:
		#configura o ponteiro do filho direito
		jal get_fd
		sw $s0,0($v0)
	
new_node_end_if:
	lw $a0,($v0)#a0 volta a ter o endereco do novo no
	
	#configura todos os campos do novo no com 0
	jal get_fe
	sw $zero,0($v0)
	
	jal get_fd
	sw $zero,0($v0)
	
	jal get_terminal
	sw $zero,0($v0)
	
	#incrementa a quantidade de nos da arvore
	addi $s6,$s6,1

new_node_return:
	#restaura o contexto e retorna
	lw $s1,0($sp)
	lw $s0,4($sp)
	lw $ra,8($sp)
	addi $sp,$sp,12
	move $v0,$a0
	jr $ra
	
	
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
#argumentos: void
#return: v0, string lida, ou 0 se string invalida, v1 = 1 se sair do loop, 0 caso contrario
read_key:
	#leitura da chave a ser manipulada
	#read string
	li $v0,8
	la $a0,str_space
	lw $a1,str_size
	syscall
	
	#compara string,para ver se so tem 0 e 1
	move $t0,$a0
	la $t2,cmp_str
	lb $t3,0($t2) #carrega o 0 de t2
	lb $t4,1($t2) #carrega o 1 de t2
	lb $t5,2($t2) #carrega condicao de parada
	lb $t1,($t0)
	beqz $t1,invalido #se entroou com string vazia o input eh invalido
	loop_read_key:
		lb $t1,($t0)
		beq $t1,$t3,inc_t0 #if t0='0' t0++
		beq $t1,$t4,inc_t0 #if t0='1' t0++
		beq $t1,$t5,end_loop_read_key #if t0='\n' break
		#se nenhuma das condicoes acima foi satisfeita, a string tem algo que nao eh nem 0, nem 1, nem a condicao de parada.
		#pula para a checagem se o que foi inserido eh '-1'
		j check_exit_key
		inc_t0:
			addi $t0,$t0,1
			j loop_read_key
	end_loop_read_key:
		#chave formatada corretamente
		move $v1,$zero
		move $v0,$a0
		#retorna
		jr $ra
	check_exit_key:
		#algo diferente de '0','1' e '\n' foi inserido, checa se a string eh igual a '-1\n'
		lb $t0,0($a0)
		lb $t1,1($a0)
		lb $t3,3($t2) #carrega o '-'
		lb $t4,1($t2) #carrega o '1'
		bne $t0,$t3,invalido #if(t0!='-') invalido
		bne $t1,$t4,invalido #if(t1!='1') invalido
		#a chave entrada eh para sair do loop
		li $v1,1
		jr $ra
	invalido:
		#input invalido, avisa e retorna 0,0
		li $v0,4
		la $a0,err_input
		syscall
		move $v1,$zero
		move $v0,$zero
		jr $ra	


#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
#argumentos: a0 endereco do no atual,a1 chave buscada,a2 profundidade
#retorno: v0: endereco mais proximo do buscado, v1: igual ao inserdo (0) ou qual profundidade chegou
rec_src:
	#funcao de busca recursiva
	#Se encontrou \n, encontrou o no buscado
	li $t0,'\n'
	add $t1,$a1,$a2
	lb $t1,($t1)
	beq $t0,$t1,rec_src_found
	
	#push ra
	addi $sp,$sp,-4
	sw $ra,0($sp)
	
	#para qual lado descer
	li $t0,'0'
	beq $t0,$t1,rec_src_left
	

	#rec_src_right:
		#argumentos ja carregados: a0, no atual
		jal get_fd
		j rec_src_body
	rec_src_left:
		jal get_fe
		
		
#corpo da busca: se nao nulo, chama recursivamente
rec_src_body:
	lw $v0,($v0) #carrega o endereco do filho desejado
	beqz $v0,rec_src_not_found #se nao possui o filho desejado, termina a recursao
	move $a0,$v0 #prepara os argumentos para chamada recursiva
	addi $a2,$a2,1
	#as linhas abaixo equivalem a dizer 
	#return rec_src($a0,$a1,$a2+1)
	jal rec_src #chamada recursiva
	j rec_src_return #retorno
	
	
	#prepara os argumentos para retorno, caso o fim da recursao tenha sido encontrado
	rec_src_found:
		#$v0 tem o endereco do no buscado
		move $v0,$a0
		#profundidade atual vale -1, indicado que se chegou exatamente no no desejado
		li $v1,-1
		j rec_src_return
	rec_src_not_found:
		#$v0 tem o endereco mais proximo do no buscado, para realizar a insercao
		move $v0,$a0
		#$v1 tem a profundidade atual
		move $v1,$a2
		#j rec_src_return
		
		
rec_src_return:
	#pop ra
	lw $ra,0($sp)
	addi $sp,$sp,4
	jr $ra
	

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
#argumentos: a0: raiz da arvore, a1 key
#retorno: void
imprime_caminho:
	#inprime o caminho percorrido na busca por uma chave
	#salva o contexto
	addi $sp,$sp,-12
	sw $ra,8($sp)
	sw $s0,4($sp)
	sw $s1,0($sp)
	move $s0,$a0 #guarda o no atual em s0
	li $s1,0 #profundidade
	
	#imprime a string inicial
	li $v0,4
	la $a0,imprime_caminho_base_str
	syscall
	#carrega o primeiro valor da chave
	add $t1,$s1,$a1
	lb $t1,($t1)
	imprime_caminho_loop:
		#imprime uma virgula
		li $v0,4
		la $a0,virg_str
		syscall
		beq $t1,'1',imprime_caminho_loop_dir
		#imprime_caminho_loop_esq
			#se a chave atual eh '0', imprime a string ' esq' e carrega o filho esquerdo
			li $v0,4
			la $a0,imprime_caminho_esq_str
			syscall
			move $a0,$s0
			jal get_fe
			j imprime_caminho_end_if
		imprime_caminho_loop_dir:
			#se a chave atual eh '1', imprime a string ' dir' e carrega o filho direito
			li $v0,4
			la $a0,imprime_caminho_dir_str
			syscall
			move $a0,$s0
			jal get_fd
		imprime_caminho_end_if:
		lw $t1,($v0)
		#se o ponteiro do filho aponta para NULL, sai do loop
		beqz $t1,imprime_caminho_end_loop
		#senao carrega o novo no atual, para continuar imprimindo
		move $s0,$t1
		addi $s1,$s1,1
		add $t1,$s1,$a1
		lb $t1,($t1)
		beq $t1,'\n',imprime_caminho_end_loop #se encontrou a condicao de parada da string, sai do loop
		j imprime_caminho_loop
	imprime_caminho_end_loop:
	#imprime o fim de linha
	li $v0,4
	la $a0,EOL_str
	syscall
	#restaura o contexto
	lw $s1,0($sp)
	lw $s0,4($sp)
	lw $ra,8($sp)
	addi $sp,$sp,12
	jr $ra
	

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------	
#argumentos: a0: no
#retorno: void
imprime_no:
	#imprime o no passado, segundo a formatacao desejada
	addi $sp,$sp,-8
	sw $ra,4($sp)
	sw $s0,0($sp)
	
	move $s0,$a0
	li $v0,4
	la $a0,imprime_no_abre_str
	syscall
	
	#calcula a chave do no sendo impresso
	#se o no a ser impresso eh a raiz da arvore, entra num caso especial
	beq $s0,$s7,imprime_no_raiz
	move $a0,$s0
	#carrega o ponteiro do pai
	jal get_p
	lw $a0,($v0)
	#carrega o ponteiro do filho esquerdo do pai.
	jal get_fe
	lw $v0,($v0)
	#se o no atual for igual ao filho esquerdo do pai, a chave eh '0', senao a chave eh '1'
	bne $s0,$v0,imprime_no_1
	#imprime_no_0:
		li $v0,1
		li $a0,0
		syscall
		#a continuacao do programa assume $v0=4. para acelerar a execucao
		li $v0,4
		j imprime_no_terminal
	imprime_no_1:
		li $v0,1
		li $a0,1
		syscall
		#a continuacao do programa assume $v0=4. para acelerar a execucao
		li $v0,4
		j imprime_no_terminal
	imprime_no_raiz:
		li $v0,4
		la $a0,imprime_no_raiz_str
		syscall
		#j imprime_no_termianl
	imprime_no_terminal:
	#imprime uma virgula
	la $a0,virg_str
	syscall
	#calcula se o no eh terminal
	move $a0,$s0
	jal get_terminal
	lw $v0,($v0)
	beqz $v0,imprime_no_NT
	#imprime_no_T:
		#se o no for terminal, imprime 'T'
		li $v0,4
		la $a0,imprime_no_T_str
		syscall
		j imprime_no_fe
	imprime_no_NT:
		#caso contrario imprime 'NT'
		li $v0,4
		la $a0,imprime_no_NT_str
		syscall
		#j imprime_no_fe
	imprime_no_fe:
	#imprime o filho esquerdo do no
	la $a0,virg_str
	syscall
	move $a0,$s0
	jal get_fe
	lw $v0,($v0)
	beqz $v0,imprime_no_fe_null
	#imprime_no_fe_notNull
		#se o ponteiro para o filho esquedo nao for nulo, imprime o endereco
		move $t0,$v0
		#imprime ' ' para formatacao
		li $v0,4
		la $a0,space_str
		syscall
		li $v0,1
		move $a0,$t0
		syscall
		#novamente, $v0 = 4 eh assumido na parte seguinte do programa
		li $v0,4
		j imprime_no_fd
	imprime_no_fe_null:
		#se o filho esquerdo for nulo, imprime 'null' conforme a formatacao solicitada
		li $v0,4
		la $a0,imprime_no_null_str
		syscall
		#j imprime_no_fd
	imprime_no_fd:
	#realiza o mesmo algoritmo acima, agora trabalhando com o filho direito
	la $a0,virg_str
	syscall
	move $a0,$s0
	jal get_fd
	lw $v0,($v0)
	beqz $v0,imprime_no_fd_null
	#imprime_no_fd_notNull
		move $t0,$v0
		li $v0,4
		la $a0,space_str
		syscall
		li $v0,1
		move $a0,$t0
		syscall
		j imprime_no_fecha
	imprime_no_fd_null:
		li $v0,4
		la $a0,imprime_no_null_str
		syscall
		#j imprime_no_fecha
	imprime_no_fecha:
	#fecha os parentesis
	li $v0,4
	la $a0,imprime_no_fecha_str
	syscall
	#restaura o contexto
	lw $s0,0($sp)
	lw $ra,4($sp)
	addi $sp,$sp,8
	jr $ra
	
	
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
#argumentos a0: char* k
##retorno: $v0: strlen(k)
calc_prof:
	#calcula a profundidade do no a ser manipulado
	li $t0,'\n' # condicao de parada
	li $v0,0 #inicia valor de retorno
	calc_prof_loop:
		lb $t1,($a0)
		beq $t1,$t0,calc_prof_end_loop
		addi $a0,$a0,1
		addi $v0,$v0,1
		j calc_prof_loop
calc_prof_end_loop:
	jr $ra
#---------------------------------------------------------------------------------------------------------------------------------------------------------------------
#argumentos: a0: node* n
#return: $v0: n->p
get_p:
	#retorna o endereco em que foi armazenado o no pai de $a0
	lw $t0,node_p_offset
	add $v0,$a0,$t0
	jr $ra
	

#------------------------------------------------------------------------------------------------------------
#argumento: a0: node* n
#return v0: n->fe
get_fe:
	#retorna o endereco em que foi armazenado o filho esquerdo de $a0
	lw $t0,node_fe_offset
	add $v0,$a0,$t0
	jr $ra


#------------------------------------------------------------------------------------------------------------------------------
#argumentos: a0: node* n
#return v0: n->fd
get_fd:
	#retorna o endereco em que foi armazenado o filho direito de $a0
	lw $t0,node_fd_offset
	add $v0,$a0,$t0
	jr $ra


#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------
#argumentos: a0 node* n
#return v0 n->terminal
get_terminal:
	#retorna o endereco em que foi armazenado se $a0 eh terminal
	lw $t0,node_terminal_offset
	add $v0,$a0,$t0
	jr $ra
	
	
