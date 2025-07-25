#!/usr/bin/env python3
"""
OmniScript Discovery Framework API Client

This script provides commands to interact with Salesforce OmniScript APIs:
- Get OmniScript structure information
- List all OmniScript processes
"""

import json
import os
import sys
from pathlib import Path
from typing import Optional, Dict, Any, List

import click
import requests
from dotenv import load_dotenv
from rich.console import Console
from rich.table import Table
from simple_salesforce import Salesforce
from simple_salesforce.exceptions import SalesforceAuthenticationFailed, SalesforceError

console = Console()


class SalesforceClient:
    """Salesforce client for OmniScript Discovery Framework API calls."""
    
    def __init__(self, username: str, password: str, security_token: str, domain: str = 'login'):
        """Initialize Salesforce client.
        
        Args:
            username: Salesforce username
            password: Salesforce password
            security_token: Salesforce security token
            domain: Salesforce domain (login, test, custom domain, or full Lightning domain)
        """
        self.username = username
        self.password = password
        self.security_token = security_token
        # Keep the full domain as provided - simple-salesforce handles Lightning domains
        self.domain = domain
        self.sf = None
    
    def connect(self) -> None:
        """Establish connection to Salesforce."""
        try:
            # Handle Lightning Experience domains differently
            if '.lightning.force.com' in self.domain:
                # For Lightning domains, use instance_url instead of domain
                instance_url = f"https://{self.domain}"
                self.sf = Salesforce(
                    username=self.username,
                    password=self.password,
                    security_token=self.security_token,
                    instance_url=instance_url
                )
                click.echo(f"✅ Successfully connected to Lightning Experience as {self.username}")
                click.echo(f"🌩️ Using Lightning domain: {self.domain}")
            else:
                # For standard domains (login, test, custom.my.salesforce.com)
                self.sf = Salesforce(
                    username=self.username,
                    password=self.password,
                    security_token=self.security_token,
                    domain=self.domain
                )
                click.echo(f"✅ Successfully connected to Salesforce as {self.username}")
        except SalesforceAuthenticationFailed as e:
            click.echo(f"❌ Authentication failed: {e}", err=True)
            sys.exit(1)
        except Exception as e:
            click.echo(f"❌ Connection failed: {e}", err=True)
            sys.exit(1)
    
    def get_omniscript_structure(self, omniscript_id: str) -> Dict[str, Any]:
        """Get OmniScript structure using Discovery Framework API.
        
        Args:
            omniscript_id: The OmniScript ID to query
            
        Returns:
            Dictionary containing the OmniScript structure
        """
        if not self.sf:
            raise RuntimeError("Not connected to Salesforce")
        
        try:
            # Call the OmniScript Discovery Framework API using raw requests with Workbench-like headers
            # This is required because the Discovery Framework API checks for specific headers
            import requests
            from urllib.parse import quote_plus
            
            custom_type = quote_plus("Discovery Framework")
            api_path = f"/services/data/v62.0/connect/omniscript/{omniscript_id}?customType={custom_type}"
            full_url = f"https://{self.sf.sf_instance}{api_path}"
            
            # Headers that mimic Workbench behavior (required for Discovery Framework API)
            headers = {
                'Authorization': f'Bearer {self.sf.session_id}',
                'Accept': 'application/json',
                'User-Agent': 'Mozilla/5.0 (compatible; SalesforceWorkbench)',
                'X-Requested-With': 'XMLHttpRequest',
                'Content-Type': 'application/json'
            }
            
            click.echo(f"🔍 Calling Discovery Framework API: {api_path}")
            
            response = requests.get(full_url, headers=headers, timeout=30)
            
            if response.status_code == 200:
                return response.json()
            else:
                raise SalesforceError(f"API call failed with status {response.status_code}: {response.text}")
                
        except SalesforceError as e:
            click.echo(f"❌ Salesforce API error: {e}", err=True)
            sys.exit(1)
        except Exception as e:
            click.echo(f"❌ Unexpected error: {e}", err=True)
            sys.exit(1)
    
    def list_omniscript_processes(self) -> List[Dict[str, Any]]:
        """List all OmniScript processes using SOQL query.
        
        Returns:
            List of dictionaries containing OmniScript process information
        """
        if not self.sf:
            raise RuntimeError("Not connected to Salesforce")
        
        try:
            # Execute SOQL query to get all OmniScript processes
            query = """
            SELECT Id, Name, UniqueName, Type, SubType, Language, 
                   VersionNumber, DesignerCustomizationType, IsActive,
                   CreatedDate, LastModifiedDate, CreatedBy.Name, LastModifiedBy.Name
            FROM OmniProcess
            ORDER BY Name, VersionNumber DESC
            """
            
            result = self.sf.query(query)
            return result['records']
                
        except SalesforceError as e:
            click.echo(f"❌ Salesforce API error: {e}", err=True)
            sys.exit(1)
        except Exception as e:
            click.echo(f"❌ Unexpected error: {e}", err=True)
            sys.exit(1)


