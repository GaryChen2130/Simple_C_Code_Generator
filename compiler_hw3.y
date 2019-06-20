/*	Definition section */
%{

#include <stdio.h>
#include <stdbool.h>
#include <string.h>

int local_cnt;
int error_num;
int func_flag;
int id_flag;
int op_flag;
int declare_line;
extern int yylineno;
extern int yylex();
extern char *yytext;   // Get current token from lex
char *error_msg;
char *buff_tmp;
char *id_buff;
static char *cast_type;
extern char buf[256];  // Get current code line from lex

FILE *file;

/* Symbol table function - you can add new function if needed. */
int lookup_symbol(char *);
void create_symbol();
void insert_symbol(char *symbol_name,char *entry_name, char *data_name, int ffd_flag);
void dump_symbol();

int syntax_error_flag;

typedef struct entry{

	int entry_num;
	char *name;
	char *entry_type;
    char *data_type;
    int scope_level;
    char *parameters;
    struct entry *next;
	int ffd_flag;

	char *value_type;
	int int_const;
	float float_const;
	char *str_const;
	int asgn_flag;
	int reg_num;

} Entry;

Entry *table_head;

void Insert_Entry(Entry **, Entry *);
Entry *Remove_Entry();
void yysemantic(int);
void Print_Table(int);
void Change_Table_Flag(char *);
int Remove_Redundant();
int Check_Table();
Entry *Get_Entry(char *);
void Casting(char *,char *);
void *Check_Casting(char *,char *,char *);

%}

/* Use variable or self-defined structure to represent
 * nonterminal and token type
 */
%union {
    int i_val;
    double f_val;
    char* string;
}

/* Token without return */
%token PRINT 
%token IF ELSE FOR WHILE
%token SEMICOLON RET CONT BREAK
%token ADD SUB MUL DIV MOD INC DEC
%token MT LT MTE LTE EQ NE
%token AND OR NOT LB RB LCB RCB LSB RSB COMMA QUATA

/* Token with return, which need to sepcify type */
%token <i_val> I_CONST
%token <f_val> F_CONST
%token <string> STR_CONST
%token <string> ID
%token <string> STRING INT FLOAT BOOL VOID TRUE FALSE
%token <string> ASGN ADDASGN SUBASGN MULASGN DIVASGN MODASGN

/* Nonterminal with return, which need to sepcify type */
%type <string> type
%type <string> func_def declaration declaration_specs declarator 
%type <string> parameter_list parameter_declaration
%type <string> init_declarator_list init_declarator
%type <string> assign_expression logical_or_expression logical_and_expression
%type <string> equality_expression relation_expression
%type <string> add_expression mul_expression
%type <string> unary_expression postfix_expression primary_expression
%type <string> assign_op
%type <string> id_var

/* Yacc will start at this nonterminal */
%start program

/* Grammar section */
%%

program
    : global_declaration
    | program global_declaration
;

global_declaration 
    : func_def
    | declaration
;

