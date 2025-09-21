#!/bin/bash

# WolfPy Package Installer
# This script installs the WolfPy package into Mathematica's Applications directory

set -e  # Exit on any error

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

# Function to detect Mathematica installation
detect_mathematica() {
    print_status "Detecting Mathematica installation..."
    
    # Common Mathematica installation paths
    MATHEMATICA_PATHS=(
        "/Applications/Mathematica.app"
        "/Applications/Wolfram Mathematica.app"
        "/opt/Wolfram/Mathematica"
        "/usr/local/Wolfram/Mathematica"
        "$HOME/Applications/Mathematica.app"
    )
    
    for path in "${MATHEMATICA_PATHS[@]}"; do
        if [ -d "$path" ]; then
            MATHEMATICA_ROOT="$path"
            print_success "Found Mathematica at: $MATHEMATICA_ROOT"
            return 0
        fi
    done
    
    print_warning "Mathematica installation not found in standard locations"
    return 1
}

# Function to find user Applications directory
find_user_applications_dir() {
    print_status "Finding Mathematica user Applications directory..."
    
    # Platform-specific paths - check both Wolfram and Mathematica directories
    case "$(uname)" in
        "Darwin")  # macOS
            # Try Wolfram first (newer versions), then Mathematica (older versions)
            if [ -d "$HOME/Library/Wolfram/Applications" ]; then
                USER_APPS_DIR="$HOME/Library/Wolfram/Applications"
                print_status "Using Wolfram Applications directory (newer version)"
            elif [ -d "$HOME/Library/Mathematica/Applications" ]; then
                USER_APPS_DIR="$HOME/Library/Mathematica/Applications"
                print_status "Using Mathematica Applications directory (older version)"
            else
                # Create the preferred directory (Wolfram for newer versions)
                USER_APPS_DIR="$HOME/Library/Wolfram/Applications"
                print_status "Neither directory exists, will create: $USER_APPS_DIR"
            fi
            ;;
        "Linux")
            # Try Wolfram first, then Mathematica
            if [ -d "$HOME/.Wolfram/Applications" ]; then
                USER_APPS_DIR="$HOME/.Wolfram/Applications"
                print_status "Using Wolfram Applications directory (newer version)"
            elif [ -d "$HOME/.Mathematica/Applications" ]; then
                USER_APPS_DIR="$HOME/.Mathematica/Applications"
                print_status "Using Mathematica Applications directory (older version)"
            else
                USER_APPS_DIR="$HOME/.Wolfram/Applications"
                print_status "Neither directory exists, will create: $USER_APPS_DIR"
            fi
            ;;
        "CYGWIN"*|"MINGW"*|"MSYS"*)  # Windows
            # Try Wolfram first, then Mathematica
            if [ -d "$HOME/AppData/Roaming/Wolfram/Applications" ]; then
                USER_APPS_DIR="$HOME/AppData/Roaming/Wolfram/Applications"
                print_status "Using Wolfram Applications directory (newer version)"
            elif [ -d "$HOME/AppData/Roaming/Mathematica/Applications" ]; then
                USER_APPS_DIR="$HOME/AppData/Roaming/Mathematica/Applications"
                print_status "Using Mathematica Applications directory (older version)"
            else
                USER_APPS_DIR="$HOME/AppData/Roaming/Wolfram/Applications"
                print_status "Neither directory exists, will create: $USER_APPS_DIR"
            fi
            ;;
        *)
            print_error "Unsupported operating system: $(uname)"
            exit 1
            ;;
    esac
    
    print_status "User Applications directory: $USER_APPS_DIR"
}

# Function to create directory if it doesn't exist
ensure_directory() {
    if [ ! -d "$1" ]; then
        print_status "Creating directory: $1"
        mkdir -p "$1"
    fi
}

# Function to backup existing installation
backup_existing() {
    local target_dir="$1"
    if [ -d "$target_dir" ]; then
        local backup_dir="${target_dir}.backup.$(date +%Y%m%d_%H%M%S)"
        print_warning "Existing WolfPy installation found"
        print_status "Creating backup at: $backup_dir"
        mv "$target_dir" "$backup_dir"
    fi
}

