## Overview

This Python Click script provides two main functions for working with Salesforce OmniScript data:

### Use Case 1: Get OmniScript Structure (Assessments GET)
Calls the [OmniScript Discovery Framework API](https://developer.salesforce.com/docs/atlas.en-us.industries_reference.meta/industries_reference/connect_resources_store_discovery_framework_structure.htm) with an omniScriptId and returns the 
[omniscript output](https://developer.salesforce.com/docs/atlas.en-us.industries_reference.meta/industries_reference/connect_responses_omniscript_output.htm) as well-formatted JSON so that users can see the structure for various omniscripts.

### Use Case 2: List All OmniScript Processes
Executes a SOQL query to retrieve all OmniScript processes and displays them in a rich table format or JSON output.

## General Technical Requirements

1. Must be written as a python click script
2. Must read the .env using python-dotenv to get SFDC credentials
3. Must use salesforce credential flow with username/password/token
4. Must allow for the .env to have a scheme for calling multiple instances, each with their own username/token/password
5. Must allow the user to pass the .env instance scheme as an optional parameter.  If this parameter is not passed in, the default .env instance is chosen
6. Must allow the user to pass the omniscript ID as a required parameter
7. Must allow the user to pass an optional Path parameter, to which the script will also write the output.
8. The python click script must be written to `scripts/python`

## Usage

### Setup

1. Create a `.env` file in the `scripts/python/` directory with your Salesforce credentials:
   
   **Option A:** Copy the example file and modify it:
   ```bash
   cp scripts/python/env.example scripts/python/.env
   # Then edit scripts/python/.env with your actual credentials
   ```
   
   **Option B:** Create `.env` manually with this format:
   ```bash
   # Default Salesforce Instance
   DEFAULT_SF_USERNAME=your_username@example.com
   DEFAULT_SF_PASSWORD=your_password
   DEFAULT_SF_TOKEN=your_security_token
   DEFAULT_SF_DOMAIN=login

   # Optional: Additional instances
   PROD_SF_USERNAME=prod_user@example.com
   PROD_SF_PASSWORD=prod_password
   PROD_SF_TOKEN=prod_security_token
   PROD_SF_DOMAIN=login

   SANDBOX_SF_USERNAME=sandbox_user@example.com.sandbox
   SANDBOX_SF_PASSWORD=sandbox_password
   SANDBOX_SF_TOKEN=sandbox_security_token
   SANDBOX_SF_DOMAIN=test
   ```
   
   📋 **See `scripts/python/env.example` for a comprehensive template with detailed instructions.**

2. Activate the virtual environment and install dependencies:
```bash
source .venv/bin/activate
uv sync
```

### Running the Script

The script now supports multiple commands. Use `--help` to see available commands and options.

```bash
# Get main help (shows available commands)
python scripts/python/omniscript_discovery.py --help

# Get help for specific commands
python scripts/python/omniscript_discovery.py get --help
python scripts/python/omniscript_discovery.py list --help
```

#### Command 1: Get OmniScript Structure

```bash
# Basic usage with default instance
python scripts/python/omniscript_discovery.py get <OMNISCRIPT_ID>

# Using a specific instance
python scripts/python/omniscript_discovery.py get <OMNISCRIPT_ID> --instance PROD

# Save output to file
python scripts/python/omniscript_discovery.py get <OMNISCRIPT_ID> --output-path results.json
```

#### Command 2: List OmniScript Processes

```bash
# List all processes in a rich table (default)
python scripts/python/omniscript_discovery.py list

# List only active processes
python scripts/python/omniscript_discovery.py list --active-only

# Use specific instance
python scripts/python/omniscript_discovery.py list --instance PROD

# Export as JSON
python scripts/python/omniscript_discovery.py list --format json --output-path processes.json

# Combine options
python scripts/python/omniscript_discovery.py list --instance PROD --active-only --output-path active_prod_processes.txt
```

### Examples

#### Getting OmniScript Structure

```bash
# Get OmniScript structure using default instance
python scripts/python/omniscript_discovery.py get a0X1234567890abcde

# Get structure from production instance and save to file
python scripts/python/omniscript_discovery.py get a0X1234567890abcde --instance PROD --output-path prod_omniscript.json

# Get structure from sandbox without pretty formatting
python scripts/python/omniscript_discovery.py get a0X1234567890abcde --instance SANDBOX --no-pretty
```

#### Listing OmniScript Processes

```bash
# Display all processes in a beautiful table
python scripts/python/omniscript_discovery.py list

# Show only active processes from production
python scripts/python/omniscript_discovery.py list --instance PROD --active-only

# Export all processes to JSON
python scripts/python/omniscript_discovery.py list --format json --output-path all_processes.json

# Get active sandbox processes and save table to file
python scripts/python/omniscript_discovery.py list --instance SANDBOX --active-only --output-path sandbox_active.txt

# Quick peek at development processes
python scripts/python/omniscript_discovery.py list --instance DEV
```

### Sample Output

#### Rich Table Output (list command)
```
🔧 OmniScript Processes
┏━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━┳━━━━━━━━━━━━━━━┳━━━━━━━━┳━━━━━━━━┳━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━┓
┃ Name                    ┃ Type       ┃ SubType       ┃ Language ┃ Version ┃ Active ┃ Unique Name                  ┃ ID               ┃
┡━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━╇━━━━━━━━━━━━━━━╇━━━━━━━━╇━━━━━━━━╇━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━┩
│ Customer Registration   │ OmniScript │ Registration  │ English │   1.0  │ ✅ Yes │ CustomerRegistration         │ a0X123456789abcd │
│ Account Assessment      │ OmniScript │ Assessment    │ English │   2.1  │ ❌ No  │ AccountAssessment            │ a0X987654321xyz  │
└─────────────────────────┴────────────┴───────────────┴────────┴────────┴────────┴──────────────────────────────┴──────────────────┘
```