func_def 
    : declaration_specs declarator declaration_list {	if(!strcmp(table_head -> name, "main"))
															fprintf(file, ".method public static main([Ljava/lang/String;)V\n");
														else{
															char *str = strdup($2),*tmp;
															fprintf(file,".method public static %s(",strtok(str,"|"));
															while((tmp = strtok(NULL,", ")) != NULL){
																if(!strcmp(tmp,"int"))
																	fprintf(file,"I");
																else if(!strcmp(tmp,"float"))
																	fprintf(file,"F");
																else if(!strcmp(tmp,"bool"))
																	fprintf(file,"Z");
																else if(!strcmp(tmp,"string"))
																	fprintf(file,"Ljava/lang/String");	
															}

															tmp = strdup($1);
															if(!strcmp(tmp,"int"))
																fprintf(file,")I\n");
															else if(!strcmp(tmp,"float"))
																fprintf(file,")F\n");
															else if(!strcmp(tmp,"bool"))
																fprintf(file,")Z\n");
															else if(!strcmp(tmp,"string"))
																fprintf(file,")Ljava/lang/String\n");	
															else if(!strcmp(tmp,"void"))
																fprintf(file,")V\n");

														}
														fprintf(file,".limit stack 50\n.limit locals 50\n");

													} compound_stat	{	

														int lookup_num;
	                  						  			char *tmp = strdup($2);
			  											char *id = strtok(tmp,"|");
		          										lookup_num = lookup_symbol(id);
			  											if(lookup_num < 0){
			      											insert_symbol($2, "function", $1, 0);
			  											}
			  											else if(lookup_num == 2){
			      											Change_Table_Flag(id);
			  											}
			  											else{
			      											error_num = 3;
		 	      											if(error_msg == NULL)
			          											error_msg = strdup("Redeclared function ");
			      											else
			          											strcpy(error_msg,"Redeclared function ");
			      											strcat(error_msg, id);
			  											}
														fprintf(file, ".end method\n");
													}

    | declaration_specs declarator	{	if(!strcmp(table_head -> name, "main"))
											fprintf(file, ".method public static main([Ljava/lang/String;)V\n");
										else{
											char *str = strdup($2),*tmp;
											fprintf(file,".method public static %s(",strtok(str,"|"));
											while((tmp = strtok(NULL,", ")) != NULL){
												if(!strcmp(tmp,"int"))
													fprintf(file,"I");
												else if(!strcmp(tmp,"float"))
													fprintf(file,"F");
												else if(!strcmp(tmp,"bool"))
													fprintf(file,"Z");
												else if(!strcmp(tmp,"string"))
													fprintf(file,"Ljava/lang/String");	
											}

											tmp = strdup($1);
											if(!strcmp(tmp,"int"))
												fprintf(file,")I\n");
											else if(!strcmp(tmp,"float"))
												fprintf(file,")F\n");
											else if(!strcmp(tmp,"bool"))
												fprintf(file,")Z\n");
											else if(!strcmp(tmp,"string"))
												fprintf(file,")Ljava/lang/String\n");	
											else if(!strcmp(tmp,"void"))
												fprintf(file,")V\n");

										}
										fprintf(file,".limit stack 50\n.limit locals 50\n");

									} compound_stat	{	

										int lookup_num;
							            char *tmp = strdup($2);
									  	char *id = strtok(tmp,"|");
								        lookup_num = lookup_symbol(id);
									  	if(lookup_num < 0){
									    	insert_symbol($2, "function", $1, 0);
									  	}
									  	else if(lookup_num == 2){
									    	Change_Table_Flag(id);
									  	}
									  	else{
									    	error_num = 3;
								 	    	if(error_msg == NULL)
									    		error_msg = strdup("Redeclared function ");
									    	else
									    		strcpy(error_msg,"Redeclared function ");
									    	strcat(error_msg, id);
									  	}
										fprintf(file, ".end method\n");
									}

    | declarator declaration_list compound_stat
    | declarator compound_stat
;

declaration_specs 
    : type						{$$ = $1;}
    | type declaration_specs	{;}
;

declarator 
    : ID																	{$$ = strdup(yytext); strcpy(table_head -> name, yytext);}
    | LB declarator RB														{;}
    | declarator LB enter_scope reset_local parameter_list RB leave_scope	{
								    											$$ = strcat(strcat($1,"|"), $5);
								    											func_flag = 1;
								    											declare_line = yylineno;
																			}
    | declarator LB id_list RB	{;}
    | declarator LB reset_local RB	{$$ = $1; func_flag = 1; declare_line = yylineno;}
;

declaration_list 
    : declaration
    | declaration_list declaration
;

compound_stat 
    : LCB enter_scope RCB leave_scope
    | LCB enter_scope block_item_list RCB leave_scope
;

reset_local :	{local_cnt = 0; }

enter_scope :	{
					++(table_head -> scope_level);
					func_flag = 0; 
					/*printf("%d\n",table_head -> scope_level);*/
				}
leave_scope : {--(table_head -> scope_level); }

block_item_list
    : block_item
    | block_item_list block_item
;

block_item 
    : declaration_list
    | stat_list
;

stat_list 
    : stat
    | stat_list stat
;

