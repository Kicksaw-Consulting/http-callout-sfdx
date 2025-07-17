# Salesforce DX Project: Next Steps

Now that you've created a Salesforce DX project, what's next? Here are some documentation resources to get you started.

## How Do You Plan to Deploy Your Changes?

Do you want to deploy a set of changes, or create a self-contained application? Choose a [development model](https://developer.salesforce.com/tools/vscode/en/user-guide/development-models).

## Configure Your Salesforce DX Project

The `sfdx-project.json` file contains useful configuration information for your project. See [Salesforce DX Project Configuration](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_config.htm) in the _Salesforce DX Developer Guide_ for details about this file.

## Read All About It

- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)

# Essential Salesforce CLI Commands for Beginners

Welcome to Salesforce development! This guide covers the most important CLI commands you'll need to get started with Salesforce development and deployment.

## 🔄 CLI Version Update (Important!)

**Note**: Salesforce transitioned from `sfdx` to `sf` commands in July 2023. The new `sf` CLI is faster and more intuitive. Both command styles work, but `sf` is the future.

- **New style**: `sf org login web`
- **Old style**: `sfdx force:auth:web:login` (still works but deprecated)

## 🔧 Getting Started Commands

### Check CLI Version
```bash
sf --version
```

### Get Help
```bash
sf --help
sf org --help
sf project --help
```

## 🔐 Authentication & Org Management

### 1. Authenticate with Your Org
```bash
# Login to a Salesforce org (opens browser)
sf org login web

# Login to a sandbox
sf org login web --instance-url https://test.salesforce.com

# Login with an alias (recommended for multiple orgs)
sf org login web --alias myorg
```

### 2. List Connected Orgs
```bash
# See all connected orgs
sf org list

# See more details
sf org list --all
```

### 3. Set Default Org
```bash
# Set default org for commands
sf config set target-org your-org-alias-or-username
```

### 4. Open Org in Browser
```bash
# Open default org
sf org open

# Open specific org
sf org open --target-org myorg
```

## 🏗️ Scratch Orgs (Development Environments)

### 1. Create a Scratch Org
```bash
# Create scratch org with default settings
sf org create scratch --definition-file config/project-scratch-def.json --alias myscratch

# Create with specific duration (1-30 days)
sf org create scratch --definition-file config/project-scratch-def.json --alias myscratch --duration-days 7 --set-default
```

### 2. Delete a Scratch Org
```bash
sf org delete scratch --target-org myscratch
```

## 📦 Code Deployment & Retrieval

### 1. Deploy Your Code to Org
```bash
# Deploy all source to default org
sf project deploy start

# Deploy specific file or folder
sf project deploy start --source-dir force-app/main/default/classes/MyClass.cls

# Deploy with test run
sf project deploy start --test-level RunLocalTests
```

### 2. Retrieve Code from Org
```bash
# Get all changes from org
sf project retrieve start

# Retrieve specific metadata
sf project retrieve start --metadata ApexClass:MyClass
```

### 3. Quick Deploy (for Development)
```bash
# Push changes to scratch org (development only)
sf project deploy start --ignore-conflicts

# Pull changes from scratch org
sf project retrieve start --ignore-conflicts
```

## 🧪 Testing

### 1. Run Apex Tests
```bash
# Run all tests
sf apex run test

# Run specific test class
sf apex run test --class-names MyTestClass

# Run tests with code coverage
sf apex run test --code-coverage --result-format human
```

### 2. View Test Results
```bash
# Get detailed test results with coverage
sf apex get test --test-run-id YOUR_TEST_RUN_ID --code-coverage --detailed-coverage
```

## 📊 Data Management

### 1. Export/Import Data
```bash
# Export data using SOQL
sf data query --query "SELECT Id, Name FROM Account LIMIT 10"

# Import data from CSV
sf data import tree --plan data/sample-data-plan.json
```

### 2. Create Records
```bash
# Create a single record
sf data create record --sobject Account --values "Name='Test Account' Type='Customer'"
```

## 🔍 Debugging & Logs

### 1. View Logs
```bash
# List recent logs
sf apex list log

# Get specific log
sf apex get log --log-id YOUR_LOG_ID

# Tail logs in real-time
sf apex tail log
```

## 📋 Common Workflow Examples

### Starting a New Feature
```bash
# 1. Create a new scratch org
sf org create scratch --definition-file config/project-scratch-def.json --alias feature-branch --duration-days 7 --set-default

# 2. Push your code
sf project deploy start

# 3. Work on your feature...

# 4. Run tests
sf apex run test --code-coverage

# 5. When done, delete scratch org
sf org delete scratch --target-org feature-branch
```

### Deploying to Production
```bash
# 1. Validate deployment (doesn't actually deploy)
sf project deploy start --dry-run --test-level RunLocalTests --target-org production

# 2. If validation passes, deploy for real
sf project deploy start --test-level RunLocalTests --target-org production
```

## 🆘 Troubleshooting Tips

1. **Authentication Issues**: Run `sf org login web` to re-authenticate
2. **Permission Errors**: Make sure you have the right permissions in your org
3. **Deployment Conflicts**: Use `--ignore-conflicts` flag for development orgs
4. **Get Help**: Use `--help` flag with any command for detailed information

## 📚 Quick Reference

| Task | New Command (sf) | Old Command (sfdx) |
|------|------------------|-------------------|
| Login | `sf org login web` | `sfdx force:auth:web:login` |
| Create Scratch Org | `sf org create scratch` | `sfdx force:org:create` |
| Deploy Code | `sf project deploy start` | `sfdx force:source:push` |
| Retrieve Code | `sf project retrieve start` | `sfdx force:source:pull` |
| Run Tests | `sf apex run test` | `sfdx force:apex:test:run` |
| Open Org | `sf org open` | `sfdx force:org:open` |

## 🔗 Helpful Resources

- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/)
- [Trailhead: Salesforce DX](https://trailhead.salesforce.com/trails/sfdx_get_started)
- [VS Code Salesforce Extensions](https://marketplace.visualstudio.com/items?itemName=salesforce.salesforcedx-vscode)

# pyx-http-callout-sfdx
