#!/bin/bash

# Build script for Toy Language project
# This script handles automatic recompilation when .flex or .cup files change

PROJECT_DIR="$(pwd)"
FLEX_FILE="src/main/jflex/lexer.flex"
CUP_FILE="src/main/cup/grammar.cup"
GENERATED_LEXER="src/main/java/com/toylang/Lexer.java"
GENERATED_PARSER="src/main/java/com/toylang/Parser.java"
GENERATED_SYMBOLS="src/main/java/com/toylang/Symbols.java"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if file exists
check_file() {
    if [ ! -f "$1" ]; then
        print_error "File not found: $1"
        return 1
    fi
    return 0
}

# Function to check if file is newer than another
is_newer() {
    [ "$1" -nt "$2" ]
}

# Function to generate lexer
generate_lexer() {
    print_status "Generating lexer from $FLEX_FILE..."
    if mvn jflex:generate; then
        print_success "Lexer generated successfully"
        return 0
    else
        print_error "Failed to generate lexer"
        return 1
    fi
}

# Function to generate parser
generate_parser() {
    print_status "Generating parser from $CUP_FILE..."
    if mvn cup:generate; then
        print_success "Parser generated successfully"
        return 0
    else
        print_error "Failed to generate parser"
        return 1
    fi
}

# Function to compile project
compile_project() {
    print_status "Compiling project..."
    if mvn compile; then
        print_success "Project compiled successfully"
        return 0
    else
        print_error "Failed to compile project"
        return 1
    fi
}

# Function to run the application
run_application() {
    print_status "Running Toy Language IDE..."
    mvn exec:java
}

# Function to check and regenerate if needed
check_and_regenerate() {
    local need_lexer=false
    local need_parser=false
    local need_compile=false
    
    # Check if lexer needs regeneration
    if [ ! -f "$GENERATED_LEXER" ] || is_newer "$FLEX_FILE" "$GENERATED_LEXER"; then
        print_status "Lexer source is newer than generated lexer or lexer doesn't exist"
        need_lexer=true
    fi
    
    # Check if parser needs regeneration
    if [ ! -f "$GENERATED_PARSER" ] || [ ! -f "$GENERATED_SYMBOLS" ] \
       || is_newer "$CUP_FILE" "$GENERATED_PARSER" \
       || is_newer "$CUP_FILE" "$GENERATED_SYMBOLS"; then
        print_status "Parser source is newer than generated parser/symbols or parser doesn't exist"
        need_parser=true
    fi
    
    # Generate lexer if needed
    if [ "$need_lexer" = true ]; then
        if ! generate_lexer; then
            return 1
        fi
        need_compile=true
    fi
    
    # Generate parser if needed
    if [ "$need_parser" = true ]; then
        if ! generate_parser; then
            return 1
        fi
        need_compile=true
    fi
    
    # Compile if any generation occurred or if no class files exist
    if [ "$need_compile" = true ] || [ ! -d "target/classes" ]; then
        if ! compile_project; then
            return 1
        fi
    else
        print_status "No regeneration needed, project is up to date"
    fi
    
    return 0
}

# Main script logic
case "${1:-build}" in
    "setup")
        print_status "Setting up project structure..."
        
        # Create directory structure
        mkdir -p src/main/java/com/toylang
        mkdir -p src/main/jflex
        mkdir -p src/main/cup
        mkdir -p src/test/java
        
        print_success "Project structure created"
        
        # Check if files exist, if not create them
        if [ ! -f "$FLEX_FILE" ]; then
            print_warning "Lexer file not found. Please create $FLEX_FILE"
        fi
        
        if [ ! -f "$CUP_FILE" ]; then
            print_warning "Parser file not found. Please create $CUP_FILE"
        fi
        
        print_status "Run './build.sh' to build and run the project"
        ;;
        
    "clean")
        print_status "Cleaning generated files..."
        rm -f "$GENERATED_LEXER" "$GENERATED_PARSER" "$GENERATED_SYMBOLS"
        mvn clean
        print_success "Clean completed"
        ;;
        
    "generate")
        print_status "Force regenerating lexer and parser..."
        generate_lexer && generate_parser
        ;;
        
    "build")
        print_status "Building Toy Language project..."
        if check_and_regenerate; then
            print_success "Build completed successfully"
        else
            print_error "Build failed"
            exit 1
        fi
        ;;
        
    "run")
        print_status "Building and running Toy Language IDE..."
        if check_and_regenerate; then
            run_application
        else
            print_error "Build failed, cannot run application"
            exit 1
        fi
        ;;
        
    "watch")
        print_status "Starting file watcher for automatic rebuilds..."
        print_status "Watching: $FLEX_FILE and $CUP_FILE"
        print_status "Press Ctrl+C to stop watching"
        
        # Initial build
        check_and_regenerate
        
        # Watch for changes (requires inotify-tools on Arch Linux)
        if command -v inotifywait >/dev/null 2>&1; then
            while inotifywait -e modify "$FLEX_FILE" "$CUP_FILE" 2>/dev/null; do
                print_status "File change detected, rebuilding..."
                if check_and_regenerate; then
                    print_success "Rebuild completed"
                else
                    print_error "Rebuild failed"
                fi
            done
        else
            print_warning "inotifywait not found. Install inotify-tools for file watching:"
            print_warning "sudo pacman -S inotify-tools"
            print_status "Falling back to periodic checking every 2 seconds..."
            
            last_flex_mod=0
            last_cup_mod=0
            
            while true; do
                if [ -f "$FLEX_FILE" ]; then
                    flex_mod=$(stat -f %m "$FLEX_FILE" 2>/dev/null || stat -c %Y "$FLEX_FILE" 2>/dev/null)
                else
                    flex_mod=0
                fi
                
                if [ -f "$CUP_FILE" ]; then
                    cup_mod=$(stat -f %m "$CUP_FILE" 2>/dev/null || stat -c %Y "$CUP_FILE" 2>/dev/null)
                else
                    cup_mod=0
                fi
                
                if [ "$flex_mod" != "$last_flex_mod" ] || [ "$cup_mod" != "$last_cup_mod" ]; then
                    print_status "File change detected, rebuilding..."
                    if check_and_regenerate; then
                        print_success "Rebuild completed"
                    else
                        print_error "Rebuild failed"
                    fi
                    last_flex_mod=$flex_mod
                    last_cup_mod=$cup_mod
                fi
                
                sleep 2
            done
        fi
        ;;
        
    "help"|"-h"|"--help")
        echo "Toy Language Build Script"
        echo ""
        echo "Usage: $0 [command]"
        echo ""
        echo "Commands:"
        echo "  setup     - Create project directory structure"
        echo "  build     - Build the project (regenerate if needed)"
        echo "  run       - Build and run the IDE"
        echo "  generate  - Force regenerate lexer and parser"
        echo "  clean     - Clean generated files and compiled classes"
        echo "  watch     - Watch for file changes and auto-rebuild"
        echo "  help      - Show this help message"
        echo ""
        echo "Default command: build"
        ;;
        
    *)
        print_error "Unknown command: $1"
        print_status "Use '$0 help' for usage information"
        exit 1
        ;;
esac