declaration 
    : declaration_specs SEMICOLON				
    | declaration_specs init_declarator_list SEMICOLON	{	int lookup_num,redundant_flag;
															char *tmp = strdup($2);
															char *id = strtok(tmp,"|");
															lookup_num = lookup_symbol(id);
															if((lookup_num != 1) && (lookup_num != 2)){
								    							if(!func_flag){

																	char *data_type;

																	if(!strcmp($1,"int"))
																		data_type = strdup("I");
																	else if(!strcmp($1,"float"))
																		data_type = strdup("F");
																	else if(!strcmp($1,"string"))
																		data_type = strdup("Ljava/lang/String");
																	else if(!strcmp($1,"bool"))
																		data_type = strdup("Z");
																	else
																		data_type = strdup($1);

																	if(table_head -> scope_level == 0){ // Global Variable
																		if(!(table_head -> asgn_flag)){ // Without Initialize
																			fprintf(file, ".field public static %s %s\n",$2,data_type);
																			table_head -> int_const = 0;
																			table_head -> float_const = 0;
																		}
																		else{ // With Initialize

																			if((!strcmp($1,"int")) || (!strcmp($1,"bool"))){
																				if(!strcmp(table_head -> value_type,"F")){
																					fprintf(file,"    f2i\n");
																					table_head -> int_const = table_head -> float_const;
																				}
																				fprintf(file, ".field public static %s %s = %d\n",$2,data_type,table_head -> int_const);
																			}
																			else if(!strcmp($1,"float")){
																				if(!strcmp(table_head -> value_type,"I")){
																					fprintf(file,"    i2f\n");
																					table_head -> float_const = table_head -> int_const;
																				}
																				fprintf(file, ".field public static %s %s = %f\n",$2,data_type,table_head -> float_const);
																			}
																			else if(!strcmp($1,"string"))
																				fprintf(file, ".field public static %s %s = \"%s\"\n",$2,data_type,table_head -> str_const);
																			
																			table_head -> asgn_flag = 0;
																		}
																	}
																	else{ // Local Variable
																		if(!(table_head -> asgn_flag)){ // Without Initialize
																			if(!strcmp($1,"float")){
																				fprintf(file, "    ldc 0\n    fstore %d\n",local_cnt++);
																				table_head -> float_const = 0;
																			}
																			else{
																				fprintf(file, "    ldc 0\n    istore %d\n",local_cnt++);
																				table_head -> int_const = 0;
																			}
																		}
																		else{ // With Initialize

																			if((!strcmp($1,"int")) || (!strcmp($1,"bool"))){
																				if(!strcmp(table_head -> value_type,"F")){
																					fprintf(file,"    f2i\n");
																					table_head -> int_const = table_head -> float_const;
																				}
																				fprintf(file, "    istore %d\n",local_cnt++);
																			}
																			else if(!strcmp($1,"float")){
																				if(!strcmp(table_head -> value_type,"I")){
																					fprintf(file,"    i2f\n");
																					table_head -> float_const = table_head -> int_const;
																				}
																				fprintf(file, "    fstore %d\n",local_cnt++);
																			}
																			else if(!strcmp($1,"string"))
																				fprintf(file, "    istore %d\n",local_cnt++);
																			
																			table_head -> asgn_flag = 0;
																		}
																		
																	}

								    							    insert_symbol($2, "variable", $1, 0);
																		
																}
								    							else{ // For function foward declaration
																	insert_symbol($2, "function", $1, 1);
																	do{
									    								redundant_flag = Remove_Redundant();
																	}while(redundant_flag);
								    							}
															}
															else if (lookup_num == 1){
																error_num = 4;
																if(error_msg == NULL)
																	error_msg = strdup("Redeclared variable ");
																else
																	strcpy(error_msg,"Redeclared variable ");
																strcat(error_msg, id);
															}
															else if (lookup_num == 2){
																error_num = 3;
																if(error_msg == NULL)
																	error_msg = strdup("Redeclared function ");
																else
																	strcpy(error_msg,"Redeclared function ");
																do{
									    							redundant_flag = Remove_Redundant();
																}while(redundant_flag);
																strcat(error_msg, id);
															}
															func_flag = 0;
														}
;

stat 
    : compound_stat
    | expression_stat
    | select_stat
    | loop_stat
    | jump_stat
    | print_stat
;

print_stat 
    : PRINT LB QUATA STR_CONST QUATA RB SEMICOLON
    | PRINT LB primary_expression RB SEMICOLON		{
    													if(id_flag && (lookup_symbol($3) < 0)){
															error_num = 2;
															if(error_msg == NULL)
																error_msg = strdup("Undeclared variable ");
															else
																strcpy(error_msg, "Undeclared variable ");
															strcat(error_msg,$3);
														}

														if(id_flag){
															Entry *entry = Get_Entry($3);
															if(entry -> scope_level == 0)
																fprintf(file,"    getstatic compiler_hw3/%s %s\n",entry -> name,table_head -> value_type);
															else if(!strcmp(entry -> data_type,"float"))
																fprintf(file,"    fload %d\n",entry -> reg_num);
															else
																fprintf(file,"    iload %d\n",entry -> reg_num);
														}
														else if((!strcmp(table_head -> value_type,"I")) || (!strcmp(table_head -> value_type,"Z")))
															fprintf(file,"    ldc %d\n",table_head -> int_const);
														else if(!strcmp(table_head -> value_type,"F"))
															fprintf(file,"    ldc %f\n",table_head -> float_const);
														else if(!strcmp(table_head -> value_type,"Ljava/lang/String"))
															fprintf(file,"    ldc \"%s\"\n",table_head -> str_const);

														fprintf(file,"    getstatic java/lang/System/out Ljava/io/PrintStream;\n");
														fprintf(file,"    swap\n");
														fprintf(file,"    invokevirtual java/io/PrintStream/println(%s)V\n",table_head -> value_type);

													}
;

id_var 
    : ID	{$$ = strdup(yytext);}
;