def load_credentials(instance: str) -> Dict[str, str]:
    """Load Salesforce credentials from .env file in the scripts/python directory.
    
    Args:
        instance: Instance name prefix (e.g., 'DEFAULT', 'PROD', 'SANDBOX')
        
    Returns:
        Dictionary containing credentials
    """
    # Get the directory where this script is located
    script_dir = Path(__file__).parent
    env_file = script_dir / '.env'
    
    # Load .env file from the script directory
    load_dotenv(env_file)
    
    # Build credential keys based on instance
    username_key = f"{instance}_SF_USERNAME"
    password_key = f"{instance}_SF_PASSWORD"
    token_key = f"{instance}_SF_TOKEN"
    domain_key = f"{instance}_SF_DOMAIN"
    
    # Get credentials
    username = os.getenv(username_key)
    password = os.getenv(password_key)
    token = os.getenv(token_key)
    domain = os.getenv(domain_key, 'login')  # Default to 'login'
    
    # Validate required credentials
    missing_creds = []
    if not username:
        missing_creds.append(username_key)
    if not password:
        missing_creds.append(password_key)
    if not token:
        missing_creds.append(token_key)
    
    if missing_creds:
        click.echo(f"❌ Missing required environment variables: {', '.join(missing_creds)}", err=True)
        click.echo("\n📝 Expected .env format:")
        click.echo(f"   {username_key}=your_username")
        click.echo(f"   {password_key}=your_password")
        click.echo(f"   {token_key}=your_security_token")
        click.echo(f"   {domain_key}=login  # Optional: login, test, or custom domain")
        sys.exit(1)
    
    return {
        'username': username,
        'password': password,
        'security_token': token,
        'domain': domain
    }


@click.group()
def cli():
    """OmniScript Discovery Framework API Client
    
    Provides commands to interact with Salesforce OmniScript APIs.
    """
    pass