# Function to install package
install_package() {
    local source_dir="$1"
    local target_dir="$2"
    
    print_status "Installing WolfPy package..."
    
    # Create target directory
    ensure_directory "$(dirname "$target_dir")"
    
    # Backup existing installation
    backup_existing "$target_dir"
    
    # Copy package files
    print_status "Copying package files..."
    cp -r "$source_dir" "$target_dir"
    
    # Set appropriate permissions
    chmod -R 755 "$target_dir"
    
    print_success "WolfPy package installed successfully!"
}

# Function to test installation
test_installation() {
    print_status "Testing installation..."
    
    # Create a test Mathematica script
    local test_script=$(mktemp).m
    cat > "$test_script" << 'EOF'
Needs["WolfPy`"];
If[ValueQ[WolfPy`ToPython] && ValueQ[WolfPy`ToPythonString],
    Print["WolfPy package loaded successfully!"];
    Exit[0],
    Print["Failed to load WolfPy package!"];
    Exit[1]
]
EOF

    # Try to run the test (if Mathematica kernel is available)
    if command -v math >/dev/null 2>&1; then
        if math -script "$test_script" >/dev/null 2>&1; then
            print_success "Installation test passed!"
        else
            print_warning "Installation test failed (but package files were copied)"
        fi
    elif command -v MathKernel >/dev/null 2>&1; then
        if MathKernel -script "$test_script" >/dev/null 2>&1; then
            print_success "Installation test passed!"
        else
            print_warning "Installation test failed (but package files were copied)"
        fi
    else
        print_warning "Mathematica kernel not found in PATH - skipping test"
    fi
    
    # Clean up test script
    rm -f "$test_script"
}

# Function to print usage instructions
print_usage_instructions() {
    echo
    print_success "Installation complete!"
    echo
    echo "To use WolfPy in Mathematica, add this line to your notebooks:"
    echo
    echo -e "    ${BLUE}Needs[\"WolfPy\`\"]${NC}"
    echo
    echo "Example usage:"
    echo -e "    ${BLUE}myFunc[x_] := x^2 + Sin[x]${NC}"
    echo -e "    ${BLUE}ToPython[myFunc]${NC}"
    echo
    echo "For more examples, see the documentation at:"
    echo -e "    ${BLUE}$TARGET_DIR/README.md${NC}"
    echo -e "    ${BLUE}$TARGET_DIR/Examples.nb${NC}"
    echo
}

# Main installation function
main() {
    echo
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                        WolfPy Installer                         ║"
    echo "║              Mathematica to Python Converter                    ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo
    
    # Get the directory where this script is located
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
    SOURCE_DIR="$SCRIPT_DIR"
    
    # Check if we're in the right directory
    if [ ! -f "$SOURCE_DIR/WolfPy.m" ]; then
        print_error "WolfPy.m not found in current directory!"
        print_error "Please run this script from the WolfPy package directory."
        exit 1
    fi
    
    # Detect installation method preference
    if [ "$1" = "--system" ]; then
        print_status "Installing to system-wide location..."
        if ! detect_mathematica; then
            print_error "Cannot install system-wide without detecting Mathematica installation"
            exit 1
        fi
        TARGET_DIR="$MATHEMATICA_ROOT/Contents/AddOns/Applications/WolfPy"
        if [ ! -w "$(dirname "$TARGET_DIR")" ]; then
            print_error "No write permission to system directory. Try running with sudo or use user installation."
            exit 1
        fi
    else
        print_status "Installing to user Applications directory..."
        find_user_applications_dir
        TARGET_DIR="$USER_APPS_DIR/WolfPy"
    fi
    
    # Install the package
    install_package "$SOURCE_DIR" "$TARGET_DIR"
    
    # Test the installation
    test_installation
    
    # Print usage instructions
    print_usage_instructions
}

# Handle command line arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "WolfPy Package Installer"
    echo
    echo "Usage:"
    echo "  ./install.sh           Install to user Applications directory (recommended)"
    echo "  ./install.sh --system  Install to system-wide location (requires admin privileges)"
    echo "  ./install.sh --help    Show this help message"
    echo
    echo "The installer will:"
    echo "  1. Detect your Mathematica installation"
    echo "  2. Copy WolfPy package files to the appropriate Applications directory"
    echo "  3. Set proper permissions"
    echo "  4. Test the installation (if possible)"
    echo
    exit 0
fi

# Run the main installation
main "$@"