expression_stat 
    : SEMICOLON
    | expression SEMICOLON
;

select_stat 
    : IF LB expression RB stat
    | IF LB expression RB stat ELSE stat
;

loop_stat 
    : WHILE LB expression RB stat
;

jump_stat 
    : CONT SEMICOLON
    | BREAK SEMICOLON
    | RET SEMICOLON				{fprintf(file, "    return\n");}
    | RET expression SEMICOLON  {
									if(!strcmp(table_head -> value_type,"F"))
										fprintf(file, "    freturn\n");
									else
										fprintf(file, "    ireturn\n");
								}
;

expression 
    : assign_expression
    | expression COMMA assign_expression
;

assign_expression 
    : logical_or_expression	{$$ = $1;}
    | unary_expression {id_flag = 0;} assign_op {	if(strcmp($3,"=")){
	
														Entry *entry = Get_Entry($1);
														if(entry -> scope_level == 0){
															if(!strcmp(entry -> data_type,"int"))
																fprintf(file,"    getstatic compiler_hw3/%s I\n",entry -> name);
															else if(!strcmp(entry -> data_type,"float"))
																fprintf(file,"    getstatic compiler_hw3/%s F\n",entry -> name);
														}
														else if(!strcmp(entry -> data_type,"float"))
															fprintf(file,"    fload %d\n",entry -> reg_num);
														else
															fprintf(file,"    iload %d\n",entry -> reg_num);

													}

												} assign_expression { // For expression computation and casting

													strcpy(id_buff,$1);
													if(!strcmp($3,"+=")){
    													Check_Casting($1,$5,cast_type);
														if(!strcmp(cast_type,"I"))
															fprintf(file,"    iadd\n");
														else
															fprintf(file,"    fadd\n");
													}
													else if(!strcmp($3,"-=")){
    													Check_Casting($1,$5,cast_type);
														if(!strcmp(cast_type,"I"))
															fprintf(file,"    isub\n");
														else
															fprintf(file,"    fsub\n");
													}
													else if(!strcmp($3,"*=")){
    													Check_Casting($1,$5,cast_type);
														if(!strcmp(cast_type,"I"))
															fprintf(file,"    imul\n");
														else
															fprintf(file,"    fmul\n");
													}
													else if(!strcmp($3,"/=")){
    													Check_Casting($1,$5,cast_type);
														if(!strcmp(cast_type,"I"))
															fprintf(file,"    idiv\n");
														else
															fprintf(file,"    fdiv\n");
													}
													else if(!strcmp($3,"%=")){
    													Check_Casting($1,$5,cast_type);
														if(!strcmp(cast_type,"I"))
															fprintf(file,"    imod\n");
														//else
															//erroe
													}

													if(!strcmp($3,"="))
														Casting($1,$5);
													else
														Casting($1,cast_type);

												} store_var
;

logical_or_expression 
    : logical_and_expression							{$$ = $1;}
    | logical_or_expression OR logical_and_expression
;

logical_and_expression 
    : equality_expression								{$$ = $1;}
    | logical_and_expression AND equality_expression
;

equality_expression 
    : relation_expression							{$$ = $1;}
    | equality_expression EQ relation_expression
    | equality_expression NE relation_expression
;

relation_expression 
    : add_expression							{$$ = $1;}
    | relation_expression LT add_expression
    | relation_expression MT add_expression
    | relation_expression LTE add_expression
    | relation_expression MTE add_expression
;

add_expression 
    : mul_expression					{ $$ = $1; }
    | add_expression ADD mul_expression	{	Check_Casting($1,$3,cast_type);
											strcpy($$,cast_type);
											if(!strcmp($$,"I")){fprintf(file,"    iadd\n");}
											else{fprintf(file,"    fadd\n");} 
										}
    | add_expression SUB mul_expression	{	Check_Casting($1,$3,cast_type);
											strcpy($$,cast_type);
											if(!strcmp($$,"I")){fprintf(file,"    isub\n");}
											else{fprintf(file,"    fsub\n");} 
										}
;

mul_expression 
    : unary_expression								{	if(id_flag){strcpy(id_buff,$1);} } load_const load_var	{ $$ = $1; }
    | mul_expression MUL unary_expression			{	if(id_flag){strcpy(id_buff,$3);} } load_const load_var	{ 	Check_Casting($1,$3,cast_type);
																													$$ = strdup(cast_type);
																													if(!strcmp($$,"I")){fprintf(file,"    imul\n");}
																													else{fprintf(file,"    fmul\n");} 
																												}
    | mul_expression DIV unary_expression			{	if(id_flag){strcpy(id_buff,$3);} } load_const load_var	{	Check_Casting($1,$3,cast_type);
																													$$ = strdup(cast_type);
																													if(!strcmp($$,"I")){fprintf(file,"    idiv\n");}
																													else{fprintf(file,"    fdiv\n");} 
																												}
    | mul_expression MOD unary_expression			{	if(id_flag){strcpy(id_buff,$3);} } load_const load_var	{	Check_Casting($1,$3,cast_type);
																													$$ = strdup(cast_type);
																													if(!strcmp($$,"I")){fprintf(file,"    imod\n");}
																													else{/*error*/} 
																												}
