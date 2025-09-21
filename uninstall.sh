#!/bin/bash

# WolfPy Package Uninstaller
# This script removes the WolfPy package from Mathematica's Applications directory

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

# Function to find user Applications directory
find_user_applications_dir() {
    # Platform-specific paths - check both Wolfram and Mathematica directories
    case "$(uname)" in
        "Darwin")  # macOS
            # Check both locations for WolfPy installation
            if [ -d "$HOME/Library/Wolfram/Applications/WolfPy" ]; then
                USER_APPS_DIR="$HOME/Library/Wolfram/Applications"
            elif [ -d "$HOME/Library/Mathematica/Applications/WolfPy" ]; then
                USER_APPS_DIR="$HOME/Library/Mathematica/Applications"
            else
                USER_APPS_DIR="$HOME/Library/Wolfram/Applications"  # Default for newer versions
            fi
            ;;
        "Linux")
            # Check both locations for WolfPy installation
            if [ -d "$HOME/.Wolfram/Applications/WolfPy" ]; then
                USER_APPS_DIR="$HOME/.Wolfram/Applications"
            elif [ -d "$HOME/.Mathematica/Applications/WolfPy" ]; then
                USER_APPS_DIR="$HOME/.Mathematica/Applications"
            else
                USER_APPS_DIR="$HOME/.Wolfram/Applications"  # Default for newer versions
            fi
            ;;
        "CYGWIN"*|"MINGW"*|"MSYS"*)  # Windows
            # Check both locations for WolfPy installation
            if [ -d "$HOME/AppData/Roaming/Wolfram/Applications/WolfPy" ]; then
                USER_APPS_DIR="$HOME/AppData/Roaming/Wolfram/Applications"
            elif [ -d "$HOME/AppData/Roaming/Mathematica/Applications/WolfPy" ]; then
                USER_APPS_DIR="$HOME/AppData/Roaming/Mathematica/Applications"
            else
                USER_APPS_DIR="$HOME/AppData/Roaming/Wolfram/Applications"  # Default for newer versions
            fi
            ;;
        *)
            print_error "Unsupported operating system: $(uname)"
            exit 1
            ;;
    esac
}

# Function to find WolfPy installations
find_installations() {
    print_status "Searching for WolfPy installations..."
    
    INSTALLATIONS=()
    
    # Check user directory
    find_user_applications_dir
    if [ -d "$USER_APPS_DIR/WolfPy" ]; then
        INSTALLATIONS+=("$USER_APPS_DIR/WolfPy")
        print_status "Found user installation: $USER_APPS_DIR/WolfPy"
    fi
    
    # Check common system directories
    SYSTEM_PATHS=(
        "/Applications/Mathematica.app/Contents/AddOns/Applications/WolfPy"
        "/Applications/Wolfram Mathematica.app/Contents/AddOns/Applications/WolfPy"
        "/opt/Wolfram/Mathematica/*/Contents/AddOns/Applications/WolfPy"
        "/usr/local/Wolfram/Mathematica/*/Contents/AddOns/Applications/WolfPy"
    )
    
    for path in "${SYSTEM_PATHS[@]}"; do
        if [ -d "$path" ]; then
            INSTALLATIONS+=("$path")
            print_status "Found system installation: $path"
        fi
    done
    
    if [ ${#INSTALLATIONS[@]} -eq 0 ]; then
        print_warning "No WolfPy installations found"
        return 1
    fi
    
    return 0
}

# Function to remove installation
remove_installation() {
    local install_path="$1"
    local force="$2"
    
    if [ ! -d "$install_path" ]; then
        print_warning "Installation not found: $install_path"
        return 1
    fi
    
    if [ "$force" != "true" ]; then
        echo
        print_warning "About to remove: $install_path"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_status "Skipping removal of: $install_path"
            return 0
        fi
    fi
    
    print_status "Removing: $install_path"
    
    # Create backup before removal
    local backup_path="${install_path}.removed.$(date +%Y%m%d_%H%M%S)"
    if mv "$install_path" "$backup_path" 2>/dev/null; then
        print_success "Removed successfully (backup created at: $backup_path)"
    else
        print_error "Failed to remove: $install_path"
        print_error "You may need to run with sudo for system installations"
        return 1
    fi
}

# Function to clean up backup files
cleanup_backups() {
    print_status "Searching for old WolfPy backups..."
    
    find_user_applications_dir
    local backup_pattern="$USER_APPS_DIR/WolfPy.backup.*"
    local removed_pattern="$USER_APPS_DIR/WolfPy.removed.*"
    
    local backups_found=false
    
    # Find backup files
    for pattern in "$backup_pattern" "$removed_pattern"; do
        for backup in $pattern; do
            if [ -d "$backup" ]; then
                backups_found=true
                echo "  Found backup: $backup"
            fi
        done
    done
    
    if [ "$backups_found" = true ]; then
        echo
        read -p "Remove all backup directories? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            for pattern in "$backup_pattern" "$removed_pattern"; do
                for backup in $pattern; do
                    if [ -d "$backup" ]; then
                        print_status "Removing backup: $backup"
                        rm -rf "$backup"
                    fi
                done
            done
            print_success "Backup cleanup complete"
        fi
    else
        print_status "No backup directories found"
    fi
}

# Main uninstall function
main() {
    echo
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║                      WolfPy Uninstaller                         ║"
    echo "║              Mathematica to Python Converter                    ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo
    
    local force=false
    local cleanup=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --force)
                force=true
                shift
                ;;
            --cleanup)
                cleanup=true
                shift
                ;;
            --help|-h)
                echo "WolfPy Package Uninstaller"
                echo
                echo "Usage:"
                echo "  ./uninstall.sh           Interactive uninstall"
                echo "  ./uninstall.sh --force   Remove all installations without prompting"
                echo "  ./uninstall.sh --cleanup Remove old backup directories"
                echo "  ./uninstall.sh --help    Show this help message"
                echo
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    if [ "$cleanup" = true ]; then
        cleanup_backups
        exit 0
    fi
    
    # Find all installations
    if ! find_installations; then
        exit 0
    fi
    
    echo
    print_status "Found ${#INSTALLATIONS[@]} WolfPy installation(s)"
    
    # Remove each installation
    local removed_count=0
    for installation in "${INSTALLATIONS[@]}"; do
        if remove_installation "$installation" "$force"; then
            ((removed_count++))
        fi
    done
    
    echo
    if [ $removed_count -gt 0 ]; then
        print_success "Uninstallation complete! Removed $removed_count installation(s)."
        echo
        print_status "Note: Backup directories were created in case you need to restore."
        print_status "Use './uninstall.sh --cleanup' to remove backup directories."
    else
        print_warning "No installations were removed."
    fi
    echo
}

# Run the main uninstaller
main "$@"