@cli.command('get')
@click.argument('omniscript_id', required=True)
@click.option(
    '--instance', '-i',
    default='DEFAULT',
    help='Salesforce instance configuration to use from .env file (default: DEFAULT)'
)
@click.option(
    '--output-path', '-o',
    type=click.Path(),
    help='Optional file path to write the JSON output'
)
@click.option(
    '--pretty/--no-pretty',
    default=True,
    help='Format JSON output with indentation (default: True)'
)
def get_omniscript_structure(omniscript_id: str, instance: str, output_path: Optional[str], pretty: bool):
    """Get OmniScript structure from Salesforce OmniScript Discovery Framework API.
    
    OMNISCRIPT_ID: The ID of the OmniScript to retrieve structure for
    
    \b
    Examples:
        # Using default instance
        python omniscript_discovery.py a0X1234567890abcde
        
        # Using specific instance
        python omniscript_discovery.py a0X1234567890abcde --instance PROD
        
        # Save output to file
        python omniscript_discovery.py a0X1234567890abcde --output-path omniscript.json
    
    \b
    .env file format:
        DEFAULT_SF_USERNAME=user@example.com
        DEFAULT_SF_PASSWORD=password123
        DEFAULT_SF_TOKEN=your_security_token
        DEFAULT_SF_DOMAIN=login
        
        PROD_SF_USERNAME=prod@example.com
        PROD_SF_PASSWORD=prodpassword
        PROD_SF_TOKEN=prod_security_token
        PROD_SF_DOMAIN=login
    """
    # Validate .env file exists in the script directory
    script_dir = Path(__file__).parent
    env_file = script_dir / '.env'
    if not env_file.exists():
        click.echo(f"❌ .env file not found in {script_dir}", err=True)
        click.echo(f"Please create a .env file at {env_file} with your Salesforce credentials", err=True)
        click.echo(f"You can copy {script_dir / 'env.example'} to get started", err=True)
        sys.exit(1)
    
    # Load credentials for specified instance
    click.echo(f"🔑 Loading credentials for instance: {instance}")
    credentials = load_credentials(instance)
    
    # Create Salesforce client and connect
    client = SalesforceClient(**credentials)
    client.connect()
    
    # Get OmniScript structure
    click.echo(f"📊 Retrieving OmniScript structure for ID: {omniscript_id}")
    structure = client.get_omniscript_structure(omniscript_id)
    
    # Format JSON output
    if pretty:
        json_output = json.dumps(structure, indent=2, ensure_ascii=False)
    else:
        json_output = json.dumps(structure, ensure_ascii=False)
    
    # Output to console
    click.echo("\n📋 OmniScript Structure:")
    click.echo("=" * 50)
    click.echo(json_output)
    
    # Write to file if path specified
    if output_path:
        try:
            output_file = Path(output_path)
            output_file.parent.mkdir(parents=True, exist_ok=True)
            
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(json_output)
            
            click.echo(f"\n💾 Output saved to: {output_file.absolute()}")
        except Exception as e:
            click.echo(f"\n❌ Failed to write output file: {e}", err=True)
            sys.exit(1)
    
    click.echo(f"\n✅ Successfully retrieved OmniScript structure for {omniscript_id}")


@cli.command('list')
@click.option(
    '--instance', '-i',
    default='DEFAULT',
    help='Salesforce instance configuration to use from .env file (default: DEFAULT)'
)
@click.option(
    '--output-path', '-o',
    type=click.Path(),
    help='Optional file path to write the JSON output'
)
@click.option(
    '--active-only', '-a',
    is_flag=True,
    help='Show only active OmniScript processes'
)
@click.option(
    '--format', '-f',
    type=click.Choice(['table', 'json'], case_sensitive=False),
    default='table',
    help='Output format: table (default) or json'
)
def list_omniscript_processes(instance: str, output_path: Optional[str], active_only: bool, format: str):
    """List all OmniScript processes from Salesforce.
    
    \b
    Examples:
        # List all OmniScript processes in a table
        python omniscript_discovery.py list
        
        # List only active processes from production
        python omniscript_discovery.py list --instance PROD --active-only
        
        # Export to JSON file
        python omniscript_discovery.py list --format json --output-path processes.json
    """
    # Validate .env file exists in the script directory
    script_dir = Path(__file__).parent
    env_file = script_dir / '.env'
    if not env_file.exists():
        click.echo(f"❌ .env file not found in {script_dir}", err=True)
        click.echo(f"Please create a .env file at {env_file} with your Salesforce credentials", err=True)
        click.echo(f"You can copy {script_dir / 'env.example'} to get started", err=True)
        sys.exit(1)
    
    # Load credentials for specified instance
    click.echo(f"🔑 Loading credentials for instance: {instance}")
    credentials = load_credentials(instance)
    
    # Create Salesforce client and connect
    client = SalesforceClient(**credentials)
    client.connect()
    
    # Get OmniScript processes
    click.echo("📊 Retrieving OmniScript processes...")
    processes = client.list_omniscript_processes()
    
    # Filter active only if requested
    if active_only:
        processes = [p for p in processes if p.get('IsActive', False)]
        click.echo(f"🔍 Filtered to {len(processes)} active processes")
    
    if not processes:
        click.echo("📋 No OmniScript processes found.")
        return
    
    # Format and display output
    if format.lower() == 'json':
        # JSON output
        json_output = json.dumps(processes, indent=2, ensure_ascii=False)
        
        # Output to console
        click.echo("\n📋 OmniScript Processes (JSON):")
        click.echo("=" * 50)
        click.echo(json_output)
        
        # Write to file if path specified
        if output_path:
            try:
                output_file = Path(output_path)
                output_file.parent.mkdir(parents=True, exist_ok=True)
                
                with open(output_file, 'w', encoding='utf-8') as f:
                    f.write(json_output)
                
                click.echo(f"\n💾 Output saved to: {output_file.absolute()}")
            except Exception as e:
                click.echo(f"\n❌ Failed to write output file: {e}", err=True)
                sys.exit(1)
    else:
        # Rich table output
        display_processes_table(processes, output_path)
    
    click.echo(f"\n✅ Successfully retrieved {len(processes)} OmniScript processes")