;

unary_expression 
    : postfix_expression							{	$$ = $1; }
    | INC unary_expression	 						{	strcpy(id_buff,$2); op_flag = 1; } load_var {	fprintf(file,"    ldc 1\n");
																										if(!strcmp(table_head -> value_type,"I"))
																											fprintf(file,"    iadd\n");
																										else{
																											fprintf(file,"    i2f\n");
																											fprintf(file,"    fadd\n");
																										}
																									} store_var { $$ = $2; }

    | DEC unary_expression 							{	strcpy(id_buff,$2); op_flag = 1; } load_var {	fprintf(file,"    ldc 1\n");
																										if(!strcmp(table_head -> value_type,"I"))
																											fprintf(file,"    isub\n");
																										else{
																											fprintf(file,"    i2f\n");
																											fprintf(file,"    fsub\n");
																										}
																									} store_var { $$ = $2; }

    | unary_op unary_expression						{	if(id_flag){strcpy(id_buff,$2);} } load_const load_var { $$ = $2; }
;

postfix_expression 
    : primary_expression							{	if(id_flag){$$ = $1; }else{ $$ = strdup(table_head -> value_type);} }
    | postfix_expression LSB expression RSB			{	$$ = $1; }
    | postfix_expression LB RB						{	$$ = $1;
														if(lookup_symbol($1) < 0){
															error_num = 1;
															if(error_msg == NULL)
																error_msg = strdup("Undeclared function ");
															else
																strcpy(error_msg, "Undeclared function ");
															strcat(error_msg,$1);
														}
													}
    | postfix_expression LB argv_expression_list RB	{	$$ = $1;
														if(lookup_symbol($1) < 0){
							  								error_num = 1;
															if(error_msg == NULL)
																error_msg = strdup("Undeclared function ");
															else
																strcpy(error_msg, "Undeclared function ");
															strcat(error_msg,$1);
							  							}
														id_flag = 1;
													}
    | postfix_expression INC 						{	strcpy(id_buff,$1); }	load_var	{	op_flag = 1;
																								fprintf(file,"    ldc 1\n");
																								if(!strcmp(table_head -> value_type,"I"))
																									fprintf(file,"    iadd\n");
																								else{
																									fprintf(file,"    i2f\n");
																									fprintf(file,"    fadd\n");
																								}
																								
																							} store_var {$$ = $1; }
 
    | postfix_expression DEC 						{	strcpy(id_buff,$1); }	load_var	{	op_flag = 1;
																								fprintf(file,"    ldc 1\n");
																								if(!strcmp(table_head -> value_type,"I"))
																									fprintf(file,"    isub\n");
																								else{
																									fprintf(file,"    i2f\n");
																									fprintf(file,"    fsub\n");
																								}

																							} store_var {$$ = $1; }
;

load_const:	{	if(!id_flag && !op_flag && (table_head -> scope_level > 0)){
					if(!strcmp(table_head -> value_type,"F"))
						fprintf(file,"    ldc %f\n",table_head -> float_const);
					else if(!strcmp(table_head -> value_type,"Ljava/lang/String"))
						fprintf(file,"    ldc \"%s\"\n",table_head -> str_const);
					else
						fprintf(file,"    ldc %d\n",table_head -> int_const);
				}
				op_flag = 0;
			}

load_var:	{	if(id_flag){
					Entry *entry = Get_Entry(id_buff);//printf("%s\n",id_buff);
					if(!strcmp(entry -> entry_type,"function")){
						char *str = strdup(entry -> name),*tmp;
						fprintf(file,"    invokestatic compiler_hw3/%s(",strtok(str,"|"));
						while((tmp = strtok(NULL,", ")) != NULL){
							if(!strcmp(tmp,"int"))
								fprintf(file,"I");
							else if(!strcmp(tmp,"float"))
								fprintf(file,"F");
							else if(!strcmp(tmp,"bool"))
								fprintf(file,"Z");
							else if(!strcmp(tmp,"string"))
								fprintf(file,"Ljava/lang/String");	
						}

						tmp = strdup(entry -> data_type);
						if(!strcmp(tmp,"int"))
							fprintf(file,")I\n");
						else if(!strcmp(tmp,"float"))
							fprintf(file,")F\n");
						else if(!strcmp(tmp,"bool"))
							fprintf(file,")Z\n");
						else if(!strcmp(tmp,"string"))
							fprintf(file,")Ljava/lang/String\n");	
						else if(!strcmp(tmp,"void"))
							fprintf(file,")V\n");

					}
					else if(entry -> scope_level == 0)
						fprintf(file,"    getstatic compiler_hw3/%s %s\n",entry -> name,table_head -> value_type);
					else if(!strcmp(entry -> data_type,"float"))
						fprintf(file,"    fload %d\n",entry -> reg_num);
					else
						fprintf(file,"    iload %d\n",entry -> reg_num);
				}
				id_flag = 0;
			}

