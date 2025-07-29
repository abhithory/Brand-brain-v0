#!/bin/bash

# PostgreSQL Connection Script
# This script connects to PostgreSQL using environment variables


# Load environment variables from .env file
if [ -f .env ]; then
    set -a  # automatically export all variables
    source .env
    set +a  # stop automatically exporting
fi


set -e  # Exit on any error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if required environment variables are set
if [ -z "$DB_HOST" ]; then
    print_error "DB_HOST environment variable is not set"
    exit 1
fi

if [ -z "$DB_PORT" ]; then
    print_info "DB_PORT not set, using default: 5432"
    export DB_PORT=5432
fi

if [ -z "$DB_NAME" ]; then
    print_error "DB_NAME environment variable is not set"
    exit 1
fi

if [ -z "$DB_USER" ]; then
    print_error "DB_USER environment variable is not set"
    exit 1
fi

if [ -z "$DB_PASSWORD" ]; then
    print_error "DB_PASSWORD environment variable is not set"
    exit 1
fi

# Set password for psql
export PGPASSWORD="$DB_PASSWORD"

print_info "Connecting to PostgreSQL..."
print_info "Host: $DB_HOST"
print_info "Port: $DB_PORT"
print_info "Database: $DB_NAME"
print_info "User: $DB_USER"

print_success "Starting psql session..."

# Connect to PostgreSQL
psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME"