/* JFlex specification for toy language */

package com.toylang;

import java_cup.runtime.*;
import java.util.ArrayList;
import java.util.List;

%%

%class LexerCup
%type java_cup.runtime.Symbol
%unicode
%cup
%line
%column

%{
    private List<Token> tokens = new ArrayList<>();
    
    public static class Token {
        public final String type;
        public final String value;
        public final int line;
        public final int column;
        
        public Token(String type, String value, int line, int column) {
            this.type = type;
            this.value = value;
            this.line = line;
            this.column = column;
        }
        
        @Override
        public String toString() {
            return String.format("Token{type='%s', value='%s', line=%d, col=%d}", 
                               type, value, line, column);
        }
    }
    
    private Symbol symbol(int type) {
        Token token = new Token(getTokenName(type), yytext(), yyline + 1, yycolumn + 1);
        tokens.add(token);
        return new Symbol(type, yyline, yycolumn);
    }
    
    private Symbol symbol(int type, Object value) {
        Token token = new Token(getTokenName(type), yytext(), yyline + 1, yycolumn + 1);
        tokens.add(token);
        return new Symbol(type, yyline, yycolumn, value);
    }
    
    public List<Token> getTokens() {
        return new ArrayList<>(tokens);
    }
    
    public void clearTokens() {
        tokens.clear();
    }
    
    private String getTokenName(int type) {
        try {
            java.lang.reflect.Field[] fields = Symbols.class.getFields();
            for (java.lang.reflect.Field field : fields) {
                if (field.getType() == int.class && field.getInt(null) == type) {
                    return field.getName();
                }
            }
        } catch (Exception e) {
            // ignore
        }
        return "UNKNOWN(" + type + ")";
    }
%}

/* Regular expression definitions */
L = [a-zA-Z_]+
D = [0-9]
espacio = [ ,\t,\r,\n]+

%%

/*Encender/Apagar*/
"ENCENDER"      { return symbol(Symbols.Encender, yytext()); }
"APAGAR"        { return symbol(Symbols.Apagar, yytext()); }

/*Funciones*/
"CALENTAR"      { return symbol(Symbols.Calentar, yytext()); }
"COCINAR"       { return symbol(Symbols.Cocinar, yytext()); }

/*TipoTiempo*/
"h"             { return symbol(Symbols.H, yytext()); }
"m"             { return symbol(Symbols.M, yytext()); }
"s"             { return symbol(Symbols.S, yytext()); }

/* Ignore spaces */
{espacio}       { /* Ignore */ }

/*Operadores*/
"//".*          { /* Ignore */ }
"+"             { return symbol(Symbols.Suma, yytext()); }
"-"             { return symbol(Symbols.Resta, yytext()); }
"*"             { return symbol(Symbols.Multiplicacion, yytext()); }
"/"             { return symbol(Symbols.Division, yytext()); }
"("             { return symbol(Symbols.AParentesis, yytext()); }
")"             { return symbol(Symbols.CParentesis, yytext()); }

/*Simbolo de : para separar tiempos*/
":"             { return symbol(Symbols.DosPuntos, yytext()); }

/*Termino de lineas*/
"."             { return symbol(Symbols.Punto, yytext()); }

/*Enteros*/
({D}){0,2}      { return symbol(Symbols.NumeroEntero, yytext()); }

/*ERROR*/
.               { 
                  Token token = new Token("ERROR", yytext(), yyline + 1, yycolumn + 1);
                  tokens.add(token);
                  throw new RuntimeException("Illegal character: " + yytext() + 
                                           " at line " + (yyline+1) + ", column " + (yycolumn+1)); 
                }