store_var:	{
				Entry *entry = Get_Entry(id_buff);
				if(entry -> scope_level == 0)
					fprintf(file,"    putstatic compiler_hw3/%s %s\n",entry -> name,table_head -> value_type);
				else if(!strcmp(entry -> data_type,"float"))
					fprintf(file,"    fstore %d\n",entry -> reg_num);
				else
					fprintf(file,"    istore %d\n",entry -> reg_num);
			}

primary_expression 
    : ID	{	
				$$ = strdup(yytext);
				id_flag = 1;
    			if(lookup_symbol(yytext) < 0){
					error_num = 2;
					if(error_msg == NULL)
						error_msg = strdup("Undeclared variable ");
					else
						strcpy(error_msg, "Undeclared variable ");
					strcat(error_msg,yytext);
				}

				Entry *entry = Get_Entry(yytext);
				char *type = strdup(entry -> data_type);
				if(!strcmp(type,"int"))
					strcpy(table_head -> value_type,"I");
				else if(!strcmp(type,"float"))
					strcpy(table_head -> value_type,"F");
				else if(!strcmp(type,"bool"))
					strcpy(table_head -> value_type,"Z");
				else if(!strcmp(type,"string"))
					strcpy(table_head -> value_type,"Ljava/lang/String");
				else if(!strcmp(type,"void"))
					strcpy(table_head -> value_type,"V");

			}
    | I_CONST	{strcpy(table_head -> value_type, "I"); table_head -> int_const = atoi(yytext); id_flag = 0; }
    | F_CONST	{strcpy(table_head -> value_type, "F"); sscanf(yytext,"%f",&(table_head -> float_const)); id_flag = 0; }
    | QUATA STR_CONST { strcpy(table_head -> value_type, "Ljava/lang/String"); strcpy(table_head -> str_const, yytext); id_flag = 0; } QUATA
    | TRUE		{strcpy(table_head -> value_type, "Z"); table_head -> int_const = 1; id_flag = 0; }
    | FALSE		{strcpy(table_head -> value_type, "Z"); table_head -> int_const = 0; id_flag = 0; }
    | LB expression RB	{;}
;

parameter_list 
    : parameter_declaration							{$$ = $1;}
    | parameter_list COMMA parameter_declaration	{$$ = strcat(strcat($1, ", "), $3);}
;

parameter_declaration 
    : declaration_specs declarator	{	$$ = $1;
										local_cnt++;
					  					insert_symbol($2, "parameter", $1, 0);
                                    }
    | declaration_specs			
;

argv_expression_list 
    : assign_expression								
    | argv_expression_list COMMA assign_expression
;

init_declarator_list 
    : init_declarator	{$$ = $1;}
    | init_declarator_list COMMA init_declarator
;

init_declarator 
    : declarator					{$$ = $1;}
    | declarator ASGN initializer	{$$ = $1; table_head -> asgn_flag = 1;}
;

initializer 
    : assign_expression
    | LCB init_list RCB
    | LCB init_list COMMA RCB
;

init_list 
    : initializer
    | init_list COMMA initializer
;

assign_op 
    : ASGN		{$$ = strdup(yytext); }
    | ADDASGN	{$$ = strdup(yytext); }
    | SUBASGN	{$$ = strdup(yytext); }
    | MULASGN	{$$ = strdup(yytext); }
    | DIVASGN	{$$ = strdup(yytext); }
    | MODASGN	{$$ = strdup(yytext); }
;

id_list 
    : ID
    | id_list COMMA ID
;

unary_op 
    : ADD
    | SUB
    | NOT
;

/* actions can be taken when meet the token or rule */
type
    : INT		{ $$ = strdup(yytext); }
    | FLOAT		{ $$ = strdup(yytext); }
    | BOOL  	{ $$ = strdup(yytext); }
    | STRING	{ $$ = strdup(yytext); }
    | VOID 		{ $$ = strdup(yytext); }
;

%%