def display_processes_table(processes: List[Dict[str, Any]], output_path: Optional[str] = None):
    """Display OmniScript processes in a rich table format."""
    
    table = Table(title="🔧 OmniScript Processes", show_header=True, header_style="bold magenta")
    
    # Add columns
    table.add_column("Name", style="cyan", no_wrap=True, width=25)
    table.add_column("Type", style="green", width=12)
    table.add_column("SubType", style="yellow", width=15)
    table.add_column("Language", style="blue", width=8)
    table.add_column("Version", justify="center", style="magenta", width=8)
    table.add_column("Active", justify="center", style="bold", width=8)
    table.add_column("Unique Name", style="white", width=30)
    table.add_column("ID", style="dim", width=18)
    
    # Add rows
    for process in processes:
        # Format active status with emoji
        active_status = "✅ Yes" if process.get('IsActive', False) else "❌ No"
        active_style = "bold green" if process.get('IsActive', False) else "bold red"
        
        # Truncate long names and unique names
        name = str(process.get('Name', 'N/A'))
        if len(name) > 23:
            name = name[:20] + "..."
            
        unique_name = str(process.get('UniqueName', 'N/A'))
        if len(unique_name) > 28:
            unique_name = unique_name[:25] + "..."
        
        table.add_row(
            name,
            str(process.get('Type', 'N/A')),
            str(process.get('SubType', 'N/A')),
            str(process.get('Language', 'N/A')),
            str(process.get('VersionNumber', 'N/A')),
            active_status,
            unique_name,
            str(process.get('Id', 'N/A'))[:18]
        )
    
    # Display table
    console.print("\n")
    console.print(table)
    
    # Save to file if requested
    if output_path:
        try:
            output_file = Path(output_path)
            output_file.parent.mkdir(parents=True, exist_ok=True)
            
            # Export as text table
            with console.capture() as capture:
                console.print(table)
            table_text = capture.get()
            
            with open(output_file, 'w', encoding='utf-8') as f:
                f.write(table_text)
            
            click.echo(f"\n💾 Table output saved to: {output_file.absolute()}")
        except Exception as e:
            click.echo(f"\n❌ Failed to write output file: {e}", err=True)
            sys.exit(1)


