/* Scanner for GOB2 Documentations */


%{
#include <stdbool.h>
#include <ctype.h>
#include <errno.h>
#include <error.h>

#define CHAR_BUFFER_LENGTH 255


//#define D foobar
#ifdef D 
#define DEBUG(msg, ...) fprintf(stdout, msg"\n", ##__VA_ARGS__)
#else
#define DEBUG(msg, ...) 
#endif


extern int errno;

static int depth = -1;
static char my_class[CHAR_BUFFER_LENGTH];
static char my_func_prefix[CHAR_BUFFER_LENGTH];

static void print_class_with_namespace(char *classname){
	char *p = strtok(classname, ":");
	printf("%s", p);
	while(p){
		p = strtok(NULL, ":");
		if( p )
			printf("::%s", p);
	}
}

#ifdef FLEX_SCANNER
int yylex(void);
int yywrap(void) { return 1; }
#endif

%}


%x IN_CLASS_DEF
%x IN_CLASS
%x IN_METHOD_DEF
%x IN_METHOD
%x IN_METHOD_ARGUMENTS
%x AFTER_METHOD_ARGUMENTS
%x IN_PROPERTY_DEF
%x IN_PROPERTY
%x IN_PROPERTY_SETGET
%x IN_VARIABLE_DEF
%x IN_VARIABLE
%x IN_COMMENT
%x IN_C_CODE
%x IN_METHOD_OR_VARIABLE_START

WS [ \t\n]
TYPE [a-zA-Z0-9]+(:[a-zA-Z0-9]+)*
CLASS [a-zA-Z0-9]+(:[a-zA-Z0-9]+)+
FUNCNAME [a-zA-Z0-9_]+


%%
^{WS}*\%[a-z]*{WS}*\{ {
	BEGIN(IN_C_CODE);
}
<IN_C_CODE>^{WS}*\%[a-z]*{WS}*\} {
	BEGIN(INITIAL);
}

<IN_C_CODE>.* { ; /*ignore*/ }


class {
	printf("class");
	BEGIN(IN_CLASS_DEF);
}

<IN_CLASS_DEF>from {
	printf(":");
}

<IN_CLASS_DEF>{TYPE} {
	print_class_with_namespace(yytext);
}
<IN_CLASS_DEF>\({WS}*abstract{WS}*\) {
	; //ignore
}
<IN_CLASS_DEF>\{ {
	printf("{\n");
	BEGIN(IN_CLASS);
}

<IN_CLASS>(constructor|init|dispose|finalize){WS}*\({WS}*self{WS}*\){WS}*\{ { 
	DEBUG("FOUND INTERNAL METHOD: %s", yytext);
	BEGIN(IN_METHOD);
	depth = 0;
}

<IN_CLASS>property {
	DEBUG("FOUND PROPERTY");
	BEGIN(IN_PROPERTY);
	depth = 0;
}

<IN_CLASS>\/\*\* {
	DEBUG("FOUND CLASS COMMENT");
	printf("/**");
	BEGIN(IN_COMMENT);
}
<IN_COMMENT>\*\/ {
	BEGIN(IN_CLASS);
	printf("*/");
	DEBUG("END CLASS COMMENT");
}
<IN_COMMENT>[^(\*\/)]+ {
	printf(yytext);
}

<IN_PROPERTY>\( {
	BEGIN(IN_PROPERTY_DEF);
	DEBUG("FOUND PROPERTY DEFINITION");
	depth = 0;
}

<IN_PROPERTY_DEF>\( {
	DEBUG("FOUND PROPERTY DEFINITION");
	depth++;
}
<IN_PROPERTY_DEF>\) {
	depth--;
	if( depth < 0 ){
		DEBUG("END PROPERTY DEFINITION");
		BEGIN(IN_PROPERTY);
	}
}
<IN_PROPERTY_DEF>[^\(\)] { ; }

<IN_PROPERTY>\{ {
	BEGIN(IN_PROPERTY_SETGET);
	DEBUG("STARTING SETTER AND GETTER FOR PROPERTY");
	depth = 0;
}

<IN_PROPERTY_SETGET>\{ {
	depth++;
}
<IN_PROPERTY_SETGET>\} {
	depth--;
	if( depth < 0 ){
		BEGIN(IN_PROPERTY);
		DEBUG("END SETTER AND GETTER FOR PROPERTY");
	}
}
<IN_PROPERTY_SETGET>[^\{\}]+ { ; };

<IN_PROPERTY>\; {
	DEBUG("END PROPERTY");
	BEGIN(IN_CLASS);
}

<IN_CLASS>(private|public|protected) {
	printf("%s: ", yytext);
	BEGIN(IN_METHOD_OR_VARIABLE_START);
}

<IN_METHOD_OR_VARIABLE_START>{TYPE} {
	DEBUG("FOUND TYPE OF METHOD OR PROPERTY '%s'", yytext);
	print_class_with_namespace(yytext);
}

<IN_METHOD_OR_VARIABLE_START>"=" {
	BEGIN(IN_VARIABLE);
	DEBUG("FOUND START OF VARIABLE");
	depth = 0;
}

<IN_VARIABLE>\{ {
	depth++;
}
<IN_VARIABLE>\} {
	depth--;
}
<IN_VARIABLE>; {
	if( depth <= 0 ){
		printf(";");
		BEGIN(IN_CLASS);
	}
}

<IN_PROPERTY>\}{WS}*; {
	DEBUG("FOUND END OF PROPERTY");
	printf(";");
	BEGIN(IN_CLASS);
}

<IN_PROPERTY,IN_VARIABLE>. {
	; // Ignore
}

<IN_METHOD_OR_VARIABLE_START>{FUNCNAME} {
	DEBUG("FOUND FUNCTION NAME '%s'", yytext);
	printf(yytext);
}
<IN_METHOD_OR_VARIABLE_START>\( {
	DEBUG("FOUND METHOD ARGUMENT START");
	printf("(");
	BEGIN(IN_METHOD_ARGUMENTS);
	depth = 0;
}

<IN_METHOD_ARGUMENTS>{TYPE} {
	print_class_with_namespace(yytext);
}

<IN_METHOD_ARGUMENTS>\( {
	depth++;
}

<IN_METHOD_ARGUMENTS>\) {
	depth--;
	if( depth < 0 ){
		printf(")");
		BEGIN(AFTER_METHOD_ARGUMENTS);
	}
}

<AFTER_METHOD_ARGUMENTS>\{ {
	printf(";");
	BEGIN(IN_METHOD);
	depth = 0;
}
<AFTER_METHOD_ARGUMENTS>[^\{]+ {
	; // ignore
}

<IN_METHOD>\{ {
	depth++;
}

<IN_METHOD>\} {
	depth--;
	if( depth < 0 ){
		DEBUG("FOUND END OF METHOD");
		BEGIN(IN_CLASS);
	}
}

<IN_METHOD>[^\{\}]+ { ; }

%%

int main( int argc, char **argv ){
	++argv, --argc;  /* skip over program name */
	if ( argc > 0 )
	        yyin = fopen( argv[0], "r" );
	else
	        yyin = stdin;
	
	yylex();
}



