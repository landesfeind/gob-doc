/* Scanner for GOB2 Documentations */


%{
#include <stdbool.h>
#include <ctype.h>
#include <errno.h>
#include <error.h>

#define CHAR_BUFFER_LENGTH 255

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

static void parse_class(const char *line, bool is_abstract){
	char *p;
	
	p = strchr(yytext, ' '); // Find first bunch of whitespaces
	if( ! p ) error(100, 0, "Parsing error: did not find ' ' before class name: %s", yytext);
	while( *p == ' ' )
		p++;
	char *classname = p;
	p = strchr(p, ' ');
	if( ! p ) error(100, 0, "Parsing error: did not find end of class name: %s", classname);
	*p = '\0';
	p++; // Finish classname
	p = strchr(p, 'f'); // start of "from"
	if( ! p ) error(100, 0, "Parsing error: did not find 'from': %s", classname + 1);
	p = strchr(p, ' ');
	if( ! p ) error(100, 0, "Parsing error: did not find ' ' after from: %s", yytext);
	while( *p == ' ' )
		p++;
	char *parentclass = p;
	p = strchr(p, ' ');
	if(p)
		*p = '\0';
	printf("class ");
	strncpy(my_class, classname, CHAR_BUFFER_LENGTH);
	print_class_with_namespace(classname);
	printf(" : ");
	print_class_with_namespace(parentclass);

	strncpy(my_func_prefix, classname, CHAR_BUFFER_LENGTH);
	int i;
	for(i = 0; i < strlen(classname); i++){
		my_func_prefix[i] = tolower(my_func_prefix[i]);
		if( my_func_prefix[i] == ':' )
			my_func_prefix[i] = '_';
	}
	my_func_prefix[i] = '\0';
}


char *forward_ws(char *orig){
	char *a = orig;
	while(1){
		if( *a == '\0' ){
			fprintf(stderr, "ERROR: can not forward from string '%s'", orig);
		}
		else if( *a == ' ' || *a == '\t' ){
			a++;
		}
		else {
			return a;
		}
	}
}



#ifdef FLEX_SCANNER
int yylex(void);
int yywrap(void) { return 1; }
#endif

%}


%x GOB2_IN_CLASS
%x GOB2_IN_METHOD
%x IGNORE_C_CODE

WS [ \t\n]
CLASSNAME [a-zA-Z0-9]+(:[a-zA-Z0-9]+)*


%%
^{WS}*\%[a-z]*{WS}*\{ {
	BEGIN(IGNORE_C_CODE);
}
<IGNORE_C_CODE>^{WS}*\%[a-z]*{WS}*\} {
	BEGIN(INITIAL);
}

<IGNORE_C_CODE>.* { ; /*ignore*/ }

class{WS}+{CLASSNAME}{WS}+from{WS}+{CLASSNAME}{WS}*\({WS}*abstract{WS}*\) {
	//fprintf(stderr, "FOUND CLASS: '%s'\n", yytext);
	parse_class(yytext, true);
	BEGIN(GOB2_IN_CLASS);
}

class{WS}+{CLASSNAME}{WS}+from{WS}+{CLASSNAME} {
	//fprintf(stderr, "FOUND CLASS: '%s'\n", yytext);
	parse_class(yytext, false);
	BEGIN(GOB2_IN_CLASS);
}

<GOB2_IN_CLASS>^{WS}*(private|public|protected){WS}+{CLASSNAME}{WS}+\*?[a-z_]+{WS}*\(.*\).*\{ { 
	char *start;
	char *p2;
	// Accessibility
	char *p = strchr(yytext, ' ');
	*p = '\0';
	printf("%s: ", yytext);	
	// Return value
	start = p+1;
	p = strchr(start, ' ');
	*p = '\0';
	print_class_with_namespace(start);
	// Method name
	printf(" ");
	start = forward_ws(p+1);
	if( *start == '*' ){
		printf("*");
		start++;
	}
	p = strpbrk(start, " (\t");
	*p = '\0';
	print_class_with_namespace(start);
	start = p + 1;
	printf("(");

	p = strchr(start, ')');
	*p = '\0';

	while(start){
		p = strpbrk(start, " (");
		if( p )
			*p = '\0';
		if(strcmp(start, "self") == 0){
			print_class_with_namespace(my_class);
			printf(" *self");
		}
		else {
			print_class_with_namespace(start);
		}

		start = p ? strchr(p+1, ',') : NULL;
		if( start ){
			*start = '\0';
			start++;
			while( *start == ' ' )
				start++;
		}
		if( p )
			printf(" %s%s", p+1, start ? ", " : "");
	}
	printf(");");
	BEGIN(GOB2_IN_METHOD);
	depth = 0;
}

<GOB2_IN_METHOD>\{ {
	depth++;
}
<GOB2_IN_METHOD>\} {
	depth--;
	if( depth <= 0 )
		BEGIN(GOB2_IN_CLASS);
}
<GOB2_IN_METHOD>[^\{\}]+ {
	;
}
%%

int main( int argc, char **argv ){
	++argv, --argc;  /* skip over program name */
	if ( argc > 0 )
	        yyin = fopen( argv[0], "r" );
	else
	        yyin = stdin;
	
	yylex();
}



