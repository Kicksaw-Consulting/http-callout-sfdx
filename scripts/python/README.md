## Overview

This Python Click script provides two main functions for working with Salesforce OmniScript data, featuring **beautiful Rich library formatting** with colorized output, syntax highlighting, and auto-sizing tables:

### Use Case 1: Get OmniScript Structure (Assessments GET)
Calls the [OmniScript Discovery Framework API](https://developer.salesforce.com/docs/atlas.en-us.industries_reference.meta/industries_reference/connect_resources_store_discovery_framework_structure.htm) with an omniScriptId and returns the 
[omniscript output](https://developer.salesforce.com/docs/atlas.en-us.industries_reference.meta/industries_reference/connect_responses_omniscript_output.htm) as **colorized JSON with syntax highlighting** and a **summary table** showing key properties.

### Use Case 2: List All OmniScript Processes
Executes a SOQL query to retrieve all OmniScript processes and displays them in a **beautiful auto-sizing table** (no truncation) or JSON output.

## ✨ Visual Features

This script leverages the **Rich library** to provide a beautiful, modern CLI experience:

### 🎨 Get Command Features:
- **📊 Summary Table**: Key OmniScript properties (Name, Type, Version, etc.) displayed in a colorized table
- **🌈 JSON Syntax Highlighting**: Full structure with color-coded keys, values, and proper indentation
- **🎯 Structured Layout**: Clean panels and borders for easy reading
- **💾 File Output**: Raw JSON still saved to files when using `--output-path`

### 📊 List Command Features:
- **🔧 Auto-Sizing Tables**: Columns automatically adjust to content (no more truncation!)
- **🎨 Color-Coded Status**: Active/Inactive processes with emoji indicators
- **📋 Rich Formatting**: Beautiful borders, headers, and consistent styling
- **📈 Smart Layout**: Tables adapt to terminal width and content length

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

**Dependencies include:**
- `click` - CLI framework
- `python-dotenv` - Environment variable management
- `simple-salesforce` - Salesforce API client
- `rich` - Beautiful terminal formatting and colors
- `requests` - HTTP client for API calls

### Running the Script

The script supports multiple commands with **beautiful Rich formatting**. All visual enhancements work in any modern terminal with color support. Use `--help` to see available commands and options.

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

#### 🎨 Get Command Output (with Rich formatting)

**Summary Table:**
```
            📊 OmniScript Summary             
┏━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━┓
┃ Property             ┃ Value               ┃
┡━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━┩
│ Name                 │ PRAPARE             │
│ Type                 │ Screening           │
│ SubType              │ PRAPARE             │
│ Language             │ English             │
│ Version              │ 3.0                 │
│ Designer Type        │ Discovery Framework │
│ Usage Type           │ Default             │
│ Total Elements       │ 1                   │
└──────────────────────┴─────────────────────┘
```

**Followed by colorized JSON with syntax highlighting:**
```json
{
  "description": null,
  "designerCustomizationType": "Discovery Framework",
  "discoveryFrameworkUsageType": "Default",
  "elements": [
    {
      "customTypeDetails": {
        "discoveryFramework": {
          "questionCategory": "Demographic",
          "questionDataType": "Radio",
          "questionDeveloperName": "Housing_Situation"
        }
      },
      "name": "Housing_Situation",
      "type": "Radio"
    }
  ],
  "language": "English",
  "name": "PRAPARE"
}
```

#### 📊 List Command Output (auto-sizing table)
```
                                                 🔧 OmniScript Processes                                                 
┏━━━━━━━━━━━━┳━━━━━━━━━━━┳━━━━━━━━━━━┳━━━━━━━━━━┳━━━━━━━━━┳━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┳━━━━━━━━━━━━━━━━━━━━┓
┃ Name       ┃ Type      ┃ SubType   ┃ Language ┃ Version ┃ Active ┃ Unique Name                   ┃ ID                 ┃
┡━━━━━━━━━━━━╇━━━━━━━━━━━╇━━━━━━━━━━━╇━━━━━━━━━━╇━━━━━━━━━╇━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━╇━━━━━━━━━━━━━━━━━━━━┩
│ EPDS       │ Screening │ EPDS      │ English  │   2.0   │ ✅ Yes │ Screening_EPDS_English_2      │ 0jNfl0000000g5hEAA │
│ PRAPARE    │ Screening │ PRAPARE   │ English  │   3.0   │ ✅ Yes │ Screening_PRAPARE_English_3   │ 0jNfl0000000g45EAA │
│ Well Being │ Screening │ WellBeing │ English  │   6.0   │ ✅ Yes │ Screening_WellBeing_English_6 │ 0jNfl0000000gC9EAI │
└────────────┴───────────┴───────────┴──────────┴─────────┴────────┴───────────────────────────────┴────────────────────┘
```

> 💫 **Note**: All output features full color syntax highlighting and responsive formatting in your terminal!