/* C code section */
int main(int argc, char** argv)
{
    yylineno = 0;
	local_cnt = 0;
    error_num = 0;
    func_flag = 0;
	op_flag = 0;
    declare_line = 0;
    error_msg = NULL;
    buff_tmp = NULL;
	id_buff = strdup("");
	id_flag = 0;
    syntax_error_flag = 0;
	cast_type = strdup("");

	file = fopen("compiler_hw3.j","w");

	fprintf(file,   ".class public compiler_hw3\n"
                    ".super java/lang/Object\n");

    create_symbol();
    yyparse();

    if(syntax_error_flag == 0){
    	Print_Table(0);
    	printf("\nTotal lines: %d \n",yylineno);
    }

	fclose(file);

    return 0;
}

void yyerror(char *s)
{
    if(error_num != 0)
    	yysemantic(1);
    else
    	printf("%d: %s\n", yylineno + 1,buf);

    syntax_error_flag = 1;
    printf("\n|-----------------------------------------------|\n");
    printf("| Error found in line %d: %s\n", yylineno + 1, buf);
    printf("| %s", s);
    printf("\n|-----------------------------------------------|\n\n");
    memset(buf,'\0',sizeof(buf));
    
}

void yysemantic(int mode){

        int lineno;

        if(error_num == 3)
		lineno = declare_line + 1;
	else
		lineno = yylineno + mode;

	printf("%d: %s\n", yylineno + mode, buf);
    	printf("\n|-----------------------------------------------|\n");
	if(error_num == 3)
    		printf("| Error found in line %d: %s\n", lineno, buff_tmp);
	else
    		printf("| Error found in line %d: %s\n", lineno, buf);
    	printf("| %s", error_msg);
    	printf("\n|-----------------------------------------------|\n\n");
	if(!mode)memset(buf,'\0',sizeof(buf));
    	error_num = 0;

}

void create_symbol() {

	table_head = (Entry *)malloc(sizeof(Entry));
	table_head -> entry_num = 0;
	table_head -> scope_level = 0;

	table_head -> name = strdup("");
	table_head -> value_type = strdup("");
	table_head -> str_const = strdup("");
	table_head -> asgn_flag = 0;

	table_head -> next = NULL;

}

void insert_symbol(char *symbol_name, char *entry_name, char *data_name, int ffd_flag) {

	//printf("insert symbol\n%s\n%s\n%s\n", symbol_name, entry_name, data_name);
	Entry *new_entry = (Entry *)malloc(sizeof(Entry));
	new_entry -> entry_num = (table_head -> entry_num)++;
	new_entry -> scope_level = table_head -> scope_level;
	new_entry -> name = strdup(symbol_name);
	new_entry -> entry_type = strdup(entry_name);
	new_entry -> data_type = strdup(data_name);
	new_entry -> ffd_flag = ffd_flag;

	if(!strcmp(entry_name, "variable")){
		if((!strcmp(data_name, "int")) || (!strcmp(data_name, "bool")))
			new_entry -> int_const = table_head -> int_const;
		else if(!strcmp(data_name, "float"))
			new_entry -> float_const = table_head -> float_const;
		else if(!strcmp(data_name, "string"))
			new_entry -> str_const = strdup(table_head -> str_const);
	}

	new_entry -> reg_num = local_cnt - 1;

	Insert_Entry(&table_head, new_entry);

}

int lookup_symbol(char *id) {
	
	Entry *cur;
	char *name;

	cur = table_head;
	cur = cur -> next;
	while(cur != NULL){
		name = strdup(cur -> name);
		strcpy(name, strtok(name, "|"));
		if((!strcmp(id, name)) && (cur -> scope_level == table_head -> scope_level))
			break;
		cur = cur -> next;
	}

	if(cur != NULL) {
		if(cur -> ffd_flag == 1) return 2; // Find out forwarding declared function
		else return 1; // Find out in the same scope
	}

	cur = table_head;
	cur = cur -> next;
	while(cur != NULL){
		name = strdup(cur -> name);
		strcpy(name, strtok(name, "|"));
		if(!strcmp(id, name))
			break;
		cur = cur -> next;
	}

	if(cur != NULL){
		if(cur -> ffd_flag == 1) return 2; // Find out forwarding declared function
		else return 0; // Find out in different scope
	}
	else return -1; // Not found

}

void dump_symbol() {
    printf("\n%-10s%-10s%-12s%-10s%-10s%-10s\n\n",
           "Index", "Name", "Kind", "Type", "Scope", "Attribute");
}