@cli.command('debug')
@click.argument('omniscript_id', required=True)
@click.option(
    '--instance', '-i',
    default='DEFAULT',
    help='Salesforce instance configuration to use from .env file (default: DEFAULT)'
)
@click.option(
    '--raw-request', '-r',
    is_flag=True,
    help='Try making raw HTTP requests with different headers'
)
def debug_api_call(omniscript_id: str, instance: str, raw_request: bool):
    """Debug the Discovery Framework API call with various approaches.
    
    This command helps troubleshoot API connectivity issues by trying different
    methods and showing detailed information about the requests and responses.
    """
    # Load credentials and connect
    script_dir = Path(__file__).parent
    env_file = script_dir / '.env'
    if not env_file.exists():
        click.echo(f"❌ .env file not found at {env_file}", err=True)
        sys.exit(1)
    
    click.echo(f"🔑 Loading credentials for instance: {instance}")
    credentials = load_credentials(instance)
    
    client = SalesforceClient(**credentials)
    client.connect()
    
    click.echo(f"\n🔍 Testing Discovery Framework API for ID: {omniscript_id}")
    
    # Try different approaches
    approaches = [
        {
            'name': 'Original URL with Discovery+Framework',
            'url': f"/services/data/v62.0/connect/omniscript/{omniscript_id}?customType=Discovery+Framework"
        },
        {
            'name': 'URL with Discovery%20Framework (percent encoding)',
            'url': f"/services/data/v62.0/connect/omniscript/{omniscript_id}?customType=Discovery%20Framework"
        },
        {
            'name': 'URL without customType parameter',
            'url': f"/services/data/v62.0/connect/omniscript/{omniscript_id}"
        },
        {
            'name': 'URL with different API version (v59.0)',
            'url': f"/services/data/v59.0/connect/omniscript/{omniscript_id}?customType=Discovery+Framework"
        }
    ]
    
    for i, approach in enumerate(approaches, 1):
        click.echo(f"\n🧪 Approach {i}: {approach['name']}")
        click.echo(f"   URL: {approach['url']}")
        
        try:
            response = client.sf.restful(approach['url'], method='GET')
            if response.status_code == 200:
                click.echo(f"   ✅ SUCCESS! Status: {response.status_code}")
                result = response.json()
                click.echo(f"   📄 Response keys: {list(result.keys())}")
                return  # Stop on first success
            else:
                click.echo(f"   ❌ Failed with status: {response.status_code}")
                click.echo(f"   📄 Response: {response.text[:200]}...")
        except Exception as e:
            click.echo(f"   💥 Exception: {str(e)[:200]}...")
    
    click.echo(f"\n🚨 All approaches failed. The Discovery Framework API may not be available in this org.")
    
    if raw_request:
        click.echo(f"\n🧪 Trying raw HTTP requests...")
        try_raw_requests(client, omniscript_id)
    
    click.echo(f"💡 Try checking:")
    click.echo(f"   - OmniStudio permissions and licenses")
    click.echo(f"   - API access permissions")
    click.echo(f"   - Whether the Discovery Framework feature is enabled")


def try_raw_requests(client: SalesforceClient, omniscript_id: str):
    """Try making raw HTTP requests with different headers to match Workbench behavior."""
    import requests
    
    base_url = f"https://{client.sf.sf_instance}"
    api_url = f"/services/data/v62.0/connect/omniscript/{omniscript_id}?customType=Discovery+Framework"
    full_url = base_url + api_url
    
    # Headers that mimic a browser/Workbench request
    headers_variations = [
        {
            'name': 'Workbench-like headers',
            'headers': {
                'Authorization': f'Bearer {client.sf.session_id}',
                'Accept': 'application/json',
                'User-Agent': 'Mozilla/5.0 (compatible; SalesforceWorkbench)',
                'X-Requested-With': 'XMLHttpRequest',
                'Content-Type': 'application/json'
            }
        },
        {
            'name': 'Standard API headers',
            'headers': {
                'Authorization': f'Bearer {client.sf.session_id}',
                'Accept': 'application/json',
                'User-Agent': 'Python/simple-salesforce'
            }
        },
        {
            'name': 'Minimal headers',
            'headers': {
                'Authorization': f'Bearer {client.sf.session_id}',
                'Accept': 'application/json'
            }
        }
    ]
    
    for i, variation in enumerate(headers_variations, 1):
        click.echo(f"\n🔬 Raw Request {i}: {variation['name']}")
        click.echo(f"   URL: {full_url}")
        click.echo(f"   Headers: {variation['headers']}")
        
        try:
            response = requests.get(full_url, headers=variation['headers'], timeout=30)
            click.echo(f"   📡 Status: {response.status_code}")
            click.echo(f"   📋 Response Headers: {dict(response.headers)}")
            
            if response.status_code == 200:
                click.echo(f"   ✅ SUCCESS with raw request!")
                result = response.json()
                click.echo(f"   📄 Response keys: {list(result.keys())}")
                click.echo(f"   📊 First few lines of response:")
                click.echo(f"   {str(result)[:300]}...")
                return
            else:
                click.echo(f"   ❌ Failed: {response.text[:100]}...")
                
        except Exception as e:
            click.echo(f"   💥 Exception: {str(e)[:100]}...")
    
    click.echo(f"\n🚨 All raw request approaches also failed.")


if __name__ == '__main__':
    cli() 