Entry *Get_Entry(char *id){
	
	Entry *cur;
	char *name;

	// Search in the same scope first
	cur = table_head;
	cur = cur -> next;
	while(cur != NULL){
		name = strdup(cur -> name);
		strcpy(name, strtok(name, "|"));
		if((!strcmp(id, name)) && (cur -> scope_level == table_head -> scope_level))
			break;
		cur = cur -> next;
	}

	if(cur != NULL)
		return cur;

	// Search in all scopes
	cur = table_head;
	cur = cur -> next;
	while(cur != NULL){
		name = strdup(cur -> name);
		strcpy(name, strtok(name, "|"));
		if(!strcmp(id, name)){
			return cur;	
		}
		cur = cur -> next;
	}

	return NULL;

}


void Insert_Entry(Entry **head, Entry *new_entry){
	head = &((*head) -> next);
	while(*head != NULL)
		head = &((*head) -> next);
	(*head) = new_entry;
	new_entry -> next = NULL;
	return;
}


Entry *Remove_Entry(){

	int n = table_head -> scope_level;
	Entry *cur,*prev;

	cur = table_head;
	prev = cur;
	cur = cur -> next;
	while(cur != NULL){
		if((*cur).scope_level == n){
			prev -> next = cur -> next;
			return cur;
		}
		prev = cur;
		cur = cur -> next;
	}

	return NULL;

}

void Casting(char *id1,char *id2){

	Entry *e1 = Get_Entry(id1);
	Entry *e2 = Get_Entry(id2);
	char *type1,*type2,*str;

	if(e1 == NULL){
		if(!strcmp(id1,"F"))
			type1 = strdup("float");
		else
			type1 = strdup("int");
	}
	else
		type1 = strdup(e1 -> data_type);

	if(e2 == NULL){
		if(!strcmp(id2,"F"))
			type2 = strdup("float");
		else
			type2 = strdup("int");
	}
	else
		type2 = strdup(e2 -> data_type);
	
	if(!strcmp(type1,"float") && (!strcmp(type2,"int"))){
		fprintf(file,"    i2f\n");
	}
	else if(!strcmp(type1,"int") && (!strcmp(type2,"float"))){
		fprintf(file,"    f2i\n");
	}

	return;

}

void *Check_Casting(char *id1,char *id2,char *type){

	Entry *e1 = Get_Entry(id1);
	Entry *e2 = Get_Entry(id2);
	char *type1,*type2;

	if(e1 == NULL){
		if(!strcmp(id1,"F"))
			type1 = strdup("float");
		else
			type1 = strdup("int");
	}
	else
		type1 = strdup(e1 -> data_type);

	if(e2 == NULL){
		if(!strcmp(id2,"F"))
			type2 = strdup("float");
		else
			type2 = strdup("int");
	}
	else
		type2 = strdup(e2 -> data_type);

	if(!strcmp(type1,"float") && (!strcmp(type2,"int"))){
		fprintf(file,"    i2f\n");
		strcpy(type,"F");
		return;
	}
	else if(!strcmp(type1,"int") && (!strcmp(type2,"float"))){
		fprintf(file,"    swap\n");
		fprintf(file,"    i2f\n");
		strcpy(type,"F");
		return;
	}

	strcpy(type,"I");
	return;

}

void Print_Table(int mode){

	int index = 0,scope,cur_scope,flag = 0;
	char *name,*e,*d,*p;
	Entry *cur;
	if(mode) ++(table_head -> scope_level);

	do{

		cur = Remove_Entry();
		if(cur == NULL){
			if(mode) --(table_head -> scope_level);
			break;
		}

		if(index == 0)dump_symbol();
		name = strtok(cur -> name, "|");
		e = cur -> entry_type;
		d = cur -> data_type;
		scope = cur -> scope_level;
		p = strtok(NULL, "|");
		if(p == NULL) p = "";
		printf("%-10d%-10s%-12s%-10s%-10d%s\n",index++,name,e,d,scope,p);
		free(cur);
		flag = 1;

	}while(1);

	if(flag) printf("\n");
	return;

}


void Change_Table_Flag(char *id){

	Entry *cur;

	cur = table_head -> next;
	while(cur != NULL){
		char *tmp = strdup(cur -> name);
		char *name = strtok(tmp,"|");
		if(!strcmp(name, id)){
			cur -> ffd_flag = 0;
			return;
		}
		cur = cur -> next;
	}

	return;

}


int Remove_Redundant(){

	int n = (table_head -> scope_level) + 1;
	Entry *cur,*prev;

	cur = table_head;
	prev = cur;
	cur = cur -> next;
	while(cur != NULL){
		if((*cur).scope_level == n){
			prev -> next = cur -> next;
			free(cur);
			return 1;
		}
		prev = cur;
		cur = cur -> next;
	}

	return 0;

}


int Check_Table(){

	int n = table_head -> scope_level;
	Entry *cur;

	cur = table_head -> next;
	while(cur != NULL){
		if((*cur).scope_level == n){
			return 1;
		}
		cur = cur -> next;
	}

	return 0;

}



